
//SPDX-LIcense-Identifier: MIT

pragma solidity ^0.8.20;

import {Script,console} from "forge-std/Script.sol";
import {ElectionFactory} from "../src/ElectionFactory.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

/**
 * @title DeployElectionFactory
 * @author cypherpulse.base.eth
 * @notice This script deploys the ElectionFactory contract
 * @dev Handles deployment across different networks using HelperConfig
 */

contract DeployElectionFactory is Script{
    //Funcions //
    /***
     * @notice Main deployment function
     * @return electionFactory The deployed ElectionFactory contract
     * @return helperConfig The HelperConfig instance used
     */

    function run() external returns (ElectionFactory,HelperConfig){
        HelperConfig helperConfig = new HelperConfig();
        HelperConfg.NetworkConfig memory config = helperConfig.getActiveNetworkConfig();

        return deployElectionFactory(config);
    }

    /***
     * @notice Deploys ElectionFactory contract
     * @param config Network configuration from HelperCofig
     * @return electionFactory The deployed contract instance
     * @return helperConfig The HelperConfig instance
     * 
     */

    function deployElectionFactory(HelperConfig.NetworkConfig memory config)
    public 
    returns (ElectionFactory,HelperConfig)
    {
        console.log("Deploying ElectionFactory on", config.networkName);
        console.log("Deployer address:", config.deployer);
        console.log("Chain ID:", config.chainId);

        // Start broadcasting transactions
        vm.startBroadcast(config.deployerKey);

        //Deploy ElectionFactory contract
        ElecionFactory electionFactory = new ElectionFactory();

        // Stop broadcasting
        vm.stopBroadcast();

        console.log("ElectionFactory deployed at:",config.networkName);
        console.log("Deployer address :",config.deployer);
        console.log("Chain ID:",config.chainId);

        //Start broadcasting transactions
        vm.startBroadcast(config.deployerKey);

        //Deploy ElectionFactory contract
        ElectionFactory electionFactory = new ElectionFactory();

        //Stop broadcasting
        vm.stopBroadcast();

        console.log("ElectionFactory deployed at:",address(electionFactory));
        console.log("Platform admin set to:",electionFactory.getPlatformAdmin());

        //Verify deployment worked correctly 
        _verifyDeployment(electionFactory, config);

        return (electionFactory, new HelperConfig());
    }

    /***
     * @notice Verifies the deployment was succesful
     * @param electionFactory The deployed contract to verify
     * @param config Network configuration used
     */

    function _verifyDeployment(
        ElectionFactory electionFactory,
        HelperConfig.NetworkConfig memory config
    )internal view{
        console.log("Verifying deployment...");

        //check platfrom admin is set correctly 
        require(
            electionFactory.getPlatfromAdmin() == config.deployer,
            "Platform admin not set correctly"
        );

        //Check initial election ID is set 
        require(
            electionFactory.getTotalElections()==0,
            "Initial election count should be 0"
        );

        console.log("Deployment Verification Passed");

        //Log deployment summary
        console.log("\n=== DEPLOYMENT SUMMARY ===");
        console.log("Network:",config.networkName);
        console.log("Contract Address:",address(electionFactory));
        console.log("Platform Admin:",electionFactory.getPlatformAdmin());
    }
}