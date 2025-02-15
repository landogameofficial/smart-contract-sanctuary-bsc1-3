/**
 *Submitted for verification at BscScan.com on 2022-12-15
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/ReentrancyGuard.sol";
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}
interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library Address {
   
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

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

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library SafeERC20 {

    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector,spender,newAllowance));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),"SafeERC20: approve from non-zero to non-zero allowance");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

interface IPair {
    function totalSupply() external view returns (uint);
}

interface IPlanetRouter {

    function addLiquidity(address tokenA, address tokenB, uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin,
        address to,
        uint deadline) external returns (uint amountA, uint amountB, uint liquidity);
 
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline
    ) external returns (uint[] memory amounts);

    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
}

interface IWBNB is IERC20 {
    function deposit() external payable;
    function withdraw(uint256 wad) external;
}

interface StablePool {
    function add_liquidity(uint256[] memory amounts, uint256 min_mint_amount, address _lpTokenReceiver) external;
    function exchange(uint256 i, uint256 j, uint256 dx, uint256 min_dy, address receiver) external returns (uint256 dy);
    function remove_liquidity_one_coin(uint256 _token_amount, uint256 i, uint256 min_amount) external;
}


contract PlanetZap is ReentrancyGuard, Ownable, Pausable {
    using SafeERC20 for IERC20;

    address private constant wbnbAddress = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address private constant busdAddress = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;

    uint256 public goodwill = 0;
    uint256 routerDeadlineDuration = 300;
    
    mapping(address => bool) private verifiedRouter;

    constructor() {
    }

    receive() external payable {}
    
    function isVerified(address routerAddress) external view onlyOwner returns(bool){
        return verifiedRouter[routerAddress];
    }
    
    function setRouterVerified(address routerAddress) external onlyOwner{
        require(verifiedRouter[routerAddress] == false,"!!ROUTER_ALREADY_VERIFIED");
        verifiedRouter[routerAddress] = true;
    }


    function zapIn(
        address _fromTokenAddress,
        uint256 _amountIn,
        address[] memory _token0Path,
        address[] memory _token1Path,
        uint256 _slippageFactor,
        uint256 _minPoolTokens,
        address _LPRouterAddress
        ) external payable nonReentrant whenNotPaused {
        require(verifiedRouter[_LPRouterAddress] == true,"!!ROUTER_NOT_VERIFIED");

        uint256 halfAmount = _pullTokens(_fromTokenAddress, _amountIn)/2;

        ZapIn_internal(
            _fromTokenAddress,
            halfAmount,
            _token0Path,
            _token1Path,
            _slippageFactor,
            _minPoolTokens,
            _LPRouterAddress);

    }

    function zapInFrom3GStables(
        address _stablePoolAddress,
        uint256 _amountIn,
        uint[] calldata stableSwapPoolData,
        address[] memory _token0Path,
        address[] memory _token1Path,
        uint256 _slippageFactor,
        uint256 _minPoolTokens,
        address _LPRouterAddress
        ) external payable nonReentrant whenNotPaused {
    
        require(verifiedRouter[_LPRouterAddress] == true,"!!ROUTER_NOT_VERIFIED");

        uint256 amountToTransform = StablePool(_stablePoolAddress).exchange(stableSwapPoolData[0], stableSwapPoolData[1], _amountIn, stableSwapPoolData[2], address(this));

        address _fromTokenAddress = _token0Path[0];
        uint256 halfAmount = _pullTokens(_fromTokenAddress, amountToTransform)/2;


         ZapIn_internal(
            _fromTokenAddress,
            halfAmount,
            _token0Path,
            _token1Path,
            _slippageFactor,
            _minPoolTokens,
            _LPRouterAddress);
    }

    function zapInto3GStables(
        address _fromTokenAddress,
        uint256 _amountIn,
        address[] memory _pathToStableToken,
        uint256 slippageFactor,
        address _routerAddress,
        address _stablePoolAddress,
        uint256 _fromStableTokenIndex,
        uint256 _nCoins,
        uint256 _minPoolTokens
        ) external payable nonReentrant whenNotPaused {
        require(verifiedRouter[_routerAddress] == true,"!!ROUTER_NOT_VERIFIED");
        
        uint256 pulledAmount = _pullTokens(_fromTokenAddress, _amountIn);
        
        if (_fromTokenAddress == address(0)) {
            _wrapBNB();
            _fromTokenAddress = wbnbAddress;
        }

        uint256 token0Amt;        
        if (_pathToStableToken[_pathToStableToken.length - 1] != _fromTokenAddress)
            token0Amt = _safeSwap(_routerAddress, _fromTokenAddress, pulledAmount, _pathToStableToken, slippageFactor, address(this));
        else
            token0Amt = pulledAmount;
    
        address _fromStableTokenAddress = _pathToStableToken[_pathToStableToken.length - 1]; 
        _approveTokenIfNeeded(_fromStableTokenAddress, _stablePoolAddress);

        uint256[] memory liquidityAmount = new uint256[](_nCoins);

        for(uint i = 0; i < _nCoins; ++i){
            if(i == _fromStableTokenIndex)
                liquidityAmount[i] = token0Amt;
            else
                liquidityAmount[i] = 0;
        }

        StablePool(_stablePoolAddress).add_liquidity(liquidityAmount, _minPoolTokens, msg.sender);

    }

    function ZapIn_internal(
        address _fromTokenAddress,
        uint256 halfAmount,
        address[] memory _token0Path,
        address[] memory _token1Path,
        uint256 slippageFactor,
        uint256 _minPoolTokens,
        address _LPRouterAddress)
        internal {
        
        if (_fromTokenAddress == address(0)) {
            _wrapBNB();
            _fromTokenAddress = wbnbAddress;
        }

        address token0 = _token0Path[_token0Path.length-1];
        address token1 = _token1Path[_token1Path.length-1];


        uint256 token0Amt; uint256 token1Amt;
        if (token0 != _fromTokenAddress)
            token0Amt = _safeSwap(_LPRouterAddress, _fromTokenAddress, halfAmount, _token0Path, slippageFactor, address(this));
        else
            token0Amt = halfAmount;

        if (token1 != _fromTokenAddress)
            token1Amt = _safeSwap(_LPRouterAddress, _fromTokenAddress, halfAmount, _token1Path, slippageFactor, address(this));
        else 
            token1Amt = halfAmount;

        _approveTokenIfNeeded(token0, _LPRouterAddress);
        _approveTokenIfNeeded(token1, _LPRouterAddress);
        ( , , uint256 LPBought) = IPlanetRouter(_LPRouterAddress).addLiquidity(
            token0,
            token1,
            token0Amt,
            token1Amt,
            1,
            1,
            msg.sender,  
            block.timestamp + routerDeadlineDuration
        );

        require(LPBought >= _minPoolTokens, "ERR: High Slippage");
    }


       /*
        * convertedToken is address(0) if user want bnb;
        * convertedToken is wbnbAddress if user want wbnb;
        */

    function convertLiquidityToken(address wantAddress, uint256 wantAmount, address routerAddress, address[] memory path1, address[] memory path2, uint256 slippageFactor, uint256 minTokens) external nonReentrant  {

        convertLiquidityToken_internal (wantAddress, wantAmount, routerAddress, path1, path2, slippageFactor, minTokens, msg.sender);   

    }

    function convertLiquidityToStables(
        address wantAddress,
        uint256 wantAmount,
        address routerAddress,
        address[] memory path1,
        address[] memory path2, 
        uint256 slippageFactor,
        uint256 minNonStableTokens,
        address _stablePoolAddress,
        uint[] calldata stableSwapPoolData
       )
        external nonReentrant  {

        uint256 tokensReceived = convertLiquidityToken_internal (wantAddress, wantAmount, routerAddress, path1, path2, slippageFactor, minNonStableTokens, address(this));

        address _fromStableTokenAddress = path1[path1.length - 1]; 
        _approveTokenIfNeeded(_fromStableTokenAddress, _stablePoolAddress);

        StablePool(_stablePoolAddress).exchange(stableSwapPoolData[0], stableSwapPoolData[1], tokensReceived, stableSwapPoolData[2], msg.sender);
    }

    function convertLiquidityFromStables(
        address _stablePoolAddress,
        uint256 wantAmount,
        uint256 _stableTokenIndex,
        uint256 minStables,
        address routerAddress,
        address[] memory path1,
        uint256 slippageFactor,
        uint256 _minTokens)
        external nonReentrant{

        address _StableTokenAddress = path1[0]; 
        uint256 balBefore = IERC20(_StableTokenAddress).balanceOf(address(this));

        StablePool(_stablePoolAddress).remove_liquidity_one_coin(
            wantAmount,
            _stableTokenIndex,
            minStables);
        uint256 stablesReceived = IERC20(_StableTokenAddress).balanceOf(address(this)) - balBefore;
        uint256 output = stablesReceived;

        if (stablesReceived > 0 && path1.length > 1) { 
            (output) =_safeSwap(
                routerAddress,
                _StableTokenAddress,
                stablesReceived,
                path1,
                slippageFactor,
                msg.sender);      
        }

        require(output >= _minTokens, "ERR: High Slippage");
        /**
        Old code sends above swap to this address and then transfers to user
        if(convertedToken != address(0)){
            IERC20(convertedToken).safeTransfer(to,output);                    
        }
        else{
            _unwrapBNB(output);
            SafeERC20.safeTransferETH(to,output);
        }

        */
    }    


    function convertLiquidityToken_internal
        (address wantAddress,
        uint256 wantAmount,
        address routerAddress,
        address[] memory path1,
        address[] memory path2,
        uint256 slippageFactor,
        uint256 minTokens,
        address to) 
        internal returns (uint256 output) {     


        address token0 = path1[0];
        address token1 = path2[0];
    
        require(token0 != address(0),"token0 cannot be zero");
        require(token1 != address(0),"token1 cannot be zero");
        require(token0 != token1,"token0 and token1 address is same");

        IERC20(wantAddress).safeTransferFrom(
            address(msg.sender),
            address(this),
            wantAmount
        );        
        _approveTokenIfNeeded(wantAddress,routerAddress);  
        
        {
           /*
            * Avoid stack too deep errors
            */
            uint256 _wantAmount = wantAmount;
            address _routerAddress = routerAddress;
            address[] memory _path1 = path1;
            address[] memory _path2 = path2;
            uint256 _slippageFactor = slippageFactor;
            address _to = to;
    
            
            (uint token0Amt, uint token1Amt) = IPlanetRouter(_routerAddress).removeLiquidity(
                                                  _path1[0],
                                                  _path2[0],
                                                  _wantAmount,
                                                  1,
                                                  1,
                                                  address(this),
                                                  block.timestamp + routerDeadlineDuration);
                                                              
                                                              
            if (token0Amt > 0 && token1Amt > 0) { 

                if (_path1.length > 1){
                    
                    (token0Amt) =_safeSwap(
                        _routerAddress,
                        _path1[0],
                        token0Amt,
                        _path1,
                        _slippageFactor,
                        _to);      
                }
                
                if (_path2.length > 1){
                    
                    (token1Amt) =_safeSwap(
                        _routerAddress,
                        _path2[0],
                        token1Amt,
                        _path2,
                        _slippageFactor,
                        _to);                   
                }
            }

            output = token0Amt+token1Amt;
            require(output >= minTokens, "Err: High slippage");

        }   
    }

    
    function convertLpOutput (address wantAddress, uint256 wantAmount, address routerAddress, address[] memory _path1, address[] memory _path2) external view returns (uint256 output){

        address token0 = _path1[0];
        address token1 = _path2[0];
        
        uint256 wantAddToken0Bal = IERC20(token0).balanceOf(wantAddress);
        uint256 wantAddToken1Bal = IERC20(token1).balanceOf(wantAddress);
        uint256 wantTotalSupply = IPair(wantAddress).totalSupply();
        
        uint256 token0Amt = (wantAmount*wantAddToken0Bal)/(wantTotalSupply);
        uint256 token1Amt = (wantAmount*wantAddToken1Bal)/(wantTotalSupply);
             
            if (token0Amt > 0 && token1Amt > 0) {
                                
              
                if (_path1.length > 1){
                    (token0Amt) = IPlanetRouter(routerAddress).getAmountsOut(token0Amt,_path1)[_path1.length - 1];
                }
                
              
                if (_path2.length > 1){
                    (token1Amt) = IPlanetRouter(routerAddress).getAmountsOut(token1Amt,_path2)[_path2.length - 1];
                }
            
                 output = token0Amt + token1Amt;
            }
    }

    function _pullTokens(
        address token,
        uint256 amount
    ) internal returns (uint256 value) {
        uint256 totalGoodwillPortion;

        if (token == address(0)) {
            require(msg.value > 0, "No eth sent");

            // subtract goodwill
            totalGoodwillPortion = _subtractGoodwill(msg.value);

            return msg.value - totalGoodwillPortion;
        } else {
            require(amount > 0, "Invalid token amount");
            require(msg.value == 0, "BNB sent with token");

            IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

            totalGoodwillPortion = _subtractGoodwill(amount);

            return amount - totalGoodwillPortion;
        }
    }

    function _subtractGoodwill(uint256 amount) internal view returns (uint256 totalGoodwillPortion) {
        if (goodwill > 0) {
            totalGoodwillPortion = (amount*goodwill)/1000;
        }
    }


    function _safeSwap(
        address _routerAddress,
        address _from,
        uint256 _amountIn,
        address[] memory _path,
        uint256 slippageFactor,
        address _recipient
    ) private returns (uint256 amount) {
        _approveTokenIfNeeded(_from, _routerAddress);
        uint256 _amountOut = IPlanetRouter(_routerAddress).getAmountsOut(_amountIn, _path)[_path.length - 1];

        amount = IPlanetRouter(_routerAddress).swapExactTokensForTokens(
            _amountIn,
            (_amountOut*slippageFactor)/1000,
            _path,
            _recipient,
            block.timestamp + routerDeadlineDuration
        )[_path.length - 1];
        
        return amount;
    }


    function _approveTokenIfNeeded(address token, address _routerAddress) private {
        if (IERC20(token).allowance(address(this), _routerAddress) == 0) {
            IERC20(token).safeApprove(_routerAddress, type(uint256).max);
        }
    }

    function _wrapBNB() internal {
        uint256 bnbBal = address(this).balance;
        if (bnbBal > 0) {
            IWBNB(wbnbAddress).deposit{value: bnbBal}(); // BNB -> WBNB
        }
    }

    function _unwrapBNB(uint256 amount) internal virtual {
        // WBNB -> BNB
        if (amount > 0) {
            IWBNB(wbnbAddress).withdraw(amount); // WBNB -> BNB
        }
    }


    function setGoodwill(uint16 _goodwill) public onlyOwner {
        require(
            _goodwill >= 0 && _goodwill <= 100,
            "Invalid goodWill value"
        );
        goodwill = _goodwill;
    }

    function withdrawTokens(address[] calldata tokens) external onlyOwner {
        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 qty;

            if (tokens[i] == address(0)) {
                qty = address(this).balance;
                Address.sendValue(payable(owner()), qty);
            } else {
                qty = IERC20(tokens[i]).balanceOf(address(this));
                IERC20(tokens[i]).safeTransfer(owner(), qty);
            }
        }
    }
}