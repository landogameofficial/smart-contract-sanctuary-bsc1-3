// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "./Whitelist.sol";
import "./BeinGiveTake.sol";
import "./BICRight.sol";
import "./Priority.sol";

contract PrivateV2 is Context, AccessControlEnumerable {
    // whitelist ROLE
    bytes32 public constant WHITELIST_PRIVATE_SALE = keccak256("WHITELIST_PRIVATE_SALE");
    bytes32 public constant WHITELIST_CORE_TEAM = keccak256("WHITELIST_CORE_TEAM");

    // Private sale ROLE
    bytes32 public constant MODERATOR_CONTRACT = keccak256("MODERATOR_CONTRACT");

    constructor(address bicAddr, address birAddr, address bgtAddr, address busdAddr, address whitelistAddr, address priorityAddr) {
        address adminAddress = _msgSender();
        _setupRole(DEFAULT_ADMIN_ROLE, adminAddress);
        _setupRole(MODERATOR_CONTRACT, adminAddress);

        bicToken = IERC20(bicAddr);
        birToken = BICRight(birAddr);
        bgtToken = BeinGiveTake(bgtAddr);
        busdToken = IERC20(busdAddr);
        whitelistContract = Whitelist(whitelistAddr);
        priorityContract = Priority(priorityAddr);

        // init
        rateAirdropByBurnBIR = Fraction(24, 100);
        rateAirdropForCore = Fraction(10, 100);
        // 0.033
        price = Fraction(33, 1000);
        // refer: https://www.epochconverter.com/
        // Saturday, August 6, 2022 6:00:00 GMT+07:00
        priorityStartTime = 1659740400;
        // Monday, August 8, 2022 20:00:00 GMT+07:00
        officialStartTime = 1659963600;

        // bic 0%; bir, bgt, busd 10%
        rateAirdropForRef = RateRef(Fraction(0, 100), Fraction(10, 100), Fraction(10, 100), Fraction(10, 100));
        isPause = false;

        ownerAddress = address(0x26fd28835377154728D5FC159a0f6681cd11a006);
        airdropCoreTeamAddress = address(0x3DC4Bd62602972BA7fD58f10453cADab82E0e426);
    }

    using SafeMath for uint256;
    IERC20 public bicToken;
    BICRight public birToken;
    BeinGiveTake public bgtToken;
    IERC20 public busdToken;
    Whitelist public whitelistContract;
    Priority public priorityContract;

    Fraction public rateAirdropByBurnBIR;
    Fraction public rateAirdropForCore;
    Fraction public price;
    uint256 public priorityStartTime;
    uint256 public officialStartTime;
    uint256 public priorityEndTime;
    uint256 public officialEndTime;
    RateRef public rateAirdropForRef;
    bool public isPause;
    address public ownerAddress;
    address public airdropCoreTeamAddress;
    address public airdropRefAddress;

    struct Fraction {
        uint256 numerator;
        uint256 denominator;
    }

    struct RateRef {
        Fraction bic;
        Fraction bir;
        Fraction bgt;
        Fraction busd;
    }

    event BuySuccess(address _userAddr, address _refAddr, uint256 _spentBUSD, uint256 _bicByBUSD, uint256 _burnBIR, uint256 _bicAirdropByBurnBIR, uint256 _bicAirdropForCore, uint256 _time);

    event UpdateAirdropCoreTeamAddress(address _airdropCoreTeamAddress, uint256 _time);
    event UpdateAirdropRefAddress(address _airdropRefAddress, uint256 _time);
    event UpdateWhitelistAddress(address _whitelistAddress, uint256 _time);
    event UpdatePriorityAddress(address _priorityAddress, uint256 _time);
    event UpdateRateAirdrop(Fraction _rateAirdropByBurnBIR, Fraction _rateAirdropForCore, uint256 _time);
    event UpdateConfigSale(Fraction _price, uint256 _priorityStartTime, uint256 _priorityEndTime, uint256 _officialStartTime, uint256 _officialEndTime, uint256 _time);
    event UpdateRateRef(RateRef _rateRef, uint256 _time);
    event SetIsPause(bool _isPause, uint256 _time);
    event UpdateOwner(address _ownerAddress, uint256 _time);
    event WithdrawToken(address _token, uint256 _amount, address _receiver, uint256 _time);

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /** @dev expectResult: expect result when user spent BUSD, BIR to receive BIC
      * @param spentBUSD: BUSD user spent
      * @param spentBIR: BIR user spent (if spentBIR = 0, don't burn BIR)

      * @return bicByBUSD: BIC user receive by spent BUSD
      * @return burnBIR: BIR user will burn
      * @return bicAirdropByBurnBIR: BIC user receive by burn BIR
      */
    function expectResult(uint256 spentBUSD, uint256 spentBIR) public view returns (uint256, uint256, uint256) {
        // bicByBUSD = spentBUSD / price
        uint256 bicByBUSD = spentBUSD.mul(price.denominator).div(price.numerator);
        uint256 burnBIR = 0;
        uint256 bicAirdropByBurnBIR = 0;
        uint256 remainBIC = bicToken.balanceOf(address(this));
        if (spentBIR > 0) {
            // (r)emainBIC/(1+rateAirdropByBurnBIR(n/d)) = r / (1 + n/d) = r / ( (d + n)/d ) = (r * d) / (d + n)
            uint256 maxBIRByRemainBIC = remainBIC.mul(rateAirdropByBurnBIR.denominator).div(rateAirdropByBurnBIR.denominator.add(rateAirdropByBurnBIR.numerator));
            burnBIR = min(min(spentBIR, bicByBUSD), maxBIRByRemainBIC);
            // bicAirdropByBurnBIR = burnBIR * rateAirdropByBurnBIR
            bicAirdropByBurnBIR = burnBIR.mul(rateAirdropByBurnBIR.numerator).div(rateAirdropByBurnBIR.denominator);
        }
        return (bicByBUSD, burnBIR, bicAirdropByBurnBIR);
    }

    /** @dev handleTransfer: handle transfer BUSD, BIC, BIR, BGT
      * @param userAddr: user address
      * @param refAddr: referral address
      * @param spentBUSD: BUSD user spent
      * @param bicByBUSD: BIC user receive by spent BUSD
      * @param burnBIR: BIR user will burn
      * @param bicAirdropByBurnBIR: BIC user receive when burn BIR
      * @param bicAirdropForCore: BIC user receive if core team
      */
    function handleTransfer(address userAddr, address refAddr, uint256 spentBUSD, uint256 bicByBUSD, uint256 burnBIR, uint256 bicAirdropByBurnBIR, uint256 bicAirdropForCore) private {
        // bicUserReceive: BIC user receive by spent BUSD and burn BIR
        uint256 bicUserReceive = bicByBUSD.add(bicAirdropByBurnBIR);
        // refBIC, refBIR, refBGT, refBUSD: BIC, BIR, BGT, BUSD for referral
        uint256 refBIC = bicByBUSD.mul(rateAirdropForRef.bic.numerator).div(rateAirdropForRef.bic.denominator);
        uint256 refBIR = bicByBUSD.mul(rateAirdropForRef.bir.numerator).div(rateAirdropForRef.bir.denominator);
        uint256 refBGT = spentBUSD.mul(rateAirdropForRef.bgt.numerator).div(rateAirdropForRef.bgt.denominator);
        uint256 refBUSD = spentBUSD.mul(rateAirdropForRef.busd.numerator).div(rateAirdropForRef.busd.denominator);

        // transfer BUSD
        require(
            busdToken.transferFrom(userAddr, ownerAddress, spentBUSD),
            "Failed to transfer BUSD from user to owner"
        );
        require(
            busdToken.transferFrom(airdropRefAddress, refAddr, refBUSD),
            "Failed to transfer BUSD airdrop for referral"
        );

        // transfer BIC
        require(
            bicToken.transfer(userAddr, bicUserReceive),
            "Failed to transfer BIC from contract to user"
        );
        if (bicAirdropForCore > 0) {
            require(
                bicToken.transferFrom(airdropCoreTeamAddress, userAddr, bicAirdropForCore),
                "Failed to transfer BIC airdrop for core team"
            );
        }
        if (refBIC > 0) {
            require(
                bicToken.transferFrom(airdropRefAddress, refAddr, refBIC),
                "Failed to transfer BIC airdrop for referral"
            );
        }

        // transfer BIR
        if (burnBIR > 0) {
            birToken.burnFrom(userAddr, burnBIR);
        }
        require(
            birToken.transferFrom(airdropRefAddress, refAddr, refBIR),
            "Failed to transfer BIR airdrop for referral"
        );

        // transfer BGT
        bgtToken.mintTo(userAddr, spentBUSD);
        bgtToken.mintTo(refAddr, refBGT);
    }

    /** @dev buy: user buy BIC by spent BUSD, BIR
      * @param spentBUSD: BUSD user spent
      * @param spentBIR: BIR user spent (if spentBIR = 0, don't burn BIR)
      */
    function buy(uint256 spentBUSD, uint256 spentBIR) public {
        require(!isPause, "The contract is paused");

        (address refAddr, bool isWhitelist,) = whitelistContract.getUserInfo(msg.sender, WHITELIST_PRIVATE_SALE);
        require(isWhitelist, "Do not have buy permission (NOT in whitelist)");

        require(
            busdToken.balanceOf(msg.sender) >= spentBUSD,
            "BUSD amount in user's wallet is insufficient"
        );

        uint256 remainBIC = bicToken.balanceOf(address(this));
        require(
            spentBUSD <= (remainBIC.mul(price.numerator).div(price.denominator)),
            "BIC amount in contract is insufficient"
        );
        require(
            block.timestamp >= priorityStartTime,
            "Priority round is NOT started"
        );
        bool isRoundPriority = false;
        if (block.timestamp <= priorityEndTime) {
            isRoundPriority = true;
            bool isUserPriority = priorityContract.isPriority(msg.sender, spentBIR);
            require(
                isUserPriority,
                "User does not have permission in the priority round"
            );
        } else {
            require(
                block.timestamp >= officialStartTime,
                "Official round is NOT started"
            );
            require(
                block.timestamp <= officialEndTime,
                "All rounds of this month ended"
            );
        }

        (uint256 bicByBUSD, uint256 burnBIR, uint256 bicAirdropByBurnBIR) = expectResult(spentBUSD, spentBIR);
        (, bool isCoreTeam,) = whitelistContract.getUserInfo(msg.sender, WHITELIST_CORE_TEAM);
        uint256 bicAirdropForCore = 0;
        if (isCoreTeam) {
            // bicAirdropForCore = bicByBUSD * rateAirdropForCore
            bicAirdropForCore = bicByBUSD.mul(rateAirdropForCore.numerator).div(rateAirdropForCore.denominator);
        } else {
            if (isRoundPriority) {
                bool isUserPriority = priorityContract.isPriority(msg.sender, burnBIR);
                require(
                    isUserPriority,
                    "The BIR amount spent to burn is insufficient to join the priority round"
                );
            }
        }
        handleTransfer(msg.sender, refAddr, spentBUSD, bicByBUSD, burnBIR, bicAirdropByBurnBIR, bicAirdropForCore);
        emit BuySuccess(msg.sender, refAddr, spentBUSD, bicByBUSD, burnBIR, bicAirdropByBurnBIR, bicAirdropForCore, block.timestamp);
    }

    function updateAirdropCoreTeamAddress(address _airdropCoreTeamAddress) public {
        require(hasRole(MODERATOR_CONTRACT, _msgSender()), "Must have MODERATOR_CONTRACT role");
        airdropCoreTeamAddress = _airdropCoreTeamAddress;
        emit UpdateAirdropCoreTeamAddress(_airdropCoreTeamAddress, block.timestamp);
    }

    function updateAirdropRefAddress(address _airdropRefAddress) public {
        require(hasRole(MODERATOR_CONTRACT, _msgSender()), "Must have MODERATOR_CONTRACT role");
        airdropRefAddress = _airdropRefAddress;
        emit UpdateAirdropRefAddress(_airdropRefAddress, block.timestamp);
    }

    function updateWhitelistAddress(address _whitelistAddress) public {
        require(hasRole(MODERATOR_CONTRACT, _msgSender()), "Must have MODERATOR_CONTRACT role");
        whitelistContract = Whitelist(_whitelistAddress);
        emit UpdateWhitelistAddress(_whitelistAddress, block.timestamp);
    }

    function updatePriorityAddress(address _priorityAddress) public {
        require(hasRole(MODERATOR_CONTRACT, _msgSender()), "Must have MODERATOR_CONTRACT role");
        priorityContract = Priority(_priorityAddress);
        emit UpdatePriorityAddress(_priorityAddress, block.timestamp);
    }

    function updateRateAirdrop(Fraction memory _rateAirdropByBurnBIR, Fraction memory _rateAirdropForCore) public {
        require(hasRole(MODERATOR_CONTRACT, _msgSender()), "Must have MODERATOR_CONTRACT role");
        rateAirdropByBurnBIR = _rateAirdropByBurnBIR;
        rateAirdropForCore = _rateAirdropForCore;
        emit UpdateRateAirdrop(_rateAirdropByBurnBIR, _rateAirdropForCore, block.timestamp);
    }

    function updateConfigSale(Fraction memory _price, uint256 _priorityStartTime, uint256 _priorityEndTime, uint256 _officialStartTime, uint256 _officialEndTime) public {
        require(hasRole(MODERATOR_CONTRACT, _msgSender()), "Must have MODERATOR_CONTRACT role");
        price = _price;
        priorityStartTime = _priorityStartTime;
        priorityEndTime = _priorityEndTime;
        officialStartTime = _officialStartTime;
        officialEndTime = _officialEndTime;
        emit UpdateConfigSale(_price, _priorityStartTime, _priorityEndTime, _officialStartTime, _officialEndTime, block.timestamp);
    }

    function updateRateRef(RateRef memory _rateRef) public {
        require(hasRole(MODERATOR_CONTRACT, _msgSender()), "Must have MODERATOR_CONTRACT role");
        rateAirdropForRef = _rateRef;
        emit UpdateRateRef(_rateRef, block.timestamp);
    }

    function setIsPause(bool _isPause) public {
        require(hasRole(MODERATOR_CONTRACT, _msgSender()), "Must have MODERATOR_CONTRACT role");
        isPause = _isPause;
        emit SetIsPause(_isPause, block.timestamp);
    }

    function updateOwner(address _ownerAddress) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Must have ADMIN role");
        ownerAddress = _ownerAddress;
        emit UpdateOwner(_ownerAddress, block.timestamp);
    }

    function withdraw(address _token) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Must have ADMIN role");
        IERC20 token = IERC20(_token);
        uint256 amount = token.balanceOf(address(this));
        require(amount > 0, "Insufficient amount");
        require(token.transfer(ownerAddress, amount), "Failed to transfer");
        emit WithdrawToken(_token, amount, ownerAddress, block.timestamp);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

contract Whitelist is Context, AccessControlEnumerable {
    bytes32 public constant UPDATE_WHITELIST_ROLE = keccak256("UPDATE_WHITELIST_ROLE");
    constructor() {
        address adminAddress = _msgSender();

        _setupRole(DEFAULT_ADMIN_ROLE, adminAddress);

        _setupRole(UPDATE_WHITELIST_ROLE, adminAddress);
    }

    struct UserInfo {
        mapping(bytes32 => bool) role;
        address ref;
        address[] listExtra;
    }

    mapping(address => UserInfo) public userInfo;

    event UpdateMultiUserInfo(address[] _listAddrUser, bytes32[] _listRole, bool[] _listValueRole, address[] _listAddrRef, address[][] _listListExtra, uint256 _time);

    function updateMultiUserInfo(
        address[] memory _listAddrUser,
        bytes32[] memory _listRole,
        bool[] memory _listValueRole,
        address[] memory _listAddrRef,
        address[][] memory _listListExtra) public {
        require(hasRole(UPDATE_WHITELIST_ROLE, _msgSender()), "Must have UPDATE_WHITELIST_ROLE to update userInfo");
        // check
        uint256 lenArray = _listAddrUser.length;
        require(_listRole.length == lenArray, "_listRole.length != lenArray");
        require(_listValueRole.length == lenArray, "_listValueRole.length != lenArray");
        require(_listAddrRef.length == lenArray, "_listAddrRef.length != lenArray");
        require(_listListExtra.length == lenArray, "_listExtra.length != lenArray");

        for (uint256 i = 0; i < lenArray; i++) {
            userInfo[_listAddrUser[i]].ref = _listAddrRef[i];
            userInfo[_listAddrUser[i]].role[_listRole[i]] = _listValueRole[i];
            userInfo[_listAddrUser[i]].listExtra = _listListExtra[i];
        }
        emit UpdateMultiUserInfo(_listAddrUser, _listRole, _listValueRole, _listAddrRef, _listListExtra, block.timestamp);
    }

    function getUserInfo(address _addrUser, bytes32 _role) view public returns (address, bool, address[] memory) {
        return (userInfo[_addrUser].ref, userInfo[_addrUser].role[_role], userInfo[_addrUser].listExtra);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

contract UserStartTime is Context, AccessControlEnumerable {
    bytes32 public constant UPDATE_START_TIME_ROLE = keccak256("UPDATE_START_TIME_ROLE");
    constructor() {
        address adminAddress = _msgSender();

        _setupRole(DEFAULT_ADMIN_ROLE, adminAddress);

        _setupRole(UPDATE_START_TIME_ROLE, adminAddress);
    }
    mapping(address => uint256) public startTime;

    event UpdateMultiUserInfo(address[] _listUsers, uint256[] _listStartTimes, uint256 _time);

    function updateMultiUserInfo(address[] memory _listUsers, uint256[] memory _listStartTimes) public {
        require(hasRole(UPDATE_START_TIME_ROLE, _msgSender()), "Must have UPDATE_START_TIME_ROLE");
        // check
        uint256 lenArray = _listUsers.length;
        require(_listStartTimes.length == lenArray, "_listStartTimes.length != lenArray");
        for (uint256 i = 0; i < lenArray; i++) {
            startTime[_listUsers[i]] = _listStartTimes[i];
        }
        emit UpdateMultiUserInfo(_listUsers, _listStartTimes, block.timestamp);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Whitelist.sol";
import "./BeinGiveTake.sol";
import "./BICRight.sol";
import "./UserStartTime.sol";

contract Priority is Context, AccessControlEnumerable {
    bytes32 public constant WHITELIST_CORE_TEAM = keccak256("WHITELIST_CORE_TEAM");

    constructor(address bicAddr, address birAddr, address bgtAddr, address whitelistAddr, address userStartTimeAddr) {
        bicToken = IERC20(bicAddr);
        birToken = BICRight(birAddr);
        bgtToken = BeinGiveTake(bgtAddr);
        whitelistContract = Whitelist(whitelistAddr);
        userStartTimeContract = UserStartTime(userStartTimeAddr);
        address adminAddress = _msgSender();
        _setupRole(DEFAULT_ADMIN_ROLE, adminAddress);
    }

    IERC20 public bicToken;
    BICRight public birToken;
    BeinGiveTake public bgtToken;
    Whitelist public whitelistContract;
    UserStartTime public userStartTimeContract;

    uint256 public minBurnBIRInPriority = 1000 * 1e18;

    uint256 public durationPriority = 86400 * 90; // 90 days

    event UpdateMinBurnBIRInPriority(uint256 _minBurnBIRInPriority, uint256 _time);
    event UpdateDurationPriority(uint256 _durationPriority, uint256 _time);

    function isPriority(address userAddress, uint256 spentBIR) public view returns (bool) {
        uint256 birUser = birToken.balanceOf(userAddress);
        (, bool isCoreTeam,) = whitelistContract.getUserInfo(userAddress, WHITELIST_CORE_TEAM);
        uint256 startTime = userStartTimeContract.startTime(userAddress);
        if (
            ((spentBIR >= minBurnBIRInPriority) && (birUser >= minBurnBIRInPriority))
            || (isCoreTeam)
            || (block.timestamp - startTime <= durationPriority)
        ) {
            return true;
        }
        return false;
    }

    function updateMinBurnBIRInPriority(uint256 _minBurnBIRInPriority) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Must have admin role");
        minBurnBIRInPriority = _minBurnBIRInPriority;
        emit UpdateMinBurnBIRInPriority(_minBurnBIRInPriority, block.timestamp);
    }

    function updateDurationPriority(uint256 _durationPriority) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Must have admin role");
        durationPriority = _durationPriority;
        emit UpdateDurationPriority(_durationPriority, block.timestamp);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

contract BeinGiveTake is Context, AccessControlEnumerable {
    bytes32 public constant MINT_ROLE = keccak256("MINT_ROLE");

    constructor() {
        address adminAddress = msg.sender;

        _setupRole(DEFAULT_ADMIN_ROLE, adminAddress);

        _setupRole(MINT_ROLE, adminAddress);

        _name = "Bein Give and Take";
        _symbol = "BGT";
        _decimal = 18;
    }

    mapping (address => uint256) private _balances;
    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimal;

    event Transfer(address indexed from, address indexed to, uint256 value);

    function mintTo(address account, uint256 amount) public {
        require(hasRole(MINT_ROLE, msg.sender), "Must have MINT_ROLE");

        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimal;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "./BeinGiveTake.sol";

contract BICRight is Context, AccessControlEnumerable, ERC20Burnable, ERC20Pausable {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    bytes32 public constant BLACK_LIST_ROLE = keccak256("BLACK_LIST_ROLE");

    bytes32 public constant MINT_BGT_ROLE = keccak256("MINT_BGT_ROLE");

    constructor(address addrBGT) ERC20("BIC Right", "BIR") {
        address adminAddress = _msgSender();

        _setupRole(DEFAULT_ADMIN_ROLE, adminAddress);

        _setupRole(BLACK_LIST_ROLE, adminAddress);

        _setupRole(PAUSER_ROLE, adminAddress);

        _mint(adminAddress, 100000000 * 1e18);

        tokenAddressBGT = addrBGT;
    }

    event UpdateTokenAddressBGT(address addr, uint256 time);

    event BlockAddress(address addr, uint256 time);

    event UnblockAddress(address addr, uint256 time);

    event BurnReceiveBGT(address account, uint256 amount, uint256 time);

    mapping(address => bool) public blacklist;
    address public tokenAddressBGT;

    function updateTokenAddressBGT(address addr) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Must have DEFAULT_ADMIN_ROLE");
        tokenAddressBGT = addr;
        emit UpdateTokenAddressBGT(addr, block.timestamp);
    }

    function blockAddress(address addr) public {
        require(hasRole(BLACK_LIST_ROLE, _msgSender()), "Must have black list role to block");
        blacklist[addr] = true;
        emit BlockAddress(addr, block.timestamp);
    }

    function unblockAddress(address addr) public {
        require(hasRole(BLACK_LIST_ROLE, _msgSender()), "Must have black list role to unblock");
        blacklist[addr] = false;
        emit UnblockAddress(addr, block.timestamp);
    }

    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "Must have pauser role to pause");
        _pause();
    }

    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "Must have pauser role to unpause");
        _unpause();
    }

    function burnReceiveBGT(uint256 amount) public {
        burn(amount);
        BeinGiveTake bgtToken = BeinGiveTake(tokenAddressBGT);
        bgtToken.mintTo(msg.sender, amount);
        emit BurnReceiveBGT(msg.sender, amount, block.timestamp);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override(ERC20, ERC20Pausable) {
        require(!blacklist[from], "Address is in blacklist");
        if (hasRole(MINT_BGT_ROLE, from)) {
            BeinGiveTake bgtToken = BeinGiveTake(tokenAddressBGT);
            bgtToken.mintTo(to, amount);
        }
        super._beforeTokenTransfer(from, to, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../security/Pausable.sol";

/**
 * @dev ERC20 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC20Pausable is ERC20, Pausable {
    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "ERC20Pausable: token transfer while paused");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        _approve(account, _msgSender(), currentAllowance - amount);
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable {
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping (bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {grantRole} to track enumerable memberships
     */
    function grantRole(bytes32 role, address account) public virtual override {
        super.grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {revokeRole} to track enumerable memberships
     */
    function revokeRole(bytes32 role, address account) public virtual override {
        super.revokeRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {renounceRole} to track enumerable memberships
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        super.renounceRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {_setupRole} to track enumerable memberships
     */
    function _setupRole(bytes32 role, address account) internal virtual override {
        super._setupRole(role, account);
        _roleMembers[role].add(account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
}

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping (address => bool) members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if(!hasRole(role, account)) {
            revert(string(abi.encodePacked(
                "AccessControl: account ",
                Strings.toHexString(uint160(account), 20),
                " is missing role ",
                Strings.toHexString(uint256(role), 32)
            )));
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}