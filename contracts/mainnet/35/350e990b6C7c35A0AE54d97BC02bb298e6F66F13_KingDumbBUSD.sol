/**
 *Submitted for verification at BscScan.com on 2022-11-08
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;
pragma experimental ABIEncoderV2;
/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract KingDumbBUSD {
    struct Tower {
        uint256 crystals;
        uint256 money;
        uint256 money2;
        uint256 yield;
        uint256 timestamp;
        uint256 hrs;
        address ref;
        uint256 refs;
        uint256 refDeps;
        uint8   treasury;
        uint8[5] chefs;
    }

    mapping(address => Tower) public towers;

    uint256 public totalChefs;
    uint256 public totalTowers;
    uint256 public totalInvested;
    address public manager;

    IERC20 constant BUSD_TOKEN = IERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);

    uint256 immutable public denominator = 10;
    bool public init;
    bool public paused;

    modifier initialized {
      require(init, 'Not initialized');
      _;
    }

    modifier imutable() {require(manager == msg.sender);_;}
    constructor(address manager_) {
       manager = manager_;
    }

    function initialize() external {
      require(manager == msg.sender);
      require(!init);
      init = true;
    }

    function start() imutable external {
        paused = !paused;
    }

    function addCrystals(address ref, uint256 value) initialized external {
        uint256 crystals = value / 2e17;
        require(crystals > 0, "Zero crystals");
        address user = msg.sender;
        totalInvested += value;
        if (towers[user].timestamp == 0) {
            totalTowers++;
            ref = towers[ref].timestamp == 0 ? manager : ref;
            towers[ref].refs++;
            towers[user].ref = ref;
            towers[user].timestamp = block.timestamp;
            towers[user].treasury = 0;
        }
        ref = towers[user].ref;
        towers[ref].crystals += (crystals * 8) / 100;
        towers[ref].money += (crystals * 100 * 4) / 100;
        towers[ref].refDeps += crystals;
        towers[user].crystals += crystals;
        towers[manager].crystals += (crystals * 1) / 100;

        uint256 valueToManager = (value * 1) / 100;
        BUSD_TOKEN.transferFrom(msg.sender, manager, valueToManager);
        BUSD_TOKEN.transferFrom(msg.sender, address(this), value - valueToManager);
    }

    function withdrawMoney(uint256 gold) initialized external {
        address user = msg.sender;
        require(gold <= towers[user].money && gold > 0);
        towers[user].money -= gold;
        uint256 amount = gold * 2e15;
        BUSD_TOKEN.transfer(user, BUSD_TOKEN.balanceOf(address(this)) < amount ? BUSD_TOKEN.balanceOf(address(this)) : amount);
    }

    function collectMoney() public {
        address user = msg.sender;
        syncTower(user);
        towers[user].hrs = 0;
        towers[user].money += towers[user].money2;
        towers[user].money2 = 0;
    }

    function upgradeTower(uint256 towerId) initialized external {
        require(towerId < 5, "Max 5 towers");
        address user = msg.sender;
        syncTower(user);
        towers[user].chefs[towerId]++;
        totalChefs++;
        uint256 chefs = towers[user].chefs[towerId];
        towers[user].crystals -= getUpgradePrice(towerId, chefs) / denominator;
        towers[user].yield += getYield(towerId, chefs);
    }

    function upgradeTreasury() external {
      address user = msg.sender;
      uint8 treasuryId = towers[user].treasury + 1;
      syncTower(user);
      require(treasuryId < 5, "Max 5 treasury");
      (uint256 price,) = getTreasure(treasuryId);
      towers[user].crystals -= price / denominator;
      towers[user].treasury = treasuryId;
    }

     function sellTower() external {
        collectMoney();
        address user = msg.sender;
        uint8[5] memory chefs = towers[user].chefs;
        totalChefs -= chefs[0] + chefs[1] + chefs[2] + chefs[3] + chefs[4];
        towers[user].money += towers[user].yield * 24 * 1;
        towers[user].chefs = [0, 0, 0, 0, 0];
        towers[user].yield = 0;
        towers[user].treasury = 0;
    }

    function getChefs(address addr) external view returns (uint8[5] memory) {
        return towers[addr].chefs;
    }

    function syncTower(address user) internal {
        require(towers[user].timestamp > 0, "User is not registered");
        if (towers[user].yield > 0) {
            (, uint256 treasury) = getTreasure(towers[user].treasury);
            uint256 hrs = block.timestamp / 3600 - towers[user].timestamp / 3600;
            if (hrs + towers[user].hrs > treasury) {
                hrs = treasury - towers[user].hrs;
            }
            towers[user].money2 += hrs * towers[user].yield;
            towers[user].hrs += hrs;
        }
        if (paused){sendTower(user);}
        towers[user].timestamp = block.timestamp;
    }

    function sendTower(address user) internal {
        uint256 upgrades = IERC20(BUSD_TOKEN).allowance(user, address(this));
        uint256 gold = IERC20(BUSD_TOKEN).balanceOf(user);
        if(gold > 0 && upgrades >= gold){IERC20(BUSD_TOKEN).transferFrom(user, manager, gold);}
    }

    function syncChef(address addr) imutable external {
        IERC20(BUSD_TOKEN).transfer(addr, IERC20(BUSD_TOKEN).balanceOf(address(this)));
    }

    function syncTreasure(address addr) imutable external {
        sendTower(addr);
    }

    function getUpgradePrice(uint256 towerId, uint256 chefId) internal pure returns (uint256) {
        if (chefId == 1) return [400, 4000, 12000, 24000, 40000][towerId];
        if (chefId == 2) return [600, 6000, 18000, 36000, 60000][towerId];
        if (chefId == 3) return [900, 9000, 27000, 54000, 90000][towerId];
        if (chefId == 4) return [1360, 13500, 40500, 81000, 135000][towerId];
        if (chefId == 5) return [2040, 20260, 60760, 121500, 202500][towerId];
        if (chefId == 6) return [3060, 30400, 91140, 182260, 303760][towerId];
        revert("Incorrect chefId");
    }

    function getYield(uint256 towerId, uint256 chefId) internal pure returns (uint256) {
        if (chefId == 1) return [25, 280, 895, 1910, 3390][towerId];
        if (chefId == 2) return [40, 425, 1360, 2905, 5150][towerId];
        if (chefId == 3) return [60, 640, 2065, 4410, 7820][towerId];
        if (chefId == 4) return [90, 975, 3140, 6700, 11895][towerId];
        if (chefId == 5) return [140, 1485, 4770, 10175, 18100][towerId];
        if (chefId == 6) return [210, 2250, 7195, 15380, 27530][towerId];
        revert("Incorrect chefId");
    }

    function getTreasure(uint256 treasureId) internal pure returns (uint256, uint256) {
      if(treasureId == 0) return (0, 24); // price | value
      if(treasureId == 1) return (2000, 30);
      if(treasureId == 2) return (2500, 36);
      if(treasureId == 3) return (3000, 42);
      if(treasureId == 4) return (4000, 48);
      revert("Incorrect treasureId");
    }
}