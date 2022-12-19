// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

abstract contract IERC20
{
    function transferFrom(address _from, address _to, uint256 _amount) external virtual returns (bool);
    function transfer(address to, uint256 amount) external virtual returns (bool);
}

contract SimpleStaking 
{
    IERC20 public vara; // = IERC20(0xYourVaraTokenContractAddress) 
     
    mapping (address => uint) stakedFunds;
    mapping (address => uint) releaseDates; 

    event Staked(address _staker, uint _amount, uint _duration, uint _releaseDate);
    event Unstaked(address _staker, uint _amount, uint _releaseDate);

    function max(uint a, uint b) public pure returns (uint) {
        return a >= b ? a : b;
    }

    function Stake(uint _amount)
        public
    {
        require(_amount + stakedFunds[msg.sender] > 300 * 10**18, "stake must be greater than 300 vara");

        uint currentStake = stakedFunds[msg.sender];
        _unstake(currentStake);
        _stake(currentStake + _amount, 90 days + block.timestamp);
    }

    function Unstake(uint _amount)
        public
    {
        require(releaseDates[msg.sender] > block.timestamp, "too early to unstake");
        _unstake(_amount);
    }

    function _stake(uint _amount, uint _releaseDate)
        private
    {
        // update the mappings
        stakedFunds[msg.sender] = _amount; // not += because we unstake first to emit noeugh info to do the accounting for the merkle drop
        releaseDates[msg.sender] = _releaseDate;

        // transfer _amount of vara to this contract
        vara.transferFrom(msg.sender, address(this), _amount);

        // emit a Stake event
        emit Staked(_amount, _releaseDate - block.timestamp, _releaseDate);
    }

    function _unstake(uint _amount)
        private
    {
        // ensure that the staker has _amount staked
        require(stakedFunds[msg.sender] >= _amount, "unstaking too much");
        // emit an unstaking event
        emit Unstaked(_amount, releaseDates[msg.sender]);
        // update the mappings
        stakedFunds[msg.sender] -= _amount; // this actually is also a require as it would have an underflow error
        releaseDates[msg.sender] = 0;
        // transfer _amount of vara to msg.sender
        vara.transfer(msg.sender, _amount);
    }
}
