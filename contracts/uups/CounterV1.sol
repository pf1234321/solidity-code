// contracts/CounterV1.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; // 指定Solidity编译器版本

// 引入OpenZeppelin的UUPS可升级合约基类
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
// 引入OpenZeppelin的Ownable合约基类（用于权限管理）
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

// 声明CounterV1合约，继承UUPSUpgradeable和OwnableUpgradeable
contract CounterV1 is  Initializable, UUPSUpgradeable, OwnableUpgradeable {
    uint256 public count; // 公开的计数器变量

    // 构造函数，禁用初始化器，防止直接部署实现合约
    constructor() {
        _disableInitializers(); // 禁用初始化器，防止实现合约被初始化
    }

    // 初始化函数，只能被代理合约调用一次
    function initialize() initializer public {
        __UUPSUpgradeable_init(); // 初始化UUPS可升级模块
        __Ownable_init();         // 初始化Ownable模块，设置合约拥有者
        count = 0;                // 初始化计数器为0
    }

    // 计数器加一的外部函数
    function increment() external {
        count += 1; // 计数器加一
    }

    // 获取当前计数值的外部只读函数
    function getCount() external view returns (uint256) {
        return count; // 返回当前计数值
    }

    // UUPS代理必须实现的内部函数，用于授权升级逻辑合约
    function _authorizeUpgrade(address newImplementation) internal onlyOwner override {}
    // 只有合约拥有者可以升级合约，实现了UUPS的安全要求
}    