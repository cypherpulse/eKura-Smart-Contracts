// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {ElectionFactory} from "../src/ElectionFactory.sol";
import {VoteStorage} from "../src/VoteStorage.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/**
 * @title Deploy
 * @author eKura Team
 * @notice Main deployment script for complete eKura system
 * @dev Deploys ElectionFactory + VoteStorage with proper configuration
 */
contract Deploy is Script {
    
    ////////////////////////////////////////////////////////////////////////////
    ////                           STRUCTS                                  ////
    ////////////////////////////////////////////////////////////////////////////
    
    struct DeploymentResult {
        ElectionFactory electionFactory;
        VoteStorage voteStorage;
        address voteStorageProxy;
        address voteStorageImplementation;
        HelperConfig helperConfig;
        HelperConfig.NetworkConfig networkConfig;
    }
    
    ////////////////////////////////////////////////////////////////////////////
    ////                           FUNCTIONS                                ////
    ////////////////////////////////////////////////////////////////////////////
    
    /**
     * @notice Main deployment function
     * @return result Complete deployment information
     */
    function run() external returns (DeploymentResult memory result) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getActiveNetworkConfig();
        
        console.log("Starting eKura Smart Contract Deployment");
        console.log("==========================================");
        console.log("Network:", config.networkName);
        console.log("Chain ID:", config.chainId);
        console.log("Deployer:", config.deployer);
        console.log("Is Testnet:", config.isTestnet);
        console.log("");
        
        return deployCompleteSystem(config, helperConfig);
    }
    
    /**
     * @notice Deploys the complete eKura system
     * @param config Network configuration
     * @param helperConfig Helper config instance
     * @return result Deployment result with all contract addresses
     */
    function deployCompleteSystem(
        HelperConfig.NetworkConfig memory config,
        HelperConfig helperConfig
    ) public returns (DeploymentResult memory result) {
        
        console.log("Deployment Plan:");
        console.log("1. Deploy ElectionFactory");
        console.log("2. Deploy VoteStorage Implementation");
        console.log("3. Deploy VoteStorage Proxy");
        console.log("4. Initialize VoteStorage");
        console.log("5. Verify Deployment");
        console.log("");
        
        vm.startBroadcast(config.deployerKey);
        
        // Step 1: Deploy ElectionFactory
        console.log("Step 1: Deploying ElectionFactory...");
        ElectionFactory electionFactory = new ElectionFactory();
        console.log("ElectionFactory deployed at:", address(electionFactory));
        console.log("   Platform Admin:", electionFactory.getPlatformAdmin());
        console.log("");
        
        // Step 2: Deploy VoteStorage Implementation
        console.log("Step 2: Deploying VoteStorage Implementation...");
        VoteStorage voteStorageImplementation = new VoteStorage();
        console.log("VoteStorage Implementation deployed at:", address(voteStorageImplementation));
        console.log("");
        
        // Step 3: Prepare initialization data
        console.log("Step 3: Preparing VoteStorage initialization...");
        bytes memory initializerData = abi.encodeCall(
            VoteStorage.initialize,
            (address(electionFactory))
        );
        console.log("Initialization data prepared");
        console.log("");
        
        // Step 4: Deploy VoteStorage Proxy
        console.log("Step 4: Deploying VoteStorage Proxy...");
        ERC1967Proxy voteStorageProxy = new ERC1967Proxy(
            address(voteStorageImplementation),
            initializerData
        );
        console.log("VoteStorage Proxy deployed at:", address(voteStorageProxy));
        console.log("");
        
        vm.stopBroadcast();
        
        // Step 5: Wrap proxy in VoteStorage interface
        VoteStorage voteStorage = VoteStorage(address(voteStorageProxy));
        
        // Step 6: Verify deployment
        console.log("Step 5: Verifying Deployment...");
        _verifyDeployment(electionFactory, voteStorage, config);
        
        // Prepare result
        result = DeploymentResult({
            electionFactory: electionFactory,
            voteStorage: voteStorage,
            voteStorageProxy: address(voteStorageProxy),
            voteStorageImplementation: address(voteStorageImplementation),
            helperConfig: helperConfig,
            networkConfig: config
        });
        
        // Final summary
        _printDeploymentSummary(result);
        
        return result;
    }
    
    /**
     * @notice Verifies that deployment was successful
     */
    function _verifyDeployment(
        ElectionFactory electionFactory,
        VoteStorage voteStorage,
        HelperConfig.NetworkConfig memory config
    ) internal view {
        
        // Verify ElectionFactory
        require(address(electionFactory).code.length > 0, "ElectionFactory not deployed");
        require(
            electionFactory.getPlatformAdmin() == config.deployer,
            "ElectionFactory admin incorrect"
        );
        require(
            electionFactory.getTotalElections() == 0,
            "ElectionFactory initial state incorrect"
        );
        
        // Verify VoteStorage
        require(address(voteStorage).code.length > 0, "VoteStorage not deployed");
        require(
            voteStorage.getElectionFactory() == address(electionFactory),
            "VoteStorage factory reference incorrect"
        );
        require(
            voteStorage.owner() == config.deployer,
            "VoteStorage owner incorrect"
        );
        
        console.log("All verification checks passed!");
        console.log("");
    }
    
    /**
     * @notice Prints final deployment summary
     */
    function _printDeploymentSummary(DeploymentResult memory result) internal view {
        console.log("DEPLOYMENT COMPLETED SUCCESSFULLY!");
        console.log("=====================================");
        console.log("");
        console.log("CONTRACT ADDRESSES:");
        console.log("----------------------");
        console.log("ElectionFactory:           ", address(result.electionFactory));
        console.log("VoteStorage Proxy:         ", result.voteStorageProxy);
        console.log("VoteStorage Implementation:", result.voteStorageImplementation);
        console.log("");
        console.log("CONFIGURATION:");
        console.log("------------------");
        console.log("Network:        ", result.networkConfig.networkName);
        console.log("Chain ID:       ", result.networkConfig.chainId);
        console.log("Platform Admin: ", result.networkConfig.deployer);
        console.log("Is Testnet:     ", result.networkConfig.isTestnet);
        console.log("");
        console.log("NEXT STEPS:");
        console.log("---------------");
        if (result.networkConfig.isTestnet) {
            console.log("1. Run integration tests");
            console.log("2. Create sample elections for testing");
            console.log("3. Test voting functionality");
            console.log("4. Deploy to mainnet when ready");
        } else {
            console.log("1. Verify contracts on explorer");
            console.log("2. Set up monitoring");
            console.log("3. Configure backend integration");
            console.log("4. Launch eKura platform!");
        }
        console.log("");
        console.log("eKura Smart Contracts are live and ready!");
        console.log("============================================");
    }
}