// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {VoteStorage} from "../src/VoteStorage.sol";
import {ElectionFactory} from "../src/ElectionFactory.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/**
 * @title DeployVoteStorage
 * @author cypherpulse.base.eth
 * @notice This script deploys the upgradeable VoteStorage contract with proxy
 * @dev Uses OpenZeppelin's ERC1967Proxy for upgradeability
 */
contract DeployVoteStorage is Script {
    
    ////////////////////////////////////////////////////////////////////////////
    ////                           FUNCTIONS                                ////
    ////////////////////////////////////////////////////////////////////////////
    
    /**
     * @notice Main deployment function
     * @return proxy The deployed VoteStorage proxy contract
     * @return helperConfig The HelperConfig instance used
     */
    function run() external returns (VoteStorage, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getActiveNetworkConfig();
        
        return deployVoteStorage(config);
    }
    
    /**
     * @notice Deploys VoteStorage with proxy pattern
     * @param config Network configuration from HelperConfig
     * @return voteStorageProxy The deployed proxy contract
     * @return helperConfig The HelperConfig instance
     */
    function deployVoteStorage(HelperConfig.NetworkConfig memory config) 
        public 
        returns (VoteStorage, HelperConfig) 
    {
        console.log("Deploying VoteStorage with Proxy on", config.networkName);
        console.log("Deployer address:", config.deployer);
        
        // We need an ElectionFactory address to initialize VoteStorage
        // This should be passed as parameter or read from previous deployment
        address electionFactoryAddress = _getElectionFactoryAddress(config);
        
        console.log("Using ElectionFactory at:", electionFactoryAddress);
        
        vm.startBroadcast(config.deployerKey);
        
        // 1. Deploy the implementation contract
        VoteStorage voteStorageImplementation = new VoteStorage();
        console.log("Implementation deployed at:", address(voteStorageImplementation));
        
        // 2. Encode the initializer function call
        bytes memory initializerData = abi.encodeCall(
            VoteStorage.initialize,
            (electionFactoryAddress)
        );
        
        // 3. Deploy the proxy contract
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(voteStorageImplementation),
            initializerData
        );
        
        console.log("Proxy deployed at:", address(proxy));
        
        vm.stopBroadcast();
        
        // 4. Wrap the proxy in the VoteStorage interface
        VoteStorage voteStorageProxy = VoteStorage(address(proxy));
        
        // 5. Verify deployment
        _verifyDeployment(voteStorageProxy, electionFactoryAddress, config);
        
        return (voteStorageProxy, new HelperConfig());
    }
    
    /**
     * @notice Gets ElectionFactory address for initialization
     * @param config Network configuration
     * @return electionFactoryAddress The address to use
     * @dev In production, this would read from deployment artifacts
     */
    function _getElectionFactoryAddress(HelperConfig.NetworkConfig memory config) 
        internal 
        pure 
        returns (address) 
    {
        // For now, we'll use a placeholder
        // In real deployment, you'd either:
        // 1. Pass this as a parameter
        // 2. Read from deployment artifacts
        // 3. Deploy ElectionFactory first in the same script
        
        if (config.chainId == 31337) { // Local Anvil
            // Return zero address for local testing - we'll deploy both contracts
            return address(0);
        }
        
        // For testnets/mainnet, you'd use the actual deployed address
        revert("ElectionFactory address not configured for this network");
    }
    
    /**
     * @notice Deploys both contracts together for local testing
     * @param config Network configuration
     * @return voteStorage The VoteStorage proxy
     * @return electionFactory The ElectionFactory contract
     */
    function deployBothContracts(HelperConfig.NetworkConfig memory config)
        external
        returns (VoteStorage, ElectionFactory)
    {
        console.log("Deploying both contracts for local testing...");
        
        vm.startBroadcast(config.deployerKey);
        
        // 1. Deploy ElectionFactory first
        ElectionFactory electionFactory = new ElectionFactory();
        console.log("ElectionFactory deployed at:", address(electionFactory));
        
        // 2. Deploy VoteStorage implementation
        VoteStorage voteStorageImpl = new VoteStorage();
        
        // 3. Encode initializer with ElectionFactory address
        bytes memory initData = abi.encodeCall(
            VoteStorage.initialize,
            (address(electionFactory))
        );
        
        // 4. Deploy proxy
        ERC1967Proxy proxy = new ERC1967Proxy(address(voteStorageImpl), initData);
        
        vm.stopBroadcast();
        
        VoteStorage voteStorage = VoteStorage(address(proxy));
        
        console.log("VoteStorage proxy deployed at:", address(proxy));
        
        // Verify both deployments
        _verifyBothContracts(voteStorage, electionFactory, config);
        
        return (voteStorage, electionFactory);
    }
    
    /**
     * @notice Verifies VoteStorage deployment
     */
    function _verifyDeployment(
        VoteStorage voteStorage,
        address expectedFactory,
        HelperConfig.NetworkConfig memory config
    ) internal view {
        console.log("Verifying VoteStorage deployment...");
        
        // Check proxy deployed correctly
        require(address(voteStorage).code.length > 0, "Proxy not deployed");
        
        // Check initialization worked
        require(
            voteStorage.getElectionFactory() == expectedFactory,
            "ElectionFactory not set correctly"
        );
        
        // Check ownership
        require(
            voteStorage.owner() == config.deployer,
            "Owner not set correctly"
        );
        
        console.log("✅ VoteStorage verification passed!");
    }
    
    /**
     * @notice Verifies both contract deployments
     */
    function _verifyBothContracts(
        VoteStorage voteStorage,
        ElectionFactory electionFactory,
        HelperConfig.NetworkConfig memory config
    ) internal view {
        console.log("Verifying both contract deployments...");
        
        // Verify ElectionFactory
        require(
            electionFactory.getPlatformAdmin() == config.deployer,
            "ElectionFactory admin incorrect"
        );
        
        // Verify VoteStorage
        require(
            voteStorage.getElectionFactory() == address(electionFactory),
            "VoteStorage factory reference incorrect"
        );
        
        require(
            voteStorage.owner() == config.deployer,
            "VoteStorage owner incorrect"
        );
        
        console.log("✅ Both contracts verified successfully!");
        
        // Log summary
        console.log("\n=== DEPLOYMENT SUMMARY ===");
        console.log("Network:", config.networkName);
        console.log("ElectionFactory:", address(electionFactory));
        console.log("VoteStorage Proxy:", address(voteStorage));
        console.log("Deployer:", config.deployer);
        console.log("========================\n");
    }
}