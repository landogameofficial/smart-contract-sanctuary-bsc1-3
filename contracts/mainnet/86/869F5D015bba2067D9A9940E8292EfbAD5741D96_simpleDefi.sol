//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
import "./Interfaces.sol";
import "./Storage.sol";
// import "hardhat/console.sol";
///@title simpleDefi.sol
///@author Derrick Bradbury ([email protected])
///@notice Common simpleDefi functions not specific to pool/solo contracts
contract simpleDefi is Storage, Ownable, AccessControl {
    event sdAmountTransferred(uint amount, address user);
    event sdInitialized(uint64 poolId, address lpContract);
    event sdLiquidityProvided(uint256 lpOut);
    event sdLiquidatedPool(uint256 poolId, uint256 amount);
    event sdLiquidated(address _user, uint256 _amount, uint _units);
    event sdHarveterAdd(address _harvester);
    event sdFeeSent(address _user, bytes16 _type, uint amount,uint total);
    event sdHeldFunds(uint amount);
    event sdDeposit(uint amount);
   
    error sdFunctionLocked();
    error sdAlreadyInitialized();
    error sdDepositNotAllowed();
    error sdInsufficentFunds();
    error sdAddressError();
    error sdLiquidationTooSoon();
    // error sdHoldBackTooHigh();
    
    ///@notice Prevent function from being run twice
    modifier lockFunction() {
        if (_locked == true) revert sdFunctionLocked();
        _locked = true;
        _;
        _locked = false;
    }
    
    ///@notice Only allow authorized users to execute function
    modifier allowHarvest() {
        if (hasRole(HARVESTER,msg.sender) == false) revert sdFunctionLocked();
        _;
    }

    modifier allowAdmin() {
        if (!(hasRole(DEFAULT_ADMIN_ROLE,msg.sender) || owner() == msg.sender)) revert sdFunctionLocked();
        _;
    }

    ///@notice Add user to allow Harvesting 
    ///@param _address address of user to add
    function addHarvester(address _address) external allowAdmin {
        if (_address == address(0)) revert sdAddressError();

        _setupRole(HARVESTER,_address);
        emit sdHarveterAdd(_address);
    }

    ///@notice Initial setup of contract based on pool
    ///@param _poolId External ID of pool based on exchanges MasterChef contract
    ///@param _beacon beacon contract address
    ///@param _exchangeName string name of the exchange
    ///@param _owner unused to allow for compatibility with solo pools
    ///@dev emit "Initialized" event when initialized
    ///@dev _owner parameter and payable is only there for compatibility with proxy for solo contracts
    function initialize(uint64 _poolId, address _beacon, string memory _exchangeName, address _owner) public payable onlyOwner {
        if (_initialized == true) revert sdAlreadyInitialized();
        if (_beacon == address(0)) revert sdAddressError();
        _initialized = true;       
        paused = false;
        liquidationFee = false;
        beaconContract = _beacon;
        exchange = _exchangeName;    
        revision = 1;
        
        feeCollector = iBeacon(beaconContract).getAddress("FEECOLLECTOR");
        (SwapFee,) = iBeacon(_beacon).getFee(_exchangeName,"SWAPFEE",address(0)); //SWAP FEE is 1e8

        transferOwnership(_owner);
        _setupRole(HARVESTER, iBeacon(beaconContract).getAddress("HARVESTER"));
        _setupRole(DEFAULT_ADMIN_ROLE, iBeacon(beaconContract).getAddress("ADMINUSER"));
        _setupRole(DEFAULT_ADMIN_ROLE,owner());

        (exchangeInfo, iData) = poolUtil.initializePool(_poolId, _beacon, _exchangeName);
    }

    ///@notice Allow admin to pause deposits
    ///@dev Just flips the status, no direct allowance of setting
    function pause() public allowAdmin {
        paused = !paused;
    }

    ///@notice Add depoist to specific user
    ///@dev called during the swap pool function
    ///@param _user address of user to add
    ///@dev emits "sdDeposit" with amount deposited 
    function deposit(address _user) public payable lockFunction {
        if (paused == true) revert sdDepositNotAllowed();
        if(msg.value < 1e16) revert sdInsufficentFunds(); //prevent an attack with tiny amounts
        
        poolUtil.addFunds(iData, mHolders, addFunds(msg.value,_user,true),_user);
 
        emit sdDeposit(msg.value);
    }


    ///@notice Add funds to user
    ///@dev uses msg.value and msg.sender to add deposit
    function deposit() external payable {
        deposit(msg.sender);
    }

    ///@notice Get pending total pending reward for pool
    ///@return uint256 total pending reward
    function getPendingReward() public view returns (uint) {    
        (, bytes memory data) = exchangeInfo.chefContract.staticcall(abi.encodeWithSignature(exchangeInfo.pendingCall, iData.poolId,address(this)));

        return data.length==0?0:abi.decode(data,(uint256)) + ERC20(exchangeInfo.rewardToken).balanceOf(address(this));
    }

    ///@notice remove funds from current pool and deposit into external pool
    ///@param _contract address of external pool
    function swapPool(address _contract) external {
        //liquidate current user and do not send funds
        uint _amount = performLiquidation(msg.sender,false);
        emit sdAmountTransferred(_amount,msg.sender);
        simpleDefi(payable(_contract)).deposit{value: _amount}(msg.sender);
    }
    
    ///@notice remove funds from current pool and send to user
    ///@dev uses msg.sender as user
    function liquidate() external {
        uint _rval = performLiquidation(msg.sender,true);
        if (_rval == 0) revert sdInsufficentFunds();
    }

    ///@notice Administrative force remove funds from current pool and send to user
    ///@param _user address to remove funds from pool 
    function admin_liquidate(address _user) external allowAdmin {
        performLiquidation(_user,true);
    }

    ///@notice Internal processing of liquidation
    ///@param _user address of user to remove funds from pool
    ///@param _sendfunds bool if true funds are sent to user
    ///@return uint amount of funds removed from pool
    function performLiquidation(address _user, bool _sendfunds) internal lockFunction returns (uint) {    
        if (poolUtil.getLastDepositDate(mHolders, _user) + DEPOSIT_HOLD > block.timestamp) revert sdLiquidationTooSoon();
        if ( mHolders.iHolders[_user].amount == 0) return 0;

        uint _units = poolUtil.calcUnits(iData, mHolders,_user, true);
        uint total;

        if (_units > 0) {
            poolUtil.requestFunds(iData, mHolders, _user, 0); // 0 i request everything
            (uint amount0, uint amount1) = poolUtil.removeLiquidity(iData, exchangeInfo, _units,true); //remove liquidity from pool

            (address t0, address t1) = iData.token0 < iData.token1 ? (iData.token0, iData.token1) : (iData.token1, iData.token0); // sort tokens from removeLiquidity to match amount0 and amount1
            
            total += swap(amount0,t0,WBNB_ADDR);
            total += swap(amount1,t1,WBNB_ADDR);                       
            
            uint64 minDepositTime = iBeacon(beaconContract).getConst('DEFAULT','MINDEPOSITTIME');
            if (minDepositTime > 0 && (block.timestamp - mHolders.iHolders[_user].depositDate) <= minDepositTime) {
                (uint fee,) = iBeacon(beaconContract).getFee('DEFAULT','LIQUIDATIONFEE',address(_user));
                uint feeAmount = ((total * fee)/100e18);
                total -= feeAmount;
                payable(feeCollector).transfer(feeAmount);
                emit sdFeeSent(_user, "LIQUIDATIONFEE", feeAmount,total);
            }

            if (_sendfunds) {
                payable(address(_user)).transfer(total);
                emit sdLiquidated(_user, total,_units);
            }
        }
        return total;
    }

    ///@notice remove funds from all users in  current pool and send to user
    function system_liquidate() external allowAdmin lockFunction {
        if (liquidationFee == false) {
            lastGas += iBeacon(beaconContract).getConst('DEFAULT','LIQUIDATIONGAS');
            liquidationFee = true;
        }
        do_harvest(0);

        poolUtil.removeLiquidity(iData,exchangeInfo,0,true);
        revertBalance();  
            
        emit sdLiquidatedPool(iData.poolId, poolUtil.revertShares(iData, mHolders));
    }

    ///@notice Future functionality, sets amount of reward to hold back from re-investment
    ///@param _holdback uint amount of reward to hold back
    // function setHoldback(uint _holdback) external {
    //     if (_holdback > 100*1e18) revert sdHoldBackTooHigh();

    //     mHolders.iHolders[msg.sender].holdback = _holdback;
    //     emit sdHeldFunds(_holdback);
    // }
    
    ///@notice Harvest reward from current pool, and distribute to users
    ///@dev Records gas used for recovery on next run
    function harvest() external lockFunction allowHarvest {
        uint startGas = gasleft() + 21000 + 7339;
        uint allocPoint;
        if (exchangeInfo.psV2)
            (,,allocPoint,,) = iMasterChefv2(exchangeInfo.chefContract).poolInfo(iData.poolId);
        else
            (, allocPoint,,) = iMasterChef(exchangeInfo.chefContract).poolInfo(iData.poolId);

        if (allocPoint == 0) {
            lastGas += iBeacon(beaconContract).getConst('DEFAULT','LIQUIDATIONGAS');
            liquidationFee = true;
        }
        do_harvest(1);               
        // addFunds(address(this).balance,address(0),true);
        lastGas = startGas - gasleft();
    }

    ///@notice helper function to return balance of both tokens in a pair
    ///@return _bal0 is token0 balance
    ///@return _bal1 is token1 balance
    function tokenBalance() internal view returns (uint ,uint ) {
        return (ERC20(iData.token0).balanceOf(address(this)),ERC20(iData.token1).balanceOf(address(this)));
    }    

    ///@notice admin function to send back a token to a user
    ///@param token address of token to be sent
    ///@param _to_user address of user to be refunded
    ///@param _amount amount to send, must be < than token balance
    function rescueToken(address token, address _to_user,uint _amount) external allowAdmin{
        if (token == WBNB_ADDR && address(this).balance >= _amount) {
           payable(_to_user).transfer(_amount);
           return;
        }        

        uint _bal = ERC20(token).balanceOf(address(this));
        if(_amount > _bal) revert sdInsufficentFunds();
        ERC20(token).transfer(_to_user,_amount);
    }

    ///@notice Invest funds into pool
    ///@param inValue amount of money to add into the external pool
    ///@dev take in BNB, split it across the 2 tokens and add the liquidity

    function addFunds(uint inValue, address _user, bool _deposit) private returns (uint liquidity){
        if(inValue <= 10) revert sdInsufficentFunds();
        uint split;
        uint amount0;
        uint amount1;
        if (iData.lastProcess == 0) iData.lastProcess = block.timestamp;

        if (_user != address(0)) {
            inValue = poolUtil.initDeposit(beaconContract, feeCollector, iData, mHolders, inValue,_user);
        }

        if (iData.token0 == WBNB_ADDR || iData.token1 == WBNB_ADDR) {
            split = inValue/2;
            amount0 = (iData.token0 != WBNB_ADDR) ? swap(split,WBNB_ADDR,iData.token0) : split;    
            amount1 = (iData.token1 != WBNB_ADDR) ? swap(split,WBNB_ADDR,iData.token1) : split;
        }
        else {
            amount0 = swap(inValue,WBNB_ADDR,iData.token0);    
            split = amount0/2;
            split = split - ((split*(SwapFee/100))/1e8);                 
            amount1 = swap(split,iData.token0,iData.token1);
            amount0 = split;
        }

        liquidity = poolUtil.addLiquidity(iData,exchangeInfo,amount0,amount1,_deposit);
    }


    ///@notice take amountIn for _token0 and swap for _token1
    ///@param amountIn amount of _token0
    ///@param _token0 address of first token (amountIn source)
    ///@param _token1 address of destination token
    ///@dev generates path, and passes of to overloaded swap function
    ///@return resulting amount of token1 swapped 
    function swap(uint amountIn, address _token0, address _token1) internal returns (uint){
        return poolUtil.swap(exchangeInfo, iData, amountIn,[_token0,_token1],[intToken0,intToken1]);
    }

    ///@notice Perform actual harvest, distributrion does not re-invest
    ///@param revert_trans - if 1 revert transactino if no pending cake, otherwise just return 0
    function do_harvest(uint revert_trans) private returns (uint) {    
        uint pendingCake = getPendingReward();
        if (pendingCake == 0) { //if no pending cake revert or return 0 depending on requiremnts
            if (revert_trans == 1) {
                revert sdInsufficentFunds();
            }
            else {
                    return 0;
            }
        }
        uint _bal = address(this).balance; //Get balance before any distribution fees
        
        iMasterChef(exchangeInfo.chefContract).deposit(iData.poolId,0); //do the harvest
        pendingCake = ERC20(exchangeInfo.rewardToken).balanceOf(address(this)); //get balance of pending cake

        uint reward = swap(pendingCake,exchangeInfo.rewardToken, WBNB_ADDR); //change into BNB
        uint gasRecovery = (lastGas * tx.gasprice); //Calculate gasRecovery in BNB from current gasprice

        // If the reward is < than the gasRecovery, cover gas recovery fees, this should be avoided by setting a high threshold for harvests
        if (gasRecovery > reward) { 
            gasRecovery = reward;
        }
        emit sdFeeSent(address(0),"GASRECOVERY", gasRecovery,reward);
            
        uint finalReward = reward - gasRecovery; //calculate the final reward after gas recovery
        if (finalReward > 0 ) {
            // convert reward into LP tokens to distribute
            uint rewardLP = addFunds(finalReward,address(0), false);

            // Using the LP Tokens, distribute the reward to all accounts. 
            uint feeAmount = poolUtil.distContrib(iData, mHolders, [rewardLP, pendingCake], beaconContract);

            //Calculate the amount of LP Tokens left to be staked
            rewardLP = rewardLP - feeAmount;

            //Stake the remaining LP tokens in the pool
            iMasterChef(exchangeInfo.chefContract).deposit(iData.poolId,rewardLP);
            emit sdLiquidityProvided(rewardLP);

            // Remove the FEE amount left over and convert to BNB
            poolUtil.removeLiquidity(iData, exchangeInfo, feeAmount, false);
            revertBalance();
        }
        else {
            poolUtil.commitFunds(iData,mHolders);
        }

        // Calculate the fee from the opening balance, and the current balance
        _bal = address(this).balance - _bal;
        if(_bal > 0) {
            //send the fee to the collector
            payable(address(feeCollector)).transfer(_bal);
            emit sdFeeSent(address(0), "HARVESTFEE", _bal,pendingCake);
        }

        iData.lastProcess = block.timestamp;

        return finalReward;
    }

    //@notice Function to revert token to base token 
    //@return amount of token reverted
    function revertBalance() internal {
        uint _rewards = ERC20(exchangeInfo.rewardToken).balanceOf(address (this));
        if (_rewards > 0 ){
            swap(_rewards, exchangeInfo.rewardToken,WBNB_ADDR);
        }

        (uint _bal0, uint _bal1) = tokenBalance();
        
        if (iData.token0 != WBNB_ADDR && _bal0 > 0) {
            swap(_bal0, iData.token0,WBNB_ADDR);
        }
        
        if (iData.token1 != WBNB_ADDR && _bal1 > 0) {
            swap(_bal1, iData.token1,WBNB_ADDR);
        }
    }   

    ///@notice Return information on pool holdings based on user
    ///@param _user address of the user
    ///@return lastDeposit timestamp of last deposit
    ///@return units Percentage of pool user holds
    ///@return amount internal tokens held by user
    ///@return _pendingReward amount of pending reward for the user
    ///@return _accumulatedRewards total rewards accumulated by the user
    function userInfo(address _user) external view returns (uint lastDeposit,uint units, uint amount,uint _pendingReward, uint _accumulatedRewards) {   
        (amount,lastDeposit,units, _accumulatedRewards) = poolUtil.getUserInfo(iData, mHolders, _user);
        _pendingReward = pendingRewardUser(_user,units) ;  
    }

    ///@notice Returns pending reward baesd on user
    ///@param _user address of the user
    ///@param _units units allocated to user
    ///@return amount of pending reward for the user
    function pendingRewardUser(address _user, uint _units) public view returns (uint) {
        uint _pendingReward = getPendingReward();  
        if (_units == 0) _units = poolUtil.calcUnits(iData, mHolders,_user,false);

        return (_pendingReward * _units)/1e18;
    }

    ///@notice Returns pending reward baesd on user (overloaded without units)
    ///@param _user address of the user
    ///@return amount of pending reward for the user
    function pendingRewardUser(address _user) public view returns (uint) {
        return pendingRewardUser(_user,0);
    }

    ///@notice Returns pending reward baesd on user (overloaded without user being passed in)
    ///@dev uses msg.sender as user
    ///@return amount of pending reward for the user
    function pendingReward() external view returns (uint) {
        return pendingRewardUser(msg.sender,0);
    }

    ///@notice get pool LP balance
    ///@return _bal of LP tokens held by pool
    function getLPBalance() external view returns (uint _bal) {
        (_bal,) =  iMasterChef(exchangeInfo.chefContract).userInfo(iData.poolId,address(this));
        return _bal;
    }

    ///@notice Runs a check to display information from the pool and the holders
    ///@return _holders total amount held by users, added up individurally
    ///@return _poolTotal Total amount reported by state variable
    ///@return _dQueue total amount of unprocessed deposits
    ///@return _wQueue total amount of unprocessed withdrawals
    function audit() external view returns (uint _holders,uint _poolTotal,uint _dQueue, uint _wQueue){
        (_holders,_poolTotal,_dQueue,_wQueue) = poolUtil.auditHolders(iData,mHolders);        
    }

    ///@notice resets lastGas to 0 for debugging
    function resetGas() external allowAdmin{
        lastGas = 0;
    }

    ///@notice set the intermedate token for each token in the pair
    ///@param _token0 address of the first token in the pair
    ///@param _token1 address of the second token in the pair
    function setInterToken(address _token0, address _token1) public allowAdmin {
        intToken0 = _token0;
        intToken1 = _token1;
    }
}

//SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.0;
import "../Interfaces.sol";

// import "hardhat/console.sol";
///@title poolUtil.sol
///@author Derrick Bradbury ([email protected])
///@dev Library to handle staked pool and distribute rewards amongst stakeholders
library poolUtil {
    event addFunds_evt(address _user, uint _amount);
    event requestFunds_evt(uint _amount);
    event sendFunds_evt(address _to, uint _amount);
    // event sendHoldback_evt(address _to, uint _amount);
    event distContrib_evt(address _to_, uint _units, uint _amount, uint _feeAmount);
    event distContribTotal_evt(uint _total, uint _amount);
    event commitFunds_evt(uint _amount);
    event liquidateFunds_evt(uint _total, uint _amount);
    event returnDeposits_evt(uint _total, uint _amount);
    event Swap(address _from, address _to, uint amountIn, uint amountOut);
    event sdFeeSent(address _user, bytes16 _type, uint amount, uint total);
    event sdInitialized(uint64 poolId, address lpContract);
    event sdLiquidated(address _user, uint256 _amount, uint _units);

    event sdLiquidityProvided(uint256 amount0, uint256 amount1, uint256 lpOut);
    event sdDepositFee(address _user, uint _amount);
    error sdInsufficentFunds();
    error sdBeaconNotConfigured();
    error sdLPContractRequired();
    error sdPoolNotActive();


    ///@notice Add funds to a held pool from a user
    ///@param _self stHolders structure from main contract
    ///@param _amount amount to add for user into staking
    ///@return Amount to be invested
    ///@dev Emits addFunds_evt to notify funds being added
    function initDeposit(address _beacon, address feeCollector, stData storage _self, stHolders storage _holders, uint _amount, address _user) internal returns (uint) {
        require(!_self.paused,"Deposits are Paused");

        if(_holders.iHolders[_user].depositDate == 0) {
            _holders.iQueue.push(_user);
            _holders.iHolders[_user]._pos = _holders.iQueue.length-1;
        }

        if (_user != address(0)) {
            (uint fee,) = iBeacon(_beacon).getFee('DEFAULT','DEPOSITFEE',address(_user));
            if (fee > 0) {
                    uint feeAmount = ((_amount * fee)/100e18);
                    _amount = _amount - feeAmount;
                    payable(feeCollector).transfer(feeAmount);
                    emit sdFeeSent(_user, "DEPOSITFEE", feeAmount,_amount);
            }
        }
        return _amount;
    }
    
    function addFunds(stData storage _self, stHolders storage _holders, uint _amount, address _user) internal {
        transHolders memory _tmp;
        _tmp.amount = _amount;
        _tmp.account = _user;
        _tmp.timestamp = block.timestamp;

        _holders.dHolders.push(_tmp);
        _holders.dQueue[_user].push(_holders.dHolders.length-1);
        _holders.iHolders[_user].depositDate = block.timestamp>_self.lastProcess?block.timestamp:_self.lastProcess; //set users last deposit date
        _holders.iHolders[_user].amount += _amount; // Increment users account
        
        _self.depositTotal += _amount;

        emit addFunds_evt(_user, _amount);

    }
    ///@notice Request funds from a held pool
    ///@dev Overloads requestFunds to request funds from a held pool without adding the user
    ///@param _self stHolders structure from main contract
    ///@param _amount amount to request from staking pool
    ///@return Amount passed in

    function requestFunds(stData storage _self, stHolders storage _holders, uint _amount) internal returns (uint) {
        return requestFunds(_self, _holders, msg.sender, _amount);
    }

    ///@notice User can request funds to be withdrawn, amount put into queue
    ///@param _self stHolders structure from main contract
    ///@param _amount of stake amount to be sent back for user
    ///@dev Emits requestFunds_evt to notify funds being added
    ///@dev if 0 amount is passed in, all requests for user are removed
    function requestFunds(stData storage _self, stHolders storage _holders,address _user, uint _amount) internal returns (uint _returnAmount) {
        require(!_self.paused,"Withdrawals are Paused");
        require(_amount <= _holders.iHolders[_user].amount,"Insufficent Funds");
        if (_amount == 0) _amount = _holders.iHolders[_user].amount;

        transHolders memory _tmp;
        _tmp.amount = _amount;
        _tmp.account = _user;
        _tmp.timestamp = block.timestamp;
        
        _holders.wHolders.push(_tmp);
        uint wholder_len = _holders.wHolders.length;
        _holders.wQueue[_user].push(wholder_len-1);
        _holders.iHolders[_user].amount -= _amount;
        _self.withdrawTotal += _amount;

        _returnAmount = _amount;
        emit requestFunds_evt(_amount);
    }

    ///@notice Function calculates share percentage for particular user
    ///@param _self stHolders structure from main contract
    ///@param _user address of user to calculate
    ///@return _units - returns units based on current blance and total deposits and withdrawals
    function calcUnits(stData storage _self, stHolders storage _holders, address _user, bool _liquidate) internal view returns (uint _units) {
        
        uint _time = block.timestamp - _self.lastProcess; // time since last harvest
        _time = _time > 0 ? _time : 1; // if difference is 0 set it to 1
        
        uint _amt = _holders.iHolders[_user].amount * _time; // Current Users Balance
        
        uint _pt;   // Total amount of deposits for entire pool     
        
        if (!_liquidate) {            
            _pt = _self.poolTotal  * _time; // if pool total is 0 set it to total deposits - withdrawals
            
            //Calculate time based balance only when distributing rewards
            for (uint d = 0; d < _holders.dHolders.length; d++) {     
                if (_holders.dHolders[d].timestamp == 0) continue;       
                uint _ttime = _holders.dHolders[d].timestamp;

                uint _dTime = _ttime - _self.lastProcess; //_holders.dHolders[d].timestamp - _self.lastProcess; //difference between deposit and last harvest user NOT in pool
                uint _tAmt;
                uint _cAmt;
                if (_dTime > 0) {
                    uint _tmpAmount = _holders.dHolders[d].amount; // the amount of the deposit 
                    uint _tmpTime = _time - _dTime; // the time since last harvest

                    _tAmt = _tmpAmount * (_tmpTime>0?_tmpTime:1); // amount to deduct from deposit amount 
                    _pt += _tAmt;

                    if (_holders.dHolders[d].account == _user) {
                        _cAmt = (_tmpAmount * _time) - _tAmt; // amount to deduct from total amount
                        if (_amt > 0)
                            _amt -= _cAmt;
                        else
                            _amt += _tAmt;
                    }
                }    
                else {
                    _pt += _amt;
                }            
            }

            for (uint w = 0; w < _holders.wHolders.length; w++) {
                if (_holders.wHolders[w].timestamp == 0) continue;       
                uint _wTime = block.timestamp - _holders.wHolders[w].timestamp; //Time the user was not in the pool
                uint _cTime = _holders.wHolders[w].timestamp - _self.lastProcess; //Time the user was in the pool
                uint _tmpAmount = _holders.wHolders[w].amount;                

                _pt -= _tmpAmount * _wTime; // remove amount when not in pool.
                
                if (_holders.wHolders[w].account == _user) 
                    if (_amt > 0)
                        _amt -= _tmpAmount * _wTime;
                    else
                        _amt += _tmpAmount * (_cTime>0?_cTime:1);
            }
        }
        else {
            _pt = ((_self.poolTotal +_self.depositTotal) - _self.withdrawTotal) * _time; // Pool Total
        }
                  
        _units = _pt > 0 ? (_amt*(10**18)) / _pt : 0;
        if (_units > 1*10**18) _units = 1*10**18;

        return _units;
    }



    /// @notice Add all deposits to accountholder
    /// @param _self stHolders structure from main contract
    function commitDeposits(stData storage _self, stHolders storage _holders) private {
        for (uint i = _holders.dHolders.length; i > 0; i--) {            
            address _user = _holders.dHolders[i-1].account;

            _holders.iHolders[_user].depositDate = block.timestamp;
            _self.depositTotal -= _holders.dHolders[i-1].amount;
            _self.poolTotal += _holders.dHolders[i-1].amount;
        }
        clearDepositsQueue(_holders,address(0));
    }

    ///@notice Clear out deposits for a specific user
    ///@param _self stHolders structure from main contract
    ///@param _user address of user to clear
    function clearDeposits(stData storage _self, stHolders storage _holders, address _user) internal {
        for (uint i = 0; i < _holders.dHolders.length; i++) {
            if (_holders.dHolders[i].account == _user) {
                _self.depositTotal -= _holders.dHolders[i].amount;
            }
        }
        clearDepositsQueue(_holders,_user);
    }

    ///@notice Clear out Memory for deposits
    ///@param _holders stHolders structure from main contract
    ///@param _user address of user to clear
    function clearDepositsQueue(stHolders storage _holders, address _user) internal {        
        if (_user == address(0)) {
            for (uint i = _holders.dHolders.length;i>0;i--) {
                delete _holders.dQueue[_holders.dHolders[i-1].account];
                _holders.dHolders.pop();
            }
            delete _holders.dHolders;
        }
        else {
            for(uint i = _holders.dQueue[_user].length;i>0;i--){
                delete _holders.dHolders[_holders.dQueue[_user][i-1]];
            }
            delete _holders.dQueue[_user];
        }
    }


    /// @notice Remove all withdrawals to accountholder
    /// @param _self stHolders structure from main contract
    function commitWithdrawals(stData storage _self, stHolders storage _holders) private {
        for (uint i = _holders.wHolders.length; i > 0; i--) {
            address _user = _holders.wHolders[i-1].account;
            _self.withdrawTotal -= _holders.wHolders[i-1].amount;
            _self.poolTotal -= _holders.wHolders[i-1].amount;
            
            if (_holders.iHolders[_user].amount == 0) {
                if (_holders.iQueue.length > 1) {
                    _holders.iQueue[_holders.iHolders[_user]._pos] = _holders.iQueue[_holders.iQueue.length-1];
                    _holders.iQueue.pop();
                }

                delete _holders.iHolders[_user];
            }
        }
        clearWithdrawalQueue(_holders,address(0));
    }

    ///@notice Clear out withdrawal queue for sepcific user
    ///@param _self stHolders structure from main contract
    ///@param _user address of user to clear
    function clearWithdrawals(stData storage _self, stHolders storage _holders, address _user) internal {
        for (uint i = 0; i < _holders.wHolders.length; i++) {
            if (_holders.wHolders[i].account == _user) {
                _self.withdrawTotal -= _holders.wHolders[i].amount;
                if (_self.poolTotal > 0) _self.poolTotal -= _holders.wHolders[i].amount;
            }
        }
        clearWithdrawalQueue(_holders,_user);
    }

    ///@notice Clear out Memory for deposits
    ///@param _holders stHolders structure from main contract
    ///@param _user address of user to clear
    function clearWithdrawalQueue(stHolders storage _holders, address _user) internal {        
        if (_user == address(0)) {
            for (uint i = _holders.wHolders.length;i>0;i--) {
                delete _holders.wQueue[_holders.wHolders[i-1].account];
                _holders.wHolders.pop();
            }
            delete _holders.wHolders;
        }
        else {
            for(uint i = _holders.wQueue[_user].length;i>0;i--){
                delete _holders.wHolders[_holders.wQueue[_user][i-1]];
            }
            delete _holders.wQueue[_user];
        }
    }

    ///@notice Function will distribute BNB to stakeholders based on stake
    ///@return _feeAmount - amount of BNB recovered in fees
    ///@param _self stHolders structure from main contract
    ///@param _amount contains BNB to be distributed to stakeholders based on stake, and amount of reward token to for recording.
    ///@dev emits "distContribTotal_evt" total amount distributed
    ///@dev will revert with math error if more stake is allocated than was supplied in _amount parameter
    function distContrib(stData storage _self, stHolders storage _holders, uint[2] memory _amount, address _beacon) internal returns (uint _feeAmount) {        
        if (_amount[0] > 0) {
            uint _totalDist = 0;
            
            (uint fee,) = iBeacon(_beacon).getFee('DEFAULT','HARVEST',address(0));  // Get the fee without any discounts  

            bool check_fee;
            {// Stack control
                uint last_discount =  iBeacon(_beacon).getDataUint('LASTDISCOUNT'); // Get the timestamp of the last discount applied from the beacon
                check_fee = (last_discount >= _self.lastDiscount)?true:false;
                if (check_fee) _self.lastDiscount = last_discount;
            }

            for(uint i = 0; i < _holders.iQueue.length;i++) {
                address _user = _holders.iQueue[i];
                
                // (uint _units, uint share, uint feeAmount) = calcAmount(_self,_holders,[_user,_beacon], [_amount[0],_amount[1],fee],check_fee);
                (uint[3] memory _rv) = calcAmount(_self,_holders,[_user,_beacon], [_amount[0],_amount[1],fee],check_fee);
                if (_holders.iHolders[_user].amount > 0) _totalDist += _rv[1];
                _feeAmount += _rv[2];

            }
            
            _self.poolTotal += _totalDist;
            require(_amount[0] >= _totalDist,"Distribution failed");
            emit distContribTotal_evt(_totalDist,_amount[0]);

            _self.dust += _amount[0] - _totalDist;
        }

        commitDeposits(_self,_holders);
        commitWithdrawals(_self,_holders);
    }

    function commitFunds(stData storage _self, stHolders storage _holders) internal {
        commitDeposits(_self,_holders);
        commitWithdrawals(_self,_holders);
    }

    ///@notice due to stack limits, this function is broken out of the distContrib function looop
    ///@return _rv - _units, share, feeAmount - due to stack limitations
    ///@param _self stHolders structure from main contract
    ///@param _holders stHolders structure from main contract
    ///@param _addr contains _user and _beacon due to stack limitations
    ///@param _amt contains _amount, _rewardToken, and fee due to stack limitations
    ///@param check_fee bool - true if discount should be looked up
    ///@dev emits "distContrib_evt" for each distribution to user
    ///@dev emits "sendHoldback_evt" if holdback for user is requested
    ///@dev emits "sendFunds_evt" if user has liquidated and final distribution is being sent

    function calcAmount(stData storage _self, stHolders storage _holders, address[2] memory _addr, uint[3] memory _amt, bool check_fee) internal returns (uint[3] memory _rv) {
        //Since user cannot call this function, and parent functions (harvest, and system_liquidate) lock to prevent re-execution,  re-enterancy is not a concern
        uint discount; 

        address _user = _addr[0];
        uint _amount = _amt[0];
        uint _rewardToken = _amt[1];
        uint fee = _amt[2];

        if (check_fee) {    // If there are new discounts, force a check
            uint expires;
            (discount, expires) = iBeacon(_addr[1]).getDiscount(_user);
            if (discount > 0) {
                _holders.iHolders[_user].discount = discount;
                _holders.iHolders[_user].discountValidTo = expires;
            }
        } else { // otherwise use the last discount stored in contract
            // If discountValidTo is 0, it measns it's permanant. If amount is 0 it doesn't matter, as it won't be applied
            discount = (_holders.iHolders[_user].discountValidTo <= block.timestamp) ? _holders.iHolders[_user].discount : 0;                
        } 

        _rv[0] = calcUnits(_self, _holders, _user,false);  // _units or % of reward distribution
        _rv[1] = (_amount * _rv[0])/1e18; // share of bnb to be distributed to user
        _rv[2] = ((_rv[1] * fee)/100e18); // calculate fee amount

        if (discount>0) _rv[2] = _rv[2] - (_rv[2] *(discount/100) / (10**18)); // apply discount if applicable

        _rv[1] = _rv[1] - _rv[2]; // subtract fee from share

        // { // stack control
        //     if (_holders.iHolders[_user].holdback > 0) {
        //         uint holdback = ((_rv[1] * (_holders.iHolders[_user].holdback/100))/1e18); //calculate holdback based on users requested amount
        //         if (_rv[1] >= holdback){
        //             _rv[1] = _rv[1] - holdback; //remove holdback from users share
        //             payable(_user).transfer(holdback);
        //             emit sendHoldback_evt(_user, holdback);
        //         }
        //     }
        // }
        
        if (_holders.iHolders[_user].amount > 0) { // check if the user has already liquidated
            _holders.iHolders[_user].amount += _rv[1]; // add share to user's total share
            uint tokenShare = ((_rewardToken * _rv[0])/1e18); // calculate share of reward token to be distributed to user based on units
            _holders.iHolders[_user].accumulatedRewards += tokenShare - ((tokenShare * fee)/100e18);
        }
        else { // If liquidated send share back to user
            payable(_user).transfer(_rv[1]);
            emit sendFunds_evt(_user, _rv[1]);
        }
        emit distContrib_evt(_user, _rv[0], _rv[1], _rv[2]);
    }


    ///@notice Function will iterate through staked holders and add up total stake and compare to what contract thinks exists
    ///@param _self stHolders structure from main contract
    ///@return Calculated total
    ///@return Contract Pool Total
    function auditHolders(stData storage _self, stHolders storage _holders) public view returns (uint,uint,uint,uint) {
        uint _total = 0;
        for(uint i = _holders.iQueue.length; i > 0;i--){
            address _user = _holders.iQueue[i-1];
            _total += _holders.iHolders[_user].amount;
        }                    
        // _self.dust += 1;

        // return (_total, _self.poolTotal + _self.depositTotal - _self.withdrawTotal,_holders.dHolders.length,_holders.wHolders.length);
        return (_total, _self.poolTotal , _self.depositTotal, _self.withdrawTotal);
    }

    ///@notice Returns user info based on pool info
    ///@param _self stHolders structure from main contract
    ///@param _user Address of user
    ///@return _amount Amount of Units held by user
    ///@return _depositDate Date of last deposit
    ///@return _units Number of units held by user
    ///@return _accumulatedRewards Number of units accumulated by user

    function getUserInfo(stData storage _self, stHolders storage _holders, address _user) public view returns (uint _amount, uint _depositDate, uint _units, uint _accumulatedRewards) {
        _units = calcUnits(_self, _holders, _user,false);        
        // (uint _lpBal,) = iMasterChef(chefContract).userInfo(_self.poolId,address(this));
        // uint _units_amount = calcUnits(_self, _holders, _user,true); // _units_amount must return not based on time in pool, but overall total        
        // _amount = (_lpBal * _units_amount)/1e18;

        _amount = _holders.iHolders[_user].amount;

        _depositDate = _holders.iHolders[_user].depositDate;
        _accumulatedRewards = _holders.iHolders[_user].accumulatedRewards;
    }


    ///@notice Get last deposit date for a user
    ///@param _holders stHolders structure from main contract
    ///@param _user Address of user
    ///@return _depositDate Date of last deposit
    function getLastDepositDate(stHolders storage _holders, address _user) public view returns (uint _depositDate) {
        _depositDate = _holders.iHolders[_user].depositDate;
    }

    ///@notice Remove specified liquidity from the pool
    ///@param _units percent of total liquidity to remove
    ///@return amountTokenA of liquidity removed (Token A)
    ///@return amountTokenB of liquidity removed (Token B)
    function removeLiquidity(stData storage iData, iBeacon.sExchangeInfo memory exchangeInfo,  uint _units, bool _withdraw) external returns (uint amountTokenA, uint amountTokenB){
        (uint _lpBal,) = iMasterChef(exchangeInfo.chefContract).userInfo(iData.poolId,address(this));
        if (_units != 0) {
            _lpBal = (_units * _lpBal)/1e18;
            if(_lpBal == 0) revert sdInsufficentFunds();
        }

        uint deadline = block.timestamp + DEPOSIT_HOLD;
        if (_withdraw) {
            iMasterChef(exchangeInfo.chefContract).withdraw(iData.poolId,_lpBal);
        }
        
        _lpBal = ERC20(iData.lpContract).balanceOf(address(this));

        if (iData.token0 == WBNB_ADDR || iData.token1 == WBNB_ADDR) {
            (amountTokenA, amountTokenB) = iRouter(exchangeInfo.routerContract).removeLiquidityETH(iData.token0==WBNB_ADDR?iData.token1:iData.token0,_lpBal,0,0,address(this), deadline);
            (amountTokenA, amountTokenB) = iData.token0 == WBNB_ADDR ? (amountTokenB, amountTokenA) : (amountTokenA, amountTokenB); // returns eth to amountTokenB
        }
        else
            (amountTokenA, amountTokenB) = iRouter(exchangeInfo.routerContract).removeLiquidity(iData.token0,iData.token1,_lpBal,0,0,address(this), deadline);

        return (amountTokenA, amountTokenB);
    }

    //@notice helper function to add liquidity to the pool
    //@param _amount0 amount of token0 to add to the pool
    //@param _amount1 amount of token1 to add to the pool    
    function addLiquidity(stData storage iData, iBeacon.sExchangeInfo memory exchangeInfo,uint amount0, uint amount1, bool _deposit) external returns (uint liquidity){
        uint amountA;
        uint amountB;

        if (iData.token1 == WBNB_ADDR) {
            (amountA, amountB, liquidity) = iRouter(exchangeInfo.routerContract).addLiquidityETH{value: amount1}(iData.token0, amount0, 0,0, address(this), block.timestamp);
        }
        else if (iData.token0 == WBNB_ADDR) {
            (amountA, amountB, liquidity) = iRouter(exchangeInfo.routerContract).addLiquidityETH{value: amount0}(iData.token1, amount1, 0,0, address(this), block.timestamp);
        }
        else {
            ( amountA,  amountB, liquidity) = iRouter(exchangeInfo.routerContract).addLiquidity(iData.token0, iData.token1, amount0, amount1, 0, 0, address(this), block.timestamp);
        }
        if (_deposit) {
            iMasterChef(exchangeInfo.chefContract).deposit(iData.poolId,liquidity);
            emit sdLiquidityProvided(amountA, amountB, liquidity);
        }
    }


    ///@notice take amountIn for path[0] and swap for token1
    ///@param amountIn amount of path[0]
    ///@param path token path required for swap 
    ///@return resulting amount of path[1] swapped 
    function swap(iBeacon.sExchangeInfo memory exchangeInfo,stData memory iData,uint amountIn, address[2] memory path, address[2] memory intToken) external returns (uint){
        if(amountIn == 0) revert sdInsufficentFunds();

        uint _cBalance = address(this).balance;
        if (path[0] == WBNB_ADDR && path[path.length-1] == WBNB_ADDR) {
            if (ERC20(WBNB_ADDR).balanceOf(address(this)) >= amountIn) {
                iWBNB(WBNB_ADDR).withdraw(amountIn);
                _cBalance = address(this).balance;
            }
            if (amountIn > _cBalance) revert sdInsufficentFunds();
            return amountIn;
        }

        uint pathLength = 2;
        address intermediateToken;

        if (exchangeInfo.intermediateToken != address(0)) {
            intermediateToken = exchangeInfo.intermediateToken;
            pathLength = 3;
        }
        else {
            if (intToken[0] != address(0) && (path[0] == iData.token0 || path[1] == iData.token0)) {
                pathLength = 3;
                intermediateToken = intToken[0];
            }

            if (intToken[1] != address(0) && (path[0] == iData.token1 || path[1] == iData.token1)) {
                pathLength = 3;
                intermediateToken = intToken[1];
            }

            if (path[0] == intermediateToken || path[1] == intermediateToken) {
                pathLength = 2;
                intermediateToken = address(0);
            }
        }

        address[] memory swapPath = new address[](pathLength);

        if (pathLength == 2) {
            swapPath[0] = path[0];
            swapPath[1] = path[1];
        }
        else {
            swapPath[0] = path[0];
            swapPath[1] = intermediateToken;
            swapPath[2] = path[1];
        }

        uint[] memory amounts;


        if (path[0] == WBNB_ADDR && ERC20(WBNB_ADDR).balanceOf(address(this)) >= amountIn) {
            iWBNB(WBNB_ADDR).withdraw(amountIn);
            _cBalance = address(this).balance;
        }
        uint deadline = block.timestamp + 600; 

        if (path[path.length - 1] == WBNB_ADDR) {
            amounts = iRouter(exchangeInfo.routerContract).swapExactTokensForETH(amountIn, 0,  swapPath, address(this), deadline);
        } else if (path[0] == WBNB_ADDR && _cBalance >= amountIn) {
            amounts = iRouter(exchangeInfo.routerContract).swapExactETHForTokens{value: amountIn}(0,swapPath,address(this),deadline);
        }
        else {
            amounts = iRouter(exchangeInfo.routerContract).swapExactTokensForTokens(amountIn, 0,swapPath,address(this),deadline);
        }
        emit Swap(path[0], path[path.length-1],amounts[0], amounts[amounts.length-1]);
        return amounts[amounts.length-1];
    }
    
    function initializePool(uint64 _poolId, address _beacon, string memory _exchangeName) internal returns (iBeacon.sExchangeInfo memory exchangeInfo, stData memory iData) {
        exchangeInfo = iBeacon(_beacon).getExchangeInfo(_exchangeName);
        if (exchangeInfo.chefContract == address(0)) revert sdBeaconNotConfigured();

        address _lpContract;
        uint _alloc;

        if (exchangeInfo.psV2) {
            _lpContract = iMasterChefv2(exchangeInfo.chefContract).lpToken(_poolId);
            (,,_alloc,,) = iMasterChefv2(exchangeInfo.chefContract).poolInfo(_poolId);
        }
        else {
            (_lpContract, _alloc,,) = iMasterChef(exchangeInfo.chefContract).poolInfo(_poolId);
        }
        
        if(_lpContract == address(0)) revert sdLPContractRequired();
        if(_alloc == 0) revert sdPoolNotActive();

        iData.poolId = _poolId;
        iData.lpContract =  _lpContract;
        iData.token0 = iLPToken(_lpContract).token0();
        iData.token1 = iLPToken(_lpContract).token1();

        ERC20(iData.token0).approve(exchangeInfo.routerContract,MAX_INT);
        ERC20(iData.token1).approve(exchangeInfo.routerContract,MAX_INT);
        ERC20(exchangeInfo.rewardToken).approve(exchangeInfo.routerContract,MAX_INT);
        
        iLPToken(_lpContract).approve(exchangeInfo.chefContract,MAX_INT);        
        iLPToken(_lpContract).approve(exchangeInfo.routerContract,MAX_INT);        
        emit sdInitialized(_poolId,_lpContract);
    }

    function revertShares(stData storage iData, stHolders storage mHolders) internal returns (uint _total_base_sent) {
        uint _total_base = address(this).balance;
        //loop through owners and send shares to them
        for (uint i = mHolders.iQueue.length; i > 0; i--) {
            address _user = mHolders.iQueue[i-1];
            uint _units = poolUtil.calcUnits(iData, mHolders,_user,true);
            uint _refund = (_units * _total_base)/1e18;
            _total_base_sent += _refund;
            mHolders.iHolders[_user].amount = 0;
            payable(_user).transfer(_refund);

            delete mHolders.iHolders[_user];
            mHolders.iQueue.pop();
            
            emit sdLiquidated(_user,_refund, _units);
        }
        iData.poolTotal = 0;
        iData.depositTotal = 0;
        iData.withdrawTotal = 0;
    }    
}

//SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./utils/poolUtil.sol";
import "./Interfaces.sol";
contract Storage {
    uint256 public lastGas;
    
    address public beaconContract;
    address public logic_contract;
    address internal feeCollector;
            
    bool internal _locked;
    bool internal _initialized;
    bool internal _shared;

    bytes32 public constant HARVESTER = keccak256("HARVESTER");
    string internal exchange;

    bool internal liquidationFee;
    bool public paused;

    stData public iData;
    stHolders internal mHolders;
    iBeacon.sExchangeInfo public exchangeInfo;

    uint public SwapFee; // 8 decimal places
    uint public revision;

    address intToken0;
    address intToken1;
    // bool bitflip;
}

//SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.7;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
   
uint constant MAX_INT = type(uint).max;
uint constant DEPOSIT_HOLD = 15; // 600;
address constant WBNB_ADDR = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

struct stData {
    address lpContract;
    address token0;
    address token1;

    uint poolId;
    uint dust;        
    uint poolTotal;
    uint unitsTotal;
    uint depositTotal;
    uint withdrawTotal;
    uint lastProcess;
    uint lastDiscount;
    bool paused;
}

struct sHolders {
    uint amount;
    uint holdback;
    uint depositDate;
    uint discount;
    uint discountValidTo;    
    uint accumulatedRewards;    
    uint _pos;
}

struct transHolders {
    uint amount;
    uint timestamp;
    address account;
}

struct stHolders{
    mapping (address=>sHolders) iHolders;
    address[] iQueue;

    transHolders[] dHolders;        
    mapping(address=>uint[]) dQueue;
    
    transHolders[] wHolders;        
    mapping(address=>uint[]) wQueue;
}

interface iMasterChef{
     function pendingCake(uint256 _pid, address _user) external view returns (uint256);
     function poolInfo(uint _poolId) external view returns (address, uint,uint,uint);
     function userInfo(uint _poolId, address _user) external view returns (uint,uint);
     function deposit(uint poolId, uint amount) external;
     function withdraw(uint poolId, uint amount) external;
     function cakePerBlock() external view returns (uint);
     function updatePool(uint poolId) external;
}

interface iMasterChefv2{
    function poolInfo(uint _poolId) external view returns (uint, uint,uint,uint,bool);
    function lpToken(uint _poolId) external view returns (address);
}


interface iRouter { 
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);    
    function swapExactTokensForTokens(uint amountIn,uint amountOutMin,address[] calldata path,address to,uint deadline) external returns (uint[] memory amounts);
    function addLiquidityETH(address token,uint amountTokenDesired ,uint amountTokenMin,uint amountETHMin,address to,uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function addLiquidity(address tokenA,address tokenB,uint amountADesired,uint amountBDesired,uint amountAMin,uint amountBMin,address to,uint deadline) external returns (uint amountA, uint amountB, uint liquidity);
    function removeLiquidityETH(address token,uint liquidity,uint amountTokenMin,uint amountETHMin,address to,uint deadline) external returns (uint amountToken, uint amountETH);
    function removeLiquidity(address tokenA,address tokenB, uint liquidity,uint amountAMin,uint amountBMin,address to,uint deadline) external returns (uint amountToken, uint amountETH);
}

interface iLPToken{
    function token0() external view returns (address);
    function token1() external view returns (address);
    function allowance(address owner, address spender) external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);    
}

interface iBeacon {
    struct sExchangeInfo {
        address chefContract;
        address routerContract;
        address rewardToken;
        address intermediateToken;
        address baseToken;
        string pendingCall;
        string contractType_solo;
        string contractType_pooled;
        bool psV2;
    }

    function getExchangeInfo(string memory _name) external view returns(sExchangeInfo memory);
    function getFee(string memory _exchange, string memory _type, address _user) external returns(uint,uint);
    function getFee(string memory _exchange, string memory _type) external returns(uint,uint);
    function getDiscount(address _user) external view returns(uint,uint);
    function getConst(string memory _exchange, string memory _type) external returns(uint64);
    function getExchange(string memory _exchange) external view returns(address);
    function getAddress(string memory _key) external view returns(address _value);
    function getDataUint(string memory _key) external view returns(uint _value);
}

interface iWBNB {
    function withdraw(uint wad) external;
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
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
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
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
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
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
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
     * bearer except when using {AccessControl-_setupRole}.
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
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

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
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

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
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

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
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
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
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
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
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
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
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
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