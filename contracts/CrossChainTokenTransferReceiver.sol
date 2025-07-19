// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// 引入 Chainlink CCIP 跨链通信相关合约和库
import "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
// 引入 OpenZeppelin 的 ERC20 接口和安全操作库
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// 跨链 Token 转账接收方合约，继承自 Chainlink 的 CCIPReceiver
contract CrossChainTokenTransferReceiver is CCIPReceiver {
    // 使用 SafeERC20 库，增强 IERC20 的安全操作
    using SafeERC20 for IERC20;
    
    // 事件：记录每次跨链接收到 Token 的详细信息
    event TokensReceived(
        bytes32 indexed messageId,           // 跨链消息ID
        uint64 indexed sourceChainSelector,  // 源链的 ChainSelector
        address sender,                      // 源链发送者地址
        address token,                       // 接收到的 ERC20 Token 地址
        uint256 tokenAmount                  // 接收到的 Token 数量
    );

    // 构造函数，部署时传入 CCIP 路由器地址，初始化父合约
    // Chainlink CCIP 路由器地址（Router Address）是指Chainlink 跨链互操作协议
    // （CCIP, Cross-Chain Interoperability Protocol）
    // 网络上的一个智能合约地址，它负责在不同区块链之间路由和转发跨链消息与资产。
    constructor(address router) CCIPReceiver(router) {}
    
    /**
     * @notice 接收来自源链的 Token 并转发给目标接收者
     * @param message CCIP 跨链消息体，包含发送者、接收者、Token 信息等
     */
    function _ccipReceive(
        Client.Any2EVMMessage memory message
    ) internal override {
        // 1. 解析消息中的发送者地址（源链发起合约地址）
        // 把 CCIP 跨链消息中的 sender 字段（字节数组）解码成以太坊地址类型，并赋值给变量 sender
        address sender = abi.decode(message.sender, (address));
        // 2. 获取源链的 ChainSelector（唯一标识源链）
        uint64 sourceChainSelector = message.sourceChainSelector;
        
        // 3. 遍历所有接收到的 Token（支持一次接收多种 Token）
        for (uint256 i = 0; i < message.tokenAmounts.length; i++) {
            Client.EVMTokenAmount memory tokenAmount = message.tokenAmounts[i];
            
            // 4. 将 Token 转账给消息指定的接收者（目标链上的用户/合约）
            IERC20(tokenAmount.token).safeTransfer(
                abi.decode(message.receiver, (address)), // 解析目标接收者地址
                tokenAmount.amount
            );
            
            // 5. 记录事件，便于链上追踪
            emit TokensReceived(
                message.messageId,
                sourceChainSelector,
                sender,
                tokenAmount.token,
                tokenAmount.amount
            );
        }
    }
}