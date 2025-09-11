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
import "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol"; // Changed this line
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
    EIP712Upgradeable
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
    ElectionFactory private s_electionFactory;

    /***
     * @dev EIP712 typehash for voteData struct.
     */
    bytes32 private constant VOTE_TYPEHASH = 
        keccak256("VoteData(address voter,uint256 electionId,uint256 candidateId,uint256 nonce,uint256 deadline)");

    /***
     * @dev Mapping to store vote hashes : electionId => voterAddress => voteHash
     */
    mapping(uint256 => mapping(address => bytes32)) private s_voteHashes;

    /***
     * Mapping to track voting status: electionId => voterAddress => hasVoted
     */
    mapping(uint256 => mapping(address => bool)) private s_hasVoted;

    /***
     * @dev Mapping to track vote counts: electionId => candidateId => voteCount
     */
    mapping(uint256 => mapping(uint256 => uint256)) private s_voteCounts;

    /***
     * @dev Mapping to track nonces for meta-transactions: voterAddress => nonce
     */
    mapping(address => uint256) private s_nonces;

    /***
     * @dev Mapping to store vote timestamps: electionId => voterAddress => timestamp
     */
    mapping(uint256 => mapping(address => uint256)) private s_voteTimestamps;

    /***
     * @dev Mapping to store salts used for vote hashes: electionId => voterAddress => salt
     */

    mapping(uint256 => mapping(address => bytes32)) private s_voteSalts;

    // Events //

    /***
     * @notice Emitted when a vote is successfully cast
     * @param voter Address of the voter
     * @param electionId Election Identifier
     * @param candidateId Candidate/position/project voted for
     * @param voteHash Hash of the vote for verification
     * @param timestamp Unix timestamp when the vote was cast
     * @param isMetaTransaction True if vote was cast via meta-transaction
     */

    event VoteCast(
        address indexed voter,
        uint256 indexed electionId,
        uint256 indexed candidateId,
        bytes32 voteHash,
        uint256 timestamp,
        bool isMetaTransaction
    );

    /***
     * @notice Emitted when vote counts are updated
     * @param electionId Election Identifier
     * @param candidateId Candidate whose count changed
     * @param newCount Updated vote count
     */

    event VoteCountUpdated(
        uint256 indexed electionId,
        uint256 indexed candidateId,
        uint256 newCount
    );

    /***
     * @notice Emitted when the ElectionFactory address is set 
     * @param oldFactory Previous factory address
     * @param newFactory New factory address
     * @param changedBy Address that made the change
     */

    event ElectionFactoryUpdated(
        address indexed oldFactory,
        address indexed newFactory,
        address indexed changedBy
    );

    /***
     * @notice Emitted when a meta-transaction vote is processed
     * @param voter Address of the voter
     * @param relayer Address that submitted the meta-transaction
     * @param electionId Election Identifier
     * @param nonce Nonce used in the meta-transaction
     */

    event MetaTransactionExecuted(
        address indexed voter,
        address indexed relayer,
        uint256 indexed electionId,
        uint256 nonce
    );

    //MODIFIERS//

    /***
     * @notice Ensures the election exists and is currently active.
     * @param electionId The election to validate
     * @dev Checks with ElectionFactory for election status and timing
     */

    modifier onlyActiveElection(uint256 electionId){
        if(address(s_electionFactory)==address(0)){
            revert VoteStorage__ElectionFactoryNotSet();
        }
        if(!s_electionFactory.isElectionActive(electionId)){
            revert VoteStorage__ElectionNotActive();
        }
        _;
    }

    /***
     * @notice Ensures the voter hasn't already voted in this election
     * @param electionId The election to check
     * @param voter The voter address to validate
     */

    modifier notAlreadyVoted(uint256 electionId, address voter){
        if(s_hasVoted[electionId][voter]){
            revert VoteStorage__AlreadyVoted();
        }
        _;
    }

    /***
     * @notice Validates that the candidate exists for the given election
     * @param electionId The election identifier
     * @param candidateId The candidate to validate (index in candidates array)
     */

    modifier validCandidate(uint256 electionId, uint256 candidateId){
        ElectionFactory.Election memory election = s_electionFactory.getElection(electionId);
        if(candidateId >= election.candidates.length){
            revert VoteStorage__InvalidCandidate();
        }
        _;
    }

    /***
     * @notice Validates meta-transaction signature and timing
     * @param voteData The vote data struct containing signature details
     * @param signature The EIP-712 Signature
     */

    modifier validSignature(VoteData calldata voteData, bytes calldata signature){
        if(block.timestamp > voteData.deadline){
            revert VoteStorage__SignatureExpired();
        }
        if(voteData.nonce != s_nonces[voteData.voter]){
            revert VoteStorage__InvalidNonce();
        }
        bytes32 structHash = keccak256(abi.encode(
            VOTE_TYPEHASH,
            voteData.voter,
            voteData.electionId,
            voteData.candidateId,
            voteData.nonce,
            voteData.deadline
        ));

        bytes32 hash = _hashTypedDataV4(structHash);
        address signer = ECDSA.recover(hash, signature);

        if (signer != voteData.voter){
            revert VoteStorage__InvalidSignature();
        }
        _;
        
    }

    // Functions //
    /***
     * @notice Initializes the upgradable contract
     * @param electionFactory Address of the ElectionFactory contract
     * @dev Replaces constructor for upgradable contracts
     */

    function initialize(address electionFactory) external initializer{
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        __EIP712_init("VoteStorage","1"); // Initialize EIP712 with name and version

        s_electionFactory = ElectionFactory(electionFactory);
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(){
        _disableInitializers();
    }

    /// EXternal Functions ///
    

    /***
     * @notice Direct voting function for web3 users with connected wallets
     * @param electionId The election to vote in
     * @param candidateId The candidate/position/project to vote for
     * @dev Requires active election,valid candidate, and no previous vote
     */

    function vote(uint256 electionId,uint256 candidateId) external whenNotPaused nonReentrant onlyActiveElection(electionId) onlyActiveElection(electionId) notAlreadyVoted(electionId,msg.sender) validCandidate(electionId, candidateId){
        _processVote(msg.sender,electionId, candidateId, false);
    }

    /***
     * @notice Meta-transaction voting for gasless voting (web2 and web3 users)
     * @param voteData Struct containing vote details and signature parameters
     * @param signatures EIP-712 Signature from the voter
     * @dev Enables gasless voting via relayers, requires valid signature
     */

    function voteWithSignature(
        VoteData calldata voteData,
        bytes calldate signatures
    )
      external
      whenNotPaused
      nonReentrant
      onlyActiveElection(voteData.electionId)
      notAlreadyVoted(voteData.electionId,  voteData.voter)
      validCandidate(voteData.electionId, voteData.candidateId)
      validSignature(voteData, signature)
    {
        //Increment nonce to prevent reply attacks
        s_nonces[voteData.voter]++;

        // Emit meta-transaction execution event
        emit MetaTransactionExecuted(
            voteData.voter,
            msg.sender,//relayer address 
            voteData.electionId,
            voteData.nonce
        );
        //process the vote
        _processVote(voteData.voter, voteData.electionId, voteData.candidateId, true);
    }

    /***
     * @notice Updates the ElectionFactory contract address(emergency function)
     * @param newElectionFactory Address of the new ElectionFactory contract
     * @dev Only owner can update, emits event for transparency
     */

    function setElectionFactory(address newElectionFactory) external onlyOwner{
        require(newElectionFactory != address(0),"Invalid factory address");

        address oldFactory = address(s_electionFactory);
        s_electionFactory = ElectionFactory(newElectionFactory)

        emit ElectionFactoryUpdated(oldFactory, newElectionFactory, msg.sender);
    }

    /***
     * @notice Emergency pause function
     * @dev Only owner can pause the contract, halts voting functions
     */

    function pause() external onlyOwner{
        _pause();
    }

    /***
     * @notice Emergency unpause function
     * @dev Only owner can unpause the contract
     */

    function unpause() external onlyOwner{
        _unpause();
    }

    // Internal Functions //
    
    /***
     * @notice Internal function to process votes and update storage
     * @param voter Address of voter
     * 
     */

}
