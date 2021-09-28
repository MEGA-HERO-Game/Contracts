// SPDX-License-Identifier: GPL-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts@4.3.0/access/Ownable.sol";
import "@openzeppelin/contracts@4.3.0/token/ERC721/IERC721.sol";
import "./MPNFT_721.sol";
import "./DiamondCard.sol";


contract OperatorProxy is Ownable {

    address public rootSigner;
    mapping(address => uint256) public nonce;

    MP public MPNFT;
    DiamondCard public diamondCard;
    IERC721 public IBox;

    event ExchangeIbox(address _user, uint256 _iboxId, uint256[] _mpIds, uint256[] _diaIds, uint256[] _diaAmounts);
    event Withdraw(address _user, uint256[] _mpIds, uint256[] _diaIds, uint256[] _diaAmounts);

    uint private unlocked = 1;
    modifier _lock() {
        require(unlocked == 1, 'Err: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    constructor(DiamondCard _diamondCard, MP _MPNFT, IERC721 _IBox, address _rootSigner) {
        diamondCard = _diamondCard;//钻石NFT合约地址
        MPNFT = _MPNFT;//MPNFT 合约地址
        IBox = _IBox;//IBox 合约地址
        rootSigner = _rootSigner;
    }


 	function setSigner(address _addr) public onlyOwner {
        rootSigner = _addr;
    }


    // Ibox 资产兑换
    function exchangeIbox(uint256 _iboxId, uint256[] memory _mpIds, uint256[] memory _diaIds, uint256[] memory _diaAmounts, uint256 _blockNumber, uint8 _v, bytes32 _r, bytes32 _s) external _lock {

        require(block.number - _blockNumber < 28800, "Err: Sign expired");
    	bytes32 _h = keccak256(abi.encodePacked(_blockNumber, _iboxId, _mpIds, _diaIds, _diaAmounts));
        require(ecrecover(_h,_v,_r,_s) == rootSigner, "Err: Sign Error");

        //销毁用户iBox资产
        IBox.transferFrom(msg.sender, address(this), _iboxId);
        require(IBox.ownerOf(_iboxId) == address(this), "Err: Failed to destroy");

        _mintMP(_mpIds);
        _mintDiamond(_diaIds, _diaAmounts);

    	emit ExchangeIbox(msg.sender, _iboxId, _mpIds, _diaIds, _diaAmounts);

    }

    // 用户提币
    function withdraw(uint256[] memory _mpIds, uint256[] memory _diaIds, uint256[] memory _diaAmounts, uint256 _nonce, uint8 _v, bytes32 _r, bytes32 _s) external _lock {

    	require(_nonce != nonce[msg.sender] + 1, "Err: nonce error");
    	bytes32 _h = keccak256(abi.encodePacked(msg.sender, _mpIds, _diaIds, _diaAmounts, _nonce));
        require(ecrecover(_h,_v,_r,_s) == rootSigner, "Err: Sign Error");

        nonce[msg.sender]++;
		_mintMP(_mpIds);
        _mintDiamond(_diaIds, _diaAmounts);

    	emit Withdraw(msg.sender, _mpIds, _diaIds, _diaAmounts);
    }

    //创建 MP
	function _mintMP(uint256[] memory _mpIds) internal {
		if(_mpIds.length > 0){
        	MPNFT.operatorMint(msg.sender, _mpIds);
        }
	}

	//创建钻石卡
	function _mintDiamond(uint256[] memory _diaIds, uint256[] memory _diaAmounts) internal {
        if(_diaIds.length > 0){
        	require(_diaIds.length == _diaAmounts.length, "Err: _diaIds and _diaAmounts do not match in length");
        	diamondCard.operatorMint(msg.sender, _diaIds, _diaAmounts);
        }
	}

}
