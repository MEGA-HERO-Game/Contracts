// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "@openzeppelin/contracts@4.3.0/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts@4.3.0/access/Ownable.sol";

contract MP is ERC721URIStorage, Ownable {

    string private baseURI;

    mapping(address => uint256[]) public userNfts;
    mapping(uint256 => uint256) private userNftsIndex;

    address public operator;
    uint256 public mintLimit;
    
    uint256 public currentEpoch;
    uint256 public currentEpochMinted;

    modifier _onlyOperator() {
        require(operator == _msgSender(), "Operator: caller is not the operator");
        _;
    }

    modifier _mintLimit(uint256[] memory _ids) {
        uint256 epoch = block.number / 28800;
        if(currentEpoch != epoch){
            currentEpoch = epoch;
            currentEpochMinted = 0;
        }
        currentEpochMinted = currentEpochMinted + _ids.length;
        require(currentEpochMinted <= mintLimit, "Err: The MPNFT casting quota has been used up");
        _;
    }

    constructor() ERC721("MPNFT", "MP") {
    }


    function setBaseUri(string memory _baseURIArg) external onlyOwner {
        baseURI = _baseURIArg;
    }

    function setOperator(address _operator) external onlyOwner {
        operator = _operator;
    }

    function setLimit(uint256 _limit) external onlyOwner {
        mintLimit = _limit;
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI) external onlyOwner {
        _setTokenURI(tokenId, _tokenURI);
    }

    function operatorMint(address _to, uint256[] memory _ids) external _onlyOperator _mintLimit(_ids) {
        for(uint256 i = 0; i < _ids.length; i++){
            _mint(_to, _ids[i]);
        }
    }

    function mint(address _to, uint256 _tokenId) external onlyOwner{
        _mint(_to, _tokenId);
    }

    function burn(uint256 _tokenId) external {
        require(msg.sender == ERC721.ownerOf(_tokenId), "Err: transfer caller is not owner");
        _burn(_tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {

        if(from == to){
            return;
        }

        if (from == address(0)) {
            _mintNft(tokenId, to);
        } else if (to == address(0)) {
            _burnNft(tokenId, from);
        } else {
            _transferNft(tokenId, from, to);
        }
    }


    function _mintNft(uint256 tokenId, address to) internal{
        userNfts[to].push(tokenId);
        userNftsIndex[tokenId] = userNfts[to].length;
    }


    function _burnNft(uint256 tokenId, address from) internal{

        uint256 lastTokenId = userNfts[from][userNfts[from].length - 1];
        userNfts[from].pop();//弹出尾部元素

        //使用尾部元素覆盖
        if(lastTokenId != tokenId){
            uint256 index = userNftsIndex[tokenId];
            userNfts[from][index - 1] = lastTokenId;
            userNftsIndex[lastTokenId] = index;
        }

        delete userNftsIndex[tokenId];
    }

    function _transferNft(uint256 tokenId, address from, address to) internal{

        uint256 lastTokenId = userNfts[from][userNfts[from].length - 1];
        userNfts[from].pop();//弹出尾部元素

        //使用尾部元素覆盖
        if(lastTokenId != tokenId){
            uint256 index = userNftsIndex[tokenId];
            userNfts[from][index - 1] = lastTokenId;
            userNftsIndex[lastTokenId] = index;
        }

        //转移给to
        userNfts[to].push(tokenId);

        //更新下标
        userNftsIndex[tokenId] = userNfts[to].length;
    }

    function _setBaseURI(string memory baseURI_) internal virtual {
        baseURI = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    //获取用户NFT总量
    function getUserNftTotal(address _addr) public view returns(uint256){
        return userNfts[_addr].length;
    }

    //获取用户NFT列表
    function getUserNftList(address _addr) public view returns(uint256[] memory){
        return userNfts[_addr];
    }

    //迭代获取用户NFT列表
    function iterationUserNftList(address _addr, uint256 _start, uint256 _end) public view returns(uint256[] memory){
        if(userNfts[_addr].length < _end ){
            _end = userNfts[_addr].length;
        }

        uint256[] memory list;
        list = new uint256[](_end - _start);
        for(uint256 i = _start; i < _end; i++){
            list[i-_start] = userNfts[_addr][i];
        }
        return list;
    }

}