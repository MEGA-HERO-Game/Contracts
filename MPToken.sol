// SPDX-License-Identifier: SimPL-2.0

pragma solidity >=0.8.0;

import "../node_modules/openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";

contract MPToken is ERC20{
    // 超级帐户
    address private _governance;

    //普通操作帐户
    address private _operator;

    constructor (address governance_) public ERC20("MP","MP"){
        _governance = governance_;
        _operator = governance_;
    }

    modifier onlyGovernance(){
        require (msg.sender == _governance, "mp token only governance cann call this");

        _;
    }

    modifier onlyOperator(){
        require (msg.sender == _operator || msg.sender == _governance, "only operator cann call this");

        _;
    }



    function mintToken (address account, uint256 amount) external onlyOperator{

        _mint(account, amount);
    }

    

}