// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "../interfaces/IMultiFeeDistribution.sol";
import "../interfaces/IOnwardIncentivesController.sol";
import "../dependencies/openzeppelin/contracts/IERC20.sol";
import "../dependencies/openzeppelin/contracts/SafeERC20.sol";
import "../dependencies/openzeppelin/contracts/SafeMath.sol";
import "../dependencies/openzeppelin/contracts/Ownable.sol";
import "../dependencies/openzeppelin/contracts/ReentrancyGuard.sol";

// based on the Sushi MasterChef
// https://github.com/sushiswap/sushiswap/blob/master/contracts/MasterChef.sol
contract MasterChef is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }
    // Info of each pool.
    struct PoolInfo {
        uint256 allocPoint; // How many allocation points assigned to this pool.
        uint256 lastRewardTime; // Last second that reward distribution occurs.
        uint256 accRewardPerShare; // Accumulated rewards per share, times ACC_SHARE_PRECISION. See below.
        IOnwardIncentivesController onwardIncentives;
    }
    // Info about token emissions for a given time period.
    struct EmissionPoint {
        uint128 startTimeOffset;
        uint128 rewardsPerSecond;
    }

    address public immutable poolConfigurator;

    IMultiFeeDistribution public immutable rewardMinter;
    uint256 public rewardsPerSecond;
    uint256 public immutable maxMintableTokens;
    uint256 public mintedTokens;

    // Info of each pool.
    address[] public registeredTokens;
    mapping(address => PoolInfo) public poolInfo;

    // Data about the future reward rates. emissionSchedule stored in reverse chronological order,
    // whenever the number of blocks since the start block exceeds the next block offset a new
    // reward rate is applied.
    EmissionPoint[] public emissionSchedule;
    // token => user => Info of each user that stakes LP tokens.
    mapping(address => mapping(address => UserInfo)) public userInfo;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when reward mining starts.
    uint256 public startTime;
    // accurrate share pricision
    uint256 public constant ACC_SHARE_PRECISION = 1e18;

    // account earning rewards => receiver of rewards for this account
    // if receiver is set to address(0), rewards are paid to the earner
    // this is used to aid 3rd party contract integrations
    mapping (address => address) public claimReceiver;

    event Deposit(
        address indexed token,
        address indexed user,
        uint256 amount
    );

    event Withdraw(
        address indexed token,
        address indexed user,
        uint256 amount
    );

    event EmergencyWithdraw(
        address indexed token,
        address indexed user,
        uint256 amount
    );

    event PoolAdded(
        address token,
        uint256 alloc
    );

    constructor(
        uint128[] memory _startTimeOffset,
        uint128[] memory _rewardsPerSecond,
        address _poolConfigurator,
        IMultiFeeDistribution _rewardMinter,
        uint256 _maxMintable
    )
        Ownable()
    {
        poolConfigurator = _poolConfigurator;
        rewardMinter = _rewardMinter;
        uint256 length = _startTimeOffset.length;
        for (uint256 i = length - 1; i + 1 != 0; i--) {
            emissionSchedule.push(
                EmissionPoint({
                    startTimeOffset: _startTimeOffset[i],
                    rewardsPerSecond: _rewardsPerSecond[i]
                })
            );
        }
        maxMintableTokens = _maxMintable;
    }

    // adjust emission schedule
    function setEmissionSchedule(
        uint128[] memory _startTimeOffset, 
        uint128[] memory _rewardsPerSecond
    ) external onlyOwner {
        uint128 first = _startTimeOffset[0];
        uint256 length = _startTimeOffset.length;
        require(length > 0, "Array cant be 0.");
        require(first > block.timestamp.sub(startTime).add(86400), "OffsetTime can be set to at least 24hr.");
        delete emissionSchedule;
        for (uint256 i = length - 1; i + 1 != 0; i--) {
            emissionSchedule.push(
                EmissionPoint({
                    startTimeOffset: _startTimeOffset[i],
                    rewardsPerSecond: _rewardsPerSecond[i]
                })
            );
        }
    }

    // Start the party
    function start() public onlyOwner {
        require(startTime == 0);
        startTime = block.timestamp;
    }

    // Add a new lp to the pool. Can only be called by the poolConfigurator.
    function addPool(address _token, uint256 _allocPoint) external onlyOwner {
        require(poolInfo[_token].lastRewardTime == 0);
        _updateEmissions();
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        registeredTokens.push(_token);
        poolInfo[_token] = PoolInfo({
            allocPoint: _allocPoint,
            lastRewardTime: block.timestamp,
            accRewardPerShare: 0,
            onwardIncentives: IOnwardIncentivesController(0)
        });
        emit PoolAdded(_token, _allocPoint);
    }

    // Update the given pool's allocation point. Can only be called by the owner.
    function batchUpdateAllocPoint(
        address[] calldata _tokens,
        uint256[] calldata _allocPoints
    ) public onlyOwner {
        require(_tokens.length == _allocPoints.length);
        _massUpdatePools();
        uint256 _totalAllocPoint = totalAllocPoint;
        for (uint256 i = 0; i < _tokens.length; i++) {
            PoolInfo storage pool = poolInfo[_tokens[i]];
            require(pool.lastRewardTime > 0, "token invalid!");
            _totalAllocPoint = _totalAllocPoint.sub(pool.allocPoint).add(_allocPoints[i]);
            pool.allocPoint = _allocPoints[i];
        }
        totalAllocPoint = _totalAllocPoint;
    }

    function setClaimReceiver(address _user, address _receiver) external {
        require(msg.sender == _user || msg.sender == owner());
        claimReceiver[_user] = _receiver;
    }

    function poolLength() external view returns (uint256) {
        return registeredTokens.length;
    }

    function claimableReward(address _user, address[] calldata _tokens)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory claimable = new uint256[](_tokens.length);
        for (uint256 i = 0; i < _tokens.length; i++) {
            address token = _tokens[i];
            PoolInfo storage pool = poolInfo[token];
            UserInfo storage user = userInfo[token][_user];
            uint256 accRewardPerShare = pool.accRewardPerShare;
            uint256 lpSupply = IERC20(token).balanceOf(address(this));
            if (block.timestamp > pool.lastRewardTime && lpSupply != 0) {
                uint256 duration = block.timestamp.sub(pool.lastRewardTime);
                uint256 reward = duration.mul(rewardsPerSecond).mul(pool.allocPoint).div(totalAllocPoint);
                accRewardPerShare = accRewardPerShare.add(reward.mul(ACC_SHARE_PRECISION).div(lpSupply));
            }
            claimable[i] = user.amount.mul(accRewardPerShare).div(ACC_SHARE_PRECISION).sub(user.rewardDebt);
        }
        return claimable;
    }

    function _updateEmissions() internal {
        uint256 length = emissionSchedule.length;
        if (startTime > 0 && length > 0) {
            EmissionPoint memory e = emissionSchedule[length-1];
            if (block.timestamp.sub(startTime) > e.startTimeOffset) {
                 _massUpdatePools();
                rewardsPerSecond = uint256(e.rewardsPerSecond);
                emissionSchedule.pop();
            }
        }
    }

    // Update reward variables for all pools
    function _massUpdatePools() internal {
        uint256 totalAP = totalAllocPoint;
        uint256 length = registeredTokens.length;
        for (uint256 i = 0; i < length; ++i) {
            _updatePool(registeredTokens[i], totalAP);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function _updatePool(address _token, uint256 _totalAllocPoint) internal {
        PoolInfo storage pool = poolInfo[_token];
        if (block.timestamp <= pool.lastRewardTime) {
            return;
        }
        uint256 lpSupply = IERC20(_token).balanceOf(address(this));
        if (lpSupply == 0 || _totalAllocPoint == 0) {
            pool.lastRewardTime = block.timestamp;
            return;
        }
        uint256 duration = block.timestamp.sub(pool.lastRewardTime);
        if(_totalAllocPoint != 0){
          uint256 reward = duration.mul(rewardsPerSecond).mul(pool.allocPoint).div(_totalAllocPoint);
          pool.accRewardPerShare = pool.accRewardPerShare.add(reward.mul(ACC_SHARE_PRECISION).div(lpSupply));
          pool.lastRewardTime = block.timestamp;
        }

    }


    function _mint(address _user, uint256 _amount) internal {
        uint256 minted = mintedTokens;
        if (minted.add(_amount) > maxMintableTokens) {
            _amount = maxMintableTokens.sub(minted);
        }
        if (_amount > 0) {
            mintedTokens = minted.add(_amount);
            address receiver = claimReceiver[_user];
            if (receiver == address(0)) receiver = _user;
            rewardMinter.mint(receiver, _amount, true);
        }
    }

    // Deposit LP tokens into the contract. Also triggers a claim.
    function deposit(address _token, uint256 _amount) external nonReentrant {
        PoolInfo storage pool = poolInfo[_token];
        require(pool.lastRewardTime > 0, "token invalid!");
        UserInfo storage user = userInfo[_token][msg.sender];
        _updateEmissions();
        _updatePool(_token, totalAllocPoint);
        // suppoet fot token
        uint256 balanceBefore = IERC20(_token).balanceOf(address(this)); 
        IERC20(_token).safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
        _amount = IERC20(_token).balanceOf(address(this)).sub(balanceBefore);
        // claim reward
        if (user.amount > 0) {
            uint256 pending =
                user.amount.mul(pool.accRewardPerShare).div(ACC_SHARE_PRECISION).sub(
                    user.rewardDebt
                );
            _mint(msg.sender, pending);
        }
        // update user info
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(ACC_SHARE_PRECISION);

        
        
        emit Deposit(_token, msg.sender, _amount);

    }

    // Withdraw LP tokens. Also triggers a claim.
    function withdraw(address _token, uint256 _amount) external nonReentrant {
        PoolInfo storage pool = poolInfo[_token];
        require(pool.lastRewardTime > 0, "token invalid!");
        UserInfo storage user = userInfo[_token][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        _updateEmissions();
        _updatePool(_token, totalAllocPoint);
        // pending reward
        uint256 pending =
            user.amount.mul(pool.accRewardPerShare).div(ACC_SHARE_PRECISION).sub(
                user.rewardDebt
            );
         // update user info
        user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(ACC_SHARE_PRECISION);
        
        _mint(msg.sender, pending);
        IERC20(_token).safeTransfer(address(msg.sender), _amount); 

        emit Withdraw(_token, msg.sender, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(address _token) external nonReentrant {
        PoolInfo storage pool = poolInfo[_token];
        require(pool.lastRewardTime > 0, "token invalid!");
        UserInfo storage user = userInfo[_token][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        IERC20(_token).safeTransfer(address(msg.sender), amount);

        emit EmergencyWithdraw(_token, msg.sender, amount);
    }

    // Claim pending rewards for one or more pools.
    // Rewards are not received directly, they are minted by the rewardMinter.
    function claim(address _user, address[] calldata _tokens) external nonReentrant {
        _updateEmissions();
        uint256 pending;
        uint256 _totalAllocPoint = totalAllocPoint;
        require(_totalAllocPoint != 0, "Total alloc must > 0");
        for (uint i = 0; i < _tokens.length; i++) {
            PoolInfo storage pool = poolInfo[_tokens[i]];
            require(pool.lastRewardTime > 0, "token invalid!");
            _updatePool(_tokens[i], _totalAllocPoint);
            UserInfo storage user = userInfo[_tokens[i]][_user];
            pending = pending.add(user.amount.mul(pool.accRewardPerShare).div(ACC_SHARE_PRECISION).sub(user.rewardDebt));
            user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(ACC_SHARE_PRECISION);
        }
        _mint(_user, pending);
    }

    function updateEmissions() external onlyOwner {
        _updateEmissions();
    }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IMultiFeeDistribution {

    function addReward(address rewardsToken) external;
    function mint(address user, uint256 amount, bool withPenalty) external;
    function exit() external;
    function withdrawExpiredLocks() external;
    function getReward() external;

}

pragma solidity 0.7.6;

interface IOnwardIncentivesController {
    function handleAction(
        address _user,
        uint256 _balance,
        uint256 _totalSupply
    ) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

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

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import {IERC20} from './IERC20.sol';
import {SafeMath} from './SafeMath.sol';
import {Address} from './Address.sol';

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  using SafeMath for uint256;
  using Address for address;

  function safeTransfer(
    IERC20 token,
    address to,
    uint256 value
  ) internal {
    callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
  }

  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint256 value
  ) internal {
    callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
  }

  function safeApprove(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    require(
      (value == 0) || (token.allowance(address(this), spender) == 0),
      'SafeERC20: approve from non-zero to non-zero allowance'
    );
    callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
  }

  function callOptionalReturn(IERC20 token, bytes memory data) private {
    require(address(token).isContract(), 'SafeERC20: call to non-contract');

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = address(token).call(data);
    require(success, 'SafeERC20: low-level call failed');

    if (returndata.length > 0) {
      // Return data is optional
      // solhint-disable-next-line max-line-length
      require(abi.decode(returndata, (bool)), 'SafeERC20: ERC20 operation did not succeed');
    }
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
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
    require(c >= a, 'SafeMath: addition overflow');

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
    return sub(a, b, 'SafeMath: subtraction overflow');
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
  function sub(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
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
    require(c / a == b, 'SafeMath: multiplication overflow');

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
    return div(a, b, 'SafeMath: division by zero');
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
   */
  function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
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
    return mod(a, b, 'SafeMath: modulo by zero');
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
   */
  function mod(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import './Context.sol';

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
contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor() {
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
    require(_owner == _msgSender(), 'Ownable: caller is not the owner');
    _;
  }

  /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
  function renounceOwnership() public virtual onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), 'Ownable: new owner is the zero address');
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
 abstract contract ReentrancyGuard {
     // Booleans are more expensive than uint256 or any type that takes up a full
     // word because each write operation emits an extra SLOAD to first read the
     // slot's contents, replace the bits taken up by the boolean, and then write
     // back. This is the compiler's defense against contract upgrades and
     // pointer aliasing, and it cannot be disabled.

     // The values being non-zero value makes deployment a bit more expensive,
     // but in exchange the refund on every call to nonReentrant will be lower in
     // amount. Since refunds are capped to a percentage of the total
     // transaction's gas, it is best to keep them low in cases like this one, to
     // increase the likelihood of the full refund coming into effect.
     uint256 private constant _NOT_ENTERED = 1;
     uint256 private constant _ENTERED = 2;

     uint256 private _status;

     constructor () internal {
         _status = _NOT_ENTERED;
     }

     /**
      * @dev Prevents a contract from calling itself, directly or indirectly.
      * Calling a `nonReentrant` function from another `nonReentrant`
      * function is not supported. It is possible to prevent this from happening
      * by making the `nonReentrant` function external, and make it call a
      * `private` function that does the actual work.
      */
     modifier nonReentrant() {
         // On the first call to nonReentrant, _notEntered will be true
         require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

         // Any calls to nonReentrant after this point will fail
         _status = _ENTERED;

         _;

         // By storing the original value once again, a refund is triggered (see
         // https://eips.ethereum.org/EIPS/eip-2200)
         _status = _NOT_ENTERED;
     }
 }

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;

/**
 * @dev Collection of functions related to the address type
 */
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
    assembly {
      codehash := extcodehash(account)
    }
    return (codehash != accountHash && codehash != 0x0);
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
   */
  function sendValue(address payable recipient, uint256 amount) internal {
    require(address(this).balance >= amount, 'Address: insufficient balance');

    // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
    (bool success, ) = recipient.call{value: amount}('');
    require(success, 'Address: unable to send value, recipient may have reverted');
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
  function _msgSender() internal view virtual returns (address payable) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}