/**
 *Submitted for verification at BscScan.com on 2022-09-09
*/

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: TaxContract.sol



pragma solidity 0.8.6;





contract TaxContract is Ownable {
    using SafeMath for uint256;
    uint256 constant maximumPercentage = 5000; // 50% maximum
    struct Tax {
        uint256 from;
        uint256 to;
        uint256 percent; //2 decimal
        bool valid;
    }

    Tax[] public taxs;

    mapping(address => bool) excludedTax;

    address constant ownerAddress =
        0x0858953Ba2599AF7a9Cc7605912cB60Ec3Bf5C59;

    event ExcludedTax(address user, bool isExcluded, uint256 time);

    constructor() {
        excludedTax[ownerAddress] = true;
        emit ExcludedTax(ownerAddress, true, block.timestamp);
        excludedTax[_msgSender()] = true;
        emit ExcludedTax(_msgSender(), true, block.timestamp);
    }

    function setExcludedTaxes(
        address[] memory _accounts,
        bool[] memory _isExcludeds
    ) external onlyOwner {
        require(
            _accounts.length == _isExcludeds.length,
            "Error: input invalid"
        );
        for (uint8 i = 0; i < _accounts.length; i++) {
            require(_accounts[i] != address(0), "Error: address(0");
            excludedTax[_accounts[i]] = _isExcludeds[i];
            emit ExcludedTax(_accounts[i], _isExcludeds[i], block.timestamp);
        }
    }

    event SetTax(
        uint256 from,
        uint256 to,
        uint256 percent,
        bool valid,
        uint256 time
    );

    function setTaxes(
        uint256[] calldata _froms,
        uint256[] calldata _tos,
        uint256[] calldata _percents,
        bool[] calldata _valids
    ) external onlyOwner {
        require(_froms.length == _tos.length, "Error: invalid input");
        require(_froms.length == _percents.length, "Error: invalid input");
        require(_froms.length == _valids.length, "Error: invalid input");

        if (_froms.length > 0) {
            delete taxs;

            for (uint256 i = 0; i < _froms.length; i++) {
                require(
                    _percents[i] < maximumPercentage,
                    "Error: exceed maximum"
                );
                Tax storage tax = taxs.push();
                tax.from = _froms[i];
                tax.to = _tos[i];
                tax.percent = _percents[i];
                tax.valid = _valids[i];
                emit SetTax(
                    _froms[i],
                    _tos[i],
                    _percents[i],
                    _valids[i],
                    block.timestamp
                );
            }
        }
    }

    event UpdateTax(
        uint256 index,
        uint256 from,
        uint256 to,
        uint256 percent,
        uint256 time
    );

    function updateTax(
        uint256 _index,
        uint256 _from,
        uint256 _to,
        uint256 _percent
    ) external onlyOwner {
        require(_index < taxs.length, "Invalid _index");
        require(_from > 0, "Invalid from");
        require(_to > _from, "Invalid from to");
        require(_percent < maximumPercentage, "Error: exceed maximum");

        if (_from != taxs[_index].from) taxs[_index].from = _from;

        if (_to != taxs[_index].to) taxs[_index].to = _to;

        if (_percent != taxs[_index].percent) taxs[_index].percent = _percent;
        emit UpdateTax(_index, _from, _to, _percent, block.timestamp);
    }

    function getTax()
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        for (uint256 i = 0; i < taxs.length; i++) {
            Tax memory tax = taxs[i];

            if (tax.from == 0 && tax.to == 0 && tax.valid)
                return (0, 0, 0, tax.percent);

            if (
                block.timestamp >= tax.from &&
                block.timestamp <= tax.to &&
                tax.valid
            ) return (i + 1, tax.from, tax.to, tax.percent);
        }

        return (0, 0, 0, 0);
    }

    function applyTax(
        address _sender,
        address _recipient,
        uint256 _amount
    ) external view returns (uint256) {
        if (taxs.length == 0) return 0;

        if (excludedTax[_sender] || excludedTax[_recipient]) return 0;

        (, , , uint256 percent) = getTax();

        if (percent > 0) {
            uint256 taxAmount = uint256(_amount * percent) / uint256(10000); //2 decimals
            return taxAmount;
        }
        return 0;
    }

    event Withdraw(address tokenContract, uint256 amount, uint256 time);

    function withdrawToken(address _tokenContract, uint256 _amount)
        external
        onlyOwner
    {
        require(
            _tokenContract != address(0) && _tokenContract != address(this),
            "Error: address invalid"
        );
        IERC20(_tokenContract).transfer(_msgSender(), _amount);
        emit Withdraw(_tokenContract, _amount, block.timestamp);
    }
}
// File: FUBI.sol



pragma solidity 0.8.6;






contract FUBI is Ownable, IERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    uint8 private _decimals;
    string private _symbol;
    string private _name;

    TaxContract taxContract;

    address constant ownerAddress =
        0x0858953Ba2599AF7a9Cc7605912cB60Ec3Bf5C59;

    constructor(TaxContract _taxContract) {
        require(address(_taxContract) != address(0), "Error: address(0)");
        _name = "Future Big Finance";
        _symbol = "FUBI";
        _decimals = 18;
        _mint(ownerAddress, 500 * 10**6 * 10**18);
        taxContract = _taxContract;
    }

    event UpdateTaxContract(
        address oldContract,
        address newContract,
        uint256 time
    );

    function updateTaxContract(TaxContract _taxContract) external onlyOwner {
        require(address(_taxContract) != address(0), "Error: address(0)");
        emit UpdateTaxContract(
            address(taxContract),
            address(_taxContract),
            block.timestamp
        );
        taxContract = _taxContract;
    }

    function getOwner() external view returns (address) {
        return owner();
    }

    function decimals() external view returns (uint8) {
        return _decimals;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account)
        external
        view
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address from, uint256 value) internal {
        _balances[from] = _balances[from].sub(value);
        _totalSupply = _totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address from, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[from][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );

        uint256 taxAmount = 0;
        if (address(taxContract) != address(0))
            taxAmount = taxContract.applyTax(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
        if (taxAmount > 0) {
            _balances[recipient] = _balances[recipient].add(amount - taxAmount);
            _balances[address(taxContract)] = _balances[address(taxContract)]
                .add(taxAmount);
            emit Transfer(sender, recipient, amount - taxAmount);
            emit Transfer(sender, address(taxContract), taxAmount);
        } else {
            _balances[recipient] = _balances[recipient].add(amount);
            emit Transfer(sender, recipient, amount);
        }
    }

    event Withdraw(address tokenContract, uint256 amount, uint256 time);

    function withdrawToken(address _tokenContract, uint256 _amount)
        external
        onlyOwner
    {
        require(
            _tokenContract != address(0) && _tokenContract != address(this),
            "Error: address invalid"
        );
        IERC20 token = IERC20(_tokenContract);

        token.transfer(msg.sender, _amount);
        emit Withdraw(_tokenContract, _amount, block.timestamp);
    }

    function _approve(
        address from,
        address spender,
        uint256 amount
    ) internal {
        require(from != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[from][spender] = amount;
        emit Approval(from, spender, amount);
    }
}