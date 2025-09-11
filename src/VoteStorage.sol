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

    function vote(uint256 electionId,uint256 candidateId) external whenNotPaused nonReentrant onlyActiveElection(electionId)  notAlreadyVoted(electionId,msg.sender) validCandidate(electionId, candidateId){
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
        bytes calldate signature
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
     * @param electionId Election identifier
     * @param candidateId Candidate identifier
     * @param isMetaTransaction Wheather this vte came via meta-transaction
     * @dev 
     */

    function _processVote(
        address voter,
        uint256 electionId,
        uint256 candidateId,
        bool isMetaTransaction
    )internal{
        // Generate a rando, salt for privacy
        bytes32 salt = keccak256(abi.encodePacked(
            voter,
            electionId,
            candidateId,
            block.timestamp,
            block.prevrandao, // More secure than block.difficulty in post-merge Ethereum
        ));
        // Generate vote hash for verification
        bytes32 voteHash = keccak256(abi.encodePacked(
            voter,
            candidateId,
            electionId,
            block.timestamp,
            salt
        ));

        //update Storage
        s_voteHashes[electionId][voter]=voteHash;
        s_hasVoted[electionId][voter]=true;
        s_voteTimestamps[electionId][voter] =block.timestamp;  
        s_voteSalts[electionId][voter]=salt;

        // Increment vote count
        s_voteCounts[electionId][candidateId]++;

        //Emit events
        emit VoteCast(
            voter,
            electionId,
            candidateId,
            voteHash,
            block.timestamp,
            isMetaTransaction
        );

        emit VoteCountUpdated(
            electionId,
            candidateId,
            s_voteCounts[electionId][candidateId]
        );
    }

    // View & Pure Functions //
        /***
         * @notice gets the vote hash for a voter in an election
         * @param electionId The election identifier
         * @param voter The voter address
         * @return The stored vote hash for verification
         */

        function getVoteHash(uint256 electionId, address voter) external view returns(bytes32){
            return s_voteHashes[electionId][voter];
        }

        /***
         * @notice Checks if a voter has voted in specific election
         * @param electionId The election identifier
         * @param voter The voter address
         * @return True if the voter has already voted
         */

        function hasVoted(uint256 electionId, address voter)
           external
           view
           returns(bool)
           {
            return s_hasVoted[electionId][voter];
           }
    /***
     * @notice Gets vote count for a spefic candidate in an election
     * @param electionId The election identifier
     * @param candidateId The candidate identifier
     * @return The current vote count
     *  */ 

     function getVoteCount(uint256 electionId,uint256candidateId)
        external
        view
        returns(uint256)
        {
            return s_voteCounts[electionId][candidateId];
        }

    /***
     * @notice Gets all vote counts for an election
     * @param electionId The election identifier
     * @return Array of vote counts for each candidate
     */

    function getAllVoteCounts(uint256 electionId)
       external
       view
       returns(uint256[] memory)
    {
        ElectionFactory.Election memory election = s_electionFactory.getElection(electionId);
        uint256[] memory counts = new uint256[](election.candidates.length);

        for(uint256 i=0; i< election.candidates.length; i++){
            counts[i] = s_voteCounts[electionId][i];
        }

        return counts;
    }

    /***
     * @notice Gets the current nonce for a voter (for meta-transactions)
     * @param voter The voter address
     * @return The current nonce
     */

    function getNonce(address voter) external view returns(uint256){
        return s_nonces[voter];
    }

    /***
     * @notice Gets the timestamp when a voter voted
     * @param electionId The election identifier
     * @param voter The voter address
     * @return The timestamp of the vote
     */

    function getVoteTimestamp(uint256 electionId, address voter)
        external 
        view
        returns(uint256)
    {
        return s_voteTimestamps[electionId][voter];
    }
   
   /***
    * @notice Gets the salt used for a specific vote hash
    * @param electionId The election identifier
    * @param voter The voter address
    * @return The salt used in vote hash generation
    */

   function getVoteSalt(uint246 electionId, address voter)
       external
       view
       returns(bytes32)
    {
        return s_voteSalts[electionId][voter];
    }
   
   /***
    * @notice Gets the ElectionFactory contract address
    * @return The current ElectionFactory address
    */

   function getElectionFactory() external view returns(address){
        return address(s_electionFactory);
   }

   /***
    * @notice Verifies a vote hash against stored data
    * @param electionId The election identifier
    * @param voter The voter address
    * @param candidateId The candidate they voted for
    * @return True if the recomputed hash matches stored hash
    */

    function verifyVoteHash(
        uint256 electionId,
        address voter,
        uint256 candidateId
    )external view returns (bool){
        bytes32 storedHash = s_voteHashes[electionId][voter];
        bytes32 salt = s_voteSalts[electionId][voter];
        bytes32 timestamp = s_votedTimestamps[electionId][voter];

        bytes32 recomputedHash = keccak256(abi.encodePacked(
            voter,
            candidateId,
            electionId,
            

        ))
    }

}
