// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Test} from "forge-std/Test.sol";
import {InsurancePool} from "../src/InsurancePool.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract InsurancePoolTest is Test {
    InsurancePool public pool;
    ERC20Mock public usdc;

    address public owner = address(1);
    address public staking = address(2);
    address public validator1 = address(5);
    address public seeder = address(7);
    address public recipient = address(77);

    uint256 constant FUND_BALANCE = 1_000_000e6; // $1,000,000 USDC

    function setUp() public {
        usdc = new ERC20Mock();

        // Deploy pool as owner
        vm.prank(owner);
        pool = new InsurancePool(address(usdc));

        // Authorize the staking contract
        vm.prank(owner);
        pool.setStakingContract(staking);

        // Fund and approve the staking contract (drives contributePremium)
        usdc.mint(staking, FUND_BALANCE);
        vm.prank(staking);
        usdc.approve(address(pool), type(uint256).max);

        // Fund and approve a seeder (drives seedPool)
        usdc.mint(seeder, FUND_BALANCE);
        vm.prank(seeder);
        usdc.approve(address(pool), type(uint256).max);
    }

    /*//////////////////////////////////////////////////////////////
                        PREMIUM CONTRIBUTION TESTS
    //////////////////////////////////////////////////////////////*/

    function test_ContributePremium_BaseRate() public {
        // $1000 stake at 2% base premium = $20
        vm.prank(staking);
        uint256 premium = pool.contributePremium(validator1, 1_000e6);

        assertEq(premium, 20e6, "Premium should be 2% of stake");

        (uint256 totalContributions,, uint256 currentBalance,) = pool.poolStats();
        assertEq(totalContributions, 20e6, "Contributions should equal premium");
        assertEq(currentBalance, 20e6, "Balance should equal premium");
        assertEq(pool.validatorContributions(validator1), 20e6, "Validator contribution tracked");
        assertEq(usdc.balanceOf(address(pool)), 20e6, "Pool should hold the premium");
    }

    function test_ContributePremium_OnlyStaking() public {
        vm.prank(validator1);
        vm.expectRevert(InsurancePool.Unauthorized.selector);
        pool.contributePremium(validator1, 1_000e6);
    }

    /*//////////////////////////////////////////////////////////////
                          COVERAGE CLAIM TESTS
    //////////////////////////////////////////////////////////////*/

    function test_ClaimCoverage_Pays40Percent() public {
        // Fund the pool so it can pay a full claim
        vm.prank(seeder);
        pool.seedPool(1_000e6);

        uint256 stakingBalanceBefore = usdc.balanceOf(staking);

        // $100 slashed → 40% coverage = $40
        vm.prank(staking);
        uint256 coverage = pool.claimCoverage(validator1, 100e6);

        assertEq(coverage, 40e6, "Coverage should be 40% of slashed amount");
        assertEq(
            usdc.balanceOf(staking),
            stakingBalanceBefore + 40e6,
            "Coverage should be forwarded to staking contract"
        );

        (, uint256 totalClaims, uint256 currentBalance,) = pool.poolStats();
        assertEq(totalClaims, 40e6, "Total claims tracked");
        assertEq(currentBalance, 960e6, "Balance reduced by coverage");
        assertEq(pool.validatorClaims(validator1), 40e6, "Validator claim tracked");
    }

    function test_ClaimCoverage_PoolDepleted_PaysPartial() public {
        // Pool only has $10, but 40% of $100 would be $40
        vm.prank(seeder);
        pool.seedPool(10e6);

        vm.prank(staking);
        uint256 coverage = pool.claimCoverage(validator1, 100e6);

        assertEq(coverage, 10e6, "Should pay only what the pool holds");

        (, uint256 totalClaims, uint256 currentBalance,) = pool.poolStats();
        assertEq(currentBalance, 0, "Pool drained to zero");
        assertEq(totalClaims, 10e6, "Partial payout tracked as claim");
    }

    function test_ClaimCoverage_EmptyPool_ReturnsZero() public {
        uint256 stakingBalanceBefore = usdc.balanceOf(staking);

        vm.prank(staking);
        uint256 coverage = pool.claimCoverage(validator1, 100e6);

        assertEq(coverage, 0, "Empty pool pays nothing");
        assertEq(usdc.balanceOf(staking), stakingBalanceBefore, "No transfer on empty pool");
    }

    function test_ClaimCoverage_OnlyStaking() public {
        vm.prank(validator1);
        vm.expectRevert(InsurancePool.Unauthorized.selector);
        pool.claimCoverage(validator1, 100e6);
    }

    /*//////////////////////////////////////////////////////////////
                            SEEDING TESTS
    //////////////////////////////////////////////////////////////*/

    function test_SeedPool_IncreasesBalance() public {
        uint256 poolBalanceBefore = usdc.balanceOf(address(pool));

        vm.prank(seeder);
        pool.seedPool(500e6);

        (,, uint256 currentBalance,) = pool.poolStats();
        assertEq(currentBalance, 500e6, "Seed should increase tracked balance");
        assertEq(usdc.balanceOf(address(pool)), poolBalanceBefore + 500e6, "Pool holds seeded USDC");
    }

    /*//////////////////////////////////////////////////////////////
                          POOL HEALTH TESTS
    //////////////////////////////////////////////////////////////*/

    function test_GetPoolHealth_HealthyWhenNoTarget() public view {
        (uint256 currentBalance, uint256 targetBalance, uint256 healthPercentage, bool isHealthy) =
            pool.getPoolHealth();

        assertEq(currentBalance, 0, "No balance yet");
        assertEq(targetBalance, 0, "No target yet");
        assertEq(healthPercentage, 100, "Health defaults to 100% with no target");
        assertTrue(isHealthy, "Pool is healthy with no target set");
    }

    /*//////////////////////////////////////////////////////////////
                           ADMIN TESTS
    //////////////////////////////////////////////////////////////*/

    function test_SetStakingContract_OnlyOwner() public {
        vm.prank(validator1);
        vm.expectRevert(); // Ownable: OwnableUnauthorizedAccount
        pool.setStakingContract(address(123));
    }

    function test_EmergencyWithdraw_TransfersFullBalance() public {
        vm.prank(seeder);
        pool.seedPool(100e6);

        vm.prank(owner);
        pool.emergencyWithdraw(recipient);

        assertEq(usdc.balanceOf(recipient), 100e6, "Recipient receives full pool balance");
        assertEq(usdc.balanceOf(address(pool)), 0, "Pool emptied");
    }

    function test_EmergencyWithdraw_OnlyOwner() public {
        vm.prank(validator1);
        vm.expectRevert(); // Ownable: OwnableUnauthorizedAccount
        pool.emergencyWithdraw(recipient);
    }
}
