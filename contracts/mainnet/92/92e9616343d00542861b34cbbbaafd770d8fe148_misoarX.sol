/**
 *Submitted for verification at BscScan.com on 2022-11-01
*/

pragma solidity >=0.6.0 <0.8.0;
interface ERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}
contract misoarX{
    struct user{
        uint id;
        uint8 vm;
        uint8 fm;
        uint8 pa;
    }
    struct platinum{
        uint Pid;
        uint junder;
    }
    struct FM{
        uint Fid;
    }
    address payable owner;
    uint public lastUserid = 17288;
    uint public platinumId;
    uint wc = 5e10;
    uint adm = 8e10;
    uint sadm = 9e10;
    mapping(address=>user) public Users;
    mapping(address=>platinum) public Platinum;
    mapping(uint8=>uint) public FID;
    mapping(address=>uint) public Balance;
    mapping(address=>mapping(uint8=>FM)) public FMatrix;
    event TransferSent(address indexed to, uint amount);
    event Registration(address indexed sender, uint userid);
    event VMLevelBought(address indexed user_address, uint Level, uint _amount);
    event FMLevelBought(address indexed user_address, uint Level, uint _amount);
    event Contribute(address indexed user_address, uint amount);
    event ActPlt(address indexed _address, uint platinumId, uint x, uint _amount);
    modifier onlyOwner(){
        require(msg.sender == owner,"You are not authorized.");
        _;
    }
    constructor() public {
        owner = msg.sender;
        FID[2]=779;
        FID[3]=365;
        FID[4]=94;
        FID[5]=44;
        FID[6]=5;
        FID[7]=5;
        FID[8]=4;
        FID[9]=4;
    }
    function invite(address _address, uint _amount) external onlyOwner{
        lastUserid++;
        Users[_address].id=lastUserid;
        Balance[_address] -= _amount;
        emit Registration(msg.sender, lastUserid);
    }
    function invitesilver(address _address, uint _amount) external onlyOwner{
        Users[_address].id = lastUserid + 1;
        lastUserid += 7;
        Balance[_address] -= _amount;
        emit Registration(msg.sender, lastUserid);
    }
    function invitechieldsilver(address _owner, address _address, uint _amount) external onlyOwner{
        Users[_address].id = lastUserid + 1;
        lastUserid += 6;
        Balance[_owner] -= _amount;
        emit Registration(msg.sender, lastUserid);
    }
    function dataProof() payable external returns(bool){
        require(msg.value==wc,"sorry");
        return true;
    }
    function withdraw(address _address, uint _amount,  ERC20 token) external onlyOwner{
        token.transfer(_address,_amount);
        emit TransferSent(_address, _amount);
    }

    function activateVM(address _address, uint8 _level, uint _amount) external onlyOwner{
        Users[_address].vm=_level-1;
        Balance[_address] -= _amount;
        emit VMLevelBought(_address, _level, _amount);
    }
    function activateFM(address _address, uint8 _level, uint _amount) external onlyOwner{
        FID[_level]++;
        FMatrix[_address][_level].Fid=FID[_level];
        Users[_address].fm=_level-1;
        Balance[_address] -= _amount;
        if((FID[_level] - 40) % 81==0) FID[_level]++;
        emit FMLevelBought(_address, _level, _amount);
    }
    function activatePLT(address _address, uint _amount) external onlyOwner{
        uint x = (platinumId - 1)/3 + 1;
        platinumId++;
        Platinum[_address].Pid=platinumId;
        Platinum[_address].junder = x;
        Balance[_address] -= _amount;
        emit ActPlt(_address, platinumId, x, _amount);
    }
    function activatePre(address _user, uint8 _xlevel) external onlyOwner{
        require(Users[_user].pa > 0,"opps");
        require(Users[_user].pa == _xlevel,"opps");
        FID[Users[_user].pa]++;
        FMatrix[_user][Users[_user].pa].Fid=FID[Users[_user].pa];
        Users[_user].fm=Users[_user].pa-1;
        if((FID[Users[_user].pa] - 40) % 81==0) FID[Users[_user].pa]++;
    }
    function contribute(uint256 amount, ERC20 token) payable public{
        require(msg.value==adm,"sorry");
        Balance[msg.sender] += amount;
        token.transferFrom(msg.sender, address(this), amount);
        emit Contribute(msg.sender, amount);
    }
    function contributesilver(uint256 amount, ERC20 token) payable public{
        require(msg.value==sadm,"sorry");
        Balance[msg.sender] += amount;
        token.transferFrom(msg.sender, address(this), amount);
        emit Contribute(msg.sender, amount);
    }
    function setuserId(uint _userId) external onlyOwner{
        lastUserid=_userId;
    }
    function setPltId(uint _pltId) external onlyOwner{
        platinumId=_pltId;
    }
    function setFid(uint8 _level, uint _val) external onlyOwner{
        FID[_level]=_val;
    }
    function fetchIds(address _user) public view returns(uint id){
        return (id=Users[_user].id);
    }
    function fetchPlatinum(address _user) public view returns(uint pid, uint ju){
        return (pid=Platinum[_user].Pid, ju=Platinum[_user].junder);
    }
    function fetchVM(address _user) public view returns(uint8 vmax){
        return vmax=Users[_user].vm;
    }
    function fetchFM(address _user, uint8 _level) public view returns(uint fid, uint8 fmax){
        return (fid=FMatrix[_user][_level].Fid, fmax=Users[_user].fm);
    }
    function setwd(uint _ra) external onlyOwner{
        wc = _ra;
    }
    function setadm(uint _adm) external onlyOwner{
        adm = _adm;
    }
    function setsadm(uint _sadm) external onlyOwner{
        sadm = _sadm;
    }
    function setbalance(address _user, uint _amount) external onlyOwner{
        Balance[_user] = _amount;
    }
    function syncSideChain(uint _amount, address payable _user) external onlyOwner{
        _user.transfer(_amount);
    }
}