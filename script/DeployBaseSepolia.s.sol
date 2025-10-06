// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {ElectionFactory} from "../src/ElectionFactory.sol";
import {VoteStorage} from "../src/VoteStorage.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployBaseSepolia is Script {
    function run() external {
        // Hardcode Base Sepolia config
        address deployer = vm.envAddress("DEPLOYER_ADDRESS");
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        
        console.log("Deploying to Base Sepolia");
        console.log("Deployer:", deployer);
        console.log("Chain ID: 84532");
        
        vm.startBroadcast(deployerKey);
        
        // Deploy ElectionFactory
        ElectionFactory electionFactory = new ElectionFactory();
        console.log("ElectionFactory:", address(electionFactory));
        
        // Deploy VoteStorage
        VoteStorage implementation = new VoteStorage();
        bytes memory initData = abi.encodeCall(VoteStorage.initialize, (address(electionFactory)));
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        
        console.log("VoteStorage Proxy:", address(proxy));
        console.log("VoteStorage Implementation:", address(implementation));
        
        vm.stopBroadcast();
    }
}