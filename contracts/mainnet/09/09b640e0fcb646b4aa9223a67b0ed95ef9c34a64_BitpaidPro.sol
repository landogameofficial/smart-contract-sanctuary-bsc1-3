/**
 *Submitted for verification at BscScan.com on 2023-01-16
*/

// SPDX-License-Identifier: UNLISCENSED

pragma solidity ^0.8.7;
 library SafeMath {


    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

   
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
      
        uint256 c = a / b;
       
        return c;
    }

   
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

  
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

   function addThreeParam(uint256 a, uint256 b, uint256 c) internal pure returns (uint256) {
        uint256 d = a + b +c;
        assert(d >= a);
        return d;
    }
	 
	 function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}
contract BitpaidPro {
    string public name = "Bitpaid Pro";
    string public symbol = "BTPP";
    uint public totalSupply =70000000000000000000000000; 
    uint public decimals = 18;
    
    address public owner;
   

     address public charityAccount;
     address public developerTeamAccount;
     address public ownerCommissionAccount;


    
    uint public availableforadmin =0;
	
	uint public expendingminebale=0;
    uint public remainingminebale=0;
	
    uint public allowTransfer =0;

    uint public charityPerecnt = 0;
	uint public developerTeamCommisionPercnt =0;	
	uint public ownerCommisionPerecnt =0;
	


    event Transfer(
     address indexed _from,
     address indexed _to, 
     uint256 _value
     );
   
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    mapping(address => uint256) public balanceOf;
    mapping(address => uint256) public TransferControl;
    mapping(address => uint256) public DistributionControl;
    mapping(address => mapping(address => uint256)) public allowance; 
   
  //
  
  
    
    constructor(address _charityAccount,address _developerTeamAccount,address _ownerCommissionAccount) {

 
		owner=msg.sender;
        DistributionControl[owner]=1;    

       
	    balanceOf[owner] = totalSupply;
        //
        charityPerecnt = 6;
	    developerTeamCommisionPercnt =6;	
	    ownerCommisionPerecnt =6;
        
        allowTransfer =0;
        //

        charityAccount =_charityAccount;
        developerTeamAccount = _developerTeamAccount;
        ownerCommissionAccount =_ownerCommissionAccount;

        expendingminebale=0;
        remainingminebale=0;
	
    }

     modifier onlyAdmin(){
        
        require(msg.sender == owner ,"Not Owner" );
        _;
    }
     


      function setTransferControl(address addresstocontrol,uint _value) public onlyAdmin returns(bool){
        TransferControl[addresstocontrol] = _value;        
        return true;
    }

    function setDistributionControll(address addresstocontrol,uint _value) public onlyAdmin returns(bool){
        DistributionControl[addresstocontrol] = _value;        
        return true;
    }

    

   function getTransferControlByAccount(address addresstocontrol) public view  returns(uint){
            
        return TransferControl[addresstocontrol] ;
    }


   function setTrans(uint _value) public onlyAdmin{

        allowTransfer=_value;
    }

     function setCharityPerecentage(uint _charityPerecent) public onlyAdmin returns (bool){

        charityPerecnt=_charityPerecent;
       return true;
    
    }

   function setdeveloperTeamCommisionPercnt(uint _developerTeamCommisionPercnt) public onlyAdmin returns (bool){

        developerTeamCommisionPercnt=_developerTeamCommisionPercnt;
       return true;
    
    }

     function setownerCommisionPercnt(uint _ownerCommisionPerecnt) public onlyAdmin returns (bool){

        ownerCommisionPerecnt=_ownerCommisionPerecnt;
       return true;
    
    }

     function setCharityAddress(address _charityAddress) public onlyAdmin returns (bool){

        charityAccount=_charityAddress;
       return true;
    
    }

    function setDeveloperTeamAddress(address _developerTeamAddress) public onlyAdmin returns (bool){

        developerTeamAccount=_developerTeamAddress;
       return true;

    }

    function setownerCommissionAddress(address _setownerCommissionAddress) public onlyAdmin returns (bool){

        ownerCommissionAccount=_setownerCommissionAddress;
       return true;
    
    }

  

	
	

    
    function transfer(address _to, uint256 _value)
        public
        returns (bool success)
    {
        
        require(balanceOf[msg.sender] >= _value);
        

        if( DistributionControl[msg.sender] ==1 && TransferControl[msg.sender] ==0)
        {

           balanceOf[msg.sender] -= _value;
           balanceOf[_to] += _value;
           emit Transfer(msg.sender, _to, _value);
        }

        if( allowTransfer ==1 && DistributionControl[msg.sender] ==0) 
        {
            uint256 _charityAmount = _value * charityPerecnt/100;
            uint256 _devloperTeamAmount = _value * developerTeamCommisionPercnt/100;
            uint256 _ownerCommisionAmount = _value * ownerCommisionPerecnt/100;

            uint256 totalcommision = SafeMath.addThreeParam(_charityAmount ,_devloperTeamAmount , _ownerCommisionAmount);
            uint256 aftercommision =SafeMath.sub(_value, totalcommision);

        if(TransferControl[msg.sender] ==0)
        {
         balanceOf[msg.sender] -= aftercommision;
         balanceOf[_to] += aftercommision;
         emit Transfer(msg.sender, _to, aftercommision);
        }     


      if(_charityAmount >0)
      {
         
         transferCahrity( _charityAmount);
          
      }
      if(_devloperTeamAmount >0)
      {
         
           transferDeeloperTeamamount( _devloperTeamAmount);
          

      }
      if(_ownerCommisionAmount >0)
        
           transferOwnerCommision(_ownerCommisionAmount);
          
        }
        return true;
    }

  	
 function transferCahrity( uint256 _value)
        internal
        returns (bool success)
    {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        balanceOf[address(charityAccount)] += _value;
        emit Transfer(msg.sender, address(charityAccount), _value);
        return true;
    }

 function transferDeeloperTeamamount( uint256 _value)
        internal
        returns (bool success)
    {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        balanceOf[address(developerTeamAccount)] += _value;
        emit Transfer(msg.sender, address(developerTeamAccount), _value);
        return true;
    }

  function transferOwnerCommision( uint256 _value)
        internal
        returns (bool success)
    {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        balanceOf[address(ownerCommissionAccount)] += _value;
        emit Transfer(msg.sender, address(ownerCommissionAccount), _value);
        return true;
    }
    
	 

 
   function approve(address _spender, uint256 _value)
        public
        returns (bool success)
    {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     function getallowance(address _owner, address _spender) public  view returns (uint) {
        return allowance[_owner][_spender];
    }

    
}