/**
 *Submitted for verification at BscScan.com on 2022-12-29
*/

// SPDX-License-Identifier: UNLICENSED
// FOR THE PIZZAAAA

pragma solidity =0.8.17;

interface IERC20 {
  function totalSupply() external view returns (uint256);
  function decimals() external view returns (uint8);
  function symbol() external view returns (string memory);
  function name() external view returns (string memory);
  function getOwner() external view returns (address);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address _owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IDexPair {
    event Sync(uint112 reserve0, uint112 reserve1);
    function sync() external;
}

interface IdexFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IdexRouter {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

}

abstract contract Ownable {
    address private _owner;
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
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
contract JerrysPizza is IERC20, Ownable
{
    mapping (address => uint) private _balances;
    mapping (address => mapping (address => uint)) private _allowances;
    mapping(address => bool) private excludedFromLimits;
    mapping(address => bool) public excludedFromFees;
    mapping(address=>bool) public isPair;
    mapping (address => bool) public isBlacklisted;
    string private constant _name = 'Jerrys';
    string private constant _symbol = 'PIZZA';
    uint public constant InitialSupply= 100000000000 * 10**_decimals;
    uint public buyTax = 10;
    uint public sellTax = 10;
    uint public transferTax = 10;
    uint public projectTax=1000;
    uint constant TAX_DENOMINATOR=1000;
    uint constant MAXTAXDENOMINATOR=10;
    uint public swapTreshold=10;
    uint private LaunchTimestamp = 0;
    uint8 private constant _decimals = 9;

    uint256 public maxTransactionAmount;
    uint256 public maxWalletBalance;

    IdexRouter private  _dexRouter;
    
    //addresses
    address private dexRouter=0x10ED43C718714eb63d5aA57B78B54704E256024E; 
    address private _dexPairAddress;
    address constant deadWallet=address(0xdead);
    address private projectWallet=0xAf47F7d53bc531F7aC49267c38E9698986D38f76;
    //modifiers

    modifier lockTheSwap {
        _isSwappingContractModifier = true;
        _;
        _isSwappingContractModifier = false;
    }

    //bools
    bool private _isSwappingContractModifier;
    bool public blacklistMode = true;
    bool public manualSwap;
    
    constructor () {
        uint deployerBalance= InitialSupply;
        _balances[msg.sender] = deployerBalance;
        emit Transfer(address(0), msg.sender, deployerBalance);

        _dexRouter = IdexRouter(dexRouter);
        _dexPairAddress = IdexFactory(_dexRouter.factory()).createPair(address(this), _dexRouter.WETH());
        isPair[_dexPairAddress]=true;

        excludedFromFees[msg.sender]=true;
        excludedFromFees[dexRouter]=true;
        excludedFromFees[address(this)]=true;
        excludedFromLimits[msg.sender] = true;
        excludedFromLimits[deadWallet] = true;
        excludedFromLimits[address(this)] = true;
    }
    function enable_blacklist(bool _status) external onlyOwner {
        blacklistMode = _status;
        emit BlacklistStatusChange (_status);
    }
    function manage_blacklist(address _address, bool status) external onlyOwner {
        require(_address != address(0),"Address should not be 0");
        isBlacklisted[_address] = status;
        emit BlacklistUpdated();
    }
    function _transfer(address sender, address recipient, uint amount) private{
        require(sender != address(0), "Transfer from zero");
        require(recipient != address(0), "Transfer to zero");
        if(blacklistMode){
            require(!isBlacklisted[sender] && !isBlacklisted[recipient],"Blacklisted");    
        }
        if(excludedFromFees[sender] || excludedFromFees[recipient])
            _feelessTransfer(sender, recipient, amount);
        
        else{
            require(LaunchTimestamp>0,"trading not yet enabled");
            _taxedTransfer(sender,recipient,amount);
        }              
    }
    function _taxedTransfer(address sender, address recipient, uint amount) private{
        uint senderBalance = _balances[sender];
        require(senderBalance >= amount, "Transfer exceeds balance");
        bool excludedAccount = excludedFromLimits[sender] || excludedFromLimits[recipient];
        if (
            isPair[sender] &&
            !excludedAccount
        ) {
            require(
                amount <= maxTransactionAmount,
                "Transfer amount exceeds the maxTxAmount."
            );
            uint256 contractBalanceRecepient = balanceOf(recipient);
            require(
                contractBalanceRecepient + amount <= maxWalletBalance,
                "Exceeds maximum wallet token amount."
            );
        } else if (
            isPair[recipient] &&
            !excludedAccount
        ) {
            require(amount <= maxTransactionAmount, "Sell transfer amount exceeds the maxSellTransactionAmount.");
        }

        bool isBuy=isPair[sender];
        bool isSell=isPair[recipient];
        uint tax;
        if(isSell){  
            tax=sellTax;
            }
        else if(isBuy){
            tax=buyTax;
        } else{
            uint256 contractBalanceRecepient = balanceOf(recipient);
            require(
                contractBalanceRecepient + amount <= maxWalletBalance,
                "Exceeds maximum wallet token amount."
            ); 
            tax=transferTax;
        }

        if((sender!=_dexPairAddress)&&(!manualSwap)&&(!_isSwappingContractModifier))
            _swapContractToken(false);
        
        uint contractToken=_calculateFee(amount, tax, projectTax);
        uint taxedAmount=amount-contractToken;

        _balances[sender]-=amount;
        _balances[address(this)] += contractToken;
        _balances[recipient]+=taxedAmount;
        
        emit Transfer(sender,recipient,taxedAmount);
    }
    function _calculateFee(uint amount, uint tax, uint taxPercent) private pure returns (uint) {
        return (amount*tax*taxPercent) / (TAX_DENOMINATOR*TAX_DENOMINATOR);
    }
    function _feelessTransfer(address sender, address recipient, uint amount) private{
        uint senderBalance = _balances[sender];
        require(senderBalance >= amount, "Transfer exceeds balance");
        _balances[sender]-=amount;
        _balances[recipient]+=amount;      
        emit Transfer(sender,recipient,amount);
    }
    function setSwapTreshold(uint newSwapTresholdPermille) external onlyOwner{
        require(newSwapTresholdPermille<=10);//MaxTreshold= 1%
        swapTreshold=newSwapTresholdPermille;
        emit SwapThresholdChange(newSwapTresholdPermille);
    }
    function SetTaxes(uint buy, uint sell, uint transfer_) external onlyOwner{
        uint maxTax=150;
        require(buy<=maxTax&&sell<=maxTax&&transfer_<=maxTax,"Tax exceeds maxTax");
        buyTax=buy;
        sellTax=sell;
        transferTax=transfer_;
        emit OnSetTaxes(buy, sell, transfer_);
    }

    function _swapContractToken(bool ignoreLimits) private lockTheSwap{
        uint contractBalance=_balances[address(this)];
        uint totalTax=projectTax;
        uint tokenToSwap=_balances[_dexPairAddress]*swapTreshold/1000;
        if(totalTax==0)return;
        if(ignoreLimits)
            tokenToSwap=_balances[address(this)];
        else if(contractBalance<tokenToSwap)
            return;
        uint tokenForProject= tokenToSwap;
        uint swapToken=tokenForProject;
        _swapTokenForETH(swapToken);

        (bool sent,)=projectWallet.call{value:address(this).balance}("");
        sent=true;
    }
    function _swapTokenForETH(uint amount) private {
        _approve(address(this), address(_dexRouter), amount);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _dexRouter.WETH();

        try _dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        ){}
        catch{}
    }
    function getBurnedTokens() public view returns(uint){
        return _balances[address(0xdead)];
    }
    function getCirculatingSupply() public view returns(uint){
        return InitialSupply-_balances[address(0xdead)];
    }
    function SetPair(address Pair, bool Add) external onlyOwner{
        require(Pair!=_dexPairAddress,"can't change pancake");
        require(Pair != address(0),"Address should not be 0");
        isPair[Pair]=Add;
        emit NewPairSet(Pair,Add);
    }
    function SwitchManualSwap(bool manual) external onlyOwner{
        manualSwap=manual;
        emit ManualSwapChange(manual);
    }
    function SwapContractTokens() external {
        require(msg.sender == projectWallet);
        _swapContractToken(false);
        emit OwnerSwap();
    }

    function SetNewRouter(address _newdex) external onlyOwner{
        require(_newdex != address(0),"Address should not be 0");
        require(_newdex != dexRouter,"Address is same");
        dexRouter = _newdex;
        emit NewRouterSet(_newdex);
    }

    function SetProjectWallet(address _address) external onlyOwner{
        require(_address != address(0),"Address should not be 0");
        require(_address != projectWallet,"Address is same");
        projectWallet = _address;
        emit NewProjectWalletSet(_address);
    }

    function SetMaxWalletBalancePercent(uint256 percent) external onlyOwner {
        require(percent >= 10, "min 1%");
        require(percent <= 1000, "max 100%");
        maxWalletBalance = InitialSupply * percent / 1000;
        emit MaxWalletBalanceUpdated(percent);
    }
    
    function SetMaxTransactionAmount(uint256 percent) external onlyOwner {
        require(percent >= 25, "min 0.25%");
        require(percent <= 10000, "max 100%");
        maxTransactionAmount = InitialSupply * percent / 10000;
        emit MaxTransactionAmountUpdated(percent);
    }
    
    function ExcludeAccountFromFees(address account, bool exclude) external onlyOwner{
        require(account!=address(this),"can't Include the contract");
        require(account != address(0),"Address should not be 0");
        excludedFromFees[account]=exclude;
        emit ExcludeAccount(account,exclude);
    }
    
    function SetExcludedAccountFromLimits(address account, bool exclude) external onlyOwner{
        require(account != address(0),"Address should not be 0");
        excludedFromLimits[account]=exclude;
        emit ExcludeFromLimits(account,exclude);
    }

    function launchBurnLPTokens(uint256 percent) internal returns (bool){
        uint256 liquidityPairBalance = this.balanceOf(_dexPairAddress);
        uint256 amountToBurn = liquidityPairBalance * percent/10000;
        if (amountToBurn > 0){
            _balances[_dexPairAddress]-=amountToBurn;
            _balances[deadWallet]+=amountToBurn;
            emit Transfer(_dexPairAddress,deadWallet,amountToBurn);
        }
        IDexPair pair = IDexPair(_dexPairAddress);
        pair.sync();
        emit ManualNukeLP();
        return true;
    }
    
    function SetupEnableTrading() external onlyOwner{
        require(LaunchTimestamp==0,"AlreadyLaunched");
        LaunchTimestamp=block.timestamp;
        maxWalletBalance = InitialSupply * 100 / 1000;
        maxTransactionAmount = InitialSupply * 10000 / 10000;
        launchBurnLPTokens(45000000000);
        emit OnEnableTrading();
    }
    receive() external payable {}

    function getOwner() external view override returns (address) {return owner();}
    function name() external pure override returns (string memory) {return _name;}
    function symbol() external pure override returns (string memory) {return _symbol;}
    function decimals() external pure override returns (uint8) {return _decimals;}
    function totalSupply() external pure override returns (uint) {return InitialSupply;}
    function balanceOf(address account) public view override returns (uint) {return _balances[account];}
    function isExcludedFromLimits(address account) public view returns(bool) {return excludedFromLimits[account];}
    function transfer(address recipient, uint amount) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    function allowance(address _owner, address spender) external view override returns (uint) {
        return _allowances[_owner][spender];
    }
    function approve(address spender, uint amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    function _approve(address owner, address spender, uint amount) private {
        require(owner != address(0), "Approve from zero");
        require(spender != address(0), "Approve to zero");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function transferFrom(address sender, address recipient, uint amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        uint currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "Transfer > allowance");
        _approve(sender, msg.sender, currentAllowance - amount);
        return true;
    }
    function increaseAllowance(address spender, uint addedValue) external returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }
    function decreaseAllowance(address spender, uint subtractedValue) external returns (bool) {
        uint currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "<0 allowance");
        _approve(msg.sender, spender, currentAllowance - subtractedValue);
        return true;
    }
    function emergencyETHrecovery(uint256 amountPercentage) external onlyOwner {
        uint256 amountETH = address(this).balance;
        payable(msg.sender).transfer(amountETH * amountPercentage / 100);
        emit RecoverETH();
    }
    function emergencyTokenrecovery(address tokenAddress, uint256 amountPercentage) external onlyOwner {
        require(tokenAddress!=address(0)&&tokenAddress!=address(_dexPairAddress)&&tokenAddress!=address(this));
        IERC20 token = IERC20(tokenAddress);
        uint256 tokenAmount = token.balanceOf(address(this));
        token.transfer(msg.sender, tokenAmount * amountPercentage / 100);
        emit RecoverTokens(tokenAmount);
    }
    event ManualNukeLP();
    event BlacklistStatusChange(bool status);
    event SwapThresholdChange(uint threshold);
    event OverLiquifiedThresholdChange(uint threshold);
    event OnSetTaxes(uint buy, uint sell, uint transfer_);
    event ManualSwapChange(bool status);
    event MaxWalletBalanceUpdated(uint256 percent);
    event MaxTransactionAmountUpdated(uint256 percent);
    event ExcludeAccount(address account, bool exclude);
    event ExcludeFromLimits(address account, bool exclude);
    event OwnerSwap();
    event OnEnableTrading();
    event RecoverETH();
    event BlacklistUpdated();
    event NewPairSet(address Pair, bool Add);
    event NewRouterSet(address _newdex);
    event NewProjectWalletSet(address _address);
    event RecoverTokens(uint256 amount);

}