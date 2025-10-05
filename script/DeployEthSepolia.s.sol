// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {ElectionFactory} from "../src/ElectionFactory.sol";
import {VoteStorage} from "../src/VoteStorage.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployEthSepolia is Script {
    function run() external {
        // Get deployment config
        address deployer = vm.envAddress("DEPLOYER_ADDRESS");
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        
        console.log(" Deploying to Ethereum Sepolia");
        console.log("=================================");
        console.log("Deployer:", deployer);
        console.log("Chain ID: 11155111 (Ethereum Sepolia)");
        console.log("");
        
        vm.startBroadcast(deployerKey);
        
        // Step 1: Deploy ElectionFactory
        console.log("Step 1: Deploying ElectionFactory...");
        ElectionFactory electionFactory = new ElectionFactory();
        console.log("ElectionFactory deployed at:", address(electionFactory));
        console.log("   Platform Admin:", electionFactory.getPlatformAdmin());
        console.log("");
        
        // Step 2: Deploy VoteStorage Implementation
        console.log("Step 2: Deploying VoteStorage Implementation...");
        VoteStorage voteStorageImplementation = new VoteStorage();
        console.log("VoteStorage Implementation:", address(voteStorageImplementation));
        console.log("");
        
        // Step 3: Deploy VoteStorage Proxy
        console.log("Step 3: Deploying VoteStorage Proxy...");
        bytes memory initData = abi.encodeCall(
            VoteStorage.initialize,
            (address(electionFactory))
        );
        ERC1967Proxy voteStorageProxy = new ERC1967Proxy(
            address(voteStorageImplementation),
            initData
        );
        console.log("VoteStorage Proxy:", address(voteStorageProxy));
        console.log("");
        
        vm.stopBroadcast();
        
        // Step 4: Verification
        console.log("Step 4: Verifying Deployment...");
        VoteStorage voteStorage = VoteStorage(address(voteStorageProxy));
        
        require(
            voteStorage.getElectionFactory() == address(electionFactory),
            "VoteStorage factory reference incorrect"
        );
        require(
            voteStorage.owner() == deployer,
            "VoteStorage owner incorrect"
        );
        require(
            electionFactory.getPlatformAdmin() == deployer,
            "ElectionFactory admin incorrect"
        );
        
        console.log(" All verification checks passed!");
        console.log("");
        
        // Final Summary
        console.log(" ETHEREUM SEPOLIA DEPLOYMENT COMPLETE!");
        console.log("========================================");
        console.log("");
        console.log(" CONTRACT ADDRESSES:");
        console.log("ElectionFactory:           ", address(electionFactory));
        console.log("VoteStorage Proxy:         ", address(voteStorageProxy));
        console.log("VoteStorage Implementation:", address(voteStorageImplementation));
        console.log("");
        console.log(" VIEW ON ETHERSCAN:");
        console.log("ElectionFactory:    https://sepolia.etherscan.io/address/", address(electionFactory));
        console.log("VoteStorage Proxy:  https://sepolia.etherscan.io/address/", address(voteStorageProxy));
        console.log("");
        console.log("eKura is now live on Ethereum Sepolia!");
    }
}