/**
 *Submitted for verification at BscScan.com on 2022-08-04
*/

// Code written by MrGreenCrypto
// SPDX-License-Identifier: None
pragma solidity 0.8.15;

interface IBEP20 {
  function decimals() external view returns (uint8);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract StakingWithFixedTokensPerCycle {
    address public token;
    address public admin;
    uint256 public blocksPerCycle;
    uint256 public lastRewardBlock;
    uint256 public tokensPerCycle;
    uint256 public lockDuration;
    uint256 public totalRewardsSentOutAlready;
    uint256 public totalStakedTokens;
    uint256 private _decimals;
    uint256 private secondsPerBlock = 3;
    uint256 private _accuracyFactor = 10 ** 36;    
    uint256 private _totalRewardsPerToken;
    mapping (address => Stake) public stakes;

    struct Stake {
        uint256 stakedAmount;
        uint256 oldRewards;
        uint256 rewardsCollected;
        uint256 lockedUntil;
    }

	event Realised(address account, uint amount);
    event Staked(address account, uint stakedAmount);
    event Unstaked(address account, uint amount);

    modifier onlyOwner() {if(msg.sender != admin) return; _;}

    constructor (address stakingToken, address tokenOwner, uint256 _tokensPerCycle, uint256 _blocksPerCycle, uint256 lockTime) {
        token = stakingToken;
        admin = tokenOwner;
        lastRewardBlock = block.number;
        lockDuration = lockTime;
        _decimals = IBEP20(token).decimals();
        tokensPerCycle = _tokensPerCycle * 10 ** _decimals;
        blocksPerCycle = _blocksPerCycle;
    }

    function getStake(address account) public view returns (uint256) {
        return stakes[account].stakedAmount;
    }

    function getTotalClaimsOfStaker(address staker) external view returns (uint256) {
        return stakes[staker].rewardsCollected;
    }

    function claimableRewards(address staker) public view returns (uint256){
        uint256 totalRewards = stakes[staker].stakedAmount *  _totalRewardsPerToken / _accuracyFactor;
        uint256 availableRewardsOfStaker = totalRewards - stakes[staker].oldRewards;
        return availableRewardsOfStaker;
    }

    function StakeSome(uint amount) external {
        require(amount > 0);
        amount = amount * 10 ** _decimals;
        IBEP20(token).transferFrom(msg.sender, address(this), amount);
        _stake(msg.sender, amount);
    }

    function StakeAll() external {
        uint256 amount = IBEP20(token).balanceOf(msg.sender) * 9999 / 10000;
        require(amount > 0);
        IBEP20(token).transferFrom(msg.sender, address(this), amount);
        _stake(msg.sender, amount);
    }

    function UnstakeSome(uint amount) external {
        require(amount > 0);
        amount = amount * 10 ** _decimals;
        _unstake(msg.sender, amount);
    }

    function UnstakeAll() external {
        uint256 amount = getStake(msg.sender);
        require(amount > 0);
        _unstake(msg.sender, amount);
    }
    
    function ClaimRewards() external {
        _realise(msg.sender);
    }

    function updateRewards() internal {
        uint256 cyclesSinceLastTime = (block.number - lastRewardBlock) / blocksPerCycle;
        if (totalStakedTokens == 0 || cyclesSinceLastTime == 0) return;
        lastRewardBlock += cyclesSinceLastTime * blocksPerCycle;
        uint256 newRewards = cyclesSinceLastTime * tokensPerCycle;
        uint256 additionalAmountPerStakedToken = newRewards * _accuracyFactor / totalStakedTokens;
        _totalRewardsPerToken += additionalAmountPerStakedToken;
    }

    function _realise(address staker) internal {
        updateRewards();
        uint256 totalRewards = stakes[staker].stakedAmount *  _totalRewardsPerToken / _accuracyFactor;
        if(stakes[staker].stakedAmount == 0 || totalRewards <= stakes[staker].oldRewards) return;
        uint256 rewardsToRealise = totalRewards - stakes[staker].oldRewards;
        stakes[staker].rewardsCollected += rewardsToRealise;
        totalRewardsSentOutAlready += rewardsToRealise;
        IBEP20(token).transfer(staker, rewardsToRealise);
        stakes[staker].oldRewards = stakes[staker].stakedAmount * _totalRewardsPerToken / _accuracyFactor;
        emit Realised(staker, rewardsToRealise / (10 ** _decimals));
    }

    function _stake(address staker, uint256 stakedAmount) internal {
        require(stakedAmount > 0);
        _realise(staker);
        stakes[staker].lockedUntil = block.timestamp + lockDuration;
        stakes[staker].stakedAmount += stakedAmount;
        stakes[staker].oldRewards = stakes[staker].stakedAmount * _totalRewardsPerToken / _accuracyFactor;
        totalStakedTokens += stakedAmount;
        emit Staked(staker, stakedAmount / (10 ** _decimals));
    }

    function _unstake(address staker, uint256 amount) internal {
        require(stakes[staker].lockedUntil <= block.timestamp, "Your staked tokens are still locked, please try again later");
        _realise(staker);
        stakes[staker].stakedAmount -= amount;
        stakes[staker].oldRewards = stakes[staker].stakedAmount * _totalRewardsPerToken / _accuracyFactor;
        totalStakedTokens -= amount;
        IBEP20(token).transfer(staker, amount);
        emit Unstaked(staker, amount / (10 ** _decimals));
    }

    function fillThePool(uint256 howManyCycles) external onlyOwner {
        IBEP20(token).transferFrom(msg.sender, address(this), howManyCycles * tokensPerCycle);
        lastRewardBlock = block.number;
    }

    function convertDaysToCycles(uint256 _days) public view returns(uint256) {
        return (_days * 1 days) / (blocksPerCycle * secondsPerBlock);
    }

    function convertWeeksToCycles(uint256 _weeks) public view returns(uint256) {
        return (_weeks * 1 weeks) / (blocksPerCycle * secondsPerBlock);
    }

    function convertMonthsToCycles(uint256 _months) public view returns(uint256) {
        return (_months * 30 days) / (blocksPerCycle * secondsPerBlock);
    }
}