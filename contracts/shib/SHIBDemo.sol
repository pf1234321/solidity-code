// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/Sqrt.sol";
contract SHIBDemo is ERC20, ERC20Permit, ReentrancyGuardUpgradeable {
    using SafeERC20 for IERC20;

    // 核心常量定义
    uint256 public constant totalSupply = 1000000000000000 * 10**18;
    uint256 public constant maxTransferCount = 100000000 * 10**18;
    uint256 public constant dayTransferLimit = 3;
    uint256 public constant FEE_DENOMINATOR = 10000;
    uint256 public constant LIQUIDITY_FEE = 30;

    // 状态变量
    IERC20 public immutable pairedToken;
    ERC20 public immutable liquidityToken;
    mapping(address => mapping(uint256 => uint256)) public dailyTransferCount;
    mapping(address => uint256) public liquidityShares;
    uint256 public totalLiquidityShares;
    uint256 public immutable creationTime;

    // 事件定义
    event LiquidityAdded(address indexed provider, uint256 shibAmount, uint256 pairedTokenAmount, uint256 actualShib, uint256 actualPaired, uint256 shares);
    event LiquidityRemoved(address indexed provider, uint256 shibAmount, uint256 pairedTokenAmount, uint256 shares);

    constructor(address _pairedToken) ERC20("SHIBDemo", "SHIB") ERC20Permit("SHIBDemo") {
        pairedToken = IERC20(_pairedToken);
        liquidityToken = new ERC20("SHIB-LP", "SHIB-LP");
        _mint(msg.sender, totalSupply);
        creationTime = block.timestamp;
    }

    function burn(uint256 amount) external {
        super._burn(msg.sender, amount);
    }

    /**
     * @dev 重写ERC20的_transfer函数（核心转账逻辑，添加自定义规则）
     * @param from 转账发起地址（资金流出方）
     * @param to 转账接收地址（资金流入方）
     * @param amount 转账总金额（未扣除销毁和手续费的原始金额）
     * 核心功能：
     * 1. 限制单笔转账额度和每日转账次数（防大额波动和恶意刷量）
     * 2. 实现交易销毁机制（增强代币通缩性）
     * 3. 提取流动性手续费（自动注入流动性池，奖励做市商）
     * 执行流程：
     * - 先校验转账规则（额度、次数）
     * - 再计算销毁和手续费
     * - 最后分步骤执行销毁、手续费转账和实际转账
     */
    function _transfer(address from, address to, uint256 amount) internal override {
        // 校验1：单笔转账金额不得超过最大限制（防止大额交易冲击市场）
        // maxTransferCount为常量（如1亿枚），超过则转账失败
        require(amount <= maxTransferCount, "Transfer amount exceeds the daily limit");
        
        // 计算当前日期（按UTC时间，以天为单位：时间戳÷86400秒/天）
        uint256 currentDay = block.timestamp / 86400;
        
        // 校验2：非铸造场景（from≠0地址）需限制每日转账次数
        if (from != address(0)) { 
            // 验证当前地址今日交易次数是否小于限制（如3次/天）
            require(dailyTransferCount[from][currentDay] < dayTransferLimit, "Daily transfer limit exceeded");
            // 交易次数+1（记录本次转账，用于后续次数校验）
            dailyTransferCount[from][currentDay]++;
        }
        
        // 计算转账中的资金分配：
        // 1. 销毁金额：转账金额的0.1%（amount × 1/1000）
        uint256 burnAmount = amount * 1 / 1000;
        // 2. 流动性手续费：转账金额的0.3%（LIQUIDITY_FEE=30，FEE_DENOMINATOR=10000 → 30/10000=0.3%）
        uint256 liquidityFee = amount * LIQUIDITY_FEE / FEE_DENOMINATOR;
        
        // 步骤1：执行销毁（从发起者地址销毁对应金额，永久减少总供应量）
        super._burn(from, burnAmount);
        
        // 步骤2：转账手续费到流动性池（将手续费转入合约地址，作为流动性池储备）
        super._transfer(from, address(this), liquidityFee);
        
        // 步骤3：执行实际转账（将剩余金额转给接收方：总金额 - 销毁金额 - 手续费）
        super._transfer(from, to, amount - burnAmount - liquidityFee);
    }

    function getDailyTransferCount(address user, uint256 timestamp) external view returns (uint256) {
        uint256 day = timestamp / 86400;
        return dailyTransferCount[user][day];
    }

    // 核心优化：添加流动性函数（按比例校验+实际转移匹配量+退回超额）
    function addLiquidity(uint256 shibAmount, uint256 pairedTokenAmount) 
        external 
        nonReentrant 
        returns (uint256 shares) 
    {
        require(shibAmount > 0 && pairedTokenAmount > 0, "Cannot add zero liquidity");
        
        uint256 totalShib = balanceOf(address(this));
        uint256 totalPaired = pairedToken.balanceOf(address(this));
        
        // 定义实际注入量（后续根据比例调整）
        uint256 actualShib;
        uint256 actualPaired;

        if (totalLiquidityShares == 0) {
            // 首次添加：直接使用用户注入量（初始化比例）
            actualShib = shibAmount;
            actualPaired = pairedTokenAmount;
            // shares = actualShib; // 首次份额=注入的SHIB数量
             shares = Math.sqrt(actualShib * actualPaired); // 使用数学库计算几何平均数
        } else {
            // 非首次添加：计算应注入的配对代币数量
            uint256 requiredPairedAmount = (shibAmount * totalPaired) / totalShib;

            // 根据用户提供的数量确定实际注入量（匹配池内比例）
            if (pairedTokenAmount == requiredPairedAmount) {
                // 比例完全匹配：全量注入
                actualShib = shibAmount;
                actualPaired = pairedTokenAmount;
            } else if (pairedTokenAmount < requiredPairedAmount) {
                // 配对代币不足：按实际配对代币量反推SHIB注入量
                actualPaired = pairedTokenAmount;
                actualShib = (actualPaired * totalShib) / totalPaired;
            } else {
                // 配对代币超额：按SHIB注入量确定配对代币注入量
                actualShib = shibAmount;
                actualPaired = requiredPairedAmount;
            }
            // 根据实际注入量计算份额（因比例已匹配，两种方式结果一致）  用户获得的份额 = （用户注入的有效 SHIB 数量 ÷ 池内已有 SHIB 总量）× 池内现有总份额
            // 总池有 1000 SHIB + 100 USDT，总 shares 为 200 份。 此时： totalShib 是1000 SHIB   totalLiquidityShares是200
            // 用户注入 100 SHIB + 10 USDT（占总池的 10%），则获得 20 份 shares（占总 shares 的 10%）。  此时： actualShib 是100 SHIB
            // 这里的 “10% 占比” 是 “数量比例”（注入的 SHIB 占总 SHIB 的 10%，注入的 USDT 占总 USDT 的 10%）
            // 新资金注入会让老用户的 “相对占比” 下降，但 “绝对权益价值” 会随总池增长而水涨船高（除非资产价格下跌）。
            // 这和现实中 “投资基金” 的逻辑一致 —— 新资金进入会稀释老投资者的占比，但基金规模变大后，老投资者的资产也会跟着增值。
            // 后续有用户注入了以后，份额数量不变  但是占比变了  因为totalLiquidityShares变大了
            shares = (actualShib * totalLiquidityShares) / totalShib;
        }

        require(shares > 0, "Invalid liquidity amount");

        // 转移实际注入的SHIB（并退回超额部分）
        _transfer(msg.sender, address(this), actualShib);
        if (shibAmount > actualShib) {
            // 退回超额SHIB（从合约转回用户）
            _transfer(address(this), msg.sender, shibAmount - actualShib);
        }

        // 转移实际注入的配对代币（并退回超额部分）
        pairedToken.safeTransferFrom(msg.sender, address(this), actualPaired);
        if (pairedTokenAmount > actualPaired) {
            // 退回超额配对代币（从合约转回用户）
            pairedToken.safeTransfer(msg.sender, pairedTokenAmount - actualPaired);
        }

        // 更新份额记录
        liquidityShares[msg.sender] += shares;
        // totalLiquidityShares（总流动性份额）的值会随着用户向资金池注入流动性而增加。  是人为设定的 “权益计数基准”
        // 它本质是 “资金池所有流动性份额的总和”，新用户注入资产时会获得新的份额，因此总份额会累加。
        // 注入的人越多，总份额就越大，就像 “公司发行的股票总数” 会随着增发而增加一样。
        totalLiquidityShares += shares;

        // 发行LP代币（份额凭证）
        liquidityToken._mint(msg.sender, shares);

        // 触发事件（新增实际注入量参数，便于前端追踪）
        emit LiquidityAdded(msg.sender, shibAmount, pairedTokenAmount, actualShib, actualPaired, shares);
        return shares;
    }

    /**
     * @dev 移除流动性（核心功能：用户销毁LP份额，取回对应比例的两种代币）
     * @param shares 要销毁的流动性份额数量（用户需确保持有足够份额）
     * @return shibAmount 取回的SHIB代币数量（按份额比例计算）
     * @return pairedTokenAmount 取回的配对代币数量（按份额比例计算）
     * 安全特性：
     * - 非重入保护（nonReentrant）：防止恶意合约通过递归调用窃取资产
     * - 权限校验：确保用户持有足够份额，避免无效操作
     * 核心逻辑：
     * 1. 校验份额有效性（数量>0且用户持有量充足）
     * 2. 按份额占比计算可取回的两种代币数量
     * 3. 更新份额记录（减少用户个人份额和总份额）
     * 4. 销毁用户持有的LP代币（回收份额凭证）
     * 5. 将对应数量的代币转回用户地址
     */
    function removeLiquidity(uint256 shares) 
        external 
        nonReentrant 
        returns (uint256 shibAmount, uint256 pairedTokenAmount) 
    {
        // 校验份额有效性：必须大于0，且用户持有的份额不小于要销毁的数量
        require(shares > 0 && liquidityShares[msg.sender] >= shares, "Invalid share amount");
        
        // 获取当前流动性池中的两种代币储备量（用于计算取回数量）
        uint256 totalShib = balanceOf(address(this)); // 池内SHIB总数量
        uint256 totalPaired = pairedToken.balanceOf(address(this)); // 池内配对代币总数量
        
        // 按份额占比计算可取回的代币数量：
        // 取回的SHIB = （用户销毁的份额 / 总份额）× 池内SHIB总量
        shibAmount = (shares * totalShib) / totalLiquidityShares;
        // 取回的配对代币 = （用户销毁的份额 / 总份额）× 池内配对代币总量
        pairedTokenAmount = (shares * totalPaired) / totalLiquidityShares;
        
        // 更新流动性份额记录：
        liquidityShares[msg.sender] -= shares; // 减少用户个人持有的份额
        totalLiquidityShares -= shares; // 减少总流动性份额（总份额随销毁减少）
        
        // 销毁用户持有的LP代币（份额凭证失效，避免重复使用）
        liquidityToken._burn(msg.sender, shares);
        
        // 将计算好的代币转回用户：
        _transfer(address(this), msg.sender, shibAmount); // 转移SHIB
        pairedToken.safeTransfer(msg.sender, pairedTokenAmount); // 转移配对代币（安全转账）
        
        // 触发事件：记录移除操作（便于前端追踪和链下数据分析）
        emit LiquidityRemoved(msg.sender, shibAmount, pairedTokenAmount, shares);
        return (shibAmount, pairedTokenAmount);
    }
 

    function getLiquidityPoolStatus() 
        external 
        view 
        returns (uint256 shibReserve, uint256 pairedTokenReserve, uint256 totalShares) 
    {
        return (balanceOf(address(this)), pairedToken.balanceOf(address(this)), totalLiquidityShares);
    }


    /**
     * @dev 查询用户的流动性资产信息（供用户查看自身持仓详情）
     * @param user 目标用户地址（需查询的用户）
     * @return shares 用户持有的流动性份额数量（LP份额）
     * @return shibValue 份额对应的SHIB资产价值（当前可提取的SHIB数量）
     * @return pairedTokenValue 份额对应的配对代币资产价值（当前可提取的配对代币数量）
     * 核心逻辑：
     * 1. 先获取用户持有的份额数量
     * 2. 若总份额>0（池内有资产），按份额占比计算对应资产价值
     * 3. 若总份额=0（池内无资产），资产价值默认返回0
     */
    function getUserLiquidity(address user) 
        external 
        view 
        returns (uint256 shares, uint256 shibValue, uint256 pairedTokenValue) 
    {
        // 获取用户当前持有的流动性份额（直接从状态变量读取）
        shares = liquidityShares[user];
        
        // 仅当总份额>0时计算资产价值（避免除以0错误）
        if (totalLiquidityShares > 0) {
            uint256 totalShib = balanceOf(address(this)); // 池内SHIB总数量
            uint256 totalPaired = pairedToken.balanceOf(address(this)); // 池内配对代币总数量
            
            // 份额对应的SHIB价值 = （用户份额 / 总份额）× 池内SHIB总量
            shibValue = (shares * totalShib) / totalLiquidityShares;
            // 份额对应的配对代币价值 = （用户份额 / 总份额）× 池内配对代币总量
            pairedTokenValue = (shares * totalPaired) / totalLiquidityShares;
        }
        // 若总份额=0，shibValue和pairedTokenValue默认返回0（无需额外处理）
    }
}