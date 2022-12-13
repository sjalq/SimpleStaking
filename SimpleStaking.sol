// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.0;

abstract contract IERC20
{
    function deposit() payable public virtual;
    function withdraw(uint _amount) public virtual;
    function balanceOf() public virtual returns (uint); 
    function transferFrom(address _from, address _to, uint256 _amount) external virtual returns (bool);
    function transfer(address to, uint256 amount) external virtual returns (bool);
}

contract SimpleStaking 
{
    IERC20 public vara; // = IERC20(0xYourVaraTokenContractAddress) 
    IERC20 public nodal; // = IERC20(0xYourNodalTokenContractAddress)
     
    mapping (address => uint) stakedFunds;
    mapping (address => uint) releaseDates; 

    event Staked(uint _amount, uint _duration, uint _releaseDate);
    event Unstaked(uint _amount, uint _releaseDate);

    function max(uint a, uint b) public pure returns (uint) {
        return a >= b ? a : b;
    }

    function Stake(uint _amount, uint _duration)
        public
    {
        uint currentStake = stakedFunds[msg.sender];
        uint releaseDate = releaseDates[msg.sender];
        _unstake(currentStake);
        _stake(currentStake + _amount, max(_duration + block.timestamp, releaseDate));
    }

    function Unstake(uint _amount)
        public
    {
        // require now exceeds msg.sender's releaseDate
        require(releaseDates[msg.sender] > block.timestamp, "Too early to unstake");
        _unstake(_amount);
    }

    function _stake(uint _amount, uint _releaseDate)
        private
    {
        // transfer _amount of vara to this contract
        vara.transferFrom(msg.sender, address(this), _amount);

        // transfer 100*10**18 of nodal to this contract
        nodal.transferFrom(msg.sender, address(this), 100*10**18);

        // update the mappings
        stakedFunds[msg.sender] = _amount; // not += because we unstake first to emit noeugh info to do the accounting for the merkle drop
        releaseDates[msg.sender] = _releaseDate;

        // emit a Stake event
        emit Staked(_amount, _releaseDate - block.timestamp, _releaseDate);
    }

    function _unstake(uint _amount)
        private
    {
        // ensure that the staker has _amount staked
        require(stakedFunds[msg.sender] >= _amount, "Unstaking too much");
        // emit an unstaking event
        emit Unstaked(_amount, releaseDates[msg.sender]);
        // update the mappings
        stakedFunds[msg.sender] -= _amount; // this actually is a check as it would have an underflow error
        releaseDates[msg.sender] = 0;
        // transfer _amount of vara to msg.sender
        vara.transfer(msg.sender, _amount);
        // transfer 100*10**18 of nodal to msg.sender
        nodal.transfer(msg.sender, _amount);
    }
}
