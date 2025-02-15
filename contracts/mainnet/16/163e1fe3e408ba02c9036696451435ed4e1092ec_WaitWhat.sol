/**
 *Submitted for verification at BscScan.com on 2021-12-16
*/

/**
Wait...What? - $HUH

Telegram: https://t.me/wait_what_token
*/


// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

abstract contract Auth {
    address internal owner;
    mapping (address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    /**
     * Function modifier to require caller to be authorized
     */
    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }

    /**
     * Authorize address. Owner only
     */
    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    /**
     * Remove address' authorization. Owner only
     */
    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    /**
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    /**
     * Return address' authorization status
     */
    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    /**
     * Transfer ownership to new address. Caller must be owner. Leaves old owner authorized
     */
    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
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
}


interface IDexFactory {
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


interface IDexRouter {
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





/**
 * 響
 * ひびき
 * /çibʲikʲi/
 * 
 * The sound of money in your pocket. The echoes of the cries of those who didn't buy. The reverberation of the rocket going to the moon.
 *
 * Multichain tools and blockchain games.
 * https://hibiki.finance https://t.me/hibikifinance 
 */


contract WaitWhat is IBEP20, Auth {

	address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

	string constant _name = "Wait...What?";
    string constant _symbol = "HUH";
    uint8 constant _decimals = 18;

    uint256 _totalSupply = 10_000_000 * (10 ** _decimals);
    uint256 public _maxTxAmount = _totalSupply / 100;
	uint256 public _maxWalletAmount = _totalSupply / 100;

	mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;
    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => uint256) _boughtAt;

	// Fees. Some may be completely inactive at all times.
	uint256 liquidityFee = 100;
    uint256 burnFee = 0;
	uint256 stakingFee = 0;
	uint256 nftStakingFee = 0;
    uint256 feeDenominator = 1000;
    uint256 sellMultiplier = 2000;
    uint256 sellDenominator = 1000;
    uint256 jeetMultiplier = 2;
    uint256 jeetBlocks = 1000;
    uint256 jeetBurnFee = 0;
	bool public feeOnNonTrade = false;
    bool private isSell = false;
    bool private isJeet = false;

	uint256 public stakingPrizePool = 0;
	bool public stakingRewardsActive = false;
	address public stakingRewardsContract;
	uint256 public nftStakingPrizePool = 0;
	bool public nftStakingRewardsActive = false;
	address public nftStakingRewardsContract;

	address public autoLiquidityReceiver;

	IDexRouter public router;
    address pcs2BNBPair;
    address[] public pairs;

	bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply / 20000;
    bool inSwap;
    modifier swapping() {
		inSwap = true;
		_;
		inSwap = false;
	}

	uint256 public launchedAt = 0;
	uint256 private antiSniperBlocks = 3;
	uint256 private antiSniperGasLimit = 30 gwei;
	bool private gasLimitActive = true;

	event AutoLiquifyEnabled(bool enabledOrNot);
	event AutoLiquify(uint256 amountBNB, uint256 autoBuybackAmount);
	event StakingRewards(bool activate);
	event NFTStakingRewards(bool active);

	constructor() Auth(msg.sender) {
		//router = IDexRouter(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
		router = IDexRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        pcs2BNBPair = IDexFactory(router.factory()).createPair(router.WETH(), address(this));
        _allowances[address(this)][address(router)] = type(uint256).max;

		isFeeExempt[msg.sender] = true;
        isFeeExempt[address(this)] = true;
		isTxLimitExempt[msg.sender] = true;
		isTxLimitExempt[address(this)] = true;
        isTxLimitExempt[DEAD] = true;
        isTxLimitExempt[ZERO] = true;

		autoLiquidityReceiver = msg.sender;
		pairs.push(pcs2BNBPair);
		_balances[msg.sender] = _totalSupply;
		emit Transfer(address(0), msg.sender, _totalSupply);
	}

	receive() external payable {}
    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

	function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
			require(_allowances[sender][msg.sender] >= amount, "Insufficient Allowance");
            _allowances[sender][msg.sender] -= amount;
        }

        return _transferFrom(sender, recipient, amount);
    }

	function _isStakingReward(address sender, address recipient) internal view returns (bool) {
		return sender == stakingRewardsContract
			|| sender == nftStakingRewardsContract
			|| recipient == stakingRewardsContract
			|| recipient == nftStakingRewardsContract;
	}

	function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
		require(amount > 0);
        if (inSwap || _isStakingReward(sender, recipient)) {
            return _basicTransfer(sender, recipient, amount);
        }

        checkTxLimit(sender, recipient, amount);

        if (shouldSwapBack()) {
            liquify();
        }

        if (!launched() && recipient == pcs2BNBPair) {
            require(_balances[sender] > 0);
            require(sender == owner, "Only the owner can be the first to add liquidity.");
            launch();
        }

		require(amount <= _balances[sender], "Insufficient Balance");
        _balances[sender] -= amount;

        uint256 amountReceived = shouldTakeFee(sender, recipient) ? takeFee(sender, amount) : amount;
        _balances[recipient] += amountReceived;

		// Update staking pool, if active.
		// Update of the pool can be deactivated for launch and staking contract migration.
		if (stakingRewardsActive) {
			sendToStakingPool();
		}
		if (nftStakingRewardsActive) {
			sendToNftStakingPool();
		}

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

	function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
		require(amount <= _balances[sender], "Insufficient Balance");
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

	function checkTxLimit(address sender, address recipient, uint256 amount) internal view {
        require(amount <= _maxTxAmount || isTxLimitExempt[sender] || isTxLimitExempt[recipient] && sender == pcs2BNBPair, "TX Limit Exceeded");
		// Max wallet check.
		if (sender != owner
            && recipient != owner
            && !isTxLimitExempt[recipient]
            && recipient != ZERO 
            && recipient != DEAD 
            && recipient != pcs2BNBPair 
            && recipient != address(this)
        ) {
            uint256 newBalance = balanceOf(recipient) + amount;
            require(newBalance <= _maxWalletAmount, "Exceeds max wallet.");
        }
    }

	// Decides whether this trade should take a fee.
	// Trades with pairs are always taxed, unless sender or receiver is exempted.
	// Non trades, like wallet to wallet, are configured, untaxed by default.
	function shouldTakeFee(address sender, address recipient) internal returns (bool) {
        if (isFeeExempt[sender] || isFeeExempt[recipient] || !launched()) {
			return false;
		}

        address[] memory liqPairs = pairs;
        for (uint256 i = 0; i < liqPairs.length; i++) {
            if (sender == liqPairs[i] ) {
                isSell = false;
                _boughtAt[recipient] = block.number;
				return true;
			}
        }
        for (uint256 i = 0; i < liqPairs.length; i++) {
            if (recipient == liqPairs[i]) {
                isSell = true;
                if(_boughtAt[sender] + jeetBlocks > block.number){
                    isJeet = true;
                }
				return true;
			}
        }
        return feeOnNonTrade;
    }

	function setAntisniperBlocks(uint256 blocks) external authorized {
		antiSniperBlocks = blocks;
	}

	function setAntisniperGas(bool active, uint256 quantity) external authorized {
		require(!active || quantity >= 1 gwei, "Needs to be at least 1 gwei.");
		gasLimitActive = active;
		antiSniperGasLimit = quantity;
	}

	function takeFee(address sender, uint256 amount) internal returns (uint256) {
		if (!launched()) {
			return amount;
		}
		uint256 liqFee = 0;
		uint256 bf = 0;
		uint256 steak = 0;
		uint256 nftStake = 0;
		if (block.number - launchedAt <= antiSniperBlocks || gasLimitActive && tx.gasprice >= antiSniperGasLimit) {
			liqFee = amount * feeDenominator - 1 / feeDenominator;
            _balances[address(this)] += liqFee;
			amount -= liqFee;
			emit Transfer(sender, address(this), liqFee);
        } else {
			// If there is a liquidity tax active for autoliq, the contract keeps it.
			if (liquidityFee > 0) {
				liqFee = amount * liquidityFee / feeDenominator;
                if(isSell){
                    liqFee = liqFee * sellMultiplier / sellDenominator;
                }
                if(isJeet){
                    liqFee = liqFee * jeetMultiplier;
                }
				_balances[address(this)] += liqFee;
				emit Transfer(sender, address(this), liqFee);
			}
			// If there is an active burn fee, burn a percentage and give it to dead address.
			if (burnFee > 0 || jeetBurnFee > 0) {
				bf = amount * burnFee / feeDenominator;
                if(isSell){
                    bf = bf * sellMultiplier / sellDenominator;
                }
                if(isJeet){
                    bf += amount * jeetBurnFee / feeDenominator;
                }
				_balances[DEAD] += bf;
				emit Transfer(sender, DEAD, bf);
			}
			// If staking tax is active, it is stored on ZERO address.
			// If staking payout itself is active, it is later moved from ZERO to the appropriate staking address.
			if (stakingFee > 0) {
				steak = amount * stakingFee / feeDenominator;
                if(isSell){
                    steak = steak * sellMultiplier / sellDenominator;
                }
				_balances[ZERO] += steak;
				stakingPrizePool += steak;
				emit Transfer(sender, ZERO, steak);
			}
			if (nftStakingFee > 0) {
				nftStake = amount * nftStakingFee / feeDenominator;
                if(isSell){
                    nftStake = nftStake * sellMultiplier / sellDenominator;
                }
				_balances[ZERO] += nftStake;
				nftStakingPrizePool += nftStake;
				emit Transfer(sender, ZERO, nftStake);
			}
		}
        isJeet = false;
        return amount - liqFee - bf - steak - nftStake;
    }

	function sendToStakingPool() internal {
		_balances[ZERO] -= stakingPrizePool;
		_balances[stakingRewardsContract] += stakingPrizePool;
		emit Transfer(ZERO, stakingRewardsContract, stakingPrizePool);
		stakingPrizePool = 0;
	}

	function sendToNftStakingPool() internal {
		_balances[ZERO] -= nftStakingPrizePool;
		_balances[nftStakingRewardsContract] += nftStakingPrizePool;
		emit Transfer(ZERO, nftStakingRewardsContract, nftStakingPrizePool);
		nftStakingPrizePool = 0;
	}

	function setStakingRewardsAddress(address addy) external authorized {
		stakingRewardsContract = addy;
		isFeeExempt[addy] = true;
		isTxLimitExempt[addy] = true;
	}

	function setNftStakingRewardsAddress(address addy) external authorized {
		nftStakingRewardsContract = addy;
		isFeeExempt[addy] = true;
		isTxLimitExempt[addy] = true;
	}

    function shouldSwapBack() internal view returns (bool) {
        return launched()
			&& msg.sender != pcs2BNBPair
            && !inSwap
            && swapEnabled
            && _balances[address(this)] >= swapThreshold;
    }

	function setSwapEnabled(bool set) external authorized {
		swapEnabled = set;
		emit AutoLiquifyEnabled(set);
	}

	function liquify() internal swapping {
        uint256 amountToTeam = balanceOf(address(this)) / 3;
        uint256 amountToLiquidity = balanceOf(address(this)) / 3;
        uint256 amountToSwapForBNB = amountToLiquidity + amountToTeam;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwapForBNB,
            0,
            path,
            address(this),
            block.timestamp
        );
        uint256 amountBNB = address(this).balance;
        uint256 devBNB = amountBNB / 5;
        
        payable(0x8D84e59Aabe7A16Fc87005C007B2a6341a691B90).transfer(devBNB);
        
        uint256 amountBNBLiquidity = address(this).balance;

		router.addLiquidityETH{value: amountBNBLiquidity}(
			address(this),
			amountToLiquidity,
			0,
			0,
			autoLiquidityReceiver,
			block.timestamp
		);
        payable(0xe6497e1F2C5418978D5fC2cD32AA23315E7a41Fb).transfer(address(this).balance);
    }

	function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function launch() internal {
        launchedAt = block.number;
    }

	function setTxLimit(uint256 amount) external authorized {
        require(amount >= _totalSupply / 1000);
        _maxTxAmount = amount;
    }

	function setMaxWallet(uint256 amount) external authorized {
		require(amount >= _totalSupply / 1000);
		_maxWalletAmount = amount;
	}

    function setIsFeeExempt(address holder, bool exempt) external authorized {
        isFeeExempt[holder] = exempt;
    }

    function setIsTxLimitExempt(address holder, bool exempt) external authorized {
        isTxLimitExempt[holder] = exempt;
    }

    function setFees(uint256 _liquidityFee, uint256 _burnFee, uint256 _stakingFee, uint256 _nftStakingFee, uint256 _feeDenominator, uint256 _sellMultiplier, uint256 _sellDenominator, uint256 _jeetMultiplier, uint256 _jeetBlocks, uint256 _jeetBurnFee) external authorized {
        liquidityFee = _liquidityFee;
        burnFee = _burnFee;
		stakingFee = _stakingFee;
		nftStakingFee = _nftStakingFee;
        feeDenominator = _feeDenominator;
        sellMultiplier = _sellMultiplier;
        sellDenominator = _sellDenominator;
        jeetMultiplier = _jeetMultiplier;
        jeetBlocks = _jeetBlocks;
        jeetBurnFee = _jeetBurnFee;
		uint256 totalFee = _liquidityFee + _burnFee + _stakingFee + _nftStakingFee;
        require(totalFee < feeDenominator / 5, "Maximum allowed buytax on this contract is 20%.");
        require(totalFee * sellMultiplier / sellDenominator < feeDenominator / 2, "Maximum allowed selltax on this contract is 50%.");
    }

    function setLiquidityReceiver(address _autoLiquidityReceiver) external authorized {
        autoLiquidityReceiver = _autoLiquidityReceiver;
    }

	function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply - balanceOf(DEAD) - balanceOf(ZERO) + stakingPrizePool + nftStakingPrizePool;
    }

	// Recover any BNB sent to the contract by mistake.
	function rescue() external {
        payable(owner).transfer(address(this).balance);
    }

	function setStakingRewardsActive(bool active) external authorized {
		stakingRewardsActive = active;
		emit StakingRewards(active);
	}

	function setNftStakingRewardsActive(bool active) external authorized {
		nftStakingRewardsActive = active;
		emit NFTStakingRewards(active);
	}

	function addPair(address pair) external authorized {
        pairs.push(pair);
    }
    
    function removeLastPair() external authorized {
        pairs.pop();
    }
}