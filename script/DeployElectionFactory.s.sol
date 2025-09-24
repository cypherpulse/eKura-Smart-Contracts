
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

        console.log("ElectionFactory deployed at:")
    }
}