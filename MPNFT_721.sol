// SPDX-License-Identifier: MIT
pragma solidity ^0.8;
import "@openzeppelin/contracts@4.3.0/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts@4.3.0/access/Ownable.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721Enumerable {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}


contract MP is ERC721URIStorage, Ownable {

    string private baseURI;

    address public operator;
    uint256 public mintLimit;
    
    uint256 public currentEpoch;
    uint256 public currentEpochMinted;

    modifier _onlyOperator() {
        require(operator == _msgSender(), "Operator: caller is not the operator");
        _;
    }

    modifier _onlyOperatorOrOwner() {
        require(operator == _msgSender() || owner() == _msgSender(), "Operator: caller is not the operator or owner");
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

    function setTokenURI(uint256 tokenId, string memory _tokenURI) external _onlyOperatorOrOwner {
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

    function _setBaseURI(string memory baseURI_) internal virtual {
        baseURI = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    //获取用户NFT列表
    function getUserNftList(address _addr) public view returns(uint256[] memory){
        uint256 _len = ERC721.balanceOf(_addr);
        uint256[] memory _list = new uint256[](_len);
        for(uint256 i = 0; i < _len; i++){
            _list[i] = tokenOfOwnerByIndex(_addr, i);
        }
        return _list;
    }

    //迭代获取用户NFT列表
    function iterationUserNftList(address _addr, uint256 _start, uint256 _end) public view returns(uint256[] memory){
        uint256 _len = ERC721.balanceOf(_addr);
        if(_len < _end ){
            _end = _len;
        }
        uint256[] memory _list = new uint256[](_end - _start);
        for(uint256 i = _start; i < _end; i++){
            _list[i-_start] = tokenOfOwnerByIndex(_addr, i);
        }
        return _list;
    }
}
