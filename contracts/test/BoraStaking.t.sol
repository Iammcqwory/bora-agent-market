// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Test} from "forge-std/Test.sol";
import {BoraStaking} from "../src/BoraStaking.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract BoraStakingTest is Test {
    BoraStaking public staking;
    ERC20Mock public usdc;
    
    address public owner = address(1);
    address public marketplace = address(2);
    address public dispute = address(3);
    address public insurancePool = address(4);
    address public validator1 = address(5);
    address public validator2 = address(6);
    address public buyer = address(7);

    uint256 constant USDC_DECIMALS = 6;
    uint256 constant INITIAL_BALANCE = 10_000e6; // $10,000 USDC

    function setUp() public {
        // Deploy mock USDC
        usdc = new ERC20Mock();
        
        // Deploy staking contract
        vm.prank(owner);
        staking = new BoraStaking(address(usdc), insurancePool);
        
        // Set authorized contracts
        vm.startPrank(owner);
        staking.setMarketplaceContract(marketplace);
        staking.setDisputeContract(dispute);
        vm.stopPrank();

        // Fund validators
        usdc.mint(validator1, INITIAL_BALANCE);
        usdc.mint(validator2, INITIAL_BALANCE);

        // Approve staking contract
        vm.prank(validator1);
        usdc.approve(address(staking), type(uint256).max);
        
        vm.prank(validator2);
        usdc.approve(address(staking), type(uint256).max);
    }

    /*//////////////////////////////////////////////////////////////
                         STAKE REQUIREMENT TESTS
    //////////////////////////////////////////////////////////////*/

    function test_StakeRequirement_Tier1() public {
        // $50 item → 20% stake
        uint256 stake = staking.getRequiredStake(50e6);
        assertEq(stake, 10e6, "Tier 1: 20% of $50 should be $10");
    }

    function test_StakeRequirement_Tier2() public {
        // $300 item → 35% stake
        uint256 stake = staking.getRequiredStake(300e6);
        assertEq(stake, 105e6, "Tier 2: 35% of $300 should be $105");
    }

    function test_StakeRequirement_Tier3() public {
        // $750 item → 50% stake
        uint256 stake = staking.getRequiredStake(750e6);
        assertEq(stake, 375e6, "Tier 3: 50% of $750 should be $375");
    }

    function test_StakeRequirement_Tier4() public {
        // $1500 item → 75% stake
        uint256 stake = staking.getRequiredStake(1500e6);
        assertEq(stake, 1125e6, "Tier 4: 75% of $1500 should be $1125");
    }

    /*//////////////////////////////////////////////////////////////
                           LOCKING TESTS
    //////////////////////////////////////////////////////////////*/

    function test_LockStake_Success() public {
        uint256 itemPrice = 300e6; // $300
        uint256 requiredStake = staking.getRequiredStake(itemPrice);
        uint256 premium = (requiredStake * 200) / 10_000; // 2%
        uint256 totalCost = requiredStake + premium;

        uint256 balanceBefore = usdc.balanceOf(validator1);

        vm.prank(marketplace);
        uint256 stakeId = staking.lockStake(validator1, 1, itemPrice);

        // Verify stake created
        assertEq(stakeId, 1, "First stake should have ID 1");
        
        // Verify USDC transferred
        assertEq(
            usdc.balanceOf(validator1), 
            balanceBefore - totalCost,
            "Validator should pay stake + premium"
        );
        
        // Verify insurance premium sent to pool
        assertEq(
            usdc.balanceOf(insurancePool),
            premium,
            "Premium should be sent to insurance pool"
        );

        // Verify stake details
        BoraStaking.Stake memory stake = staking.getStake(stakeId);
        assertEq(stake.validator, validator1);
        assertEq(stake.amount, requiredStake);
        assertEq(stake.listingId, 1);
        assertTrue(uint8(stake.status) == 0); // LOCKED
    }

    function test_LockStake_OnlyMarketplace() public {
        vm.prank(validator1);
        vm.expectRevert(BoraStaking.Unauthorized.selector);
        staking.lockStake(validator1, 1, 300e6);
    }

    function test_LockStake_InsufficientBalance() public {
        // Validator doesn't have enough USDC
        address poorValidator = address(99);
        usdc.mint(poorValidator, 10e6); // Only $10
        
        vm.prank(poorValidator);
        usdc.approve(address(staking), type(uint256).max);

        vm.prank(marketplace);
        vm.expectRevert(); // ERC20 transfer will fail
        staking.lockStake(poorValidator, 1, 1000e6); // Requires $750 stake
    }

    /*//////////////////////////////////////////////////////////////
                          RELEASE TESTS
    //////////////////////////////////////////////////////////////*/

    function test_ReleaseStake_Success() public {
        // Lock stake
        vm.prank(marketplace);
        uint256 stakeId = staking.lockStake(validator1, 1, 300e6);

        uint256 requiredStake = staking.getRequiredStake(300e6);
        uint256 balanceBefore = usdc.balanceOf(validator1);

        // Fast forward past lock period (72 hours)
        vm.warp(block.timestamp + 72 hours + 1);

        // Release stake
        vm.prank(marketplace);
        staking.releaseStake(stakeId);

        // Verify stake returned
        assertEq(
            usdc.balanceOf(validator1),
            balanceBefore + requiredStake,
            "Stake should be returned to validator"
        );

        // Verify status updated
        BoraStaking.Stake memory stake = staking.getStake(stakeId);
        assertTrue(uint8(stake.status) == 1); // RELEASED
    }

    function test_ReleaseStake_TooEarly() public {
        vm.prank(marketplace);
        uint256 stakeId = staking.lockStake(validator1, 1, 300e6);

        // Try to release immediately
        vm.prank(marketplace);
        vm.expectRevert(BoraStaking.StakeLocked.selector);
        staking.releaseStake(stakeId);

        // Try after 24 hours (still too early)
        vm.warp(block.timestamp + 24 hours);
        vm.prank(marketplace);
        vm.expectRevert(BoraStaking.StakeLocked.selector);
        staking.releaseStake(stakeId);
    }

    function test_ReleaseStake_OnlyMarketplace() public {
        vm.prank(marketplace);
        uint256 stakeId = staking.lockStake(validator1, 1, 300e6);

        vm.warp(block.timestamp + 72 hours + 1);

        vm.prank(validator1);
        vm.expectRevert(BoraStaking.Unauthorized.selector);
        staking.releaseStake(stakeId);
    }

    /*//////////////////////////////////////////////////////////////
                          SLASHING TESTS
    //////////////////////////////////////////////////////////////*/

    function test_SlashStake_Success() public {
        // Lock stake
        vm.prank(marketplace);
        uint256 stakeId = staking.lockStake(validator1, 1, 300e6);

        uint256 requiredStake = staking.getRequiredStake(300e6);
        uint256 buyerBalanceBefore = usdc.balanceOf(buyer);

        // Slash stake (dispute contract wins for buyer)
        vm.prank(dispute);
        staking.slashStake(stakeId, buyer);

        // Verify slashed stake sent to buyer
        assertEq(
            usdc.balanceOf(buyer),
            buyerBalanceBefore + requiredStake,
            "Buyer should receive slashed stake"
        );

        // Verify status updated
        BoraStaking.Stake memory stake = staking.getStake(stakeId);
        assertTrue(uint8(stake.status) == 2); // SLASHED
    }

    function test_SlashStake_OnlyDispute() public {
        vm.prank(marketplace);
        uint256 stakeId = staking.lockStake(validator1, 1, 300e6);

        vm.prank(marketplace);
        vm.expectRevert(BoraStaking.Unauthorized.selector);
        staking.slashStake(stakeId, buyer);
    }

    function test_SlashStake_CannotSlashTwice() public {
        vm.prank(marketplace);
        uint256 stakeId = staking.lockStake(validator1, 1, 300e6);

        vm.prank(dispute);
        staking.slashStake(stakeId, buyer);

        // Try to slash again
        vm.prank(dispute);
        vm.expectRevert(BoraStaking.StakeLocked.selector);
        staking.slashStake(stakeId, buyer);
    }

    /*//////////////////////////////////////////////////////////////
                           PAUSE TESTS
    //////////////////////////////////////////////////////////////*/

    function test_Pause_StopsOperations() public {
        vm.prank(owner);
        staking.emergencyPause();

        vm.prank(marketplace);
        vm.expectRevert(BoraStaking.Paused.selector);
        staking.lockStake(validator1, 1, 300e6);
    }

    function test_Unpause_ResumesOperations() public {
        vm.prank(owner);
        staking.emergencyPause();

        vm.prank(owner);
        staking.unpause();

        vm.prank(marketplace);
        uint256 stakeId = staking.lockStake(validator1, 1, 300e6);
        assertEq(stakeId, 1, "Should work after unpause");
    }

    /*//////////////////////////////////////////////////////////////
                      VALIDATOR TRACKING TESTS
    //////////////////////////////////////////////////////////////*/

    function test_ValidatorStakes_TrackedCorrectly() public {
        // Validator stakes on 3 items
        vm.startPrank(marketplace);
        staking.lockStake(validator1, 1, 100e6);
        staking.lockStake(validator1, 2, 200e6);
        staking.lockStake(validator1, 3, 300e6);
        vm.stopPrank();

        uint256[] memory stakes = staking.getValidatorStakes(validator1);
        assertEq(stakes.length, 3, "Should track 3 stakes");
        assertEq(stakes[0], 1);
        assertEq(stakes[1], 2);
        assertEq(stakes[2], 3);
    }

    function test_ValidatorTotalStaked_UpdatesCorrectly() public {
        uint256 stake1 = staking.getRequiredStake(300e6);
        uint256 stake2 = staking.getRequiredStake(500e6);

        vm.startPrank(marketplace);
        staking.lockStake(validator1, 1, 300e6);
        staking.lockStake(validator1, 2, 500e6);
        vm.stopPrank();

        assertEq(
            staking.validatorTotalStaked(validator1),
            stake1 + stake2,
            "Total should be sum of both stakes"
        );
    }
}
