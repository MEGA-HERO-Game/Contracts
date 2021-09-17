// SPDX-License-Identifier: SimPL-2.0

pragma solidity >=0.8.0;

import "./MPToken.sol";


interface IBoxToken{
  function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

  function totalSupply() external view returns (uint256);

  function tokenURI(uint256 tokenId) external view returns (string memory);

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

  function balanceOf(address owner) external view returns (uint256 balance);

  function approve(address to, uint256 tokenId) external;

  function getApproved(uint256 tokenId) external view returns (address operator);
}

interface IMPNFTToken{
  function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) external;

  function createTokenForIboxExchange ( uint256 amount, string memory uri)  external returns (uint256);
  
}

contract IboxTokenExchange {

  IMPNFTToken public _mpNFT;
  IBoxToken public _iboxToken;
  address public _operator;
  address public _receiver;

  struct OrderInfo{
    uint256 requestId;
    uint256 iBoxTokenId;
    uint256 []mpTokenId;
    address user;
    uint256 []amount;
    uint256 []sourceId;

    uint status; //订单状态：1为待交易，2为交易成功
  }
  

  mapping(uint256 => OrderInfo) _orders;

  struct AssetInfo{
    uint256 id;
    uint256 assetToken;
  }
  event IboxTokenExchangeEvent(
    uint256 requestId,
    uint status,
    AssetInfo []list
  );

  event IboxTokenOrderEvent(
    uint256 requestId,
    uint status,
    uint256 assetId
  );


  // constructor(address mpNFT, address ibox, address operator) public {
  //   _mpNFT = MPNFT(nft);
  //   _iboxToken = ERC721(ibox);
  //   _operator = operator;
  // }

  constructor(address operator, address receiver) public {
    _operator = operator;
    _receiver = receiver;
  }

  function setConfig (address ibox, address mpNft) external onlyOperator {
    _iboxToken = IBoxToken(ibox);
    _mpNFT = IMPNFTToken(mpNft);
  }

  function getReceiver() public view returns(address){
    return _receiver;
  }

  function getIboxToken () public view returns (address){
    return address (_iboxToken);
  }

  function getNFTToken () public view returns (address){
    return address (_mpNFT);
  }

  modifier onlyOperator(){
      require (msg.sender == _operator, "ibox exchange only operator can call this");

      _;
  }

  // event Log(
  //       address log,
  //       string msg
  //   );


  /***
  创建资产兑换订单
   */
  function createExchangeOrder (uint256 requestId, uint256 iBoxToken, uint256 []memory sourceId,
   string [] memory newUri, address user, uint256 [] memory amount)
    external onlyOperator{
    uint l = amount.length;

    
    // OrderInfo memory o = OrderInfo(requestId, iBoxToken, new int256[](0),user, new int256[](0),new int256[](0),1);
    _orders[requestId].requestId = requestId;
    _orders[requestId].iBoxTokenId = iBoxToken;
    _orders[requestId].status = 1;
    _orders[requestId].user = user;

    for (uint i = 0; i < l; i++){
      uint256 id = _mpNFT.createTokenForIboxExchange (amount[i], newUri[i]);
      _orders[requestId].mpTokenId.push(id);
      _orders[requestId].amount.push(amount[i]);
      _orders[requestId].sourceId.push(sourceId[i]);
    }

    emit IboxTokenOrderEvent(requestId, _orders[requestId].status, iBoxToken);
    
  }

  function getOrderStatus (uint256 requestId) public view returns (uint){

    return _orders[requestId].status;
  }

  /***
    用户购买 NFT
   */
  function exchange (uint256 requestId) public{
    bytes memory aa;

    OrderInfo memory o = _orders[requestId];

    require(o.requestId == requestId && o.status == 1, "valid buy order request id or status");
    uint l = o.mpTokenId.length;
    AssetInfo []memory result = new AssetInfo[] (l);
    _iboxToken.safeTransferFrom(msg.sender, _receiver, o.iBoxTokenId, aa);

    // uint l = o.mpTokenId.length;
    
    for (uint i = 0; i < l; i++){
      _mpNFT.safeTransferFrom(_operator, msg.sender, o.mpTokenId[i], o.amount[i], aa);
      result[i].id = o.sourceId[i];
      result[i].assetToken = o.mpTokenId[i];
    }
    

    _orders[requestId].status = 2;
    emit IboxTokenExchangeEvent(requestId, 1, result);
  }

  function getIboxTokenUri (uint256 iBoxToken) public view returns (string memory){
    return _iboxToken.tokenURI(iBoxToken);
  }

  function getUserIboxTokenId (address user) public view returns (uint256[]memory){
    uint balance = _iboxToken.balanceOf(user);
    // return balance;
    if (balance == 0){
      return new uint256[](0);
    }

    uint256[] memory result = new uint256[](balance);
    for (uint i = 0; i < balance; i++){
      uint256 token = _iboxToken.tokenOfOwnerByIndex(user, i);

      result[i] = token;
    }

    return result;
  }

  // function approve(uint256 tokenId) public {
  //   _iboxToken.approve(to, tokenId);
  // }

  // function getApproved(uint256 tokenId) external view returns (address operator){
  //   _iboxToken.getApproved(tokenId);
  // }
}