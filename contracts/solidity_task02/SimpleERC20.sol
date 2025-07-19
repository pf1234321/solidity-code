// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 一个简单的 ERC20 代币合约实现，支持转账、授权、代扣和增发功能
contract SimpleERC20 {
    // 代币名称
    string public name;
    // 代币符号
    string public symbol;
    // 代币小数位数
    uint8 public decimals;
    // 代币总供应量
    uint256 public totalSupply;
    
    // 账户余额映射：地址 => 余额
    mapping(address => uint256) public balanceOf;
    // 授权额度映射：授权人 => (被授权人 => 授权额度)
    mapping(address => mapping(address => uint256)) public allowance;
    
    // 合约所有者地址
    address public owner;
    
    // 转账事件
    event Transfer(address indexed from, address indexed to, uint256 value);
    // 授权事件
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    /**
     * @dev 构造函数，初始化代币信息和初始供应量
     * @param _name 代币名称
     * @param _symbol 代币符号
     * @param _decimals 小数位数
     * @param _initialSupply 初始供应量（不含小数）
     */
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _initialSupply
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _initialSupply * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply; // 初始供应量分配给合约部署者
        owner = msg.sender;
        
        emit Transfer(address(0), msg.sender, totalSupply);
    }
    
    /**
     * @dev 转账函数，将代币从调用者转给指定地址
     * @param to 接收方地址
     * @param value 转账数量
     * @return 是否转账成功
     */
    function transfer(address to, uint256 value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }
    
    /**
     * @dev 授权函数，允许 spender 代替调用者花费指定数量的代币
     * @param spender 被授权地址
     * @param value 授权额度
     * @return 是否授权成功
     */
    function approve(address spender, uint256 value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }
    
    /**
     * @dev 代扣转账函数，允许 spender 从 from 地址转账到 to 地址
     * @param from 代币来源地址
     * @param to 接收方地址
     * @param value 转账数量
     * @return 是否转账成功
     */
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool) {
        require(allowance[from][msg.sender] >= value, "Allowance exceeded");
        _transfer(from, to, value);
        _approve(from, msg.sender, allowance[from][msg.sender] - value);
        return true;
    }
    
    /**
     * @dev 增发代币函数，仅限合约所有者调用
     * @param to 接收增发代币的地址
     * @param value 增发数量
     */
    function mint(address to, uint256 value) external {
        require(msg.sender == owner, "Only owner can mint");
        _mint(to, value);
    }
    
    /**
     * @dev 内部转账函数，实现实际的余额转移和事件触发
     * @param from 发送方地址
     * @param to 接收方地址
     * @param value 转账数量
     */
    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal {
        require(from != address(0), "Transfer from zero address");
        require(to != address(0), "Transfer to zero address");
        require(balanceOf[from] >= value, "Insufficient balance");
        
        balanceOf[from] -= value;
        balanceOf[to] += value;
        
        emit Transfer(from, to, value);
    }
    
    /**
     * @dev 内部授权函数，实现授权额度的设置和事件触发
     * @param _owner 授权人地址
     * @param spender 被授权人地址
     * @param value 授权额度
     */
    function _approve(
        address _owner,
        address spender,
        uint256 value
    ) internal {
        require(_owner != address(0), "Approve from zero address");
        require(spender != address(0), "Approve to zero address");
        
        allowance[_owner][spender] = value;
        emit Approval(_owner, spender, value);
    }
    
    /**
     * @dev 内部增发函数，实现代币的增发和事件触发
     * @param to 接收增发代币的地址
     * @param amount 增发数量
     */
    function _mint(address to, uint256 amount) internal {
        require(to != address(0), "Mint to zero address");
        
        totalSupply += amount;
        balanceOf[to] += amount;
        
        emit Transfer(address(0), to, amount);
    }
}    