// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {BoraStaking} from "../src/BoraStaking.sol";

contract DeployScript is Script {
    // Base Sepolia USDC (mock for testnet)
    address constant USDC_SEPOLIA = 0x036CbD53842c5426634e7929541eC2318f3dCF7e;
    
    // Base Mainnet USDC
    address constant USDC_MAINNET = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console2.log("Deploying from:", deployer);
        console2.log("Deployer balance:", deployer.balance);

        vm.startBroadcast(deployerPrivateKey);

        // Determine which USDC to use based on chain
        address usdcAddress = block.chainid == 84532 ? USDC_SEPOLIA : USDC_MAINNET;
        
        // For initial deployment, insurance pool is deployer (will be replaced)
        address insurancePool = deployer;

        // Deploy staking contract
        BoraStaking staking = new BoraStaking(usdcAddress, insurancePool);

        console2.log("BoraStaking deployed at:", address(staking));
        console2.log("USDC address:", usdcAddress);
        console2.log("Insurance pool:", insurancePool);

        vm.stopBroadcast();

        // Save deployment addresses
        console2.log("\n=== DEPLOYMENT COMPLETE ===");
        console2.log("Add these to your .env:");
        console2.log("STAKING_CONTRACT=", address(staking));
    }
}
