pragma solidity ^0.8.0;

contract MergeSortedArrays {
    /**
     * @dev 合并两个有序数组为一个新的有序数组
     * @param arr1 第一个有序数组
     * @param arr2 第二个有序数组
     * @return 合并后的有序数组
     */
    function merge(uint256[] memory arr1, uint256[] memory arr2) public pure returns (uint256[] memory) {
        uint256 m = arr1.length;
        uint256 n = arr2.length;
        uint256[] memory mergedArray = new uint256[](m + n);
        // 先复制 arr1
        for (uint256 i = 0; i < m; i++) {
            mergedArray[i] = arr1[i];
        }
        // 再添加 arr2
        for (uint256 j = 0; j < n; j++) {
            mergedArray[m + j] = arr2[j];
        }
        // 冒泡排序
        uint256 len = m + n;
        for (uint256 i = 0; i < len; i++) {
            for (uint256 j = 0; j < len - 1 - i; j++) {
                if (mergedArray[j] > mergedArray[j + 1]) {
                    uint256 temp = mergedArray[j];
                    mergedArray[j] = mergedArray[j + 1];
                    mergedArray[j + 1] = temp;
                }
            }
        }
        return mergedArray;
    }
}