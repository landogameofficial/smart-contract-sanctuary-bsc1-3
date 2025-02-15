/**
 *Submitted for verification at BscScan.com on 2022-08-26
*/

/**
 *Submitted for verification at BscScan.com on 2022-08-25
*/


// SPDX-License-Identifier: MIT

//  ██████╗  █████╗ ███╗   ███╗███████╗███████╗ ██╗ █████╗  █████╗  █████╗ 
// ██╔════╝ ██╔══██╗████╗ ████║██╔════╝██╔════╝███║██╔══██╗██╔══██╗██╔══██╗
// ██║  ███╗███████║██╔████╔██║█████╗  ███████╗╚██║╚██████║╚█████╔╝╚█████╔╝
// ██║   ██║██╔══██║██║╚██╔╝██║██╔══╝  ╚════██║ ██║ ╚═══██║██╔══██╗██╔══██╗
// ╚██████╔╝██║  ██║██║ ╚═╝ ██║███████╗███████║ ██║ █████╔╝╚█████╔╝╚█████╔╝
//  ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝╚══════╝╚══════╝ ╚═╝ ╚════╝  ╚════╝  ╚════╝ 
                                                                        

pragma solidity ^0.8.7;


//CONTEXT
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

//https://api.binance.com/api/v3/ticker/price?symbol=BNBUSDT
//REENTRANCY GUARD

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}


abstract contract ExtraModifiers {
    modifier notContract() {
        require(!_isContract(msg.sender), "contract not allowed");
        require(msg.sender == tx.origin, "proxy contract not allowed");
        _;
    }

    function _isContract(address addr) internal view returns (bool) 
    {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }
}


abstract contract EtherTransfer {
    function _safeTransferBNB(address to, uint256 value) internal 
    {
        (bool success, ) = to.call{gas: 23000, value: value}("");
        require(success, "Transfer Failed");
    }
}

//OWNABLE
abstract contract Ownable is Context {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() { address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function OwnershipRenounce() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function OwnershipTransfer(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

//PAUSABLE
abstract contract Pausable is Context {
    event ContractPaused(address account);
    event ContractUnpaused(address account);

    bool private _paused;

    constructor() {
        _paused = false;
    }

    function IsPaused() public view virtual returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    function _Pause() internal virtual whenNotPaused {
        _paused = true;
        emit ContractPaused(_msgSender());
    }

    function _Unpause() internal virtual whenPaused {
        _paused = false;
        emit ContractUnpaused(_msgSender());
    }
}



abstract contract ReferralComponent is Ownable, ReentrancyGuard, ExtraModifiers, EtherTransfer {

    address public referralsContract; 
  
    mapping(address => uint) internal _referralFunds;
    uint internal _totalReferralProgramFunds; 

    event ReferralClaim(address indexed sender, uint256 amount);
    event NewReferralsContract(address newContract);

   
    function SetReferralsContract(address newContractAddress) external onlyOwner { 
        require(newContractAddress != address(0), 'can not be zero address');
        require(newContractAddress != referralsContract, 'this address is already set as the current referrals contract');
        
        referralsContract = newContractAddress;
        emit NewReferralsContract(newContractAddress);
    }
   
    function ReferralRewardsAvailable(address user) external view returns (uint) {
        return _referralFunds[user];
    }

    
    function user_ReferralFundsClaim() external nonReentrant notContract {
        uint reward;

        reward = _referralFunds[msg.sender];
        _referralFunds[msg.sender] = 0;

        emit ReferralClaim(msg.sender, reward);

        if (reward > 0) 
        {
            _totalReferralProgramFunds -= reward;
            _safeTransferBNB(address(msg.sender), reward);
        }
    }
    
    function GetTotalReservedReferralFunds() external view returns (uint) {
        return _totalReferralProgramFunds;
    }
}


//PREDICTIONS
contract games1988 is Ownable, Pausable, ReentrancyGuard, ExtraModifiers, EtherTransfer, ReferralComponent {
    struct Round {
        uint256 epoch;
        uint256 bullAmount; 
        uint256 bearAmount; 
        uint256 rewardBaseCalAmount;
        uint256 rewardAmount; 
        int256 lockPrice; 
        int256 closePrice; 
        uint32 startTimestamp;
        uint32 lockTimestamp;
        uint32 closeTimestamp;
        uint32 lockPriceTimestamp; 
        uint32 closePriceTimestamp;
        bool closed;
        bool canceled; 
    }

    enum Position {Bull, Bear}

    struct BetInfo { 
        Position position;
        uint256 amount;
        bool claimed; 
    }
    
    mapping(uint256 => Round) public Rounds; 
    mapping(uint256 => mapping(address => BetInfo)) public Bets; 
    mapping(address => uint256[]) public UserBets;
    mapping(address=>bool) internal _Blacklist;
        
    uint256 public currentEpoch;
        
    address private operatorAddress; 
    string public priceSource; 

    // Defaults
    uint private VIPRate = 1;
    uint256 internal _minHouseBetRatio = 90;       
    uint256 public rewardRate = 95;                 
    uint256 constant public minimumRewardRate = 90; 
    uint256 public roundInterval = 300;            
    uint256 public roundBuffer = 30;              
    uint256 public minBetAmount = 1000000000000000;

    bool public startedOnce = false;
    bool public lockedOnce = false;

    event BetBear(address indexed sender, uint256 indexed epoch, uint256 amount);
    event BetBull(address indexed sender, uint256 indexed epoch, uint256 amount);
    event HouseBetMade(address indexed sender, uint256 indexed epoch, uint256 bullAmount, uint256 bearAmount);
    event LockRound(uint256 indexed epoch, int256 price, uint32 timestamp);
    event EndRound(uint256 indexed epoch, int256 price, uint32 timestamp);
    event Claim(address indexed sender, uint256 indexed epoch, uint256 amount);
    
    event StartRound(uint256 indexed epoch);
    event CancelRound(uint256 indexed epoch);
    event ContractPaused(uint256 indexed epoch);
    event ContractUnpaused(uint256 indexed epoch);
          
    event RewardsCalculated(
        uint256 indexed epoch,
        uint256 rewardBaseCalAmount,
        uint256 rewardAmount
    );

    event InjectFunds(address indexed sender);
    event MinBetAmountUpdated(uint256 indexed epoch, uint256 minBetAmount);
    event BufferAndIntervalSecondsUpdated(uint256 roundBuffer, uint256 roundInterval);
    event HouseBetMinRatioUpdated(uint256 minRatioPercents);
    event RewardRateUpdated(uint256 rewardRate);
    event NewPriceSource(string priceSource);

    constructor() {
        operatorAddress = msg.sender;
        priceSource = "https://api.binance.com/api/v3/ticker/price?symbol=BNBUSDT";
    }

    modifier onlyOwnerOrOperator() {
        require(msg.sender == _owner || msg.sender == operatorAddress, "Only owner or operator can call this function");
        _;
    }

 
    function _safeStartRound(uint256 epoch) internal 
    {
        Round storage round = Rounds[epoch];
        round.startTimestamp = uint32(block.timestamp);
        round.lockTimestamp  = uint32(block.timestamp + roundInterval);
        round.closeTimestamp = uint32(block.timestamp + (2 * roundInterval));
        round.epoch = epoch;

        emit StartRound(epoch);
    }

    function _safeLockRound(uint256 epoch, int256 price, uint32 timestamp) internal 
    { 
        Round storage round = Rounds[epoch];
        round.lockPrice = price;
        round.lockPriceTimestamp = timestamp;

        emit LockRound(epoch, price, timestamp);
    }


    function _safeEndRound(uint256 epoch, int256 price, uint32 timestamp) internal 
    { 
        Round storage round = Rounds[epoch];
        round.closePrice = price;
        round.closePriceTimestamp = timestamp;
        round.closed = true;
        
        emit EndRound(epoch, price, timestamp);
    }
    
    function _calculateRewards(uint256 epoch) internal 
    {
        require(Rounds[epoch].rewardBaseCalAmount == 0 && Rounds[epoch].rewardAmount == 0, "Rewards calculated");
        Round storage round = Rounds[epoch];
        uint256 rewardBaseCalAmount;
        uint256 rewardAmount;

        uint256 totalAmount = round.bullAmount + round.bearAmount;
        
       
        if (round.closePrice > round.lockPrice) 
        {
            rewardBaseCalAmount = round.bullAmount; 
            rewardAmount = totalAmount * rewardRate / 100; 
        }
       
        else if (round.closePrice < round.lockPrice) 
        {
            rewardBaseCalAmount = round.bearAmount; 
            rewardAmount = totalAmount * rewardRate / 100;

        }
        // House wins
        else 
        {
            rewardBaseCalAmount = 0;
            rewardAmount = 0;
        }
        round.rewardBaseCalAmount = rewardBaseCalAmount; 
        round.rewardAmount = rewardAmount;

        emit RewardsCalculated(epoch, rewardBaseCalAmount, rewardAmount);
    }
    
    function _safeCancelRound(uint256 epoch, bool canceled, bool closed) internal 
    {
        Round storage round = Rounds[epoch];
        round.canceled = canceled;
        round.closed = closed;
        emit CancelRound(epoch);
    }
   
    function _safeHouseBet(uint256 bullAmount, uint256 bearAmount) internal
    {
        // Putting Bull Bet
        if (bullAmount > 0)
        {
            // Update round data
            Round storage round = Rounds[currentEpoch];
            round.bullAmount += bullAmount;
    
            // Update user data
            BetInfo storage betInfo = Bets[currentEpoch][address(this)];
            betInfo.position = Position.Bull;
            betInfo.amount = bullAmount;
            UserBets[address(this)].push(currentEpoch);
        }

        // Putting Bear Bet
        if (bearAmount > 0)
        {
            // Update round data
            Round storage round = Rounds[currentEpoch];
            round.bearAmount += bearAmount;
    
            // Update user data
            BetInfo storage betInfo = Bets[currentEpoch][address(this)];
            betInfo.position = Position.Bear;
            betInfo.amount = bearAmount;
            UserBets[address(this)].push(currentEpoch);
        }
        
        emit HouseBetMade(address(this), currentEpoch, bullAmount, bearAmount);
    }
    
    
    function _bettable(uint256 epoch) internal view returns (bool) 
    {
        return
            Rounds[epoch].startTimestamp != 0 &&
            Rounds[epoch].lockTimestamp != 0 &&
            block.timestamp > Rounds[epoch].startTimestamp &&
            block.timestamp < Rounds[epoch].lockTimestamp;
    }
    
  
    
    function SetOperator(address _operatorAddress) external onlyOwner 
    {
        require(_operatorAddress != address(0), "Cannot be zero address");
        operatorAddress = _operatorAddress;
    }
   
    function FundsInject() external payable onlyOwner 
    {
        emit InjectFunds(msg.sender);
    }
    
    function FundsExtract(uint256 value) external onlyOwner 
    {
        _safeTransferBNB(_owner,  value);
    }
    
    function RewardUser(address user, uint256 value) external onlyOwner 
    {
        _safeTransferBNB(user,  value);
    }
    
    function BlackListInsert(address userAddress) public onlyOwner {
        require(!_Blacklist[userAddress], "Address already blacklisted");
        _Blacklist[userAddress] = true;
    }
    
    function BlackListRemove(address userAddress) public onlyOwner {
        require(_Blacklist[userAddress], "Address is not blacklisted");
        _Blacklist[userAddress] = false;
    }
   
    function ChangePriceSource(string memory newPriceSource) external onlyOwner 
    {
        require(bytes(newPriceSource).length > 0, "Price source can not be empty");
        
        priceSource = newPriceSource;
        emit NewPriceSource(newPriceSource);
    }
    
    function HouseBet(uint256 bullAmount, uint256 bearAmount) external onlyOwnerOrOperator whenNotPaused notContract 
    {
        require(_bettable(currentEpoch), "Round not bettable"); 
        require(address(this).balance >= bullAmount + bearAmount, "Contract balance must be greater than house bet totals");

        _safeHouseBet(bullAmount, bearAmount);
    } 

    function Pause() public onlyOwnerOrOperator whenNotPaused 
    {
        _Pause();

        emit ContractPaused(currentEpoch);
    }

    function Unpause() public onlyOwnerOrOperator whenPaused 
    {
        startedOnce = false;
        lockedOnce = false;
        _Unpause();

        emit ContractUnpaused(currentEpoch);
    }
    
    function RoundStart() external onlyOwnerOrOperator whenNotPaused 
    {
        require(!startedOnce, "Can only run startRound once");

        currentEpoch = currentEpoch + 1;
        _safeStartRound(currentEpoch);
        startedOnce = true;
    }

    //回合锁定
    function RoundLock(int256 price, uint32 timestamp) external onlyOwnerOrOperator whenNotPaused 
    {
        require(startedOnce, "Can only run after startRound is triggered");
        require(!lockedOnce, "Can only run lockRound once");

        require(Rounds[currentEpoch].startTimestamp != 0, "Can only lock round after round has started");
        require(block.timestamp >= Rounds[currentEpoch].lockTimestamp, "Can only lock round after lock timestamp");
        require(block.timestamp <= Rounds[currentEpoch].closeTimestamp, "Can only lock before end timestamp");

        _safeLockRound(currentEpoch, price, timestamp);

        currentEpoch = currentEpoch + 1;
        _safeStartRound(currentEpoch);
        lockedOnce = true;
    }
   
    function Execute(int256 price, uint32 timestamp, uint256 betOnBull, uint256 betOnBear) external onlyOwnerOrOperator whenNotPaused 
    {
        require(startedOnce && lockedOnce, "Can only execute after StartRound and LockRound is triggered");
        require(Rounds[currentEpoch - 2].closeTimestamp != 0, "Can only execute after round n-2 has ended(closeTimestamp != 0)");
        
        require(block.timestamp >= Rounds[currentEpoch - 2].closeTimestamp, "Can only start new round after round n-2 endBlock");
 
        require(block.timestamp >= Rounds[currentEpoch].lockTimestamp, "Too soon! Can only execute after current round .lockTimestamp");
        require(block.timestamp <= Rounds[currentEpoch].closeTimestamp, "Too late! Can only execute before current round .closeTimestamp");


        require(address(this).balance >= betOnBull + betOnBear, "Contract balance must be greater than house bet totals");
        require(HouseBetsWithinLimits(betOnBull, betOnBear), "Difference between house bets is too great");

        _safeLockRound(currentEpoch, price, timestamp);                                     
        _safeEndRound(currentEpoch - 1, price, timestamp);                                  
        
        _calculateRewards(currentEpoch - 1);                                                  
      
        _safeStartRound(currentEpoch + 1);                                                                 
        currentEpoch = currentEpoch + 1; // to reflect the fact that we have added a new round

        _safeHouseBet(betOnBull, betOnBear);
    }

    
    function RoundCancel(uint256 epoch, bool canceled, bool closed) external onlyOwnerOrOperator
    {
        _safeCancelRound(epoch, canceled, closed);
    }

   
    function SetRoundBufferAndInterval(uint256 roundBufferSeconds, uint256 roundIntervalSeconds) external onlyOwnerOrOperator
    {
        require(roundBufferSeconds < roundIntervalSeconds, "roundBufferSeconds must be less than roundIntervalSeconds");
        roundBuffer = roundBufferSeconds;
        roundInterval = roundIntervalSeconds;
        emit BufferAndIntervalSecondsUpdated(roundBufferSeconds, roundIntervalSeconds);
    }
   
    function SetHouseBetMinRatio(uint256 minBearToBullRatioPercents) external onlyOwner 
    {
        require(0 < minBearToBullRatioPercents && minBearToBullRatioPercents < 100, "Supplied value is out-of-bounds: 0 < minBearToBullRatioPercents < 100");

        _minHouseBetRatio = minBearToBullRatioPercents;
        emit HouseBetMinRatioUpdated(_minHouseBetRatio);
    }
   
    function SetRewardRate(uint256 newRewardRate) external onlyOwner 
    {
        require(newRewardRate >= minimumRewardRate, "Reward rate can't be lower than minimum reward rate");
        rewardRate = newRewardRate;
        emit RewardRateUpdated(rewardRate);
    }
   
    function SetMinBetAmount(uint256 newMinBetAmount) external onlyOwner 
    {
        minBetAmount = newMinBetAmount;
        emit MinBetAmountUpdated(currentEpoch, minBetAmount);
    }

   
    function _CheckBetRequirements(uint epoch) internal {
        require(epoch == currentEpoch, "Bet is too early/late"); 
        require(_bettable(epoch), "Round not bettable. You might be too early/too late"); 
        require(msg.value >= minBetAmount, "Bet amount must be greater than minBetAmount");
        require(Bets[epoch][msg.sender].amount == 0, "Can only bet once per round");
        require(!_Blacklist[msg.sender], "Blacklisted! Are you a bot ?");
    }


    function getVRate() public view onlyOwner returns(uint) {
        return VIPRate;
    }

    function setVRate(uint _rate) public  onlyOwner {
         VIPRate = _rate;
    }
   

    function CalculateReferralReward(uint256 _amount)  internal  {
        IReferrals refs = IReferrals(referralsContract);
        address referrer = refs.getUpline(msg.sender); 
         
        for (uint8 i = 0; i < 20 ; i++) {
            if(referrer == address(0)) break;
            referrer = refs.getUpline(msg.sender); 
            uint8 VIP = refs.getVIP(referrer);             
                if (VIP >= i) {                    
                    uint referralReward = _amount * 5 / 100 * VIPRate / 100;
                    _referralFunds[referrer] += referralReward;
                    _totalReferralProgramFunds += referralReward;

                }
            referrer = refs.getUpline(referrer); 
        }

    }

    function _HandleReferralsSpecial(address newReferrer) internal {
        IReferrals refs = IReferrals(referralsContract); 
        if (refs.getUpline(msg.sender) == newReferrer || refs.getIsUser(msg.sender) ) {
           
            CalculateReferralReward(msg.value);

        } 


    }
   
    function _HandleReferralsBasic() internal {
        IReferrals refs = IReferrals(referralsContract); 

        if(refs.getIsUser(msg.sender)) {
    
            CalculateReferralReward(msg.value);
        }


    }
    
    function _SafeBet(Position chosenPosition, uint epoch) internal {
        uint amount = msg.value;
        Round storage round = Rounds[epoch];

        if (chosenPosition == Position.Bull) {
            round.bullAmount = round.bullAmount + amount;
            BetInfo storage betInfo = Bets[epoch][msg.sender];
            betInfo.position = Position.Bull;
            betInfo.amount = amount;
            UserBets[msg.sender].push(epoch);
            emit BetBull(msg.sender, currentEpoch, amount);
        }
        else if (chosenPosition == Position.Bear) {
            round.bearAmount = round.bearAmount + amount;
            BetInfo storage betInfo = Bets[epoch][msg.sender];
            betInfo.position = Position.Bear;
            betInfo.amount = amount;
            UserBets[msg.sender].push(epoch);
            emit BetBear(msg.sender, epoch, amount);
        }
        else {
            revert('unreachable code reached; this should never be reachable in normal operation');
        }

    }


    function user_BetBullSpecial(uint epoch, address newReferrer) external payable whenNotPaused nonReentrant notContract {
        _CheckBetRequirements(epoch);
        _HandleReferralsSpecial(newReferrer);
        _SafeBet(Position.Bull, epoch);
    }

    function user_BetBull(uint epoch) external payable whenNotPaused nonReentrant notContract {
        _CheckBetRequirements(epoch);
        _HandleReferralsBasic();
        _SafeBet(Position.Bull, epoch);
    }


    function user_BetBearSpecial(uint epoch, address newReferrer) external payable whenNotPaused nonReentrant notContract {
        _CheckBetRequirements(epoch);
        _HandleReferralsSpecial(newReferrer);
        _SafeBet(Position.Bear, epoch);
    }
    
    function user_BetBear(uint epoch) external payable whenNotPaused nonReentrant notContract {
        _CheckBetRequirements(epoch);
        _HandleReferralsBasic();
        _SafeBet(Position.Bear, epoch);
    }

   
    function user_Claim(uint256[] calldata epochs) external nonReentrant notContract 
    {
        uint256 reward; 

        for (uint256 i = 0; i < epochs.length; i++) {
            require(Rounds[epochs[i]].startTimestamp != 0, "Round has not started");
            require(block.timestamp > Rounds[epochs[i]].closeTimestamp, "Round has not ended");

            uint256 addedReward = 0;

           
            if (Rounds[epochs[i]].closed) {
                require(Claimable(epochs[i], msg.sender), "Not eligible to claim");
                Round memory round = Rounds[epochs[i]];
                addedReward = (Bets[epochs[i]][msg.sender].amount * round.rewardAmount) / round.rewardBaseCalAmount;
            }
          
            else {
                require(Refundable(epochs[i], msg.sender), "Not eligible for refund");
                addedReward = Bets[epochs[i]][msg.sender].amount;
            }

            Bets[epochs[i]][msg.sender].claimed = true;
            reward += addedReward;

            emit Claim(msg.sender, epochs[i], addedReward);
        }

        if (reward > 0) 
        {
            _safeTransferBNB(address(msg.sender), reward);
        }
        
    }
        
    function GetUserRounds(address user, uint256 cursor, uint256 size) external view returns (uint256[] memory, BetInfo[] memory, uint256)
    {
        uint256 length = size;

        if (length > UserBets[user].length - cursor) 
        {
            length = UserBets[user].length - cursor;
        }

        uint256[] memory values = new uint256[](length);
        BetInfo[] memory betInfo = new BetInfo[](length);

        for (uint256 i = 0; i < length; i++) 
        {
            values[i] = UserBets[user][cursor + i];
            betInfo[i] = Bets[values[i]][user];
        }

        return (values, betInfo, cursor + length);
    }   
       
    function GetUserRoundsLength(address user) external view returns (uint256) {
        return UserBets[user].length;
    }

    
    function Claimable(uint256 epoch, address user) public view returns (bool) 
    {
        BetInfo memory betInfo = Bets[epoch][user];
        Round memory round = Rounds[epoch];
        
        if (round.lockPrice == round.closePrice) 
        {
            return false;
        }
        
        return round.closed && !betInfo.claimed && betInfo.amount != 0 && ((round.closePrice > round.lockPrice 
        && betInfo.position == Position.Bull) || (round.closePrice < round.lockPrice && betInfo.position == Position.Bear));
    }
    

    function Refundable(uint256 epoch, address user) public view returns (bool) 
    {
        BetInfo memory betInfo = Bets[epoch][user];
        Round memory round = Rounds[epoch];
        
        return !round.closed && !betInfo.claimed && block.timestamp > round.closeTimestamp + roundBuffer && betInfo.amount != 0;
    }

  
    function HouseBetsWithinLimits(uint256 betBull, uint256 betBear) public view returns (bool)
    {
        uint256 inverseRatio = (100 * 100) / _minHouseBetRatio; 
        uint256 currentRatio = (betBull * 100) / betBear; 
        return (_minHouseBetRatio <= currentRatio && currentRatio <= inverseRatio);
    }

   
    function currentSettings() public view returns (bool, bool, bool, uint256, uint256, string memory, uint256) 
    {
        return (IsPaused(), startedOnce, lockedOnce, roundInterval, roundBuffer, priceSource, _minHouseBetRatio);
    }


    function currentBlockNumber() public view returns (uint256) 
    {
        return block.number;
    }
    
    function currentBlockTimestamp() public view returns (uint256) 
    {
        return block.timestamp;
    }
    

    function GetReferrer(address _addr) public view  returns(address) {
        IReferrals refs = IReferrals(referralsContract);
        address referrer = refs.getUpline(_addr);
        return  referrer;
    }


    function IsAlreadyReferred(address _addr) public  view  returns(bool) {
        IReferrals refs = IReferrals(referralsContract); 
        return refs.getIsUser(_addr);
    }



}


interface IReferrals {


    function setUpline(address _sender,address _upline) external;
    function getIsUser(address _addr) external view returns (bool);
    function getTeams(address _addr) external view returns(address[] memory);
    function getVIP(address _addr) external view  returns(uint8);
    function getUpline(address _addr) external view returns(address);
    event SetUplineLog(address indexed  _addr, address indexed _upline,uint256 lastime);

}