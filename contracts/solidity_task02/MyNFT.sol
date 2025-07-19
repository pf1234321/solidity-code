// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyNFT is ERC721, Ownable {
    
    uint256 private _tokenIdCounter;
  
    // 存储每个 token 的 URI
    mapping(uint256 => string) private _tokenURIs;
    
    // 合约名称和符号
    constructor() ERC721("MyNFT", "MNFT") Ownable(msg.sender) {}
    
    // 铸造新NFT的函数，仅限合约所有者调用
    function safeMint(address to, string memory uri) public onlyOwner {
         uint256 tokenId = _tokenIdCounter;
        // 计数器加一，为下一个 NFT 预留新的 tokenId
        _tokenIdCounter++;
        // 安全地铸造（mint）一个 NFT，分配给地址 to，tokenId 为当前值
        _safeMint(to, tokenId);
        // 为编号为 tokenId 的 NFT 设置元数据的 URI 地址，让每个 NFT 都能有独立的描述信息（如图片、属性等）。
        _setTokenURI(tokenId, uri);
    }
    
    // 设置 token URI
    function _setTokenURI(uint256 tokenId, string memory uri) internal {
        _tokenURIs[tokenId] = uri;
    }
    
    // 获取 token URI
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        string memory uri = _tokenURIs[tokenId];
        require(bytes(uri).length > 0, "URI query for nonexistent token");
        return uri;
    }
 
}