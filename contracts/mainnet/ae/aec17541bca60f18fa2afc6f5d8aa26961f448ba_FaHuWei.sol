// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

import "./DividendPayingToken.sol";
import "./SafeMath.sol";
import "./IterableMapping.sol";
import "./Ownable.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router.sol";
import "./IERC20.sol";

contract FaHuWei is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;
    address public immutable uniswapV2Pair;

    IERC20 WBNB = IERC20(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);

    bool private swapping;
    bool private luckAndDividend = true;

    FaHuWeiDividendTracker public dividendTracker;

    uint256 public swapTokensAtAmount = 200 * (10**18);
    uint256 public luckTokensAtAmount = 10**17;
    uint256 public minLuckHold = 50 * (10**18);
    uint256 private maxSupply = 100000 * (10**18);

    uint256 public _maxWalletTokenPerThousand = 100;
    uint256 public _maxWalletToken = maxSupply.mul(_maxWalletTokenPerThousand).div(1000);

    uint256 public _fees = 11;
    uint256 public _buyFees = 10;

    uint256 public _BNBReward = 60;
    uint256 public _project = 30;
    uint256 public _liquidity = 10;

    address payable public  _projectAddress = 0xa91a285b88bd2D6027c8091944264229d1782add;
    address payable public liquidityWallet = 0xF8ebb38e694DE3591E70E004c4e68a7CcF878CFd;

    // use by default 300,000 gas to process auto-claiming dividends
    uint256 public gasForProcessing = 300000;

    // exlcude from fees and max transaction amount
    mapping (address => bool) private _isExcludedFromFees;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;

    struct LuckRecord {
        address addr;
        uint256 amount;
    }

    mapping(uint256 => LuckRecord) public luckRecord;
    uint256 public nextLuckId;

    event UpdateDividendTracker(address indexed newAddress, address indexed oldAddress);
    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
    event FixedSaleEarlyParticipantsAdded(address[] participants);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event LiquidityWalletUpdated(address indexed newLiquidityWallet, address indexed oldLiquidityWallet);
    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event FixedSaleBuy(address indexed account, uint256 indexed amount, bool indexed earlyParticipant, uint256 numberOfBuyers);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    event SendDividends(
        uint256 tokensSwapped,
        uint256 amount
    );

    event SendLuck(
        address luckAddress,
        uint256 amount
    );

    event ProcessedDividendTracker(
        uint256 iterations,
        uint256 claims,
        uint256 lastProcessedIndex,
        bool indexed automatic,
        uint256 gas,
        address indexed processor
    );

    constructor() public ERC20("cut me", "😂cut me😂") {
        dividendTracker = new FaHuWeiDividendTracker();

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        // exclude from receiving dividends
        dividendTracker.excludeFromDividends(address(dividendTracker));
        dividendTracker.excludeFromDividends(address(this));
        dividendTracker.excludeFromDividends(owner());
        dividendTracker.excludeFromDividends(address(_uniswapV2Router));
        
        // exclude from paying fees or having max transaction amount
        excludeFromFees(liquidityWallet, true);
        excludeFromFees(address(this), true);
        excludeFromFees(owner(), true);

        _mint(owner(), maxSupply);
    }

    receive() external payable {
    }
    
    function updateDividendTracker(address newAddress) public onlyOwner {
        require(newAddress != address(dividendTracker), "FaHuWei: The dividend tracker already has that address");

        FaHuWeiDividendTracker newDividendTracker = FaHuWeiDividendTracker(payable(newAddress));

        require(newDividendTracker.owner() == address(this), "FaHuWei: The new dividend tracker must be owned by the FaHuWei token contract");

        newDividendTracker.excludeFromDividends(address(newDividendTracker));
        newDividendTracker.excludeFromDividends(address(this));
        newDividendTracker.excludeFromDividends(owner());
        newDividendTracker.excludeFromDividends(address(uniswapV2Router));

        emit UpdateDividendTracker(newAddress, address(dividendTracker));

        dividendTracker = newDividendTracker;
    }

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(newAddress != address(uniswapV2Router), "FaHuWei: The router already has that address");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "FaHuWei: Account is already the value of 'excluded'");
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function FaHuWeiExcludeFromDividends(address addr) public onlyOwner {
        dividendTracker.excludeFromDividends(addr);
    }
    
    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }

        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "FaHuWei: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");
        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "FaHuWei: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;

        if(value) {
            dividendTracker.excludeFromDividends(pair);
        }

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateLiquidityWallet(address payable newLiquidityWallet) public onlyOwner {
        require(newLiquidityWallet != liquidityWallet, "FaHuWei: The liquidity wallet is already this address");
        excludeFromFees(newLiquidityWallet, true);
        emit LiquidityWalletUpdated(newLiquidityWallet, liquidityWallet);
        liquidityWallet = newLiquidityWallet;
    }

    function updateGasForProcessing(uint256 newValue) public onlyOwner {
        require(newValue >= 200000 && newValue <= 500000, "FaHuWei: gasForProcessing must be between 200,000 and 500,000");
        require(newValue != gasForProcessing, "FaHuWei: Cannot update gasForProcessing to same value");
        emit GasForProcessingUpdated(newValue, gasForProcessing);
        gasForProcessing = newValue;
    }

    function updateClaimWait(uint256 claimWait) external onlyOwner {
        dividendTracker.updateClaimWait(claimWait);
    }

    function updateL(uint256 l) public onlyOwner {
        luckTokensAtAmount = l;
    }

    function updateS(uint256 s) public onlyOwner {
        swapTokensAtAmount = s;
    }
    
    function updateLUCKHODL(uint256 LUCKHODL) public onlyOwner {
        minLuckHold = LUCKHODL;
    }

    function updateSellFees(uint256 sellFees) public onlyOwner {
        _fees = sellFees;
    }

    function updateBuyFees(uint256 buyFees) public onlyOwner {
        _buyFees = buyFees;
    }

    function updateCAKEReward(uint256 CAKEReward) public onlyOwner {
        _BNBReward = CAKEReward;
    }

    function updateMaxWalletTokenPerThousand(uint256 perThousand) public onlyOwner {
        _maxWalletTokenPerThousand = perThousand;
        _maxWalletToken = maxSupply.mul(_maxWalletTokenPerThousand).div(1000);
    }

    function updateProject(uint256 project) public onlyOwner {
        _project = project;
    }

    function updateLiquidity(uint256 liquidity) public onlyOwner {
        _liquidity = liquidity;
    }

    function setAddress(address payable projectAddress) public onlyOwner {
        _projectAddress = projectAddress;
    }

    function getClaimWait() external view returns(uint256) {
        return dividendTracker.claimWait();
    }

    function getTotalDividendsDistributed() external view returns (uint256) {
        return dividendTracker.totalDividendsDistributed();
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function withdrawableDividendOf(address account) public view returns(uint256) {
        return dividendTracker.withdrawableDividendOf(account);
    }

    function dividendTokenBalanceOf(address account) public view returns (uint256) {
        return dividendTracker.balanceOf(account);
    }

    function getAccountDividendsInfo(address account)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
        return dividendTracker.getAccount(account);
    }

    function getAccountDividendsInfoAtIndex(uint256 index)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
        return dividendTracker.getAccountAtIndex(index);
    }

    function processDividendTracker(uint256 gas) external {
        (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) = dividendTracker.process(gas);
        emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, false, gas, tx.origin);
    }

    function claim() external {
        dividendTracker.processAccount(msg.sender, false);
    }

    function getLastProcessedIndex() external view returns(uint256) {
        return dividendTracker.getLastProcessedIndex();
    }

    function getNumberOfDividendTokenHolders() external view returns(uint256) {
        return dividendTracker.getNumberOfTokenHolders();
    }

    function contractInfo() external view returns(uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        uint256 total = dividendTracker.totalDividendsDistributed();
        return (WBNB.balanceOf(uniswapV2Pair), balanceOf(address(uniswapV2Pair)), msg.sender.balance, balanceOf(msg.sender),  address(this).balance, balanceOf(address(this)),  total);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        
        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if(
            canSwap &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            from != liquidityWallet &&
            to != liquidityWallet
        ) {
            swapping = true;

            uint256 swapTokens = contractTokenBalance.mul(_liquidity).div(100);
            swapAndLiquify(swapTokens);
	    
	    if (luckAndDividend) {
                uint256 sellTokens = balanceOf(address(this));
                swapAndSendDividends(sellTokens);
	    }
	    
            swapping = false;
        }
	
	if (luckAndDividend) {
		sendLuckBonus();
	}

        bool takeFee = !swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        if(takeFee) {
            if (!automatedMarketMakerPairs[to]) {
                uint256 heldTokens = balanceOf(to);
                require((heldTokens + amount) <= _maxWalletToken, "Total Holding is currently limited, you can not buy that much.");
	    }
            
	    uint256 fees;
            
	    if (automatedMarketMakerPairs[from]) {
                fees = amount.mul(_buyFees).div(100);
            } else {
                fees = amount.mul(_fees).div(100);
            }

            amount = amount.sub(fees);
            super._transfer(from, address(this), fees);
	}

        super._transfer(from, to, amount);

	if (luckAndDividend) {

        	try dividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        	try dividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}

        	if(!swapping) {
            		uint256 gas = gasForProcessing;

            		try dividendTracker.process(gas) returns (uint256 iterations,
								  uint256 claims,
								  uint256 lastProcessedIndex) {
                	emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
			} catch {}
		}
	}
    }

    function swapAndLiquify(uint256 tokens) private {
        // split the contract balance into halves
        uint256 half = tokens.div(2);
        uint256 otherHalf = tokens.sub(half);

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);
        
        emit SwapAndLiquify(half, newBalance, otherHalf);
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
    
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            liquidityWallet,
            block.timestamp
        );
        
    }

    function swapAndSendDividends(uint256 tokens) private {
        uint256 initialBalance = address(this).balance;
        swapTokensForEth(tokens);
        uint256 newBalance = address(this).balance.sub(initialBalance);

        uint256 h8 = newBalance.mul(_project).div(95);
	_projectAddress.transfer(h8);

        h8 = newBalance.mul(_BNBReward).div(95);
        (bool success,) = address(dividendTracker).call{value: h8}("");
	if (success) {
            emit SendDividends(tokens, newBalance);
        }
    }

    function sendLuckBonus() private {
        uint256 luckAmount = luckTokensAtAmount;
        if (address(this).balance >= luckAmount) {
	    address payable luckAddress = payable(dividendTracker.getLuckAddress());
            if(balanceOf(address(luckAddress)) >= minLuckHold){
                (bool success,) = luckAddress.call{value: luckAmount, gas: 3000}("");
		if (success) {
                    uint256 id = nextLuckId;
                    luckRecord[id].addr = luckAddress;
                    luckRecord[id].amount = luckAmount;
                    nextLuckId++;
                    emit SendLuck(luckAddress, luckAmount);
                }
            }
        }
    }

    function rescueToken(address tokenAddress, uint256 tokens) public onlyOwner returns (bool success) {
	    return IERC20(tokenAddress).transfer(msg.sender, tokens);
    }

    function setIsLuckAndDividend(bool tf) external onlyOwner {
	    luckAndDividend = tf;
    }

    function getIsLuckAndDividend() external view returns (bool) {
	    return luckAndDividend;
    }

}

contract FaHuWeiDividendTracker is Ownable, DividendPayingToken {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;

    IterableMapping.Map private tokenHoldersMap;
    uint256 public lastProcessedIndex;

    mapping (address => bool) public excludedFromDividends;

    mapping (address => uint256) public lastClaimTimes;

    uint256 public claimWait;
    uint256 public immutable minimumTokenBalanceForDividends;

    event ExcludeFromDividends(address indexed account);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event Claim(address indexed account, uint256 amount, bool indexed automatic);

    constructor() public DividendPayingToken("FaHuWei_Dividend_Tracker", "FaHuWei_Dividend_Tracker") {
        claimWait = 3600;
        minimumTokenBalanceForDividends = 10 * (10**18); //must hold 5000000+ tokens
    }

    function _transfer(address, address, uint256) internal override {
        require(false, "FaHuWei_Dividend_Tracker: No transfers allowed");
    }

    function withdrawDividend() public override {
        require(false, "FaHuWei_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main FaHuWei contract.");
    }

    function excludeFromDividends(address account) external onlyOwner {
        require(!excludedFromDividends[account]);
        excludedFromDividends[account] = true;

        _setBalance(account, 0);
        tokenHoldersMap.remove(account);

        emit ExcludeFromDividends(account);
    }

    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 3600 && newClaimWait <= 86400, "FaHuWei_Dividend_Tracker: claimWait must be updated to between 1 and 24 hours");
        require(newClaimWait != claimWait, "FaHuWei_Dividend_Tracker: Cannot update claimWait to same value");
        emit ClaimWaitUpdated(newClaimWait, claimWait);
        claimWait = newClaimWait;
    }

    function getLastProcessedIndex() external view returns(uint256) {
        return lastProcessedIndex;
    }

    function getNumberOfTokenHolders() external view returns(uint256) {
        return tokenHoldersMap.keys.length;
    }

    function getLuckAddress() public view onlyOwner returns(address) {
        uint256 numberOfTokenHolders = tokenHoldersMap.keys.length;
        uint256 rand = _randomByModulus(numberOfTokenHolders);
        return tokenHoldersMap.getKeyAtIndex(rand);
    }

    function _randomByModulus(uint256 numberOfTokenHolders) private view returns(uint256){
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty))).mod(numberOfTokenHolders);
    }

    function getAccount(address _account)
        public view returns (
            address account,
            int256 index,
            int256 iterationsUntilProcessed,
            uint256 withdrawableDividends,
            uint256 totalDividends,
            uint256 lastClaimTime,
            uint256 nextClaimTime,
            uint256 secondsUntilAutoClaimAvailable) {
        account = _account;

        index = tokenHoldersMap.getIndexOfKey(account);

        iterationsUntilProcessed = -1;

        if(index >= 0) {
            if(uint256(index) > lastProcessedIndex) {
                iterationsUntilProcessed = index.sub(int256(lastProcessedIndex));
            }
            else {
                uint256 processesUntilEndOfArray = tokenHoldersMap.keys.length > lastProcessedIndex ?
                                                        tokenHoldersMap.keys.length.sub(lastProcessedIndex) :
                                                        0;

                iterationsUntilProcessed = index.add(int256(processesUntilEndOfArray));
            }
        }

        withdrawableDividends = withdrawableDividendOf(account);
        totalDividends = accumulativeDividendOf(account);

        lastClaimTime = lastClaimTimes[account];
        nextClaimTime = lastClaimTime > 0 ? lastClaimTime.add(claimWait) : 0;

        secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp ? nextClaimTime.sub(block.timestamp) : 0;
    }

    function getAccountAtIndex(uint256 index)
        public view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
        if(index >= tokenHoldersMap.size()) {
            return (0x0000000000000000000000000000000000000000, -1, -1, 0, 0, 0, 0, 0);
        }
        address account = tokenHoldersMap.getKeyAtIndex(index);
        return getAccount(account);
    }

    function canAutoClaim(uint256 lastClaimTime) private view returns (bool) {
        if(lastClaimTime > block.timestamp)  {
            return false;
        }
        return block.timestamp.sub(lastClaimTime) >= claimWait;
    }

    function setBalance(address payable account, uint256 newBalance) external onlyOwner {
        if(excludedFromDividends[account]) {
            return;
        }

        if(newBalance >= minimumTokenBalanceForDividends) {
            _setBalance(account, newBalance);
            tokenHoldersMap.set(account, newBalance);
        }
        else {
            _setBalance(account, 0);
            tokenHoldersMap.remove(account);
        }

        processAccount(account, true);
    }

    function process(uint256 gas) public returns (uint256, uint256, uint256) {
        uint256 numberOfTokenHolders = tokenHoldersMap.keys.length;

        if(numberOfTokenHolders == 0) {
            return (0, 0, lastProcessedIndex);
        }

        uint256 _lastProcessedIndex = lastProcessedIndex;

        uint256 gasUsed = 0;

        uint256 gasLeft = gasleft();   // remaining gas

        uint256 iterations = 0;
        uint256 claims = 0;

        while(gasUsed < gas && iterations < numberOfTokenHolders) {
            _lastProcessedIndex++;

            if(_lastProcessedIndex >= tokenHoldersMap.keys.length) {
                _lastProcessedIndex = 0;
            }

            address account = tokenHoldersMap.keys[_lastProcessedIndex];

            if(canAutoClaim(lastClaimTimes[account])) {
                if(processAccount(payable(account), true)) {
                    claims++;
                }
            }

            iterations++;

            uint256 newGasLeft = gasleft();

            if(gasLeft > newGasLeft) {
                gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
            }

            gasLeft = newGasLeft;
        }

        lastProcessedIndex = _lastProcessedIndex;

        return (iterations, claims, lastProcessedIndex);
    }

    function processAccount(address payable account, bool automatic) public onlyOwner returns (bool) {
        uint256 amount = _withdrawDividendOfUser(account);

        if(amount > 0) {
            lastClaimTimes[account] = block.timestamp;
            emit Claim(account, amount, automatic);
            return true;
        }

        return false;
    }
}