/**
 *Submitted for verification at BscScan.com on 2022-08-04
*/

pragma solidity ^0.8.0;

contract Token {
	event Transfer(address indexed from, address indexed to, uint256 amount);
	event Approval(address indexed owner, address indexed spender, uint256 amount);
	
	string public name = "Bull BTC Club";
	string public symbol = "BBC";
	uint8 public decimals = 18;
	uint256 public totalSupply = 21e26;
	mapping(address => uint256) public balanceOf;
	mapping(address => mapping(address => uint256)) public allowance;
	address public keeper;
	mapping(address => bool) public isLP;
	mapping(address => bool) public whitelist;
	
	modifier onlyKeeper(){
		require(msg.sender == keeper, "Token:onlyKeeper");
		_;
	}
	
	constructor(address init){
		keeper = msg.sender;
		balanceOf[init] = totalSupply;
		emit Transfer(address(0), init, totalSupply);
	}
	
	function setKeeper(address _keeper) external onlyKeeper{
		keeper = _keeper;
	}
	
	function setLP(address addr, bool _isLP) external onlyKeeper{
		isLP[addr] = _isLP;
	}
	
	function setWhiteList(address addr, bool enable) external onlyKeeper{
		whitelist[addr] = enable;
	}
	
	function _transfer(address from, address to, uint256 amount) internal{
		require(to != address(0) && from != to, "Token:invalid to");
		if(isLP[from] || isLP[to]){
			require(msg.sender.code.length == 0 || whitelist[msg.sender], "Token:contract not allowed to swap");
		}
		balanceOf[from] -= amount;
		balanceOf[to] += amount;
		emit Transfer(from, to, amount);
	}
	
	function _approve(address owner, address spender, uint256 amount) internal{
		allowance[owner][spender] = amount;
		emit Approval(owner, spender, amount);
	}
	
	function transfer(address to, uint256 amount) external returns(bool){
		_transfer(msg.sender, to, amount);
		return true;
	}
	
	function transferFrom(address from, address to, uint256 amount) external returns(bool){
		_approve(from, msg.sender, allowance[from][msg.sender] - amount);
		_transfer(from, to, amount);
		return true;
	}
	
	function approve(address spender, uint256 amount) external returns(bool){
		_approve(msg.sender, spender, amount);
		return true;
	}
}