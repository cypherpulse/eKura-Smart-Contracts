
// SPDX-License-Identifer: MIT

pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
/***
 * @title HelperConfig
 * @author cypherpulse.base.eth
 * @notice This contract helps manage configurations for different networks
 * @dev Handles deployment parameters for local, testnet, and mainnet environments
 */

contract HelperConfig is Script{
    //Errors//
    error HelperConfig__InvalidChainId();

    //Type Declarations
    struct NetworkConfig{
        address deployer; //Address that deploys contracts
        uint256 deployerKey; // Private key for deployment
        bool isTestnet; // True if testnet, false if mainnet
        string networkName; // Human readable network name
        string rpcUrl; // RPC endpoint
        uint256 chainId; // Network chain Id
        address verifyContract; // Contract verification API endpoint
    }

    // STATE VARIABLES //
    uint256 public constant ETH_MAINNET_HAIN_ID =1
    uint256 public constant ETH_SEPOLA_CHAIN_ID =11155111;
    uint256 public constant BASE_MAINNET_CHAIN_ID =8453;
    uint256 public constant BASE_SEPOLIA_CHAIN_ID =84531;
    uint256 public constant LOCALHOST_CHAIN_ID =31337;

    // Default localconfiguration
    uint256 public constant Default_ANVIL_PRIVATE_KEY =0xA11CE;
    
}