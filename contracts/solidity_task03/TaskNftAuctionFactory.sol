// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TaskAuction.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

contract NftAuctionFactory {
    // immutable 是 Solidity 里的一个关键字，用来修饰状态变量，表示该变量只能在合约的构造函数里赋值一次，之后就不能再修改。
    // immutable = “部署时定值，之后永不变，且比普通变量更省gas”。  类似Java中的final
    address public immutable implementation; // TaskAuction实现合约地址
    address[] public auctions;
    mapping(uint256 => address) public auctionMap; // tokenId => auction合约地址

    event AuctionCreated(address indexed auctionAddress, uint256 tokenId);

    constructor(address _implementation) {
        implementation = _implementation;
    }

    function createAuction(
        uint256 duration,
        uint256 startPrice,
        address nftContractAddress,
        uint256 tokenId
    ) external returns (address) {
        // 创建clone Clones = “批量复制合约的高效工厂工具”。
        // 这行代码就是“用 implementation 作为模板，快速复制出一个新合约，并拿到它的地址”。
        address clone = Clones.clone(implementation);
        // 初始化
        TaskAuction(clone).initialize(
            msg.sender,
            duration,
            startPrice,
            nftContractAddress,
            tokenId
        );
        auctions.push(clone);
        auctionMap[tokenId] = clone;

        emit AuctionCreated(clone, tokenId);
        return clone;
    }

    function getAuctions() external view returns (address[] memory) {
        return auctions;
    }

    function getAuction(uint256 tokenId) external view returns (address) {
        return auctionMap[tokenId];
    }
}
