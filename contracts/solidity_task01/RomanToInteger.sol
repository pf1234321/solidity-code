// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract RomanToInteger {
    /**
     * @dev 将罗马数字转换为整数
     * @param s 待转换的罗马数字字符串
     * @return 对应的整数值
     */
    function romanToInt(string memory s) public pure returns (uint256) {
        bytes memory roman = bytes(s);
        uint256 result = 0;
        uint256 prevValue = 0;
        
        for (uint256 i = roman.length; i > 0; i--) {
            uint256 currentValue = getValue(roman[i-1]);
            
            if (currentValue < prevValue) {
                result -= currentValue;
            } else {
                result += currentValue;
            }
            
            prevValue = currentValue;
        }
        
        return result;
    }
    
    function getValue(bytes1 char) internal pure returns (uint256) {
        if (char == 'I') return 1;
        if (char == 'V') return 5;
        if (char == 'X') return 10;
        if (char == 'L') return 50;
        if (char == 'C') return 100;
        if (char == 'D') return 500;
        if (char == 'M') return 1000;
        revert("Invalid Roman character");
    }
}    