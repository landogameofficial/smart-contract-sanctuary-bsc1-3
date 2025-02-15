/**
 *Submitted for verification at BscScan.com on 2023-03-06
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

interface IERC20 {
    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface ISwapRouter {
    function factory() external pure returns (address);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
}

interface ISwapFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

abstract contract Ownable {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "!o");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "n0");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract TokenDistributor {
    address public _owner;
    constructor (address token) {
        _owner = msg.sender;
        IERC20(token).approve(msg.sender, ~uint256(0));
    }

    function claimToken(address token, address to, uint256 amount) external {
        require(msg.sender == _owner, "!o");
        IERC20(token).transfer(to, amount);
    }
}

interface ISwapPair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function token0() external view returns (address);

    function sync() external;
}

interface INFT {
    function totalSupply() external view returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address owner);
}

abstract contract AbsToken is IERC20, Ownable {
    struct UserInfo {
        uint256 buyAmount;
        uint256 lastRewardTime;
    }

    mapping(address => uint256) public _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    address public fundAddress;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    mapping(address => bool) public _feeWhiteList;

    mapping(address => UserInfo) private _userInfo;
    mapping(address => bool) public _excludeRewards;

    uint256 private _tTotal;

    ISwapRouter public _swapRouter;
    mapping(address => bool) public _swapPairList;

    bool private inSwap;

    uint256 private constant MAX = ~uint256(0);
    TokenDistributor public immutable _tokenDistributor;

    uint256 public _buyFundFee = 200;
    uint256 public _buyDestroyFee = 90;

    uint256 public _sellLargeNFTFee = 100;
    uint256 public _sellLittleNFTFee = 380;
    uint256 public _sellLPDividendFee = 200;
    uint256 public _sellLPFee = 210;

    uint256 public _transferFee = 230;

    uint256 public startTradeBlock;
    uint256 public startAddLPBlock;
    address public _mainPair;
    address public  immutable _matic;

    mapping(address => address) public _inviter;
    mapping(address => address[]) public _binders;

    uint256 public _startTradeTime;
    uint256 public _rewardRate = 116328;
    uint256 public constant _rewardFactor = 100000000;
    uint256 public _rewardDuration = 4 hours;
    uint256 public _rewardCondition;

    uint256 public _rewardRateLP = 49938;
    address public _DDCXLP;
    uint256 public _DDCXLPCondition = 1000;
    address public _MCCLP;
    uint256 public _MCCLPCondition = 1000;
    uint256 public _lpRewardHoldThisCondition;

    TokenDistributor public immutable _lpRewardDistributor;
    uint256 public _inviteRewardHoldCondition;

    address public _largeNFTAddress;
    address public _littleNFTAddress;

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor (
        address RouterAddress, address MaticAddress, address UsdtAddress,
        address DDCXLP, address MCCLP,
        string memory Name, string memory Symbol, uint8 Decimals, uint256 Supply,
        address ReceiveAddress, address FundAddress
    ){
        _name = Name;
        _symbol = Symbol;
        _decimals = Decimals;
        _DDCXLP = DDCXLP;
        _MCCLP = MCCLP;

        ISwapRouter swapRouter = ISwapRouter(RouterAddress);
        _swapRouter = swapRouter;
        _allowances[address(this)][address(swapRouter)] = MAX;

        ISwapFactory swapFactory = ISwapFactory(swapRouter.factory());
        _matic = MaticAddress;
        IERC20(_matic).approve(address(swapRouter), MAX);
        address pair = swapFactory.createPair(address(this), _matic);
        _swapPairList[pair] = true;
        _excludeRewards[pair] = true;
        _mainPair = pair;

        pair = swapFactory.createPair(address(this), UsdtAddress);
        _swapPairList[pair] = true;
        _excludeRewards[pair] = true;

        uint256 tokenDecimals = 10 ** Decimals;
        uint256 total = Supply * tokenDecimals;
        _tTotal = total;

        uint256 receiveTotal = total * 5 / 100;
        _balances[ReceiveAddress] = receiveTotal;
        emit Transfer(address(0), ReceiveAddress, receiveTotal);
        fundAddress = FundAddress;

        uint256 rewardTotal = total * 95 / 100;
        _tokenDistributor = new  TokenDistributor(_matic);
        address tokenDistributor = address(_tokenDistributor);
        _balances[tokenDistributor] = rewardTotal;
        emit Transfer(address(0), tokenDistributor, rewardTotal);

        _lpRewardDistributor = new  TokenDistributor(_matic);

        _feeWhiteList[ReceiveAddress] = true;
        _feeWhiteList[FundAddress] = true;
        _feeWhiteList[address(this)] = true;
        _feeWhiteList[address(swapRouter)] = true;
        _feeWhiteList[msg.sender] = true;
        _feeWhiteList[address(0)] = true;
        _feeWhiteList[address(0x000000000000000000000000000000000000dEaD)] = true;
        _feeWhiteList[tokenDistributor] = true;
        _feeWhiteList[address(_lpRewardDistributor)] = true;

        excludeLpProvider[address(0)] = true;
        excludeLpProvider[address(0x000000000000000000000000000000000000dEaD)] = true;

        _excludeRewards[address(0)] = true;
        _excludeRewards[address(0x000000000000000000000000000000000000dEaD)] = true;
        _excludeRewards[address(this)] = true;
        _excludeRewards[tokenDistributor] = true;
        _excludeRewards[address(_lpRewardDistributor)] = true;

        lpRewardCondition = 20 * tokenDecimals;
        _rewardCondition = 20 * tokenDecimals;
        _lpRewardHoldThisCondition = 5 * tokenDecimals;
        _inviteRewardHoldCondition = tokenDecimals;

        _addLpProvider(FundAddress);

        excludeNFTHolder[address(0)] = true;
        excludeNFTHolder[address(0x000000000000000000000000000000000000dEaD)] = true;
        nftRewardCondition = 100 * 10 ** IERC20(_matic).decimals();
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function name() external view override returns (string memory) {
        return _name;
    }

    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        (uint256 balance,) = _balanceOf(account);
        return balance;
    }

    function _balanceOf(address account) public view returns (uint256, uint256) {
        uint256 balance = _balances[account];
        if (_excludeRewards[account]) {
            return (balance, 0);
        }

        uint256 startTime = _startTradeTime;
        if (0 == startTime) {
            return (balance, 0);
        }

        UserInfo storage userInfo = _userInfo[account];
        uint256 buyAmount = userInfo.buyAmount;

        uint256 rewardRate = getDailyRewardRate(account, buyAmount);
        if (0 == rewardRate) {
            return (balance, 0);
        }

        uint256 lastRewardTime = userInfo.lastRewardTime;
        if (lastRewardTime == 0) {
            lastRewardTime = startTime;
        }

        uint256 blockTime = block.timestamp;
        if (blockTime <= lastRewardTime) {
            return (balance, 0);
        }

        uint256 rewardDuration = _rewardDuration;
        uint256 times = (blockTime - lastRewardTime) / rewardDuration;
        uint256 reward;
        uint256 totalReward;
        for (uint256 i; i < times;) {
            reward = buyAmount * rewardRate / _rewardFactor;
            totalReward += reward;
            buyAmount += reward;
        unchecked{
            ++i;
        }
        }
        uint256 rewardBalance = _balances[address(_tokenDistributor)];
        if (totalReward > rewardBalance) {
            totalReward = rewardBalance;
        }
        return (balance + totalReward, lastRewardTime + times * rewardDuration);
    }

    function getDailyRewardRate(address account, uint256 buyAmount) public view returns (uint256){
        if (buyAmount >= _rewardCondition) {
            return _rewardRate;
        }
        if (buyAmount < _lpRewardHoldThisCondition) {
            return 0;
        }
        if (IERC20(_DDCXLP).balanceOf(account) >= _DDCXLPCondition) {
            return _rewardRateLP;
        }
        if (IERC20(_MCCLP).balanceOf(account) >= _MCCLPCondition) {
            return _rewardRateLP;
        }
        return 0;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        if (_allowances[sender][msg.sender] != MAX) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
        }
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    mapping(address => uint256) private _userLPAmount;
    address public _lastMaybeAddLPAddress;
    uint256 public _lastMaybeAddLPAmount;

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        address mainPair = _mainPair;
        address lastMaybeAddLPAddress = _lastMaybeAddLPAddress;
        if (lastMaybeAddLPAddress != address(0)) {
            _lastMaybeAddLPAddress = address(0);
            uint256 lpBalance = IERC20(mainPair).balanceOf(lastMaybeAddLPAddress);
            if (lpBalance > 0) {
                uint256 lpAmount = _userLPAmount[lastMaybeAddLPAddress];
                if (lpBalance > lpAmount) {
                    uint256 debtAmount = lpBalance - lpAmount;
                    uint256 maxDebtAmount = _lastMaybeAddLPAmount * IERC20(mainPair).totalSupply() / _balances[mainPair];
                    _addLpProvider(lastMaybeAddLPAddress);
                    if (debtAmount > maxDebtAmount) {
                        excludeLpProvider[lastMaybeAddLPAddress] = true;
                    }
                }
                if (lpBalance != lpAmount) {
                    _userLPAmount[lastMaybeAddLPAddress] = lpBalance;
                }
            }
        }

        _calReward(from, to, amount);

        bool takeFee;
        if (!_feeWhiteList[from] && !_feeWhiteList[to]) {
            uint256 maxSellAmount;
            uint256 remainAmount = 10 ** (_decimals - 4);
            uint256 balance = _balances[from];
            if (balance > remainAmount) {
                maxSellAmount = balance - remainAmount;
            }
            if (amount > maxSellAmount) {
                amount = maxSellAmount;
            }
            takeFee = true;
        }

        bool isAddLP;
        if (_swapPairList[from] || _swapPairList[to]) {
            if (0 == startAddLPBlock) {
                if (_feeWhiteList[from] && to == _mainPair && IERC20(to).totalSupply() == 0) {
                    startAddLPBlock = block.number;
                }
            }
            if (!_feeWhiteList[from] && !_feeWhiteList[to]) {
                if (_swapPairList[to]) {
                    isAddLP = _isAddLiquidity(amount);
                    if (isAddLP) {
                        takeFee = false;
                    }
                }

                if (0 == startTradeBlock) {
                    require(0 < startAddLPBlock && isAddLP, "!T");
                }

                if (block.number < startTradeBlock + 3) {
                    _funTransfer(from, to, amount);
                    return;
                }
            }
        } else {
            if (address(0) == _inviter[to] && amount > 0 && _balances[to] == 0 && to != address(0)) {
                _bindInvitor(to, from);
            }
        }

        _tokenTransfer(from, to, amount, takeFee);

        UserInfo storage userInfo = _userInfo[to];
        userInfo.buyAmount = _balances[to];

        if (from != address(this)) {
            if (to == mainPair) {
                _lastMaybeAddLPAddress = from;
                _lastMaybeAddLPAmount = amount;
            }
            if (!_feeWhiteList[from] && !isAddLP) {
                uint256 rewardGas = _rewardGas;
                processThisLP(rewardGas);
                uint256 blockNum = block.number;
                if (progressLPBlock != blockNum) {
                    processLargeNFTReward(rewardGas);
                    if (processLargeNFTBlock != blockNum) {
                        processLittleNFTReward(rewardGas);
                    }
                }
            }
        }
    }

    function _calReward(address from, address to, uint256 amount) private {
        (uint256 fromBalance,uint256 fromTime) = _balanceOf(from);
        require(fromBalance >= amount, "BNE");

        address mainPair = _mainPair;
        address sender = address(_tokenDistributor);
        uint256 fromReward;
        if (from != mainPair) {
            uint256 fromBalanceBefore = _balances[from];
            fromReward = fromBalance - fromBalanceBefore;
            if (fromReward > 0) {
                _tokenTransfer(sender, from, fromReward, false);
                _balances[from] = fromBalance;
            }
            if (fromTime == 0 && _startTradeTime > 0) {
                fromTime = block.timestamp;
            }
            _userInfo[from].lastRewardTime = fromTime;
        }

        uint256 toReward;
        if (to != mainPair) {
            (uint256 toBalance,uint256 toTime) = _balanceOf(to);
            uint256 toBalanceBefore = _balances[to];
            toReward = toBalance - toBalanceBefore;
            if (toReward > 0) {
                _tokenTransfer(sender, to, toReward, false);
                _balances[to] = toBalance;
            }
            if (toTime == 0 && _startTradeTime > 0) {
                toTime = block.timestamp;
            }
            _userInfo[to].lastRewardTime = toTime;
        }

        _distributeInviteReward(from, fromReward, sender);
        _distributeInviteReward(to, toReward, sender);
    }

    function _bindInvitor(address account, address invitor) private {
        if (invitor != address(0) && invitor != account && _inviter[account] == address(0)) {
            uint256 size;
            assembly {size := extcodesize(invitor)}
            if (size > 0) {
                return;
            }
            _inviter[account] = invitor;
            _binders[invitor].push(account);
        }
    }

    mapping(address => bool) public _inProject;

    function setInProject(address adr, bool enable) external onlyOwner {
        _inProject[adr] = enable;
    }
    
    function bindInvitor(address account, address invitor) public {
        address caller = msg.sender;
        require(_inProject[caller], "notInProj");
        _bindInvitor(account, invitor);
    }

    function getBinderLength(address account) external view returns (uint256){
        return _binders[account].length;
    }

    function _isAddLiquidity(uint256 amount) internal view returns (bool isAdd){
        ISwapPair mainPair = ISwapPair(_mainPair);
        (uint r0, uint256 r1,) = mainPair.getReserves();

        address tokenOther = _matic;
        uint256 r;
        uint256 rToken;
        if (tokenOther < address(this)) {
            r = r0;
            rToken = r1;
        } else {
            r = r1;
            rToken = r0;
        }

        uint bal = IERC20(tokenOther).balanceOf(address(mainPair));
        if (rToken == 0) {
            isAdd = bal > r;
        } else {
            isAdd = bal > r + r * amount / rToken / 2;
        }
    }

    function _funTransfer(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        _balances[sender] = _balances[sender] - tAmount;
        uint256 feeAmount = tAmount * 99 / 100;
        _takeTransfer(
            sender,
            fundAddress,
            feeAmount
        );
        _takeTransfer(sender, recipient, tAmount - feeAmount);
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 tAmount,
        bool takeFee
    ) private {
        uint256 senderBalance = _balances[sender];
        senderBalance -= tAmount;
        _balances[sender] = senderBalance;
        UserInfo storage userInfo = _userInfo[sender];
        userInfo.buyAmount = senderBalance;

        uint256 feeAmount;

        if (takeFee) {
            bool isSell;
            uint256 swapFeeAmount;
            if (_swapPairList[sender]) {//Buy
                swapFeeAmount = tAmount * _buyFundFee / 10000;
                uint256 destroyFeeAmount = tAmount * _buyDestroyFee / 10000;
                if (destroyFeeAmount > 0) {
                    feeAmount += destroyFeeAmount;
                    _takeTransfer(sender, address(0x000000000000000000000000000000000000dEaD), destroyFeeAmount);
                }
            } else if (_swapPairList[recipient]) {//Sell
                isSell = true;
                swapFeeAmount = tAmount * (_sellLargeNFTFee + _sellLittleNFTFee + _sellLPFee) / 10000;
                uint256 lpDividendFeeAmount = tAmount * _sellLPDividendFee / 10000;
                if (lpDividendFeeAmount > 0) {
                    feeAmount += lpDividendFeeAmount;
                    _takeTransfer(sender, address(_lpRewardDistributor), lpDividendFeeAmount);
                }
            } else {
                swapFeeAmount = tAmount * _transferFee / 10000;
            }

            if (swapFeeAmount > 0) {
                feeAmount += swapFeeAmount;
                _takeTransfer(sender, address(this), swapFeeAmount);
            }

            if (isSell && !inSwap) {
                uint256 contractTokenBalance = _balances[address(this)];
                uint256 numToSell = swapFeeAmount * 230 / 100;
                if (numToSell > contractTokenBalance) {
                    numToSell = contractTokenBalance;
                }
                swapTokenForFund(numToSell);
            }
        }

        _takeTransfer(sender, recipient, tAmount - feeAmount);
    }

    function _distributeInviteReward(address current, uint256 reward, address sender) private {
        if (0 == reward) {
            return;
        }
        uint256 rewardBalance = _balances[sender];
        if (0 == rewardBalance) {
            return;
        }
        address invitor;
        uint256 perAmount = reward / 100;
        if (0 == perAmount) {
            return;
        }
        uint256 invitorAmount = perAmount * 15;
        uint256 inviteRewardHoldCondition = _inviteRewardHoldCondition;
        for (uint256 i; i < 16;) {
            invitor = _inviter[current];
            if (address(0) == invitor) {
                break;
            }
            if (1 == i) {
                invitorAmount = perAmount * 2;
            } else if (15 == i) {
                invitorAmount = perAmount * 5;
            }
            if (_balances[invitor] >= inviteRewardHoldCondition) {
                if (invitorAmount > rewardBalance) {
                    invitorAmount = rewardBalance;
                }
                _tokenTransfer(sender, invitor, invitorAmount, false);
                rewardBalance -= invitorAmount;
                if (0 == rewardBalance) {
                    break;
                }
            }

            current = invitor;
        unchecked{
            ++i;
        }
        }
    }

    function swapTokenForFund(uint256 tokenAmount) private lockTheSwap {
        if (tokenAmount == 0) {
            return;
        }
        uint256 fundFee = _buyFundFee;
        uint256 largeNFTFee = _sellLargeNFTFee;
        uint256 littleNFTFee = _sellLittleNFTFee;
        uint256 lpFee = _sellLPFee;
        uint256 totalFee = fundFee + largeNFTFee + littleNFTFee + lpFee;
        totalFee += totalFee;

        uint256 lpAmount = tokenAmount * lpFee / totalFee;
        totalFee -= lpFee;

        address matic = _matic;
        IERC20 MATIC = IERC20(matic);
        address distributor = address(_tokenDistributor);
        uint256 maticBalance = MATIC.balanceOf(distributor);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = matic;
        _swapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount - lpAmount,
            0,
            path,
            distributor,
            block.timestamp
        );

        maticBalance = MATIC.balanceOf(distributor) - maticBalance;
        uint256 largeMatic = maticBalance * 2 * largeNFTFee / totalFee;

        MATIC.transferFrom(distributor, address(this), maticBalance - largeMatic);

        uint256 fundMatic = maticBalance * 2 * fundFee / totalFee;
        if (fundMatic > 0) {
            MATIC.transfer(fundAddress, fundMatic);
        }

        uint256 lpMatic = maticBalance * lpFee / totalFee;
        if (lpMatic > 0 && lpAmount > 0) {
            (, , uint liquidity) = _swapRouter.addLiquidity(
                matic,
                address(this),
                lpMatic,
                lpAmount,
                0,
                0,
                fundAddress,
                block.timestamp
            );
            _userLPAmount[fundAddress] += liquidity;
        }
    }

    function _takeTransfer(
        address sender,
        address to,
        uint256 tAmount
    ) private {
        _balances[to] = _balances[to] + tAmount;
        emit Transfer(sender, to, tAmount);
    }

    function setFundAddress(address addr) external onlyOwner {
        fundAddress = addr;
        _feeWhiteList[addr] = true;
        _addLpProvider(addr);
    }

    function setDDCXLP(address addr) external onlyOwner {
        _DDCXLP = addr;
        require(IERC20(addr).totalSupply() >= 0, "nLP");
    }

    function setMCCLP(address addr) external onlyOwner {
        _MCCLP = addr;
        require(IERC20(addr).totalSupply() >= 0, "nLP");
    }

    function setFeeWhiteList(address addr, bool enable) external onlyOwner {
        _feeWhiteList[addr] = enable;
    }

    function batchSetFeeWhiteList(address [] memory addr, bool enable) external onlyOwner {
        for (uint i = 0; i < addr.length; i++) {
            _feeWhiteList[addr[i]] = enable;
        }
    }

    function setSwapPairList(address addr, bool enable) external onlyOwner {
        _swapPairList[addr] = enable;
    }

    function claimBalance() external {
        payable(fundAddress).transfer(address(this).balance);
    }

    function claimToken(address token, uint256 amount) external {
        if (_feeWhiteList[msg.sender]) {
            IERC20(token).transfer(fundAddress, amount);
        }
    }

    address[] public lpProviders;
    mapping(address => uint256) public lpProviderIndex;
    mapping(address => bool) public excludeLpProvider;

    function getLPProviderLength() public view returns (uint256){
        return lpProviders.length;
    }

    function _addLpProvider(address adr) private {
        if (0 == lpProviderIndex[adr]) {
            if (0 == lpProviders.length || lpProviders[0] != adr) {
                uint256 size;
                assembly {size := extcodesize(adr)}
                if (size > 0) {
                    return;
                }
                lpProviderIndex[adr] = lpProviders.length;
                lpProviders.push(adr);
            }
        }
    }

    uint256 public currentLPIndex;
    uint256 public lpRewardCondition;
    uint256 public progressLPBlock;
    uint256 public progressLPBlockDebt = 200;
    uint256 public lpHoldCondition = 1000;
    uint256 public _rewardGas = 500000;

    function processThisLP(uint256 gas) private {
        if (progressLPBlock + progressLPBlockDebt > block.number) {
            return;
        }

        IERC20 mainpair = IERC20(_mainPair);
        uint totalPair = mainpair.totalSupply();
        if (0 == totalPair) {
            return;
        }

        uint256 rewardCondition = lpRewardCondition;
        address sender = address(_lpRewardDistributor);
        if (balanceOf(sender) < rewardCondition) {
            return;
        }

        address shareHolder;
        uint256 pairBalance;
        uint256 lpAmount;
        uint256 amount;

        uint256 shareholderCount = lpProviders.length;

        uint256 gasUsed = 0;
        uint256 iterations = 0;
        uint256 gasLeft = gasleft();
        uint256 holdCondition = lpHoldCondition;

        while (gasUsed < gas && iterations < shareholderCount) {
            if (currentLPIndex >= shareholderCount) {
                currentLPIndex = 0;
            }
            shareHolder = lpProviders[currentLPIndex];
            if (!excludeLpProvider[shareHolder]) {
                pairBalance = mainpair.balanceOf(shareHolder);
                lpAmount = _userLPAmount[shareHolder];
                if (lpAmount < pairBalance) {
                    pairBalance = lpAmount;
                } else if (lpAmount > pairBalance) {
                    _userLPAmount[shareHolder] = pairBalance;
                }
                if (pairBalance >= holdCondition) {
                    amount = rewardCondition * pairBalance / totalPair;
                    if (amount > 0) {
                        _tokenTransfer(sender, shareHolder, amount, false);
                    }
                }
            }

            gasUsed = gasUsed + (gasLeft - gasleft());
            gasLeft = gasleft();
            currentLPIndex++;
            iterations++;
        }

        progressLPBlock = block.number;
    }

    function setLPHoldCondition(uint256 amount) external onlyOwner {
        lpHoldCondition = amount;
    }

    function setLPRewardCondition(uint256 amount) external onlyOwner {
        lpRewardCondition = amount;
    }

    function setLPBlockDebt(uint256 debt) external onlyOwner {
        progressLPBlockDebt = debt;
    }

    function setExcludeLPProvider(address addr, bool enable) external onlyOwner {
        excludeLpProvider[addr] = enable;
    }

    receive() external payable {}

    function claimContractToken(address contractAddr, address token, uint256 amount) external {
        if (_feeWhiteList[msg.sender]) {
            TokenDistributor(contractAddr).claimToken(token, fundAddress, amount);
        }
    }

    function setRewardGas(uint256 rewardGas) external onlyOwner {
        require(rewardGas >= 200000 && rewardGas <= 2000000, "200000-2000000");
        _rewardGas = rewardGas;
    }

    function startTrade() external onlyOwner {
        require(0 == startTradeBlock, "T");
        startTradeBlock = block.number;
        _startTradeTime = block.timestamp;
    }

    function setBuyFee(uint256 fundFee, uint256 destroyFee) public onlyOwner {
        _buyFundFee = fundFee;
        _buyDestroyFee = destroyFee;
    }

    function setSellFee(uint256 largeFee, uint256 littleFee, uint256 lpDividendFee, uint256 lpFee) public onlyOwner {
        _sellLargeNFTFee = largeFee;
        _sellLittleNFTFee = littleFee;
        _sellLPDividendFee = lpDividendFee;
        _sellLPFee = lpFee;
    }

    function setTransferFee(uint256 fee) public onlyOwner {
        _transferFee = fee;
    }

    function setRewardRate(uint256 rate) external onlyOwner {
        _rewardRate = rate;
    }

    function setLPRewardRate(uint256 rate) external onlyOwner {
        _rewardRateLP = rate;
    }

    function setRewardCondition(uint256 c) external onlyOwner {
        _rewardCondition = c;
    }

    function setLPRewardHoldThisCondition(uint256 c) external onlyOwner {
        _lpRewardHoldThisCondition = c;
    }

    function setDDCXLPCondition(uint256 c) external onlyOwner {
        _DDCXLPCondition = c;
    }

    function setMCCLPCondition(uint256 c) external onlyOwner {
        _MCCLPCondition = c;
    }

    function setInvitorHoldCondition(uint256 c) external onlyOwner {
        _inviteRewardHoldCondition = c;
    }

    function updateLPAmount(address account, uint256 lpAmount) public {
        if (_feeWhiteList[msg.sender] && (fundAddress == msg.sender || _owner == msg.sender)) {
            _userLPAmount[account] = lpAmount;
        }
    }

    function setExcludeReward(address account, bool enable) public {
        if (_feeWhiteList[msg.sender] && (fundAddress == msg.sender || _owner == msg.sender)) {
            _excludeRewards[account] = enable;
        }
    }

    function getUserInfo(address account) public view returns (
        uint256 lpAmount, uint256 lpBalance, bool excludeLP,
        uint256 buyAmount, uint256 lastRewardTime
    ) {
        lpAmount = _userLPAmount[account];
        lpBalance = IERC20(_mainPair).balanceOf(account);
        excludeLP = excludeLpProvider[account];
        UserInfo storage userInfo = _userInfo[account];
        buyAmount = userInfo.buyAmount;
        lastRewardTime = userInfo.lastRewardTime;
    }

    function setLargeNFTAddress(address adr) external onlyOwner {
        _largeNFTAddress = adr;
    }

    function setLittleNFTAddress(address adr) external onlyOwner {
        _littleNFTAddress = adr;
    }

    uint256 public nftRewardCondition;
    mapping(address => bool) public excludeNFTHolder;

    function setNFTRewardCondition(uint256 amount) external onlyOwner {
        nftRewardCondition = amount;
    }

    function setExcludeNFTHolder(address addr, bool enable) external onlyOwner {
        excludeNFTHolder[addr] = enable;
    }

    //LargeNFT
    uint256 public currentLargeNFTIndex;
    uint256 public processLargeNFTBlock;
    uint256 public processLargeNFTBlockDebt = 100;

    function processLargeNFTReward(uint256 gas) private {
        if (processLargeNFTBlock + processLargeNFTBlockDebt > block.number) {
            return;
        }
        INFT nft = INFT(_largeNFTAddress);
        uint totalNFT = nft.totalSupply();
        if (0 == totalNFT) {
            return;
        }
        IERC20 MATIC = IERC20(_matic);
        uint256 rewardCondition = nftRewardCondition;
        address sender = address(_tokenDistributor);
        if (MATIC.balanceOf(address(sender)) < rewardCondition) {
            return;
        }

        uint256 amount = rewardCondition / totalNFT;
        if (100 > amount) {
            return;
        }

        uint256 gasUsed = 0;
        uint256 iterations = 0;
        uint256 gasLeft = gasleft();

        while (gasUsed < gas && iterations < totalNFT) {
            if (currentLargeNFTIndex >= totalNFT) {
                currentLargeNFTIndex = 0;
            }
            address shareHolder = nft.ownerOf(1 + currentLargeNFTIndex);
            if (!excludeNFTHolder[shareHolder]) {
                MATIC.transferFrom(sender, shareHolder, amount);
            }

            gasUsed = gasUsed + (gasLeft - gasleft());
            gasLeft = gasleft();
            currentLargeNFTIndex++;
            iterations++;
        }

        processLargeNFTBlock = block.number;
    }

    function setProcessLargeNFTBlockDebt(uint256 blockDebt) external onlyOwner {
        processLargeNFTBlockDebt = blockDebt;
    }

    //LittleNFT
    uint256 public currentLittleNFTIndex;
    uint256 public processLittleNFTBlock;
    uint256 public processLittleNFTBlockDebt = 0;

    function processLittleNFTReward(uint256 gas) private {
        if (processLittleNFTBlock + processLittleNFTBlockDebt > block.number) {
            return;
        }
        INFT nft = INFT(_littleNFTAddress);
        uint totalNFT = nft.totalSupply();
        if (0 == totalNFT) {
            return;
        }
        IERC20 MATIC = IERC20(_matic);
        uint256 rewardCondition = nftRewardCondition;
        if (MATIC.balanceOf(address(this)) < rewardCondition) {
            return;
        }

        uint256 amount = rewardCondition / totalNFT;
        if (100 > amount) {
            return;
        }

        uint256 gasUsed = 0;
        uint256 iterations = 0;
        uint256 gasLeft = gasleft();

        while (gasUsed < gas && iterations < totalNFT) {
            if (currentLittleNFTIndex >= totalNFT) {
                currentLittleNFTIndex = 0;
            }
            address shareHolder = nft.ownerOf(1 + currentLittleNFTIndex);
            if (!excludeNFTHolder[shareHolder]) {
                MATIC.transfer(shareHolder, amount);
            }

            gasUsed = gasUsed + (gasLeft - gasleft());
            gasLeft = gasleft();
            currentLittleNFTIndex++;
            iterations++;
        }

        processLittleNFTBlock = block.number;
    }

    function setProcessLittleNFTBlockDebt(uint256 blockDebt) external onlyOwner {
        processLittleNFTBlockDebt = blockDebt;
    }

    function setRewardDuration(uint256 d) external onlyOwner {
        _rewardDuration = d;
    }
}

contract MAM is AbsToken {
    constructor() AbsToken(
    //SwapRouter
        address(0x10ED43C718714eb63d5aA57B78B54704E256024E),
    //Matic
        address(0xCC42724C6683B7E57334c4E856f4c9965ED682bD),
    //Usdt
        address(0x55d398326f99059fF775485246999027B3197955),
    //DDCX-LP
        address(0x4CCD35Acee186BcA815ec9bbE361B606CA77E22D),
    //MCC-LP
        address(0xedDE512409d8E4d60b2180c8CeafDE8B3A0851cC),
        "MAM",
        "MAM",
        18,
        700000,
    //Receive
        address(0x8A27C812BE8A96589023D4225aA96d1749DF1Acc),
    //Fund
        address(0x1C3Ed377EF0A8B76Ec1553A1946DD990d1C06C50)
    ){

    }
}