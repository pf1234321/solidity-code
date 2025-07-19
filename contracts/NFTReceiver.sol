// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract NFTReceiver is IERC721Receiver {
    // 实现ERC721接收接口
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes memory data
    ) external override pure returns (bytes4) {
        // 返回固定的选择器值，表示合约可以处理NFT接收
        return this.onERC721Received.selector;
    }
    
    // 可选：添加一个函数用于将NFT转出合约
    function transferNFT(
        address nftContract,
        uint256 tokenId,
        address to
    ) external {
        IERC721(nftContract).safeTransferFrom(address(this), to, tokenId);
    }
}    