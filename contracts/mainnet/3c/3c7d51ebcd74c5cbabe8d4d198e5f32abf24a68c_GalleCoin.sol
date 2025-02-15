/**
 *  SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.17;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';

 
interface IDexFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IDexRouter {
     function factory() external pure returns (address);
     function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
     
} 

interface IDexPair{
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

contract FeeDelegate {
    constructor (address token) {
        IERC20(token).approve(msg.sender, uint(~uint256(0)));
    }
}

contract GalleCoin is IERC20,Ownable {
    
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    uint256 private _initSupply;
    string private _name;
    string private _symbol;
    
    uint256 public minToSell; 
    uint256 public minToDividen; 

    uint256 public tokenToDividen; 

    mapping(uint256=>address) public tokenDividenQueue; 
    uint256 public tokenDividenQueueMaxIndex; 
    uint256 public tokenDividenQueueOffset; 
    uint256[] private tokenDividenQueueSlot; 
    uint256 private tokenDividenQueueSlotIndex; 

    mapping(uint256=>address) public lpDividenQueue;
    uint256 public lpDividenQueueMaxIndex;
    uint256 public lpDividenQueueOffset;
    uint256[] private lpDividenQueueSlot;
    uint256 private lpDividenQueueSlotIndex;
    mapping(address=>uint256) public tokenDividenQueuedIndex;
    mapping(address=>uint256) public lpDividenQueuedIndex;

    uint256 public sellTaxFee; 
    uint256 public buyTaxFee;
    address public taxAddress0;
    address public taxAddress1;
    address public feeDelegate;

    uint256 public marketPart;
    uint256 public tokenPart;
    uint256 public lpPart;
    
    address public tokenPair;
    address public swapRouter;
    address public usdt;

    event SwapTokens(
        uint256 amountIn,
        address[] path
    );
    
    mapping(address => bool) public _isExcludedFromFee;
    mapping(address => bool) public _isExcludedFromDividen; 
    mapping(address => bool) public _blackLists;
    mapping(address => bool) public _buyWhiteLists;
    bool public buyStatus; 

    uint256 public lpDividenMaxCount;  
    uint256 public tokenDividenMaxCount; 

    uint256 public excludeLpShare;      
    uint256 public excludeTokenShare;   


    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor() {
        _name = "GalleCoin";
        _symbol = "GC";
        sellTaxFee = 500; 
        buyTaxFee = 500;
        address _router = 0x10ED43C718714eb63d5aA57B78B54704E256024E; 
        address _usdt = 0x55d398326f99059fF775485246999027B3197955;  
        feeDelegate = address(new FeeDelegate(_usdt)); 
        
        _totalSupply = 100000000*10**18;        
        _balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);
        
        _isExcludedFromFee[_msgSender()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromDividen[_msgSender()] = true;
        _isExcludedFromDividen[address(this)] = true;
        _buyWhiteLists[_msgSender()] = true;
        _buyWhiteLists[address(this)] = true;

        marketPart = 100; 
        tokenPart = 0; 
        lpPart = 9900; 
        minToSell = 5000*10**18; 
        minToDividen = 100*10**18; 
        tokenToDividen = 5000*10**18; 
        lpDividenMaxCount = 10;  
        tokenDividenMaxCount = 10;  

        taxAddress0 = _msgSender();
        taxAddress1 = _msgSender();
        setDex(_router,_usdt);

        
        _approve(_msgSender(), _router, uint(~uint256(0)));
    }
    
       
    function setDex(address _router,address _usdt) internal{
        IDexRouter dexRouter = IDexRouter(_router);
        address tokenA = address(this);
        address tokenB = _usdt;
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        if(IDexFactory(dexRouter.factory()).getPair(token0,token1)==address(0)){
            tokenPair = IDexFactory(dexRouter.factory())
            .createPair(tokenA, tokenB);
        }
        else{
            tokenPair = IDexFactory(dexRouter.factory()).getPair(token0,token1);
        }
        _isExcludedFromDividen[tokenPair] = true;
        _buyWhiteLists[tokenPair] = true;
        swapRouter = _router;
        usdt = _usdt;
    }   
    
    
    
    function setExcludeFromFee(address[] memory accounts,bool status) external onlyOwner{
        for(uint256 i=0;i<accounts.length;i++)
            _isExcludedFromFee[accounts[i]] = status;
    }

    
    function setExcludeFromDividen(address[] memory accounts,bool status) external onlyOwner{
        for(uint256 i=0;i<accounts.length;i++)
            _isExcludedFromDividen[accounts[i]] = status;
    }


    
    function setBlackLists(address[] memory accounts,bool status) external onlyOwner{
        for(uint256 i=0;i<accounts.length;i++)
            _blackLists[accounts[i]] = status;
    }

   
    function setBuyWhiteLists(address[] memory accounts,bool status) external onlyOwner{
        for(uint256 i=0;i<accounts.length;i++)
            _buyWhiteLists[accounts[i]] = status;
    }
    
    function setTaxAddress(address _taxAddress0,address _taxAddress1) external onlyOwner{
        taxAddress0 = _taxAddress0;
        taxAddress1 = _taxAddress1;
    }

    
    function setMinToSell(uint256 _min) external onlyOwner{
        minToSell = _min;
    }

    
    function setMinToDividen(uint256 _min) external onlyOwner{
        minToDividen = _min;
    }
    
   
    function setTokenToDividen(uint256 _minHold) external onlyOwner{
        tokenToDividen = _minHold;
    }

    function setTax(uint256 _sellFee,uint256 _buyFee) external onlyOwner{
        require(_sellFee<=10000,"invalid sellFee");
        require(_buyFee<=10000,"infalid buyFee");
        sellTaxFee = _sellFee;
        buyTaxFee = _buyFee;
    }

    function setDividen(uint256 _marketPart,uint256 _tokenPart,uint256 _lpPart) external onlyOwner{
        require(_marketPart+_tokenPart+_lpPart==10000,"invalid percent");
        marketPart = _marketPart;
        tokenPart = _tokenPart;
        lpPart = _lpPart;
    }

    function setBuyStatus(bool status) external onlyOwner{
        buyStatus = status;
    }

    function setMaxCount(uint256 _lpDividenMaxCount,uint256 _tokenDividenMaxCount) external onlyOwner{
        lpDividenMaxCount = _lpDividenMaxCount;
        tokenDividenMaxCount = _tokenDividenMaxCount;
    }

    function setExcludedFromLpDividenShare(uint256 _excludeLpShare) external onlyOwner{
        excludeLpShare = _excludeLpShare;
    }

    function setExcludedFromTokenDividenShare(uint256 _excludeTokenShare) external onlyOwner{
        excludeTokenShare = _excludeTokenShare;
    }    
  
    function withdrawExternalToken(address _tokenAddress) external onlyOwner{        
        uint256 amount = IERC20(_tokenAddress).balanceOf(address(this));
        if(amount > 0){
            IERC20(_tokenAddress).safeTransfer(msg.sender,amount);
        }
    }

    function sendTaxFee(uint256 taxAmount) internal{
        uint256 fee0 = taxAmount.mul(5000).div(10000);
        IERC20(usdt).safeTransfer(taxAddress0,fee0);
        uint256 fee1 = taxAmount.sub(fee0);
        IERC20(usdt).safeTransfer(taxAddress1,fee1);
    }

    function _isAddLiquidity() internal view returns (bool isAdd){
        (uint r0,uint256 r1,) = IDexPair(tokenPair).getReserves();
        uint256 rUsdt;
        if (usdt < address(this)) {
            rUsdt = r0;
        } else {
            rUsdt = r1;
        }

        uint balUsdt = IERC20(usdt).balanceOf(tokenPair);
        isAdd = balUsdt > rUsdt;        
    }

    function _isRemoveLiquidity() internal view returns (bool isRemove){
        (uint r0,uint256 r1,) = IDexPair(tokenPair).getReserves();
        uint256 rUsdt;
        if (usdt < address(this)) {
            rUsdt = r0;
        } else {
            rUsdt = r1;
        }

        uint balUsdt = IERC20(usdt).balanceOf(tokenPair);
        isRemove = rUsdt >= balUsdt;
    }

    function swapTokens(uint256 tokenAmount) private returns(uint256 usdtAmount){
        IDexRouter _router = IDexRouter(swapRouter);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = usdt;

        _approve(address(this), swapRouter, tokenAmount);

        uint256 usdtBefore = IERC20(usdt).balanceOf(feeDelegate);
        _router.swapExactTokensForTokens(
            tokenAmount,
            0, 
            path,
            feeDelegate, 
            block.timestamp
        );        
        uint256 usdtAfter = IERC20(usdt).balanceOf(feeDelegate);
        usdtAmount = usdtAfter.sub(usdtBefore);
        IERC20(usdt).safeTransferFrom(feeDelegate,address(this),usdtAmount);
        emit SwapTokens(tokenAmount, path);
    }


    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(!_blackLists[sender]&&!_blackLists[recipient],"black list");
                
        bool doProcessDividen = true;  
        bool takeSellFee = false;
        if(recipient==tokenPair){ //sell or add
            if(!_isAddLiquidity()){
                takeSellFee = true;
            }  
            else{                
                doProcessDividen = false; //add liquid not div
                if(!_isExcludedFromDividen[sender]&&lpDividenQueuedIndex[sender]==0){ 
                    addToQueue(sender,true);
                }
            }          
        }
        if (_isExcludedFromFee[sender]) {
            takeSellFee = false;
        }

        bool takeBuyFee = false;
        if(sender==tokenPair){ // buy or remove
            if(!_isRemoveLiquidity()){
                if(!buyStatus&&!_buyWhiteLists[recipient]){
                    revert("buy disable");
                }
                takeBuyFee = true;
            }           
            doProcessDividen = false; //remove liquid or buy not div                    
        }
        if (_isExcludedFromFee[recipient]) {
            takeBuyFee = false;
        }
                
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance.sub(amount);
        }   
        
        if(takeSellFee&&sellTaxFee>0){
            uint256  _sellTaxFee = amount.mul(sellTaxFee).div(10000);
            _balances[address(this)] =_balances[address(this)].add(_sellTaxFee);                
            emit Transfer(sender, address(this), _sellTaxFee);
            amount = amount.sub(_sellTaxFee);
        }

        if(takeBuyFee&&buyTaxFee>0){
            uint256  _buyTaxFee = amount.mul(buyTaxFee).div(10000);
            _balances[address(this)] =_balances[address(this)].add(_buyTaxFee);
            emit Transfer(sender, address(this), _buyTaxFee);
            amount = amount.sub(_buyTaxFee);
        }

        if(doProcessDividen){
            if(_balances[address(this)]>=minToSell){
               uint256 usdtIncome = swapTokens(_balances[address(this)]);
               sendTaxFee(usdtIncome.mul(marketPart).div(10000)); //send maketing fee       
            }
            processDividen();         
        }
          
        
        _balances[recipient] = _balances[recipient].add(amount);    
        if(!_isExcludedFromDividen[recipient]&&_balances[recipient]>=tokenToDividen&&tokenDividenQueuedIndex[recipient]==0){ 
            addToQueue(recipient,false);
        }
        emit Transfer(sender, recipient, amount);
    }

    function addToQueue(address user,bool isLp) internal{
        if(isLp){
                uint256 _index = 0;
                if(lpDividenQueueSlotIndex<lpDividenQueueSlot.length){
                    _index = lpDividenQueueSlot[lpDividenQueueSlotIndex];
                    lpDividenQueueSlotIndex++;                    
                }
                else{
                    lpDividenQueueMaxIndex++;
                    _index = lpDividenQueueMaxIndex;
                }
                lpDividenQueue[_index] = user;
                lpDividenQueuedIndex[user] = _index;
        }
        else{
                uint256 _index = 0;
                if(tokenDividenQueueSlotIndex<tokenDividenQueueSlot.length){
                    _index = tokenDividenQueueSlot[tokenDividenQueueSlotIndex];
                    tokenDividenQueueSlotIndex++;                    
                }
                else{
                    tokenDividenQueueMaxIndex++;
                    _index = tokenDividenQueueMaxIndex;
                }
                tokenDividenQueue[_index] = user;
                tokenDividenQueuedIndex[user] = _index;              
        }        
    }

    function removeFromQueue(address user,bool isLp) internal{     
        if(isLp){
                uint256 _index = lpDividenQueuedIndex[user];
                lpDividenQueuedIndex[user] = 0;
                lpDividenQueue[_index] = address(0);
                lpDividenQueueSlot.push(_index);
        }
        else{
                uint256 _index = tokenDividenQueuedIndex[user];
                tokenDividenQueuedIndex[user] = 0;
                tokenDividenQueue[_index] = address(0);
                tokenDividenQueueSlot.push(_index);            
        }
    }

    function processDividen() internal{
        uint256 usdtBalance = IERC20(usdt).balanceOf(address(this));
        if(usdtBalance>=minToDividen){
            //process dividen
            //LP dividen        
            if(lpPart>0){
                if(lpDividenQueueOffset==lpDividenQueueMaxIndex){
                    lpDividenQueueOffset = 0;
                }
                uint256 lpDivideCounter = 0;
                uint256 totalLP = IERC20(tokenPair).totalSupply();
                totalLP = totalLP.sub(excludeLpShare);
                while(lpDivideCounter<lpDividenMaxCount&&lpDividenQueueOffset<lpDividenQueueMaxIndex){
                    lpDividenQueueOffset++;
                    lpDivideCounter++;
                    address user = lpDividenQueue[lpDividenQueueOffset];
                    uint256 userLp = IERC20(tokenPair).balanceOf(user);
                    if(!_isExcludedFromDividen[user]&&userLp>0){
                        uint256 lpBonus = usdtBalance.mul(lpPart).div(10000).mul(userLp).div(totalLP);
                        IERC20(usdt).safeTransfer(user,lpBonus);
                    }
                    else{
                        removeFromQueue(user,true);
                    }
                }    
            }    
            

            //token dividen    
            if(tokenPart>0){
               if(tokenDividenQueueOffset==tokenDividenQueueMaxIndex){
                    tokenDividenQueueOffset = 0;
                }
                uint256 tokenDivideCounter = 0;
                uint256 totalToken = _totalSupply.sub(excludeTokenShare).sub(_balances[tokenPair]);
                while(tokenDivideCounter<tokenDividenMaxCount&&tokenDividenQueueOffset<tokenDividenQueueMaxIndex){
                    tokenDividenQueueOffset++;
                    tokenDivideCounter++;
                    address user = tokenDividenQueue[tokenDividenQueueOffset];
                    uint256 userToken = _balances[user];
                    if(!_isExcludedFromDividen[user]&&userToken>=tokenToDividen){
                        uint256 tokenBonus = usdtBalance.mul(tokenPart).div(10000).mul(userToken).div(totalToken);
                        IERC20(usdt).safeTransfer(user,tokenBonus);
                    }
                    else{
                        removeFromQueue(user,false);
                    }
                }     
            } 
        }
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() external pure returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() external view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) external view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) external virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) external view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) external virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance.sub(subtractedValue));
        }

        return true;
    }
    

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
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
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}