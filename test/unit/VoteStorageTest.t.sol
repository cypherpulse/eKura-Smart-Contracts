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
        emit VoteCast(
            voter1,
            electionId,
            candidateId,
            bytes32(0),
            block.timestamp,
            false
        );

        voteStorage.vote(electionId, candidateId);

        // Verify vote was recorded
        assertTrue(voteStorage.hasVoted(electionId, voter1));
        assertEq(voteStorage.getVoteCount(electionId, candidateId),1);
    }

    function test_Vote_RevertWhen_AlreadyVoted() public {
        uint256 candidateId = 0;

        // First Vote
        vm.prank(voter1);
        voteStorage.vote(electionId, candidateId);

        // Attempt on second vote should fail
        vm.prank(voter1);
        vm.expectRevert(VoteStorage.VoteStorage__AlreadyVoted.selector);
        voteStorage.vote(electionId, candidateId);
    }

    function test_Vote_RevertWhen_InvalidCandidate() public{
        uint256 invalidCandidateId = 89; //candidate id doesnt exist

        vm.prank(voter1);
        vm.expectRevert(VoteStorage.VoteStorage__InvalidCandidate.selector);
        voteStorage.vote(electionId, invalidCandidateId);
    }

    function test_Vote_RevertWhen_ElectionNotActive() public {
        //Warp to after election end
        ElectionFactory.Election memory election = electionFactory.getElection(electionId);
        vm.warp(election.endTime + 1);

        vm.prank(voter1);
        vm.expectRevert(VoteStorage.VoteStorage__ElectionNotActive.selector);
        voteStorage.vote(electionId, 0);
    }

    function test_Vote_RevertWhen_Paused() public {
        // Pause Contract
        vm.prank(platformAdmin);
        voteStorage.pause();

        vm.prank(voter1);
        vm.expectRevert("Pausable: Paused");
        voteStorage.vote(electionId, 0);
    } 

    // Meta Transaction Tests //

    function test_VoteWithSignature_Success() public{
        uint256 candidateId = 1; // voting for Bob
        uint256 nonce = voteStorage.getNonce(voter1);
        uint256 deadline = block.timestamp + 1 hours;

        //create Vote Data//
        VoteStorage.VoteData memory voteData = VoteStorage.VoteData({
            voter: voter1,
            electionId: electionId,
            candidateId: candidateId,
            nonce: nonce,
            deadline: deadline
        });

        //Sign the data
        bytes memory signature = _signVoteData(voteData, voter1);

        vm.prank(relayer);

        //Expect Events
        vm.expectEmit(true, true, true, true);
        emit MetaTransactionExecuted(voter1, relayer, electionId, nonce);

        voteStorage.voteWithSignature(voteData, signature);

        //Verify vote was recorded //
        assertTrue(voteStorage.hasVoted(electionId, voter1));
        assertEq(voteStorage.getVoteCount(electionId, candidateId), 1);
        assertEq(voteStorage.getNonce(voter1), nonce + 1);
    }

    function test_VoteWithSignature_RevertWhen_ExpiredSignature() public{
        uint256 candidateId = 0;
        uint256 nonce = voteStorage.getNonce(voter1);
        uint256 deadline = block.timestamp - 1; // Expired

        VoteStorage.VoteData memory voteData = VoteStorage.VoteData({
            voter: voter1,
            electionId: electionId,
            candidateId: candidateId,
            nonce: nonce,
            deadline: deadline
        });

        bytes memory signature = _signVoteData(voteData, voter1);

        vm.prank(relayer);
        vm.expectRevert(VoteStorage.VoteStorage__SignatureExpired.selector);
        voteStorage.voteWithSignature(voteData, signature);
    }

    function test_VoteWithSignature_RevertWhen_InvalidNonce() public{
        uint256 candidateId = 0;
        uint256 wrongNonce = 897; //Wrong nonce
        uint256 deadline = block.timestamp + 1 hours;

       VoteStorage.VoteData memory voteData = VoteStorage.VoteData({
        voter: voter1,
        electionId: electionId,
        candidateId: candidateId,
        nonce: wrongNonce,
        deadline: deadline
       });

       bytes memory signature = _signVoteData(voteData, voter1);

       vm.prank(relayer);
       vm.expectRevert(VoteStorage.VoteStorage__InvalidNonce.selector);
       voteStorage.voteWithSignature(voteData, signature);
    }

    //VIEW FUNCTIONS//
    function test_GetAllVoteCounts() public{
        // Cast votes for different candidates
        vm.prank(voter1);
        voteStorage.vote(electionId, 0); //Alice

        vm.prank(voter2);
        voteStorage.vote(electionId, 1); //Bob

        uint256[] memory counts = voteStorage.getAllVoteCounts(electionId);

        assertEq(counts.length, 3); //3 candidates
        assertEq(counts[0], 1); //Alice: 1 Vote
        assertEq(counts[1], 1); //Bob: 1 vote
        assertEq(counts[2], 0); //Carol: 0 votes
    }

    function test_VerifyVoteHash() public {
        uint256 candidateId = 0;

        vm.prank(voter1);
        voteStorage.vote(electionId, candidateId);

        //Verify the vote hash
        assertTrue(voteStorage.verifyVoteHash(electionId, voter1, candidateId));

        // Verify fails with wrong candidate
        assertFalse(voteStorage.verifyVoteHash(electionId, voter1, 1));
    }

    // ADMIN FUNCTION TESTS //

    function test_SetElectionFactory() public {
        address newFactory = makeAddr("newFactory");

        vm.prank(platformAdmin);
        voteStorage.setElectionFactory(newFactory);

        assertEq(voteStorage.getElectionFactory(), newFactory);
    }

    function test_SetElectionFactory_RevertWhen_NotOwner() public{
        address newFactory = makeAddr("newFactory");

        
    }
}