// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title InsurancePool
 * @notice Shared pool that covers first 40% of validator slashing losses
 * @dev Self-sustaining at 5% dispute rate via 2% premiums
 */
contract InsurancePool is Ownable {
    /*//////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/

    uint256 private constant BASIS_POINTS = 10_000;
    uint256 private constant COVERAGE_PERCENTAGE = 4_000;  // 40%
    uint256 private constant MIN_POOL_RATIO = 2_000;       // 20% of target
    uint256 private constant EMERGENCY_PREMIUM = 300;      // 3% if pool low

    /*//////////////////////////////////////////////////////////////
                                 STATE
    //////////////////////////////////////////////////////////////*/

    IERC20 public immutable USDC;
    address public stakingContract;

    struct PoolStats {
        uint256 totalContributions;
        uint256 totalClaims;
        uint256 currentBalance;
        uint256 targetBalance;       // Dynamically adjusted
    }

    PoolStats public poolStats;
    
    mapping(address => uint256) public validatorContributions;
    mapping(address => uint256) public validatorClaims;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event PremiumContributed(
        address indexed validator,
        uint256 amount,
        uint256 stakeAmount
    );

    event ClaimPaid(
        address indexed validator,
        uint256 slashedAmount,
        uint256 coverageAmount
    );

    event PoolSeeded(
        address indexed seeder,
        uint256 amount
    );

    event EmergencyPremiumActivated(
        uint256 newPremiumRate
    );

    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error Unauthorized();
    error InsufficientPoolBalance();
    error TransferFailed();

    /*//////////////////////////////////////////////////////////////
                             CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _usdc) Ownable(msg.sender) {
        USDC = IERC20(_usdc);
    }

    /*//////////////////////////////////////////////////////////////
                              MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyStaking() {
        if (msg.sender != stakingContract) revert Unauthorized();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                         CORE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Receive premium contribution from validator
     * @param validator Who is staking
     * @param stakeAmount The stake amount (premium is % of this)
     */
    function contributePremium(address validator, uint256 stakeAmount) 
        external 
        onlyStaking 
        returns (uint256 premium)
    {
        // Calculate premium (2% base, 3% if pool is low)
        uint256 premiumRate = _getCurrentPremiumRate();
        premium = (stakeAmount * premiumRate) / BASIS_POINTS;

        // Transfer premium from staking contract
        bool success = USDC.transferFrom(msg.sender, address(this), premium);
        if (!success) revert TransferFailed();

        // Update state
        poolStats.totalContributions += premium;
        poolStats.currentBalance += premium;
        validatorContributions[validator] += premium;

        // Adjust target balance (grows with more validators)
        poolStats.targetBalance = _calculateTargetBalance();

        emit PremiumContributed(validator, premium, stakeAmount);
    }

    /**
     * @notice Claim insurance coverage for slashed stake
     * @param validator Who was slashed
     * @param slashedAmount Full amount that was slashed
     * @return coverageAmount How much the pool paid
     */
    function claimCoverage(address validator, uint256 slashedAmount) 
        external 
        onlyStaking 
        returns (uint256 coverageAmount)
    {
        // Calculate 40% coverage
        coverageAmount = (slashedAmount * COVERAGE_PERCENTAGE) / BASIS_POINTS;

        // Check if pool has enough
        if (poolStats.currentBalance < coverageAmount) {
            // Pool depleted - pay what we can
            coverageAmount = poolStats.currentBalance;
        }

        if (coverageAmount == 0) {
            return 0;  // Pool empty, no coverage
        }

        // Transfer coverage to staking contract (will forward to validator)
        bool success = USDC.transfer(stakingContract, coverageAmount);
        if (!success) revert TransferFailed();

        // Update state
        poolStats.totalClaims += coverageAmount;
        poolStats.currentBalance -= coverageAmount;
        validatorClaims[validator] += coverageAmount;

        emit ClaimPaid(validator, slashedAmount, coverageAmount);

        // Activate emergency premium if pool is low
        if (_isPoolBelowTarget()) {
            emit EmergencyPremiumActivated(EMERGENCY_PREMIUM);
        }
    }

    /**
     * @notice Seed the pool (owner or community funding)
     * @param amount Amount of USDC to add
     */
    function seedPool(uint256 amount) external {
        bool success = USDC.transferFrom(msg.sender, address(this), amount);
        if (!success) revert TransferFailed();

        poolStats.currentBalance += amount;
        
        emit PoolSeeded(msg.sender, amount);
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Get current premium rate (base 2%, emergency 3%)
     */
    function _getCurrentPremiumRate() internal view returns (uint256) {
        if (_isPoolBelowTarget()) {
            return EMERGENCY_PREMIUM;  // 3%
        }
        return 200;  // 2% base rate
    }

    /**
     * @notice Check if pool balance is below 20% of target
     */
    function _isPoolBelowTarget() internal view returns (bool) {
        uint256 minBalance = (poolStats.targetBalance * MIN_POOL_RATIO) / BASIS_POINTS;
        return poolStats.currentBalance < minBalance;
    }

    /**
     * @notice Calculate target pool balance
     * @dev Target grows with total contributions (proxy for validator count)
     */
    function _calculateTargetBalance() internal view returns (uint256) {
        // Target = 5x total claims (assumes 5% dispute rate)
        // Minimum target = 10% of total contributions
        uint256 claimBasedTarget = poolStats.totalClaims * 5;
        uint256 contributionBasedTarget = poolStats.totalContributions / 10;
        
        return claimBasedTarget > contributionBasedTarget 
            ? claimBasedTarget 
            : contributionBasedTarget;
    }

    /*//////////////////////////////////////////////////////////////
                          VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function getPoolHealth() external view returns (
        uint256 currentBalance,
        uint256 targetBalance,
        uint256 healthPercentage,
        bool isHealthy
    ) {
        currentBalance = poolStats.currentBalance;
        targetBalance = poolStats.targetBalance;
        
        if (targetBalance == 0) {
            healthPercentage = 100;
            isHealthy = true;
        } else {
            healthPercentage = (currentBalance * 100) / targetBalance;
            isHealthy = !_isPoolBelowTarget();
        }
    }

    function getValidatorStats(address validator) external view returns (
        uint256 totalContributed,
        uint256 totalClaimed,
        uint256 netPosition
    ) {
        totalContributed = validatorContributions[validator];
        totalClaimed = validatorClaims[validator];
        
        if (totalContributed > totalClaimed) {
            netPosition = totalContributed - totalClaimed;
        } else {
            netPosition = 0;  // Net receiver
        }
    }

    /*//////////////////////////////////////////////////////////////
                          ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function setStakingContract(address _staking) external onlyOwner {
        stakingContract = _staking;
    }

    /**
     * @notice Emergency withdrawal (only if critical bug found)
     */
    function emergencyWithdraw(address recipient) external onlyOwner {
        uint256 balance = USDC.balanceOf(address(this));
        bool success = USDC.transfer(recipient, balance);
        if (!success) revert TransferFailed();
    }
}
