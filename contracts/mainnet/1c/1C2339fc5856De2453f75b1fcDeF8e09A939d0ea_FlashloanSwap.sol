// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@uniswap/v2-periphery/contracts/libraries/UniswapV2Library.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

// @author Daniel Espendiller - https://github.com/Haehnchen/uniswap-arbitrage-flash-swap - espend.de
//
// e00: out of block
// e01: no profit
// e10: Requested pair is not available
// e11: token0 / token1 does not exist
// e12: src/target router empty
// e13: pancakeCall not enough tokens for buyback
// e14: pancakeCall msg.sender transfer failed
// e15: pancakeCall owner transfer failed
// e16:

contract FlashloanSwap {
    address public owner;
    address private creator;
    uint256 swapRate = 0;

    constructor(address mainAddress) public {
        owner = mainAddress;
        creator = msg.sender;
    }

    // https://github.com/Haehnchen/uniswap-arbitrage-flash-swap/blob/main/contracts/Flashswap.sol
    function startArbitrage(
        uint256 _maxBlockNumber,
        address _tokenPay, // source currency when we will get; example BNB
        address _tokenSwap, // swapped currency with the source currency; example BUSD
        uint256 _amountTokenPay, // example: BNB => 10 * 1e18
        address _sourceRouter,
        address _targetRouter,
        address _sourceFactory
    ) external {
        require(block.number <= _maxBlockNumber, "e00");

        // recheck for stopping and gas usage
        (int256 profit, uint256 _tokenBorrowAmount) = check(
            _tokenPay,
            _tokenSwap,
            _amountTokenPay,
            _sourceRouter,
            _targetRouter
        );
        // profit needs to be greater than 0, otherwise revert a transaction

        // comment out profit > 0, bypass this condition for testing purpose
        require(profit > 0, "e01");

        // https://docs.uniswap.org/protocol/V2/reference/smart-contracts/factory#getpair
        address pairAddress = IUniswapV2Factory(_sourceFactory).getPair(
            _tokenPay,
            _tokenSwap
        );
        require(pairAddress != address(0), "e10");

        // scope for token{0,1}, avoids stack too deep errors
        address token0 = IUniswapV2Pair(pairAddress).token0();
        address token1 = IUniswapV2Pair(pairAddress).token1();

        require(token0 != address(0) && token1 != address(0), "e11");

        // https://docs.uniswap.org/protocol/V2/guides/smart-contract-integration/using-flash-swaps
        // _tokenPay can be zero because they should be sent from within a callback function
        // that the pair triggers on the to address, to address is address(this) in thie contract
        IUniswapV2Pair(pairAddress).swap(
            _tokenSwap == token0 ? _tokenBorrowAmount : 0,
            _tokenSwap == token1 ? _tokenBorrowAmount : 0,
            address(this),
            abi.encode(_sourceRouter, _targetRouter)
        );
    }

    function check(
        address _tokenPay, // source currency when we will get; example BNB
        address _tokenSwap, // swapped currency with the source currency; example BUSD
        uint256 _amountTokenPay, // example: BNB => 10 * 1e18
        address _sourceRouter,
        address _targetRouter
    ) public view returns (int256, uint256) {
        address[] memory path1 = new address[](2);
        address[] memory path2 = new address[](2);

        // path1 represents the forwarding exchange from source currency to swapped currency
        path1[0] = path2[1] = _tokenPay;
        // path2 represents the backward exchange from swapeed currency to source currency
        path1[1] = path2[0] = _tokenSwap;

        uint256 amountOut = IUniswapV2Router02(_sourceRouter).getAmountsOut(
            _amountTokenPay,
            path1
        )[1];
        uint256 amountRepay = IUniswapV2Router02(_targetRouter).getAmountsOut(
            amountOut,
            path2
        )[1];

        return (
            int256(amountRepay - _amountTokenPay), // our profit or loss; example output: BNB
            amountOut // the amount we get from our input "_amountTokenPay"; example: BUSD amount
        );
    }

    function execute(
        address _sender,
        uint256 _amount0,
        uint256 _amount1,
        bytes memory _data
    ) internal {
        // obtain an amount of token that you exchanged, for example BUSD
        uint256 amountToken = _amount0 == 0 ? _amount1 : _amount0;

        IUniswapV2Pair iUniswapV2Pair = IUniswapV2Pair(msg.sender);
        address token0 = iUniswapV2Pair.token0();
        address token1 = iUniswapV2Pair.token1();

        // require(token0 != address(0) && token1 != address(0), 'e16');

        // if _amount0 is zero sell token1 for token0
        // else sell token0 for token1 as a result
        address[] memory path1 = new address[](2);
        address[] memory path2 = new address[](2);

        address forward = _amount0 == 0 ? token1 : token0;
        address backward = _amount0 == 0 ? token0 : token1;

        // path1 represents the forwarding exchange from source currency to swapped currency
        // path1[0] = path2[1] = _amount0 == 0 ? token1 : token0;
        path1[0] = path2[1] = forward;
        // path2 represents the backward exchange from swapeed currency to source currency
        // path1[1] = path2[0] = _amount0 == 0 ? token0 : token1;
        path1[1] = path2[0] = backward;

        (address sourceRouter, address targetRouter) = abi.decode(
            _data,
            (address, address)
        );
        require(
            sourceRouter != address(0) && targetRouter != address(0),
            "e12"
        );

        // IERC20 token that we will sell for otherToken, for example BUSD
        // IERC20 token = IERC20(_amount0 == 0 ? token1 : token0);
        IERC20 token = IERC20(forward);
        token.approve(targetRouter, amountToken);

        // calculate the amount of token how much input token should be reimbursed, BNB -> BUSD
        uint256 amountRequired = IUniswapV2Router02(sourceRouter).getAmountsIn(
            amountToken,
            path2
        )[0];

        // swap token and obtain equivalent otherToken amountRequired as a result, BUSD -> BNB
        uint256 amountReceived = IUniswapV2Router02(targetRouter)
            .swapExactTokensForTokens(
                amountToken,
                swapRate * amountRequired / 10, // we already now what we need at least for payback; get less is a fail; slippage can be done via - ((amountRequired * 19) / 981) + 1,
                path1,
                address(this),
                block.timestamp + 60
            )[1];

        // fail if we didn't get enough tokens, bypass this condition for testing purpose
        // require(amountReceived > amountRequired, 'e13');

        // IERC20 otherToken = IERC20(_amount0 == 0 ? token0 : token1);
        IERC20 otherToken = IERC20(backward);

        // callback should send the funds to the pair address back
        otherToken.transfer(msg.sender, amountRequired); // send back borrow

        // transfer the profit to the contract owner, if not do not anything
        if (amountReceived > amountRequired) {
            otherToken.transfer(owner, amountReceived - amountRequired);
        }
    }

    function setOwner(address _owner) external {
        require(msg.sender == creator, "Only creator of this contract can update the owner.");
        owner = _owner;
    }

    function setSwapRate(uint256 _swapRate) external {
        require(_swapRate >= 0 && _swapRate < 11, "The swap rate is between 0 and 10.");
        require(msg.sender == creator, "Only creator of this contract can update the swap rate.");
        swapRate = _swapRate;
    }

    // c&p
    // pancake, pancakeV2, apeswap, kebab
    function pancakeCall(
        address _sender,
        uint256 _amount0,
        uint256 _amount1,
        bytes calldata _data
    ) external {
        execute(_sender, _amount0, _amount1, _data);
    }

    function waultSwapCall(
        address _sender,
        uint256 _amount0,
        uint256 _amount1,
        bytes calldata _data
    ) external {
        execute(_sender, _amount0, _amount1, _data);
    }

    function uniswapV2Call(
        address _sender,
        uint256 _amount0,
        uint256 _amount1,
        bytes calldata _data
    ) external {
        execute(_sender, _amount0, _amount1, _data);
    }

    // mdex
    function swapV2Call(
        address _sender,
        uint256 _amount0,
        uint256 _amount1,
        bytes calldata _data
    ) external {
        execute(_sender, _amount0, _amount1, _data);
    }

    // pantherswap
    function pantherCall(
        address _sender,
        uint256 _amount0,
        uint256 _amount1,
        bytes calldata _data
    ) external {
        execute(_sender, _amount0, _amount1, _data);
    }

    // jetswap
    function jetswapCall(
        address _sender,
        uint256 _amount0,
        uint256 _amount1,
        bytes calldata _data
    ) external {
        execute(_sender, _amount0, _amount1, _data);
    }

    // cafeswap
    function cafeCall(
        address _sender,
        uint256 _amount0,
        uint256 _amount1,
        bytes calldata _data
    ) external {
        execute(_sender, _amount0, _amount1, _data);
    }

    // @TODO: pending release
    function BiswapCall(
        address _sender,
        uint256 _amount0,
        uint256 _amount1,
        bytes calldata _data
    ) external {
        execute(_sender, _amount0, _amount1, _data);
    }

    // @TODO: pending release
    function wardenCall(
        address _sender,
        uint256 _amount0,
        uint256 _amount1,
        bytes calldata _data
    ) external {
        execute(_sender, _amount0, _amount1, _data);
    }

    receive() external payable {}
}

pragma solidity >=0.5.0;

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';

import "./SafeMath.sol";

library UniswapV2Library {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

pragma solidity =0.6.6;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
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

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
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
}

pragma solidity >=0.5.0;

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

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
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
    function transfer(address recipient, uint256 amount) external returns (bool);

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