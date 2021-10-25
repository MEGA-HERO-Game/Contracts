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
    event Recharge(address indexed _user, address _invitation, uint256 _id, uint256 _amount, uint256 _usdt);


    address public operator;
    uint256 public mintLimit;
    
    uint256 public currentEpoch;
    uint256 public currentEpochMinted;

    modifier _onlyOperator() {
        require(operator == _msgSender(), "Operator: caller is not the operator");
        _;
    }

    modifier _mintLimit(uint256[] memory _ids, uint256[] memory _amounts) {

        uint256 _totalValue = 0;
        for(uint256 i = 0; i < _ids.length; i++){
            require(_exists(_ids[i]), "Err: Invalid ID");
            require(idToMaxSupply[_ids[i]] >= totalSupply(_ids[i]).add(_amounts[i]), "Err: Exceeding maximum supply");
            _totalValue = _totalValue + idToPrice[_ids[i]] * _amounts[i];
        }

        if(_totalValue > 0){
            uint256 epoch = block.number / 28800;
            if(currentEpoch != epoch){
                currentEpoch = epoch;
                currentEpochMinted = 0;
            }
            currentEpochMinted = currentEpochMinted + _totalValue;
            require(currentEpochMinted <= mintLimit, "Err: The Diamond casting quota has been used up");
        }
        _;
    }


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


    //创建NFT类型
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

    //operator合约发行NFT
    function operatorMint(address _account, uint256[] memory _ids, uint256[] memory _amounts) external _onlyOperator _mintLimit(_ids, _amounts)  {
        _mintBatch(_account, _ids, _amounts, "");
    }

    //管理员发行NFT
    function mint(address _account, uint256 _id, uint256 _amount) external onlyOwner {
        require(_exists(_id), "Err: Invalid ID");
        require(idToMaxSupply[_id] >= totalSupply(_id).add(_amount), "Err: Exceeding maximum supply");
        _mint(_account, _id, _amount, "");
    }

    //用户购买NFT
    function buy(uint256 _id, uint256 _amount, uint8 _v, bytes32 _r, bytes32 _s, address _invitation,uint256 _blockNumber) external{
        
        require(_exists(_id), "Err: Invalid ID");
        require(idToPrice[_id] > 0, "Err: Can't buy");
        require(idToMaxSupply[_id] >= totalSupply(_id).add(_amount), "Err: Exceeding maximum supply");

        if(_invitation != address(0)){
            require(block.number - _blockNumber < 28800, "Err: Sign expired");
            bytes32 _h = keccak256(abi.encodePacked(msg.sender, _invitation, _blockNumber));
            require(ecrecover(_h,_v,_r,_s) == rootSigner, "Err: Sign Error");
        }

        uint256 _total = idToPrice[_id].mul(_amount);
        _settlementUsdt(_total, _invitation);
        _mint(msg.sender, _id, _amount, "");
        emit Buy(msg.sender, _invitation, _id, _amount, _total);
    }

    //用户充值
    function recharge(uint256 _id, uint256 _amount, uint8 _v, bytes32 _r, bytes32 _s, address _invitation,uint256 _blockNumber) external{
        require(_exists(_id), "Err: Invalid ID");
        require(idToPrice[_id] > 0, "Err: Can't buy");
        // require(idToMaxSupply[_id] >= totalSupply(_id).add(_amount), "Err: Exceeding maximum supply");

        if(_invitation != address(0)){
            require(block.number - _blockNumber < 28800, "Err: Sign expired");
            bytes32 _h = keccak256(abi.encodePacked(msg.sender, _invitation, _blockNumber));
            require(ecrecover(_h,_v,_r,_s) == rootSigner, "Err: Sign Error");
        }

        uint256 _total = idToPrice[_id].mul(_amount);
        _settlementUsdt(_total, _invitation);
        emit Recharge(msg.sender, _invitation, _id, _amount, _total);
    }

    //结算资金
    function _settlementUsdt(uint256 _total, address _invitation) internal{
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

    function setOperator(address _operator) external onlyOwner {
        operator = _operator;
    }

    function setLimit(uint256 _limit) external onlyOwner {
        mintLimit = _limit;
    }

    function burn(uint256 _id, uint256 _amount) external {
        _burn(msg.sender, _id, _amount);
    }

    function burnBatch(uint256[] memory _ids, uint256[] memory _amounts) external {
        _burnBatch(msg.sender, _ids, _amounts);
    }
}
