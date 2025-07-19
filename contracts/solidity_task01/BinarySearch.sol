pragma solidity ^0.8.0;

contract BinarySearch {
    /**
     * @dev 在有序数组中查找目标值的索引
     * @param arr 有序数组
     * @param target 目标值
     * @return 如果找到，返回目标值的索引；否则返回 type(uint256).max 表示未找到
     */
    function search(uint256[] memory arr, uint256 target) public pure returns (uint256) {
        uint256 left = 0;
        uint256 right = arr.length;
        
        while (left < right) {
            uint256 mid = left + (right - left) / 2;
            
            if (arr[mid] == target) {
                return mid;
            } else if (arr[mid] < target) {
                left = mid + 1;
            } else {
                right = mid;
            }
        }
        // 未找到目标值
        return type(uint256).max;
    }
}
    