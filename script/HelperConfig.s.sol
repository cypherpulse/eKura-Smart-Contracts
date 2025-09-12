
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
        address deloyer; //Address that deploys contracts
        uint256 deployerKey // Private ke for deployment
    }
}