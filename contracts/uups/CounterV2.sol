// contracts/CounterV2.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract CounterV2 is  Initializable,UUPSUpgradeable, OwnableUpgradeable {
    uint256 public count;
    string public version; // 新增状态变量，展示升级兼容性

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
        __UUPSUpgradeable_init();
        __Ownable_init();
        count = 0;
        version = "V2";
    }

    function increment() external {
        count += 1;
    }

    function getCount() external view returns (uint256) {
        return count;
    }

    // 新增功能
    function decrement() external {
        require(count > 0, "Count cannot be negative");
        count -= 1;
    }

    // 获取版本信息
    function getVersion() external view returns (string memory) {
        return version;
    }

    // UUPS 代理必须实现的内部函数，用于授权升级
    function _authorizeUpgrade(address newImplementation)    internal    onlyOwner  override {}
}    