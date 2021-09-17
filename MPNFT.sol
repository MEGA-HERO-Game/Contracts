// SPDX-License-Identifier: SimPL-2.0

pragma solidity >=0.8.0;

import "../node_modules/openzeppelin-solidity/contracts/token/ERC1155/ERC1155.sol";
import "../node_modules/openzeppelin-solidity/contracts/token/ERC1155/IERC1155Receiver.sol"; 
contract MPNFT is ERC1155, IERC1155Receiver{
    address private _governance;
    address private _ibox_exchange;
    uint256 private _index;

    mapping(uint256=>string) private _uris;


    struct UserNftInfo{
        mapping(uint256=> int256) _nfts;
        uint256[] _nft_ids;
    }
    mapping(address=>UserNftInfo) private _user_nfts;

    event AddTokensEvent(
        uint256 []assetId,
        string []uris,
        uint256[] ids,
        uint256 requestId
    );


    event DeleteNFTEvent(
        uint256 requestId,
        address user,
        uint256 assetId
    );

    function addUserNftInfo(address user, uint256 assetId) internal{
        if (_user_nfts[user]._nfts[assetId] == 0){
            _user_nfts[user]._nfts[assetId] = 1;
            _user_nfts[user]._nft_ids.push(assetId);
        }

    }


    modifier onlyGovernance(){
        require (msg.sender == _governance, "nft only governance cann call this");

        _;
    }

    

    constructor (address governance_, address ibox_exchange) public ERC1155("http://localhost:28080/e/{id}.json"){
        _governance = governance_;
        _ibox_exchange = ibox_exchange;
        _index = 10000;
    }

    function setIboxExchange(address ibox_exchange) external onlyGovernance{
        _ibox_exchange = ibox_exchange;
    }

    function getIboxExchange () public view returns(address){
        return _ibox_exchange;
    }


    function createTokenForIboxExchange ( uint256 amount, string memory uri) public returns (uint256){
        require (msg.sender == _ibox_exchange, "nft only ibox exchange can call this");

        _index ++;

        _mint(_governance, _index, amount, "");
        _uris[_index] = uri;
        addUserNftInfo(_governance, _index);
        return _index;
    }

    

    function burnToken (uint256 requestId, address user, uint256 assetId, uint amount) external onlyGovernance{
        // emit DeleteNFTEvent(requestId, user, assetId);
        _burn(user, assetId, amount);
        emit DeleteNFTEvent(requestId, user, assetId);
    }

    function addTokens ( uint256 [] memory copies, uint256 []memory souceIds, string [] memory uri_, uint256 requestId_, address user) external onlyGovernance {
        uint l = copies.length;

        uint256 [] memory ids_ = new uint256[](l);
        for (uint i = 0; i < l; i++){
            _index ++;
            ids_[i] = _index;
            _mint(user, _index, copies[i], "");
            _uris[_index] = uri_[i];
            addUserNftInfo(user, _index);
        }

        emit AddTokensEvent (ids_, uri_, souceIds, requestId_);
    }

    function uri(uint256 tokenId_) public view virtual override returns (string memory) {
        return _uris[tokenId_];
    }

    function getTokenCount () public view returns (uint256){
        return _index;
    }

    struct UserAssetInfo{
        uint256 assetId;
        uint256 amount;
    }

    function getUserAssetIds (address user) public view returns (uint256 [] memory){

        return _user_nfts[user]._nft_ids;
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
        public
        virtual
        override
    {
        super.safeTransferFrom(from, to, id, amount, data);
        addUserNftInfo(to, id);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        public
        virtual
        override
    {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);

        uint l = ids.length;

        for (uint i = 0; i < l; i++){
            addUserNftInfo(to, ids[i]);
        }
        
    }

    function onERC1155Received(address operator, address from, uint256 id, uint256 value, bytes calldata data)
     external virtual override returns(bytes4){
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external  virtual override
        returns(bytes4){
            return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    }
}