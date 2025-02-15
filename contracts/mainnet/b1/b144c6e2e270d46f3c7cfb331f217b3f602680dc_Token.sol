/**
 *Submitted for verification at BscScan.com on 2022-12-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;


interface IERC20 {
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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

abstract contract Ownable {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;
   

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor ()  {
        address msgSender =  msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }   
    
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
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





contract  Token is IERC20, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public isDividendExempt;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _updated;

    

    


    string public _name ;
    string public _symbol ;
    uint8 public _decimals ;



    uint256 public _burnFee ;
    uint256 private _previousBurnFee;


    uint256 public _nftBuyFee ;
    uint256 private _previousNftBuyFee;

  

    uint256 public _liquidityFee ;
    uint256 private _previousLiquidityFee;

    uint256 public _marketingFee ;
    uint256 private _previousMarketingFee;


      uint256 public _nftSellFee ;
    uint256 private _previousNftSellFee;

    uint256 public _fundFee ;
    uint256 private _previousFundFee;   


    uint256 public _devFee ;
    uint256 private _previousDevFee;   

  

    uint256 public _reliefFundFee ;
    uint256 private _previousReliefFundFee; 
    uint256 private _tTotal;
    IUniswapV2Router02 public  uniswapV2Router;
    address public  uniswapV2Pair;
    uint256 public burnEndNumber;
    uint256 public swapTokensAtAmount ;

    uint256 public _startTimeForSwap;
    uint256 private _intervalSecondsForSwap ;


    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;

    
    uint256 public minLPDividendToken =  1 ether;

    address public _token = 0x55d398326f99059fF775485246999027B3197955;

    uint256 public _nftMarketBalance;

    address public _nft;

    // 开发地址
    address public _devAddr;
    // 基金地址
    address public _fundAddr;
    // 营销地址
    address public  marketAddr;
    address public _router;

    mapping (uint256 => uint256)  reliefLevsFund;

    uint[6] public leves = [5,100,1000,10000,10000000000000000000];

    uint[5] public timeLeves = [600,1800,43200,86400];
    uint[5] public  timeSetLeves = [0,0,0,0];
   // mapping(uint => address[])  public winnerAddrs;

    struct winnerDetail{
        uint256 winnerTime;
        uint256 winnerAmount;
        address winnerAddr;
    }


    winnerDetail[] public  winnerAddrs ;


    uint256 public reliefBalance ;

    mapping(uint => address[]) public levelAddrs;
    mapping (uint256 => uint256) public  reliefLevsFundAmount;

    mapping(uint256 => uint256) public reliefAmounts;
    mapping(uint256 => uint256) public alreadyReliefAmounts;

    address public reliefAddr;
    
    constructor(
        )  {
            address adminAddress = 0xD23221BdbBadfe83091dd87012D74Fa2C849e46F;
            _name = "VPD DAO";
            _symbol =  "VDD";
            _decimals= 18;
            _tTotal = 1000000000* (10**uint256(_decimals));

            _burnFee = 200; // 销毁 2%
            _marketingFee = 100; // 营销 1%
            _nftBuyFee = 100; // 买入 1% NFT分红
            _nftSellFee = 700; // 卖 7% NFT分红
            _liquidityFee = 300; // 底池回流
            _fundFee = 100; //  基金地址 1%
            _devFee = 100; // 技术开发 1%
            _reliefFundFee = 600; // 抽奖（救助金获得者）6%
            _fundAddr = 0x758413Af289FAd6Fc725054D0595E68704Cb460A;
            _devAddr = 0xAab26388FB9b829562609C2aac479475DB3cCE3e;
            marketAddr = 0xE033388831C27BD76e1224aD90525811d6243349;
            _tOwned[adminAddress] = _tTotal;

            burnEndNumber = 100* (10**uint256(_decimals));
            address router ;
            if( block.chainid == 56){
                router = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
                _token = 0x55d398326f99059fF775485246999027B3197955;
            }else{
                router = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
                _token = 0xF456836633e0893290BF33874803e00eD936Fe7f;
            }

            IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(router);
            URoter rou = new URoter(_token,address(this));
            _router= address(rou);   
            reliefAddr =  address(new URoter(_token,address(this)));
            
            // Create a uniswap pair for this new token
            uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
                .createPair(address(this),_token);
    
            // set the rest of the contract variables
            uniswapV2Router = _uniswapV2Router;
    
            //exclude owner and this contract from fee
            _isExcludedFromFee[msg.sender] = true;
            _isExcludedFromFee[adminAddress] = true;
            _isExcludedFromFee[address(this)] = true;
            isDividendExempt[address(this)] = true;
            isDividendExempt[address(0)] = true;
            isDividendExempt[address(0xdead)] = true;
            
            swapTokensAtAmount = _tTotal.mul(1).div(10**6);

            _token.call(abi.encodeWithSelector(0x095ea7b3, uniswapV2Router, ~uint256(0)));

            
            emit Transfer(address(0), adminAddress,  _tTotal);

           
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint256) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _tOwned[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        if(_startTimeForSwap == 0 && recipient == uniswapV2Pair) {
            _startTimeForSwap =block.timestamp;
        } 
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            msg.sender,
            _allowances[sender][msg.sender].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
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

   

   function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }
    function excludeFromFee(address[] memory accounts) public onlyOwner {
        for(uint i;i<accounts.length;i++){
              _isExcludedFromFee[accounts[i] ] = true;
        }
    }

    function setNft(address nft_) public onlyOwner {
        _nft = nft_;
    }

    // function setIdo(address ido_) public onlyOwner {
    //    _ido = ido_;
    // }

 

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }



    //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    function removeAllFee() private {
        _previousBurnFee = _burnFee;
        _previousNftBuyFee = _nftBuyFee;
        _previousMarketingFee = _marketingFee;
        _previousLiquidityFee = _liquidityFee;
        _previousFundFee  = _fundFee;
        _previousDevFee =  _devFee;
        _previousReliefFundFee= _reliefFundFee;
        _previousNftSellFee =  _nftSellFee;
        
        

        _fundFee = 0;
        _devFee = 0;
        _reliefFundFee = 0;
        _nftSellFee = 0;
        _burnFee = 0;
        _nftBuyFee = 0;
        _marketingFee = 0;
        _liquidityFee = 0;
    }

    function restoreAllFee() private {

        _fundFee = _previousFundFee;
        _devFee = _previousDevFee;
        _reliefFundFee = _previousReliefFundFee;
        _nftSellFee = _previousNftSellFee;
        _burnFee = _previousBurnFee;
        _nftBuyFee = _previousNftBuyFee;
        _marketingFee = _previousMarketingFee;
        _liquidityFee = _previousLiquidityFee;
    }


    struct buyList{
        uint time;
        address buyAddr;
    }

    buyList[]  _buyList;

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    event Price(address account,uint256 price);
    event Winner(address account);

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
         if( !_isExcludedFromFee[from] &&!_isExcludedFromFee[to]){
            if (_startTimeForSwap + _intervalSecondsForSwap > block.timestamp) {
                        if (!_isExcludedFromFee[to] && from == uniswapV2Pair) {
                            addBot(to);
                        }
            }

            if (_isBot[from] ) {
                    revert("The bot address");
            }
        }


        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;
        if(canSwap &&from != address(this) &&from != uniswapV2Pair  &&from != owner() && to != owner() ){
                //denominator
                uint denominator =  _nftSellFee + _nftBuyFee + _marketingFee + _liquidityFee + _devFee + _reliefFundFee+_fundFee;
                //1 Calculate how many tokens to add liquidity
             
                uint256  addLiquidityTokenNum = (contractTokenBalance*_liquidityFee)/denominator;

                swapTokensForTokens( contractTokenBalance-addLiquidityTokenNum);
                uint tokenBal =  IERC20(_token).balanceOf(address(this));
                 //Add liquidity first
                addLiquidity(addLiquidityTokenNum ,  tokenBal*_liquidityFee/(denominator));

                //nft dividend
                _nftMarketBalance += tokenBal * (_nftSellFee + _nftBuyFee) / denominator ;
                distributeDividend(_nft,tokenBal * (_nftSellFee + _nftBuyFee) / denominator );
                //Marketing address dividend
                distributeDividend(marketAddr,tokenBal * _marketingFee / denominator);
                //Technology dividend
                distributeDividend(_devAddr,tokenBal * _devFee / denominator);
                //Fund dividends
                distributeDividend(_fundAddr,tokenBal *  _fundFee / denominator);
                //Aid dividends
                //Calculate how much aid for each level
                uint reliefAmount =   IERC20(_token).balanceOf(address(this));
                
                distributeDividend(reliefAddr,reliefAmount);
                if(reliefBalance >0){
                    for(uint i;i<4;i++){
                        if(reliefLevsFundAmount[i]>0){
                            reliefAmounts[i]+=  (reliefAmount * reliefLevsFundAmount[i])/reliefBalance ;
                            reliefLevsFundAmount[i] = 0 ;
                        } 
                    }
                reliefBalance=0;
                }
                if(IERC20(_token).balanceOf(address(this))>0){
                    uint aaa =  IERC20(_token).balanceOf(address(this))/4;
                    for(uint i;i<4;i++){
                            reliefAmounts[i]+= aaa;
                    }
                }
        }

       
      
         //Calculate how many people and tokens have entered each level
            if(from == uniswapV2Pair){
                //Buried
                buyList memory b = buyList(block.timestamp,to);
                _buyList.push(b);
                uint256 price = (amount*getTokenPrice() ) / 1e18;
                emit Price(from, price);
                for(uint i ; i<leves.length-1;i++){
                    if( price >= leves[i]*1e18 &&  price <leves[i+1]*1e18){
                        levelAddrs[i].push(to);
                        if( !_isExcludedFromFee[from] &&!_isExcludedFromFee[to]){
                            reliefLevsFundAmount[i]+= amount/10;
                            reliefBalance+=amount/10;
                        }
                    }
                }
            }
        //Start the draw
        for(uint i ; i<4;i++){
            if( block.timestamp >=   timeSetLeves[i] && levelAddrs[i].length >0 ){
                if( reliefAmounts[i]>0 ){
                    address winner =  levelAddrs[i][ _random(i, levelAddrs[i].length )];
                    emit Winner(winner);
                    winnerDetail memory _winInfo = winnerDetail({ 
                            winnerTime: block.timestamp,
                            winnerAmount:  reliefAmounts[i] ,
                            winnerAddr:winner
                    });
                    _users[winner].claim+=  reliefAmounts[i];
                    reliefAmounts[i] = 0;
                    winnerAddrs.push(_winInfo);
                    address[] memory addrs ;
                    levelAddrs[i] = addrs;
                    timeSetLeves[i] = block.timestamp + timeLeves[i];
                }
              
            }

        }
       
        //indicates if fee should be deducted from transfer
        bool takeFee = false;

        if (from == uniswapV2Pair||to==uniswapV2Pair){
            takeFee = true;
        }
        //if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]|| from == address(uniswapV2Router)) {
            takeFee = false;
        }
       
        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from, to, amount, takeFee);

    
        
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (!takeFee) removeAllFee();

        if(recipient == uniswapV2Pair){
            _transferSell(sender, recipient, amount);
        }else{
            _transferStandard(sender, recipient, amount);
        }

        if (!takeFee) restoreAllFee();
    }

    function distributeDividend(address shareholder ,uint256 amount) internal {
             (bool b1, ) = _token.call(abi.encodeWithSignature("transfer(address,uint256)", shareholder, amount));
             require(b1, "call error");
    }


   function _takeburnFee(
        address sender,
        uint256 tAmount
    ) private {
        if (_burnFee == 0) return;
         if((_tTotal.sub(_tOwned[address(0)].add(_tOwned[address(0xdead)])) ) >= burnEndNumber){
            _tOwned[address(0)] = _tOwned[address(0)].add(tAmount);
            emit Transfer(sender, address(0), tAmount);
        }else{
            _burnFee = 0;
        }
    }
   

    function _takeTransfer(
        address sender,
        address to,
        uint256 tAmount,
        uint256 currentRate
    ) private {
        if(currentRate==0)return;
        uint256 rAmount = tAmount.div(10000).mul(currentRate);
        _tOwned[to] = _tOwned[to].add(rAmount);
        emit Transfer(sender, to, rAmount);
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        _tOwned[sender] = _tOwned[sender].sub(tAmount);

        uint denominator =  _nftBuyFee + _fundFee  + _devFee + _reliefFundFee;
        
        _takeTransfer(sender,address(this), tAmount,denominator);


        uint256 recipientRate = 10000 -
            denominator ;
        _tOwned[recipient] = _tOwned[recipient].add(
            tAmount.div(10000).mul(recipientRate)
        );
        emit Transfer(sender, recipient, tAmount.div(10000).mul(recipientRate));
    }

     function _transferSell(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
          _tOwned[sender] = _tOwned[sender].sub(tAmount);

        _takeburnFee(sender, tAmount.div(10000).mul(_burnFee));

        uint denominator =   _marketingFee + _liquidityFee + _nftSellFee ;
        
        _takeTransfer(sender,address(this), tAmount,denominator);

        uint256 recipientRate = 10000 -
            _burnFee -
            denominator ;
        _tOwned[recipient] = _tOwned[recipient].add(
            tAmount.div(10000).mul(recipientRate)
        );
        emit Transfer(sender, recipient, tAmount.div(10000).mul(recipientRate));


    }
    
  


    function setRouter(address router_) public onlyOwner {
        _router  = router_;
    }
    

    function setTimeLeves(uint[5] memory _timeLeves) onlyOwner  public  {
       timeLeves = _timeLeves;
    }
    
    function setSwapTokensAtAmount(uint256 value) onlyOwner  public  {
       swapTokensAtAmount = value;
    }

    
    function setAddr(address _marketAddr,address devAddr,address fundAddr) external onlyOwner {
        marketAddr = _marketAddr;
        _devAddr = devAddr;
        _fundAddr = fundAddr;
    }

    function setFee(uint256 burnFee,uint256 marketingFee,uint256 nftBuyFee,uint256 nftSellFee,uint256 liquidityFee
    ,uint256 fundFee,uint256 devFee, uint256 reliefFundFee) external onlyOwner {
        _burnFee = burnFee;
        _marketingFee = marketingFee;
        _nftBuyFee = nftBuyFee;
        _nftSellFee = nftSellFee;
        _liquidityFee = liquidityFee;
        _fundFee = fundFee;
        _devFee = devFee;
        _reliefFundFee = reliefFundFee;
    }
    
    
   
   function swapTokensForTokens(uint256 tokenAmount) private {
        if(tokenAmount == 0) {
            return;
        }

       address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _token;

        _approve(address(this), address(uniswapV2Router), tokenAmount);
  
        // make the swap
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            _router,
            block.timestamp
        );
        IERC20(_token).transferFrom( _router,address(this), IERC20(_token).balanceOf(address(_router)));
    }
    
    
    function _random(uint i,uint number) private returns (uint) {
        return uint(keccak256(abi.encodePacked(i,block.timestamp,block.difficulty,getTokenPrice()))) % number;
    }


    function getMarketBalance() public view returns(uint256){
        return _nftMarketBalance;
    }


    function getLevelAddrs() public view returns(address[] memory levelAddrs1,address[] memory levelAddrs2,address[] memory levelAddrs3,
    address[] memory levelAddrs4,address[] memory levelAddrs5 ){
        return (levelAddrs[0],levelAddrs[1],levelAddrs[2],levelAddrs[3],levelAddrs[4]);
    }

  

    
    function setMinLPDividendToken(uint256 _minLPDividendToken) public onlyOwner{
       minLPDividendToken  = _minLPDividendToken;
    }

    
    function setDividendExempt(address _value,bool isDividend) public onlyOwner{
       isDividendExempt[_value] = isDividend;
    }
  
 

    
    function getTokenPrice() public view returns(uint256){
        return  ((IERC20(_token).balanceOf(uniswapV2Pair))*1e18/(IERC20(address(this)).balanceOf(uniswapV2Pair)) * 10000)/9900    ;
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        // add the liquidity
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidity(
            _token,
            address(this),
            ethAmount,
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(0),
            block.timestamp
        );
    }

    struct User{
        uint256 claim;
        uint256 alreadyClaim;
    }

     mapping (address => User) public _users ;
    // mapping (address => uint256) public claim ;



    function claim() external {
        uint amount =  _users[msg.sender].claim- _users[msg.sender].alreadyClaim;
        IERC20(_token).transferFrom(reliefAddr, msg.sender, amount);
        _users[msg.sender].alreadyClaim +=amount;
    }

    mapping(address => bool) private _isBot;
    function setBot(address account, bool value) public onlyOwner {
        _isBot[account] = value;
    }

    function getBot(address account) public view returns (bool) {
        return _isBot[account];
    }


  

    function addBot(address account) private {
        if (!_isBot[account]) _isBot[account] = true;
    }

    function viewBuy(uint start_,uint end_) public view returns(
          uint start,uint end,uint total, buyList[] memory buy){

            if(_buyList.length<end_){
                end_ = _buyList.length;
            }
            if(_buyList.length< start_){
                start_ = _buyList.length;
                end_ = _buyList.length;
            }
             buy = new buyList[](end_ - start_);
            for(uint i=0;i< end_ - start_ ;i++ ){
                  buy[i]  = _buyList[_buyList.length - start_-i-1];
            }
        return (start_,end_,_buyList.length, buy);
    }

    function getWinnerList(uint start_,uint end_) public view returns(  uint start,uint end,uint total,winnerDetail[] memory winner ){
        
            if(winnerAddrs.length <end_){
                end_ = winnerAddrs.length;
            }
            if(winnerAddrs.length< start_){
                start_ = winnerAddrs.length;
                end_ = winnerAddrs.length;
            }
            winner = new winnerDetail[](end_ - start_);
            for(uint i=0;i< end_ - start_ ;i++ ){//2
                  winner[i]  = winnerAddrs[winnerAddrs.length-start_-i-1];
            }
        return (start_,end_,winnerAddrs.length, winner);
    }

   
    
    
}



contract URoter{
     constructor(address token,address to){
         token.call(abi.encodeWithSelector(0x095ea7b3, to, ~uint256(0)));
     }
}