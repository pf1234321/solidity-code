// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "hardhat/console.sol";

contract BeggingContract {
    // 记录每个捐赠者的地址和捐赠金额
    mapping(address => uint256) public donationsRel;
    // 记录合约所有者的地址
    address public owner;
    // 记录总捐赠金额
    uint256 public totalDonations;

    // 记录所有的捐赠者
    address[] public donations;
    // 记录所有的捐赠金额
    uint256[] amounts;
    // 时间限制：添加一个时间限制，只有在特定时间段内才能捐赠。
     uint256 startTime;
     uint256 endTime;

    // 记录捐赠者地址
    constructor() {
        owner = msg.sender;
        // block.timestamp 的单位是秒
        startTime = block.timestamp;
        // 1 小时对应的秒数为 1 × 3600 = 3600 秒。   这里结束时间也可以从构造函数里面传入  我这里写死
        // 我这里写60秒
        endTime = block.timestamp+ 3600;
    }

    event Donation(address donor, uint256 amount);

    function donate() external payable {
        require(block.timestamp<=endTime,"Donation time has expired");
        donationsRel[msg.sender] += msg.value;
        totalDonations += msg.value;
        donations.push(msg.sender);
        amounts.push(msg.value);
        emit Donation(msg.sender, msg.value);
    }

    function withdraw() external payable  {
        require(msg.sender == owner, "Only owner can withdraw");
        uint256 balance = address(this).balance;
        payable(owner).transfer(balance);
        balance = 0;
    }

    receive() external payable {}

    fallback() external payable {}

    function getDonation(address addr) public  view returns (uint256) {
        require(addr != address(0), "error  address");
        return donationsRel[addr];
    }

    function getTopDonation(
        uint256 top
    ) public view returns (address[] memory, uint256[] memory) {
        uint256 count = donations.length;
        if (top > count) top = count;

        // 创建临时数组
        address[] memory donors = new address[](count);
        uint256[] memory values = new uint256[](count);

        // 复制原始数据
        for (uint256 i = 0; i < count; i++) {
            donors[i] = donations[i];
            values[i] = amounts[i];
        }

        // 冒泡排序（降序），同步交换两个数组
        for (uint256 i = 0; i < count - 1; i++) {
            for (uint256 j = 0; j < count - i - 1; j++) {
                if (values[j] < values[j + 1]) {
                    // 交换金额
                    uint256 tempValue = values[j];
                    values[j] = values[j + 1];
                    values[j + 1] = tempValue;

                    // 同步交换地址
                    address tempAddr = donors[j];
                    donors[j] = donors[j + 1];
                    donors[j + 1] = tempAddr;
                }
            }
        }

        // 返回前 top 个结果
        address[] memory topDonors = new address[](top);
        uint256[] memory topValues = new uint256[](top);
        for (uint256 i = 0; i < top; i++) {
            topDonors[i] = donors[i];
            topValues[i] = values[i];
        }

        return (topDonors, topValues);
    }
}
