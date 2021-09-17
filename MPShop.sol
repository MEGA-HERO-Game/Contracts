
// SPDX-License-Identifier: SimPL-2.0

pragma solidity >=0.8.0;

import "./MPNFT.sol";

interface IIERC20{
  function transfer(address recipient, uint256 amount) external;
  function transferFrom(address sender, address receipient, uint256 amount) external;
  function balanceOf(address account) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
}

contract MPShop {

  IIERC20 public _usdt;
  address public _operator;
  address private _receiver;

  struct OrderInfo{
    uint256 requestId;
    address buyer;
    uint256 amount;
    uint256 price;
    uint status;  //1为等待,2为成功,3为失败
  }

  event OrderEvent(
    uint256 requestId,
    address buyer,
    uint256 amount,
    uint256 price
  );


  

  mapping(uint256 => OrderInfo) _orders;
  

  constructor(address operator, address usdt, address receiver) public {
    _operator = operator;
    _receiver = receiver;
    _usdt = IIERC20(usdt);
  }

  function balanceOfUsdt (address user) public view returns (uint256){
    return _usdt.balanceOf(user);
  }

  

  modifier onlyOperator(){
    require (msg.sender == _operator, "shop only operator cann call this");

    _;
  }

  function getReceiver() public view returns(address){
    return _receiver;
  }

  function createBuyOrder (uint256 requestId, address user, uint256 amount, uint256 price) public {
    OrderInfo memory o = OrderInfo(requestId, user, amount,price,1);

    _orders[requestId] = o;
  }

  // event Log (
  //   string msg,
  //   address from,
  //   address to,
  //   uint256 p1,
  //   uint256 p2,
  //   uint256 allowance
  // );

  function approveUsdt (address user, uint256 amount) public returns (bool){

    bool result = _usdt.approve(user, amount);

    uint f = 0;

    if (result){
      f = 1;
    }

    // emit Log("buy", msg.sender,user, f, amount, _usdt.allowance(address(this), _operator));
    return result;
  }

  function buyToken (uint256 requestId, uint price)  public  {
    OrderInfo memory o = _orders[requestId];

    require (requestId == o.requestId, "request id error");
    require (price == o.price, "price error");
    require (o.status == 1, "order is success");

    // emit Log("buy2", msg.sender,_operator, o.price, price, _usdt.allowance(msg.sender, address(this)));


    _usdt.transferFrom(msg.sender, _receiver, price);
    
    _orders[requestId].status = 2;
    _orders[requestId].requestId = 0;
    emit OrderEvent(o.requestId, o.buyer, o.amount, o.price);
  }

  function getOrderStatus (uint256 requestId) public view returns (uint256){
    return _orders[requestId].status;
  }
  
}