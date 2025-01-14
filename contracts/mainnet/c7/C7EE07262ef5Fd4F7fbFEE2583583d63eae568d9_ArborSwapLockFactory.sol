// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "contracts/ArborSwapRewardsLockSimple.sol";
import "contracts/ArborSwapRewardsLockVesting.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";


contract ArborSwapLockFactory is Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _lockIds;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    address payable public feeAddr;
    uint256 public lockFeeSimple;
    uint256 public lockFeeVesting;

    address[] public locks;
    mapping(address => EnumerableSet.UintSet) private _userLockIds;
    EnumerableSet.AddressSet private _lockedTokens;
    mapping(address => EnumerableSet.UintSet) private _tokenToLockIds;

    mapping(uint256 => address) lockIdToAddy;
    event LogCreateSimpleLock(address lock, address owner);
    event LogCreateVestingLock(address lock, address owner);
    event LogSetFeeSimple(uint256 fee);
    event LogSetFeeVesting(uint256 fee);
    event LogSetFeeAddress(address fee);

    function createSimpleLock(uint _duration, uint256 amount, address _token) external payable{
        require(msg.value >= lockFeeSimple, "Not enough BNB sent");
        require(IERC20(_token).balanceOf(msg.sender) >= amount, "Insufficient funds.");
        require(IERC20(_token).allowance(msg.sender, address(this)) >= amount, "Insufficient allowance.");
        ArborSwapRewardsLockSimple lock = new ArborSwapRewardsLockSimple(msg.sender,_duration,amount, _token, address(this));
        uint256 lockId = _lockIds.current();
        address lockAddy = lock.getAddress();
        _lockIds.increment();
        locks.push(lockAddy);
        _userLockIds[msg.sender].add(lockId);
        _lockedTokens.add(_token);
        _tokenToLockIds[_token].add(lockId);
        lockIdToAddy[lockId] = lockAddy;
        IERC20(_token).transferFrom(msg.sender, lockAddy, amount);
        lock.lock();
        feeAddr.transfer(msg.value);
        emit LogCreateSimpleLock(lockAddy, msg.sender);
    }

    function createVestingLock(
        uint _numberOfPortions,
        uint timeBetweenPortions,
        uint distributionStartDate,
        uint _TGEPortionUnlockingTime,
        uint256 _TGEPortionPercent,
        address _token, 
        uint256 amount) external payable {

        require(msg.value >= lockFeeVesting, "Not enough BNB sent");
        require(IERC20(_token).balanceOf(msg.sender) >= amount, "Insufficient funds.");
        require(IERC20(_token).allowance(msg.sender, address(this)) >= amount, "Insufficient allowance.");

        ArborSwapRewardsLockVesting lock = new ArborSwapRewardsLockVesting(
        _numberOfPortions,
        timeBetweenPortions,
        distributionStartDate,
        _TGEPortionUnlockingTime,
        msg.sender,
        _token,
        address(this));

        uint256 lockId = _lockIds.current();
        address lockAddy = lock.getAddress();
        _lockIds.increment();
        locks.push(lockAddy);
        _userLockIds[msg.sender].add(lockId);
        _lockedTokens.add(_token);
        _tokenToLockIds[_token].add(lockId);
        lockIdToAddy[lockId] = lockAddy;
        IERC20(_token).transferFrom(msg.sender, lockAddy, amount);
        lock.lock(amount, _TGEPortionPercent);
        feeAddr.transfer(msg.value);

        emit LogCreateVestingLock(lockAddy, msg.sender);
    }

    function setFeeSimple(uint256 fee) external onlyOwner{
        require(fee != lockFeeSimple, "Already set to this value"); 
        lockFeeSimple = fee;
        emit LogSetFeeSimple(fee);
    }

    function setFeeVesting(uint256 fee) external onlyOwner{
        require(fee != lockFeeVesting, "Already set to this value"); 
        lockFeeVesting = fee;
        emit LogSetFeeVesting(fee);
    }

    function setFeeAddress(address payable fee) external onlyOwner{
        require(fee != feeAddr, "Already set to this value"); 
        feeAddr = fee;
        emit LogSetFeeAddress(fee);
    }

    function getTotalLockCount() external view returns (uint256) {
        // Returns total lock count, regardless of whether it has been unlocked or not
        return locks.length;
    }

    function getLockAt(uint256 index) external view returns (address) {
        return locks[index];
    }

    function getLockById(uint256 lockId) public view returns (address) {
        return lockIdToAddy[lockId];
    }

    function allTokenLockedCount() public view returns (uint256) {
        return _lockedTokens.length();
    }

    function lockCountForUser(address user)
        public
        view
        returns (uint256)
    {
        return _userLockIds[user].length();
    }

    function locksForUser(address user)
        external
        view
        returns (address[] memory)
    {
        uint256 length = _userLockIds[user].length();
        address[] memory userLocks = new address[](length);

        for (uint256 i = 0; i < length; i++) {
            userLocks[i] = getLockById(_userLockIds[user].at(i));
        }
        return userLocks;
    }

    function lockForUserAtIndex(address user, uint256 index)
        external
        view
        returns (address)
    {
        require(lockCountForUser(user) > index, "Invalid index");
        return getLockById(_userLockIds[user].at(index));
    }

    function totalLockCountForToken(address token)
        external
        view
        returns (uint256)
    {
        return _tokenToLockIds[token].length();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";


contract ArborSwapRewardsLockSimple {

   using SafeMath for uint256;
   uint256 public lockedAmount;
   uint256 public fee;
   uint public duration;
   uint public unlockDate;
   address public owner;
   address public factory;
   IERC20 public token;
   bool public tokensWithdrawn;
   bool public tokensLocked;

   event LogLock(uint unlockDate, uint256 lockedAmount);
   event LogWithdraw(address to, uint256 lockedAmount);
   event LogWithdrawReflections(address to, uint256 amount);
   event LogWithdrawDividends(address to, uint256 dividends);
   event LockUpdated(uint256 newAmount, uint256 newUnlockDate);

   modifier onlyOwner {
        require(msg.sender == owner, "OnlyOwner: Restricted access.");
        _;
   }

   modifier onlyOwnerOrFactory {
        require(msg.sender == owner || msg.sender == factory, "OnlyOwnerOrFactory: Restricted access.");
        _;
   }

   constructor(address _owner, uint _duration, uint256 amount, address _token, address _factory) public {
       require(_owner != address(0), "Invalid owner address"); 
       owner = _owner;
       duration = _duration;
       lockedAmount = amount;
       token = IERC20(_token);
       factory = _factory;
   }

   function lock() public payable onlyOwnerOrFactory {
       require(tokensLocked == false, "Already locked");
       unlockDate = block.timestamp + duration;
       tokensLocked = true;
       emit LogLock(unlockDate, lockedAmount);
   }

   function editLock(
        uint256 newAmount,
        uint256 newUnlockDate
    ) external onlyOwner {
        require(tokensWithdrawn == false, "Lock was unlocked");

        if (newUnlockDate > 0) {
            require(
                newUnlockDate >= unlockDate &&
                    newUnlockDate > block.timestamp,
                "New unlock time should not be before old unlock time or current time"
            );
            unlockDate = newUnlockDate;
        }

        if (newAmount > 0) {
            require(
                newAmount >= lockedAmount,
                "New amount should not be less than current amount"
            );

            uint256 diff = newAmount - lockedAmount;

            if (diff > 0) {
                lockedAmount = newAmount;
                token.transferFrom(msg.sender, address(this), diff);
            }
        }

        emit LockUpdated(
            newAmount,
            newUnlockDate
        );
    }

   function unlock() external onlyOwner{
       require(block.timestamp >= unlockDate, "too early");
       require(tokensWithdrawn == false);
       tokensWithdrawn = true;

       token.transfer(owner, lockedAmount);

       emit LogWithdraw(owner, lockedAmount);
   }

   function withdrawReflections() external onlyOwner{
       if(tokensWithdrawn){
           uint256 reflections = token.balanceOf(address(this));
           if(reflections > 0){
              token.transfer(owner, reflections);
           }
           emit LogWithdrawReflections(owner, reflections);
       } else {
            uint256 contractBalanceWReflections = token.balanceOf(address(this));
            uint256 reflections = contractBalanceWReflections - lockedAmount;
            if(reflections > 0){
              token.transfer(owner, reflections);
            }
            emit LogWithdrawReflections(owner, reflections);
       }
   }

   function withdrawDividends(address _token) external onlyOwner{
       uint256 dividends = IERC20(_token).balanceOf(address(this));
       if(dividends > 0){
          IERC20(_token).transfer(owner, dividends);
       }
       emit LogWithdrawDividends(owner, dividends);
   }

   function getAddress() external view returns(address){
       return address(this);
   }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";



contract ArborSwapRewardsLockVesting {

    using SafeMath for *;

    uint public totalTokensWithdrawn;
    
    uint256 public TGEPortion;
    uint256 public vestedLockedAmount;
    uint256 public amountPerPortion;
    bool public TGEPortionWithdrawn;
    bool[] public isVestedPortionWithdrawn;
    bool public allTokensWithdrawn;
    bool public tokensLocked;
    IERC20 public dividendToken;
    
    address public factory;
    IERC20 public token;

    address public owner;


    uint public TGEPortionUnlockingTime;
    uint public numberOfPortions;
    uint [] distributionDates;

    event LogLock(address owner, uint256 amount);
    event LogWithdrawReflections(address owner, uint256 reflections);
    event LogWithdrawDividends(address owner, uint256 dividends);

    modifier onlyOwner {
        require(msg.sender == owner, "OnlyOwner: Restricted access.");
        _;
    }

    modifier onlyOwnerOrFactory {
        require(msg.sender == owner || msg.sender == factory, "OnlyOwnerOrFactory: Restricted access.");
        _;
    }


    /// Load initial distribution dates Vesting
    constructor (
        uint _numberOfPortions,
        uint timeBetweenPortions,
        uint distributionStartDate,
        uint _TGEPortionUnlockingTime,
        address _owner,
        address _token,
        address _factory
    ) {   
        require(_owner != address(0), "Invalid owner address"); 
        require(_token != address(0), "Invalid token address");
       
        owner = _owner;
        // Store number of portions
        numberOfPortions = _numberOfPortions;
        factory = _factory; 

        // Time when initial portion is unlocked
        TGEPortionUnlockingTime = _TGEPortionUnlockingTime;

        // Set distribution dates
        for(uint i = 0 ; i < _numberOfPortions; i++) {
            distributionDates.push(distributionStartDate + i*timeBetweenPortions);
        }
        // Set the token address
        token = IERC20(_token);
    }


    /// Register participant
    function lock(
        uint256 amount,
        uint tgePortionPercent
    )
    external payable onlyOwnerOrFactory {
        

        require(!tokensLocked, "Tokens already locked.");
    
        uint TGEPortionAmount = amount.mul(tgePortionPercent).div(100);
        
        uint vestedAmount = amount.sub(TGEPortionAmount);

        // Compute amount per portion
        uint portionAmount = vestedAmount.div(numberOfPortions);
        bool[] memory isPortionWithdrawn = new bool[](numberOfPortions);

        
        TGEPortion = TGEPortionAmount;
        vestedLockedAmount = vestedAmount;
        amountPerPortion = portionAmount;
        TGEPortionWithdrawn = false;
        isVestedPortionWithdrawn = isPortionWithdrawn;
    
       
        tokensLocked = true;
        
        emit LogLock(owner, amount);
    }


    // User will always withdraw everything available
    function withdraw()
    external onlyOwner
    {
        address user = msg.sender;
        require(tokensLocked == true, "Withdraw: Tokens were not locked.");

        uint256 totalToWithdraw = 0;

        // Initial portion can be withdrawn
        if(!TGEPortionWithdrawn && block.timestamp >= TGEPortionUnlockingTime) {
            totalToWithdraw = totalToWithdraw.add(TGEPortion);
            // Mark initial portion as withdrawn
            TGEPortionWithdrawn = true;
        }


        // For loop instead of while
        for(uint i = 0 ; i < numberOfPortions ; i++) {
            if(isPortionUnlocked(i) == true && i < distributionDates.length) {
                if(!isVestedPortionWithdrawn[i]) {
                    // Add this portion to withdraw amount
                    totalToWithdraw = totalToWithdraw.add(amountPerPortion);

                    // Mark portion as withdrawn
                    isVestedPortionWithdrawn[i] = true;
                }
            }
        }

        // Account total tokens withdrawn.
        totalTokensWithdrawn = totalTokensWithdrawn.add(totalToWithdraw);
        if(totalTokensWithdrawn == vestedLockedAmount + TGEPortion){
            allTokensWithdrawn = true;
        }
        // Transfer all tokens to user
        token.transfer(user, totalToWithdraw);
    }

    function withdrawReflections() external onlyOwner{
       if(allTokensWithdrawn){
           uint256 reflections = token.balanceOf(address(this));
           if(reflections > 0){
              token.transfer(owner, reflections);
           }
           emit LogWithdrawReflections(owner, reflections);
       } else {
            uint256 contractBalanceWReflections = token.balanceOf(address(this));
            uint256 reflections = contractBalanceWReflections - (vestedLockedAmount + TGEPortion);
            if(reflections > 0){
              token.transfer(owner, reflections);
            }
            emit LogWithdrawReflections(owner, reflections);
       }
   }

    function withdrawDividends(address _token) external onlyOwner{
       uint256 dividends = IERC20(_token).balanceOf(address(this));
       if(dividends > 0){
          IERC20(_token).transfer(owner, dividends);
       }
       emit LogWithdrawDividends(owner, dividends);
   }

    function isPortionUnlocked(uint portionId)
    public
    view
    returns (bool)
    {
        return block.timestamp >= distributionDates[portionId];
    }

    // Get all distribution dates
    function getDistributionDates()
    external
    view
    returns (uint256 [] memory)
    {
        return distributionDates;
    }

    function getAddress() external view returns(address){
       return address(this);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}