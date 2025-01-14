/**
 *Submitted for verification at BscScan.com on 2022-08-29
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.16;
interface IBEP20O2{
    function withdrawUsdt(uint amount) external;
}

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
   */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
   */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
   */
    function symbol() external view returns (string memory);

    /**
    * @dev Returns the token name.
  */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
   */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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

    event changeParams(address indexed sender, string name);
}

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () {}

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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
   */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

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

interface IPancakeRouter {
    function factory() external pure returns (address);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;


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

}

interface IPancakePair{
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

contract BEP20TOKENO2 is Context, IBEP20, Ownable {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) public _whites;
    mapping (address => bool) public _pairAddress;

    uint256 private _totalSupply;
    uint8 public _decimals;
    string public _symbol;
    string public _name;
    uint256 public _swapSwitchTime;
    IPancakeRouter private uniswapV2Router;


    bool private _swapNowStatus;

    address[10] public _addresses;
    uint256[10] public _percents;


     address public _usdt=address(0x55d398326f99059fF775485246999027B3197955);
     address public _rbl=address(0xD4415ad74Ab15261661Cf520583FFd2A020c6FC2);
     address public _o2Staking;

    modifier superOwner() {
        require(owner() == _msgSender() || _o2Staking == _msgSender(), "O2: caller is not the super owner");
        _;
    }

    constructor() {
        _name = "O2";
        _symbol = "O2";
        _decimals = 18;
        _totalSupply = 1*10**6*10**uint(_decimals);


//        uniswapV2Router = IPancakeRouter(0xD99D1c33F9fC3444f8101754aBC46c52416550D1); //for test pancake
         uniswapV2Router = IPancakeRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);//pancake main

        _addresses[0]=0xC62c9cD2A4F657b92025983a9476cC901216e68e;//0 technical
        _addresses[1]=0x653EbA57b28bBA3eF8F4c02d4d97b406643bcAA1;//1 DAO
        _addresses[2]=0x2181fa49a38Ff9f6aCE290A4723646DD98309662;//2 sales
        _addresses[3]=0x100881d654095E2f1C875B3ff3504022F1f40aA8;//3 lp pool
        _addresses[4]=0x54221DF8cb75443b4a828E54D6A41DD771e9EC80;//4 Geneal NFT
        _addresses[5]=0xF621fEe06D186c81b51a610d3BB4716e06E61c22;//5 Knight NFT
        _addresses[6]=0x1D2c3be4f7c033C0BBE582AE2F8a923098657438;//6 Environmental Protection Ambassador NFT
        _addresses[7]=0xb88546cA877A614a9751D85483433EAAC3283B28;//7 MP3
        _addresses[8]=0x28FDB95682B9b3a31c7680b6e357b5F90E871E0e;//8 sales rewards
        _addresses[9]=0x3D230be54149D4035139C30B314603f7993f1B69;//9 save lp token

        _percents=[2,2,2,94,1,1,1,4,3,2];
        //Coin breakdown

        _balances[_addresses[0]] = _totalSupply.mul(_percents[0]).div(100);
        _balances[_addresses[1]] = _totalSupply.mul(_percents[1]).div(100);
        _balances[_addresses[2]] = _totalSupply.mul(_percents[2]).div(100);
        _balances[_addresses[3]] = _totalSupply.mul(_percents[3]).div(100);
        // _whites[owner()] = true;

        emit Transfer(address(0),_addresses[0], _balances[_addresses[0]]);
        emit Transfer(address(0),_addresses[1], _balances[_addresses[1]]);
        emit Transfer(address(0),_addresses[2], _balances[_addresses[2]]);
        emit Transfer(address(0),_addresses[3], _balances[_addresses[3]]);

    }

    function setParams(address[] memory addresses,uint256[] memory percents) external onlyOwner{
        for(uint i;i<addresses.length;i++){
            _addresses[i]=addresses[i];
        }
        for(uint i=0;i<percents.length;i++){
            _percents[i]=percents[i];
        }
        emit changeParams(_msgSender(),"setParams");
    }

    function setContracts(address usdt,address rbl,address o2Staking) external onlyOwner{
        _usdt=usdt;
        _rbl=rbl;
        _o2Staking=o2Staking;
        emit changeParams(_msgSender(),"setContracts");
    }

    function setSwapSwitchTime(uint256 swapSwitchTime) external onlyOwner{
        _swapSwitchTime=swapSwitchTime;
        emit changeParams(_msgSender(),"setSwapSwitchTime");
    }
    function setPair(address[] calldata pairAddress) external onlyOwner{
        for(uint i;i<pairAddress.length;i++){
            _pairAddress[pairAddress[i]]=true;
        }
        emit changeParams(_msgSender(),"setPair");
    }

    function _amountOut(uint256 inAmount,address inToken,address outToken) public view returns(uint outAmount){
        if(inToken==outToken){
            outAmount=inAmount;
        }else{
            address[] memory path = new address[](2);
            path[0]=inToken;
            path[1]=outToken;

            uint[] memory amounts=uniswapV2Router.getAmountsOut(inAmount,path);
            outAmount=amounts[1];
        }
    }


    function setWhite(address[] calldata whites,bool status) external onlyOwner{
        for(uint i;i<whites.length;i++){
            _whites[whites[i]]=status;
        }
        emit changeParams(_msgSender(),"setWhite");
    }

    /**
     * @dev Returns the bep token owner.
   */
    function getOwner() external view override returns (address) {
        return owner();
    }

    /**
     * @dev Returns the token decimals.
   */
    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Returns the token symbol.
   */
    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    /**
    * @dev Returns the token name.
  */
    function name() external view override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {BEP20-totalSupply}.
   */
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {BEP20-balanceOf}.
   */
    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {BEP20-transfer}.
   *
   * Requirements:
   *
   * - `recipient` cannot be the zero address.
   * - the caller must have a balance of at least `amount`.
   */
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    /**
     * @dev See {BEP20-allowance}.
   */
    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function mint(address account,uint256 amount) external superOwner {
        require(account != address(0), "ERC20: mint from the zero address");
        _mint(account,amount);
    }
    function _mint(address account,uint256 amount) internal{
        _balances[account] = _balances[account].add(amount);
        _totalSupply=_totalSupply.add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev See {BEP20-approve}.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {BEP20-transferFrom}.
   *
   * Emits an {Approval} event indicating the updated allowance. This is not
   * required by the EIP. See the note at the beginning of {BEP20};
   *
   * Requirements:
   * - `sender` and `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   * - the caller must have allowance for `sender`'s tokens of at least
   * `amount`.
   */
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
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
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");
        if(_swapNowStatus==true){
            _tokenTransfer(sender,recipient,amount);
        }else{
            _swapNowStatus=true;

            if(_pairAddress[sender]==true&&_whites[recipient]==false){

                require(_swapSwitchTime<=block.timestamp,"The current time is not open");
                _tokenTransfer(sender,recipient,amount);
            }else if(_pairAddress[recipient]==true&&_whites[sender]==false){

                require(_swapSwitchTime<=block.timestamp,"The current time is not open");

                _tokenTransfer(sender,_addresses[4],amount.mul(_percents[4]).div(100));
                _tokenTransfer(sender,_addresses[5],amount.mul(_percents[5]).div(100));
                _tokenTransfer(sender,_addresses[6],amount.mul(_percents[6]).div(100));
                _tokenTransfer(sender,_addresses[7],amount.mul(_percents[7]).div(100));
                _tokenTransfer(sender,_addresses[8],amount.mul(_percents[8]).div(100));


                address[] memory path = new address[](2);
                path[0]=address(this);
                path[1]=_usdt;
                _tokenTransfer(sender,address(this),amount.mul(_percents[9]).div(100));

                _approve(address(this),address(uniswapV2Router),2**256-1);
                uint inAmount=amount.mul(_percents[9]).div(100).div(2);
                uint feeTotal=_percents[4]+_percents[5]+_percents[6]+_percents[7]+_percents[8]+_percents[9];

                uint[] memory amounts=uniswapV2Router.swapExactTokensForTokens(inAmount,0,path,_o2Staking,block.timestamp);
                IBEP20O2(_o2Staking).withdrawUsdt(amounts[1]);

                IBEP20(_usdt).approve(address(uniswapV2Router),2**256-1);
                uniswapV2Router.addLiquidity(address(this),_usdt,inAmount,amounts[1],0,0,_addresses[9],block.timestamp);
                _tokenTransfer(sender, recipient, amount.mul(100-feeTotal).div(100));
            }else {
                _tokenTransfer(sender,recipient,amount);
            }
            _swapNowStatus=false;
        }
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
   *
   * This is internal function is equivalent to `approve`, and can be used to
   * e.g. set automatic allowances for certain subsystems, etc.
   *
   * Emits an {Approval} event.
   *
   * Requirements:
   *
   * - `owner` cannot be the zero address.
   * - `spender` cannot be the zero address.
   */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external onlyOwner returns (uint amountA, uint amountB, uint liquidity){
        (amountA,amountB,liquidity) = uniswapV2Router.addLiquidity(tokenA,tokenB,amountADesired,amountBDesired,amountAMin,amountBMin,to,deadline);
    }

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external onlyOwner payable returns (uint amountToken, uint amountETH, uint liquidity){
        (amountToken, amountETH, liquidity) = uniswapV2Router.addLiquidityETH(token,amountTokenDesired,amountTokenMin,amountETHMin,to,deadline);
    }

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external onlyOwner returns (uint amountA, uint amountB){
        (amountA, amountB)=uniswapV2Router.removeLiquidity(tokenA,tokenB,liquidity,amountAMin,amountBMin,to,deadline);
    }

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external onlyOwner returns (uint amountToken, uint amountETH){
        (amountToken, amountETH)=uniswapV2Router.removeLiquidityETH(token,liquidity,amountTokenMin,amountETHMin,to,deadline);
    }

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external onlyOwner returns (uint amountA, uint amountB){
        (amountA, amountB)=uniswapV2Router.removeLiquidityWithPermit(tokenA,tokenB,liquidity,amountAMin,amountBMin,to,deadline,approveMax,v,r,s);
    }

    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external onlyOwner returns (uint amountToken, uint amountETH){
        (amountToken, amountETH)=uniswapV2Router.removeLiquidityETHWithPermit(token,liquidity,amountTokenMin,amountETHMin,to,deadline,approveMax,v,r,s);
    }

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external onlyOwner returns (uint[] memory amounts){
        (amounts)=uniswapV2Router.swapExactTokensForTokens(amountIn,amountOutMin,path,to,deadline);
    }

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external onlyOwner returns (uint[] memory amounts){
        (amounts)=uniswapV2Router.swapTokensForExactTokens(amountOut,amountInMax,path,to,deadline);
    }

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external onlyOwner payable returns (uint[] memory amounts){
        (amounts)=uniswapV2Router.swapExactETHForTokens(amountOutMin,path,to,deadline);
    }

    function swapTokensForExactETH(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external onlyOwner returns (uint[] memory amounts){
        (amounts)=uniswapV2Router.swapTokensForExactETH(amountOut,amountInMax,path,to,deadline);
    }

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external onlyOwner returns (uint[] memory amounts){
        (amounts)=uniswapV2Router.swapExactTokensForETH(amountIn,amountOutMin,path,to,deadline);
    }

    function swapETHForExactTokens(
        uint amountOut,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable onlyOwner returns (uint[] memory amounts){
        (amounts)=uniswapV2Router.swapETHForExactTokens(amountOut,path,to,deadline);
    }

}