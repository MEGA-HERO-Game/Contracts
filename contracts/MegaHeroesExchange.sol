// // SPDX-License-Identifier: SimPL-2.0

// pragma solidity >=0.8.0;

// import "./MPNFT.sol";
// import "./MPToken.sol";

// contract MegaHeroesExchange {

//   MPNFT public _token;
//   MPToken public _mp;
//   address public _operator;
  

//   struct OrderInfo{
//     uint256 requestId;
//     uint256 assetId;
//     uint256 amount;
//     address buyer;
//     uint256 price;
//   }
  

//   mapping(uint256 => OrderInfo) _orders;

//   event OrderBuyEvent(
//         uint256 requestId,
//         uint256 assetId,
//         address buyer,
//         uint256 amount
//     );


//   constructor(address _tokenAddress, address mpTokenAddress, address operator) public {
//     _token = MPNFT(_tokenAddress);
//     _mp = MPToken (mpTokenAddress);
//     _operator = operator;
//   }

//   modifier onlyOperator(){
//       require (msg.sender == _operator, "only operator cann call this");

//       _;
//   }

//   /***
//   创建购买资产订单
//    */
//   function createPurchaseAssetOrder (uint256 requestId, uint256 assetId, uint count, address buyer, uint256 price)
//     external onlyOperator{
//     OrderInfo memory o = OrderInfo(requestId, assetId, count,buyer,price);

//     _orders[requestId] = o;
//   }

//   /***
//     用户购买 NFT
//    */
//   function buyAsset (uint256 requestId) public{
//       bytes memory aa;

//       OrderInfo memory o = _orders[requestId];

//       require(o.requestId == requestId, "valid buy order request id");

//       _mp.transferFrom(msg.sender, _operator, o.amount);

//       _token.safeTransferFrom(_operator, msg.sender, o.assetId, 1, aa);
//       emit OrderBuyEvent(requestId, o.assetId, msg.sender, o.amount);
//   }

// }