// SPDX-License-Identifer: MIT

pragma solidity ^0.8.20;

import {Script,console} from "forge-std/Script.sol";
/***
 * @title HelperConfig
 * @author cypherpulse.base.eth
 * @notice This contract helps manage configurations for different networks
 * @dev Handles deployment parameters for local, testnet, and mainnet environments
 */

contract HelperConfig is Script {
    //Errors//
    error HelperConfig__InvalidChainId();

    //Type Declarations
    struct NetworkConfig {
        address deployer; //Address that deploys contracts
        uint256 deployerKey; // Private key for deployment
        bool isTestnet; // True if testnet, false if mainnet
        string networkName; // Human readable network name
        string rpcUrl; // RPC endpoint
        uint256 chainId; // Network chain Id
        address verifyContract; // Contract verification API endpoint
    }

    // STATE VARIABLES //
    uint256 public constant ETH_MAINNET_CHAIN_ID = 1;
    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant BASE_MAINNET_CHAIN_ID = 8453;
    uint256 public constant BASE_SEPOLIA_CHAIN_ID = 84531;
    uint256 public constant LOCALHOST_CHAIN_ID = 31337;

    // Default localconfiguration
    uint256 public constant DEFAULT_ANVIL_PRIVATE_KEY = 0xA11CE;

    NetworkConfig public s_activeNetworkConfig;

    // Update your HelperConfig constructor (around line 44)
    constructor() {
        // Check the actual RPC URL chain ID, not just block.chainid
        uint256 currentChainId = block.chainid;

        // When running scripts, we need to check the target chain, not the current one
        // This is a workaround for Forge script behavior
        if (currentChainId == ETH_SEPOLIA_CHAIN_ID) {
            s_activeNetworkConfig = getEthSepoliaConfig();
        } else if (currentChainId == BASE_SEPOLIA_CHAIN_ID) {
            s_activeNetworkConfig = getBaseSepoliaConfig();
        } else if (currentChainId == BASE_MAINNET_CHAIN_ID) {
            s_activeNetworkConfig = getBaseMainnetConfig();
        } else if (currentChainId == ETH_MAINNET_CHAIN_ID) {
            s_activeNetworkConfig = getEthMainnetConfig();
        } else {
            // For scripts targeting remote networks, detect from environment
            try vm.envString("BASE_SEPOLIA_RPC_URL") returns (
                string memory rpcUrl
            ) {
                if (bytes(rpcUrl).length > 0) {
                    s_activeNetworkConfig = getBaseSepoliaConfig();
                    return;
                }
            } catch {}

            // Default to Anvil
            s_activeNetworkConfig = getOrCreateAnvilConfig();
        }
    }

    /***
     * @notice Gets Ethereum Sepolia testnet configuration
     * @return NetworkConfig for Ethereum Sepolia
     * @dev Good for initial testing before moving to BaseL2
     */

    function getEthSepoliaConfig() public view returns (NetworkConfig memory) {
        return
            NetworkConfig({
                deployer: vm.envAddress("DEPLOYER_ADDRESS"),
                deployerKey: vm.envUint("PRIVATE_KEY"),
                isTestnet: true,
                networkName: "Ethereum Sepolia",
                rpcUrl: vm.envString("ETH_SEPOLIA_RPC_URL"),
                chainId: ETH_SEPOLIA_CHAIN_ID,
                verifyContract: address(0)
            });
    }

    /***
     * @notice Gets Base Sepolia testnet configuration
     * @return NetworkConfig forBase Sepolia
     * @dev Good for testing BaseL2 deployments
     */

    function getBaseSepoliaConfig() public view returns (NetworkConfig memory) {
        return
            NetworkConfig({
                deployer: vm.envAddress("DEPLOYER_ADDRESS"),
                deployerKey: vm.envUint("PRIVATE_KEY"),
                isTestnet: true,
                networkName: "Base Sepolia",
                rpcUrl: vm.envString("BASE_SEPOLIA_RPC_URL"),
                chainId: BASE_SEPOLIA_CHAIN_ID,
                verifyContract: address(0)
            });
    }

    // Add this function to HelperConfig.s.sol
    function getBaseSepoliaConfigForced()
        public
        view
        returns (NetworkConfig memory)
    {
        console.log("FORCING Base Sepolia configuration...");
        return
            NetworkConfig({
                deployer: vm.envAddress("DEPLOYER_ADDRESS"),
                deployerKey: vm.envUint("PRIVATE_KEY"),
                isTestnet: true,
                networkName: "Base Sepolia",
                rpcUrl: vm.envString("BASE_SEPOLIA_RPC_URL"),
                chainId: BASE_SEPOLIA_CHAIN_ID,
                verifyContract: address(0)
            });
    }

    /***
     * @notice Gets Base Mainnet configuration
     * @return NetworkConfig for Base Mainnet
     * @dev For production deployments on BaseL2
     */

    function getBaseMainnetConfig() public view returns (NetworkConfig memory) {
        return
            NetworkConfig({
                deployer: vm.envAddress("DEPLOYER_ADDRESS"),
                deployerKey: vm.envUint("PRIVATE_KEY"),
                isTestnet: false,
                networkName: "Base Mainnet",
                rpcUrl: vm.envString("BASE_MAINNET_RPC_URL"),
                chainId: ETH_MAINNET_CHAIN_ID,
                verifyContract: address(0)
            });
    }

    function getEthMainnetConfig() public view returns (NetworkConfig memory) {
        return
            NetworkConfig({
                deployer: vm.envAddress("DEPLOYER_ADDRESS"),
                deployerKey: vm.envUint("PRIVATE_KEY"),
                isTestnet: false,
                networkName: "Ethereum Mainnet",
                rpcUrl: vm.envString("ETH_MAINNET_RPC_URL"),
                chainId: ETH_MAINNET_CHAIN_ID,
                verifyContract: address(0)
            });
    }

    /***
     * @notice Gets or creates local Anvil configuration
     * @return NetworkConfig for local Anvil for local testing
     * @dev Used for unit tests and local development
     */

    function getOrCreateAnvilConfig()
        public
        pure
        returns (NetworkConfig memory)
    {
        return
            NetworkConfig({
                deployer: vm.addr(DEFAULT_ANVIL_PRIVATE_KEY),
                deployerKey: DEFAULT_ANVIL_PRIVATE_KEY,
                isTestnet: true,
                networkName: "Local Anvil",
                rpcUrl: "http://127.0.0.1:8545",
                chainId: LOCALHOST_CHAIN_ID,
                verifyContract: address(0)
            });
    }

    /***
     * @notice Gets the active network configuration
     * @return Currently active NetworkConfig
     */

    function getActiveNetworkConfig()
        external
        view
        returns (NetworkConfig memory)
    {
        return s_activeNetworkConfig;
    }

    /***
     * @notice Checks if current network is a testnet
     * @return True if testnet, false if mainnet
     */

    function isTestnet() external view returns (bool) {
        return s_activeNetworkConfig.isTestnet;
    }

    /***
     * @notice Gets current network name
     * @return Human readable network name
     */

    function getNetwokName() external view returns (string memory) {
        return s_activeNetworkConfig.networkName;
    }
}
