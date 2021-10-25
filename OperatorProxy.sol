// SPDX-License-Identifier: GPL-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts@4.3.0/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts@4.3.0/access/Ownable.sol";
import "@openzeppelin/contracts@4.3.0/token/ERC721/IERC721.sol";
import "./MPNFT_721.sol";
import "./DiamondCard.sol";


contract OperatorProxy is Ownable, ERC1155Holder {

    address public rootSigner;
    mapping(address => uint256) public nonce;

    uint256 public heroId = 107000000001;
    uint256 public spiritId = 207000000001;

    struct iBoxInfo{
         uint64 heroNums;//英雄数量
         uint64 spiritNums;//精灵数量
         uint64 diamondNums;//钻石卡数量（500面值）
         uint64 isActivate;//激活权限
    }

    mapping(uint256 => iBoxInfo) public iBoxInfoMap;

    MP public MPNFT;
    DiamondCard public diamondCard;
    IERC721 public IBox;
    address public oldMPNFT;


    event ExchangeIbox(address _user, uint256 _iboxId, uint256[] _mpIds, uint256[] _diaIds, uint256[] _diaAmounts, uint256[] _mpType);
    event ActivateIbox(address _user, uint256 _iboxId, uint256[] _mpType);
    event Withdraw(address _user, uint256 _nonce, uint256[] _mpIds, uint256[] _diaIds, uint256[] _diaAmounts);

    uint private unlocked = 1;
    modifier _lock() {
        require(unlocked == 1, 'Err: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    modifier _onlyOldMPNFT() {
        require(oldMPNFT == _msgSender(), "Err: caller is not the oldMPNFT");
        _;
    }

    constructor(DiamondCard _diamondCard, MP _MPNFT, IERC721 _IBox, address _oldMPNFT, address _rootSigner) {
        diamondCard = _diamondCard;//钻石NFT合约地址
        MPNFT = _MPNFT;//MPNFT 合约地址
        IBox = _IBox;//IBox 合约地址
        oldMPNFT = _oldMPNFT;//MPNFT 旧合约地址
        rootSigner = _rootSigner;
    }


 	function setSigner(address _addr) public onlyOwner {
        rootSigner = _addr;
    }


    // Ibox 资产兑换
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

        uint256[] memory _diaIds;
        uint256[] memory _diaAmounts;
        if(_diamondNums > 0){
            _diaIds = new uint256[](1);
            _diaIds[0] = 500;
            _diaAmounts = new uint256[](1);
            _diaAmounts[0] = _diamondNums;
            _mintDiamond(msg.sender, _diaIds, _diaAmounts);
        }

    	emit ExchangeIbox(msg.sender, _iboxId, _mpIds, _diaIds, _diaAmounts, _mpType);
    }

    //销毁Ibox激活游戏
    function activateIbox(uint256 _iboxId, uint256[] calldata _mpType) external _lock {

        require(iBoxInfoMap[_iboxId].isActivate > 0, "Err: No activation qualification");

        _destroyIbox(_iboxId);

        ActivateIbox(msg.sender, _iboxId, _mpType);
    }

    //销毁用户iBox资产
    function _destroyIbox(uint256 _iboxId) internal {
        IBox.transferFrom(msg.sender, address(this), _iboxId);
        require(IBox.ownerOf(_iboxId) == address(this), "Err: Failed to destroy");
    }

    // 用户提币
    function withdraw(uint256[] calldata _mpIds, uint256[] calldata _diaIds, uint256[] calldata _diaAmounts, uint256 _nonce, uint8 _v, bytes32 _r, bytes32 _s) external _lock {

    	require(_nonce == nonce[msg.sender], "Err: nonce error");
    	bytes32 _h = keccak256(abi.encodePacked(msg.sender, _mpIds, _diaIds, _diaAmounts, _nonce));
        require(ecrecover(_h,_v,_r,_s) == rootSigner, "Err: Sign Error");

        nonce[msg.sender]++;
		_mintMP(msg.sender, _mpIds);
        _mintDiamond(msg.sender, _diaIds, _diaAmounts);

    	emit Withdraw(msg.sender, _nonce, _mpIds, _diaIds, _diaAmounts);
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

    //创建 MP
	function _mintMP(address _addr, uint256[] memory _mpIds) internal {
		if(_mpIds.length > 0){
        	MPNFT.operatorMint(_addr, _mpIds);
        }
	}

	//创建钻石卡
	function _mintDiamond(address _addr, uint256[] memory _diaIds, uint256[] memory _diaAmounts) internal {
        if(_diaIds.length > 0){
        	require(_diaIds.length == _diaAmounts.length, "Err: _diaIds and _diaAmounts do not match in length");
        	diamondCard.operatorMint(_addr, _diaIds, _diaAmounts);
        }
	}

    //管理员添加Ibox资产信息
    function addIboxId(uint256[] calldata _iboxIds, uint64[] calldata _heroNums, uint64[] calldata _spiritNums, uint64[] calldata _diamondNums, uint64[] calldata _isActivate) external onlyOwner {

        uint256 _len = _iboxIds.length;
        require(_len == _heroNums.length && _len == _spiritNums.length && _len == _diamondNums.length && _len == _isActivate.length, "Err: Inconsistent parameter length");

        for(uint256 i = 0; i < _len; i++){
            iBoxInfoMap[_iboxIds[i]] = iBoxInfo(_heroNums[i], _spiritNums[i], _diamondNums[i], _isActivate[i]);
        }
    }

    //TODO TEST
    function setOldMPNFT(address _oldMPNFT) external onlyOwner {
        oldMPNFT = _oldMPNFT;//MPNFT 旧合约地址
    }
}

