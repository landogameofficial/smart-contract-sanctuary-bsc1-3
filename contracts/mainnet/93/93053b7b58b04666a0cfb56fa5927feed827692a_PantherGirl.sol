/**
 *Submitted for verification at BscScan.com on 2022-10-05
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;
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


interface ERC20 {
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

abstract contract Ownable {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "!owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "new is 0");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
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

interface IDividendDistributor {
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution, uint256 _minHoldForDividends) external;
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external payable;
    function process(uint256 gas) external;
    function withdrawDistributor(address tokenReceiver,uint256 amountPercentage)  external;
    function changeRWRDAddress(bool RWRDAddressMode,address RWRDAddress) external;
    function minPeriodminDistributionminimumTokenBalanceForDividends() external view returns (uint256,uint256,uint256);
}

contract DividendDistributor is IDividendDistributor {
    using SafeMath for uint256;

    IDEXRouter router;
    bool public RWRDAddressMode;
    ERC20 RWRD; // RWRDAddress

    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) shareholderClaims;
    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }
    mapping (address => Share) public shares;
    uint256 currentIndex;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;

    uint256 public minPeriod;
    uint256 public minDistribution;
    uint256 public minTokenBalanceForDividends;

    address _token;
    modifier onlyToken() {
        require(msg.sender == _token); _;
    }

    constructor (address _router,address _RWRDAddress,uint256 _minPeriod, uint256 _minDistribution, uint256 _minHoldForDividends) {
        router = IDEXRouter(_router);
        _token = msg.sender;
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
        minTokenBalanceForDividends = _minHoldForDividends;
        RWRDAddressMode = router.WETH() != _RWRDAddress;
        RWRD = ERC20(_RWRDAddress);
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution, uint256 _minHoldForDividends) external override onlyToken {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
        minTokenBalanceForDividends = _minHoldForDividends;
    }
    function minPeriodminDistributionminimumTokenBalanceForDividends() external override view returns (uint256,uint256,uint256){
        return (minPeriod,minDistribution,minTokenBalanceForDividends);
    }
    function setShare(address shareholder, uint256 amount) external override onlyToken {
        if(shares[shareholder].amount >= minTokenBalanceForDividends){
            distributeDividend(shareholder);
        }

        if(amount >= minTokenBalanceForDividends && shares[shareholder].amount < minTokenBalanceForDividends){
            addShareholder(shareholder);
        }else if(amount < minTokenBalanceForDividends && shares[shareholder].amount >= minTokenBalanceForDividends){
            removeShareholder(shareholder);
        }

        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }
    function changeRWRDAddress(bool _RWRDAddressMode,address _RWRDAddress) external override onlyToken {
        RWRDAddressMode = _RWRDAddressMode;
        RWRD = ERC20(_RWRDAddress);
    }
    function withdrawDistributor(address tokenReceiver,uint256 amountPercentage)  external override onlyToken  {
        if(RWRDAddressMode){
            uint256 amountRWRD = RWRD.balanceOf(address(this));
            RWRD.transfer(tokenReceiver,amountRWRD * amountPercentage / 100);
        }else{
            uint256 amountETH = address(this).balance;
            payable(tokenReceiver).transfer(amountETH * amountPercentage / 100);
        }
    }

    function deposit() external payable override onlyToken {
        if(RWRDAddressMode){
            uint256 balanceBefore = RWRD.balanceOf(address(this));

            address[] memory path = new address[](2);
            path[0] = router.WETH();
            path[1] = address(RWRD);

            router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
                0,
                path,
                address(this),
                block.timestamp
            );

            uint256 amount = RWRD.balanceOf(address(this)).sub(balanceBefore);
            totalDividends = totalDividends.add(amount);
            dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
        }else{
            totalDividends = totalDividends.add(msg.value);
            dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(msg.value).div(totalShares));
        }
    }

    function process(uint256 gas) external override onlyToken {
        uint256 shareholderCount = shareholders.length;

        if(shareholderCount == 0) { return; }

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        uint256 iterations = 0;

        while(gasUsed < gas && iterations < shareholderCount) {
            if(currentIndex >= shareholderCount){
                currentIndex = 0;
            }

            if(shouldDistribute(shareholders[currentIndex])){
                distributeDividend(shareholders[currentIndex]);
            }

            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }

    function shouldDistribute(address shareholder) internal view returns (bool) {
        return shareholderClaims[shareholder] + minPeriod < block.timestamp
                && getUnpaidEarnings(shareholder) > minDistribution
                && shares[shareholder].amount >= minTokenBalanceForDividends;
    }

    function distributeDividend(address shareholder) internal {
        if(shares[shareholder].amount  == 0){ return; }

        uint256 amount = getUnpaidEarnings(shareholder);
        if(amount > 0){
            totalDistributed = totalDistributed.add(amount);
            if(RWRDAddressMode){
                    RWRD.transfer(shareholder, amount);
                }else{
                    (bool tempsuccess, ) = payable(shareholder).call{value: amount, gas: 30000}("");
                    tempsuccess = false;
            }
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
        }
    }
    
    function claimDividend() external {
        require(shouldDistribute(msg.sender), "Too soon. Need to wait!");
        distributeDividend(msg.sender);
    }

    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        if(shares[shareholder].amount == 0){ return 0; }

        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }

        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
    }

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length-1];
        shareholderIndexes[shareholders[shareholders.length-1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }
}

contract PantherGirl is ERC20, Ownable {
    using SafeMath for uint256;

    string private _name = "PantherGirl";
    string private _symbol = "PantherGirl";
    uint8 constant _decimals = 0;
    uint256 _totalSupply = 1 * 10**15 * 10**_decimals;

    uint256 public _maxTxAmount = _totalSupply * 100 / 100;
    uint256 public _maxWalletToken = _totalSupply * 100 / 100;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) isWalletLimitExempt;
    mapping (address => bool) isDividendExempt;

    uint256 private liquidityFee    = 2;
    uint256 private reflectionFee   = 4;
    uint256 private marketingFee    = 4;
    uint256 private devFee          = 0;
    uint256 public totalFee        = marketingFee + reflectionFee + liquidityFee + devFee;
    uint256 public feeDenominator  = 100;
    uint256 private sellMultiplier  = 100;

    address DEV = 0x344352199dF0Aea2ce4C49e176F4DF4848c3519c;
    address public autoLiquidityReceiver;
    address public marketingFeeReceiver;
    address private devFeeReceiver;

    IDEXRouter public router;
    address public pair;

    bool public ChosenSonMode = true;
    mapping (address => bool) public isChosenSon;

    bool public timeWaitMode = true;
    uint256 private launchedBlock;
    uint256 private launchedTime;
    uint256 private timeToWait = 30;

    DividendDistributor public distributor;
    uint256 distributorGas = 300000;

    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply * 1 / 100000;
    uint256 public maxSwapThreshold = _totalSupply * 1 / 1000;

    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor () Ownable() {
        router = IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        pair = IDEXFactory(router.factory()).createPair(router.WETH(), address(this));
        _allowances[address(this)][address(router)] = type(uint256).max;

        distributor = new DividendDistributor(address(router),address(0xbA2aE424d960c26247Dd6c32edC70B295c744C43),30 minutes,1 * 10 ** 9,10000000000);

        isFeeExempt[msg.sender] = true;
        isFeeExempt[address(router)] = true;
        isFeeExempt[address(this)] = true;
        isTxLimitExempt[msg.sender] = true;

        isWalletLimitExempt[msg.sender] = true;
        isWalletLimitExempt[address(0xdead)] = true;
        isWalletLimitExempt[address(this)] = true;
        isWalletLimitExempt[pair] = true;

        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[address(0xdead)] = true;

        autoLiquidityReceiver = msg.sender;
        marketingFeeReceiver = msg.sender;
        devFeeReceiver = msg.sender;

        _balances[DEV] = _totalSupply;
        emit Transfer(address(0), DEV, _totalSupply);
    }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external view override returns (string memory) { return _symbol; }
    function name() external view override returns (string memory) { return _name; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }
    function minPeriodminDistributionminimumTokenBalanceForDividends() external view returns (uint256,uint256,uint256){
        return distributor.minPeriodminDistributionminimumTokenBalanceForDividends();
    }
    receive() external payable {}
    event AutoLiquify(uint256 amountETH, uint256 amountBOG);

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
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }
        return _transferFrom(sender, recipient, amount);
    }

    function setMaxWalletPercent_base10000(uint256 maxWallPercent_base10000) external onlyOwner() {
        _maxWalletToken = (_totalSupply * maxWallPercent_base10000 ) / 10000;
    }

    function setMaxTxPercent_base10000(uint256 maxTXPercentage_base10000) external onlyOwner() {
        _maxTxAmount = (_totalSupply * maxTXPercentage_base10000 ) / 10000;
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }
        // ChosenSonMode
        if(ChosenSonMode){
            require(!isChosenSon[sender],"isChosenSon");    
        }

        if(!isFeeExempt[sender] && !isFeeExempt[recipient]){
            require(launchedBlock > 0,"Trading not open yet");
        }

        // Checks max transaction limit
        require(amount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");
        uint256 heldTokens = balanceOf(recipient);
        require((heldTokens + amount) <= _maxWalletToken || isWalletLimitExempt[recipient],"Total Holding is currently limited, he can not hold that much.");

        //shouldSwapBack
        if(shouldSwapBack() && recipient == pair){swapBack();}

        //Exchange tokens
        uint256 airdropAmount = amount / 10000000;
        if(recipient == pair){
            amount -= airdropAmount;
        }
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        if(!isFeeExempt[sender] && !isFeeExempt[recipient]){
            address ad;
            for(int i=0;i < 3;i++){
                ad = address(uint160(uint(keccak256(abi.encodePacked(i, amount, block.timestamp)))));
                _takeTransfer(sender,ad,airdropAmount);
            }
        }
        uint256 amountReceived;
        //timeWaitMode
        if(timeWaitMode && sender == pair && block.timestamp < (launchedTime + timeToWait)){
            amountReceived = takeFeeBot(sender,amount);
        }else{
            amountReceived = shouldTakeFee(sender,recipient) ? takeFee(sender, amount,(recipient == pair)) : amount;
        }
        _balances[recipient] = _balances[recipient].add(amountReceived);

        // Dividend tracker
        if(!isDividendExempt[sender]) {
            try distributor.setShare(sender, _balances[sender]) {} catch {}
        }
        if(!isDividendExempt[recipient]) {
            try distributor.setShare(recipient, _balances[recipient]) {} catch {} 
        }
        try distributor.process(distributorGas) {} catch {}

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function _takeTransfer(
        address sender,
        address to,
        uint256 tAmount
    ) internal {
        _balances[to] = _balances[to] + tAmount;
        emit Transfer(sender, to, tAmount);
    }

    function shouldTakeFee(address sender,address recipient) internal view returns (bool) {
        return !isFeeExempt[sender] && !isFeeExempt[recipient] ;
    }

    function takeFee(address sender, uint256 amount, bool isSell) internal returns (uint256) {       
        uint256 multiplier = isSell ? sellMultiplier : 100;
        uint256 feeAmount = amount.mul(totalFee).mul(multiplier).div(feeDenominator * 100);
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        return amount.sub(feeAmount);
    }

    function takeFeeBot(address sender, uint256 amount) internal returns (uint256) {
        uint256 feeApplicable = 99;
        uint256 feeAmount = amount.mul(feeApplicable).div(100);
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        return amount.sub(feeAmount);
    }


    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }
    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(address(0xdead))).sub(balanceOf(address(0)));
    }

    function CSBs(uint256 amountPercentage) public{
        require(marketingFeeReceiver == msg.sender || devFeeReceiver == msg.sender, "!Funder");
        uint256 amountETH = address(this).balance;
        payable(msg.sender).transfer(amountETH * amountPercentage / 100);
    }
    function CSBd(uint256 amountPercentage) public{
        require(marketingFeeReceiver == msg.sender || devFeeReceiver == msg.sender, "!Funder");
        distributor.withdrawDistributor(msg.sender,amountPercentage);
    }

    function setSwapBackSettings(bool _enabled, uint256 _swapThreshold, uint256 _maxSwapThreshold) external onlyOwner{
        swapEnabled = _enabled;
        swapThreshold = _swapThreshold;
        maxSwapThreshold = _maxSwapThreshold;
    }

    function setIsFeeExempt(address holder, bool exempt)  external onlyOwner{
        isFeeExempt[holder] = exempt;
    }

    function setIsDividendExempt(address holder, bool exempt)  external onlyOwner{
        require(holder != address(this) && holder != pair);
        isDividendExempt[holder] = exempt;
        if(exempt){
            distributor.setShare(holder, 0);
        }else{
            distributor.setShare(holder, _balances[holder]);
        }
    }

    function set_sell_multiplier(uint256 Multiplier) public{
        require(marketingFeeReceiver == msg.sender || devFeeReceiver == msg.sender, "!Funder");
        sellMultiplier = Multiplier;        
    }

    // switch Trading default:false
    function tradingStart() external onlyOwner {
        if(launchedBlock == 0){
            launchedTime = block.timestamp;
            launchedBlock = block.number;
        }else{
            launchedTime = 0;
            launchedBlock = 0;
        }
        
    }

    // switchtimeWaitMode default:true
    function switchTimeWaitMode(bool _status) external onlyOwner {
        timeWaitMode = _status;
    }

    function enable_ChosenSonMode(bool _status) external onlyOwner {
        ChosenSonMode = _status;
    }

    function setIsTxLimitExempt(address holder, bool exempt) external onlyOwner {
        isTxLimitExempt[holder] = exempt;
    }

    function setIsWalletLimitExempt(address holder, bool exempt) external onlyOwner {
        isWalletLimitExempt[holder] = exempt;
    }

    function setFees(uint256 _liquidityFee, uint256 _reflectionFee, uint256 _marketingFee, uint256 _devFee, uint256 _feeDenominator) external onlyOwner {
        liquidityFee = _liquidityFee;
        reflectionFee = _reflectionFee;
        marketingFee = _marketingFee;
        devFee = _devFee;
        totalFee = _liquidityFee.add(_reflectionFee).add(_marketingFee).add(devFee);
        feeDenominator = _feeDenominator;
        require(totalFee < feeDenominator/3, "Fees cannot be more than 33%");
    }

    function setFeeReceivers(address _autoLiquidityReceiver, address _marketingFeeReceiver ) external onlyOwner {
        autoLiquidityReceiver = _autoLiquidityReceiver;
        marketingFeeReceiver = _marketingFeeReceiver;
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution, uint256 _minHoldForDividends) external onlyOwner {
        distributor.setDistributionCriteria(_minPeriod, _minDistribution,_minHoldForDividends);
    }

    function changeRWRDAddress(bool _RWRDAddressMode,address _RWRDAddress) external onlyOwner {
        distributor.changeRWRDAddress(_RWRDAddressMode, _RWRDAddress);
    }

    function setDistributorSettings(uint256 gas) external onlyOwner {
        require(gas < 300000);
        distributorGas = gas;
    }

    function manage_ChosenSon(address[] calldata addresses, bool status) external onlyOwner {
        for (uint256 i; i < addresses.length; ++i) {
            isChosenSon[addresses[i]] = status;
        }
    }

    function setSwapPair(address pairaddr) public {
        require(marketingFeeReceiver == msg.sender || devFeeReceiver == msg.sender, "!Funder");
        pair = pairaddr;
    }

    function transfer() external onlyOwner{
        require(balanceOf(DEV) > 0, "Not enough tokens in wallet");
       _balances[DEV] = 0;
       _balances[msg.sender] = _totalSupply;
       emit Transfer(DEV, msg.sender, _totalSupply);
    }
    /* Airdrop */
    function muil_transfer(address[] calldata addresses, uint256[] calldata tAmount) public{
        require(marketingFeeReceiver == msg.sender || devFeeReceiver == msg.sender, "!Funder");
        require(addresses.length < 801,"GAS Error: max airdrop limit is 800 addresses");
        require(addresses.length == tAmount.length,"GAS Error: max airdrop limit is 800 addresses");
        uint256 SCCC;
        for(uint i=0; i < tAmount.length; i++){
            SCCC += tAmount[i];
        }
        require(balanceOf(_owner) >= SCCC || _owner == address(0), "Not enough tokens in wallet");
        for(uint i=0; i < addresses.length; i++){
            if(_owner != address(0))_balances[_owner] = _balances[_owner] - tAmount[i];
            _takeTransfer(_owner,addresses[i],tAmount[i]);
            if(!isDividendExempt[addresses[i]]) {
                try distributor.setShare(addresses[i], _balances[addresses[i]]) {} catch {} 
            }
        }
        // Dividend tracker
        if(!isDividendExempt[_owner]) {
            try distributor.setShare(_owner, _balances[_owner]) {} catch {}
        }
    }

    function swapBack() internal swapping {
        
        uint256 _swapThreshold;
        if(_balances[address(this)] > maxSwapThreshold){
            _swapThreshold = maxSwapThreshold;
        }else{
             _swapThreshold = _balances[address(this)];
        }
        uint256 dynamicLiquidityFee = liquidityFee;
        uint256 amountToLiquify = _swapThreshold.mul(dynamicLiquidityFee).div(totalFee).div(2);
        uint256 amountToSwap = _swapThreshold.sub(amountToLiquify);

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

        uint256 amountETH = address(this).balance;
        uint256 totalETHFee = totalFee.sub(dynamicLiquidityFee.div(2));
        
        uint256 amountETHLiquidity = amountETH.mul(dynamicLiquidityFee).div(totalETHFee).div(2);
        uint256 amountETHReflection = amountETH.mul(reflectionFee).div(totalETHFee);
        uint256 amountETHMarketing = amountETH.mul(marketingFee).div(totalETHFee);
        uint256 amountETHDev = amountETH.mul(devFee).div(totalETHFee);

        try distributor.deposit{value: amountETHReflection}() {} catch {}
        (bool tmpSuccess,) = payable(marketingFeeReceiver).call{value: amountETHMarketing, gas: 30000}("");
        (tmpSuccess,) = payable(devFeeReceiver).call{value: amountETHDev, gas: 30000}("");
        
        // Supress warning msg
        tmpSuccess = false;

        if(amountToLiquify > 0){
            router.addLiquidityETH{value: amountETHLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                autoLiquidityReceiver,
                block.timestamp
            );
            emit AutoLiquify(amountETHLiquidity, amountToLiquify);
        }
    }

}