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
    HelperConfig.NetworkConfig public newtworkConfig;

    //Test addresses
    address public platfromAdmin;
    address public orgAdmin1;
    address public voter1;
    address public voter2;
    address public relayer;

    //Test constants
    uint256 public constant ORG_ID=1;
    uint256 public electionId;
    string public constant ELECTION_NAME ="Test Election";
    string public constant ELECTION_DESCRIPTION = "Test Description";
}