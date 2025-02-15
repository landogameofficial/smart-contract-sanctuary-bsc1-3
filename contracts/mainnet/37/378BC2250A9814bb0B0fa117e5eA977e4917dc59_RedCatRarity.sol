// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import './Ownable.sol';
import "./IRedCat.sol";

contract RedCatRarity is Ownable {

    // constants
    IRedCat RedCatContract = IRedCat(0x4eac4292cA228708fFA69a3f320A81a01580aCF3);

    // attributes
    mapping (uint => uint) redCatRarity;

    // modifier
    modifier onlyHolder(uint tokenId) {
        require(msg.sender == RedCatContract.ownerOf(tokenId) , "not yours");
        _;
    }

    // event
    event Unboxing(uint indexed tokenId, uint indexed rarity);
    event FixRarity(uint indexed tokenId, uint indexed rarity);

    // unboxing
    function unboxing(uint _tokenId, uint _rarity) external onlyHolder(_tokenId) {
        ( , bool unboxed) = RedCatContract.getUnboxing(_tokenId);
        require(!unboxed, "already unboxed");
        require(_rarity < 5, "invalid rarity");

        RedCatContract.unboxing(_tokenId, _rarity);
        redCatRarity[_tokenId] = _rarity;
        emit Unboxing(_tokenId, _rarity);
    }

    // only owner
    function fixRarity(uint _tokenId, uint _rarity) external onlyOwner {
        redCatRarity[_tokenId] = _rarity;
        emit FixRarity(_tokenId, _rarity);
    }

    function migration(uint _start, uint _end) public onlyOwner {
        for(uint i = _start; i <= _end; i++) {
            (uint tokenId, uint rarity) = RedCatContract.getRarity(i);
            redCatRarity[tokenId] = rarity;
        }
    }

    // getter
    function getRarity(uint _tokenId) external view returns (uint rarity) {
        require(_tokenId < RedCatContract.totalSupply(), "over totalSupply");
        rarity = redCatRarity[_tokenId];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Ownable {
    // attributes
    address private _owner;

    // modifier
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    // event
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(msg.sender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IRedCat {
    function totalSupply() external view returns (uint);
    function getRarity(uint tokenId) external view returns (uint, uint);
    function ownerOf(uint tokenId) external view returns (address);
    function getUnboxing(uint tokenId) external view returns (uint, bool);
    function unboxing(uint tokenId, uint rarity) external;
}