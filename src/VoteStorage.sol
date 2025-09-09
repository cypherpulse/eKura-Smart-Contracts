//SPDX-License-Identifier: MIT

// Layout of the contract file:
// version
// imports
// errors
// interfaces, libraries, contract

// Inside Contract:
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./ElectionFactory.sol";

/***
 * @title VoteStorage
 * @author cypherpulse.base.eth
 * @notice This contract handles the vote storage and counting for all elections created via the ElectionFactory.
 * @dev Supports both direct voting and meta-transactions, integrates with ElectionFactory for election management.
 */
contract VoteStorage is
    Initializable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    EIP712
{
    // Errors //

    error VoteStorage__ElectionNotActive();
    error VoteStorage__AlreadyVoted();
    error VoteStorage__InvalidCandidate();
    error VoteStorage__InvalidSignature();
    error VoteStorage__SignatureExpired();
    error VoteStorage__InvalidNonce();
    error VoteStorage__ElectionFactoryNotSet();


    // Type Declarations //
    /***
     * @notice Struct to for meta-transaction vote data.
     * @param voter Address of the voter
     * @param electionId Election Identifier
     * @param candidateId Candidate/position/project identifier
     * @param nonce Unique number to prevent reply attacks
     * @param deadline Unix timestamp after which signature expires
     */

    struct VoteData{
        address voter;
        uint256 electionId;
        uint256 candidateId;
        uint256 nonce;
        uint256 deadline;
    }

    // State Variables //
    /***
     * @dev Reference to the ElectionFactory contract for election validation.
     */
    ElectionFactory private electionFactory;

    /***
     * @dev EIP712 typehash for voteData struct.
     */
    bytes32 private constant VOTE_TYPEHASH = 
        keccak256()
}
