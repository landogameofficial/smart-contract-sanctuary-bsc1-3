// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "openzeppelin-solidity/contracts/access/Ownable.sol";

interface IERC20 {
    function balanceOf(address owner) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);

    function transfer(address to, uint value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint value
    ) external returns (bool);
}

interface IWETH {
    function deposit() external payable;

    function withdraw(uint wad) external;
}

interface UniswapRouter {
    function WETH() external pure returns (address);

    function getAmountsOut(
        uint amountIn,
        address[] calldata path
    ) external view returns (uint[] memory amounts);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IUniswapPair {
    function swap(
        uint amount0Out,
        uint amount1Out,
        address to,
        bytes calldata data
    ) external;

    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

contract asd123 is Ownable {
    // pancake router
    address public router = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address weth = UniswapRouter(router).WETH();

    function getAmounts(address token, address lp, address token0) private view returns(uint256 amount0Out, uint256 amount1Out) {
        uint256 amountInput;
        uint256 amountOutput;
        {
            (uint256 reserve0, uint256 reserve1, ) = IUniswapPair(lp).getReserves();
            (uint256 reserveInput, uint256 reserveOutput) = token == token0
                ? (reserve0, reserve1)
                : (reserve1, reserve0);
            amountInput = IERC20(token).balanceOf(lp) - reserveInput;
            uint256 amountInWithFee = amountInput * 9975;
            uint256 numerator = amountInWithFee * reserveOutput;
            uint256 denominator = reserveInput * 10000 + amountInWithFee;
            amountOutput = numerator / denominator;
        }
        (amount0Out, amount1Out) = token == token0
            ? (uint256(0), amountOutput)
            : (amountOutput, uint256(0));
    }

    function xd(
        address token,
        address lp
    ) external payable onlyOwner {
        IWETH(weth).deposit{value: msg.value}();
        IERC20(weth).transfer(lp, msg.value);
        (address token0, ) = token < weth ? (token, weth) : (weth, token);

        (uint256 reserve0, uint256 reserve1, ) = IUniswapPair(lp).getReserves();
        (uint256 reserveInput, uint256 reserveOutput) = weth == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);

        uint amountInWithFee = msg.value * 9975;
        uint numerator = amountInWithFee * reserveOutput;
        uint denominator = reserveInput * 10000 + amountInWithFee;
        uint amountOut = numerator / denominator;

        (uint amount0Out, uint amount1Out) = weth == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
        IUniswapPair(lp).swap(amount0Out, amount1Out, address(this), new bytes(0));
        IERC20(token).transfer(lp, IERC20(token).balanceOf(address(this)));
        (amount0Out, amount1Out) = getAmounts(token, lp, token0);
        IUniswapPair(lp).swap(amount0Out, amount1Out, address(this), new bytes(0));
        uint256 wethReceived = IERC20(weth).balanceOf(address(this));
        IWETH(weth).withdraw(wethReceived);
        payable(msg.sender).transfer(wethReceived);
    }

    function withdrawTokens(
        address token,
        address to,
        uint amount
    ) external onlyOwner {
        IERC20(token).transfer(to, amount);
    }

    function withdrawETH(address payable to, uint amount) external onlyOwner {
        to.transfer(amount);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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