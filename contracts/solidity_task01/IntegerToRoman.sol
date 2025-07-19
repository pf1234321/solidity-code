// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract IntegerToRoman {
    /**
     * @dev 将整数转换为罗马数字
     * @param num 待转换的整数，范围 1 到 3999
     * @return 对应的罗马数字字符串
     */
    function intToRoman(uint256 num) public pure returns (string memory) {
        require(num > 0 && num < 4000, "Number must be between 1 and 3999");
        
        uint256[] memory values = new uint256[](13);
        values[0] = 1000;
        values[1] = 900;
        values[2] = 500;
        values[3] = 400;
        values[4] = 100;
        values[5] = 90;
        values[6] = 50;
        values[7] = 40;
        values[8] = 10;
        values[9] = 9;
        values[10] = 5;
        values[11] = 4;
        values[12] = 1;
        
        string[] memory symbols = new string[](13);
        symbols[0] = "M";
        symbols[1] = "CM";
        symbols[2] = "D";
        symbols[3] = "CD";
        symbols[4] = "C";
        symbols[5] = "XC";
        symbols[6] = "L";
        symbols[7] = "XL";
        symbols[8] = "X";
        symbols[9] = "IX";
        symbols[10] = "V";
        symbols[11] = "IV";
        symbols[12] = "I";
        
        bytes memory result = new bytes(16); // 最大 Roman 数字长度为 15 字符
        uint256 position = 0;
        
        for (uint256 i = 0; i < values.length; i++) {
            while (num >= values[i]) {
                bytes memory currentSymbol = bytes(symbols[i]);
                for (uint256 j = 0; j < currentSymbol.length; j++) {
                    result[position] = currentSymbol[j];
                    position++;
                }
                num -= values[i];
            }
        }
        
        // 截取实际使用的长度
        bytes memory finalResult = new bytes(position);
        for (uint256 i = 0; i < position; i++) {
            finalResult[i] = result[i];
        }
        
        return string(finalResult);
    }
}    