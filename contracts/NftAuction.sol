// // SPDX-License-Identifier: SEE LICENSE IN LICENSE
// pragma solidity ^0.8;

// import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
// import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

// // import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

// import "hardhat/console.sol";

// contract NftAuction is Initializable, UUPSUpgradeable {
//     // 结构体
//     struct Auction {
//         // 卖家
//         address seller;
//         // 拍卖持续时间
//         uint256 duration;
//         // 起始价格
//         uint256 startPrice;
//         // 开始时间
//         uint256 startTime;
//         // 是否结束
//         bool ended;
//         // 最高出价者
//         address highestBidder;
//         // 最高价格
//         uint256 highestBid;
//         // NFT合约地址
//         address nftContract;
//         // NFT ID
//         uint256 tokenId;
//         // ETH 是以太坊的“官方货币”，没有合约地址，直接用。
//         // ERC20 代币 是各种项目自己发行的“应用货币”，有合约地址，必须通过合约函数转账。
//         // 参与竞价的资产类型 0x 地址表示eth，其他地址表示erc20
//         // 0x0000000000000000000000000000000000000000 表示eth
//         address tokenAddress;
//     }

//     // 状态变量 auctions：所有拍卖的存储，key 是自增的拍卖ID。
//     mapping(uint256 => Auction) public auctions;
//     // 下一个拍卖ID
//     uint256 public nextAuctionId;
//     // 管理员地址
//     address public admin;

//     // AggregatorV3Interface internal priceETHFeed;
//     // 记录每种资产（ETH、USDC等）对应的 Chainlink 预言机地址。
//     mapping(address => AggregatorV3Interface) public priceFeeds;

//     // initialize：合约初始化函数，设置管理员。
//     function initialize() public initializer {
//         admin = msg.sender;
//     }

//     // 设置某个资产的 Chainlink 预言机地址（如 ETH/USD、USDC/USD）。 USD（美元）是现实世界的法币
//     // 为某个币种（ETH 或 ERC20）设置对应的 Chainlink 预言机地址，用于后续价格查询。
//     // ETH 的设置示例 setPriceFeed(
//     //     address(0), // ETH 用全0地址
//     //     0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419 // ETH/USD 预言机地址
//     // );
//     // ERC20 代币（如 USDC）的设置示例
//     // USDC 合约地址：USDC 官方在以太坊主网部署的合约地址，所有 USDC 代币都在这里。
//     // setPriceFeed(
//     //     0xA0b86991c6218b36c1d19d4a2e9eb0ce3606eb48, // USDC 合约地址
//     //     0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6  // USDC/USD 预言机地址
//     // );
//     function setPriceFeed(address tokenAddress, address _priceFeed) public {
//         priceFeeds[tokenAddress] = AggregatorV3Interface(_priceFeed);
//     }

//     // ETH -> USD => 1766 7512 1800 => 1766.75121800
//     // USDC -> USD => 9999 4000 => 0.99994000
//     function getChainlinkDataFeedLatestAnswer(
//         address tokenAddress
//     ) public view returns (int) {
//         AggregatorV3Interface priceFeed = priceFeeds[tokenAddress];
//         // prettier-ignore
//         (
//             /* uint80 roundId */,
//             int256 answer,
//             /*uint256 startedAt*/,
//             /*uint256 updatedAt*/,
//             /*uint80 answeredInRound*/
//         ) = priceFeed.latestRoundData();
//         return answer;
//     }

//     // nftAuction.createAuction(
//     //     3600, // 持续时间：1小时（单位：秒）
//     //     1 ether, // 起拍价：1 ETH
//     //     0x1234567890abcdef1234567890abcdef12345678, // NFT 合约地址
//     //     42 // NFT 的 tokenId
//     // );
//     // 创建拍卖
//     // 只有管理员可以创建拍卖。
//     // 检查参数合法性。
//     // 将 NFT 转移到合约地址托管。
//     // 初始化一个新的 Auction 结构体，存入 auctions，并自增 nextAuctionId。
//     function createAuction(
//         uint256 _duration,
//         uint256 _startPrice,
//         address _nftAddress,
//         uint256 _tokenId
//     ) public {
//         // 只有管理员可以创建拍卖
//         require(msg.sender == admin, "Only admin can create auctions");
//         // 检查参数
//         require(_duration >= 10, "Duration must be greater than 10s");
//         require(_startPrice > 0, "Start price must be greater than 0");

//         // 转移NFT到合约   - 把 _nftAddress 这个地址上的合约，当作一个 ERC-721 合约来用，
//         //  - 调用它的 safeTransferFrom 方法，把 NFT 从 msg.sender 转到合约自己。
//         // IERC721(_nftAddress).approve(address(this), _tokenId);
//         // 含义：被拍卖 NFT 的合约地址。 作用：告诉合约是哪一个 NFT 合约（比如某个 ERC721 合约）下的 NFT 被拍卖。
//         IERC721(_nftAddress).safeTransferFrom(
//             msg.sender,
//             address(this),
//             _tokenId
//         );

//         auctions[nextAuctionId] = Auction({
//             seller: msg.sender,
//             duration: _duration,
//             startPrice: _startPrice,
//             ended: false,
//             highestBidder: address(0),
//             highestBid: 0,
//             startTime: block.timestamp,
//             nftContract: _nftAddress,
//             tokenId: _tokenId,
//             tokenAddress: address(0)
//         });

//         nextAuctionId++;
//     }

// // await nftAuction.placeBid(
// //     auctionId, // 0
// //     bidAmount, // 1000000000000000000
// //     "0x0000000000000000000000000000000000000000", // ETH用全0地址
// //     { value: bidAmount } // 这里必须带上ETH
// // );


// // const auctionId = 0;
// // const bidAmount = ethers.utils.parseUnits("100", 6); // 100 USDC = 100000000
// // const usdcAddress = "0xA0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"; // USDC主网地址
// // // 先授权
// // await usdcContract.approve(nftAuction.address, bidAmount);
// // // 再出价
// // await nftAuction.placeBid(
// //     auctionId, // 0
// //     bidAmount, // 100000000
// //     usdcAddress // USDC合约地址
// //     // 不需要value参数
// // );

//     // 买家参与买单
//     // TODO: ERC20 也能参加
//     function placeBid(
//         uint256 _auctionID,
//         uint256 amount,
//         address _tokenAddress
//     ) external payable {
//         // 统一的价值尺度
//         // ETH 是 ？ 美金
//         // 1个 USDC 是 ？ 美金
//         Auction storage auction = auctions[_auctionID];
//         // 判断当前拍卖是否结束
//         require(
//             !auction.ended &&
//                 auction.startTime + auction.duration > block.timestamp,
//             "Auction has ended"
//         );
//         // 判断出价是否大于当前最高出价
//         uint payValue;
//         if (_tokenAddress != address(0)) {
//             // 处理 ERC20
//             // 检查是否是 ERC20 资产
//             payValue =
//                 amount *
//                 uint(getChainlinkDataFeedLatestAnswer(_tokenAddress));
//         } else {
//             // 处理 ETH
//             amount = msg.value;
//             payValue =
//                 amount *
//                 uint(getChainlinkDataFeedLatestAnswer(address(0)));
//         }

//         uint startPriceValue = auction.startPrice *
//             uint(getChainlinkDataFeedLatestAnswer(auction.tokenAddress));

//         uint highestBidValue = auction.highestBid *
//             uint(getChainlinkDataFeedLatestAnswer(auction.tokenAddress));

//         require(
//             payValue >= startPriceValue && payValue > highestBidValue,
//             "Bid must be higher than the current highest bid"
//         );

//         // 转移 ERC20 到合约
//         if (_tokenAddress != address(0)) {
//             IERC20(_tokenAddress).transferFrom(
//                 msg.sender,
//                 address(this),
//                 amount
//             );
//         }

//         // 退还前最高价
//         if (auction.highestBid > 0) {
//             if (auction.tokenAddress == address(0)) {
//                 // auction.tokenAddress = _tokenAddress;
//                 payable(auction.highestBidder).transfer(auction.highestBid);
//             } else {
//                 // 退回之前的ERC20
//                 IERC20(auction.tokenAddress).transfer(
//                     auction.highestBidder,
//                     auction.highestBid
//                 );
//             }
//         }

//         auction.tokenAddress = _tokenAddress;
//         auction.highestBid = amount;
//         auction.highestBidder = msg.sender;
//     }

//     // 结束拍卖
//     function endAuction(uint256 _auctionID) external {
//         Auction storage auction = auctions[_auctionID];

//         console.log(
//             "endAuction",
//             auction.startTime,
//             auction.duration,
//             block.timestamp
//         );
//         // 判断当前拍卖是否结束
//         require(
//             !auction.ended &&
//                 (auction.startTime + auction.duration) <= block.timestamp,
//             "Auction has not ended"
//         );
//         // 转移NFT到最高出价者
//         IERC721(auction.nftContract).safeTransferFrom(
//             address(this),
//             auction.highestBidder,
//             auction.tokenId
//         );
//         // 转移剩余的资金到卖家
//         // payable(address(this)).transfer(address(this).balance);
//         auction.ended = true;
//     }

//     function _authorizeUpgrade(address) internal view override {
//         // 只有管理员可以升级合约
//         require(msg.sender == admin, "Only admin can upgrade");
//     }

//     function onERC721Received(
//         address operator,
//         address from,
//         uint256 tokenId,
//         bytes calldata data
//     ) external pure returns (bytes4) {
//         return this.onERC721Received.selector;
//     }
// }
