// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TransparentProxy.sol";
import "./Logic.sol";

/**
 * @title 透明代理演示合约
 * @dev 展示透明代理的工作流程和使用方式
 */
contract TransparentProxyDemo {
    TransparentProxy public proxy;      // 透明代理合约实例
    Logic public logic1;                // 第一个逻辑合约版本
    Logic public logic2;                // 第二个逻辑合约版本
    address public admin;               // 管理员地址
    
    /**
     * @dev 构造函数：部署代理合约和逻辑合约
     */
    constructor() {
        admin = msg.sender;
        
        // 部署初始逻辑合约
        logic1 = new Logic();
        logic1.initialize(admin);
        
        // 部署代理合约并关联逻辑合约
        proxy = new TransparentProxy(admin, address(logic1));
        
        // 部署新版本逻辑合约（用于升级演示）
        logic2 = new Logic();
        logic2.initialize(admin);

        // proxy.implementation();
    }
    
    /**
     * @dev 管理员升级代理合约的逻辑实现
     */
    function upgradeProxy() external {
        require(msg.sender == admin, "Not admin");
        // 注意：这里调用的是代理合约的upgradeTo函数
        // 由于msg.sender是管理员，会直接执行代理合约的upgradeTo
        ILogic(address(proxy)).upgradeTo(address(logic2));
    }
    
    /**
     * @dev 管理员设置值（直接调用代理合约）
     * @param newValue 新值
     */
    function adminSetValue(uint256 newValue) external {
        require(msg.sender == admin, "Not admin");
        // 管理员调用代理合约的setValue
        ILogic(address(proxy)).setValue(newValue);
    }
    
    /**
     * @dev 普通用户设置值（通过代理合约调用逻辑合约）
     * @param newValue 新值
     */
    function userSetValue(uint256 newValue) external {
        // 普通用户调用代理合约的setValue
        // 由于msg.sender不是管理员，会通过fallback转发到逻辑合约
        ILogic(address(proxy)).setValue(newValue);
    }
    
    /**
     * @dev 获取当前存储的值
     * @return 当前值
     */
    function getValue() external view returns (uint256) {
        return ILogic(address(proxy)).value();
    }
}