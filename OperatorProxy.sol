// SPDX-License-Identifier: GPL-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts@4.3.0/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts@4.3.0/access/Ownable.sol";
import "@openzeppelin/contracts@4.3.0/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts@4.3.0/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts@4.3.0/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts@4.3.0/utils/math/SafeMath.sol";
import "./MPNFT_721.sol";
import "./DiamondCard.sol";

abstract contract asset is Ownable{

	MP public MPNFT;
    DiamondCard public diamondCard;

    uint private unlocked = 1;
    modifier _lock() {
        require(unlocked == 1, 'Err: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

	//创建 MP
	function _mintMP(address _addr, uint256[] memory _mpIds) internal {
		if(_mpIds.length > 0){
        	MPNFT.operatorMint(_addr, _mpIds);
        }
	}

	//创建多种钻石卡
	function _mintDiamondBatch(address _addr, uint256[] memory _diaIds, uint256[] memory _diaAmounts) internal {
        if(_diaIds.length > 0){
        	require(_diaIds.length == _diaAmounts.length, "Err: _diaIds and _diaAmounts do not match in length");
        	diamondCard.operatorMintBatch(_addr, _diaIds, _diaAmounts);
        }
	}

	//创建一种钻石卡
	function _mintDiamond(address _addr, uint256 _diaId, uint256 _diaAmount) internal {
        diamondCard.operatorMint(_addr, _diaId, _diaAmount);
	}
}

//资产映射
contract oldNftMapping is asset, ERC1155Holder{

    address public oldMPNFT;

    modifier _onlyOldMPNFT() {
        require(oldMPNFT == _msgSender(), "Err: caller is not the oldMPNFT");
        _;
    }

	constructor(address _oldMPNFT) {
        oldMPNFT = _oldMPNFT;
    }

    //旧合约映射
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) public override _lock _onlyOldMPNFT returns (bytes4) {
        uint256[] memory _mpIds = new uint256[](1);
        _mpIds[0] = id;
        _mintMP(operator, _mpIds);
        return super.onERC1155Received(operator, from, id, value, data);
    }

    //旧合约批量映射
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) public override _lock _onlyOldMPNFT returns (bytes4) {
        _mintMP(operator, ids);
        return super.onERC1155BatchReceived(operator, from, ids, values, data);
    }
}


//资产售卖
contract assetSale is asset{
	
    address public invitationSigner;
	IERC20 public usdt;
    address public platform;
    address public pool;

    uint256 public totalRate;
    uint256 public platformRate;
    uint256 public poolRate;
    uint256 public invitationRate;

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

	//钻石卡售卖价格
    mapping(uint256 => uint256) public idToPrice;

    //充值状态
    mapping(bytes32 => uint256) public rechargeState;

    event Price(uint256 _price, uint256 indexed _id);
    event Recharge(bytes32 indexed _sn, address _user, address _invitation, uint256 _usdt);
    event Buy(address indexed _user, address _invitation, uint256 _id, uint256 _amount, uint256 _usdt);

	constructor(IERC20 _usdt, address _invitationSigner) {        
        totalRate = 10000;
        invitationSigner = _invitationSigner;
        usdt = _usdt;
    }

    
    //用户购买钻石卡 On Chain
    function buy(uint256 _id, uint256 _amount, uint8 _v, bytes32 _r, bytes32 _s, address _invitation,uint256 _blockNumber) external{
        
        require(idToPrice[_id] > 0, "Err: Can't buy");

        if(_invitation != address(0)){
            require(block.number - _blockNumber < 28800, "Err: Sign expired");
            bytes32 _h = keccak256(abi.encodePacked(msg.sender, _invitation, _blockNumber));
            require(ecrecover(_h,_v,_r,_s) == invitationSigner, "Err: Sign Error");
        }

        uint256 _usdt = idToPrice[_id].mul(_amount);
        _settlementUsdt(_usdt, _invitation);
        _mintDiamond(msg.sender, _id, _amount);
        emit Buy(msg.sender, _invitation, _id, _amount, _usdt);
    }


    //用户充值 Off Chain
    function recharge(bytes32 _sn, uint256 _usdt, uint8 _v, bytes32 _r, bytes32 _s, address _invitation,uint256 _blockNumber) external{

        require(rechargeState[_sn] == 0, "Err: Already paid");
        require(_usdt > 0, "Err: Incorrect payment amount");

        if(_invitation != address(0)){
            require(block.number - _blockNumber < 28800, "Err: Sign expired");
            bytes32 _h = keccak256(abi.encodePacked(msg.sender, _invitation, _blockNumber));
            require(ecrecover(_h,_v,_r,_s) == invitationSigner, "Err: Sign Error");
        }
        
        _settlementUsdt(_usdt, _invitation);
        rechargeState[_sn] = _usdt;
        emit Recharge(_sn, msg.sender, _invitation, _usdt);
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

        usdt.safeTransferFrom(address(msg.sender), address(this), _total);

        if(_poolTotal > 0){
            usdt.safeTransfer(pool, _poolTotal);
        }

        if(_invTotal > 0){
            usdt.safeTransfer(_invitation, _invTotal);
        }

        if(_platformTotal > 0){
            usdt.safeTransfer(platform, _platformTotal);
        }
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

    //设置钻石卡价格
    function setDiamondCardPrice(uint256 _id, uint256 _price) external onlyOwner {
        require(diamondCard.exists(_id), "Err: Invalid ID");
        idToPrice[_id] = _price;
        emit Price(_price, _id);
    }

    function setInvitationSigner(address _signer) public onlyOwner {
        invitationSigner = _signer;
    }
}

//资产兑换
contract exchangeIboxAsset is asset{

    IERC721 public IBox;
	uint256 public heroId = 107000000001;
    uint256 public spiritId = 207000000001;

    struct iBoxInfo{
         uint64 heroNums;//英雄数量
         uint64 spiritNums;//精灵数量
         uint64 diamondNums;//钻石卡数量（500面值）
         uint64 isActivate;//激活权限
    }

    mapping(uint256 => iBoxInfo) public iBoxInfoMap;//Ibox资产兑换映射表

    event ExchangeIbox(address _user, uint256 _iboxId, uint256[] _mpIds, uint256 _diaIds, uint256 _diaAmounts, uint256[] _mpType);
    event ActivateIbox(address _user, uint256 _iboxId, uint256[] _mpType);

    constructor(IERC721 _IBox) {
        IBox = _IBox;
    }


    //管理员添加Ibox资产信息
    function addIboxId(uint256[] calldata _iboxIds, uint64[] calldata _heroNums, uint64[] calldata _spiritNums, uint64[] calldata _diamondNums, uint64[] calldata _isActivate) external onlyOwner {

        uint256 _len = _iboxIds.length;
        require(_len == _heroNums.length && _len == _spiritNums.length && _len == _diamondNums.length && _len == _isActivate.length, "Err: Inconsistent parameter length");

        for(uint256 i = 0; i < _len; i++){
            iBoxInfoMap[_iboxIds[i]] = iBoxInfo(_heroNums[i], _spiritNums[i], _diamondNums[i], _isActivate[i]);
        }
    }

    //销毁Ibox兑换资产 On Chain
    function exchangeIbox(uint256 _iboxId, uint256[] calldata _mpType) external _lock {

        uint256 _heroNums = iBoxInfoMap[_iboxId].heroNums;
        uint256 _spiritNums = iBoxInfoMap[_iboxId].spiritNums;
        uint256 _diamondNums = iBoxInfoMap[_iboxId].diamondNums;

        //是否有可兑换的资产
        require(_heroNums > 0 || _spiritNums > 0 || _diamondNums > 0, "Err: Incorrect asset type");

        _destroyIbox(_iboxId);

        uint256[] memory _mpIds;
        if(_spiritNums > 0 || _heroNums > 0){
            _mpIds = new uint256[](_heroNums + _spiritNums);
        
            //英雄ID
            for(uint256 i = 0; i < _heroNums; i++){
                _mpIds[i] = heroId;
                heroId++;
            }

            //精灵ID
            for(uint256 i = 0; i < _spiritNums; i++){
                _mpIds[_heroNums+i] = spiritId;
                spiritId++;
            }

            _mintMP(msg.sender, _mpIds);
        }

        if(_diamondNums > 0){
            _mintDiamond(msg.sender, 500, _diamondNums);
        }

    	emit ExchangeIbox(msg.sender, _iboxId, _mpIds, 500, _diamondNums, _mpType);
    }

    //销毁Ibox激活游戏 Off Chain
    function activateIbox(uint256 _iboxId, uint256[] calldata _mpType) external _lock {

        require(iBoxInfoMap[_iboxId].isActivate > 0, "Err: No activation qualification");

        _destroyIbox(_iboxId);

        emit ActivateIbox(msg.sender, _iboxId, _mpType);
    }

    //销毁用户iBox资产
    function _destroyIbox(uint256 _iboxId) internal {
        IBox.transferFrom(msg.sender, address(this), _iboxId);
        require(IBox.ownerOf(_iboxId) == address(this), "Err: Failed to destroy");
    }

}


//资产提取
contract withdrawAsset is asset{
    
	address public withdrawSigner;

    uint256 public currentEpoch;
    uint256 public diamondLimit;
    uint256 public currentDiamondLimit;
    uint256 public mpLimit;
    uint256 public currentMpLimit;

    mapping(address => uint256) public nonce;

    event Withdraw(address _user, uint256 _nonce, uint256[] _mpIds, uint256[] _diaIds, uint256[] _diaAmounts);

    constructor(address _withdrawSigner) {
        withdrawSigner = _withdrawSigner;
    }

    function withdraw(uint256[] calldata _mpIds, uint256[] calldata _diaIds, uint256[] calldata _diaAmounts, uint256 _nonce, uint8 _v, bytes32 _r, bytes32 _s) external _lock {

    	require(_nonce == nonce[msg.sender], "Err: nonce error");
    	bytes32 _h = keccak256(abi.encodePacked(msg.sender, _mpIds, _diaIds, _diaAmounts, _nonce));
        require(ecrecover(_h,_v,_r,_s) == withdrawSigner, "Err: Sign Error");
		_withdrawLimit(_mpIds.length,_diaIds, _diaAmounts);

        nonce[msg.sender]++;
		_mintMP(msg.sender, _mpIds);
        _mintDiamondBatch(msg.sender, _diaIds, _diaAmounts);

    	emit Withdraw(msg.sender, _nonce, _mpIds, _diaIds, _diaAmounts);
    }

 	function setWithdrawSigner(address _signer) public onlyOwner {
        withdrawSigner = _signer;
    }

    function setLimit(uint256 _diamondLimit, uint256 _mpLimit) external onlyOwner {
    	diamondLimit = _diamondLimit;
        mpLimit = _mpLimit;
    }

    //限制每天提币的数量
    function _withdrawLimit(uint256 _mpNum, uint256[] calldata _diaIds, uint256[] calldata _diaAmounts) internal {

    	uint256 _epoch = block.number / 28800;
        if(currentEpoch != _epoch){
            currentEpoch = _epoch;
            currentDiamondLimit = 0;
            currentMpLimit = 0;
        }

        uint256 _totalValue = 0;
        for(uint256 i = 0; i < _diaIds.length; i++){
            _totalValue = _totalValue + _diaIds[i] * _diaAmounts[i];//钻石ID和钻石面值相等
        }

        currentDiamondLimit = currentDiamondLimit + _totalValue;
        require(currentDiamondLimit < diamondLimit, "Err: The Diamond mint quota has been used up");

        currentMpLimit = currentMpLimit + _mpNum;
        require(currentMpLimit < mpLimit, "Err: The MPNFT mint quota has been used up");
    }
}


contract Operator is oldNftMapping, assetSale, exchangeIboxAsset, withdrawAsset{

	constructor(
		DiamondCard _diamondCard, MP _MPNFT, 
		address _oldMPNFT,
		IERC20 _usdt, address _invitationSigner,
	 	IERC721 _IBox,
	 	address _withdrawSigner
	)
		oldNftMapping(_oldMPNFT)
		assetSale(_usdt, _invitationSigner)
		exchangeIboxAsset(_IBox)
		withdrawAsset(_withdrawSigner)
	{
        diamondCard = _diamondCard;//钻石NFT合约地址
        MPNFT = _MPNFT;//MPNFT 合约地址
    }
}
