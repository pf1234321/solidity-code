// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/StorageSlot.sol";
import "@openzeppelin/contracts/utils/Address.sol";


/**
 * @title 透明代理合约
 * @dev 实现EIP-1967标准的可升级代理，通过角色分离解决函数调用冲突
 * 管理员可直接调用代理合约的管理函数，普通用户调用会被转发到逻辑合约
 */
contract TransparentProxy {
    // 存储槽定义（遵循EIP-1967标准） _ADMIN_SLOT“当前管理员的存储槽位置”   _IMPLEMENTATION_SLOT“实现合约的存储槽位置”。
    // 使用特定哈希值计算存储槽位置，避免与逻辑合约的存储冲突
    bytes32 private constant _ADMIN_SLOT = bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1);
    bytes32 private constant _IMPLEMENTATION_SLOT = bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1);
    
    // 事件：记录重要操作
    event AdminChanged(address previousAdmin, address newAdmin);
    event Upgraded(address indexed implementation);
    
    /**
     * @dev 构造函数：初始化代理合约
     * @param _admin 代理合约管理员地址
     * @param _implementation 初始逻辑合约地址
     */
    constructor(address _admin, address _implementation) {
        _setAdmin(_admin);
        _setImplementation(_implementation);
    }
    
    // ===== 管理员管理函数 =====
    
    /**
     * @dev 获取当前管理员地址
     * @return 管理员地址
     */
    function admin() external view returns (address) {
        return _getAdmin();
    }
    
    /**
     * @dev 变更管理员
     * @param newAdmin 新管理员地址
     */
    function changeAdmin(address newAdmin) external {
        require(msg.sender == _getAdmin(), "TransparentProxy: caller is not the admin");
        _setAdmin(newAdmin);
        emit AdminChanged(_getAdmin(), newAdmin);
    }
    
    // ===== 合约升级管理函数 =====
    
    /**
     * @dev 升级逻辑合约
     * @param newImplementation 新逻辑合约地址
     */
    function upgradeTo(address newImplementation) external {
        require(msg.sender == _getAdmin(), "TransparentProxy: caller is not the admin");
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }
    
    /**
     * @dev 获取当前逻辑合约地址
     * @return 逻辑合约地址
     */
    function implementation() external view returns (address) {
        return _getImplementation();
    }
    
    // ===== 调用转发机制 =====
    
    /**
     * @dev 回退函数：处理所有未定义函数调用
     * 普通用户调用会被转发到逻辑合约
     */
    fallback() external payable {
        _delegate(_getImplementation());
    }
    
    /**
     * @dev 接收ETH的回退函数
     */
    receive() external payable {
        _delegate(_getImplementation());
    }
    
    /**
     * @dev 私有函数：将调用委托给逻辑合约
     * @param implementation 逻辑合约地址
     */
    function _delegate(address implementation) private {
        // 确保管理员不能通过fallback调用逻辑合约
        require(msg.sender != _getAdmin(), "TransparentProxy: admin cannot fallback to implementation");
        assembly {
            // 将调用数据复制到内存
            calldatacopy(0, 0, calldatasize())
            // 使用delegatecall执行逻辑合约的代码，保留当前上下文
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)
            // 复制返回数据
            returndatacopy(0, 0, returndatasize())
            // 根据执行结果返回或回滚
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
    
    // ===== 私有存储管理函数 =====
    
 
    function _getAdmin() private view returns (address adm) {
        bytes32 slot = _ADMIN_SLOT;
        assembly {
            adm := sload(slot)
        }
        return adm;
    }
    
    /**
     * @dev 设置管理员地址
     * @param newAdmin 新管理员地址
     */
    function _setAdmin(address newAdmin) private {
        bytes32 slot = _ADMIN_SLOT;
        assembly {
            sstore(slot, newAdmin)
        }
    }
    
    /**
     * @dev 获取逻辑合约地址
     * @return  impl 逻辑合约地址
     */
    function _getImplementation() private view returns (address impl) {
        bytes32 slot = _IMPLEMENTATION_SLOT;
        assembly {
            impl := sload(slot)
        }
        return impl;
    }
    
    /**
     * @dev 设置逻辑合约地址
     * @param newImplementation 新逻辑合约地址
     */
    function _setImplementation(address newImplementation) private {
        // 验证地址是否为合约
        // require(isContract(newImplementation), "TransparentProxy: new implementation is not a contract");
        // require(Address.isContract(newImplementation), "TransparentProxy: new implementation is not a contract");
        bytes32 slot = _IMPLEMENTATION_SLOT;
        assembly {
            sstore(slot, newImplementation)
        }
    }
}