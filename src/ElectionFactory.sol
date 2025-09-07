// SPDX-License-Identifier: MIT

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

contract ElectionFactory {
    // <============ TYPE DECLARATIONS ============>

    /*** @notice Struct to store election metadata
     * @dev This struct contains all the essential information for an election
     */

    struct Election {
        uint256 orgId;
        uint256 electionId;
        string electionName;
        string description;
        uint256 startTime;
        uint256 endTime;
        bool isActive;
        string[] candidates;
        address creator;
        uint256 createdAt;
    }

    /*** @notice Struct to store organization metadata
     * @dev This struct contains all the essential information for an organization
     * @notice mapping to all elections by their ID
     * @dev This mapping allows for quick access to election details
     * @dev electionID => Election
     */

    mapping(uint256 => Election) public elections;

    /***
     * @notice Mapping to track organization admins
     * @dev orgId => adminAddress => isAdmin
     */

    mapping(uint256 => mapping(address => bool)) public orgAdmins;

    /***
     * @notice Mapping to store election IDs for each organization
     * @dev orgID => electionIDs
     */

    mapping(uint256 => uint256[]) public orgElections;

    /***
     * @notice Counter for generating unique election IDs
     * @dev starts at 1,increments for each new election
     */

    uint256 public nextElectionID;

    /***
     * @notice Address of the platform admin (eKura team)
     * @dev This address can add/remove org admins and pause contracts
     */

    address public platformAdmin;

    //<============= EVENTS ============>

    /*** @notice Emitted when a new election is created
     * @param orgId The ID of the organization creating the election
     * @param electionId The unique ID of the created election
     * @param electionName The name of the election
     * @param creator The address of the election creator
     * @param createdAt The timestamp when the election was created
     */

    event ElectionCreated(
        uint256 indexed orgId,
        uint256 indexed electionId,
        string title,
        address indexed creator,
        uint256 startTime,
        uint256 endTime
    );

    /***
     * @notice Emitted when an organization admin is added
     * @param orgId The ID of the organization
     * @param admin The address of the new admin
     * @param addedBy The address of the platform admin who added the new admin
     */

    event OrgAdminAdded(
        uint256 indexed orgId,
        address indexed admin,
        address indexed addedBy
    );

    /***
     * @notice Emitted when an organization admin is removed
     * @param orgId The ID of the organization
     * @param admin The address of the removed admin
     * @param removedBy The address of the platform admin who removed the admin
     */

    event OrgAdminRemoved(
        uint256 indexed orgId,
        address indexed admin,
        address indexed removedBy
    );

    /***
     * @notice Emitted when an election's active status changes
     * @param electionId The election that was toggled
     * @param isActive The new active status of the election
     * @param changedBy The address of the platform admin who changed the status
     */

    event ElectionStatusChanged(
        uint256 indexed electionId,
        bool isActive,
        address indexed changedBy
    );

    // <============ MODIFIERS ============>

    /***
     * @notice Ensures only the platform admin can call a function
     * @dev Revert if msg.sender is not the platform admin
     */

   modifier onlyPlatformAdmin(){
      require(msg.sender == platformAdmin, "Not platform admin");
      _;
   }

   /***
    * @notice Ensures only organization admins can call a function
    * 
    */
}
