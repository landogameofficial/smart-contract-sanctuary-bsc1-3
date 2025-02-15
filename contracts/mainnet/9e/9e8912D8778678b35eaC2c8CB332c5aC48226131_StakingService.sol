// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Enjinstarter
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./libraries/UnitConverter.sol";
import "./AdminPrivileges.sol";
import "./AdminWallet.sol";
import "./interfaces/IStakingPool.sol";
import "./interfaces/IStakingService.sol";

/**
 * @title StakingService
 * @author Tim Loh
 * @notice Provides staking functionalities
 */
contract StakingService is
    Pausable,
    AdminPrivileges,
    AdminWallet,
    IStakingService
{
    using SafeERC20 for IERC20;
    using UnitConverter for uint256;

    struct StakeInfo {
        uint256 stakeAmountWei;
        uint256 lastStakeAmountWei;
        uint256 stakeTimestamp;
        uint256 stakeMaturityTimestamp; // timestamp when stake matures
        uint256 estimatedRewardAtMaturityWei; // estimated reward at maturity in Wei
        uint256 rewardClaimedWei; // reward claimed in Wei
        bool isActive; // true if allow claim rewards and unstake
        bool isInitialized; // true if stake info has been initialized
    }

    struct StakingPoolStats {
        uint256 totalRewardWei; // total pool reward in Wei
        uint256 totalStakedWei; // total staked inside pool in Wei
        uint256 rewardToBeDistributedWei; // allocated pool reward to be distributed in Wei
        uint256 totalRevokedStakeWei; // total revoked stake in Wei
    }

    uint256 public constant DAYS_IN_YEAR = 365;
    uint256 public constant PERCENT_100_WEI = 100 ether;
    uint256 public constant SECONDS_IN_DAY = 86400;
    uint256 public constant TOKEN_MAX_DECIMALS = 18;

    address public stakingPoolContract;

    mapping(bytes => StakeInfo) private _stakes;
    mapping(bytes32 => StakingPoolStats) private _stakingPoolStats;

    constructor(address stakingPoolContract_) {
        require(stakingPoolContract_ != address(0), "SSvcs: staking pool");

        stakingPoolContract = stakingPoolContract_;
    }

    /**
     * @inheritdoc IStakingService
     */
    function claimReward(bytes32 poolId)
        external
        virtual
        override
        whenNotPaused
    {
        (
            ,
            ,
            ,
            address rewardTokenAddress,
            uint256 rewardTokenDecimals,
            ,
            ,
            bool isPoolActive
        ) = _getStakingPoolInfo(poolId);
        require(isPoolActive, "SSvcs: pool suspended");

        bytes memory stakekey = _getStakeKey(poolId, msg.sender);
        require(_stakes[stakekey].isInitialized, "SSvcs: uninitialized");
        require(_stakes[stakekey].isActive, "SSvcs: stake suspended");
        require(_isStakeMaturedByStakekey(stakekey), "SSvcs: not mature");

        uint256 rewardAmountWei = _getClaimableRewardWeiByStakekey(stakekey);
        require(rewardAmountWei > 0, "SSvcs: zero reward");

        _stakingPoolStats[poolId].totalRewardWei -= rewardAmountWei;
        _stakingPoolStats[poolId].rewardToBeDistributedWei -= rewardAmountWei;
        _stakes[stakekey].rewardClaimedWei += rewardAmountWei;

        emit RewardClaimed(
            poolId,
            msg.sender,
            rewardTokenAddress,
            rewardAmountWei
        );

        _transferTokensToAccount(
            rewardTokenAddress,
            rewardTokenDecimals,
            rewardAmountWei,
            msg.sender
        );
    }

    /**
     * @inheritdoc IStakingService
     */
    function stake(bytes32 poolId, uint256 stakeAmountWei)
        external
        virtual
        override
        whenNotPaused
    {
        require(stakeAmountWei > 0, "SSvcs: stake amount");

        (
            uint256 stakeDurationDays,
            address stakeTokenAddress,
            uint256 stakeTokenDecimals,
            ,
            uint256 rewardTokenDecimals,
            uint256 poolAprWei,
            bool isPoolOpen,

        ) = _getStakingPoolInfo(poolId);
        require(isPoolOpen, "SSvcs: closed");

        uint256 stakeMaturityTimestamp = _calculateStakeMaturityTimestamp(
            stakeDurationDays,
            block.timestamp
        );
        require(
            stakeMaturityTimestamp > block.timestamp,
            "SSvcs: maturity timestamp"
        );

        uint256 truncatedStakeAmountWei = _truncatedAmountWei(
            stakeAmountWei,
            stakeTokenDecimals
        );
        require(truncatedStakeAmountWei > 0, "SSvcs: truncated stake amount");

        uint256 estimatedRewardAtMaturityWei = _truncatedAmountWei(
            _estimateRewardAtMaturityWei(
                stakeDurationDays,
                poolAprWei,
                truncatedStakeAmountWei
            ),
            rewardTokenDecimals
        );
        require(estimatedRewardAtMaturityWei > 0, "SSvcs: zero reward");
        require(
            estimatedRewardAtMaturityWei <=
                _calculatePoolRemainingRewardWei(poolId),
            "SSvcs: insufficient"
        );

        bytes memory stakekey = _getStakeKey(poolId, msg.sender);
        if (_stakes[stakekey].isInitialized) {
            uint256 stakeDurationAtAddStakeDays = (block.timestamp -
                _stakes[stakekey].stakeTimestamp) / SECONDS_IN_DAY;
            uint256 earnedRewardAtAddStakeWei = _truncatedAmountWei(
                _estimateRewardAtMaturityWei(
                    stakeDurationAtAddStakeDays,
                    poolAprWei,
                    _stakes[stakekey].lastStakeAmountWei
                ),
                rewardTokenDecimals
            );
            estimatedRewardAtMaturityWei += earnedRewardAtAddStakeWei;
            require(
                estimatedRewardAtMaturityWei <=
                    _calculatePoolRemainingRewardWei(poolId),
                "SSvcs: insufficient"
            );

            _stakes[stakekey].stakeAmountWei += truncatedStakeAmountWei;
            _stakes[stakekey].lastStakeAmountWei = truncatedStakeAmountWei;
            _stakes[stakekey].stakeTimestamp = block.timestamp;
            _stakes[stakekey].stakeMaturityTimestamp = stakeMaturityTimestamp;
            _stakes[stakekey]
                .estimatedRewardAtMaturityWei += estimatedRewardAtMaturityWei;
        } else {
            _stakes[stakekey] = StakeInfo({
                stakeAmountWei: truncatedStakeAmountWei,
                lastStakeAmountWei: truncatedStakeAmountWei,
                stakeTimestamp: block.timestamp,
                stakeMaturityTimestamp: stakeMaturityTimestamp,
                estimatedRewardAtMaturityWei: estimatedRewardAtMaturityWei,
                rewardClaimedWei: 0,
                isActive: true,
                isInitialized: true
            });
        }

        _stakingPoolStats[poolId].totalStakedWei += truncatedStakeAmountWei;
        _stakingPoolStats[poolId]
            .rewardToBeDistributedWei += estimatedRewardAtMaturityWei;

        emit Staked(
            poolId,
            msg.sender,
            stakeTokenAddress,
            truncatedStakeAmountWei,
            block.timestamp,
            stakeMaturityTimestamp,
            _stakes[stakekey].estimatedRewardAtMaturityWei
        );

        _transferTokensToContract(
            stakeTokenAddress,
            stakeTokenDecimals,
            truncatedStakeAmountWei,
            msg.sender
        );
    }

    /**
     * @inheritdoc IStakingService
     */
    function unstake(bytes32 poolId) external virtual override whenNotPaused {
        (
            ,
            address stakeTokenAddress,
            uint256 stakeTokenDecimals,
            address rewardTokenAddress,
            uint256 rewardTokenDecimals,
            ,
            ,
            bool isPoolActive
        ) = _getStakingPoolInfo(poolId);
        require(isPoolActive, "SSvcs: pool suspended");

        bytes memory stakekey = _getStakeKey(poolId, msg.sender);
        require(_stakes[stakekey].isInitialized, "SSvcs: uninitialized");
        require(_stakes[stakekey].isActive, "SSvcs: stake suspended");
        require(_isStakeMaturedByStakekey(stakekey), "SSvcs: not mature");

        uint256 stakeAmountWei = _stakes[stakekey].stakeAmountWei;
        require(stakeAmountWei > 0, "SSvcs: zero stake");

        uint256 rewardAmountWei = _getClaimableRewardWeiByStakekey(stakekey);

        _stakingPoolStats[poolId].totalStakedWei -= stakeAmountWei;
        _stakingPoolStats[poolId].totalRewardWei -= rewardAmountWei;
        _stakingPoolStats[poolId].rewardToBeDistributedWei -= rewardAmountWei;

        _stakes[stakekey] = StakeInfo({
            stakeAmountWei: 0,
            lastStakeAmountWei: 0,
            stakeTimestamp: 0,
            stakeMaturityTimestamp: 0,
            estimatedRewardAtMaturityWei: 0,
            rewardClaimedWei: 0,
            isActive: false,
            isInitialized: false
        });

        emit Unstaked(
            poolId,
            msg.sender,
            stakeTokenAddress,
            stakeAmountWei,
            rewardTokenAddress,
            rewardAmountWei
        );

        if (
            stakeTokenAddress == rewardTokenAddress &&
            stakeTokenDecimals == rewardTokenDecimals
        ) {
            _transferTokensToAccount(
                stakeTokenAddress,
                stakeTokenDecimals,
                stakeAmountWei + rewardAmountWei,
                msg.sender
            );
        } else {
            _transferTokensToAccount(
                stakeTokenAddress,
                stakeTokenDecimals,
                stakeAmountWei,
                msg.sender
            );

            if (rewardAmountWei > 0) {
                _transferTokensToAccount(
                    rewardTokenAddress,
                    rewardTokenDecimals,
                    rewardAmountWei,
                    msg.sender
                );
            }
        }
    }

    /**
     * @inheritdoc IStakingService
     */
    function addStakingPoolReward(bytes32 poolId, uint256 rewardAmountWei)
        external
        virtual
        override
        onlyRole(CONTRACT_ADMIN_ROLE)
    {
        require(rewardAmountWei > 0, "SSvcs: reward amount");

        (
            ,
            ,
            ,
            address rewardTokenAddress,
            uint256 rewardTokenDecimals,
            ,
            ,

        ) = _getStakingPoolInfo(poolId);

        uint256 truncatedRewardAmountWei = rewardTokenDecimals <
            TOKEN_MAX_DECIMALS
            ? rewardAmountWei
                .scaleWeiToDecimals(rewardTokenDecimals)
                .scaleDecimalsToWei(rewardTokenDecimals)
            : rewardAmountWei;

        _stakingPoolStats[poolId].totalRewardWei += truncatedRewardAmountWei;

        emit StakingPoolRewardAdded(
            poolId,
            msg.sender,
            rewardTokenAddress,
            truncatedRewardAmountWei
        );

        _transferTokensToContract(
            rewardTokenAddress,
            rewardTokenDecimals,
            truncatedRewardAmountWei,
            msg.sender
        );
    }

    /**
     * @inheritdoc IStakingService
     */
    function removeRevokedStakes(bytes32 poolId)
        external
        virtual
        override
        onlyRole(CONTRACT_ADMIN_ROLE)
    {
        (
            ,
            address stakeTokenAddress,
            uint256 stakeTokenDecimals,
            ,
            ,
            ,
            ,

        ) = _getStakingPoolInfo(poolId);

        require(
            _stakingPoolStats[poolId].totalRevokedStakeWei > 0,
            "SSvcs: no revoked"
        );

        uint256 totalRevokedStakeWei = _stakingPoolStats[poolId]
            .totalRevokedStakeWei;
        _stakingPoolStats[poolId].totalRevokedStakeWei = 0;

        emit RevokedStakesRemoved(
            poolId,
            msg.sender,
            adminWallet(),
            stakeTokenAddress,
            totalRevokedStakeWei
        );

        _transferTokensToAccount(
            stakeTokenAddress,
            stakeTokenDecimals,
            totalRevokedStakeWei,
            adminWallet()
        );
    }

    /**
     * @inheritdoc IStakingService
     */
    function removeUnallocatedStakingPoolReward(bytes32 poolId)
        external
        virtual
        override
        onlyRole(CONTRACT_ADMIN_ROLE)
    {
        (
            ,
            ,
            ,
            address rewardTokenAddress,
            uint256 rewardTokenDecimals,
            ,
            ,

        ) = _getStakingPoolInfo(poolId);

        uint256 unallocatedRewardWei = _calculatePoolRemainingRewardWei(poolId);
        require(unallocatedRewardWei > 0, "SSvcs: no unallocated");

        _stakingPoolStats[poolId].totalRewardWei -= unallocatedRewardWei;

        emit StakingPoolRewardRemoved(
            poolId,
            msg.sender,
            adminWallet(),
            rewardTokenAddress,
            unallocatedRewardWei
        );

        _transferTokensToAccount(
            rewardTokenAddress,
            rewardTokenDecimals,
            unallocatedRewardWei,
            adminWallet()
        );
    }

    /**
     * @inheritdoc IStakingService
     */
    function resumeStake(bytes32 poolId, address account)
        external
        virtual
        override
        onlyRole(CONTRACT_ADMIN_ROLE)
    {
        bytes memory stakekey = _getStakeKey(poolId, account);
        require(_stakes[stakekey].isInitialized, "SSvcs: uninitialized");

        require(!_stakes[stakekey].isActive, "SSvcs: stake active");

        _stakes[stakekey].isActive = true;

        emit StakeResumed(poolId, msg.sender, account);
    }

    /**
     * @inheritdoc IStakingService
     */
    function revokeStake(bytes32 poolId, address account)
        external
        virtual
        override
        onlyRole(CONTRACT_ADMIN_ROLE)
    {
        bytes memory stakekey = _getStakeKey(poolId, account);
        require(_stakes[stakekey].isInitialized, "SSvcs: uninitialized");

        uint256 stakeAmountWei = _stakes[stakekey].stakeAmountWei;
        uint256 rewardAmountWei = _stakes[stakekey]
            .estimatedRewardAtMaturityWei - _stakes[stakekey].rewardClaimedWei;

        _stakingPoolStats[poolId].totalStakedWei -= stakeAmountWei;
        _stakingPoolStats[poolId].totalRevokedStakeWei += stakeAmountWei;
        _stakingPoolStats[poolId].rewardToBeDistributedWei -= rewardAmountWei;

        _stakes[stakekey] = StakeInfo({
            stakeAmountWei: 0,
            lastStakeAmountWei: 0,
            stakeTimestamp: 0,
            stakeMaturityTimestamp: 0,
            estimatedRewardAtMaturityWei: 0,
            rewardClaimedWei: 0,
            isActive: false,
            isInitialized: false
        });

        (
            ,
            address stakeTokenAddress,
            ,
            address rewardTokenAddress,
            ,
            ,
            ,

        ) = _getStakingPoolInfo(poolId);

        emit StakeRevoked(
            poolId,
            msg.sender,
            account,
            stakeTokenAddress,
            stakeAmountWei,
            rewardTokenAddress,
            rewardAmountWei
        );
    }

    /**
     * @inheritdoc IStakingService
     */
    function suspendStake(bytes32 poolId, address account)
        external
        virtual
        override
        onlyRole(CONTRACT_ADMIN_ROLE)
    {
        bytes memory stakekey = _getStakeKey(poolId, account);
        require(_stakes[stakekey].isInitialized, "SSvcs: uninitialized");

        require(_stakes[stakekey].isActive, "SSvcs: stake suspended");

        _stakes[stakekey].isActive = false;

        emit StakeSuspended(poolId, msg.sender, account);
    }

    /**
     * @inheritdoc IStakingService
     */
    function pauseContract()
        external
        virtual
        override
        onlyRole(GOVERNANCE_ROLE)
    {
        _pause();
    }

    /**
     * @inheritdoc IStakingService
     */
    function setAdminWallet(address newWallet)
        external
        virtual
        override
        onlyRole(GOVERNANCE_ROLE)
    {
        _setAdminWallet(newWallet);
    }

    /**
     * @inheritdoc IStakingService
     */
    function setStakingPoolContract(address newStakingPool)
        external
        virtual
        override
        onlyRole(GOVERNANCE_ROLE)
    {
        require(newStakingPool != address(0), "SSvcs: new staking pool");

        address oldStakingPool = stakingPoolContract;
        stakingPoolContract = newStakingPool;

        emit StakingPoolContractChanged(
            oldStakingPool,
            newStakingPool,
            msg.sender
        );
    }

    /**
     * @inheritdoc IStakingService
     */
    function unpauseContract()
        external
        virtual
        override
        onlyRole(GOVERNANCE_ROLE)
    {
        _unpause();
    }

    /**
     * @inheritdoc IStakingService
     */
    function getClaimableRewardWei(bytes32 poolId, address account)
        external
        view
        virtual
        override
        returns (uint256)
    {
        bytes memory stakekey = _getStakeKey(poolId, account);
        require(_stakes[stakekey].isInitialized, "SSvcs: uninitialized");

        (, , , , , , , bool isPoolActive) = _getStakingPoolInfo(poolId);

        if (!isPoolActive) {
            return 0;
        }

        return _getClaimableRewardWeiByStakekey(stakekey);
    }

    /**
     * @inheritdoc IStakingService
     */
    function getStakeInfo(bytes32 poolId, address account)
        external
        view
        virtual
        override
        returns (
            uint256 stakeAmountWei,
            uint256 stakeTimestamp,
            uint256 stakeMaturityTimestamp,
            uint256 estimatedRewardAtMaturityWei,
            uint256 rewardClaimedWei,
            bool isActive
        )
    {
        bytes memory stakekey = _getStakeKey(poolId, account);
        require(_stakes[stakekey].isInitialized, "SSvcs: uninitialized");

        stakeAmountWei = _stakes[stakekey].stakeAmountWei;
        stakeTimestamp = _stakes[stakekey].stakeTimestamp;
        stakeMaturityTimestamp = _stakes[stakekey].stakeMaturityTimestamp;
        estimatedRewardAtMaturityWei = _stakes[stakekey]
            .estimatedRewardAtMaturityWei;
        rewardClaimedWei = _stakes[stakekey].rewardClaimedWei;
        isActive = _stakes[stakekey].isActive;
    }

    /**
     * @inheritdoc IStakingService
     */
    function getStakingPoolStats(bytes32 poolId)
        external
        view
        virtual
        override
        returns (
            uint256 totalRewardWei,
            uint256 totalStakedWei,
            uint256 rewardToBeDistributedWei,
            uint256 totalRevokedStakeWei,
            uint256 poolSizeWei,
            bool isOpen,
            bool isActive
        )
    {
        uint256 stakeDurationDays;
        uint256 stakeTokenDecimals;
        uint256 poolAprWei;

        (
            stakeDurationDays,
            ,
            stakeTokenDecimals,
            ,
            ,
            poolAprWei,
            isOpen,
            isActive
        ) = _getStakingPoolInfo(poolId);

        poolSizeWei = _getPoolSizeWei(
            stakeDurationDays,
            poolAprWei,
            _stakingPoolStats[poolId].totalRewardWei,
            stakeTokenDecimals
        );

        totalRewardWei = _stakingPoolStats[poolId].totalRewardWei;
        totalStakedWei = _stakingPoolStats[poolId].totalStakedWei;
        rewardToBeDistributedWei = _stakingPoolStats[poolId]
            .rewardToBeDistributedWei;
        totalRevokedStakeWei = _stakingPoolStats[poolId].totalRevokedStakeWei;
    }

    /**
     * @dev Transfer ERC20 tokens from this contract to the given account
     * @param tokenAddress The address of the ERC20 token to be transferred
     * @param tokenDecimals The ERC20 token decimal places
     * @param amountWei The amount to transfer in Wei
     * @param account The account to receive the ERC20 tokens
     */
    function _transferTokensToAccount(
        address tokenAddress,
        uint256 tokenDecimals,
        uint256 amountWei,
        address account
    ) internal virtual {
        require(tokenAddress != address(0), "SSvcs: token address");
        require(tokenDecimals <= TOKEN_MAX_DECIMALS, "SSvcs: token decimals");
        require(amountWei > 0, "SSvcs: amount");
        require(account != address(0), "SSvcs: account");

        uint256 amountDecimals = amountWei.scaleWeiToDecimals(tokenDecimals);

        IERC20(tokenAddress).safeTransfer(account, amountDecimals);
    }

    /**
     * @dev Transfer tokens from the given account to this contract
     * @param tokenAddress The address of the ERC20 token to be transferred
     * @param tokenDecimals The ERC20 token decimal places
     * @param amountWei The amount to transfer in Wei
     * @param account The account to transfer the ERC20 tokens from
     */
    function _transferTokensToContract(
        address tokenAddress,
        uint256 tokenDecimals,
        uint256 amountWei,
        address account
    ) internal virtual {
        require(tokenAddress != address(0), "SSvcs: token address");
        require(tokenDecimals <= TOKEN_MAX_DECIMALS, "SSvcs: token decimals");
        require(amountWei > 0, "SSvcs: amount");
        require(account != address(0), "SSvcs: account");

        uint256 amountDecimals = amountWei.scaleWeiToDecimals(tokenDecimals);

        IERC20(tokenAddress).safeTransferFrom(
            account,
            address(this),
            amountDecimals
        );
    }

    /**
     * @dev Returns the remaining reward for the given staking pool in Wei
     * @param poolId The staking pool identifier
     * @return calculatedRemainingRewardWei The calculaated remaining reward in Wei
     */
    function _calculatePoolRemainingRewardWei(bytes32 poolId)
        internal
        view
        virtual
        returns (uint256 calculatedRemainingRewardWei)
    {
        calculatedRemainingRewardWei =
            _stakingPoolStats[poolId].totalRewardWei -
            _stakingPoolStats[poolId].rewardToBeDistributedWei;
    }

    /**
     * @dev Returns the calculated timestamp when the stake matures given the stake duration and timestamp
     * @param stakeDurationDays The duration in days that user stakes will be locked in staking pool
     * @param stakeTimestamp The timestamp as seconds since unix epoch when the stake was placed
     * @return calculatedStakeMaturityTimestamp The timestamp as seconds since unix epoch when the stake matures
     */
    // https://github.com/crytic/slither/wiki/Detector-Documentation#dead-code
    // slither-disable-next-line dead-code
    function _calculateStakeMaturityTimestamp(
        uint256 stakeDurationDays,
        uint256 stakeTimestamp
    ) internal view virtual returns (uint256 calculatedStakeMaturityTimestamp) {
        calculatedStakeMaturityTimestamp =
            stakeTimestamp +
            stakeDurationDays *
            SECONDS_IN_DAY;
    }

    /**
     * @dev Returns the estimated reward in Wei at maturity for the given stake duration, pool APR and stake amount
     * @param stakeDurationDays The duration in days that user stakes will be locked in staking pool
     * @param poolAprWei The APR (Annual Percentage Rate) in Wei for staking pool
     * @param stakeAmountWei The amount of tokens staked in Wei
     * @return estimatedRewardAtMaturityWei The estimated reward in Wei at maturity
     */
    function _estimateRewardAtMaturityWei(
        uint256 stakeDurationDays,
        uint256 poolAprWei,
        uint256 stakeAmountWei
    ) internal view virtual returns (uint256 estimatedRewardAtMaturityWei) {
        estimatedRewardAtMaturityWei =
            (poolAprWei * stakeDurationDays * stakeAmountWei) /
            (DAYS_IN_YEAR * PERCENT_100_WEI);
    }

    /**
     * @dev Returns the claimable reward in Wei for the given stake key, returns zero if stake has been suspended
     * @param stakekey The stake identifier
     * @return claimableRewardWei The claimable reward in Wei
     */
    function _getClaimableRewardWeiByStakekey(bytes memory stakekey)
        internal
        view
        virtual
        returns (uint256 claimableRewardWei)
    {
        if (!_stakes[stakekey].isActive) {
            return 0;
        }

        if (_isStakeMaturedByStakekey(stakekey)) {
            claimableRewardWei =
                _stakes[stakekey].estimatedRewardAtMaturityWei -
                _stakes[stakekey].rewardClaimedWei;
        } else {
            claimableRewardWei = 0;
        }
    }

    /**
     * @dev Returns the staking pool size in Wei for the given parameters
     * @param stakeDurationDays The duration in days that user stakes will be locked in staking pool
     * @param poolAprWei The APR (Annual Percentage Rate) in Wei for staking pool
     * @param totalRewardWei The total amount of staking pool reward in Wei
     * @param stakeTokenDecimals The ERC20 stake token decimal places
     * @return poolSizeWei The staking pool size in Wei
     */
    function _getPoolSizeWei(
        uint256 stakeDurationDays,
        uint256 poolAprWei,
        uint256 totalRewardWei,
        uint256 stakeTokenDecimals
    ) internal view virtual returns (uint256 poolSizeWei) {
        poolSizeWei = _truncatedAmountWei(
            (DAYS_IN_YEAR * PERCENT_100_WEI * totalRewardWei) /
                (stakeDurationDays * poolAprWei),
            stakeTokenDecimals
        );
    }

    /**
     * @dev Returns the staking pool info for the given staking pool
     * @param poolId The staking pool identifier
     * @return stakeDurationDays The duration in days that user stakes will be locked in staking pool
     * @return stakeTokenAddress The address of the ERC20 stake token for staking pool
     * @return stakeTokenDecimals The ERC20 stake token decimal places
     * @return rewardTokenAddress The address of the ERC20 reward token for staking pool
     * @return rewardTokenDecimals The ERC20 reward token decimal places
     * @return poolAprWei The APR (Annual Percentage Rate) in Wei for staking pool
     * @return isOpen True if staking pool is open to accept user stakes
     * @return isPoolActive True if user is allowed to claim reward and unstake from staking pool
     */
    function _getStakingPoolInfo(bytes32 poolId)
        internal
        view
        virtual
        returns (
            uint256 stakeDurationDays,
            address stakeTokenAddress,
            uint256 stakeTokenDecimals,
            address rewardTokenAddress,
            uint256 rewardTokenDecimals,
            uint256 poolAprWei,
            bool isOpen,
            bool isPoolActive
        )
    {
        (
            stakeDurationDays,
            stakeTokenAddress,
            stakeTokenDecimals,
            rewardTokenAddress,
            rewardTokenDecimals,
            poolAprWei,
            isOpen,
            isPoolActive
        ) = IStakingPool(stakingPoolContract).getStakingPoolInfo(poolId);
        require(stakeDurationDays > 0, "SSvcs: stake duration");
        require(stakeTokenAddress != address(0), "SSvcs: stake token");
        require(
            stakeTokenDecimals <= TOKEN_MAX_DECIMALS,
            "SSvcs: stake decimals"
        );
        require(rewardTokenAddress != address(0), "SSvcs: reward token");
        require(
            rewardTokenDecimals <= TOKEN_MAX_DECIMALS,
            "SSvcs: reward decimals"
        );
        require(poolAprWei > 0, "SSvcs: pool APR");
    }

    /**
     * @dev Returns whether stake has matured for given stake key
     * @param stakekey The stake identifier
     * @return True if stake has matured
     */
    function _isStakeMaturedByStakekey(bytes memory stakekey)
        internal
        view
        virtual
        returns (bool)
    {
        return
            _stakes[stakekey].stakeMaturityTimestamp > 0 &&
            block.timestamp >= _stakes[stakekey].stakeMaturityTimestamp;
    }

    /**
     * @dev Returns the stake identifier for the given staking pool identifier and account
     * @param poolId The staking pool identifier
     * @param account The address of the user wallet that placed the stake
     * @return stakekey The stake identifier which is the ABI-encoded value of account and poolId
     */
    function _getStakeKey(bytes32 poolId, address account)
        internal
        pure
        virtual
        returns (bytes memory stakekey)
    {
        require(account != address(0), "SSvcs: account");

        stakekey = abi.encode(account, poolId);
    }

    /**
     * @dev Returns the given amount in Wei truncated to the given number of decimals
     * @param amountWei The amount in Wei
     * @param tokenDecimals The number of decimal places
     * @return truncatedAmountWei The truncated amount in Wei
     */
    function _truncatedAmountWei(uint256 amountWei, uint256 tokenDecimals)
        internal
        pure
        virtual
        returns (uint256 truncatedAmountWei)
    {
        truncatedAmountWei = tokenDecimals < TOKEN_MAX_DECIMALS
            ? amountWei.scaleWeiToDecimals(tokenDecimals).scaleDecimalsToWei(
                tokenDecimals
            )
            : amountWei;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

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
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Enjinstarter
pragma solidity ^0.8.0;

/**
 * @title UnitConverter
 * @author Tim Loh
 * @notice Converts given amount between Wei and number of decimal places
 */
library UnitConverter {
    uint256 public constant TOKEN_MAX_DECIMALS = 18;

    /**
     * @notice Scale down given amount in Wei to given number of decimal places
     * @param weiAmount Amount in Wei
     * @param decimals Number of decimal places
     * @return decimalsAmount Amount in Wei scaled down to given number of decimal places
     */
    // https://github.com/crytic/slither/wiki/Detector-Documentation#dead-code
    // slither-disable-next-line dead-code
    function scaleWeiToDecimals(uint256 weiAmount, uint256 decimals)
        internal
        pure
        returns (uint256 decimalsAmount)
    {
        require(decimals <= TOKEN_MAX_DECIMALS, "UnitConverter: decimals");

        if (decimals < TOKEN_MAX_DECIMALS && weiAmount > 0) {
            uint256 decimalsDiff = TOKEN_MAX_DECIMALS - decimals;
            decimalsAmount = weiAmount / 10**decimalsDiff;
        } else {
            decimalsAmount = weiAmount;
        }
    }

    /**
     * @notice Scale up given amount in given number of decimal places to Wei
     * @param decimalsAmount Amount in number of decimal places
     * @param decimals Number of decimal places
     * @return weiAmount Amount in given number of decimal places scaled up to Wei
     */
    // https://github.com/crytic/slither/wiki/Detector-Documentation#dead-code
    // slither-disable-next-line dead-code
    function scaleDecimalsToWei(uint256 decimalsAmount, uint256 decimals)
        internal
        pure
        returns (uint256 weiAmount)
    {
        require(decimals <= TOKEN_MAX_DECIMALS, "UnitConverter: decimals");

        if (decimals < TOKEN_MAX_DECIMALS && decimalsAmount > 0) {
            uint256 decimalsDiff = TOKEN_MAX_DECIMALS - decimals;
            weiAmount = decimalsAmount * 10**decimalsDiff;
        } else {
            weiAmount = decimalsAmount;
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Enjinstarter
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title AdminPrivileges
 * @author Tim Loh
 * @notice Provides role definitions that are inherited by other contracts and grants the owner all the defined roles
 */
contract AdminPrivileges is AccessControl {
    bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");
    bytes32 public constant CONTRACT_ADMIN_ROLE =
        keccak256("CONTRACT_ADMIN_ROLE");

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(GOVERNANCE_ROLE, msg.sender);
        _grantRole(CONTRACT_ADMIN_ROLE, msg.sender);
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Enjinstarter
pragma solidity ^0.8.0;

import "./interfaces/IAdminWallet.sol";

/**
 * @title AdminWallet
 * @author Tim Loh
 * @notice Provides an implementation of the admin wallet interface that is inherited by other contracts
 */
contract AdminWallet is IAdminWallet {
    address private _adminWallet;

    constructor() {
        _adminWallet = msg.sender;
    }

    /**
     * @inheritdoc IAdminWallet
     */
    function adminWallet() public view virtual override returns (address) {
        return _adminWallet;
    }

    /**
     * @dev Change admin wallet to a new wallet address
     * @param newWallet The new admin wallet address
     */
    function _setAdminWallet(address newWallet) internal virtual {
        require(newWallet != address(0), "AdminWallet: new wallet");

        address oldWallet = _adminWallet;
        _adminWallet = newWallet;

        emit AdminWalletChanged(oldWallet, newWallet, msg.sender);
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Enjinstarter
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/IAccessControl.sol";

/**
 * @title StakingPool Interface
 * @author Tim Loh
 * @notice Interface for StakingPool which contains the staking pool configs used by StakingService
 */
interface IStakingPool is IAccessControl {
    /**
     * @notice Emitted when a staking pool has been closed
     * @param poolId The staking pool identifier
     * @param sender The address that closed the staking pool
     */
    event StakingPoolClosed(bytes32 indexed poolId, address indexed sender);

    /**
     * @notice Emitted when a staking pool has been created
     * @param poolId The staking pool identifier
     * @param sender The address that created the staking pool
     * @param stakeDurationDays The duration in days that user stakes will be locked in staking pool
     * @param stakeTokenAddress The address of the ERC20 stake token for staking pool
     * @param stakeTokenDecimals The ERC20 stake token decimal places
     * @param rewardTokenAddress The address of the ERC20 reward token for staking pool
     * @param rewardTokenDecimals The ERC20 reward token decimal places
     * @param poolAprWei The APR (Annual Percentage Rate) in Wei for staking pool
     */
    event StakingPoolCreated(
        bytes32 indexed poolId,
        address indexed sender,
        uint256 indexed stakeDurationDays,
        address stakeTokenAddress,
        uint256 stakeTokenDecimals,
        address rewardTokenAddress,
        uint256 rewardTokenDecimals,
        uint256 poolAprWei
    );

    /**
     * @notice Emitted when a staking pool has been opened
     * @param poolId The staking pool identifier
     * @param sender The address that opened the staking pool
     */
    event StakingPoolOpened(bytes32 indexed poolId, address indexed sender);

    /**
     * @notice Emitted when a staking pool has been resumed
     * @param poolId The staking pool identifier
     * @param sender The address that resumed the staking pool
     */
    event StakingPoolResumed(bytes32 indexed poolId, address indexed sender);

    /**
     * @notice Emitted when a staking pool has been suspended
     * @param poolId The staking pool identifier
     * @param sender The address that suspended the staking pool
     */
    event StakingPoolSuspended(bytes32 indexed poolId, address indexed sender);

    /**
     * @notice Closes the given staking pool to reject user stakes
     * @dev Must be called by contract admin role
     * @param poolId The staking pool identifier
     */
    function closeStakingPool(bytes32 poolId) external;

    /**
     * @notice Creates a staking pool for the given pool identifier and config
     * @dev Must be called by contract admin role
     * @param poolId The staking pool identifier
     * @param stakeDurationDays The duration in days that user stakes will be locked in staking pool
     * @param stakeTokenAddress The address of the ERC20 stake token for staking pool
     * @param stakeTokenDecimals The ERC20 stake token decimal places
     * @param rewardTokenAddress The address of the ERC20 reward token for staking pool
     * @param rewardTokenDecimals The ERC20 reward token decimal places
     * @param poolAprWei The APR (Annual Percentage Rate) in Wei for staking pool
     */
    function createStakingPool(
        bytes32 poolId,
        uint256 stakeDurationDays,
        address stakeTokenAddress,
        uint256 stakeTokenDecimals,
        address rewardTokenAddress,
        uint256 rewardTokenDecimals,
        uint256 poolAprWei
    ) external;

    /**
     * @notice Opens the given staking pool to accept user stakes
     * @dev Must be called by contract admin role
     * @param poolId The staking pool identifier
     */
    function openStakingPool(bytes32 poolId) external;

    /**
     * @notice Resumes the given staking pool to allow user reward claims and unstakes
     * @dev Must be called by contract admin role
     * @param poolId The staking pool identifier
     */
    function resumeStakingPool(bytes32 poolId) external;

    /**
     * @notice Suspends the given staking pool to prevent user reward claims and unstakes
     * @dev Must be called by contract admin role
     * @param poolId The staking pool identifier
     */
    function suspendStakingPool(bytes32 poolId) external;

    /**
     * @notice Returns the given staking pool info
     * @param poolId The staking pool identifier
     * @return stakeDurationDays The duration in days that user stakes will be locked in staking pool
     * @return stakeTokenAddress The address of the ERC20 stake token for staking pool
     * @return stakeTokenDecimals The ERC20 stake token decimal places
     * @return rewardTokenAddress The address of the ERC20 reward token for staking pool
     * @return rewardTokenDecimals The ERC20 reward token decimal places
     * @return poolAprWei The APR (Annual Percentage Rate) in Wei for staking pool
     * @return isOpen True if staking pool is open to accept user stakes
     * @return isActive True if user is allowed to claim reward and unstake from staking pool
     */
    function getStakingPoolInfo(bytes32 poolId)
        external
        view
        returns (
            uint256 stakeDurationDays,
            address stakeTokenAddress,
            uint256 stakeTokenDecimals,
            address rewardTokenAddress,
            uint256 rewardTokenDecimals,
            uint256 poolAprWei,
            bool isOpen,
            bool isActive
        );
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Enjinstarter
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/IAccessControl.sol";
import "./IAdminWallet.sol";

/**
 * @title StakingService Interface
 * @author Tim Loh
 * @notice Interface for StakingService which provides staking functionalities
 */
interface IStakingService is IAccessControl, IAdminWallet {
    /**
     * @notice Emitted when revoked stakes have been removed from pool
     * @param poolId The staking pool identifier
     * @param sender The address that withdrew the revoked stakes to admin wallet
     * @param adminWallet The address of the admin wallet receiving the funds
     * @param stakeToken The address of the transferred ERC20 token
     * @param stakeAmountWei The amount of tokens transferred in Wei
     */
    event RevokedStakesRemoved(
        bytes32 indexed poolId,
        address indexed sender,
        address indexed adminWallet,
        address stakeToken,
        uint256 stakeAmountWei
    );

    /**
     * @notice Emitted when reward has been claimed by user
     * @param poolId The staking pool identifier
     * @param account The address of the user wallet receiving funds
     * @param rewardToken The address of the transferred ERC20 token
     * @param rewardWei The amount of tokens transferred in Wei
     */
    event RewardClaimed(
        bytes32 indexed poolId,
        address indexed account,
        address indexed rewardToken,
        uint256 rewardWei
    );

    /**
     * @notice Emitted when stake has been placed by user
     * @param poolId The staking pool identifier
     * @param account The address of the user wallet that placed the stake
     * @param stakeToken The address of the ERC20 stake token
     * @param stakeAmountWei The amount of tokens staked in Wei
     * @param stakeTimestamp The timestamp as seconds since unix epoch when the stake was placed
     * @param stakeMaturityTimestamp The timestamp as seconds since unix epoch when the stake matures
     * @param rewardAtMaturityWei The expected reward in Wei at maturity
     */
    event Staked(
        bytes32 indexed poolId,
        address indexed account,
        address indexed stakeToken,
        uint256 stakeAmountWei,
        uint256 stakeTimestamp,
        uint256 stakeMaturityTimestamp,
        uint256 rewardAtMaturityWei
    );

    /**
     * @notice Emitted when user stake has been resumed
     * @param poolId The staking pool identifier
     * @param sender The address that resumed the stake
     * @param account The address of the user wallet whose stake has been resumed
     */
    event StakeResumed(
        bytes32 indexed poolId,
        address indexed sender,
        address indexed account
    );

    /**
     * @notice Emitted when user stake with reward has been revoked
     * @param poolId The staking pool identifier
     * @param sender The address that revoked the user stake
     * @param account The address of the user wallet whose stake has been revoked
     * @param stakeToken The address of the ERC20 stake token
     * @param stakeAmountWei The amount of tokens staked in Wei
     * @param rewardToken The address of the ERC20 reward token
     * @param rewardWei The expected reward in Wei
     */
    event StakeRevoked(
        bytes32 indexed poolId,
        address indexed sender,
        address indexed account,
        address stakeToken,
        uint256 stakeAmountWei,
        address rewardToken,
        uint256 rewardWei
    );

    /**
     * @notice Emitted when user stake has been suspended
     * @param poolId The staking pool identifier
     * @param sender The address that suspended the user stake
     * @param account The address of the user wallet whose stake has been suspended
     */
    event StakeSuspended(
        bytes32 indexed poolId,
        address indexed sender,
        address indexed account
    );

    /**
     * @notice Emitted when staking pool contract has been changed
     * @param oldStakingPool The address of the staking pool contract before the staking pool was changed
     * @param newStakingPool The address pf the staking pool contract after the staking pool was changed
     * @param sender The address that changed the staking pool contract
     */
    event StakingPoolContractChanged(
        address indexed oldStakingPool,
        address indexed newStakingPool,
        address indexed sender
    );

    /**
     * @notice Emitted when reward has been added to staking pool
     * @param poolId The staking pool identifier
     * @param sender The address that added the reward
     * @param rewardToken The address of the ERC20 reward token
     * @param rewardAmountWei The amount of reward tokens added in Wei
     */
    event StakingPoolRewardAdded(
        bytes32 indexed poolId,
        address indexed sender,
        address indexed rewardToken,
        uint256 rewardAmountWei
    );

    /**
     * @notice Emitted when unallocated reward has been removed from staking pool
     * @param poolId The staking pool identifier
     * @param sender The address that removed the unallocated reward
     * @param adminWallet The address of the admin wallet receiving the funds
     * @param rewardToken The address of the ERC20 reward token
     * @param rewardAmountWei The amount of reward tokens removed in Wei
     */
    event StakingPoolRewardRemoved(
        bytes32 indexed poolId,
        address indexed sender,
        address indexed adminWallet,
        address rewardToken,
        uint256 rewardAmountWei
    );

    /**
     * @notice Emitted when stake with reward has been withdrawn by user
     * @param poolId The staking pool identifier
     * @param account The address of the user wallet that unstaked and received the funds
     * @param stakeToken The address of the ERC20 stake token
     * @param unstakeAmountWei The amount of stake tokens unstaked in Wei
     * @param rewardToken The address of the ERC20 reward token
     * @param rewardWei The amount of reward tokens claimed in Wei
     */
    event Unstaked(
        bytes32 indexed poolId,
        address indexed account,
        address indexed stakeToken,
        uint256 unstakeAmountWei,
        address rewardToken,
        uint256 rewardWei
    );

    /**
     * @notice Claim reward from given staking pool for message sender
     * @param poolId The staking pool identifier
     */
    function claimReward(bytes32 poolId) external;

    /**
     * @notice Stake given amount in given staking pool for message sender
     * @dev Requires the user to have approved the transfer of stake amount to this contract.
     *      User can increase an existing stake that has not matured yet but stake maturity date will
     *      be reset while rewards earned up to the point where stake is increased will be accumulated.
     * @param poolId The staking pool identifier
     * @param stakeAmountWei The amount of tokens to stake in Wei
     */
    function stake(bytes32 poolId, uint256 stakeAmountWei) external;

    /**
     * @notice Unstake with claim reward from given staking pool for message sender
     * @param poolId The staking pool identifier
     */
    function unstake(bytes32 poolId) external;

    /**
     * @notice Add reward to given staking pool
     * @dev Must be called by contract admin role.
     *      Requires the admin user to have approved the transfer of reward amount to this contract.
     * @param poolId The staking pool identifier
     * @param rewardAmountWei The amount of reward tokens to add in Wei
     */
    function addStakingPoolReward(bytes32 poolId, uint256 rewardAmountWei)
        external;

    /**
     * @notice Withdraw revoked stakes from given staking pool to admin wallet
     * @dev Must be called by contract admin role
     * @param poolId The staking pool identifier
     */
    function removeRevokedStakes(bytes32 poolId) external;

    /**
     * @notice Withdraw unallocated reward from given staking pool to admin wallet
     * @dev Must be called by contract admin role
     * @param poolId The staking pool identifier
     */
    function removeUnallocatedStakingPoolReward(bytes32 poolId) external;

    /**
     * @notice Resume stake for given staking pool and account
     * @dev Must be called by contract admin role
     * @param poolId The staking pool identifier
     * @param account The address of the user wallet that staked
     */
    function resumeStake(bytes32 poolId, address account) external;

    /**
     * @notice Revoke stake for given staking pool and account
     * @dev Must be called by contract admin role
     * @param poolId The staking pool identifier
     * @param account The address of the user wallet that staked
     */
    function revokeStake(bytes32 poolId, address account) external;

    /**
     * @notice Suspend stake for given staking pool and account
     * @dev Must be called by contract admin role
     * @param poolId The staking pool identifier
     * @param account The address of the user wallet that staked
     */
    function suspendStake(bytes32 poolId, address account) external;

    /**
     * @notice Pause user functions (stake, claimReward, unstake)
     * @dev Must be called by governance role
     */
    function pauseContract() external;

    /**
     * @notice Change admin wallet to a new wallet address
     * @dev Must be called by governance role
     * @param newWallet The new admin wallet
     */
    function setAdminWallet(address newWallet) external;

    /**
     * @notice Change staking pool contract to a new contract address
     * @dev Must be called by governance role
     * @param newStakingPool The new staking pool contract address
     */
    function setStakingPoolContract(address newStakingPool) external;

    /**
     * @notice Unpause user functions (stake, claimReward, unstake)
     * @dev Must be called by governance role
     */
    function unpauseContract() external;

    /**
     * @notice Returns the claimable reward in Wei for given staking pool and account
     * @param poolId The staking pool identifier
     * @param account The address of the user wallet that staked
     * @return Claimable reward in Wei
     */
    function getClaimableRewardWei(bytes32 poolId, address account)
        external
        view
        returns (uint256);

    /**
     * @notice Returns the stake info for given staking pool and account
     * @param poolId The staking pool identifier
     * @param account The address of the user wallet that staked
     * @return stakeAmountWei The amount of tokens staked in Wei
     * @return stakeTimestamp The timestamp as seconds since unix epoch when the stake was placed
     * @return stakeMaturityTimestamp The timestamp as seconds since unix epoch when the stake matures
     * @return estimatedRewardAtMaturityWei The estimated reward in Wei at maturity
     * @return rewardClaimedWei The reward in Wei that has already been claimed
     * @return isActive True if stake has not been suspended
     */
    function getStakeInfo(bytes32 poolId, address account)
        external
        view
        returns (
            uint256 stakeAmountWei,
            uint256 stakeTimestamp,
            uint256 stakeMaturityTimestamp,
            uint256 estimatedRewardAtMaturityWei,
            uint256 rewardClaimedWei,
            bool isActive
        );

    /**
     * @notice Returns the staking pool statistics for given staking pool
     * @param poolId The staking pool identifier
     * @return totalRewardWei The total amount of staking pool reward in Wei
     * @return totalStakedWei The total amount of stakes inside staking pool in Wei
     * @return rewardToBeDistributedWei The total amount of allocated staking pool reward to be distributed in Wei
     * @return totalRevokedStakeWei The total amount of revoked stakes in Wei
     * @return poolSizeWei The pool size in Wei
     * @return isOpen True if staking pool is open to accept user stakes
     * @return isActive True if user is allowed to claim reward and unstake from staking pool
     */
    function getStakingPoolStats(bytes32 poolId)
        external
        view
        returns (
            uint256 totalRewardWei,
            uint256 totalStakedWei,
            uint256 rewardToBeDistributedWei,
            uint256 totalRevokedStakeWei,
            uint256 poolSizeWei,
            bool isOpen,
            bool isActive
        );

    /**
     * @notice Returns the staking pool contract address
     * @return Staking pool contract address
     */
    function stakingPoolContract() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

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
        _checkRole(role);
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
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
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
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
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
     *
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleRevoked} event.
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
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
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
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
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

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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

// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Enjinstarter
pragma solidity ^0.8.0;

/**
 * @title AdminWallet Interface
 * @author Tim Loh
 * @notice Interface for AdminWallet where funds will be withdrawn to
 */
interface IAdminWallet {
    /**
     * @notice Emitted when admin wallet has been changed from `oldWallet` to `newWallet`
     * @param oldWallet The wallet before the wallet was changed
     * @param newWallet The wallet after the wallet was changed
     * @param sender The address that changes the admin wallet
     */
    event AdminWalletChanged(
        address indexed oldWallet,
        address indexed newWallet,
        address indexed sender
    );

    /**
     * @notice Returns the admin wallet address where funds will be withdrawn to
     * @return Admin wallet address
     */
    function adminWallet() external view returns (address);
}