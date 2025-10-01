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

    event OrgAdminAdded(
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
    uint256 public constant ORG_ID_1 = 1;
    uint256 public constant ORG_ID_2 = 2;
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

        console.log("ElectionFactory deployed at :",address(electionFactory));
        console.log("Platform Admin:",platformAdmin);

    }

    //DEPLOYMENT TESTS //

    function test_DeploymentSuccess() public{
        //Test contract was deployed correctly
        assertTrue(address(electionFactory).code.length >0);
        assertEq(electionFactory.getPlatformAdmin(),platformAdmin);
        assertEq(electionFactory.getTotalElections(),0);
    }

    //ORG ADMIN TESTS //   

    function test_AddOrgAdmin_Success() public{
        //Arrange
        vm.prank(platformAdmin);
        //Act & Assert
        vm.expectEmit(true,true,true,false);
        emit OrgAdminAdded(ORG_ID_1,orgAdmin1,platformAdmin);

        electionFactory.addOrgAdmin(ORG_ID_1, orgAdmin1);

        // Verify
        assertTrue(electionFactory.isOrgAdmin(ORG_ID_1,orgAdmin1));
    }

    function test_AddOrgAdmin_RevertWhen_NotPlatformAdmin() public{
        //Arrange
        vm.prank(user1);

        //Act&Assert
        vm.expectRevert(ElectionFactory.ElectionFactory__NotPlatformAdmin.selector);
        electionFactory.addOrgAdmin(ORG_ID_1,orgAdmin1);
    }

    function test_AddOrgAdmin_RevertWhen_InvalidAddress() public{
        //Arrange
        vm.prank(platformAdmin);

        //Act & Assert
        vm.expectRevert(ElectionFactory.ElectionFactory__InvalidAdminAddress.selector);
        electionFactory.addOrgAdmin(ORG_ID_1,address(0));
    }

    function test_AddOrgAdmin_RevertWhen_AlreadyAdmin() public{
        //Arrange
        vm.startPrank(platformAdmin);
        electionFactory.addOrgAdmin(ORG_ID_1,orgAdmin1);

        //act & Assert
        vm.expectRevert(ElectionFactory.ElectionFactory__AlreadyAnAdmin.selector);
        electionFactory.addOrgAdmin(ORG_ID_1,orgAdmin1);

        vm.stopPrank();
    }

    function test_RemoveOrgAdmin_Success() public{
        //Arrange
        vm.startPrank(platformAdmin);
        electionFactory.addOrgAdmin(ORG_ID_1,orgAdmin1);

        //Act
        electionFactory.removeOrgAdmin(ORG_ID_1,orgAdmin1);

        //Assert
        assertFalse(electionFactory.isOrgAdmin(ORG_ID_1,orgAdmin1));

        vm.stopPrank();
    }

    // ELECTION CREATION TESTS //
    modifier withOrgAdmin() {
        vm.prank(platformAdmin);
        electionFactory.addOrgAdmin(ORG_ID_1, orgAdmin1);
        _;
    }

    function test_CreateElection_Success() public withOrgAdmin{
        //Arrange
        uint256 startTime = block.timestamp + 1 days;
    }

    

}