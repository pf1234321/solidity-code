// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title 逻辑合约接口
 * @dev 定义逻辑合约必须实现的函数
 */
interface ILogic {
    /**
     * @dev 初始化函数（替代构造函数）
     * @param owner 合约所有者地址
     */
    function initialize(address owner) external;
    
    /**
     * @dev 获取存储的值
     * @return 当前存储的值
     */
    function value() external view returns (uint256);
    
    /**
     * @dev 设置存储的值
     * @param newValue 新值
     */
    function setValue(uint256 newValue) external;
    
    /**
     * @dev 模拟与代理合约同名的函数
     * 注意：这里参数不同，避免函数签名冲突
     * @param level 升级等级
     * @return 升级成功消息
     */
    function upgradeTo(uint256 level) external returns (string memory);
}