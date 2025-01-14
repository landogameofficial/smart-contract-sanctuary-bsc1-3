// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "./interfaces/IMarket.sol";
import "./utils/Math.sol";

/**
 * Change log:
 * 1. Add `initTimestamp` to save the initialization timestamp.
 * 2. Add `publicOfferingMaxCapPerUser` to limit the purchase limit of public offering users
 * 3. Change the decimals of the token to 18.
 */
contract GenesisLaunchAuctionV2 is Context, Ownable {
    using SafeERC20 for IERC20;

    // a flag to mark whitelist user
    uint256 public constant EXISTS_IN_WHITELIST = type(uint256).max;

    // whitelist phase start time
    uint256 public whitelistEnabledAt;
    // public offering phase start time
    uint256 public publicOfferingEnabledAt;
    // init phase start time
    uint256 public initAt;
    // unlock phase start time
    uint256 public unlockAt;
    // a flag to mark if it has been initialized
    bool public initialized = false;
    // initialization timestamp
    uint256 public initTimestamp;

    // whitelist price(1e18)
    uint256 public whitelistPrice;
    // public offering price(1e18)
    uint256 public publicOfferingPrice;
    // soft USD cap,
    // if the final USD cap does not reach softCap, the market will not start
    uint256 public softCap;
    // hard USD cap,
    // the final USD cap will not exceed hardCap
    uint256 public hardCap;
    // the amount of usdc that a whitelist user can buy
    uint256 public whitelistMaxCapPerUser;
    // quantity that each user can purchase at a time
    uint256 public publicOfferingMaxCapPerUser;

    // Chaos token address
    IERC20 public Chaos;
    // BUSD token address
    IERC20 public BUSD;
    // Market contract address
    IMarket public market;

    // the total number of whitelist users raised
    uint256 public whitelistTotalShares;
    // list of whitelist users
    address[] public whitelist;
    // shares of each whitelist user
    mapping(address => uint256) public whitelistSharesOf;
    // the total number of public offering users raised
    uint256 public publicOfferingTotalShares;
    // shares of each public offering user
    mapping(address => uint256) public publicOfferingSharesOf;

    struct ConstructorArgs {
        IERC20 _Chaos;
        IERC20 _BUSD;
        IMarket _market;
        uint256 _beforeWhitelistInterval;
        uint256 _whitelistInterval;
        uint256 _publicOfferingInterval;
        uint256 _initInterval;
        uint256 _whitelistPrice;
        uint256 _publicOfferingPrice;
        uint256 _softCap;
        uint256 _hardCap;
        uint256 _whitelistMaxCapPerUser;
        uint256 _publicOfferingMaxCapPerUser;
    }

    modifier beforeWhiteList() {
        require(
            !initialized && block.timestamp < whitelistEnabledAt,
            "GLA: before whitelist"
        );
        _;
    }

    modifier whitelistEnabled() {
        require(
            !initialized &&
                block.timestamp >= whitelistEnabledAt &&
                block.timestamp < publicOfferingEnabledAt,
            "GLA: whitelist enabled"
        );
        _;
    }

    modifier publicOfferingEnabled() {
        require(
            !initialized &&
                block.timestamp >= publicOfferingEnabledAt &&
                block.timestamp < initAt,
            "GLA: public offering enabled"
        );
        _;
    }

    modifier initializeEnabled() {
        require(
            !initialized &&
                block.timestamp >= initAt &&
                block.timestamp < unlockAt,
            "GLA: initialize enabled"
        );
        _;
    }

    modifier isInitialized() {
        require(initialized, "GLA: is initialized");
        _;
    }

    modifier isUnlocked() {
        require(
            !initialized && block.timestamp >= unlockAt,
            "GLA: is unlocked"
        );
        _;
    }

    constructor(ConstructorArgs memory arg) {
        require(
            arg._beforeWhitelistInterval > 0 &&
                arg._whitelistInterval > 0 &&
                arg._publicOfferingInterval > 0 &&
                arg._initInterval > 0 &&
                arg._whitelistPrice > 0 &&
                arg._publicOfferingPrice > 0 &&
                arg._softCap > 0 &&
                arg._hardCap > arg._softCap &&
                arg._whitelistMaxCapPerUser > 0 &&
                arg._publicOfferingMaxCapPerUser > 0,
            "GLA: invalid constructor args"
        );
        Chaos = arg._Chaos;
        BUSD = arg._BUSD;
        market = arg._market;
        whitelistEnabledAt = block.timestamp + arg._beforeWhitelistInterval;
        publicOfferingEnabledAt = whitelistEnabledAt + arg._whitelistInterval;
        initAt = publicOfferingEnabledAt + arg._publicOfferingInterval;
        unlockAt = initAt + arg._initInterval;
        whitelistPrice = arg._whitelistPrice;
        publicOfferingPrice = arg._publicOfferingPrice;
        softCap = arg._softCap;
        hardCap = arg._hardCap;
        whitelistMaxCapPerUser = arg._whitelistMaxCapPerUser;
        publicOfferingMaxCapPerUser = arg._publicOfferingMaxCapPerUser;
    }

    /**
     * @dev Get whitelist length.
     */
    function whitelistLength() external view returns (uint256) {
        return whitelist.length;
    }

    /**
     * @dev Get whitelist total supply.
     */
    function whitelistTotalSupply() public view returns (uint256) {
        return (whitelistTotalShares * 1e18) / whitelistPrice;
    }

    /**
     * @dev Get public offering total supply.
     */
    function publicOfferingTotalSupply() public view returns (uint256) {
        return (publicOfferingTotalShares * 1e18) / publicOfferingPrice;
    }

    /**
     * @dev Get total supply.
     */
    function totalSupply() public view returns (uint256) {
        return whitelistTotalSupply() + publicOfferingTotalSupply();
    }

    /**
     * @dev Get total USD cap.
     */
    function totalCap() public view returns (uint256) {
        return whitelistTotalShares + publicOfferingTotalShares;
    }

    /**
     * @dev Get whitelist price(1e18).
     * NOTE: This function is reserved for interface compatibility.
     */
    function getWhitelistPrice() external view returns (uint256) {
        return whitelistPrice;
    }

    /**
     * @dev Get public offering price(1e18).
     * NOTE: This function is reserved for interface compatibility.
     */
    function getPublicOfferingPrice() external view returns (uint256) {
        return publicOfferingPrice;
    }

    /**
     * @dev Get whitelist total supply(1e18).
     * NOTE: This function is reserved for interface compatibility.
     */
    function getWhitelistTotalSupply() external view returns (uint256) {
        return whitelistTotalSupply();
    }

    /**
     * @dev Get public offering total supply(1e18).
     * NOTE: This function is reserved for interface compatibility.
     */
    function getPublicOfferingTotalSupply() external view returns (uint256) {
        return publicOfferingTotalSupply();
    }

    /**
     * @dev Get total supply(1e18).
     * NOTE: This function is reserved for interface compatibility.
     */
    function getTotalSupply() public view returns (uint256) {
        return totalSupply();
    }

    /**
     * @dev Get the current phase enumeration.
     */
    function getPhase() external view returns (uint8) {
        if (initialized) {
            // initialized
            return 4;
        } else {
            if (block.timestamp < whitelistEnabledAt) {
                // before whitelist phase
                return 0;
            } else if (
                block.timestamp >= whitelistEnabledAt &&
                block.timestamp < publicOfferingEnabledAt
            ) {
                // whitlist phase
                return 1;
            } else if (
                block.timestamp >= publicOfferingEnabledAt &&
                block.timestamp < initAt
            ) {
                // public offering phase
                return 2;
            } else if (
                block.timestamp >= initAt && block.timestamp < unlockAt
            ) {
                // init phase
                return 3;
            } else {
                // unlock phase
                return 5;
            }
        }
    }

    /**
     * @dev Add whitelist user to storage.
     *      The caller must be owner.
     * NOTE Please make sure whitelistLength() * whitelistMaxCapPerUser <= hardCap.
     * @param users - Whitelist user address.
     */
    function addWhitelist(address[] memory users)
        external
        beforeWhiteList
        onlyOwner
    {
        for (uint256 i = 0; i < users.length; i++) {
            address user = users[i];
            if (whitelistSharesOf[user] == 0) {
                whitelistSharesOf[user] = EXISTS_IN_WHITELIST;
                whitelist.push(user);
            }
        }
    }

    /**
     * @dev Whitelist user buy Chaos.
     * @param amount - The amount of BUSD.
     */
    function whitelistBuy(uint256 amount) external whitelistEnabled {
        require(amount > 0, "GLA: zero amount");
        uint256 shares = whitelistSharesOf[_msgSender()];
        require(shares != 0, "GLA: invalid whitelist user");
        shares = shares == EXISTS_IN_WHITELIST ? 0 : shares;
        uint256 maxCap = whitelistMaxCapPerUser - shares;
        if (amount > maxCap) {
            amount = maxCap;
        }
        require(amount > 0, "GLA: zero amount");
        BUSD.safeTransferFrom(_msgSender(), address(this), amount);
        whitelistTotalShares += amount;
        whitelistSharesOf[_msgSender()] = shares + amount;
    }

    /**
     * @dev Public offering user buy Chaos.
     * @param amount - The amount of BUSD.
     */
    function publicOfferingBuy(uint256 amount) external publicOfferingEnabled {
        require(
            amount > 0 && amount <= publicOfferingMaxCapPerUser,
            "GLA: invalid amount"
        );
        uint256 maxCap = hardCap - totalCap();
        if (amount > maxCap) {
            amount = maxCap;
        }
        require(amount > 0, "GLA: zero amount");
        BUSD.safeTransferFrom(_msgSender(), address(this), amount);
        publicOfferingTotalShares += amount;
        publicOfferingSharesOf[_msgSender()] += amount;

        // reach the hard cap, directly start market
        if (totalCap() >= hardCap) {
            _startup();
        }
    }

    /**
     * @dev Initialize GLA.
     *      If totalSupply reaches softCap, it will start the market,
     *      otherwise it will the enter unlock phase.
     */
    function initialize() external initializeEnabled {
        if (totalCap() >= softCap) {
            _startup();
        } else {
            unlockAt = initAt + 1;
        }
    }

    /**
     * @dev Start the market.
     */
    function _startup() internal {
        uint256 _totalSupply = getTotalSupply();
        uint256 _totalCap = totalCap();
        BUSD.approve(address(market), _totalCap);
        uint256 _BUSDBalance1 = BUSD.balanceOf(address(this));
        uint256 _CHAOSBalance1 = Chaos.balanceOf(address(this));
        market.startup(address(BUSD), _totalCap, _totalSupply);
        uint256 _BUSDBalance2 = BUSD.balanceOf(address(this));
        uint256 _CHAOSBalance2 = Chaos.balanceOf(address(this));
        require(
            _BUSDBalance1 - _BUSDBalance2 == _totalCap &&
                _CHAOSBalance2 - _CHAOSBalance1 == _totalSupply,
            "GLA: startup failed"
        );
        initialized = true;
        initTimestamp = block.timestamp;
    }

    /**
     * @dev Estimate how much Chaos user can claim.
     */
    function estimateClaim(address user) public view returns (uint256 chaos) {
        uint256 shares = whitelistSharesOf[user];
        shares = shares == EXISTS_IN_WHITELIST ? 0 : shares;
        chaos += (shares * 1e18) / whitelistPrice;
        chaos += (publicOfferingSharesOf[user] * 1e18) / publicOfferingPrice;
    }

    /**
     * @dev Claim Chaos.
     */
    function claim() external isInitialized {
        uint256 chaos = estimateClaim(_msgSender());
        require(chaos > 0, "GLA: zero chaos");
        uint256 max = Chaos.balanceOf(address(this));
        Chaos.transfer(_msgSender(), max < chaos ? max : chaos);
        delete whitelistSharesOf[_msgSender()];
        delete publicOfferingSharesOf[_msgSender()];
    }

    /**
     * @dev Estimate how much BUSD user can withdraw.
     */
    function estimateWithdraw(address user)
        public
        view
        returns (uint256 shares)
    {
        shares = whitelistSharesOf[user];
        shares = shares == EXISTS_IN_WHITELIST ? 0 : shares;
        shares += publicOfferingSharesOf[user];
    }

    /**
     * @dev Withdraw BUSD.
     */
    function withdraw() external isUnlocked {
        uint256 shares = estimateWithdraw(_msgSender());
        require(shares > 0, "GLA: zero shares");
        BUSD.safeTransfer(_msgSender(), shares);
        delete whitelistSharesOf[_msgSender()];
        delete publicOfferingSharesOf[_msgSender()];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/IAccessControlEnumerable.sol";
import "./IERC20BurnableMinter.sol";
import "./IStakePool.sol";

interface IMarket is IAccessControlEnumerable {
    function Chaos() external view returns (IERC20BurnableMinter);

    function prChaos() external view returns (IERC20BurnableMinter);

    function pool() external view returns (IStakePool);

    // target funding ratio (target/10000)
    function target() external view returns (uint32);

    // target adjusted funding ratio (targetAdjusted/10000)
    function targetAdjusted() external view returns (uint32);

    // minimum value of target
    function minTarget() external view returns (uint32);

    // maximum value of the targetAdjusted
    function maxTargetAdjusted() external view returns (uint32);

    // step value of each raise
    function raiseStep() external view returns (uint32);

    // step value of each lower
    function lowerStep() external view returns (uint32);

    // interval of each lower
    function lowerInterval() external view returns (uint32);

    // the time when ratio was last modified
    function latestUpdateTimestamp() external view returns (uint256);

    // developer address
    function dev() external view returns (address);

    // fee for buying Chaos
    function buyFee() external view returns (uint32);

    // fee for selling Chaos
    function sellFee() external view returns (uint32);

    // the slope of the price function (1/(k * 1e18))
    function k() external view returns (uint256);

    // current Chaos price
    function c() external view returns (uint256);

    // floor Chaos price
    function f() external view returns (uint256);

    // floor supply
    function p() external view returns (uint256);

    // total worth
    function w() external view returns (uint256);

    // stablecoins decimals
    function stablecoinsDecimals(address token) external view returns (uint8);

    /**
     * @dev Constructor.
     * NOTE This function can only called through delegatecall.
     * @param _Chaos - Chaos token address.
     * @param _prChaos - _prChaos token address.
     * @param _pool - StakePool contract addresss.
     * @param _k - Slope.
     * @param _target - Target funding ratio.
     * @param _targetAdjusted - Target adjusted funding ratio.
     * @param _manager - Manager address.
     * @param _stablecoins - Stablecoin addresses.
     */
    function constructor1(
        IERC20BurnableMinter _Chaos,
        IERC20BurnableMinter _prChaos,
        IStakePool _pool,
        uint256 _k,
        uint32 _target,
        uint32 _targetAdjusted,
        address _manager,
        address[] memory _stablecoins
    ) external;

    /**
     * @dev Startup market.
     *      The caller must be owner.
     * @param _token - Initial stablecoin address
     * @param _w - Initial stablecoin worth
     * @param _t - Initial Chaos total supply
     */
    function startup(
        address _token,
        uint256 _w,
        uint256 _t
    ) external;

    /**
     * @dev Get the number of stablecoins that can buy Chaos.
     */
    function stablecoinsCanBuyLength() external view returns (uint256);

    /**
     * @dev Get the address of the stablecoin that can buy Chaos according to the index.
     * @param index - Stablecoin index
     */
    function stablecoinsCanBuyAt(uint256 index) external view returns (address);

    /**
     * @dev Get whether the token can be used to buy Chaos.
     * @param token - Token address
     */
    function stablecoinsCanBuyContains(address token)
        external
        view
        returns (bool);

    /**
     * @dev Get the number of stablecoins that can be exchanged with Chaos.
     */
    function stablecoinsCanSellLength() external view returns (uint256);

    /**
     * @dev Get the address of the stablecoin that can be exchanged with Chaos,
     *      according to the index.
     * @param index - Stablecoin index
     */
    function stablecoinsCanSellAt(uint256 index)
        external
        view
        returns (address);

    /**
     * @dev Get whether the token can be exchanged with Chaos.
     * @param token - Token address
     */
    function stablecoinsCanSellContains(address token)
        external
        view
        returns (bool);

    /**
     * @dev Calculate current funding ratio.
     */
    function currentFundingRatio()
        external
        view
        returns (uint256 numerator, uint256 denominator);

    /**
     * @dev Estimate adjust result.
     * @param _k - Slope
     * @param _tar - Target funding ratio
     * @param _w - Total worth
     * @param _t - Total supply
     * @return success - Whether the calculation was successful
     * @return _c - Current price
     * @return _f - Floor price
     * @return _p - Point of intersection
     */
    function estimateAdjust(
        uint256 _k,
        uint256 _tar,
        uint256 _w,
        uint256 _t
    )
        external
        pure
        returns (
            bool success,
            uint256 _c,
            uint256 _f,
            uint256 _p
        );

    /**
     * @dev Estimate next raise price.
     * @return success - Whether the calculation was successful
     * @return _t - The total supply when the funding ratio reaches targetAdjusted
     * @return _c - The price when the funding ratio reaches targetAdjusted
     * @return _w - The total worth when the funding ratio reaches targetAdjusted
     * @return raisedFloorPrice - The floor price after market adjusted
     */
    function estimateRaisePrice()
        external
        view
        returns (
            bool success,
            uint256 _t,
            uint256 _c,
            uint256 _w,
            uint256 raisedFloorPrice
        );

    /**
     * @dev Estimate raise price by input value.
     * @param _f - Floor price
     * @param _k - Slope
     * @param _p - Floor supply
     * @param _tar - Target funding ratio
     * @param _tarAdjusted - Target adjusted funding ratio
     * @return success - Whether the calculation was successful
     * @return _t - The total supply when the funding ratio reaches _tar
     * @return _c - The price when the funding ratio reaches _tar
     * @return _w - The total worth when the funding ratio reaches _tar
     * @return raisedFloorPrice - The floor price after market adjusted
     */
    function estimateRaisePrice(
        uint256 _f,
        uint256 _k,
        uint256 _p,
        uint256 _tar,
        uint256 _tarAdjusted
    )
        external
        pure
        returns (
            bool success,
            uint256 _t,
            uint256 _c,
            uint256 _w,
            uint256 raisedFloorPrice
        );

    /**
     * @dev Lower target and targetAdjusted with lowerStep.
     */
    function lowerAndAdjust() external;

    /**
     * @dev Set market options.
     *      The caller must has MANAGER_ROLE.
     *      This function can only be called before the market is started.
     * @param _k - Slope
     * @param _target - Target funding ratio
     * @param _targetAdjusted - Target adjusted funding ratio
     */
    function setMarketOptions(
        uint256 _k,
        uint32 _target,
        uint32 _targetAdjusted
    ) external;

    /**
     * @dev Set adjust options.
     *      The caller must be owner.
     * @param _minTarget - Minimum value of target
     * @param _maxTargetAdjusted - Maximum value of the targetAdjusted
     * @param _raiseStep - Step value of each raise
     * @param _lowerStep - Step value of each lower
     * @param _lowerInterval - Interval of each lower
     */
    function setAdjustOptions(
        uint32 _minTarget,
        uint32 _maxTargetAdjusted,
        uint32 _raiseStep,
        uint32 _lowerStep,
        uint32 _lowerInterval
    ) external;

    /**
     * @dev Set fee options.
     *      The caller must be owner.
     * @param _dev - Dev address
     * @param _buyFee - Fee for buying Chaos
     * @param _sellFee - Fee for selling Chaos
     */
    function setFeeOptions(
        address _dev,
        uint32 _buyFee,
        uint32 _sellFee
    ) external;

    /**
     * @dev Manage stablecoins.
     *      Add/Delete token to/from stablecoinsCanBuy/stablecoinsCanSell.
     *      The caller must be owner.
     * @param token - Token address
     * @param buyOrSell - Buy or sell token
     * @param addOrDelete - Add or delete token
     */
    function manageStablecoins(
        address token,
        bool buyOrSell,
        bool addOrDelete
    ) external;

    /**
     * @dev Estimate how much Chaos user can buy.
     * @param token - Stablecoin address
     * @param tokenWorth - Number of stablecoins
     * @return amount - Number of Chaos
     * @return fee - Dev fee
     * @return worth1e18 - The amount of stablecoins being exchanged(1e18)
     * @return newPrice - New Chaos price
     */
    function estimateBuy(address token, uint256 tokenWorth)
        external
        view
        returns (
            uint256 amount,
            uint256 fee,
            uint256 worth1e18,
            uint256 newPrice
        );

    /**
     * @dev Estimate how many stablecoins will be needed to realize prChaos.
     * @param amount - Number of prChaos user want to realize
     * @param token - Stablecoin address
     * @return worth1e18 - The amount of stablecoins being exchanged(1e18)
     * @return worth - The amount of stablecoins being exchanged
     */
    function estimateRealize(uint256 amount, address token)
        external
        view
        returns (uint256 worth1e18, uint256 worth);

    /**
     * @dev Estimate how much stablecoins user can sell.
     * @param amount - Number of Chaos user want to sell
     * @param token - Stablecoin address
     * @return fee - Dev fee
     * @return worth1e18 - The amount of stablecoins being exchanged(1e18)
     * @return worth - The amount of stablecoins being exchanged
     * @return newPrice - New Chaos price
     */
    function estimateSell(uint256 amount, address token)
        external
        view
        returns (
            uint256 fee,
            uint256 worth1e18,
            uint256 worth,
            uint256 newPrice
        );

    /**
     * @dev Buy Chaos.
     * @param token - Address of stablecoin used to buy Chaos
     * @param tokenWorth - Number of stablecoins
     * @param desired - Minimum amount of Chaos user want to buy
     * @return amount - Number of Chaos
     * @return fee - Dev fee(Chaos)
     */
    function buy(
        address token,
        uint256 tokenWorth,
        uint256 desired
    ) external returns (uint256, uint256);

    /**
     * @dev Buy Chaos for user.
     * @param token - Address of stablecoin used to buy Chaos
     * @param tokenWorth - Number of stablecoins
     * @param desired - Minimum amount of Chaos user want to buy
     * @param user - User address
     * @return amount - Number of Chaos
     * @return fee - Dev fee(Chaos)
     */
    function buyFor(
        address token,
        uint256 tokenWorth,
        uint256 desired,
        address user
    ) external returns (uint256, uint256);

    /**
     * @dev Realize Chaos with floor price and equal amount of prChaos.
     * @param amount - Amount of prChaos user want to realize
     * @param token - Address of stablecoin used to realize prChaos
     * @param desired - Maximum amount of stablecoin users are willing to pay
     * @return worth - The amount of stablecoins being exchanged
     */
    function realize(
        uint256 amount,
        address token,
        uint256 desired
    ) external returns (uint256);

    /**
     * @dev Realize Chaos with floor price and equal amount of prChaos for user.
     * @param amount - Amount of prChaos user want to realize
     * @param token - Address of stablecoin used to realize prChaos
     * @param desired - Maximum amount of stablecoin users are willing to pay
     * @param user - User address
     * @return worth - The amount of stablecoins being exchanged
     */
    function realizeFor(
        uint256 amount,
        address token,
        uint256 desired,
        address user
    ) external returns (uint256);

    /**
     * @dev Sell Chaos.
     * @param amount - Amount of Chaos user want to sell
     * @param token - Address of stablecoin used to buy Chaos
     * @param desired - Minimum amount of stablecoins user want to get
     * @return fee - Dev fee(Chaos)
     * @return worth - The amount of stablecoins being exchanged
     */
    function sell(
        uint256 amount,
        address token,
        uint256 desired
    ) external returns (uint256, uint256);

    /**
     * @dev Sell Chaos for user.
     * @param amount - Amount of Chaos user want to sell
     * @param token - Address of stablecoin used to buy Chaos
     * @param desired - Minimum amount of stablecoins user want to get
     * @param user - User address
     * @return fee - Dev fee(Chaos)
     * @return worth - The amount of stablecoins being exchanged
     */
    function sellFor(
        uint256 amount,
        address token,
        uint256 desired,
        address user
    ) external returns (uint256, uint256);

    /**
     * @dev Burn Chaos.
     *      It will preferentially transfer the excess value after burning to PSL.
     * @param amount - The amount of Chaos the user wants to burn
     */
    function burn(uint256 amount) external;

    /**
     * @dev Burn Chaos for user.
     *      It will preferentially transfer the excess value after burning to PSL.
     * @param amount - The amount of Chaos the user wants to burn
     * @param user - User address
     */
    function burnFor(uint256 amount, address user) external;

    /**
     * @dev Triggers stopped state.
     *      The caller must be owner.
     */
    function pause() external;

    /**
     * @dev Returns to normal state.
     *      The caller must be owner.
     */
    function unpause() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library Math {
    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    /**
     * @dev Convert value from srcDecimals to dstDecimals.
     */
    function convertDecimals(
        uint256 value,
        uint8 srcDecimals,
        uint8 dstDecimals
    ) internal pure returns (uint256 result) {
        if (srcDecimals == dstDecimals) {
            result = value;
        } else if (srcDecimals < dstDecimals) {
            result = value * (10**(dstDecimals - srcDecimals));
        } else {
            result = value / (10**(srcDecimals - dstDecimals));
        }
    }

    /**
     * @dev Convert value from srcDecimals to dstDecimals, rounded up.
     */
    function convertDecimalsCeil(
        uint256 value,
        uint8 srcDecimals,
        uint8 dstDecimals
    ) internal pure returns (uint256 result) {
        if (srcDecimals == dstDecimals) {
            result = value;
        } else if (srcDecimals < dstDecimals) {
            result = value * (10**(dstDecimals - srcDecimals));
        } else {
            uint256 temp = 10**(srcDecimals - dstDecimals);
            result = value / temp;
            if (value % temp != 0) {
                result += 1;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IERC20BurnableMinter is IERC20Metadata {
    function mint(address to, uint256 amount) external;

    function burn(uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IERC20BurnableMinter.sol";
import "./IBank.sol";

// The stakepool will mint prChaos according to the total supply of Chaos and
// then distribute it to all users according to the amount of Chaos deposited by each user.
interface IStakePool {
    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of prChaoss
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. prChaoss to distribute per block.
        uint256 lastRewardBlock; // Last block number that prChaoss distribution occurs.
        uint256 accPerShare; // Accumulated prChaoss per share, times 1e12. See below.
    }

    // The Chaos token
    function Chaos() external view returns (IERC20);

    // The prChaos token
    function prChaos() external view returns (IERC20BurnableMinter);

    // The bank contract address
    function bank() external view returns (IBank);

    // Info of each pool.
    function poolInfo(uint256 index)
        external
        view
        returns (
            IERC20,
            uint256,
            uint256,
            uint256
        );

    // Info of each user that stakes LP tokens.
    function userInfo(uint256 pool, address user)
        external
        view
        returns (uint256, uint256);

    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    function totalAllocPoint() external view returns (uint256);

    // Daily minted Chaos as a percentage of total supply, the value is mintPercentPerDay / 1000.
    function mintPercentPerDay() external view returns (uint32);

    // How many blocks are there in a day.
    function blocksPerDay() external view returns (uint256);

    // Developer address.
    function dev() external view returns (address);

    // Withdraw fee(Chaos).
    function withdrawFee() external view returns (uint32);

    // Mint fee(prChaos).
    function mintFee() external view returns (uint32);

    // Constructor.
    function constructor1(
        IERC20 _Chaos,
        IERC20BurnableMinter _prChaos,
        IBank _bank,
        address _owner
    ) external;

    function poolLength() external view returns (uint256);

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(
        uint256 _allocPoint,
        IERC20 _lpToken,
        bool _withUpdate
    ) external;

    // Update the given pool's prChaos allocation point. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) external;

    // Set options. Can only be called by the owner.
    function setOptions(
        uint32 _mintPercentPerDay,
        uint256 _blocksPerDay,
        address _dev,
        uint32 _withdrawFee,
        uint32 _mintFee,
        bool _withUpdate
    ) external;

    // View function to see pending prChaoss on frontend.
    function pendingRewards(uint256 _pid, address _user)
        external
        view
        returns (uint256);

    // Update reward vairables for all pools. Be careful of gas spending!
    function massUpdatePools() external;

    // Deposit LP tokens to StakePool for prChaos allocation.
    function deposit(uint256 _pid, uint256 _amount) external;

    // Deposit LP tokens to StakePool for user for prChaos allocation.
    function depositFor(
        uint256 _pid,
        uint256 _amount,
        address _user
    ) external;

    // Withdraw LP tokens from StakePool.
    function withdraw(uint256 _pid, uint256 _amount) external;

    // Claim reward.
    function claim(uint256 _pid) external;

    // Claim reward for user.
    function claimFor(uint256 _pid, address _user) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20BurnableMinter.sol";
import "./IStakePool.sol";
import "./IMarket.sol";

interface IBank {
    // Order token address
    function Order() external view returns (IERC20BurnableMinter);

    // Market contract address
    function market() external view returns (IMarket);

    // StakePool contract address
    function pool() external view returns (IStakePool);

    // helper contract address
    function helper() external view returns (address);

    // user debt
    function debt(address user) external view returns (uint256);

    // developer address
    function dev() external view returns (address);

    // fee for borrowing Order
    function borrowFee() external view returns (uint32);

    /**
     * @dev Constructor.
     * NOTE This function can only called through delegatecall.
     * @param _Order - Order token address.
     * @param _market - Market contract address.
     * @param _pool - StakePool contract address.
     * @param _helper - Helper contract address.
     * @param _owner - Owner address.
     */
    function constructor1(
        IERC20BurnableMinter _Order,
        IMarket _market,
        IStakePool _pool,
        address _helper,
        address _owner
    ) external;

    /**
     * @dev Set bank options.
     *      The caller must be owner.
     * @param _dev - Developer address
     * @param _borrowFee - Fee for borrowing Order
     */
    function setOptions(address _dev, uint32 _borrowFee) external;

    /**
     * @dev Calculate the amount of Chaos that can be withdrawn.
     * @param user - User address
     */
    function withdrawable(address user) external view returns (uint256);

    /**
     * @dev Calculate the amount of Chaos that can be withdrawn.
     * @param user - User address
     * @param amountChaos - User staked Chaos amount
     */
    function withdrawable(address user, uint256 amountChaos)
        external
        view
        returns (uint256);

    /**
     * @dev Calculate the amount of Order that can be borrowed.
     * @param user - User address
     */
    function available(address user) external view returns (uint256);

    /**
     * @dev Borrow Order.
     * @param amount - The amount of Order
     * @return borrowed - Borrowed Order
     * @return fee - Borrow fee
     */
    function borrow(uint256 amount)
        external
        returns (uint256 borrowed, uint256 fee);

    /**
     * @dev Borrow Order from user and directly mint to msg.sender.
     *      The caller must be helper contract.
     * @param user - User address
     * @param amount - The amount of Order
     * @return borrowed - Borrowed Order
     * @return fee - Borrow fee
     */
    function borrowFrom(address user, uint256 amount)
        external
        returns (uint256 borrowed, uint256 fee);

    /**
     * @dev Repay Order.
     * @param amount - The amount of Order
     */
    function repay(uint256 amount) external;

    /**
     * @dev Triggers stopped state.
     *      The caller must be owner.
     */
    function pause() external;

    /**
     * @dev Returns to normal state.
     *      The caller must be owner.
     */
    function unpause() external;
}