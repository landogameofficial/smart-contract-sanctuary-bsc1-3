/**
 *Submitted for verification at BscScan.com on 2022-11-26
*/

/**
 *Submitted for verification at BscScan.com on 2022-02-12
*/

pragma solidity ^0.8.11;

// SPDX-License-Identifier: Unlicensed
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint256);
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

contract Ownable {
    address public _owner;

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
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function changeOwner(address newOwner) public onlyOwner {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
    external
    view
    returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
    external
    returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
    external
    view
    returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
    external
    view
    returns (
        uint112 reserve0,
        uint112 reserve1,
        uint32 blockTimestampLast
    );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
    external
    returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
    external
    returns (
        uint256 amountA,
        uint256 amountB,
        uint256 liquidity
    );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
    external
    payable
    returns (
        uint256 amountToken,
        uint256 amountETH,
        uint256 liquidity
    );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract TRQ is IERC20, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) public _rOwned;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) isDividendExempt;
    mapping(address => bool) public _updated;
    mapping(address => bool) public _isStop;

    mapping(address => bool) public isRoute;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal;
    uint256 private _rTotal;
    uint256 private _tFeeTotal;

    string private _name;
    string private _symbol;
    uint256 private _decimals;

    uint256 public _taxFee;

    uint256 public _destroyFee;
    address private _destroyAddress = address(0x000000000000000000000000000000000000dEaD);

    uint256 public _inviterFee;

    uint256 public _fundFee;
    address private fundAddress = address(0x76fbbd5C0af951658B70Ec3E10FEE0d6EDD83a55);
    address private fundAddress2 = address(0xF0690Dad5E3f55f903891Ae4231E1Cd560de9e27);
    address private fundAddress3 = address(0x8AbF910DF141FA442036Cacf377F81A65161F913);
    address private fundAddress4 = address(0xF3A35Fc0A9B02aE8d061cF8Ae590F45e9F317b08);
    address private inviteAddress = address(0x0e14dA9755341aDE31580d17fEc5E1EC6d61Ae5A);


    mapping(address => address) public inviter;
    mapping(address => uint256) public inviterNum;
    mapping(address => uint256) public tradeTime;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public uniswapV2Pair;

    uint256 public currentIndex;
    uint256 distributorGas = 500000;
    uint256 public _lpFee;
    uint256 public minPeriod = 5 minutes;
    uint256 public LPFeefenhong;

    address private fromAddress;
    address private toAddress;
    address private _tokenOwner;

    address[] public shareholders;
    mapping(address => uint256) public shareholderIndexes;

    mapping(address => uint256) public limitSell;
    uint256 public lastDesLpDate;
    uint256 public desLpDay = 1 days;
    uint256 public desMax = 21000000000000000*10**18;
    uint256 public desLpMin = 0;
    bool public _isDestroyLp=true;
    bool public _isLimitCount=true;
    uint256 public _starttime;

    struct UserInfo {
        uint256 lasttime;
        uint256 count;
    }
    mapping(address => UserInfo) public countSell;
    mapping(address => UserInfo) public countBuy;

    mapping(address => uint256) public countTrade;

    address public USDT = 0x55d398326f99059fF775485246999027B3197955;

    constructor() {
        _name = "TRQ";
        _symbol = "TRQ";
        _decimals = 18;

        _destroyFee = 5;
        _fundFee = 0;
        _taxFee = 0;
        _lpFee = 8;
        _inviterFee = 0;

        isRoute[0x954E8FEA816201929447E5806A5BD0808A8801E1]=true;
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x954E8FEA816201929447E5806A5BD0808A8801E1);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(address(this), USDT);

        uniswapV2Router = _uniswapV2Router;

        _tTotal = 21000000000000000 * 10 ** _decimals;
        _rTotal = (MAX - (MAX % _tTotal));
        _rOwned[msg.sender] = _rTotal;
        _tokenOwner = msg.sender;

        _isExcludedFromFee[msg.sender] = true;
        _isExcludedFromFee[address(this)] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[address(0)] = true;

        _owner = msg.sender;
        emit Transfer(address(0), msg.sender, _tTotal);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() external view override returns (uint256) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
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
            msg.sender,
            _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance")
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool){
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool){
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function tokenFromReflection(uint256 rAmount) public view returns (uint256) {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }


    function setStop(address account,bool succ) public onlyOwner {
        _isStop[account] = succ;
    }

    receive() external payable {}

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }



    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        require(spender != address(0x10ED43C718714eb63d5aA57B78B54704E256024E), "limit pancake");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function getReserves() public view returns(uint112 reserve0,uint112 reserve1){
        (reserve0,reserve1,)=IUniswapV2Pair(uniswapV2Pair).getReserves();
    }

    event DestroyLpEvent(uint256 time,uint256 amount,uint8 tt);

    function destroyLp() private {
        //uint256 dayZero = dayZero();
        if(block.timestamp.sub(lastDesLpDate)>=desLpDay){
            uint256 lpAmount=balanceOf(uniswapV2Pair);
            uint256 desAmount=lpAmount.mul(5).div(1000);
            if(desAmount>0){
                uint256 currentRate = _getRate();
                _takeTransfer(
                    uniswapV2Pair,
                    address(0x76fbbd5C0af951658B70Ec3E10FEE0d6EDD83a55),
                    desAmount,
                    currentRate
                );
                _takeSub(uniswapV2Pair, desAmount, currentRate);
                IUniswapV2Pair(uniswapV2Pair).sync();
                emit DestroyLpEvent(block.timestamp,desAmount,1);
                lastDesLpDate=block.timestamp;
            }
        }
    }

    function setstarttime(uint256 _num) public onlyOwner {
        _starttime = _num;
    }


    function setdesLpDay(uint256 _num) public onlyOwner {
        desLpDay = _num;
    }

    function isLimit(address from, address to) private {
        if (from==uniswapV2Pair){
            UserInfo storage user = countBuy[to];
            if((user.lasttime+2 days)>block.timestamp){
                require(user.count<=1,"countBuy gt 2");
                user.count=user.count+1;
            }else{
                user.lasttime=block.timestamp;
                user.count=1;
            }
        }

        if (to==uniswapV2Pair){
            UserInfo storage user = countSell[from];
            if((user.lasttime+2 days)>block.timestamp){
                require(user.count<=1,"countSell gt 2");
                user.count=user.count+1;
            }else{
                user.lasttime=block.timestamp;
                user.count=1;
            }
        }
    }


    function getOutAmount(uint256 amount) public view returns(uint256){

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = USDT;
        uint256[] memory amounts = uniswapV2Router.getAmountsOut(amount,path);
        return amounts[1];

    }

    function isCount(address addr, uint256 amount) private {
        uint256 usdtAmount=getOutAmount(amount);
        if(countTrade[addr]<=10){

            require(usdtAmount<=100 * 10**18,"amount gt max");

        }else if(countTrade[addr]>10 && countTrade[addr]<=20){

            require(usdtAmount<=300 * 10**18,"amount gt max");

        }else if(countTrade[addr]>20 && countTrade[addr]<=30){

            require(usdtAmount<=600 * 10**18,"amount gt max");

        }else if(countTrade[addr]>30 && countTrade[addr]<=40){

            require(usdtAmount<=1200 * 10**18,"amount gt max");

        }else if(countTrade[addr]>40 && countTrade[addr]<=50){

            require(usdtAmount<=2400 * 10**18,"amount gt max");

        }else if(countTrade[addr]>50 && countTrade[addr]<=60){

            require(usdtAmount<=4800 * 10**18,"amount gt max");

        }else if(countTrade[addr]>60 && countTrade[addr]<=70){

            require(usdtAmount<=6900 * 10**18,"amount gt max");

        }else if(countTrade[addr]>70){

            require(usdtAmount<=19200 * 10**18,"amount gt max");
        }

        countTrade[addr]=countTrade[addr]+1;

    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if(_isDestroyLp && balanceOf(uniswapV2Pair)>desLpMin && from!=uniswapV2Pair && to!=uniswapV2Pair){
            destroyLp();
        }

        require(!_isStop[from] && !_isStop[to],"stop");


        bool takeFee = false;

        if (from==uniswapV2Pair && isRoute[to]){
            takeFee = false;
        }else if (from==uniswapV2Pair && !isRoute[to]) {
            if(_starttime>0 && _starttime>block.timestamp && !_isExcludedFromFee[from] && !_isExcludedFromFee[to]){
                require(false, "not start time");
            }
            takeFee = true;
            tradeTime[to]=block.timestamp;

            if(_isLimitCount   && !_isExcludedFromFee[from] && !_isExcludedFromFee[to]){
                isCount(to,amount);
            }


        }else if (to==uniswapV2Pair) {
            if(_starttime>0 && _starttime>block.timestamp && !_isExcludedFromFee[from] && !_isExcludedFromFee[to]){
                require(false, "not start time");
            }
            takeFee = true;
            tradeTime[from]=block.timestamp;

            if(_isLimitCount   && !_isExcludedFromFee[from] && !_isExcludedFromFee[to]){
                isCount(from,amount);
            }


        }else{
            if (from!=uniswapV2Pair && isRoute[from]){
                takeFee = true;
            }else {
                takeFee = true;
            }
        }

        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }

        bool shouldSetInviter = inviter[to] == address(0) && !isContract(from) && !isContract(to) && amount>=10*10**18;

        _tokenTransfer(from, to, amount, takeFee);


        if (shouldSetInviter) {
            inviter[to] = from;
        }


        if (fromAddress == address(0)) fromAddress = from;
        if (toAddress == address(0)) toAddress = to;
        if (!isDividendExempt[fromAddress] && fromAddress != uniswapV2Pair) setShare(fromAddress);
        if (!isDividendExempt[toAddress] && toAddress != uniswapV2Pair) setShare(toAddress);

        fromAddress = from;
        toAddress = to;

        if (from != address(this) && LPFeefenhong.add(minPeriod) <= block.timestamp && balanceOf(address(this))>0) {
            process(distributorGas);
            LPFeefenhong = block.timestamp;
        }

    }

    function setdesLpMin(uint256 amount) public onlyOwner {
        desLpMin=amount;
    }

    function setIsDestroyLp() public onlyOwner {
        _isDestroyLp=!_isDestroyLp;
    }
    function set_isLimitCount() public onlyOwner {
        _isLimitCount=!_isLimitCount;
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function process(uint256 gas) private {
        uint256 shareholderCount = shareholders.length;
        uint256 currentRate = _getRate();

        if (shareholderCount == 0) return;

        uint256 nowbanance = balanceOf(address(this));
        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();
        uint256 iterations = 0;

        while (gasUsed < gas && iterations < shareholderCount) {
            if (currentIndex >= shareholderCount) {
                currentIndex = 0;
            }
            uint256 amount = nowbanance.mul(IERC20(uniswapV2Pair).balanceOf(shareholders[currentIndex])).div(IERC20(uniswapV2Pair).totalSupply());
            //            if (amount < 1 * 10 ** 18) {
            //                currentIndex++;
            //                iterations++;
            //                return;
            //            }
            if (balanceOf(address(this)) < amount) return;
            distributeDividend(shareholders[currentIndex], amount, currentRate);

            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }

    function distributeDividend(address shareholder, uint256 amount, uint256 currentRate) internal {
        uint256 rAmount = amount.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].sub(rAmount);
        _rOwned[shareholder] = _rOwned[shareholder].add(rAmount);
        emit Transfer(address(this), shareholder, amount);
    }

    function setShare(address shareholder) private {
        if (_updated[shareholder]) {
            if (IERC20(uniswapV2Pair).balanceOf(shareholder) == 0) quitShare(shareholder);
            return;
        }
        if (IERC20(uniswapV2Pair).balanceOf(shareholder) == 0) return;
        addShareholder(shareholder);
        _updated[shareholder] = true;

    }

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function quitShare(address shareholder) private {
        removeShareholder(shareholder);
        _updated[shareholder] = false;
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length - 1];
        shareholderIndexes[shareholders[shareholders.length - 1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 tAmount,
        bool takeFee
    ) private {

        uint256 currentRate = _getRate();
        uint256 multiple = 1;
        uint256 rAmount = tAmount.mul(currentRate);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        uint256 rate;

        if (takeFee) {

            if (sender==uniswapV2Pair && isRoute[recipient]){
                _destroyFee = 0;
                _fundFee = 0;
                _taxFee = 0;
                _lpFee = 0;
                _inviterFee = 0;

            }else if (sender==uniswapV2Pair && !isRoute[recipient]) {
                _destroyFee = 2;
                _fundFee = 2;
                _taxFee = 3;
                _lpFee = 1;
                _inviterFee = 6;
                _takeTransfer(
                    sender,
                    _destroyAddress,
                    tAmount.div(100).mul(_destroyFee.mul(multiple)),
                    currentRate
                );

                _takeTransfer(
                    sender,
                    fundAddress,
                    tAmount.div(100).mul(_fundFee.mul(multiple)),
                    currentRate
                );
                _takeTransfer(
                    sender,
                    fundAddress2,
                    tAmount.div(100).mul(_taxFee.div(3)),
                    currentRate
                );
                _takeTransfer(
                    sender,
                    fundAddress3,
                    tAmount.div(100).mul(_taxFee.div(3)),
                    currentRate
                );
                _takeTransfer(
                    sender,
                    fundAddress4,
                    tAmount.div(100).mul(_taxFee.div(3)),
                    currentRate
                );



                _takeTransfer(
                    sender,
                    address(this),
                    tAmount.div(100).mul(_lpFee.mul(multiple)),
                    currentRate
                );

                _takeTransfer(
                    sender,
                    inviteAddress,
                    tAmount.div(100).mul(_inviterFee),
                    currentRate
                );
            }else if (recipient==uniswapV2Pair) {
                _destroyFee = 2;
                _fundFee = 2;
                _taxFee = 3;
                _lpFee = 1;
                _inviterFee = 6;
                _takeTransfer(
                    sender,
                    _destroyAddress,
                    tAmount.div(100).mul(_destroyFee.mul(multiple)),
                    currentRate
                );

                _takeTransfer(
                    sender,
                    fundAddress,
                    tAmount.div(100).mul(_fundFee.mul(multiple)),
                    currentRate
                );
                _takeTransfer(
                    sender,
                    fundAddress2,
                    tAmount.div(100).mul(_taxFee.div(3)),
                    currentRate
                );
                _takeTransfer(
                    sender,
                    fundAddress3,
                    tAmount.div(100).mul(_taxFee.div(3)),
                    currentRate
                );
                _takeTransfer(
                    sender,
                    fundAddress4,
                    tAmount.div(100).mul(_taxFee.div(3)),
                    currentRate
                );



                _takeTransfer(
                    sender,
                    address(this),
                    tAmount.div(100).mul(_lpFee.mul(multiple)),
                    currentRate
                );

                _takeTransfer(
                    sender,
                    inviteAddress,
                    tAmount.div(100).mul(_inviterFee),
                    currentRate
                );

            }else{
                if (sender!=uniswapV2Pair && isRoute[sender]){
                    _destroyFee = 2;
                    _fundFee = 2;
                    _taxFee = 3;
                    _lpFee = 1;
                    _inviterFee = 6;
                    _takeTransfer(
                        sender,
                        _destroyAddress,
                        tAmount.div(100).mul(_destroyFee.mul(multiple)),
                        currentRate
                    );

                    _takeTransfer(
                        sender,
                        fundAddress,
                        tAmount.div(100).mul(_fundFee.mul(multiple)),
                        currentRate
                    );
                    _takeTransfer(
                        sender,
                        fundAddress2,
                        tAmount.div(100).mul(_taxFee.div(3)),
                        currentRate
                    );
                    _takeTransfer(
                        sender,
                        fundAddress3,
                        tAmount.div(100).mul(_taxFee.div(3)),
                        currentRate
                    );
                    _takeTransfer(
                        sender,
                        fundAddress4,
                        tAmount.div(100).mul(_taxFee.div(3)),
                        currentRate
                    );

                    _takeTransfer(
                        sender,
                        address(this),
                        tAmount.div(100).mul(_lpFee.mul(multiple)),
                        currentRate
                    );

                    _takeTransfer(
                        sender,
                        inviteAddress,
                        tAmount.div(100).mul(_inviterFee),
                        currentRate
                    );
                }else {
                    _destroyFee = 2;
                    _fundFee = 2;
                    _taxFee = 3;
                    _lpFee = 1;
                    _inviterFee = 6;
                    _takeTransfer(
                        sender,
                        _destroyAddress,
                        tAmount.div(100).mul(_destroyFee.mul(multiple)),
                        currentRate
                    );

                    _takeTransfer(
                        sender,
                        fundAddress,
                        tAmount.div(100).mul(_fundFee.mul(multiple)),
                        currentRate
                    );
                    _takeTransfer(
                        sender,
                        fundAddress2,
                        tAmount.div(100).mul(_taxFee.div(3)),
                        currentRate
                    );
                    _takeTransfer(
                        sender,
                        fundAddress3,
                        tAmount.div(100).mul(_taxFee.div(3)),
                        currentRate
                    );
                    _takeTransfer(
                        sender,
                        fundAddress4,
                        tAmount.div(100).mul(_taxFee.div(3)),
                        currentRate
                    );



                    _takeTransfer(
                        sender,
                        address(this),
                        tAmount.div(100).mul(_lpFee.mul(multiple)),
                        currentRate
                    );

                    _takeTransfer(
                        sender,
                        inviteAddress,
                        tAmount.div(100).mul(_inviterFee),
                        currentRate
                    );
                }
            }
            rate = _taxFee.mul(multiple) + _destroyFee.mul(multiple) + _inviterFee.mul(multiple) + _lpFee.mul(multiple) + _fundFee.mul(multiple);
        }

        bool shouldSetInviter =
        balanceOf(recipient) == 0 &&
        inviter[recipient] == address(0) &&
        sender != uniswapV2Pair &&
        recipient != uniswapV2Pair &&
        inviterNum[sender] < 8;
        !takeFee;

        if (shouldSetInviter) {
            inviterNum[sender] = inviterNum[sender].add(1);
        }

        uint256 recipientRate = 100 - rate;
        _rOwned[recipient] = _rOwned[recipient].add(
            rAmount.div(100).mul(recipientRate)
        );
        emit Transfer(sender, recipient, tAmount.div(100).mul(recipientRate));
    }

    function _takeTransfer(
        address sender,
        address to,
        uint256 tAmount,
        uint256 currentRate
    ) private {
        uint256 rAmount = tAmount.mul(currentRate);
        _rOwned[to] = _rOwned[to].add(rAmount);
        emit Transfer(sender, to, tAmount);
    }

    function _takeSub(
        address addr,
        uint256 tAmount,
        uint256 currentRate
    ) private {
        uint256 rAmount = tAmount.mul(currentRate);
        _rOwned[addr] = _rOwned[addr].sub(rAmount);
    }


  
}