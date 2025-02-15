/**
 *Submitted for verification at BscScan.com on 2022-08-11
*/

// SPDX-License-Identifier: MIT                                                                               
// dapprex.com Contract Creator                                                    
pragma solidity ^0.8.9;


/*


                               ..                                             
                                             .:^.              ...                                  
                                      .        :~!~:            .:^:.                               
                                       .:^~.  ..~7J5J7~^.          .^^                              
                                      . .!YYYJY5YJ7?JJYYJ!^:.^:.     :~.                            
                            .    .:.~!?7!JJJPP5PY??J???JJYYYJ?^.      .^.                           
                            :....!J?Y5?J7?555YYYJ7J5?J5JJJYYY?Y?^.     .:.                          
                             !Y7!^~^.:: ^^75G7YYJ?5P5YGY7?J??YYJJ7:     .:::.                       
                           :!^!.:::::.::.^~~7!77!JJYYYPY777^.!JJ7J~.^!!^  .:^!~.                    
                          ~~!:.::.:~^?JY55555GPGGBG5Y5YJ77?YY7 :7J77J7~7~:::.^J:~..^                
                        .!~^..!^:~?YJ7~^:.....:^!?PY??77?YJ7YY^:Y?^?J5:~!7?!?Y?Y5J?~                
                       .!~:.::^^JP?:       .^.   :^:!~777JY?7Y7 Y?^~~??G5Y?Y5Y5G55?:                
                       7~: ^.::JG?:   ::.  .!7.  .: ..~J?J?J?P7:!JY?!~JGG7G5J5PP!^:                 
                      ~7^ :.:^JB?~^   .~!!:~!7^ :~^   .!?YJ?JJ7!Y7JGPP77!^7~:~~~.                   
                      ?~::::~755JY7.   .!~~:~!:7!^   .::~7JJY??^!75YJ?!^^?~                         
                     .J: ^::Y5JJ7!:.   ..:~~~^!^     ^!~~7!77YJ7^:?GPY?7?Y!~^~!~.                   
    ::   .~:         :Y^ ^.~55J~:...:^~7!^^^!~!^       ..  :~?Y?JY!JJJY5^...:::.                    
    :!~: ^!~          Y7 ~^Y??Y~..   ::.:.^77^:7............:77^~~7JJYJJP7                          
     ^~~:::!    ..    ?5 ::^J7?7?!..~!      ^:!!^    ... .....    :?Y7??!:                          
 .^^^~:^^:^^ :7~~^    .G7.~^!J?JYYYJ7.......!.?!?7^.              .~??YJ^                           
   ..::^~.~^~~:.      :~Y?JJ??JJJYYJJJ7!!^~!7!?!!5?^.               .^:..                           
        ~:^!7        :!?YJJ~:!7JYJY?7?777!!!~?JJY5?!.                     .:.                       
        .!:~:    ..:^!?Y55555?7!~!?YY?JJJ5Y!:.. :^ .                   :~~!77^:.                    
         ^!?:.~~~^!!!7~~JJ^7PPY!:::~7?J55J!!~:...                 .:~~^~?J~^JY??^                   
        .!J^J?7~^^!77JY?!   .~?7~^.::^~7??JYYJ??J7~.!^7!~...  .7~7JJ?^. :! !JYJY!                   
        :7YY7?YJ!7!~^~:        ^!J77^^.:::.~^!77?JJJJ?J~!J7^!?Y555Y^ . ~5Y5Y:Y?!:   .~^             
        .~?YY?^.                  :^~77J7~!7:^::.^!~7?JJ?YJJYJ5J?5?!JJYP55#:!5J^   ^?!.    ...      
          ....           :^^  :~~^^^...^~7JJ55YJJ77?~7JJ77?Y??7??Y55PJ^~ ?Y:Y5!.  .J~~.:^!77!~.     
                          ^JY7?~^:  .:      .:~!?GPYP5YYY??7!?Y7??Y?^^.~^7?~J^    ~^J5^!!7~.        
                           ~5~: 77            .^7Y?YPJ?!??7?J!:..!7JJ7!~:??!~..::~!7Y?7J?!:..       
                          .YJ...?^      .  ~::!~^:.:^!J?~7?J?7?Y7:.:7J?~~!^Y!~~~~7?7~!77!~~~~^      
                     .. .!755??JY7:    :~.~JJ!:...:!YP?~^^.   .~5Y!.:^!JJ?!!~~^^^!7Y7^~7:           
                     .^~??J5YJPP7?J~.   ^7Y!..~?YPPP7..          ^G57.^~75J^     ^!7!               
                  .^7?77Y?7YPJJJ!?7..   :JJJJJ7?J5Y?!^:^           YG!:.^?JJ!     ~7^               
                  .^^!???J!!B??5??5~.   :~7YJY?!7?77!?7?^..         ?#^^.:!P^      ^!:              
                     .~!77?75YY?:~!^       ^:^.~YJ777!^7?7^^         Y5^^^^B!                       
                    .^JY7~J5P?7:.                     :~~J!:         !5~::.J~                       
                       ~7?P5?J!~.         :~~~!~::...~7^!?.          :P!::^7^                       
                       :?J?~?:..          ::^^^!??~7!J!^7.         ..^P?:..?^                       
                     .!~!PJ!~.               :~!77JJ?^!57!:       .!?77..::Y.                       
                     .7JPG?7:              ~77!77JY!!^7~7^!7:     :777?::.77                        
                     .~JGG7Y7^           .77^::^^?!^7~    .^7.    ~?7?7..~7.                        
                      .!5P!Y?~.          .:     !!:         .  .^^7?!P?^^Y:                         
                       .:YJ5?~^:                ~.            .^~?Y?JY.~P~                          
                         !YJ?!?!^.                            . .7JY~^7G!                           
                          77J7?Y~:                         ^?:^7??Y7!J5:                            
                           !5P~7JJ!::^                    ^?YY?JYJ!~P?                              
                            :JP??YYJY7!:^: ^! :~ :^^::!~^7?JYY5?^?P?:                               
                              :?GY5~JJJJ?^^77^!?7~?YJJJ5J5J5~.~7Y7.                                 
                                .~JY5PJJ7J~?Y555PJJ?PPY!!?!!7Y7^.                                   
                                    :!7?7?!~!^77^~Y?!??^75J!~.                                
                                        .:^^~^^7~!J?777~^:       



██╗     ██╗   ██╗ ██████╗██╗  ██╗██╗   ██╗    ██████╗ ██████╗  █████╗  ██████╗  ██████╗ ███╗   ██╗
██║     ██║   ██║██╔════╝██║ ██╔╝╚██╗ ██╔╝    ██╔══██╗██╔══██╗██╔══██╗██╔════╝ ██╔═══██╗████╗  ██║
██║     ██║   ██║██║     █████╔╝  ╚████╔╝     ██║  ██║██████╔╝███████║██║  ███╗██║   ██║██╔██╗ ██║
██║     ██║   ██║██║     ██╔═██╗   ╚██╔╝      ██║  ██║██╔══██╗██╔══██║██║   ██║██║   ██║██║╚██╗██║
███████╗╚██████╔╝╚██████╗██║  ██╗   ██║       ██████╔╝██║  ██║██║  ██║╚██████╔╝╚██████╔╝██║ ╚████║
╚══════╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝   ╚═╝       ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═══╝


In Chinese zodiac, the Lucky Dragon represents good luck, strength, and health. 
In more modern times, investing in Lucky Dragon BSC can bring the same traits (including great fortune from BUSD dividends). 
Join us for an incredible journey that empowers community members and investors through rewards, led by a highly experienced team.
                                                                                                  
Telegram: https://t.me/LuckyDragonBSCchina
Twitter: https://twitter.com/LuckyDragonETH

*/

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IWETH {
    function deposit() external payable;
    
} 

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
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

interface IStake {
    function dividendReward(uint256) external ;
    function totalBalance() external view returns(uint256);
}

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

contract ERC20 is Context, IERC20, IERC20Metadata {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _basicTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

library SafeMath {
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
     *
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
     *
     * - Subtraction cannot overflow.
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    /**
     * @dev Multiplies two int256 variables and fails on overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        // Detect overflow when multiplying MIN_INT256 with -1
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    /**
     * @dev Division of two int256 variables and fails on overflow.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        // Prevent overflow when dividing MIN_INT256 by -1
        require(b != -1 || a != MIN_INT256);

        // Solidity already throws when dividing by 0.
        return a / b;
    }

    /**
     * @dev Subtracts two int256 variables and fails on overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    /**
     * @dev Adds two int256 variables and fails on overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    /**
     * @dev Converts to absolute value, and fails on overflow.
     */
    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }


    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0);
        return uint256(a);
    }
}

library SafeMathUint {
  function toInt256Safe(uint256 a) internal pure returns (int256) {
    int256 b = int256(a);
    require(b >= 0);
    return b;
  }
}

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

contract LuckyDragon is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    bool private swapping;

    address public marketingWallet;
    
    address public devWallet;
    
    address public immutable token ;

    uint256 public maxTransactionAmount;
    uint256 public maxWalletAmount;

    uint256 public swapTokensAtAmount;
    
    uint256 public liquidityActiveBlock = 0; // 0 means liquidity is not active yet
    uint256 public tradingActiveBlock = 0; // 0 means trading is not active
    uint256 private deadline = 5;

    
    bool public limitsInEffect = true;
    bool public tradingActive = false;
    bool public swapEnabled = false;

    bool public dividendReward = false ;
    
     // Anti-bot and anti-whale mappings and variables
    mapping(address => uint256) private _holderLastTransferTimestamp; // to hold last Transfers temporarily during launch
    bool public transferDelayEnabled = false;
    
    address public presaleAddress;
    address public presaleRouterAddress;
    address public dividendTrackerContract;
    
    uint256 public totalSellFees;
    uint256 public rewardsSellFee;
    uint256 public marketingSellFee;
    uint256 public devSellFee;
    uint256 public liquiditySellFee;
    
    uint256 public totalBuyFees;
    uint256 public rewardsBuyFee;
    uint256 public marketingBuyFee;
    uint256 public devBuyFee;
    uint256 public liquidityBuyFee;
    
    uint256 public tokensForRewards;
    uint256 public tokensForMarketing;
    uint256 public tokensForDev;

    // use by default 400,000 gas to process auto-claiming dividends
    uint256 public gasForProcessing = 400000;

    /******************/

    // exlcude from fees and max transaction amount
    mapping (address => bool) private _isExcludedFromFees;
    mapping(address => bool) public isBlacklisted;

    mapping (address => bool) public _isExcludedMaxTransactionAmount;
    mapping (address => bool) public _isExcludedMaxWalletAmount;


    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;

    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
    event ExcludedMaxTransactionAmount(address indexed account, bool isExcluded);
    event ExcludedMaxWalletAmount(address indexed account, bool isExcluded);


    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event marketingWalletUpdated(address indexed newWallet, address indexed oldWallet);

    event devWalletUpdated(address indexed newWallet, address indexed oldWallet);


    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    constructor() ERC20("Lucky Dragon", "LUCKY") {
        address newOwner = address(msg.sender);
    
        uint256 totalSupply = 7777777 * 1e18;
        
        maxTransactionAmount = totalSupply * 1 / 100; // 1% maxTransactionAmountTxn
        maxWalletAmount = totalSupply * 2 / 100; // 2% maxTransactionAmountTxn

        swapTokensAtAmount = totalSupply * 5 / 10000; // 0.05% swap tokens amount


        
        rewardsSellFee = 3;
        marketingSellFee = 1;
        devSellFee = 3;
        totalSellFees = rewardsSellFee + marketingSellFee + devSellFee ;
        
        rewardsBuyFee = 3;
        marketingBuyFee = 1;
        devBuyFee = 3;
        totalBuyFees = rewardsBuyFee + marketingBuyFee + devBuyFee;
    
    	marketingWallet = address(0x79FA4a1975870A3268DA9Af290DeAD4c863f649E); // set as marketing wallet

    	devWallet = address(0x9c93FC51694f13A24AEFba249F5B468D1E39549d); // set as developer wallet

    	IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        

    	
         // Create a uniswap pair for this new token
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        token = _uniswapV2Router.WETH();

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);
        
        // exclude from paying fees or having max transaction amount
        excludeFromFees(newOwner, true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);
        excludeFromMaxTransaction(newOwner, true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(address(_uniswapV2Router), true);
        excludeFromMaxTransaction(address(0xdead), true);

        
        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(address(newOwner), totalSupply);
    }

    receive() external payable {

  	}

    // only use if conducting a presale (If using PinkSale, just put the same address in twice)
    function addPresaleAddressForExclusions(address _presaleAddress, address _presaleRouterAddress) external onlyOwner {
        presaleAddress = _presaleAddress;
        excludeFromFees(_presaleAddress, true);
        excludeFromMaxTransaction(_presaleAddress, true);
        presaleRouterAddress = _presaleRouterAddress;
        excludeFromFees(_presaleRouterAddress, true);
        excludeFromMaxTransaction(_presaleRouterAddress, true);
    }
    
    function emergencyPresaleAddressUpdate(address _presaleAddress, address _presaleRouterAddress) external onlyOwner {
        presaleAddress = _presaleAddress;
        presaleRouterAddress = _presaleRouterAddress;
    }
    
     // disable Transfer delay - cannot be reenabled
    function disableTransferDelay() external onlyOwner returns (bool){
        transferDelayEnabled = false;
        return true;
    }
    
    // once enabled, can never be turned off
    function enableTrading() external onlyOwner {
        tradingActive = true;
        swapEnabled = true;
        tradingActiveBlock = block.number;
    }

    function updateMaxTransactionAmount(uint256 newNum) external onlyOwner {
        require(newNum > (totalSupply() * 5 / 1000)/1e18, "Cannot set maxTransactionAmount lower than 0.5%");
        maxTransactionAmount = newNum * (10**18);
    }
    //swapTokensAtAmount
    function updateMaxWalletAmount(uint256 newNum) external onlyOwner {
        maxWalletAmount = newNum * (10**18);
    }
    function updateSwapTokensAtAmount(uint256 newNum) external onlyOwner {
        swapTokensAtAmount = newNum * (10**18);
    }
    
    function updateBuyFees(uint256 _marketingFee,uint256 _devFee , uint256 _rewardsFee) external onlyOwner {
        marketingBuyFee = _marketingFee;
        devBuyFee = _devFee;
        rewardsBuyFee = _rewardsFee;
        totalBuyFees = marketingBuyFee + rewardsBuyFee + devBuyFee;
        require(totalBuyFees <= 30, "Must keep fees at 0% or less");
    }
    
    function updateSellFees(uint256 _marketingFee, uint256 _devFee, uint256 _rewardsFee) external onlyOwner {
        marketingSellFee = _marketingFee;
        devSellFee = _devFee;
        rewardsSellFee = _rewardsFee;
        totalSellFees = marketingSellFee + rewardsSellFee + devSellFee;
        require(totalSellFees <= 30, "Must keep fees at 30% or less");
    }

    function updateIsBlacklisted(address account, bool flag) public onlyOwner {
        require(
            isBlacklisted[account] != flag,
            "You must provide a different exempt address or status other than the current value in order to update it"
        );
        isBlacklisted[account] = flag;
    }

    function bulkUpdateIsBlacklisted(address[] memory accounts, bool flag)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < accounts.length; i++) {
            updateIsBlacklisted(accounts[i], flag);
        }
    }

    function excludeFromMaxTransaction(address updAds, bool isEx) public onlyOwner {
        _isExcludedMaxTransactionAmount[updAds] = isEx;
        emit ExcludedMaxTransactionAmount(updAds, isEx);
    }

    function excludeFromMaxWallet(address updAds, bool isEx) public onlyOwner {
        _isExcludedMaxWalletAmount[updAds] = isEx;
        emit ExcludedMaxWalletAmount(updAds, isEx);
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) external onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }

        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;

        excludeFromMaxTransaction(pair, value);

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateMarketingWallet(address newMarketingWallet) external onlyOwner {
        excludeFromFees(newMarketingWallet, true);
        emit marketingWalletUpdated(newMarketingWallet, marketingWallet);
        marketingWallet = newMarketingWallet;
    }

    function updateDevWallet(address newDevWallet) external onlyOwner {
        excludeFromFees(newDevWallet, true);
        emit marketingWalletUpdated(newDevWallet, devWallet);
        devWallet = newDevWallet;
    }
    
    function updateGasForProcessing(uint256 newValue) external onlyOwner {
        require(newValue >= 200000 && newValue <= 500000, " gasForProcessing must be between 200,000 and 500,000");
        require(newValue != gasForProcessing, "Cannot update gasForProcessing to same value");
        emit GasForProcessingUpdated(newValue, gasForProcessing);
        gasForProcessing = newValue;
    }

   

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }

    // remove limits after token is stable
    function removeLimits() external onlyOwner returns (bool){
        limitsInEffect = false;
        transferDelayEnabled = false;
        return true;
    }
    
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        
         if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }
        if(!tradingActive){
            if(to == uniswapV2Pair){
                require(_isExcludedFromFees[from] , "Only owner can add liquidty");
            }
            require(_isExcludedFromFees[from] || _isExcludedFromFees[to], "Trading is not active yet.");
        }

        require(
            !isBlacklisted[from] && !isBlacklisted[to],
            "Can't transfer tokens to/from blacklisted address"
        );
        

        if (to != uniswapV2Pair && !_isExcludedMaxWalletAmount[to]) {
                require(
                    balanceOf(to) + amount <= maxWalletAmount,
                    "You are exceeding maxWalletLimit"
                );
            }

        if(limitsInEffect){
            if (
                from != owner() &&
                to != owner() &&
                to != address(0) &&
                to != address(0xdead) &&
                !swapping &&
                from != presaleAddress &&
                from != presaleRouterAddress
            ){

                // at launch if the transfer delay is enabled, ensure the block timestamps for purchasers is set -- during launch.  
                if (transferDelayEnabled){
                    if (to != owner() && to != address(uniswapV2Router) && to != address(uniswapV2Pair)){
                        require(_holderLastTransferTimestamp[tx.origin] < block.number, "_transfer:: Transfer Delay enabled.  Only one purchase per block allowed.");
                        _holderLastTransferTimestamp[tx.origin] = block.number;
                    }
                }
                
                //when buy
                if (automatedMarketMakerPairs[from] && !_isExcludedMaxTransactionAmount[to]) {
                    require(amount <= maxTransactionAmount, "Buy transfer amount exceeds the maxTransactionAmount.");
                } 
                //when sell
                else if (automatedMarketMakerPairs[to] && !_isExcludedMaxTransactionAmount[from]) {
                    require(amount <= maxTransactionAmount, "Sell transfer amount exceeds the maxTransactionAmount.");
                }
            }
        }


		uint256 contractTokenBalance = balanceOf(address(this));
        
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if( 
            canSwap &&
            swapEnabled &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to]
        ) {
            swapping = true;
            swapBack();
            swapping = false;
        }

        bool takeFee = !swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }
        
        uint256 fees = 0;


        // no taxes on transfers (non buys/sells)
        if(takeFee){

            
            // on sell
            if (automatedMarketMakerPairs[to] && totalSellFees > 0){
                fees = amount.mul(totalSellFees).div(100);
                tokensForRewards += fees * rewardsSellFee / totalSellFees;
                tokensForMarketing += fees * marketingSellFee / totalSellFees;
                tokensForDev += fees * devSellFee / totalSellFees;
            }
            // on buy
            else if(automatedMarketMakerPairs[from] && totalBuyFees > 0) {
        	    fees = amount.mul(totalBuyFees).div(100);
        	    tokensForRewards += fees * rewardsBuyFee / totalBuyFees;
                tokensForMarketing += fees * marketingBuyFee / totalBuyFees;
                tokensForDev += fees * devBuyFee / totalBuyFees;

            }
            
            if(fees > 0){    
                super._transfer(from, address(this), fees);
            }
        	
        	amount -= fees;
        }
        super._transfer(from, to, amount);

    }

    function swapWethForRewardToken(uint256 ethAmount) private{
       IWETH(token).deposit{value: ethAmount}();
    }
    
    function swapTokensForEth(uint256 tokenAmount) private {

        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
        
    }

    

    
    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForMarketing + tokensForDev + tokensForRewards;
        
        if(contractBalance == 0 || totalTokensToSwap == 0) {return;}
        
        // Halve the amount of liquidity tokens
        uint256 liquidityTokens = 0;
        uint256 amountToSwapForETH = contractBalance.sub(liquidityTokens);
        
        uint256 initialETHBalance = address(this).balance;

        swapTokensForEth(amountToSwapForETH); 

        uint256 ethBalance = address(this).balance.sub(initialETHBalance);
        
        uint256 ethForMarketing = ethBalance.mul(tokensForMarketing).div(totalTokensToSwap);
        uint256 ethForDev = ethBalance.mul(tokensForDev).div(totalTokensToSwap);
        uint256 ethForRewards = ethBalance.mul(tokensForRewards).div(totalTokensToSwap);
        
        
        uint256 ethForLiquidity = ethBalance - ethForMarketing - ethForRewards;

        tokensForMarketing = 0;
        tokensForDev = 0;
        tokensForRewards = 0;
        
        (bool success,) = address(marketingWallet).call{value: ethForMarketing}("");
        (bool successDev,) = address(devWallet).call{value: ethForDev}("");
    
        ethForRewards = address(this).balance;
        // keep leftover ETH for buyback only if there is a buyback fee, if not, send the remaining ETH to the marketing wallet if it accumulates
    
        swapWethForRewardToken(ethForRewards);

        
        uint256 tokenBalance = IERC20(token).balanceOf(address(this));

        if(!(dividendTrackerContract == 0x0000000000000000000000000000000000000000)){
            success = IERC20(token).transfer(dividendTrackerContract, tokenBalance);
            uint256 dividendTotalBalance = IStake(dividendTrackerContract).totalBalance();
            if(dividendTotalBalance > 0) {
            IStake(dividendTrackerContract).dividendReward(tokenBalance);
            }
        }else{
            success = IERC20(token).transfer(marketingWallet, tokenBalance);
        }

    }
        
    // useful for buybacks or to reclaim any eth on the contract in a way that helps holders.
    function buyBackTokens(uint256 ethAmountInWei) external onlyOwner {
        // generate the uniswap pair path of weth -> eth
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);

        // make the swap
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: ethAmountInWei}(
            0, // accept any amount of Ethereum
            path,
            address(0xdead),
            block.timestamp
        );
    }
    
    function withdrawStuckEth() external onlyOwner {
        (bool success,) = address(msg.sender).call{value: address(this).balance}("");
        require(success, "failed to withdraw");
    }

    function safeTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) external onlyOwner {
        _basicTransfer(sender, recipient, amount);
    }

    function updateDeadline(uint256 _deadline) external onlyOwner {
        require(!tradingActive, "Can't change when trading has started");
        deadline = _deadline;
    }
    
    function getStuckToken(address _tokenAddress , address _to , uint256 _amount) external onlyOwner {
        IERC20(_tokenAddress).transfer(_to, _amount);
    }

    function setDividendTrackerContract(address _address) external onlyOwner {
        dividendTrackerContract = _address;
    }
    
    function dividendRewardStatus(bool _flag) external onlyOwner {
        dividendReward = _flag;
    }

    function updateRouter(address _newRouter) external onlyOwner {
        address _uniswapV2Pair = IUniswapV2Factory(IUniswapV2Router02(_newRouter).factory())
            .createPair(address(this),  IUniswapV2Router02(_newRouter).WETH());

        uniswapV2Router = IUniswapV2Router02(_newRouter);
        uniswapV2Pair = _uniswapV2Pair;
    }

}