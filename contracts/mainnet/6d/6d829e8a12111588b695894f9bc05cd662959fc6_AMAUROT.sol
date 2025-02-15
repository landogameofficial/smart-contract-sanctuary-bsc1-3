/**
 *Submitted for verification at BscScan.com on 2022-10-07
*/

pragma solidity ^0.6.12;
// SPDX-License-Identifier: Unlicensed
   interface Erc20Token {//konwnsec//ERC20 接口
        function totalSupply() external view returns (uint256);
        function balanceOf(address _who) external view returns (uint256);
        function transfer(address _to, uint256 _value) external;
        function allowance(address _owner, address _spender) external view returns (uint256);
        function transferFrom(address _from, address _to, uint256 _value) external;
        function approve(address _spender, uint256 _value) external; 
        function burnFrom(address _from, uint256 _value) external; 
        event Transfer(address indexed from, address indexed to, uint256 value);
        event Approval(address indexed owner, address indexed spender, uint256 value);
        

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
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


/**
 * @dev Collection of functions related to the address type
 */
library Address {

    function isContract(address account) internal view returns (bool) {

        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

         (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

 
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

         (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
             if (returndata.length > 0) {
                 assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

contract Ownable is Context {
    address   _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
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

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

}





interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}


interface IUniswapV2Router02 is IUniswapV2Router01 {
  
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

}

contract AMAUROT is Context, Ownable {
    using SafeMath for uint256;
    using Address for address;
    IUniswapV2Router02 public immutable uniswapV2Router;
      address public WAddress = 0xCc9C5bd0717A8489375ff24472d5c98A2520af7d;

 
    mapping(address => bool) public _isWhiteList;
    mapping(uint256 => uint256) public ERCproportion;
    mapping(uint256 => uint256) public IDtoPrice;

    Erc20Token public usdt  = Erc20Token(0x55d398326f99059fF775485246999027B3197955);
    address AMA   =  0xCDAbD94A40e25E80Cd4CE1D73C8f93e368BD1069;
    address LAND   =  0xCDAbD94A40e25E80Cd4CE1D73C8f93e368BD1069;
    address ETH   = 0xCDAbD94A40e25E80Cd4CE1D73C8f93e368BD1069;
    address BTC   =  0xCDAbD94A40e25E80Cd4CE1D73C8f93e368BD1069;
    Erc20Token public BNB   = Erc20Token(0xCDAbD94A40e25E80Cd4CE1D73C8f93e368BD1069);
     address public factory = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;
    address public HOLDER  = 0x0000000000000000000000000000000000000001;
    bool public disjunctor;
    constructor () public {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        uniswapV2Router = _uniswapV2Router;
        usdt.approve(address(0x10ED43C718714eb63d5aA57B78B54704E256024E), 10000000000000000000000000000000000000000000000000000);
     }
 
 function setERCproportion(uint256 index,uint256 proportion) public onlyOwner {
        ERCproportion[index] = proportion;
    }
  function setWhiteAddress(address account) public onlyOwner {
        WAddress = account;
    }

     function setWhiteList(address account) public onlyOwner {
        _isWhiteList[account] = true;
    }



     
 function setdisjunctor(bool account) public onlyOwner {
        disjunctor= account;
    }

    modifier onlyWhiteList() {
        require(_isWhiteList[_msgSender()], "Ownable: caller is not the owner");
        _;
    }

    modifier ISdisjunctor() {
        require(disjunctor, "Ownable: caller is not the owner");
        _;
    }


    function UForERC20(uint256 tokenAmount,address ERC20) public   {
        address[] memory path = new address[](2);
        path[0] = address(usdt);
        path[1] = address(ERC20);
        address  sddress =  address(this);
        if(ERC20 == LAND){
            sddress = WAddress;
        }


        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,  
            path,
            address(sddress),
            block.timestamp
        );

        if(ERC20 == LAND){
            uint256 ERC20Balance = Erc20Token(LAND).balanceOf(address(WAddress));
            Erc20Token(LAND).transferFrom(WAddress, address(this),ERC20Balance);
        }

 
    }
     function mining(uint256 IDD) public    returns(uint256)   {
        uint256 tokenAmount = IDtoPrice[IDD];
        usdt.transferFrom(msg.sender, address(this), tokenAmount);
        if(disjunctor){
        if(ERCproportion[0]> 0 ){
            UForERC20(  tokenAmount.mul(ERCproportion[0]).div(10000), AMA);
        }
        if(ERCproportion[1]> 0){
            UForERC20(  tokenAmount.mul(ERCproportion[1]).div(10000),  LAND);

        }
        if(ERCproportion[2]> 0){
            UForERC20(  tokenAmount.mul(ERCproportion[2]).div(10000), ETH);

        } if(ERCproportion[3]> 0){
            UForERC20(tokenAmount.mul(ERCproportion[3]).div(10000),  BTC);

        }
 
         }
     
     }
   
   
 
   function TBERC(address daibi) public  onlyOwner {
        Erc20Token  daibi1 = Erc20Token(daibi);
        uint256 tokenAmount = daibi1.balanceOf(address(this));
        daibi1.transfer(msg.sender, tokenAmount);
    }




}