// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title BoraStaking
 * @notice Core staking contract for Bora Agent Market validators
 * @dev Manages validator capital locks, releases, and slashing
 */
contract BoraStaking is ReentrancyGuard, Ownable {
    /*//////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/

    uint256 private constant BASIS_POINTS = 10_000;
    uint256 private constant TIER_1_THRESHOLD = 100e6;    // $100 USDC
    uint256 private constant TIER_2_THRESHOLD = 500e6;    // $500 USDC
    uint256 private constant TIER_3_THRESHOLD = 1_000e6;  // $1,000 USDC
    
    uint256 private constant TIER_1_STAKE_PCT = 2_000;  // 20%
    uint256 private constant TIER_2_STAKE_PCT = 3_500;  // 35%
    uint256 private constant TIER_3_STAKE_PCT = 5_000;  // 50%
    uint256 private constant TIER_4_STAKE_PCT = 7_500;  // 75%

    uint256 private constant INSURANCE_PREMIUM_PCT = 200; // 2%
    uint256 private constant LOCK_PERIOD = 72 hours;

    /*//////////////////////////////////////////////////////////////
                                 STATE
    //////////////////////////////////////////////////////////////*/

    IERC20 public immutable USDC;
    address public marketplaceContract;
    address public disputeContract;
    address public insurancePool;

    enum StakeStatus {
        LOCKED,
        RELEASED,
        SLASHED
    }

    struct Stake {
        address validator;
        uint256 amount;
        uint256 listingId;
        uint256 lockTimestamp;
        StakeStatus status;
    }

    mapping(uint256 => Stake) public stakes; // stakeId => Stake
    mapping(address => uint256) public validatorTotalStaked;
    mapping(address => uint256[]) public validatorStakes; // validator => stakeIds[]
    
    uint256 public stakeIdCounter;
    bool public paused;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event StakeLocked(
        uint256 indexed stakeId,
        address indexed validator,
        uint256 indexed listingId,
        uint256 amount
    );
    
    event StakeReleased(
        uint256 indexed stakeId,
        address indexed validator,
        uint256 amount
    );
    
    event StakeSlashed(
        uint256 indexed stakeId,
        address indexed validator,
        address indexed beneficiary,
        uint256 amount
    );

    event InsurancePremiumPaid(
        uint256 indexed stakeId,
        uint256 premium
    );

    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error Paused();
    error Unauthorized();
    error InsufficientBalance();
    error StakeNotFound();
    error StakeLocked();
    error InvalidAmount();
    error InvalidValidator();
    error TransferFailed();

    /*//////////////////////////////////////////////////////////////
                             CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _usdc, address _insurancePool) Ownable(msg.sender) {
        USDC = IERC20(_usdc);
        insurancePool = _insurancePool;
    }

    /*//////////////////////////////////////////////////////////////
                              MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier whenNotPaused() {
        if (paused) revert Paused();
        _;
    }

    modifier onlyMarketplace() {
        if (msg.sender != marketplaceContract) revert Unauthorized();
        _;
    }

    modifier onlyDispute() {
        if (msg.sender != disputeContract) revert Unauthorized();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                           CORE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Lock validator stake for a listing
     * @param validator The validator providing collateral for the listing
     * @param listingId The listing being validated
     * @param itemPrice Price of the item (used to calculate required stake)
     * @return stakeId The unique identifier for this stake
     */
    function lockStake(address validator, uint256 listingId, uint256 itemPrice) 
        external 
        whenNotPaused 
        nonReentrant 
        onlyMarketplace
        returns (uint256 stakeId)
    {
        if (validator == address(0)) revert InvalidValidator();

        uint256 requiredStake = getRequiredStake(itemPrice);
        if (requiredStake == 0) revert InvalidAmount();

        // Calculate insurance premium (2% of stake)
        uint256 premium = (requiredStake * INSURANCE_PREMIUM_PCT) / BASIS_POINTS;
        uint256 totalRequired = requiredStake + premium;

        // Transfer USDC from the validator while the marketplace coordinates the action.
        bool success = USDC.transferFrom(validator, address(this), totalRequired);
        if (!success) revert TransferFailed();

        // Transfer premium to insurance pool
        success = USDC.transfer(insurancePool, premium);
        if (!success) revert TransferFailed();

        // Create stake record
        stakeId = ++stakeIdCounter;
        stakes[stakeId] = Stake({
            validator: validator,
            amount: requiredStake,
            listingId: listingId,
            lockTimestamp: block.timestamp,
            status: StakeStatus.LOCKED
        });

        validatorTotalStaked[validator] += requiredStake;
        validatorStakes[validator].push(stakeId);

        emit StakeLocked(stakeId, validator, listingId, requiredStake);
        emit InsurancePremiumPaid(stakeId, premium);
    }

    /**
     * @notice Release stake after successful verification
     * @param stakeId The stake to release
     */
    function releaseStake(uint256 stakeId) 
        external 
        whenNotPaused 
        nonReentrant 
        onlyMarketplace 
    {
        Stake storage stake = stakes[stakeId];
        if (stake.amount == 0) revert StakeNotFound();
        if (stake.status != StakeStatus.LOCKED) revert StakeLocked();
        
        // Enforce 72-hour lock period
        if (block.timestamp < stake.lockTimestamp + LOCK_PERIOD) {
            revert StakeLocked();
        }

        address validator = stake.validator;
        uint256 amount = stake.amount;

        // Update state
        stake.status = StakeStatus.RELEASED;
        validatorTotalStaked[validator] -= amount;

        // Transfer stake back to validator
        bool success = USDC.transfer(validator, amount);
        if (!success) revert TransferFailed();

        emit StakeReleased(stakeId, validator, amount);
    }

    /**
     * @notice Slash validator stake (called by dispute contract)
     * @param stakeId The stake to slash
     * @param beneficiary Who receives the slashed stake (usually buyer)
     */
    function slashStake(uint256 stakeId, address beneficiary) 
        external 
        whenNotPaused 
        nonReentrant 
        onlyDispute 
    {
        Stake storage stake = stakes[stakeId];
        if (stake.amount == 0) revert StakeNotFound();
        if (stake.status != StakeStatus.LOCKED) revert StakeLocked();

        address validator = stake.validator;
        uint256 amount = stake.amount;

        // Update state
        stake.status = StakeStatus.SLASHED;
        validatorTotalStaked[validator] -= amount;

        // Insurance pool covers first 40% if available
        // (This would call InsurancePool contract - simplified here)
        
        // Transfer slashed stake to beneficiary (buyer)
        bool success = USDC.transfer(beneficiary, amount);
        if (!success) revert TransferFailed();

        emit StakeSlashed(stakeId, validator, beneficiary, amount);
    }

    /*//////////////////////////////////////////////////////////////
                          VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Calculate required stake based on item price (tiered)
     * @param itemPrice Price of the item in USDC (6 decimals)
     * @return Required stake amount
     */
    function getRequiredStake(uint256 itemPrice) public pure returns (uint256) {
        if (itemPrice < TIER_1_THRESHOLD) {
            return (itemPrice * TIER_1_STAKE_PCT) / BASIS_POINTS;
        } else if (itemPrice < TIER_2_THRESHOLD) {
            return (itemPrice * TIER_2_STAKE_PCT) / BASIS_POINTS;
        } else if (itemPrice < TIER_3_THRESHOLD) {
            return (itemPrice * TIER_3_STAKE_PCT) / BASIS_POINTS;
        } else {
            return (itemPrice * TIER_4_STAKE_PCT) / BASIS_POINTS;
        }
    }

    /**
     * @notice Get all stake IDs for a validator
     */
    function getValidatorStakes(address validator) external view returns (uint256[] memory) {
        return validatorStakes[validator];
    }

    /**
     * @notice Get stake details
     */
    function getStake(uint256 stakeId) external view returns (Stake memory) {
        return stakes[stakeId];
    }

    /*//////////////////////////////////////////////////////////////
                          ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function setMarketplaceContract(address _marketplace) external onlyOwner {
        marketplaceContract = _marketplace;
    }

    function setDisputeContract(address _dispute) external onlyOwner {
        disputeContract = _dispute;
    }

    function emergencyPause() external onlyOwner {
        paused = true;
    }

    function unpause() external onlyOwner {
        paused = false;
    }
}
