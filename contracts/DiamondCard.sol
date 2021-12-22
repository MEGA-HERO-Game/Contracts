// SPDX-License-Identifier: GPL-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


contract DiamondCard is ERC1155Supply, Ownable {


    // Mapping from token ID to token URI
    mapping(uint256 => string) private idToUri;
    mapping(uint256 => uint256) public idToMaxSupply;

    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    event MaxSupply(uint256 _supply, uint256 indexed _id);


    address public operator;

    modifier _onlyOperator() {
        require(operator == _msgSender(), "Operator: caller is not the operator");
        _;
    }

    constructor() ERC1155("") {}


    //创建NFT类型
    function create(uint256 _id, uint256 _maxSupply, string calldata _uri) external onlyOwner {
    	require(!exists(_id), "Err: ID already exists");
        require(bytes(_uri).length > 0, "Err: Missing Content Identifier");
        
        _mint(msg.sender, _id, 0, "");
        
        idToMaxSupply[_id] = _maxSupply;
        emit MaxSupply(_maxSupply, _id);

        idToUri[_id] = _uri;
        emit URI(_uri, _id);
    }

    function operatorMintBatch(address _account, uint256[] memory _ids, uint256[] memory _amounts) external _onlyOperator {
        uint256 _len = _ids.length;
        for(uint256 i = 0; i < _len; i++){
            require(idToMaxSupply[_ids[i]] >= totalSupply(_ids[i]).add(_amounts[i]), "Err: Exceeding maximum supply");
        }
        _mintBatch(_account, _ids, _amounts, "");
    }

    function operatorMint(address _account, uint256 _id, uint256 _amount) external _onlyOperator {
        require(exists(_id), "Err: Invalid ID");
        require(idToMaxSupply[_id] >= totalSupply(_id).add(_amount), "Err: Exceeding maximum supply");
        _mint(_account, _id, _amount, "");
    }

    //管理员发行NFT
    function mint(address _account, uint256 _id, uint256 _amount) external onlyOwner {
        require(exists(_id), "Err: Invalid ID");
        require(idToMaxSupply[_id] >= totalSupply(_id).add(_amount), "Err: Exceeding maximum supply");
        _mint(_account, _id, _amount, "");
    }

    function exists(uint256 _id) public view override returns (bool) {
        return (bytes(idToUri[_id]).length > 0);
    }

    function uri(uint256 _id) public view override returns (string memory) {
        return idToUri[_id];
    }

    function setUri(uint256 _id, string calldata _uri) external onlyOwner {
        require(exists(_id), "Err: Invalid ID");
        require(bytes(_uri).length > 0, "Err: Missing Content Identifier");
        idToUri[_id] = _uri;
        emit URI(_uri, _id);   
    }

    function setMaxSupply(uint256 _id, uint256 _maxSupply) external onlyOwner {
        require(exists(_id), "Err: Invalid ID");
        // require(_maxSupply > idToMaxSupply[_id], "Err: _maxSupply is too small");
        idToMaxSupply[_id] = _maxSupply;
        emit MaxSupply(_maxSupply, _id);
    }

    function setOperator(address _operator) external onlyOwner {
        operator = _operator;
    }

    function burn(uint256 _id, uint256 _amount) external {
        _burn(msg.sender, _id, _amount);
    }

    function burnBatch(uint256[] memory _ids, uint256[] memory _amounts) external {
        _burnBatch(msg.sender, _ids, _amounts);
    }
}
