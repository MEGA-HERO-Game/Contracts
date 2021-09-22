// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "@openzeppelin/contracts@4.3.0/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts@4.3.0/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts@4.3.0/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts@4.3.0/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts@4.3.0/access/Ownable.sol";
import "@openzeppelin/contracts@4.3.0/utils/math/SafeMath.sol";

contract DiamondCardPools is Ownable, ERC1155Holder {
    
    using SafeMath for uint256;
    IERC1155 public diamondCard;

    using SafeERC20 for IERC20;
    IERC20 public usdt;
    
    mapping (uint256 => uint256) public idToDiamond;
    uint256[] public supportIds;

    mapping (uint256 => mapping(address => uint256)) public userDepositCard;

    uint256 public lastRewardBlock;//上次更新区块号
    uint256 public accRewardPerShare;//每份收益

    uint256 public startBlock;//启动挖矿块号
    uint256 public ratePerBlock;//每个块的收益率

    uint256 public totalAmount;//总质押量
    uint256 public totalRewardDebt;//用户总负债
    uint256 public totalRewardRemain;//用户存档总收益

    // Info of each user.
    struct UserInfo {
        uint256 amount;         // 用户质押资产折合钻石的数量
        uint256 rewardDebt;     // 负债数量，用于收益计算
        uint256 rewardRemain;   // 暂存的盈利刷灵，用于收益计算
    }

    mapping (address => UserInfo) public userInfo;

    event Claim(address indexed user, uint256 amount);
    event Deposit(address indexed user, uint256 id, uint256 value);
    event DepositBatch(address indexed user, uint256[] ids, uint256[] values);
    event Withdraw(address indexed user, uint256[] ids, uint256[] values);
    event EmergencyWithdraw(address indexed user, uint256[] ids, uint256[] values);

    modifier _onlyDiamondCard() {
        require(address(diamondCard) == _msgSender(), "Err: caller is not the diamondCard");
        _;
    }

    constructor(IERC1155 _diamondCard, IERC20 _usdt, uint256 _startBlock, uint256 _ratePerBlock) {
        diamondCard = _diamondCard;//钻石NFT合约地址
        usdt = _usdt;
        startBlock = _startBlock;//启动挖矿的块号
        ratePerBlock = _ratePerBlock;//每个块使用多少比例的usdt用于奖励，基数是1e9
    }

    function addTokenId(uint256 _id, uint256 _diamond) external onlyOwner {
        require(_diamond > 0, "Err: parameter error");
        require(idToDiamond[_id] == 0, "Err: id already exists");
        idToDiamond[_id] = _diamond;//该NFT折合钻石数量
        supportIds.push(_id);
    }

    //设置每个区块的分红比例
    function setRatePerBlock(uint256 _ratePerBlock) external onlyOwner {
        updatePool();
        ratePerBlock = _ratePerBlock;
    }

    //领取收益
    function claim() external {
        updatePool();
        recalculateReward(msg.sender, userInfo[msg.sender].amount);

        UserInfo storage _userinfo = userInfo[msg.sender];
        if(_userinfo.rewardRemain > 0){
            totalRewardRemain = totalRewardRemain.sub(_userinfo.rewardRemain);
            uint256 _rewardRemain = _userinfo.rewardRemain;
            _userinfo.rewardRemain = 0;
            usdt.safeTransfer(msg.sender, _rewardRemain);
            Claim(msg.sender, _rewardRemain);
        }
    }

    //存入
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) public override _onlyDiamondCard returns (bytes4) {
        uint256 _totalDeposit = _deposit(id, value, operator);
        updatePool();
        recalculateReward(operator, _totalDeposit + userInfo[operator].amount);
        emit Deposit(operator, id, value);
        return super.onERC1155Received(operator, from, id, value, data);
    }

    //批量存入
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) public override _onlyDiamondCard returns (bytes4) {
        uint256 _totalDeposit = 0;
        for(uint256 i = 0; i < ids.length; i++){
            _totalDeposit = _totalDeposit.add(_deposit(ids[i], values[i], operator));
        }
        updatePool();
        recalculateReward(operator, _totalDeposit + userInfo[operator].amount);
        emit DepositBatch(operator, ids, values);
        return super.onERC1155BatchReceived(operator, from, ids, values, data);
    }

    //提取本金
    function withdraw(uint256[] calldata ids, uint256[] calldata values) external{
        uint256 _totalWithdraw = 0;
        for(uint256 i = 0; i < ids.length; i++){
            _totalWithdraw = _totalWithdraw.add(_withdraw(ids[i], values[i]));
        }
        updatePool();
        recalculateReward(msg.sender, userInfo[msg.sender].amount.sub(_totalWithdraw));
        emit Withdraw(msg.sender, ids, values);
        diamondCard.safeBatchTransferFrom(address(this), msg.sender, ids, values, "");
    }

    //查询账户总收益
    function pendingRewards(address _addr) view external returns(uint256){
        uint256 _pendingAccRewardPerShare = pendingAccRewardPerShare();

        UserInfo memory _userinfo = userInfo[_addr];
        return _pendingAccRewardPerShare.mul(_userinfo.amount).sub(_userinfo.rewardDebt).add(_userinfo.rewardRemain);
    }


    //重新计算账户信息
    function recalculateReward(address _user, uint256 _totalDiamond) internal{

        UserInfo storage _userinfo = userInfo[_user];
        
        //更新收益
        totalRewardRemain = totalRewardRemain.sub(_userinfo.rewardRemain);
        _userinfo.rewardRemain = _userinfo.rewardRemain.add( _userinfo.amount.mul(accRewardPerShare).sub(_userinfo.rewardDebt) );
        totalRewardRemain = totalRewardRemain.add(_userinfo.rewardRemain);

        //更新资金量
        totalAmount = totalAmount.sub(_userinfo.amount);
        _userinfo.amount = _totalDiamond;
        totalAmount = totalAmount.add(_userinfo.amount);

        //更新负债
        totalRewardDebt = totalRewardDebt.sub(_userinfo.rewardDebt);
        _userinfo.rewardDebt = _userinfo.amount.mul(accRewardPerShare);
        totalRewardDebt = totalRewardDebt.add(_userinfo.rewardDebt);
    }

    function _deposit(uint256 _id, uint256 _amount, address _user) internal returns(uint256) {
        require(idToDiamond[_id] > 0, "Err: Unsupported ID");
        userDepositCard[_id][_user] = userDepositCard[_id][_user].add(_amount);
        return idToDiamond[_id].mul(_amount);
    }

    function _withdraw(uint256 _id, uint256 _amount) internal returns(uint256) {
        require(idToDiamond[_id] > 0, "Err: Unsupported ID");
        require(userDepositCard[_id][msg.sender] >= _amount, "Err: Withdraw amount exceeds deposit");
        userDepositCard[_id][msg.sender] = userDepositCard[_id][msg.sender].sub(_amount);
        return idToDiamond[_id].mul(_amount);
    }

    //刷新每份收益
    function updatePool() internal {

        if(block.number == lastRewardBlock){
            return;
        }
        accRewardPerShare = pendingAccRewardPerShare();
        lastRewardBlock = block.number;
    }

    //获取最新的每份收益
    function pendingAccRewardPerShare() public view returns(uint256){
        if(totalAmount == 0){
            return 0;
        }
        uint256 _totalUsdt = usdt.balanceOf(address(this));
        uint256 _availabilityUsdt = _totalUsdt.sub( accRewardPerShare.mul(totalAmount).sub(totalRewardDebt).add(totalRewardRemain) );//可用的U = 所有的U - 待用户提取的U

        uint256 allocateUsdt = 0;
        if(ratePerBlock.mul(block.number - lastRewardBlock) >= 1e9){
            allocateUsdt = _availabilityUsdt;//分配比例超过 1，就只有把剩下的全分了
        } else {
            allocateUsdt = _availabilityUsdt.mul(ratePerBlock).mul(block.number - lastRewardBlock).div(1e9);//本次待分配的U
        }
        return accRewardPerShare.add(allocateUsdt.div(totalAmount));
    }

    //放弃收益，紧急情况下撤出本金
    function emergencyWithdraw(uint256[] calldata ids, uint256[] calldata values) external{
        uint256 _totalWithdraw = 0;
        for(uint256 i = 0; i < ids.length; i++){
            _totalWithdraw = _totalWithdraw.add(_withdraw(ids[i], values[i]));
        }

        UserInfo storage _userinfo = userInfo[msg.sender];
        totalRewardRemain = totalRewardRemain.sub(_userinfo.rewardRemain);
        _userinfo.rewardRemain = 0;

        totalAmount = totalAmount.sub(_userinfo.amount);
        _userinfo.amount = 0;

        totalRewardDebt = totalRewardDebt.sub(_userinfo.rewardDebt);
        _userinfo.rewardDebt = 0;

        diamondCard.safeBatchTransferFrom(address(this), msg.sender, ids, values, "");
        emit EmergencyWithdraw(msg.sender, ids, values);
    }

    function getSupportIds() public view returns(uint256[] memory){
        return supportIds;
    }

    function getUserDepositList(address _user) external view returns(uint256[] memory _ids, uint256[] memory _values){
        _ids = getSupportIds();
        _values = new uint256[](_ids.length);
        for(uint256 i = 0; i < _ids.length; i++){
            _values[i] = userDepositCard[_ids[i]][_user];
        }
    }

    receive() external payable {
        revert();
    }
}
