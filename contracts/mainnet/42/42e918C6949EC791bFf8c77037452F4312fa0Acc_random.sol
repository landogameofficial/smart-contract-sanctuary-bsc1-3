/**
 *Submitted for verification at BscScan.com on 2022-11-04
*/

pragma solidity ^0.5.0 || ^0.6.0;
// pragma experimental ABIEncoderV2;

contract Governance {

    address public _governance;

    constructor() public {
        _governance = tx.origin;
    }

    event GovernanceTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyGovernance {
        require(msg.sender == _governance, "not governance");
        _;
    }

    function setGovernance(address governance)  public  onlyGovernance
    {
        require(governance != address(0), "new governance the zero address");
        emit GovernanceTransferred(_governance, governance);
        _governance = governance;
    }


}


library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SafeERC20: TRANSFER_FAILED');
    }
    // function safeTransfer(IERC20 token, address to, uint256 value) internal {
    //     callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    // }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following 
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);
    function mint(address account, uint amount) external;
    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}



contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}



library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}


interface nfttoken {
    function mint(
        address _to,
        string calldata _uri,
        uint _type
    )   
        external;
}


interface FOOTBALL {
    function isAccumulateFunds() external view returns(bool);

    function accumulateFunds( uint amounts)  external;
}

interface IPlayerBook  {
    function settleRewardUSDT(address from, uint256 amount)
        external
        returns (uint256);

    function registerGotRandom(address ac)
        external;
}


contract random is Governance {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address  usdtToken = 0x55d398326f99059fF775485246999027B3197955; 
    address public  stakeToken;
    address public _nfttoken;
    address public _footballAddr;
    address public _inviteAddr;
    address public _teamAddr;
     address public _mysticAddr1;
    address public _mysticAddr2;
    
    string[] public urls = ["QmYFTcYW7Peqso91bvj2ZWJU48CzoiCvZYUzQ7PLQVQ2Rp",
                            "QmQ5g4LJXwtEmatAzbn5NG9qJwWPmBYqdQyU76geHgpDBm",
                            "QmNqfN9fvYr6WW1iuXNWqFfYJVr2SkStZ1yvmMH8pxCZXM",
                            "QmZ5d4LqdPW35b2jD2f9CqmeEM9q7jXB2dpoan73c3ATxx",
                            "QmZnHXnnDyj7HcLuUE4nygTRJd3dYjt8Nfp5XYtWEq2ZPv",
                            "QmYhan432vYx8NDYohQrnja5t6LgA8dM5ThXy4CcuMcB1U",
                            "QmWGUZQwa7NsoHsaYdahwzPrQKN6tVEQTDy6hEMprbr3bF",
                            "QmQs9p3PXkvcUJpGFnXfM8ULDWgD1JGhYuK5FaSqm4Z95K",
                            "QmenVLFtWxkKhNMJVyfWoroPc1EALefHT3uJKVKNgfSDiF",
                            "QmRuz6cYQCV7B6h4PnRFUa6FvXyZrkVJ5S7eRuadE1byLk"];

    uint public desNum = 50*1e18;
    // uint public leftAmounts = 400;                                        

    uint randomNumber;
    struct periodSetting {
        uint _randomNumber;
        uint _person;
        uint _amounts;
        bool _end;
    }
    mapping(uint => periodSetting) public getPeriod;
    mapping(address => uint) public usrAmount;
    uint public totalAmount = 0;
    uint public curPeriod = 0;
    bool public isDigital;
    bool public ranlock = true;

    mapping(address => uint) public rewardAmount;
    mapping(address => uint) public hasRewardAmount;

    uint public totalNum = 199;
    mapping(uint => uint) public curPeriodNum;

    constructor (address new_stakeToken,address new_nfttoken,bool _isDigital,address new_inviteAddr,address new_teamAddr,address new_mysticAddr1,address new_mysticAddr2) public {
        stakeToken = new_stakeToken;
        _nfttoken = new_nfttoken;
        isDigital = _isDigital;
        _inviteAddr = new_inviteAddr;
        _teamAddr = new_teamAddr;
        _mysticAddr1 = new_mysticAddr1;
        _mysticAddr2 = new_mysticAddr2;
        randomNumber = getRandom4RepeatHash(0);
    }

    modifier onlylock {
        require(ranlock, "lock");
        ranlock = false;
        _;
    }

    function getRandom() external onlylock {

        require(curPeriodNum[curPeriod] <= totalNum,"totalNum err");
        curPeriodNum[curPeriod] = curPeriodNum[curPeriod].add(1);

        IERC20(stakeToken).safeTransferFrom(msg.sender,address(this),desNum);

        usrAmount[msg.sender] = usrAmount[msg.sender].add(desNum);
        totalAmount = totalAmount.add(desNum);

        getPeriod[curPeriod]._person = getPeriod[curPeriod]._person.add(1);

        uint _fee = 0;
        uint _totalfee = 0;
        _fee = desNum.mul(4).div(100);
        IERC20(stakeToken).safeTransfer(_footballAddr,_fee);
        if(FOOTBALL(_footballAddr).isAccumulateFunds())
        {
            FOOTBALL(_footballAddr).accumulateFunds(_fee);
        }
        _totalfee = _totalfee.add(_fee);
        _fee = desNum.mul(38).div(1000);
        IERC20(stakeToken).safeTransfer(_inviteAddr,_fee);
        IPlayerBook(_inviteAddr).settleRewardUSDT(msg.sender, desNum);
        IPlayerBook(_inviteAddr).registerGotRandom(msg.sender);
        _totalfee = _totalfee.add(_fee);
        _fee = desNum.mul(8).div(10);
        getPeriod[curPeriod]._amounts = getPeriod[curPeriod]._amounts.add(_fee);
        _totalfee = _totalfee.add(_fee);
        _fee = desNum.mul(1).div(100);
        IERC20(stakeToken).safeTransfer(_mysticAddr1,_fee.div(2));
        IERC20(stakeToken).safeTransfer(_mysticAddr2,_fee.div(2));
        _totalfee = _totalfee.add(_fee);
        IERC20(stakeToken).safeTransfer(_teamAddr,desNum.sub(_totalfee));

        uint _parame = randomNumber.mod(urls.length);
        nfttoken(_nfttoken).mint(msg.sender,urls[_parame],2);

        randomNumber = getRandom4RepeatHash(randomNumber.mod(1000000));
        ranlock = true;
    }

    
    function withdraw( uint num) external onlyGovernance {
        IERC20(stakeToken).safeTransfer(msg.sender,num);
    }

    function Reward(uint _period,address[] calldata accunts) external onlyGovernance { 
        require(_period ==  curPeriod,"_period err"); 
        require(!getPeriod[curPeriod]._end ,"_end err");  
        getPeriod[curPeriod]._end = true;

        curPeriod = curPeriod.add(1);
        periodSetting memory itemRecord;
        itemRecord._person = 0;
        itemRecord._amounts = 0;
        itemRecord._end = false;
        if(isDigital)
        {
           itemRecord._randomNumber = getRandom4RepeatHash(randomNumber.mod(1000000)).mod(10);
        }else{
            itemRecord._randomNumber = getRandom4RepeatHash(randomNumber.mod(1000000)).mod(6);
        }
        getPeriod[curPeriod] = itemRecord;

        if(getPeriod[curPeriod-1]._amounts ==0 || accunts.length == 0)
        {
            getPeriod[curPeriod]._amounts = getPeriod[curPeriod]._amounts.add(getPeriod[curPeriod-1]._amounts);
        }else{
            for(uint i=0;i<accunts.length;i++)
            {
                rewardAmount[accunts[i]] = rewardAmount[accunts[i]].add(getPeriod[curPeriod -1]._amounts.div(accunts.length));
            }
        }
        getPeriod[curPeriod-1]._amounts = 0;
    }

    function getReward() external {
        require(rewardAmount[msg.sender] > 0,"err");

        hasRewardAmount[msg.sender] = hasRewardAmount[msg.sender].add(rewardAmount[msg.sender]);

        IERC20(stakeToken).safeTransfer(msg.sender,rewardAmount[msg.sender]);

        rewardAmount[msg.sender] = 0;
    }
    
    function setDesNum( uint _desNum) external onlyGovernance {
        desNum = _desNum;
    }

    function settotalNum( uint _totalNum) external onlyGovernance {
        totalNum = _totalNum;
    }

    function set_footballAddr( address new_footballAddr) external onlyGovernance {
        _footballAddr = new_footballAddr;
    }

    function set_inviteAddr( address new_inviteAddr) external onlyGovernance {
        _inviteAddr = new_inviteAddr;
    }

    function set_teamAddr( address new_teamAddr) external onlyGovernance {
        _teamAddr = new_teamAddr;
    }

    function set_mysticAddr( address new_mysticAddr1,address new_mysticAddr2) external onlyGovernance {
        _mysticAddr1 = new_mysticAddr1;
        _mysticAddr2 = new_mysticAddr2;
    }
    
    function getRandom4RepeatHash(uint256 salt) public view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        keccak256(
                            abi.encodePacked(
                                block.timestamp,
                                block.difficulty,
                                block.coinbase,
                                msg.sender,
                                salt
                            )
                        )
                    )
                )
            );
    }
}