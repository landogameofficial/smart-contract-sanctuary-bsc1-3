pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "../interfaces/IFlashloanWrapper.sol";
import "../interfaces/IFinisher.sol";
import "../interfaces/IAutoHedgeLeveragedPosition.sol";

contract FlashloanWrapper is
	Initializable,
	UUPSUpgradeable,
	OwnableUpgradeable,
	IFlashloanWrapper,
	IFlashBorrower
{
	function initialize(address bentoBox_) external initializer {
		__Ownable_init_unchained();
		sushiBentoBox = IBentoBox(bentoBox_);
		FLASH_LOAN_FEE = 50;
		FLASH_LOAN_FEE_PRECISION = 1e5;
	}

	using SafeERC20 for IERC20;

	IBentoBox public override sushiBentoBox;

	uint256 public override FLASH_LOAN_FEE;
	uint256 public override FLASH_LOAN_FEE_PRECISION;

	// TODO: change to call sushi's bentobox directly as this is redundant call and make the
	// finishRoute.target to be FlashloanWrapper
	function takeOutFlashLoan(
		IERC20 token,
		uint256 amount,
		bytes calldata data
	) external override {
		// Guarantee that the 1st argument of the forwarded callData
		// is the caller of this fcn, first 4 bytes are function selector
		FinishRoute memory fr = abi.decode(data[68:132], (FinishRoute));
		require(fr.flwCaller == msg.sender, "FLW: invalid caller");

		sushiBentoBox.flashLoan(IFlashBorrower(address(this)), fr.target, token, amount, data);
	}

	function getFeeFactor() external view override returns (uint256) {
		return 0;
	}

	function onFlashLoan(
		address sender,
		IERC20 token,
		uint256 amount,
		uint256 fee,
		bytes calldata data
	) external override {
		require(msg.sender == address(sushiBentoBox), "FLW: invalid caller");
		require(sender == address(this), "FLW: invalid sender");

		bytes4 sig = bytes4(data[0:4]);

		uint256 segmentLength = (data.length - 4) / 32;

		bytes32[] memory dataList = new bytes32[](segmentLength);
		uint256 startIndex;

		for (uint256 index = 0; index < segmentLength; index++) {
			startIndex = index * 32 + 4;
			dataList[index] = bytes32(data[startIndex:(startIndex + 32)]);
		}

		dataList[segmentLength - 1] = bytes32(fee);
		bytes memory newData = abi.encodePacked(sig, dataList);

		FinishRoute memory fr = abi.decode(data[68:132], (FinishRoute));
		(bool success, ) = fr.target.call(newData);
		require(success, "FLW: call failed");
	}

	function setFlashloanFee(uint256 fee, uint256 precision) external onlyOwner {
		require(fee < precision, "FLW: invalid fee");
		FLASH_LOAN_FEE = fee;
		FLASH_LOAN_FEE_PRECISION = precision;
	}

	function repayFlashLoan(IERC20 token, uint256 amount) external override {
		token.safeTransferFrom(msg.sender, address(sushiBentoBox), amount);
		// emit FlashLoanRepaid(address(sushiBentoBox), amount);
	}

	function _authorizeUpgrade(address) internal override onlyOwner {}
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IBentoBox.sol";

enum FlashloanType {
	Deposit,
	Withdraw
}

interface IFlashloanWrapper {
	event Flashloan(
		address indexed receiver,
		IERC20 token,
		uint256 amount,
		uint256 fee,
		uint256 loanType
	);

	event FlashloanRepaid(address indexed to, uint256 amount);

	struct FinishRoute {
		address flwCaller;
		address target;
	}

	function takeOutFlashLoan(
		IERC20 token,
		uint256 amount,
		bytes calldata data
	) external;

	function repayFlashLoan(IERC20 token, uint256 amount) external;

	function getFeeFactor() external view returns (uint256);

	function sushiBentoBox() external view returns (IBentoBox);

	function FLASH_LOAN_FEE() external view returns (uint256);

	function FLASH_LOAN_FEE_PRECISION() external view returns (uint256);
}

pragma solidity 0.8.6;

interface IFinisher {
    function onFlw(
        uint256 amount,
        uint256 fee,
        bytes memory data
    ) external;
}

pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "../interfaces/ICErc20.sol";
import "../interfaces/IAutoHedgeStableVolatilePairUpgradeableV2.sol";
import "../interfaces/IFlashloanWrapper.sol";
import "../interfaces/IAutoHedgeLeveragedPositionFactory.sol";

interface IAutoHedgeLeveragedPosition {
	struct TokensLev {
		IERC20Metadata stable;
		ICErc20 cStable;
		IERC20Metadata vol;
		IAutoHedgeStableVolatilePairUpgradeableV2 pair;
		ICErc20 cAhlp;
	}

	struct FinishDeposit {
		IFlashloanWrapper.FinishRoute fr;
		TokensLev tokens;
		uint256 amountStableDeposit;
		uint256 amountStableToFlashloan;
		address referrer;
		uint256 flashloanFee;
	}

	struct FinishWithdraw {
		TokensLev tokens;
		uint256 amountStableWithdraw;
		uint256 amountAhlpRedeem;
		uint256 amountVolToFlashloan;
		IAutoHedgeStableVolatilePairUpgradeableV2.FinishWithdraw pairFW;
	}

	event DepositLev(
		address indexed comptroller,
		address indexed pair,
		uint256 amountStableDeposit,
		uint256 amountStableFlashloan,
		uint256 leverageRatio
	);

	function initialize(IAutoHedgeLeveragedPositionFactory factory_) external;

	function finishDeposit(bytes calldata data) external;
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IFlashBorrower {
    /// @notice The flashloan callback. `amount` + `fee` needs to repayed to msg.sender before this call returns.
    /// @param sender The address of the invoker of this flashloan.
    /// @param token The address of the token that is loaned.
    /// @param amount of the `token` that is loaned.
    /// @param fee The fee that needs to be paid on top for this loan. Needs to be the same as `token`.
    /// @param data Additional data that was passed to the flashloan function.
    function onFlashLoan(
        address sender,
        IERC20 token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external;
}

interface IBentoBox {
    /// @notice Flashloan ability.
    /// @param borrower The address of the contract that implements and conforms to `IFlashBorrower` and handles the flashloan.
    /// @param receiver Address of the token receiver.
    /// @param token The address of the token to receive.
    /// @param amount of the tokens to receive.
    /// @param data The calldata to pass to the `borrower` contract.
    // F5 - Checks-Effects-Interactions pattern followed? (SWC-107)
    // F5: Not possible to follow this here, reentrancy has been reviewed
    // F6 - Check for front-running possibilities, such as the approve function (SWC-114)
    // F6: Slight grieving possible by withdrawing an amount before someone tries to flashloan close to the full amount.
    function flashLoan(
        IFlashBorrower borrower,
        address receiver,
        IERC20 token,
        uint256 amount,
        bytes calldata data
    ) external;
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

pragma solidity 0.8.6;


interface CErc20Storage {
    function underlying() external returns (address);
}

interface ICErc20 is CErc20Storage {
    function mint(uint mintAmount) external returns (uint);
    function redeem(uint redeemTokens) external returns (uint);
    function redeemUnderlying(uint redeemAmount) external returns (uint);
    function borrow(uint borrowAmount) external returns (uint);
    function repayBorrow(uint repayAmount) external returns (uint);
    function repayBorrowBehalf(address borrower, uint repayAmount) external returns (uint);
    function liquidateBorrow(address borrower, uint repayAmount, address cTokenCollateral) external returns (uint);

    function transfer(address receiver, uint amount) external;

    function balanceOfUnderlying(address account) external returns (uint);
    function borrowBalanceCurrent(address account) external returns (uint);

    function exchangeRateCurrent() external returns (uint);
    function exchangeRateStored() external returns (uint);
    function accrueInterest() external returns (uint);

    function balanceOf(address account) external view returns (uint);
    function getCash() external view returns (uint);
    function totalSupply() external view returns (uint);

    function borrowRatePerBlock() external view returns (uint);
    function supplyRatePerBlock() external view returns (uint);
}

pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";
import "./IComptroller.sol";
import "./ICErc20.sol";
import "./IWETHUnwrapper.sol";
import "./IFlashloanWrapper.sol";
import "./IAutoHedgeStableVolatileFactoryUpgradeableV2.sol";
import "./autonomy/IRegistry.sol";

interface IAutoHedgeStableVolatilePairUpgradeableV2 {
	struct Amounts {
		uint256 stable;
		uint256 vol;
	}

	struct MmBps {
		uint64 min;
		uint64 max;
	}

	struct VolPosition {
		uint256 owned;
		uint256 debt;
		uint256 bps;
	}

	struct Tokens {
		IERC20Metadata stable;
		IERC20Metadata vol;
		ICErc20 cVol;
		IERC20Metadata uniLp;
		ICErc20 cUniLp;
	}

	struct FinishDeposit {
		IFlashloanWrapper.FinishRoute fr;
		address depositor;
		uint256 amountStableInit;
		uint256 amountVolToFlashloan;
		address to;
		address referrer;
		uint256 flashloanFee;
	}

	struct FinishWithdraw {
		IFlashloanWrapper.FinishRoute fr;
		address withrawer;
		uint256 liquidity;
		uint256 amountVolToFlashloan;
		address to;
		uint256 flashloanFee;
	}

	struct TokenUnderlyingBalances {
		uint256 amountVolBorrow;
		uint256 balanceOfUniLp;
	}

	event Deposited(
		address indexed user,
		uint256 amountStable,
		uint256 amountVol,
		uint256 amountUniLp,
		uint256 amountStableSwap,
		uint256 amountMinted
	);

	event Withdrawn(
		address indexed user,
		uint256 amountStableToUser,
		uint256 amountVolToRepay,
		uint256 amountBurned
	);

	event TokenUnderlyingBalancesUpdated(uint256 cVolBorrowAmount, uint256 cUniLpBalance);

	function initialize(
		IUniswapV2Router02 uniV2Router_,
		Tokens memory tokens,
		IERC20Metadata weth_,
		string memory name_,
		string memory symbol_,
		IRegistry registry_,
		address userFeeVeriForwarder_,
		MmBps memory mmBps_,
		IComptroller _comptroller,
		IAutoHedgeStableVolatileFactoryUpgradeableV2 factory_,
		IWETHUnwrapper wu_
	) external;

	/**
	 * @notice  Deposit stablecoins into this pair and receive back AH LP
	 *          tokens. This fcn:
	 *              1. Swaps half the stables into whatever the volatile
	 *                  token is
	 *              2. LPs both tokens on a DEX
	 *              3. Lends out the DEX LP token on Fuse/Midas (Compound
	 *                  fork platforms) to use as collateral
	 *              4. Borrows an equal amount of vol token that was LP'd with
	 *              5. Swaps it to the stable token
	 *              6. Lends out the stable token
	 *              7. Mints an AH LP token and sends it to the user.
	 *          Note depositing takes a 0.3% fee, either to Autonomy or a
	 *          referrer if there is 1.
	 * @param amountStableInit   The minimum amount of the stable that's
	 *                              accepted to be put into the LP
	 * @param to    The address to send the AH LP tokens to
	 * @param referrer  The addresses that receives the 0.3% protocol fee on
	 *                  deposits. If left as 0x00...00, it goes to Autonomy
	 */
	function deposit(
		uint256 amountStableInit,
		address to,
		address referrer
	) external;

	// /**
	//  * @notice  Withdraws stablecoins from the position by effectively
	//  *          doing everything in `deposit` in reverse order. There is
	//  *          no protocol or referrer fee for withdrawing. All positions
	//  *          are withdrawn proportionally - for example if `liquidity`
	//  *          is 10% of the pair's AH LP supply, then it'll withdraw
	//  *          10% of the stable lending position, 10% of the DEX LP,
	//  *          and be responsible for repaying 10% of the vol debt.
	//  * @param liquidity     The amount of AH LP tokens to burn
	//  * @return amountStableToUser   The amount of stables that are actually sent to the user
	//  *          after all positions have been withdrawn/repaid
	//  */
	// function withdraw(uint256 liquidity, UniArgs calldata uniArgs)
	//     external
	//     returns (uint256 amountStableToUser);

	/**
	 * @notice  This is only callable by Autonomy Network itself and only
	 *          under the condition of the vol debt being more than a set
	 *          difference (1% by default) with the amount of vol owned in
	 *          the DEX LP.
	 *          If there is more debt than in the DEX LP, it
	 *          takes some stables from the lending position, withdraws them,
	 *          swaps them to vol, and repays the debt.
	 *          If there is less debt than in the DEX LP, then more vol is
	 *          borrowed, swapped into stables, and lent out.
	 * @param user  The user who made this automation request. This must
	 *              be address(this) of the pair contract, else it'll revert
	 * @param feeAmount     The amount of fee (in the native token of the chain)
	 *                      that's needed to pay the automation fee
	 */
	function rebalanceAuto(address user, uint256 feeAmount) external;

	function finishDeposit(bytes calldata data) external;

	function finishWithdraw(bytes calldata data) external returns (uint256);

	/**
	 * @notice  Returns information on the positions of the volatile token
	 * @return  The VolPosition struct which specifies what amount of vol
	 *          tokens are owned in the DEX LP, the amount of vol tokens
	 *          in debt, and bps, which is basically debt/owned, scaled
	 *          by 1e18
	 */
	function getDebtBps() external returns (VolPosition memory);

	/**
	 * @notice  Returns the factory that created this pair
	 */
	function factory() external returns (IAutoHedgeStableVolatileFactoryUpgradeableV2);

	/**
	 * @notice  Set the min and max bps that the pool will use to rebalance,
	 *          scaled to 1e18. E.g. the min by default is a 1% difference
	 *          and is therefore 99e16
	 * @param newMmBps  The MmBps struct that specifies the min then the max
	 */
	function setMmBps(MmBps calldata newMmBps) external;

	/**
	 * @notice  Gets the token addresses involved in the pool and their
	 *          corresponding cToken/fToken addresses
	 */
	function getTokens()
		external
		view
		returns (
			IERC20Metadata stable,
			IERC20Metadata vol,
			ICErc20 cVol,
			IERC20Metadata uniLp,
			ICErc20 cUniLp
		);

	function balanceOfVolBorrow() external view returns (uint256);

	function balanceOfUniLp() external view returns (uint256);

	// function getBalanceOfUnderlyingTokens()
	// 	external
	// 	view
	// 	returns (uint256 amountVolBorrow, uint256 balanceOfUniLp);

	// function refreshBalanceOfUnderlyingTokens() external;
}

pragma solidity 0.8.6;

import "./IFlashloanWrapper.sol";

interface IAutoHedgeLeveragedPositionFactory {
    event LeveragedPositionCreated(address indexed creator, address lvgPos);

    function flw() external view returns (IFlashloanWrapper);

    function createLeveragedPosition() external returns (address lvgPos);
}

pragma solidity 0.8.6;

// SPDX-License-Identifier: UNLICENSED

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function WETH() external view returns (address);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity 0.8.6;


import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

pragma solidity 0.8.6;


interface IComptrollerStorage {
    function cTokensByUnderlying(address underlying) external view returns (address);
}

interface IComptroller is IComptrollerStorage {
    /// @notice Indicator that this is a Comptroller contract (for inspection)
//    bool public constant isComptroller = true; TODO Variables cannot be declared in interfaces.

    /*** Assets You Are In ***/

    function enterMarkets(address[] calldata cTokens) external returns (uint[] memory);
    function exitMarket(address cToken) external returns (uint);

    /*** Policy Hooks ***/

    function mintAllowed(address cToken, address minter, uint mintAmount) external returns (uint);
    function mintWithinLimits(address cToken, uint exchangeRateMantissa, uint accountTokens, uint mintAmount) external returns (uint);
    function mintVerify(address cToken, address minter, uint mintAmount, uint mintTokens) external;

    function redeemAllowed(address cToken, address redeemer, uint redeemTokens) external returns (uint);
    function redeemVerify(address cToken, address redeemer, uint redeemAmount, uint redeemTokens) external;

    function borrowAllowed(address cToken, address borrower, uint borrowAmount) external returns (uint);
    function borrowWithinLimits(address cToken, uint accountBorrowsNew) external returns (uint);
    function borrowVerify(address cToken, address borrower, uint borrowAmount) external;

    function repayBorrowAllowed(
        address cToken,
        address payer,
        address borrower,
        uint repayAmount) external returns (uint);
    function repayBorrowVerify(
        address cToken,
        address payer,
        address borrower,
        uint repayAmount,
        uint borrowerIndex) external;

    function liquidateBorrowAllowed(
        address cTokenBorrowed,
        address cTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount) external returns (uint);
    function liquidateBorrowVerify(
        address cTokenBorrowed,
        address cTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount,
        uint seizeTokens) external;

    function seizeAllowed(
        address cTokenCollateral,
        address cTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) external returns (uint);
    function seizeVerify(
        address cTokenCollateral,
        address cTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) external;

    function transferAllowed(address cToken, address src, address dst, uint transferTokens) external returns (uint);
    function transferVerify(address cToken, address src, address dst, uint transferTokens) external;

    /*** Liquidity/Liquidation Calculations ***/

    function liquidateCalculateSeizeTokens(
        address cTokenBorrowed,
        address cTokenCollateral,
        uint repayAmount) external view returns (uint, uint);
    
    /*** Pool-Wide/Cross-Asset Reentrancy Prevention ***/

    function _beforeNonReentrant() external;
    function _afterNonReentrant() external;

    function _deployMarket(bool isCEther, bytes memory constructorData, uint collateralFactorMantissa) external;
}

pragma solidity 0.8.6;

interface IWETHUnwrapper {
	function withdraw(uint256 amount, address to) external;
}

pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";
import "./IComptroller.sol";
import "./IAutoHedgeStableVolatilePairUpgradeableV2.sol";

interface IAutoHedgeStableVolatileFactoryUpgradeableV2 {
	event PairCreated(
		IERC20Metadata indexed stable,
		IERC20Metadata indexed vol,
		address pair,
		uint256
	);
	event FeeReceiverSet(address indexed receiver);
	event DepositFeeSet(uint256 fee);

	function initialize(
		address beacon_,
		address weth_,
		IUniswapV2Factory uniV2Factory_,
		IUniswapV2Router02 uniV2Router_,
		IComptroller comptroller_,
		address payable registry_,
		address userFeeVeriForwarder_,
		IAutoHedgeStableVolatilePairUpgradeableV2.MmBps memory initMmBps_,
		address feeReceiver_,
		address flw_,
		address wu_
	) external;

	function flw() external view returns (address);

	function getPair(IERC20Metadata stable, IERC20Metadata vol)
		external
		view
		returns (address pair);

	function allPairs(uint256) external view returns (address pair);

	function allPairsLength() external view returns (uint256);

	function createPair(IERC20Metadata stable, IERC20Metadata vol) external returns (address pair);

	function setFeeReceiver(address newReceiver) external;

	function setDepositFee(uint256 newDepositFee) external;

	function uniV2Factory() external view returns (IUniswapV2Factory);

	function uniV2Router() external view returns (IUniswapV2Router02);

	function registry() external view returns (address payable);

	function userFeeVeriForwarder() external view returns (address);

	function feeReceiver() external view returns (address);

	function depositFee() external view returns (uint256);
}

pragma solidity 0.8.6;


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


/**
* @title    Registry
* @notice   A contract which is essentially a glorified forwarder.
*           It essentially brings together people who want things executed,
*           and people who want to do that execution in return for a fee.
*           Users register the details of what they want executed, which
*           should always revert unless their execution condition is true,
*           and executors execute the request when the condition is true.
*           Only a specific executor is allowed to execute requests at any
*           given time, as determined by the StakeManager, which requires
*           staking AUTO tokens. This is infrastructure, and an integral
*           piece of the future of web3. It also provides the spark of life
*           for a new form of organism - cyber life. We are the gods now.
* @author   Quantaf1re (James Key)
*/
interface IRegistry {
    
    // The address vars are 20b, total 60, calldata is 4b + n*32b usually, which
    // has a factor of 32. uint112 since the current ETH supply of ~115m can fit
    // into that and it's the highest such that 2 * uint112 + 3 * bool is < 256b
    struct Request {
        address payable user;
        address target;
        address payable referer;
        bytes callData;
        uint112 initEthSent;
        uint112 ethForCall;
        bool verifyUser;
        bool insertFeeAmount;
        bool payWithAUTO;
        bool isAlive;
    }


    //////////////////////////////////////////////////////////////
    //                                                          //
    //                      Hashed Requests                     //
    //                                                          //
    //////////////////////////////////////////////////////////////

    /**
     * @notice  Creates a new request, logs the request info in an event, then saves
     *          a hash of it on-chain in `_hashedReqs`. Uses the default for whether
     *          to pay in ETH or AUTO
     * @param target    The contract address that needs to be called
     * @param referer       The referer to get rewarded for referring the sender
     *                      to using Autonomy. Usally the address of a dapp owner
     * @param callData  The calldata of the call that the request is to make, i.e.
     *                  the fcn identifier + inputs, encoded
     * @param ethForCall    The ETH to send with the call
     * @param verifyUser  Whether the 1st input of the calldata equals the sender.
     *                      Needed for dapps to know who the sender is whilst
     *                      ensuring that the sender intended
     *                      that fcn and contract to be called - dapps will
     *                      require that msg.sender is the Verified Forwarder,
     *                      and only requests that have `verifyUser` = true will
     *                      be forwarded via the Verified Forwarder, so any calls
     *                      coming from it are guaranteed to have the 1st argument
     *                      be the sender
     * @param insertFeeAmount     Whether the gas estimate of the executor should be inserted
     *                      into the callData
     * @param isAlive       Whether or not the request should be deleted after it's executed
     *                      for the first time. If `true`, the request will exist permanently
     *                      (tho it can be cancelled any time), therefore executing the same
     *                      request repeatedly aslong as the request is executable,
     *                      and can be used to create fully autonomous contracts - the
     *                      first single-celled cyber life. We are the gods now
     * @return id   The id of the request, equal to the index in `_hashedReqs`
     */
    function newReq(
        address target,
        address payable referer,
        bytes calldata callData,
        uint112 ethForCall,
        bool verifyUser,
        bool insertFeeAmount,
        bool isAlive
    ) external payable returns (uint id);

    /**
     * @notice  Creates a new request, logs the request info in an event, then saves
     *          a hash of it on-chain in `_hashedReqs`
     * @param target    The contract address that needs to be called
     * @param referer       The referer to get rewarded for referring the sender
     *                      to using Autonomy. Usally the address of a dapp owner
     * @param callData  The calldata of the call that the request is to make, i.e.
     *                  the fcn identifier + inputs, encoded
     * @param ethForCall    The ETH to send with the call
     * @param verifyUser  Whether the 1st input of the calldata equals the sender.
     *                      Needed for dapps to know who the sender is whilst
     *                      ensuring that the sender intended
     *                      that fcn and contract to be called - dapps will
     *                      require that msg.sender is the Verified Forwarder,
     *                      and only requests that have `verifyUser` = true will
     *                      be forwarded via the Verified Forwarder, so any calls
     *                      coming from it are guaranteed to have the 1st argument
     *                      be the sender
     * @param insertFeeAmount     Whether the gas estimate of the executor should be inserted
     *                      into the callData
     * @param payWithAUTO   Whether the sender wants to pay for the request in AUTO
     *                      or ETH. Paying in AUTO reduces the fee
     * @param isAlive       Whether or not the request should be deleted after it's executed
     *                      for the first time. If `true`, the request will exist permanently
     *                      (tho it can be cancelled any time), therefore executing the same
     *                      request repeatedly aslong as the request is executable,
     *                      and can be used to create fully autonomous contracts - the
     *                      first single-celled cyber life. We are the gods now
     * @return id   The id of the request, equal to the index in `_hashedReqs`
     */
    function newReqPaySpecific(
        address target,
        address payable referer,
        bytes calldata callData,
        uint112 ethForCall,
        bool verifyUser,
        bool insertFeeAmount,
        bool payWithAUTO,
        bool isAlive
    ) external payable returns (uint id);

    /**
     * @notice  Gets all keccak256 hashes of encoded requests. Completed requests will be 0x00
     * @return  [bytes32[]] An array of all hashes
     */
    function getHashedReqs() external view returns (bytes32[] memory);

    /**
     * @notice  Gets part of the keccak256 hashes of encoded requests. Completed requests will be 0x00.
     *          Needed since the array will quickly grow to cost more gas than the block limit to retrieve.
     *          so it can be viewed in chunks. E.g. for an array of x = [4, 5, 6, 7], x[1, 2] returns [5],
     *          the same as lists in Python
     * @param startIdx  [uint] The starting index from which to start getting the slice (inclusive)
     * @param endIdx    [uint] The ending index from which to start getting the slice (exclusive)
     * @return  [bytes32[]] An array of all hashes
     */
    function getHashedReqsSlice(uint startIdx, uint endIdx) external view returns (bytes32[] memory);

    /**
     * @notice  Gets the total number of requests that have been made, hashed, and stored
     * @return  [uint] The total number of hashed requests
     */
    function getHashedReqsLen() external view returns (uint);
    
    /**
     * @notice      Gets a single hashed request
     * @param id    [uint] The id of the request, which is its index in the array
     * @return      [bytes32] The sha3 hash of the request
     */
    function getHashedReq(uint id) external view returns (bytes32);


    //////////////////////////////////////////////////////////////
    //                                                          //
    //                        Bytes Helpers                     //
    //                                                          //
    //////////////////////////////////////////////////////////////

    /**
     * @notice      Encode a request into bytes
     * @param r     [request] The request to be encoded
     * @return      [bytes] The bytes array of the encoded request
     */
    function getReqBytes(Request memory r) external pure returns (bytes memory);

    function insertToCallData(bytes calldata callData, uint expectedGas, uint startIdx) external pure returns (bytes memory);


    //////////////////////////////////////////////////////////////
    //                                                          //
    //                         Executions                       //
    //                                                          //
    //////////////////////////////////////////////////////////////

    /**
     * @notice      Execute a hashedReq. Calls the `target` with `callData`, then
     *              charges the user the fee, and gives it to the executor
     * @param id    [uint] The index of the request in `_hashedReqs`
     * @param r     [request] The full request struct that fully describes the request.
     *              Typically known by seeing the `HashedReqAdded` event emitted with `newReq`
     * @param expectedGas   [uint] The gas that the executor expects the execution to cost,
     *                      known by simulating the the execution of this tx locally off-chain.
     *                      This can be forwarded as part of the requested call such that the
     *                      receiving contract knows how much gas the whole execution cost and
     *                      can do something to compensate the exact amount (e.g. as part of a trade).
     *                      Cannot be more than 10% above the measured gas cost by the end of execution
     * @return gasUsed      [uint] The gas that was used as part of the execution. Used to know `expectedGas`
     */
    function executeHashedReq(
        uint id,
        Request calldata r,
        uint expectedGas
    ) external returns (uint gasUsed);


    //////////////////////////////////////////////////////////////
    //                                                          //
    //                        Cancellations                     //
    //                                                          //
    //////////////////////////////////////////////////////////////
    
    /**
     * @notice      Execute a hashedReq. Calls the `target` with `callData`, then
     *              charges the user the fee, and gives it to the executor
     * @param id    [uint] The index of the request in `_hashedReqs`
     * @param r     [request] The full request struct that fully describes the request.
     *              Typically known by seeing the `HashedReqAdded` event emitted with `newReq`
     */
    function cancelHashedReq(
        uint id,
        Request memory r
    ) external;
    
    
    //////////////////////////////////////////////////////////////
    //                                                          //
    //                          Getters                         //
    //                                                          //
    //////////////////////////////////////////////////////////////
    
    function getAUTOAddr() external view returns (address);
    
    function getStakeManager() external view returns (address);

    function getOracle() external view returns (address);
    
    function getUserForwarder() external view returns (address);
    
    function getGasForwarder() external view returns (address);
    
    function getUserGasForwarder() external view returns (address);
    
    function getReqCountOf(address addr) external view returns (uint);
    
    function getExecCountOf(address addr) external view returns (uint);
    
    function getReferalCountOf(address addr) external view returns (uint);
}

pragma solidity 0.8.6;


interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}