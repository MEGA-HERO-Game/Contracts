// SPDX-License-Identifier: GPL-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./MetaWorld.sol";

contract MetaWorldCollocation is Ownable {

    struct Collocation {
        address recipient;
    }

    MetaWorld public metaWorld;

    mapping (uint256 => Collocation) public collocationNFTs;

    event Deposit(address owner, uint256 tokenId);
    event Withdraw(address _user, uint256 tokenId);

    constructor(MetaWorld _metaWorld){
        metaWorld = _metaWorld;//meta world nft Contract Address
    }

    function deposit(uint256 _tokenId) public{
        require(metaWorld.ownerOf(_tokenId) == msg.sender, "MetaWorldSale:token is not owned by msg.sender");

        collocationNFTs[_tokenId] = Collocation(msg.sender);
        metaWorld.transferFrom(msg.sender, address(this), _tokenId);

        emit Deposit(msg.sender, _tokenId);
    }

    function withdraw(uint256 _tokenId) public {
        Collocation memory s = collocationNFTs[_tokenId];

        require(s.recipient!=address(0x0), "MetaWorldSale:token is not Collocating");

        metaWorld.transferFrom(address(this), s.recipient, _tokenId);
        delete collocationNFTs[_tokenId];

        emit Withdraw(msg.sender, _tokenId);
    }

    function depositBatch(uint256[] memory _tokenIds) public {
        for(uint256 i = 0; i < _tokenIds.length; i++){
            deposit(_tokenIds[i]);
        }
    }

    function withdrawBatch(uint256[] memory _tokenIds)  public {
        for(uint256 i = 0; i < _tokenIds.length; i++){
            withdraw(_tokenIds[i]);
        }
    }

}
