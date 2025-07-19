// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

// 一个mapping来存储候选人的得票数
// 一个vote函数，允许用户投票给某个候选人
// 一个getVotes函数，返回某个候选人的得票数
// 一个resetVotes函数，重置所有候选人的得票数
contract  Voting{
    mapping(address => uint256) public voteMapping;
    address[] public candidates;
    
    function vote(address addr) public {
        if (voteMapping[addr] == 0) {
            candidates.push(addr);
        }
        uint256 count = voteMapping[addr];
        count++;
        voteMapping[addr] = count;
    }
    
    function resetVotes() public {
        for (uint256 i = 0; i < candidates.length; i++) {
            voteMapping[candidates[i]] = 0;
        }
    }
  function getVotes(address  addr) public view returns (uint256) {
        return voteMapping[addr];
    }
}