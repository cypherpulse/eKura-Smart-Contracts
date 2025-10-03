// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {VoteStorage} from "../../src/VoteStorage.sol";
import {ElectionFactory} from "../../src/ElectionFactory.sol";
import {DeployElectionFactory} from "../../script/DeployElectionFactory.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/***
 * @title VoteStorageTest
 * @author cypherpulse.base.eth
 * @notice Unit tests for the VoteStorage contract
 * @dev Testing upgradeable contract with proxy pattern
 */

contract VoteStorageTest is Test {
    // EVENTS //

    event VoteCast(
        address indexed voter,
        uint256 indexed electionId,
        uint256 indexed candidateId,
        bytes32 voteHash,
        uint256 timestamp,
        bool isMetaTransaction
    );

    event VoteCountUpdated(
        uint256 indexed electionId,
        uint256 indexed candidateId,
        uint256 newCount
    );

    event MetaTransactionExecuted(
        address indexed voter,
        address indexed relayer,
        uint256 indexed electionId,
        uint256 nonce
    );

    // STATE VARIABLES//
    VoteStorage public voteStorage;
    ElectionFactory public electionFactory;
    HelperConfig public helperConfig;
    HelperConfig.NetworkConfig public networkConfig;

    //Test addresses
    address public platformAdmin;
    address public orgAdmin1;
    address public voter1;
    address public voter2;
    address public relayer;

    //Test constants
    uint256 public constant ORG_ID=1;
    uint256 public electionId;
    string public constant ELECTION_NAME ="Test Election";
    string public constant ELECTION_DESCRIPTION = "Test Description";

    //EIP-712 Domain
    bytes32 public DOMAIN_SEPARATOR;

    //SETUP//

    function setUp() external{
        //Deploy ElectionFactory first
        DeployElectionFactory deployer  = new DeployElectionFactory();
        (electionFactory,helperConfig)=deployer.run();
        networkConfig = helperConfig.getActiveNetworkConfig();

        // Set Up test addresses
        platformAdmin = networkConfig.deployer;
        orgAdmin1 = makeAddr("orgAdmin1");
        voter1 = makeAddr("voter1");
        voter2 = makeAddr("voter2");
        relayer = makeAddr("relayer");

        // Deploy VoteStorage with proxy
        _deployVoteStorageWithProxy();

        //set up an org admin
        vm.prank(platformAdmin);
        electionFactory.addOrgAdmin(ORG_ID, orgAdmin1);

        _createTestElection();

        console.log("VoteStorage deployed at:",address(voteStorage));
        console.log("ElectionFactory at:",address(electionFactory));
    }

    function _deployVoteStorageWithProxy() internal {
        vm.startBroadcast(networkConfig.deployerKey);

        //Deploy implementation
        VoteStorage implementation = new VoteStorage();

        // Encode initializer
        bytes memory initData = abi.encodeCall(
            VoteStorage.initialize,
            (address(electionFactory))
        );

        // Deploy proxy
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implementation),
            initData
        );

        vm.stopBroadcast();

        //Warp proxy interface to VoteStorage
        voteStorage = VoteStorage(address(proxy));

        // Set up EIP-712 Domain Separator
        DOMAIN_SEPARATOR = voteStorage.DOMAIN_SEPARTOR();
    }

    // createTestElection Function //
    function _createTestElection() internal {
        uint256 startTime = block.timestamp + 1 hours;
        uint256 endTime = startTime + 7 days;
        string[] memory candidates = new string[](3);
        candidates[0]="Alice Smith";
        candidates[1]="Bob Johnson";
        candidates[2]="Carol";

        vm.prank(orgAdmin1);
        electionId = electionFactory.createElection(
            ORG_ID,
            ELECTION_NAME,
            ELECTION_DESCRIPTION,
            startTime,
            endTime,
            candidates
        );

        // Fast forward to election start
        vm.warp(startTime + 1);
    }

    // DEPLOYMENT TESTS //

    function test_DeploymentSuccess() public view{
        assertTrue(address(voteStorage).code.length >0);
        assertEq(voteStorage.getElectionFactory(),address(electionFactory));
        assertEq(voteStorage.owner(),platformAdmin);
    }

    //VOTING TESTS

    function test_Vote_Success() public {
        uint256 candidateId = 0; // voting for Alice

        vm.prank(voter1);

        // Expect events
        vm.expectEmit(true, true, true, false);
    }
}