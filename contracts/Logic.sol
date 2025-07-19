// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "./ILogic.sol";

/**
 * @title 逻辑合约实现
 * @dev 包含实际业务逻辑的合约，通过代理合约调用
 */
contract Logic is ILogic {
    uint256 private _value;     // 存储的值
    address private _owner;     // 合约所有者
    
    /**
     * @dev 初始化函数（替代构造函数）
     * 可升级合约不能使用构造函数，需用初始化函数
     * @param owner 合约所有者地址
     */
    function initialize(address owner) external override {
        require(_owner == address(0), "Logic: already initialized");
        _owner = owner;
    }
    
    /**
     * @dev 获取存储的值
     * @return 当前存储的值
     */
    function value() external view override returns (uint256) {
        return _value;
    }
    
    /**
     * @dev 设置存储的值
     * @param newValue 新值
     */
    function setValue(uint256 newValue) external override {
        require(msg.sender == _owner, "Logic: not owner");
        _value = newValue;
    }
    
    /**
     * @dev 模拟与代理合约同名的函数
     * 注意：参数与代理合约的upgradeTo不同，避免冲突
     * @param level 升级等级
     * @return 升级成功消息
     */
    function upgradeTo(uint256 level) external override returns (string memory) {
        require(msg.sender == _owner, "Logic: not owner");
        return string(abi.encodePacked("Upgraded to level: ", Strings.toString(level)));
    }
}