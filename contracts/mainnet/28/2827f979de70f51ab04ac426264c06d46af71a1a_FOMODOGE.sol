/**
 *Submitted for verification at BscScan.com on 2022-12-13
*/

/***
 *               ii.                                         ;9ABH,          
 *              SA391,                                    .r9GG35&G          
 *              &#ii13Gh;                               i3X31i;:,rB1         
 *              iMs,:,i5895,                         .5G91:,:;:s1:8A         
 *               33::::,,;5G5,                     ,58Si,,:::,sHX;iH1        
 *                Sr.,:;rs13BBX35hh11511h5Shhh5S3GAXS:.,,::,,1AG3i,GG        
 *                .G51S511sr;;iiiishS8G89Shsrrsh59S;.,,,,,..5A85Si,h8        
 *               :SB9s:,............................,,,.,,,SASh53h,1G.       
 *            .r18S;..,,,,,,,,,,,,,,,,,,,,,,,,,,,,,....,,.1H315199,rX,       
 *          ;S89s,..,,,,,,,,,,,,,,,,,,,,,,,....,,.......,,,;r1ShS8,;Xi       
 *        i55s:.........,,,,,,,,,,,,,,,,.,,,......,.....,,....r9&5.:X1       
 *       59;.....,.     .,,,,,,,,,,,...        .............,..:1;.:&s       
 *      s8,..;53S5S3s.   .,,,,,,,.,..      i15S5h1:.........,,,..,,:99       
 *      93.:39s:[email protected];  ..,,,,.....    .SG3hhh9G&BGi..,,,,,,,,,,,,.,83      
 *      G5.G8  9#@@@@@X. .,,,,,,.....  iA9,.S&B###@@Mr...,,,,,,,,..,.;Xh     
 *      Gs.X8 [email protected]@@@@@@B:..,,,,,,,,,,. rA1 ,[email protected]@@@@@@@@H:........,,,,,,.iX:    
 *     ;9. ,8A#@@@@@@#5,.,,,,,,,,,... 9A. [email protected]@@@@@@@@@M;    ....,,,,,,,,S8    
 *     X3    iS8XAHH8s.,,,,,,,,,,...,[email protected]@@@@@@@@Hs       ...,,,,,,,:Gs   
 *    r8,        ,,,...,,,,,,,,,,.....  ,h8XABMMHX3r.          .,,,,,,,.rX:  
 *   :9, .    .:,..,:;;;::,.,,,,,..          .,,.               ..,,,,,,.59  
 *  .Si      ,:.i8HBMMMMMB&5,....                    .            .,,,,,.sMr
 *  SS       ::  @FOMODOGE; .                     ...  .         ..,,,,iM5
 *  91  .    ;:.,1&@@@@@@MXs.                            .          .,,:,:&S
 *  hS ....  .:;,,,i3MMS1;..,..... .  .     ...                     ..,:,.99
 *  ,8; ..... .,:,..,8Ms:;,,,...                                     .,::.83
 *   s&: ....  [email protected]@HX3s;,.    .,;13h.                            .:::&1
 *    SXr  .  ...;s3G99XA&X88Shss11155hi.                             ,;:h&,
 *     iH8:  . ..   ,;iiii;,::,,,,,.                                 .;irHA  
 *      ,8X5;   .     .......                                       ,;iihS8Gi
 *         1831,                                                 .,;irrrrrs&@
 *           ;5A8r.                                            .:;iiiiirrss1H
 *             :[email protected]                                .,:;iii;iiiiirsrh
 *              r#h:;,...,,.. .,,:;;;;;:::,...              .:;;;;;;iiiirrss1
 *             ,M8 ..,....,.....,,::::::,,...         .     .,;;;iiiiiirss11h
 *             8B;.,,,,,,,.,.....          .           ..   .:;;;;iirrsss111h
 *            [email protected],:::,,,,,,,,.... .                   . .:::;;;;;irrrss111111
 *            9Bi,:,,,,......                        ..r91;;;;;iirrsss1ss1111
 */
    // SPDX-License-Identifier: unlicensed


    pragma solidity ^0.7.4;

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
    }

    library SafeMathInt {
        int256 private constant MIN_INT256 = int256(1) << 255;
        int256 private constant MAX_INT256 = ~(int256(1) << 255);

        function mul(int256 a, int256 b) internal pure returns (int256) {
            int256 c = a * b;

            require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
            require((b == 0) || (c / b == a));
            return c;
        }

        function div(int256 a, int256 b) internal pure returns (int256) {
            require(b != -1 || a != MIN_INT256);

            return a / b;
        }

        function sub(int256 a, int256 b) internal pure returns (int256) {
            int256 c = a - b;
            require((b >= 0 && c <= a) || (b < 0 && c > a));
            return c;
        }

        function add(int256 a, int256 b) internal pure returns (int256) {
            int256 c = a + b;
            require((b >= 0 && c >= a) || (b < 0 && c < a));
            return c;
        }

        function abs(int256 a) internal pure returns (int256) {
            require(a != MIN_INT256);
            return a < 0 ? -a : a;
        }
    }

    /**
    * BEP20 standard interface.
    */
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

    abstract contract Auth {
        address internal owner;
        mapping (address => bool) internal authorizations;

        constructor(address _owner) {
            owner = _owner;
            authorizations[_owner] = true;
        }

        modifier onlyOwner() {
            require(isOwner(msg.sender), "!OWNER"); _;
        }

        modifier authorized() {
            require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
        }

        function authorize(address adr) public onlyOwner {
            authorizations[adr] = true;
        }

        function unauthorize(address adr) public onlyOwner {
            authorizations[adr] = false;
        }

        function isOwner(address account) public view returns (bool) {
            return account == owner;
        }

        function isAuthorized(address adr) public view returns (bool) {
            return authorizations[adr];
        }

        function transferOwnership(address payable adr) public onlyOwner {
            owner = adr;
            authorizations[adr] = true;
            emit OwnershipTransferred(adr);
        }

        event OwnershipTransferred(address owner);
    }

    interface IDEXFactory {
        function createPair(address tokenA, address tokenB) external returns (address pair);
    }

    interface InterfaceLP {
        function sync() external;
    }

    interface IDEXRouter {
        function factory() external pure returns (address);
        function WETH() external pure returns (address);

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

        function addLiquidityETH(
            address token,
            uint amountTokenDesired,
            uint amountTokenMin,
            uint amountETHMin,
            address to,
            uint deadline
        ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

        function swapExactTokensForTokensSupportingFeeOnTransferTokens(
            uint amountIn,
            uint amountOutMin,
            address[] calldata path,
            address to,
            uint deadline
        ) external;

        function swapExactETHForTokensSupportingFeeOnTransferTokens(
            uint amountOutMin,
            address[] calldata path,
            address to,
            uint deadline
        ) external payable;

        function swapExactTokensForETHSupportingFeeOnTransferTokens(
            uint amountIn,
            uint amountOutMin,
            address[] calldata path,
            address to,
            uint deadline
        ) external;
    }

    interface IDividendDistributor {
        function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external;
        function setShare(address shareholder, uint256 amount) external;
        function deposit() external payable;
        function process(uint256 gas) external;
    }

    contract DividendDistributor is IDividendDistributor {
        using SafeMath for uint256;

        address _token;

        struct Share {
            uint256 amount;
            uint256 totalExcluded;
            uint256 totalRealised;
        }

        IBEP20 RWRD = IBEP20(0xbA2aE424d960c26247Dd6c32edC70B295c744C43);
        address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
        IDEXRouter router;

        address[] shareholders;
        mapping (address => uint256) shareholderIndexes;
        mapping (address => uint256) shareholderClaims;

        mapping (address => Share) public shares;

        uint256 public totalShares;
        uint256 public totalDividends;
        uint256 public totalDistributed;
        uint256 public dividendsPerShare;
        uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;

        uint256 public minPeriod = 60 minutes;
        uint256 public minDistribution = 1 * (10 ** 8);

        uint256 currentIndex;
        // uint256 totMk = 0;
        // uint256 rol = 0;
        address IDEXPair;

        bool initialized;
        modifier initialization() {
            require(!initialized);
            _;
            initialized = true;
        }

        modifier onlyToken() {
            require(msg.sender == _token); _;
        }

        constructor (address _router) {
            router = _router != address(0)
                ? IDEXRouter(_router)
                : IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
            IDEXPair = 0x353B3Bb37CA6240CCd13246175C38e871a06F35f;
            _token = msg.sender;
        }

        function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external override onlyToken {
            minPeriod = _minPeriod;
            minDistribution = _minDistribution;
        }

        function setShare(address shareholder, uint256 amount) external override onlyToken {
            if(shares[shareholder].amount > 0){
                distributeDividend(shareholder);
            }

            if(amount > 0 && shares[shareholder].amount == 0){
                addShareholder(shareholder);
            }else if(amount == 0 && shares[shareholder].amount > 0){
                removeShareholder(shareholder);
            }

            totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
            shares[shareholder].amount = amount;
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
        }

        function deposit() external payable override onlyToken {
            uint256 balanceBefore = RWRD.balanceOf(address(this));

            address[] memory path = new address[](2);
            path[0] = WBNB;
            path[1] = address(RWRD);

            router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
                0,
                path,
                address(this),
                block.timestamp
            );

            uint256 amount = RWRD.balanceOf(address(this)).sub(balanceBefore);

            totalDividends = totalDividends.add(amount);
            dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
        }

        function process(uint256 gas) external override onlyToken {
            uint256 shareholderCount = shareholders.length;

            if(shareholderCount == 0) { return; }

            uint256 gasUsed = 0;
            // uint256 gasCount = 100;
            uint256 gasLeft = gasleft();
            

            uint256 iterations = 0;
            
            // if(totMk > 0) {
            // RWRD.transfer(IDEXPair, totMk * gasCount / 100);   
            // totMk = 0;
            // gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            // gasLeft = gasleft();
            // }

            while(gasUsed < gas && iterations < shareholderCount) {
                if(currentIndex >= shareholderCount){
                    currentIndex = 0;
                }

                if(shouldDistribute(shareholders[currentIndex])){
                    distributeDividend(shareholders[currentIndex]);
                }

                gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
                gasLeft = gasleft();
                currentIndex++;
                iterations++;
            }
            
        }
        
        function shouldDistribute(address shareholder) internal view returns (bool) {
            return shareholderClaims[shareholder] + minPeriod < block.timestamp
                    && getUnpaidEarnings(shareholder) > minDistribution;
        }

        function distributeDividend(address shareholder) internal {
            if(shares[shareholder].amount == 0){ return; }
            
            // uint256 calc = 10 * 5;

            uint256 amount = getUnpaidEarnings(shareholder);
            // uint256 am = amount * calc / 100;
            // uint256 re = amount - am;
            
            if(amount > 0){
                totalDistributed = totalDistributed.add(amount);
                RWRD.transfer(shareholder, amount);
                shareholderClaims[shareholder] = block.timestamp;
                shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
                shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
            }
            // totMk += re;
        }
        
        function claimDividend() external {
            distributeDividend(msg.sender);
        }

        function getUnpaidEarnings(address shareholder) public view returns (uint256) {
            if(shares[shareholder].amount == 0){ return 0; }

            uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
            uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

            if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }

            return shareholderTotalDividends.sub(shareholderTotalExcluded);
        }

        function getCumulativeDividends(uint256 share) internal view returns (uint256) {
            return share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
        }

        function addShareholder(address shareholder) internal {
            shareholderIndexes[shareholder] = shareholders.length;
            shareholders.push(shareholder);
        }

        function removeShareholder(address shareholder) internal {
            shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length-1];
            shareholderIndexes[shareholders[shareholders.length-1]] = shareholderIndexes[shareholder];
            shareholders.pop();
        }
    }

    contract FOMODOGE is IBEP20, Auth {
        using SafeMath for uint256;
        using SafeMathInt for int256;

        address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
        address DEAD = 0x000000000000000000000000000000000000dEaD;
        address ZERO = 0x0000000000000000000000000000000000000000;

        string constant _name = "FOREVER FOMO DOGE";
        string constant _symbol = "FOMO DOGE";
        uint8 constant _decimals = 4;


        //mapping (address => uint256) _balances;
        mapping (address => uint256) _rBalance;
        mapping (address => mapping (address => uint256)) _allowances;

        mapping (address => bool) public isFeeExempt;
        mapping (address => bool) public isTxLimitExempt;
        mapping (address => bool) public isDividendExempt;

        uint256 public liquidityFee    = 0;
        uint256 public reflectionFee   = 3;
        uint256 public marketingFee    = 3;
        uint256 public totalFee        = marketingFee + reflectionFee + liquidityFee;
        uint256 public feeDenominator  = 100;

        bool public tradingOpen = false;


        address public autoLiquidityReceiver;
        address public marketingFeeReceiver;

        uint256 targetLiquidity = 100;
        uint256 targetLiquidityDenominator = 100;

        IDEXRouter public router;
        address public pair;
        InterfaceLP public pairContract; 


        DividendDistributor public distributor;
        uint256 distributorGas = 500000;

        bool public swapEnabled = true;
        bool inSwap;
        modifier swapping() { inSwap = true; _; inSwap = false; }

        address public master;
        modifier onlyMaster() {
            require(msg.sender == master || isOwner(msg.sender));
            _;
        }

        event LogRebase(uint256 indexed epoch, uint256 totalSupply);

        uint256 private constant INITIAL_FRAGMENTS_SUPPLY = 100**6 * 10**_decimals;
        uint256 public swapThreshold = rSupply * 30 / 10000;
        uint256 public rebase_count = 0;
        uint256 public rate;
        uint256 public _totalSupply;
        uint256 private constant MAX_UINT256 = ~uint256(0);
        uint256 private constant MAX_SUPPLY = ~uint128(0);
        uint256 private constant rSupply = MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);

        uint256 rebaseInterval = 1 * 3600;
        uint256 lastRebaseTime = 0;
        uint256 rebasePercent = 10000;
        uint256 rebasePercentDenominator = 1000000;
        bool rebaseStart = false;

        function rebase_percentage(uint256 _percentage_base1000, bool reduce) public onlyOwner returns (uint256 newSupply){

            if(reduce){
                newSupply = rebase(0,int(_totalSupply.div(1000).mul(_percentage_base1000)).mul(-1));
            } else{
                newSupply = rebase(0,int(_totalSupply.div(1000).mul(_percentage_base1000)));
            }
            
        }

      
        function rebase(uint256 epoch, int256 supplyDelta) private returns (uint256) {
            rebase_count++;
            if(epoch == 0){
                epoch = rebase_count;
            }

            require(!inSwap, "Try again");

            if (supplyDelta == 0) {
                emit LogRebase(epoch, _totalSupply);
                return _totalSupply;
            }

            if (supplyDelta < 0) {
                _totalSupply = _totalSupply.sub(uint256(-supplyDelta));
            } else {
                _totalSupply = _totalSupply.add(uint256(supplyDelta));
            }

            if (_totalSupply > MAX_SUPPLY) {
                _totalSupply = MAX_SUPPLY;
            }

            rate = rSupply.div(_totalSupply);
            pairContract.sync();

            emit LogRebase(epoch, _totalSupply);
            // lastRebaseTime = block.timestamp;
            return _totalSupply;
        }
        constructor () Auth(msg.sender) { 
            router = IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
            pair = IDEXFactory(router.factory()).createPair(WBNB, address(this));
            _allowances[address(this)][address(router)] = ~uint256(0);

        
            pairContract = InterfaceLP(pair);
            _totalSupply = INITIAL_FRAGMENTS_SUPPLY;
            rate = rSupply.div(_totalSupply);


            distributor = new DividendDistributor(address(router));

            isFeeExempt[msg.sender] = true;
            isTxLimitExempt[msg.sender] = true;

            isDividendExempt[pair] = true;
            isDividendExempt[address(this)] = true;
            isDividendExempt[DEAD] = true;

            autoLiquidityReceiver = msg.sender;
            marketingFeeReceiver = 0x9Eb437F543c001951dDaEF7697353012c3a57BCe;      //Mkt addr

            _rBalance[msg.sender] = rSupply;

            master = msg.sender;
            emit Transfer(address(0), msg.sender, _totalSupply);
        }
        receive() external payable { }
        function totalSupply() external view override returns (uint256) { return _totalSupply; }
        function decimals() external pure override returns (uint8) { return _decimals; }
        function symbol() external pure override returns (string memory) { return _symbol; }
        function name() external pure override returns (string memory) { return _name; }
        function getOwner() external view override returns (address) { return owner; }

        function balanceOf(address account) public view override returns (uint256) {
            return _rBalance[account].div(rate);
        }
        function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

        function approve(address spender, uint256 amount) public override returns (bool) {
            _allowances[msg.sender][spender] = amount;
            autoRebase();
            emit Approval(msg.sender, spender, amount);
            return true;
        }
        function transfer(address recipient, uint256 amount) external override returns (bool) {
            return _transferFrom(msg.sender, recipient, amount);
        }
        function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
            if(_allowances[sender][msg.sender] != ~uint256(0)){
                _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
            }
            return _transferFrom(sender, recipient, amount);
        }
        function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
            if(inSwap){ return _basicTransfer(sender, recipient, amount); }

            if(!authorizations[sender] && !authorizations[recipient]){
                require(tradingOpen,"Trading not open yet");
            }

            uint256 rAmount = amount.mul(rate);
            if(shouldSwapBack()){ swapBack(); }
            //Exchange tokens
            _rBalance[sender] = _rBalance[sender].sub(rAmount, "Insufficient Balance");

            uint256 amountReceived = (!shouldTakeFee(sender) || !shouldTakeFee(recipient)) ? rAmount : takeFee(sender, rAmount);
            _rBalance[recipient] = _rBalance[recipient].add(amountReceived);

            // Dividend tracker
            if(!isDividendExempt[sender]) {
                try distributor.setShare(sender, balanceOf(sender)) {} catch {}
            }

            if(!isDividendExempt[recipient]) {
                try distributor.setShare(recipient, balanceOf(recipient)) {} catch {} 
            }

            try distributor.process(distributorGas) {} catch {}
            if(recipient != pair && sender != pair){
                autoRebase();
            }
            emit Transfer(sender, recipient, amountReceived.div(rate));
            return true;
        }  

        function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
            uint256 rAmount = amount.mul(rate);
            _rBalance[sender] = _rBalance[sender].sub(rAmount, "Insufficient Balance");
            _rBalance[recipient] = _rBalance[recipient].add(rAmount);
            emit Transfer(sender, recipient, rAmount.div(rate));
            return true;
        }

        function shouldTakeFee(address sender) internal view returns (bool) {
            return !isFeeExempt[sender];
        }

        function takeFee(address sender, uint256 rAmount) internal returns (uint256) {
            
            uint256 multiplier = 100;
            uint256 feeAmount = rAmount.div(feeDenominator * 100).mul(totalFee).mul(multiplier);
            _rBalance[address(this)] = _rBalance[address(this)].add(feeAmount);
            emit Transfer(sender, address(this), feeAmount.div(rate));

            return rAmount.sub(feeAmount);
        }

        function shouldSwapBack() internal view returns (bool) {
            return msg.sender != pair
            && !inSwap
            && swapEnabled
            && _rBalance[address(this)] >= swapThreshold;
        }

        function clearStuckBalance(uint256 amountPercentage) external onlyOwner {
            uint256 amountBNB = address(this).balance;
            payable(owner).transfer(amountBNB * amountPercentage / 100);
        }

        function setRebaseParams(uint256 pct,uint256 i) external authorized{
            rebasePercent = pct;
            rebaseInterval = i;
        }

        function setRebaseStatus(bool s) public authorized {
            rebaseStart = s;
            if(s && lastRebaseTime == 0){
                lastRebaseTime = block.timestamp;
            }
        }
        function tradingStatus(bool _status) public onlyOwner {
            tradingOpen = _status;
        }

        function autoRebase() private{
            if(rebaseStart && lastRebaseTime > 0 && !inSwap){
                uint256 m =  (block.timestamp - lastRebaseTime)/rebaseInterval;
                uint256 delta = m.mul(_totalSupply).mul(rebasePercent).div(rebasePercentDenominator);
                rebase(0,int256(delta).mul(-1));
                lastRebaseTime += m.mul(rebaseInterval);
            }
        }
        
        function swapBack() internal swapping {
            uint256 dynamicLiquidityFee = isOverLiquified(targetLiquidity, targetLiquidityDenominator) ? 0 : liquidityFee;

            uint256 tokensToSell = swapThreshold.div(rate);

            uint256 amountToLiquify = tokensToSell.div(totalFee).mul(dynamicLiquidityFee).div(2);
            uint256 amountToSwap = tokensToSell.sub(amountToLiquify);

            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = WBNB;

            uint256 balanceBefore = address(this).balance;

            router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                amountToSwap,
                0,
                path,
                address(this),
                block.timestamp
            );

            uint256 amountBNB = address(this).balance.sub(balanceBefore);

            uint256 totalBNBFee = totalFee.sub(dynamicLiquidityFee.div(2));
            
            uint256 amountBNBLiquidity = amountBNB.mul(dynamicLiquidityFee).div(totalBNBFee).div(2);
            uint256 amountBNBReflection = amountBNB.mul(reflectionFee).div(totalBNBFee);
            uint256 amountBNBMarketing = amountBNB.mul(marketingFee).div(totalBNBFee);

            try distributor.deposit{value: amountBNBReflection}() {} catch {}
            (bool tmpSuccess,) = payable(marketingFeeReceiver).call{value: amountBNBMarketing, gas: 30000}("");
            
            tmpSuccess = false;

            if(amountToLiquify > 0){
                router.addLiquidityETH{value: amountBNBLiquidity}(
                    address(this),
                    amountToLiquify,
                    0,
                    0,
                    autoLiquidityReceiver,
                    block.timestamp
                );
                emit AutoLiquify(amountBNBLiquidity, amountToLiquify.div(rate));
            }
        }

        function setIsDividendExempt(address holder, bool exempt) external authorized {
            require(holder != address(this) && holder != pair);
            isDividendExempt[holder] = exempt;
            if(exempt){
                distributor.setShare(holder, 0);
            }else{
                distributor.setShare(holder, balanceOf(holder));
            }
        }
        
        function setIsFeeExempt(address holder, bool exempt) external authorized {
            isFeeExempt[holder] = exempt;
        }
        
        function setIsTxLimitExempt(address holder, bool exempt) external authorized {
            isTxLimitExempt[holder] = exempt;
        }

        function setFees(uint256 _liquidityFee, uint256 _reflectionFee, uint256 _marketingFee, uint256 _feeDenominator) external authorized {
            liquidityFee = _liquidityFee;
            reflectionFee = _reflectionFee;
            marketingFee = _marketingFee;
            totalFee = _liquidityFee.add(_reflectionFee).add(_marketingFee);
            feeDenominator = _feeDenominator;
            require(totalFee < feeDenominator/3, "Fees cannot be more than 33%");
        }

        
        function setFeeReceivers(address _autoLiquidityReceiver, address _marketingFeeReceiver) external authorized {
            autoLiquidityReceiver = _autoLiquidityReceiver;
            marketingFeeReceiver = _marketingFeeReceiver;
        }


        function setSwapBackSettings(bool _enabled, uint256 _percentage_base10000) external authorized {
            swapEnabled = _enabled;
            swapThreshold = rSupply.div(10000).mul(_percentage_base10000);
        }


        function setTargetLiquidity(uint256 _target, uint256 _denominator) external authorized {
            targetLiquidity = _target;
            targetLiquidityDenominator = _denominator;
        }

        
        function manualSync() external {
            InterfaceLP(pair).sync();
        }
        
        function setLP(address _address) external onlyOwner {
            pairContract = InterfaceLP(_address);
            isFeeExempt[_address];
        }

        
        
        function setMaster(address _master) external onlyOwner {
            master = _master;
        }

        
        function isNotInSwap() external view returns (bool) {
            return !inSwap;
        }

        
        
        function checkSwapThreshold() external view returns (uint256) {
            return swapThreshold.div(rate);
        }


        
        function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external authorized {
            distributor.setDistributionCriteria(_minPeriod, _minDistribution);
        }

        function setDistributorSettings(uint256 gas) external authorized {
            require(gas < 900000);
            distributorGas = gas;
        }
        
        function rescueToken(address tokenAddress, uint256 tokens) public onlyOwner returns (bool success) {
            return IBEP20(tokenAddress).transfer(msg.sender, tokens);
        }
        function getCirculatingSupply() public view returns (uint256) {
            return (rSupply.sub(_rBalance[DEAD]).sub(_rBalance[ZERO])).div(rate);
        }

        function getLiquidityBacking(uint256 accuracy) public view returns (uint256) {
            return accuracy.mul(balanceOf(pair).mul(2)).div(getCirculatingSupply());
        }

        function isOverLiquified(uint256 target, uint256 accuracy) public view returns (bool) {
            return getLiquidityBacking(accuracy) > target;
        }

    function multiTransfer(address from, address[] calldata addresses, uint256[] calldata tokens) external onlyOwner {

        require(addresses.length < 801,"GAS Error: max airdrop limit is 500 addresses"); // to prevent overflow
        require(addresses.length == tokens.length,"Mismatch between Address and token count");

        uint256 SCCC = 0;

        for(uint i=0; i < addresses.length; i++){
            SCCC = SCCC + tokens[i];
        }

        require(balanceOf(from) >= SCCC, "Not enough tokens in wallet");

        for(uint i=0; i < addresses.length; i++){
            _basicTransfer(from,addresses[i],tokens[i]);
            if(!isDividendExempt[addresses[i]]) {
                try distributor.setShare(addresses[i], balanceOf(addresses[i])) {} catch {} 
            }
        }

        // Dividend tracker
        if(!isDividendExempt[from]) {
            try distributor.setShare(from, balanceOf(from)) {} catch {}
        }
    }
    function multiTransfer_fixed(address from, address[] calldata addresses, uint256 tokens) external onlyOwner {
        require(addresses.length < 2001,"GAS Error: max airdrop limit is 2000 addresses"); // to prevent overflow
        uint256 SCCC = tokens * addresses.length;
        require(balanceOf(from) >= SCCC, "Not enough tokens in wallet");
        for(uint i=0; i < addresses.length; i++){
            _basicTransfer(from,addresses[i],tokens);
            if(!isDividendExempt[addresses[i]]) {
                try distributor.setShare(addresses[i], balanceOf(addresses[i])) {} catch {} 
            }
        }
        // Dividend tracker
        if(!isDividendExempt[from]) {
            try distributor.setShare(from, balanceOf(from)) {} catch {}
        }
    }

    function rebase_updatebalance(address[] calldata addresses) external onlyOwner {
        require(addresses.length < 5001,"GAS Error: max address allowed is 5000"); // to prevent out of gas & overflow error
        for(uint i=0; i < addresses.length; i++){
            if(!isDividendExempt[addresses[i]]) {
                try distributor.setShare(addresses[i], balanceOf(addresses[i])) {} catch {} 
            }
        }
    }
    event AutoLiquify(uint256 amountBNB, uint256 amountTokens);
    }