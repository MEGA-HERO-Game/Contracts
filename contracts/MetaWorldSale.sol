// SPDX-License-Identifier: GPL-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./MetaWorld.sol";

contract MetaWorldSale is Ownable {
    using SafeERC20 for IERC20;

    struct PaymentCurrency {
        uint256 id;         // payment currency id (1 is the blockchain platform currency)
        IERC20  currency;   // payment currency(ERC20) address
        bool    validity;
    }

    struct Selling {
        address payable recipient;
        uint256 currencyId;         // recipient currency id
        uint256 price;
        uint256 startTime;
    }

    MetaWorld public metaWorld;

    mapping (uint256 => Selling) public sellingNFTs;

    PaymentCurrency[] public paymentCurrencies;

    address payable platformRecipient;
    uint256 public platformFeeRatio = 10; // 10%

    event ListForSell(address owner, uint256 tokenId, uint256 currencyId, uint256 price, uint256 startTime);
    event UnListFromSelling(address owner, uint256 tokenId);
    event Sold(address buyer,uint256 tokenId, uint256 currencyId, uint256 price, uint256 fee);


    constructor(MetaWorld _metaWorld, uint256 _feeRatio){
        metaWorld = _metaWorld;//meta world nft Contract Address
        platformRecipient = payable(msg.sender);
        platformFeeRatio = _feeRatio;
        addPaymentCurrency(address(0)); // By default, platform currency is supported
    }

    function list(uint256 _tokenId,uint256 _price, uint256 _currencyId, uint256 _startTime) public{
        require(metaWorld.ownerOf(_tokenId) == msg.sender, "MetaWorldSale:token is not owned by msg.sender");
        require(_startTime >= block.timestamp, "MetaWorldSale:token sell should be the future");
        require(_paymentCurrencySupported(_currencyId) == true, "MetaWorldSale:currency must supported");

        sellingNFTs[_tokenId] = Selling(payable(msg.sender), _currencyId, _price, _startTime);

        metaWorld.transferFrom(msg.sender, address(this), _tokenId);

        emit ListForSell(msg.sender, _tokenId, _currencyId, _price, _startTime);
    }

    function unlist(uint256 tokenId) public{

        Selling memory s = sellingNFTs[tokenId];

        require(s.recipient==msg.sender,"MetaWorldSale:token is not owned by msg.sender");
        emit UnListFromSelling(sellingNFTs[tokenId].recipient,tokenId);
        metaWorld.transferFrom(address(this) , msg.sender, tokenId);
        delete sellingNFTs[tokenId];
    }

    function buy(uint256 _tokenId)  public payable{
        Selling memory s = sellingNFTs[_tokenId];
        PaymentCurrency memory c = getPaymentCurrencyById(s.currencyId);

        require(block.timestamp>s.startTime, "MetaWorldSale:not started yet");
        require(s.recipient!=address(0x0), "MetaWorldSale:token is not selling");

        uint256 recipientUser = s.price - (s.price * 100)/platformFeeRatio;
        uint256 recipientPlatform = (s.price * 100)/platformFeeRatio;

        if (c.id == 1) {
            require(msg.value > s.price, "MetaWorldSale:price is high than offer");
            if (msg.value > s.price) {
                // refund
                uint256 refund = msg.value - s.price;
                payable(msg.sender).transfer(refund);
            }
            s.recipient.transfer(recipientUser);
            payable(platformRecipient).transfer(recipientPlatform);

        } else {
            require(c.currency.allowance(address(msg.sender), address(this)) >= s.price, "MetaWorldSale:currency remain allowance is not enough");
            require(c.currency.balanceOf(address(msg.sender)) >= s.price, "MetaWorldSale:currency remain balance is not enough");
            c.currency.transferFrom(address(this), s.recipient, recipientUser);
            c.currency.transferFrom(address(this), platformRecipient, recipientPlatform);
        }

        metaWorld.transferFrom(address(this),msg.sender,_tokenId);

        delete sellingNFTs[_tokenId];

        emit Sold(msg.sender, _tokenId, c.id, recipientUser, recipientPlatform);
    }

    function setFeeRatio(uint256 _feeRatio) public onlyOwner{
        platformFeeRatio = _feeRatio;
    }

    function addPaymentCurrency(address _currency) public onlyOwner{
        require(_paymentCurrencyExists(_currency) == false, "MetaWorldSale:currency already add yet");

        PaymentCurrency memory currency;
        if(paymentCurrencies.length == 0) {
            currency.id = 1;
            currency.currency = IERC20(_currency);
            currency.validity = true;
        }else{
            paymentCurrencies[paymentCurrencies.length - 1].id + 1;
            currency.currency = IERC20(_currency);
            currency.validity = true;
        }

        paymentCurrencies.push(currency);
    }

    function disablePaymentCurrency(address _currency) public onlyOwner{
        require(_paymentCurrencyExists(_currency) == true, "MetaWorldSale:currency must add yet");
        require(_currency != address(0), "MetaWorldSale:currency must add yet");
        for(uint i=0; i<= paymentCurrencies.length; i++){
            if(paymentCurrencies[i].currency == IERC20(_currency)){
                paymentCurrencies[i].validity = false;
            }
        }
    }

    function enablePaymentCurrency(address _currency) public onlyOwner{
        require(_paymentCurrencyExists(_currency) == true, "MetaWorldSale:currency must add yet");
        require(_currency != address(0), "MetaWorldSale:currency must add yet");
        for(uint i=0; i< paymentCurrencies.length; i++){
            if(paymentCurrencies[i].currency == IERC20(_currency)){
                paymentCurrencies[i].validity = true;
            }
        }
    }

    function _paymentCurrencyExists(address _currency) internal view returns (bool) {
        for(uint i=0; i< paymentCurrencies.length; i++){
            if(paymentCurrencies[i].currency == IERC20(_currency)){
                return true;
            }
        }
        return false;
    }

    function _paymentCurrencySupported(uint256 _currencyId) internal view returns (bool) {
        for(uint i=0; i< paymentCurrencies.length; i++){
            if(paymentCurrencies[i].id == _currencyId && paymentCurrencies[i].validity == true){
                return true;
            }
        }
        return false;
    }

    function getPaymentCurrencyById(uint256 _currencyId) public view returns (PaymentCurrency memory) {
        PaymentCurrency memory c;
        for(uint i=0; i< paymentCurrencies.length; i++){
            if(paymentCurrencies[i].id == _currencyId){
                c = paymentCurrencies[i];
            }
        }
        return c;
    }

}
