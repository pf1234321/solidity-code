// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

contract SigTest {
    function transfer(address to, uint256 amount)  pure public {
        bytes4 expectedSelector = bytes4(
            keccak256("transfer(address,uint256)")
        );
        // 当前函数的选择器：在当前函数内部，msg.sig 表示当前被调用函数的选择器。
        // 手动计算的选择器：使用 bytes4(keccak256("functionName(paramTypes...)")) 计算的选择器与当前函数签名完全一致。
        require(msg.sig == expectedSelector, "Invalid selector"); // 始终通过
        // ...
    }

    receive() external payable {}

    fallback() external payable {
        bytes4 sig = msg.sig;
        if (sig == bytes4(keccak256("deposit()"))) {
            // 执行存款逻辑
        } else if (sig == bytes4(keccak256("withdraw()"))) {
            // 执行取款逻辑
        } else {
            revert("Unsupported function");
        }
    }
}
