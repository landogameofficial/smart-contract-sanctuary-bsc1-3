/**
 *Submitted for verification at BscScan.com on 2022-08-28
*/

// KNIGHT TOKEN ©
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// Main coin information
contract KNGTToken {
    // Initialize addresses mapping
    mapping(address => uint) public balances;
    // Total supply (in this case 1000 tokens)
    uint public totalSupply = 500000000 * 10 ** 18;
    // Tokens Name
    string public name = "KNIGHT";
    // Tokens Symbol
    string public symbol = "KNGT";
    // Total Decimals (max 18)
    uint public decimals = 18;
    
    // Transfers
    event Transfer(address indexed from, address indexed to, uint value);
    
    // Event executed only ones uppon deploying the contract
    constructor() {
        // Give all created tokens to adress that deployed the contract
        balances[msg.sender] = totalSupply;
    }
    
    // Check balances
    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }
    
    // Transfering coins function
    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'Insufficient balance');
        balances[msg.sender] -= value;
        balances[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
}