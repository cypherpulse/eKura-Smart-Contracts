// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {ElectionFactory} from "../../src/ElectionFactory.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {DeployElectionFactory} from "../../script/DeployElectionFactory.s.sol";

contract ElectionFactoryTest is Test{
    //EVENTS//

    event ElectionCreated(
        uint256 indexed orgId,
        uint256 indexed electionId,
        string indexed electionName,
        address creator,
        uint256  startTime,
        uint256 endTime
    );

    event orgAdminAdded(
        uint256 indexed orgId,
        address indexed admin,
        address indexed addedBy
    );

    //STATE VARIABLES//

    ElectionFactory public electionFactory;
    HelperConfig public helperConfig;
    HelperConfig.NetworkConfig public networkConfig;

    //Test addresses
    address public platformAdmin;
    address public orgAdmin1;
    address public orgAdmin2;
    address public user1;
    address public user2;

    //Test Constants
    uint256 public constant ORG_ID = 1;
    uint256 public constant ORG_ID = 2;
    string public constant ELECTION_NAME = "Student Council Elections 2025";
    string public constant ELECTION_DESCRIPTION = "Vote for your student representatives";

    // SETUP //

    function setUp() external{
        //Deploy contracts using our deployment script 
        DeployElectionFactory deployer = new DeployElectionFactory();
        (electionFactory,helperConfig)=deployer.run();
        networkConfig = helperConfig.getActiveNetworkConfig();

        //Set up test addresses//
        platformAdmin = networkConfig.deployer;
        orgAdmin1 = makeAddr("orgAdmin1");
        orgAdmin2 = makeAddr("orgAdmin2"); 
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");

        
    }

}