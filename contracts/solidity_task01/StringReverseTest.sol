// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

 

// 测试合约
contract StringReverseTest {
     /**
     * 反转纯英文字符串（仅ASCII字符）
     * 输入："abcde"
     * 输出："edcba"
     */
    function reverseAscii(string memory str) internal pure returns (string memory) {
        bytes memory byteArray = bytes(str);
        uint length = byteArray.length;
        
        // 处理空字符串
        if (length == 0) return "";
        
        for (uint i = 0; i < length / 2; i++) {
            bytes1 temp = byteArray[i];
            byteArray[i] = byteArray[length - 1 - i];
            byteArray[length - 1 - i] = temp;
        }
        
        return string(byteArray);
    }

    // function testReverse() public pure returns (string memory) {
    //     string memory test1 = "abcde";
    //     return reverseAscii(test1);
    // }
    
}    