/**
 *Submitted for verification at BscScan.com on 2022-08-05
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface IFactory {
	function createPair(address tokenA, address tokenB)
	external
	returns (address pair);

	function getPair(address tokenA, address tokenB)
	external
	view
	returns (address pair);
}

interface IRouter {
	function factory() external pure returns (address);

	function WETH() external pure returns (address);

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

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IERC20 {
	function totalSupply() external view returns (uint256);
	function balanceOf(address account) external view returns (uint256);
	function transfer(address recipient, uint256 amount) external returns (bool);
	function allowance(address owner, address spender) external view returns (uint256);
	function approve(address spender, uint256 amount) external returns (bool);

	function transferFrom(
		address sender,
		address recipient,
		uint256 amount
	) external returns (bool);

	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
	function name() external view returns (string memory);
	function symbol() external view returns (string memory);
	function decimals() external view returns (uint8);
}

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

	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		return div(a, b, "SafeMath: division by zero");
	}

	function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
		require(b > 0, errorMessage);
		uint256 c = a / b;
		// assert(a == b * c + a % b); // There is no case in which this doesn't hold

		return c;
	}

	function mod(uint256 a, uint256 b) internal pure returns (uint256) {
		return mod(a, b, "SafeMath: modulo by zero");
	}

	function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
		require(b != 0, errorMessage);
		return a % b;
	}
}

abstract contract Context {
	function _msgSender() internal view virtual returns (address) {
		return msg.sender;
	}

	function _msgData() internal view virtual returns (bytes calldata) {
		this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
		return msg.data;
	}
}

contract Ownable is Context {
	address private _owner;

	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	constructor () {
		address msgSender = _msgSender();
		_owner = msgSender;
		emit OwnershipTransferred(address(0), msgSender);
	}

	function owner() public view returns (address) {
		return _owner;
	}

	modifier onlyOwner() {
		require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

contract ERC20 is Context, IERC20, IERC20Metadata {
	using SafeMath for uint256;

	mapping(address => uint256) private _balances;
	mapping(address => mapping(address => uint256)) private _allowances;

	uint256 private _totalSupply;
	string private _name;
	string private _symbol;

	constructor(string memory name_, string memory symbol_) {
		_name = name_;
		_symbol = symbol_;
	}

	function name() public view virtual override returns (string memory) {
		return _name;
	}

	function symbol() public view virtual override returns (string memory) {
		return _symbol;
	}

	function decimals() public view virtual override returns (uint8) {
		return 18;
	}

	function totalSupply() public view virtual override returns (uint256) {
		return _totalSupply;
	}

	function balanceOf(address account) public view virtual override returns (uint256) {
		return _balances[account];
	}

	function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
		_transfer(_msgSender(), recipient, amount);
		return true;
	}

	function allowance(address owner, address spender) public view virtual override returns (uint256) {
		return _allowances[owner][spender];
	}

	function approve(address spender, uint256 amount) public virtual override returns (bool) {
		_approve(_msgSender(), spender, amount);
		return true;
	}

	function transferFrom(
		address sender,
		address recipient,
		uint256 amount
	) public virtual override returns (bool) {
		_transfer(sender, recipient, amount);
		_approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
		return true;
	}

	function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
		_approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
		return true;
	}

	function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
		_approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
		return true;
	}

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

	function _mint(address account, uint256 amount) internal virtual {
		require(account != address(0), "ERC20: mint to the zero address");
		_beforeTokenTransfer(address(0), account, amount);
		_totalSupply = _totalSupply.add(amount);
		_balances[account] = _balances[account].add(amount);
		emit Transfer(address(0), account, amount);
	}

	function _burn(address account, uint256 amount) internal virtual {
		require(account != address(0), "ERC20: burn from the zero address");
		_beforeTokenTransfer(account, address(0), amount);
		_balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
		_totalSupply = _totalSupply.sub(amount);
		emit Transfer(account, address(0), amount);
	}

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

	function _beforeTokenTransfer(
		address from,
		address to,
		uint256 amount
	) internal virtual {}
}

contract TokenE is ERC20, Ownable {
    IRouter public uniswapV2Router;
    address public immutable uniswapV2Pair;

    string private constant _name = "TokenE"; //Eurion Token";
    string private constant _symbol = "TokenE"; //ERN";
    uint8 private constant _decimals = 18;

    bool public isTradingEnabled;

    // initialSupply
    uint256 constant initialSupply = 1000000000 * (10**18);

    // max wallet is 2.0% of initialSupply
    uint256 public maxWalletAmount = initialSupply * 200 / 10000;
    uint256 public maxTxAmount = initialSupply;

    bool private _swapping;
    uint256 public minimumTokensBeforeSwap = initialSupply * 50 / 100000;

    address public liquidityWallet;
    address public operationsWallet;
    address public devWallet;
    address public legalWallet;

    struct CustomTaxPeriod {
        bytes23 periodName;
        uint8 blocksInPeriod;
        uint256 timeInPeriod;
        uint8 liquidityFeeOnBuy;
        uint8 liquidityFeeOnSell;
        uint8 operationsFeeOnBuy;
        uint8 operationsFeeOnSell;
        uint8 devFeeOnBuy;
        uint8 devFeeOnSell;
        uint8 legalFeeOnBuy;
        uint8 legalFeeOnSell;
    }

    // Launch taxes
    bool private _isLaunched;
    uint256 private _launchStartTimestamp;
    uint256 private _launchBlockNumber;
    uint256 private constant _blockedTimeLimit = 172800;

    // Base taxes
    CustomTaxPeriod private _base = CustomTaxPeriod('base',0,0,3,3,2,2,4,4,1,1);

    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isBlocked;
    mapping (address => bool) private _isExcludedFromMaxTransactionLimit;
    mapping (address => bool) private _isExcludedFromMaxWalletLimit;
    mapping (address => bool) private _isAllowedToTradeWhenDisabled;
    mapping (address => bool) private _feeOnSelectedWalletTransfers;
    mapping (address => bool) public automatedMarketMakerPairs;

    uint8 private _liquidityFee;
    uint8 private _operationsFee;
    uint8 private _devFee;
    uint8 private _legalFee;
    uint8 private _totalFee;

    event AutomatedMarketMakerPairChange(address indexed pair, bool indexed value);
    event UniswapV2RouterChange(address indexed newAddress, address indexed oldAddress);
    event WalletChange(string indexed indentifier, address indexed newWallet, address indexed oldWallet);
    event BlockedAccountChange(address indexed holder, bool indexed status);
    event FeeChange(string indexed identifier, uint8 liquidityFee, uint8 operationsFee, uint8 devFee, uint8 legalFee);
    event CustomTaxPeriodChange(uint256 indexed newValue, uint256 indexed oldValue, string indexed taxType, bytes23 period);
    event MaxTransactionAmountChange(uint256 indexed newValue, uint256 indexed oldValue);
    event MaxWalletAmountChange(uint256 indexed newValue, uint256 indexed oldValue);
    event AllowedWhenTradingDisabledChange(address indexed account, bool isExcluded);
    event ExcludeFromFeesChange(address indexed account, bool isExcluded);
    event ExcludeFromMaxTransferChange(address indexed account, bool isExcluded);
    event ExcludeFromMaxWalletChange(address indexed account, bool isExcluded);
    event MinTokenAmountBeforeSwapChange(uint256 indexed newValue, uint256 indexed oldValue);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived,uint256 tokensIntoLiqudity);
    event FeeOnSelectedWalletTransfersChange(address indexed account, bool newValue);
    event ClaimETHOverflow(uint256 amount);
    event FeesApplied(uint8 liquidityFee, uint8 operationsFee, uint8 devFee, uint8 legalFee, uint8 totalFee);

    constructor() ERC20(_name, _symbol) {
        liquidityWallet = owner();
        operationsWallet = owner();
        devWallet = owner();
        legalWallet = owner();

        IRouter _uniswapV2Router = IRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E); // Mainnet
        address _uniswapV2Pair = IFactory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;
        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        _isAllowedToTradeWhenDisabled[owner()] = true;

        _isExcludedFromMaxTransactionLimit[address(this)] = true;

        _isExcludedFromMaxWalletLimit[_uniswapV2Pair] = true;
        _isExcludedFromMaxWalletLimit[address(uniswapV2Router)] = true;
        _isExcludedFromMaxWalletLimit[address(this)] = true;
        _isExcludedFromMaxWalletLimit[owner()] = true;

        _mint(owner(), initialSupply);
    }

    receive() external payable {}

    // Setters
    function activateTrading() external onlyOwner {
        isTradingEnabled = true;
        if(_launchBlockNumber == 0) {
            _launchBlockNumber = block.number;
            _launchStartTimestamp = block.timestamp;
            _isLaunched = true;
        }
    }
    function deactivateTrading() external onlyOwner {
        isTradingEnabled = false;
    }
    function allowTradingWhenDisabled(address account, bool allowed) external onlyOwner {
		_isAllowedToTradeWhenDisabled[account] = allowed;
		emit AllowedWhenTradingDisabledChange(account, allowed);
	}
    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "EURION: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;
        emit AutomatedMarketMakerPairChange(pair, value);
    }
    function excludeFromFees(address account, bool excluded) external onlyOwner {
        require(_isExcludedFromFee[account] != excluded, "EURION: Account is already the value of 'excluded'");
        _isExcludedFromFee[account] = excluded;
        emit ExcludeFromFeesChange(account, excluded);
    }
    function excludeFromMaxTransactionLimit(address account, bool excluded) external onlyOwner {
        require(_isExcludedFromMaxTransactionLimit[account] != excluded, "EURION: Account is already the value of 'excluded'");
        _isExcludedFromMaxTransactionLimit[account] = excluded;
        emit ExcludeFromMaxTransferChange(account, excluded);
    }
    function excludeFromMaxWalletLimit(address account, bool excluded) external onlyOwner {
        require(_isExcludedFromMaxWalletLimit[account] != excluded, "EURION: Account is already the value of 'excluded'");
        _isExcludedFromMaxWalletLimit[account] = excluded;
        emit ExcludeFromMaxWalletChange(account, excluded);
    }
    function setFeeOnSelectedWalletTransfers(address account, bool value) external onlyOwner {
		require(_feeOnSelectedWalletTransfers[account] != value, "EURION: The selected wallet is already set to the value ");
		_feeOnSelectedWalletTransfers[account] = value;
		emit FeeOnSelectedWalletTransfersChange(account, value);
	}
    function blockAccount(address account) external onlyOwner {
		require(!_isBlocked[account], "EURION: Account is already blocked");
		if (_launchStartTimestamp > 0) {
			require((block.timestamp - _launchStartTimestamp) < _blockedTimeLimit, "EURION: Time to block accounts has expired");
		}
		_isBlocked[account] = true;
		emit BlockedAccountChange(account, true);
	}
	function unblockAccount(address account) external onlyOwner {
		require(_isBlocked[account], "EURION: Account is not blcoked");
		_isBlocked[account] = false;
		emit BlockedAccountChange(account, false);
	}
    function setWallets(address newLiquidityWallet, address newOperationsWallet, address newDevWallet, address newLegalWallet) external onlyOwner {
        if(liquidityWallet != newLiquidityWallet) {
            require(newLiquidityWallet != address(0), "EURION: The liquidityWallet cannot be 0");
            emit WalletChange('liquidityWallet', newLiquidityWallet, liquidityWallet);
            liquidityWallet = newLiquidityWallet;
        }
        if(operationsWallet != newOperationsWallet) {
            require(newOperationsWallet != address(0), "EURION: The operationsWallet cannot be 0");
            emit WalletChange('operationsWallet', newOperationsWallet, operationsWallet);
            operationsWallet = newOperationsWallet;
        }
        if(devWallet != newDevWallet) {
            require(newDevWallet != address(0), "EURION: The devWallet cannot be 0");
            emit WalletChange('devWallet', newDevWallet, devWallet);
            devWallet = newDevWallet;
        }
        if(legalWallet != newLegalWallet) {
            require(newLegalWallet != address(0), "EURION: The legalWallet cannot be 0");
            emit WalletChange('legalWallet', newLegalWallet, legalWallet);
            legalWallet = newLegalWallet;
        }
    }
    // Base fees
    function setBaseFeesOnBuy(uint8 _liquidityFeeOnBuy, uint8 _operationsFeeOnBuy, uint8 _devFeeOnBuy, uint8 _legalFeeOnBuy) external onlyOwner {
        _setCustomBuyTaxPeriod(_base, _liquidityFeeOnBuy, _operationsFeeOnBuy, _devFeeOnBuy, _legalFeeOnBuy);
        emit FeeChange('baseFees-Buy', _liquidityFeeOnBuy, _operationsFeeOnBuy, _devFeeOnBuy, _legalFeeOnBuy);
    }
    function setBaseFeesOnSell(uint8 _liquidityFeeOnSell,uint8 _operationsFeeOnSell , uint8 _devFeeOnSell, uint8 _legalFeeOnSell) external onlyOwner {
        _setCustomSellTaxPeriod(_base, _liquidityFeeOnSell, _operationsFeeOnSell, _devFeeOnSell, _legalFeeOnSell);
        emit FeeChange('baseFees-Sell', _liquidityFeeOnSell, _operationsFeeOnSell, _devFeeOnSell, _legalFeeOnSell);
    }
    function setUniswapRouter(address newAddress) external onlyOwner {
        require(newAddress != address(uniswapV2Router), "EURION: The router already has that address");
        emit UniswapV2RouterChange(newAddress, address(uniswapV2Router));
        uniswapV2Router = IRouter(newAddress);
    }
    function setMaxTransactionAmount(uint256 newValue) external onlyOwner {
        require(newValue != maxTxAmount, "EURION: Cannot update maxTxAmount to same value");
        emit MaxTransactionAmountChange(newValue, maxTxAmount);
        maxTxAmount = newValue;
    }
    function setMaxWalletAmount(uint256 newValue) external onlyOwner {
        require(newValue != maxWalletAmount, "EURION: Cannot update maxWalletAmount to same value");
        emit MaxWalletAmountChange(newValue, maxWalletAmount);
        maxWalletAmount = newValue;
    }
    function setMinimumTokensBeforeSwap(uint256 newValue) external onlyOwner {
        require(newValue != minimumTokensBeforeSwap, "EURION: Cannot update minimumTokensBeforeSwap to same value");
        emit MinTokenAmountBeforeSwapChange(newValue, minimumTokensBeforeSwap);
        minimumTokensBeforeSwap = newValue;
    }
    function claimETHOverflow() external onlyOwner {
        uint256 amount = address(this).balance;
        (bool success,) = address(owner()).call{value : amount}("");
        if (success){
            emit ClaimETHOverflow(amount);
        }
    }

    // Getters
    function getBaseBuyFees() external view returns (uint8, uint8, uint8, uint8) {
        return (_base.liquidityFeeOnBuy, _base.operationsFeeOnBuy, _base.devFeeOnBuy, _base.legalFeeOnBuy);
    }
    function getBaseSellFees() external view returns (uint8, uint8, uint8, uint8) {
        return (_base.liquidityFeeOnSell, _base.operationsFeeOnSell, _base.devFeeOnSell, _base.legalFeeOnSell);
    }

    // Main
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

        bool isBuyFromLp = automatedMarketMakerPairs[from];
        bool isSelltoLp = automatedMarketMakerPairs[to];

        if(!_isAllowedToTradeWhenDisabled[from] && !_isAllowedToTradeWhenDisabled[to]) {
            require(isTradingEnabled, "EURION: Trading is currently disabled.");
            require(!_isBlocked[to], "EURION: Account is blocked");
			require(!_isBlocked[from], "EURION: Account is blocked");
            if (!_isExcludedFromMaxTransactionLimit[to] && !_isExcludedFromMaxTransactionLimit[from]) {
                require(amount <= maxTxAmount, "EURION: Buy amount exceeds the maxTxBuyAmount.");
            }
            if (!_isExcludedFromMaxWalletLimit[to]) {
                require((balanceOf(to) + amount) <= maxWalletAmount, "EURION: Expected wallet amount exceeds the maxWalletAmount.");
            }
        }

        _adjustTaxes(isBuyFromLp, isSelltoLp, from , to);
        bool canSwap = balanceOf(address(this)) >= minimumTokensBeforeSwap;

        if (
            isTradingEnabled &&
            canSwap &&
            !_swapping &&
            _totalFee > 0 &&
            automatedMarketMakerPairs[to]
        ) {
            _swapping = true;
            _swapAndLiquify();
            _swapping = false;
        }

        bool takeFee = !_swapping && isTradingEnabled;

        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }

        if (takeFee && _totalFee > 0) {
            uint256 fee = amount * _totalFee / 100;
            amount = amount - fee;
            super._transfer(from, address(this), fee);
        }

        super._transfer(from, to, amount);
    }
    function _adjustTaxes(bool isBuyFromLp, bool isSelltoLp, address from, address to) private {
        _liquidityFee = 0;
        _operationsFee = 0;
        _devFee = 0;
        _legalFee = 0;

        if (isBuyFromLp) {
            if (_isLaunched && block.number - _launchBlockNumber <= 5) {
                _liquidityFee = 100;
            } else {
                _liquidityFee = _base.liquidityFeeOnBuy;
                _operationsFee = _base.operationsFeeOnBuy;
                _devFee = _base.devFeeOnBuy;
                _legalFee = _base.legalFeeOnBuy;
            } 
        }
        if (isSelltoLp) {
            _liquidityFee = _base.liquidityFeeOnSell;
            _operationsFee = _base.operationsFeeOnSell;
            _devFee = _base.devFeeOnSell;
            _legalFee = _base.legalFeeOnSell;
        }
        if (!isSelltoLp && !isBuyFromLp && (_feeOnSelectedWalletTransfers[from] || _feeOnSelectedWalletTransfers[to])) {
			_liquidityFee = _base.liquidityFeeOnSell;
            _operationsFee = _base.operationsFeeOnSell;
            _devFee = _base.devFeeOnSell;
            _legalFee = _base.legalFeeOnSell;
		}
        _totalFee = _liquidityFee + _operationsFee + _devFee + _legalFee;
        emit FeesApplied(_liquidityFee, _operationsFee, _devFee, _legalFee, _totalFee);
    }
    function _setCustomSellTaxPeriod(CustomTaxPeriod storage map,
        uint8 _liquidityFeeOnSell,
        uint8 _operationsFeeOnSell,
        uint8 _devFeeOnSell,
        uint8 _legalFeeOnSell
        ) private {
        require((_liquidityFeeOnSell+_operationsFeeOnSell+_devFeeOnSell+_legalFeeOnSell) <= 10, "EURION: Tax exceeds maximum value of 10%");
        if (map.liquidityFeeOnSell != _liquidityFeeOnSell) {
            emit CustomTaxPeriodChange(_liquidityFeeOnSell, map.liquidityFeeOnSell, 'liquidityFeeOnSell', map.periodName);
            map.liquidityFeeOnSell = _liquidityFeeOnSell;
        }
        if (map.operationsFeeOnSell != _operationsFeeOnSell) {
            emit CustomTaxPeriodChange(_operationsFeeOnSell, map.operationsFeeOnSell, 'operationsFeeOnSell', map.periodName);
            map.operationsFeeOnSell = _operationsFeeOnSell;
        }
        if (map.devFeeOnSell != _devFeeOnSell) {
            emit CustomTaxPeriodChange(_devFeeOnSell, map.devFeeOnSell, 'devFeeOnSell', map.periodName);
            map.devFeeOnSell = _devFeeOnSell;
        }
        if (map.legalFeeOnSell != _legalFeeOnSell) {
            emit CustomTaxPeriodChange(_legalFeeOnSell, map.legalFeeOnSell, 'legalFeeOnSell', map.periodName);
            map.legalFeeOnSell = _legalFeeOnSell;
        }
    }
    function _setCustomBuyTaxPeriod(CustomTaxPeriod storage map,
        uint8 _liquidityFeeOnBuy,
        uint8 _operationsFeeOnBuy,
        uint8 _devFeeOnBuy,
        uint8 _legalFeeOnBuy
        ) private {
        require((_liquidityFeeOnBuy+_operationsFeeOnBuy+_devFeeOnBuy+_legalFeeOnBuy) <= 10, "EURION: Tax exceeds maximum value of 10%");

        if (map.liquidityFeeOnBuy != _liquidityFeeOnBuy) {
            emit CustomTaxPeriodChange(_liquidityFeeOnBuy, map.liquidityFeeOnBuy, 'liquidityFeeOnBuy', map.periodName);
            map.liquidityFeeOnBuy = _liquidityFeeOnBuy;
        }
        if (map.operationsFeeOnBuy != _operationsFeeOnBuy) {
            emit CustomTaxPeriodChange(_operationsFeeOnBuy, map.operationsFeeOnBuy, 'operationsFeeOnBuy', map.periodName);
            map.operationsFeeOnBuy = _operationsFeeOnBuy;
        }
        if (map.devFeeOnBuy != _devFeeOnBuy) {
            emit CustomTaxPeriodChange(_devFeeOnBuy, map.devFeeOnBuy, 'devFeeOnBuy', map.periodName);
            map.devFeeOnBuy = _devFeeOnBuy;
        }
        if (map.legalFeeOnBuy != _legalFeeOnBuy) {
            emit CustomTaxPeriodChange(_legalFeeOnBuy, map.legalFeeOnBuy, 'legalFeeOnBuy', map.periodName);
            map.legalFeeOnBuy = _legalFeeOnBuy;
        }
    }
    function _swapAndLiquify() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 initialETHBalance = address(this).balance;
        uint8 _totalFeePrior = _totalFee;

        uint256 amountToLiquify = contractBalance * _liquidityFee / _totalFeePrior / 2;
        uint256 amountToSwap = contractBalance - amountToLiquify;

        _swapTokensForETH(amountToSwap);

        uint256 ETHBalanceAfterSwap = address(this).balance - initialETHBalance;
        uint256 totalETHFee = _totalFeePrior - (_liquidityFee / 2);
        uint256 amountETHLiquidity = ETHBalanceAfterSwap * _liquidityFee / totalETHFee / 2;
        uint256 amountETHOperations = ETHBalanceAfterSwap * _operationsFee / totalETHFee;
        uint256 amountETHLegal = ETHBalanceAfterSwap * _legalFee / totalETHFee;
        uint256 amountETHDev = ETHBalanceAfterSwap - (amountETHLiquidity + amountETHOperations + amountETHLegal);

        payable(devWallet).transfer(amountETHDev);
        payable(operationsWallet).transfer(amountETHOperations);
        payable(legalWallet).transfer(amountETHLegal);

        if (amountToLiquify > 0) {
            _addLiquidity(amountToLiquify, amountETHLiquidity);
            emit SwapAndLiquify(amountToSwap, amountETHLiquidity, amountToLiquify);
        }

        _totalFee = _totalFeePrior;
    }
    function _swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }
    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            liquidityWallet,
            block.timestamp
        );
    }
}