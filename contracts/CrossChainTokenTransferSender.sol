// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// 引入 Chainlink CCIP 跨链通信相关合约和库
import "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPSender.sol";
import "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
// 引入 OpenZeppelin 的 ERC20 接口和安全操作库
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// 跨链 Token 转账发送方合约，继承自 Chainlink 的 CCIPSender
contract CrossChainTokenTransferSender is CCIPSender {
    // 使用 SafeERC20 库，增强 IERC20 的安全操作
    using SafeERC20 for IERC20;

    // 事件：记录每次跨链发送 Token 的详细信息
    event TokensSent(
        bytes32 indexed messageId, // 跨链消息ID
        uint64 indexed destinationChainSelector, // 目标链的 ChainSelector
        address receiver, // 目标链接收者地址
        address token, // 发送的 ERC20 Token 地址
        uint256 tokenAmount, // 发送的 Token 数量
        address feeToken, // 支付手续费的 Token 地址（0 表示原生币）
        uint256 fees // 实际支付的手续费
    );

    // 构造函数，部署时传入 CCIP 路由器地址， 初始化当前合约的父类部分。
    // Chainlink CCIP 路由器地址（Router Address）是指Chainlink 跨链互操作协议
    // （CCIP, Cross-Chain Interoperability Protocol）
    // 网络上的一个智能合约地址，它负责在不同区块链之间路由和转发跨链消息与资产。
    constructor(address router) CCIPSender(router) {}

    /**
     * @notice 发送ERC20 Token到目标链
     * @param destinationChainSelector 目标链的 ChainSelector（唯一标识目标链）
     * @param receiver 目标链上的接收合约地址
     * @param token ERC20 Token 的合约地址
     * @param amount 发送的 Token 数量
     * @return messageId 跨链消息ID
     */
    function sendToken(
        uint64 destinationChainSelector,  // 2131427466778448014
        address receiver,  // a  --》 b  address
        address token,  //  token   
        uint256 amount
    ) external returns (bytes32 messageId) {
        // 1. 将用户的 Token 转账到本合约，确保合约拥有足够 Token
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        // 2. 授权路由器可以转移本合约的 Token（为跨链转账做准备）
        // router：你部署合约时传入的地址（address），只是一个普通地址。
        // i_router：父合约里根据 router 地址创建的合约对象，可以直接调用 Router 的合约方法。
        // 一句话理解：
        // router 是你传进来的地址，i_router 是用这个地址生成的 Router 合约实例，供合约内部调用。
        IERC20(token).safeApprove(address(i_router), amount);

        // 3. 构造 CCIP 跨链消息中的 Token 数组（这里只发送一种 Token）
        //   struct EVMTokenAmount {
        //       address token;   // ERC20 Token 的合约地址
        //       uint256 amount;  // Token 数量
        //   }
        Client.EVMTokenAmount[]
            memory tokenAmounts = new Client.EVMTokenAmount[](1);
        tokenAmounts[0] = Client.EVMTokenAmount({token: token, amount: amount});

        // 4. 构造 CCIP 跨链消息体
        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(receiver), // 目标链接收者地址，ABI 编码
            data: "", // 可选数据，这里为空
            tokenAmounts: tokenAmounts, // 要发送的 Token 信息
            extraArgs: "", // 额外参数，这里为空
            feeToken: address(0) // 使用原生币（如ETH）支付手续费
        });

        // 5. 获取跨链消息所需的手续费估算
        uint256 fee = i_router.getFee(destinationChainSelector, message);

        // 6. 发送跨链消息，返回消息ID
        messageId = i_router.ccipSend(destinationChainSelector, message);

        // 7. 记录事件，便于链上追踪
        emit TokensSent(
            messageId,
            destinationChainSelector,
            receiver,
            token,
            amount,
            address(0), // 手续费 Token（0 表示原生币）
            fee
        );
    }
}
