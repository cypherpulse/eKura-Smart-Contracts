// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


import {Test, console} from "forge-std/Test.sol";
import {VoteStorage} from "../../src/VoteStorage.sol";
import {ElectionFactory} from "../../src/ElectionFactory.sol";
import {DeployElectionFactory} from "../../script/DeployElectionFactory.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/**
 * @title InteractionTest
 * @author eKura Team
 * @notice Integration tests for ElectionFactory + VoteStorage interaction
 * @dev Tests the complete user journey from election creation to voting
 */
contract InteractionTest is Test {
    
    ////////////////////////////////////////////////////////////////////////////
    ////                         STATE VARIABLES                           ////
    ////////////////////////////////////////////////////////////////////////////
    
    VoteStorage public voteStorage;
    ElectionFactory public electionFactory;
    HelperConfig public helperConfig;
    HelperConfig.NetworkConfig public networkConfig;
    
    // Test users
    address public platformAdmin;
    address public orgAdmin1;
    address public orgAdmin2;
    address public voter1;
    address public voter2;
    address public voter3;
    address public relayer;
    
    // Test data
    uint256 public constant ORG_ID_1 = 1;
    uint256 public constant ORG_ID_2 = 2;
    uint256 public electionId1;
    uint256 public electionId2;
    
    ////////////////////////////////////////////////////////////////////////////
    ////                            SETUP                                   ////
    ////////////////////////////////////////////////////////////////////////////
    
    function setUp() external {
        // Deploy contracts
        _deployContracts();
        
        // Set up test addresses
        _setupAddresses();
        
        // Set up organizations and elections
        _setupOrganizations();
        _setupElections();
        
        console.log("=== INTEGRATION TEST SETUP COMPLETE ===");
        console.log("ElectionFactory:", address(electionFactory));
        console.log("VoteStorage:", address(voteStorage));
        console.log("Election 1 ID:", electionId1);
        console.log("Election 2 ID:", electionId2);
    }
    
    function _deployContracts() internal {
        // Deploy ElectionFactory
        DeployElectionFactory deployer = new DeployElectionFactory();
        (electionFactory, helperConfig) = deployer.run();
        networkConfig = helperConfig.getActiveNetworkConfig();
        
        // Deploy VoteStorage with proxy
        vm.startBroadcast(networkConfig.deployerKey);
        
        VoteStorage implementation = new VoteStorage();
        bytes memory initData = abi.encodeCall(
            VoteStorage.initialize,
            (address(electionFactory))
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        
        vm.stopBroadcast();
        
        voteStorage = VoteStorage(address(proxy));
    }
    
    function _setupAddresses() internal {
        platformAdmin = networkConfig.deployer;
        orgAdmin1 = makeAddr("orgAdmin1");
        orgAdmin2 = makeAddr("orgAdmin2");
        voter1 = makeAddr("voter1");
        voter2 = makeAddr("voter2");
        voter3 = makeAddr("voter3");
        relayer = makeAddr("relayer");
    }
    
    function _setupOrganizations() internal {
        vm.startPrank(platformAdmin);
        
        // Set up Org 1 (University)
        electionFactory.addOrgAdmin(ORG_ID_1, orgAdmin1);
        
        // Set up Org 2 (Student Council)
        electionFactory.addOrgAdmin(ORG_ID_2, orgAdmin2);
        
        vm.stopPrank();
    }
    
    function _setupElections() internal {
        uint256 startTime = block.timestamp + 1 hours;
        uint256 endTime = startTime + 7 days;
        
        // Election 1: University President Election
        string[] memory candidates1 = new string[](3);
        candidates1[0] = "Alice Johnson - Policy Reform";
        candidates1[1] = "Bob Smith - Student Welfare";
        candidates1[2] = "Carol Davis - Academic Excellence";
        
        vm.prank(orgAdmin1);
        electionId1 = electionFactory.createElection(
            ORG_ID_1,
            "University President Election 2025",
            "Choose the next university president",
            startTime,
            endTime,
            candidates1
        );
        
        // Election 2: Student Council Representative
        string[] memory candidates2 = new string[](2);
        candidates2[0] = "David Wilson - Sports & Recreation";
        candidates2[1] = "Emma Brown - Student Services";
        
        vm.prank(orgAdmin2);
        electionId2 = electionFactory.createElection(
            ORG_ID_2,
            "Student Council Representative",
            "Choose your student council representative",
            startTime,
            endTime,
            candidates2
        );
        
        // Fast forward to election start
        vm.warp(startTime + 1);
    }
    
    ////////////////////////////////////////////////////////////////////////////
    ////                    END-TO-END JOURNEY TESTS                       ////
    ////////////////////////////////////////////////////////////////////////////
    
    function test_CompleteVotingJourney_DirectVoting() public {
        console.log("\n=== TESTING COMPLETE DIRECT VOTING JOURNEY ===");
        
        // 1. Verify elections are active
        assertTrue(electionFactory.isElectionActive(electionId1));
        assertTrue(electionFactory.isElectionActive(electionId2));
        
        // 2. Initial vote counts should be zero
        assertEq(voteStorage.getVoteCount(electionId1, 0), 0); // Alice
        assertEq(voteStorage.getVoteCount(electionId1, 1), 0); // Bob
        assertEq(voteStorage.getVoteCount(electionId1, 2), 0); // Carol
        
        // 3. Voters cast their votes
        vm.prank(voter1);
        voteStorage.vote(electionId1, 0); // voter1 votes for Alice
        
        vm.prank(voter2);
        voteStorage.vote(electionId1, 1); // voter2 votes for Bob
        
        vm.prank(voter3);
        voteStorage.vote(electionId1, 0); // voter3 votes for Alice
        
        // 4. Verify vote counts
        assertEq(voteStorage.getVoteCount(electionId1, 0), 2); // Alice: 2 votes
        assertEq(voteStorage.getVoteCount(electionId1, 1), 1); // Bob: 1 vote
        assertEq(voteStorage.getVoteCount(electionId1, 2), 0); // Carol: 0 votes
        
        // 5. Verify voters are marked as having voted
        assertTrue(voteStorage.hasVoted(electionId1, voter1));
        assertTrue(voteStorage.hasVoted(electionId1, voter2));
        assertTrue(voteStorage.hasVoted(electionId1, voter3));
        
        // 6. Verify vote hashes were created
        assertTrue(voteStorage.getVoteHash(electionId1, voter1) != bytes32(0));
        assertTrue(voteStorage.getVoteHash(electionId1, voter2) != bytes32(0));
        assertTrue(voteStorage.getVoteHash(electionId1, voter3) != bytes32(0));
        
        console.log("Direct voting journey completed successfully!");
    }
    
    function test_CompleteVotingJourney_MetaTransactions() public {
        console.log("\n=== TESTING META-TRANSACTION VOTING JOURNEY ===");
        
        // 1. Create vote data for gasless voting
        uint256 candidateId = 1; // Bob Smith
        uint256 nonce = voteStorage.getNonce(voter1);
        uint256 deadline = block.timestamp + 1 hours;
        
        VoteStorage.VoteData memory voteData = VoteStorage.VoteData({
            voter: voter1,
            electionId: electionId1,
            candidateId: candidateId,
            nonce: nonce,
            deadline: deadline
        });
        
        // 2. Sign the vote data (simulating off-chain signing)
        bytes memory signature = _signVoteData(voteData, voter1);
        
        // 3. Relayer submits the meta-transaction
        vm.prank(relayer);
        voteStorage.voteWithSignature(voteData, signature);
        
        // 4. Verify the vote was recorded correctly
        assertTrue(voteStorage.hasVoted(electionId1, voter1));
        assertEq(voteStorage.getVoteCount(electionId1, candidateId), 1);
        assertEq(voteStorage.getNonce(voter1), nonce + 1);
        
        console.log("Meta-transaction voting journey completed successfully!");
    }
    
    function test_MultipleElections_SameVoter() public {
        console.log("\n=== TESTING MULTIPLE ELECTIONS FOR SAME VOTER ===");
        
        // Voter can vote in multiple elections
        vm.startPrank(voter1);
        
        // Vote in Election 1 (University President)
        voteStorage.vote(electionId1, 0); // Alice
        
        // Vote in Election 2 (Student Council)
        voteStorage.vote(electionId2, 1); // Emma
        
        vm.stopPrank();
        
        // Verify both votes were recorded
        assertTrue(voteStorage.hasVoted(electionId1, voter1));
        assertTrue(voteStorage.hasVoted(electionId2, voter1));
        
        assertEq(voteStorage.getVoteCount(electionId1, 0), 1);
        assertEq(voteStorage.getVoteCount(electionId2, 1), 1);
        
        console.log("Multiple elections voting completed successfully!");
    }
    
    function test_ElectionResults_RealTimeUpdates() public {
        console.log("\n=== TESTING REAL-TIME ELECTION RESULTS ===");
        
        // Cast multiple votes and check real-time results
        vm.prank(voter1);
        voteStorage.vote(electionId1, 0); // Alice
        
        uint256[] memory counts1 = voteStorage.getAllVoteCounts(electionId1);
        assertEq(counts1[0], 1); // Alice: 1
        assertEq(counts1[1], 0); // Bob: 0
        assertEq(counts1[2], 0); // Carol: 0
        
        vm.prank(voter2);
        voteStorage.vote(electionId1, 0); // Alice
        
        uint256[] memory counts2 = voteStorage.getAllVoteCounts(electionId1);
        assertEq(counts2[0], 2); // Alice: 2
        assertEq(counts2[1], 0); // Bob: 0
        assertEq(counts2[2], 0); // Carol: 0
        
        vm.prank(voter3);
        voteStorage.vote(electionId1, 1); // Bob
        
        uint256[] memory counts3 = voteStorage.getAllVoteCounts(electionId1);
        assertEq(counts3[0], 2); // Alice: 2
        assertEq(counts3[1], 1); // Bob: 1
        assertEq(counts3[2], 0); // Carol: 0
        
        console.log("Real-time results tracking working correctly!");
    }
    
    ////////////////////////////////////////////////////////////////////////////
    ////                        SECURITY TESTS                             ////
    ////////////////////////////////////////////////////////////////////////////
    
    function test_CannotVoteInInactiveElection() public {
        // Create election that hasn't started yet
        uint256 futureStart = block.timestamp + 10 days;
        uint256 futureEnd = futureStart + 7 days;
        string[] memory candidates = new string[](1);
        candidates[0] = "Future Candidate";
        
        vm.prank(orgAdmin1);
        uint256 futureElectionId = electionFactory.createElection(
            ORG_ID_1,
            "Future Election",
            "Election in the future",
            futureStart,
            futureEnd,
            candidates
        );
        
        // Try to vote before election starts
        vm.prank(voter1);
        vm.expectRevert(VoteStorage.VoteStorage__ElectionNotActive.selector);
        voteStorage.vote(futureElectionId, 0);
    }
    
    function test_CannotDoubleVote() public {
        // First vote
        vm.prank(voter1);
        voteStorage.vote(electionId1, 0);
        
        // Second vote should fail
        vm.prank(voter1);
        vm.expectRevert(VoteStorage.VoteStorage__AlreadyVoted.selector);
        voteStorage.vote(electionId1, 1);
    }
    
    ////////////////////////////////////////////////////////////////////////////
    ////                       HELPER FUNCTIONS                            ////
    ////////////////////////////////////////////////////////////////////////////
    
    function _signVoteData(VoteStorage.VoteData memory voteData, address signer) 
        internal 
        view 
        returns (bytes memory) 
    {
        bytes32 domainSeparator = voteStorage.getDomainSeparator();
        
        bytes32 structHash = keccak256(abi.encode(
            keccak256("VoteData(address voter,uint256 electionId,uint256 candidateId,uint256 nonce,uint256 deadline)"),
            voteData.voter,
            voteData.electionId,
            voteData.candidateId,
            voteData.nonce,
            voteData.deadline
        ));
        
        bytes32 hash = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        
        uint256 signerPrivateKey = uint256(keccak256(abi.encodePacked(signer)));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPrivateKey, hash);
        
        return abi.encodePacked(r, s, v);
    }
}