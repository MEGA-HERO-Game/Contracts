// SPDX-License-Identifier: GPL-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts@4.3.0/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts@4.3.0/access/Ownable.sol";
import "@openzeppelin/contracts@4.3.0/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts@4.3.0/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts@4.3.0/utils/math/SafeMath.sol";


contract DiamondCard is ERC1155Supply, Ownable {


    // Mapping from token ID to token URI
    mapping(uint256 => string) private idToUri;

    mapping(uint256 => uint256) public idToPrice;

    mapping(uint256 => uint256) public idToMaxSupply;

    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    IERC20 public usdt;
    address public platform;
    address public pool;

    uint256 public totalRate;
    uint256 public platformRate;
    uint256 public poolRate;
    uint256 public invitationRate;
    address public rootSigner;

    event Price(uint256 _price, uint256 indexed _id);
    event MaxSupply(uint256 _supply, uint256 indexed _id);
    event Buy(address indexed _user, address _invitation, uint256 _id, uint256 _amount, uint256 _usdt);

	constructor(IERC20 _usdt, address _platform, address _pool, uint256 _platformRate, uint256 _poolRate, address _rootSigner) ERC1155("") {
        usdt = _usdt;
        platform = _platform;
        pool = _pool;
        rootSigner = _rootSigner;

        totalRate = 10000;
        platformRate = _platformRate;
        poolRate = _poolRate;
        invitationRate = totalRate.sub(platformRate).sub(poolRate);
    }

    /**
     * @dev Creates a new NFT type
     * @param _uri Content identifier
     * @param _price Unit price of NFT
     * @param _id  newly created token ID
     */
    function create(uint256 _id, uint256 _price, uint256 _maxSupply, string calldata _uri) external onlyOwner {
    	require(!_exists(_id), "Err: ID already exists");
        require(bytes(_uri).length > 0, "Err: Missing Content Identifier");
        
        _mint(msg.sender, _id, 0, "");
        
        idToPrice[_id] = _price;
        emit Price(_price, _id);
        
        idToMaxSupply[_id] = _maxSupply;
        emit MaxSupply(_maxSupply, _id);

        idToUri[_id] = _uri;
        emit URI(_uri, _id);
    }


    function mint(address _account, uint256 _id, uint256 _amount) external onlyOwner {
        require(_exists(_id), "Err: Invalid ID");
        require(idToMaxSupply[_id] >= totalSupply(_id).add(_amount), "Err: Exceeding maximum supply");
        _mint(_account, _id, _amount, "");
    }

    function buy(uint256 _id, uint256 _amount, uint8 _v, bytes32 _r, bytes32 _s, address _invitation,uint256 _blockNumber) external{

        require(idToPrice[_id] > 0, "Err: Can't buy");
        require(idToMaxSupply[_id] >= totalSupply(_id).add(_amount), "Err: Exceeding maximum supply");

        if(_invitation != address(0)){
            require(block.number - _blockNumber < 28800, "Err: Sign expired");
            bytes32 _h = keccak256(abi.encodePacked(msg.sender, _invitation, _blockNumber));
            require(ecrecover(_h,_v,_r,_s) == rootSigner, "Err: Sign Error");
        }

        uint256 _total = idToPrice[_id].mul(_amount);
        uint256 _poolTotal = _total.mul(poolRate).div(totalRate);
        uint256 _platformTotal = 0;
        if(_invitation == address(0)){
            _platformTotal = _total.mul(invitationRate + platformRate).div(totalRate);
        } else {
            _platformTotal = _total.mul(platformRate).div(totalRate);
        }

        uint256 _invTotal = _total.sub(_poolTotal).sub(_platformTotal);

        if(_poolTotal > 0){
            usdt.safeTransferFrom(address(msg.sender), pool, _poolTotal);            
        }

        if(_invTotal > 0){
            usdt.safeTransferFrom(address(msg.sender), _invitation, _invTotal);
        }

        if(_platformTotal > 0){
            usdt.safeTransferFrom(address(msg.sender), platform, _platformTotal);
        }

        _mint(msg.sender, _id, _amount, "");
        emit Buy(msg.sender, _invitation, _id, _amount, _total);
    }


    function _exists(uint256 _id) internal view returns (bool) {
        return (bytes(idToUri[_id]).length > 0);
    }

    function uri(uint256 _id) public view override returns (string memory) {
        return idToUri[_id];
    }

    function setPool(address _pool) external onlyOwner {
        pool = _pool;
    }

    function setPlatfrom(address _platform) external onlyOwner {
        platform = _platform;
    }

    function setRate(uint256 _platformRate, uint256 _poolRate) external onlyOwner {
        platformRate = _platformRate;
        poolRate = _poolRate;
        invitationRate = totalRate.sub(platformRate).sub(poolRate);
    }

    function setSigner(address _addr) public onlyOwner {
        rootSigner = _addr;
    }

    function setPrice(uint256 _id, uint256 _price) external onlyOwner {
        require(_exists(_id), "Err: Invalid ID");
        idToPrice[_id] = _price;
        emit Price(_price, _id);
    }

    function setUri(uint256 _id, string calldata _uri) external onlyOwner {
        require(_exists(_id), "Err: Invalid ID");
        require(bytes(_uri).length > 0, "Err: Missing Content Identifier");
        idToUri[_id] = _uri;
        emit URI(_uri, _id);   
    }

    function setMaxSupply(uint256 _id, uint256 _maxSupply) external onlyOwner {
        require(_exists(_id), "Err: Invalid ID");
        // require(_maxSupply > idToMaxSupply[_id], "Err: _maxSupply is too small");
        idToMaxSupply[_id] = _maxSupply;
        emit MaxSupply(_maxSupply, _id);
    }


    function getNumber() external view returns(uint256){
        return block.number;
    }
}
