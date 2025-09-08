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
    * @param orgId The organization ID to check admin status against
    * @dev  Reverts if msg.sender is not an admin for the specified organization
    */
   modifier onlyOrgAdmin(uint256 orgId) {
       require(orgAdmins[orgId][msg.sender], "Not organization admin");
       _;
   }

   /***
    * @notice Ensures the election exists
    * @param electionId The election ID to Validate
    * @dev Reverts if the election does not exist (elction=0 means not created)
    */

   modifier validElection(uint256 electionId){
    require (elections[electionId].electionId != 0, "Election Not Found");
   }

   /***
    * @notice Validates time parameters for Elections
    * @param startTime when the election should start
    * @param endTime when the election should end
    * @dev Ensures startTime is in future and endTime is after startTime
    */

   modifier validTimeRange(uint256 startTime,uint256 endTime){
    require(startTime >= block.timestamp, "Start time must be in the future");
    require(endTime > startTime, "End time must be after start time");
    _;
   }

   /***
    * @notice Ensure input is not empty or zero
    * @param value the value to chek (for addresses,use address(0))
    */

   modifier notEmpty(string calldata value){
    require(bytes(value).length > 0, "Input cannot be empty");
    _; 
   }

   // <============ FUNCTIONS ============>
   /***
    * @notice Contract constructor - sets up the initial state
    * @dev sets the deployer as the platform admin and initializes nextElectionId
    */

    contructor(){
        platfromAdmin=msg.sender;
        nextElectionID=1; // Start election IDs from 1(0 means not created)
    }

    // <============ EXTERNAL FUNCTIONS ============>
     /**
      * @notice adds a new organization admin
      * @param orgId The ID of the organization
      * @param admin The address of the new admin to add
      * @dev Only the platform admin can call this function
      */
    
    function addOrgAdmin(uint256 orgId, address admin) external onlyPlatformAdmin{
       require(admin != adress(0), "Invalid admin address");
       require(!orgAdmins[orgId][admin], "Already an admin");

       orgAdmins[orgId][admin] = true;
       emit OrgAdminAdded(orgId, admin, msg.sender);
    }

    /***
     * @notice Removes an organization admin
     * @param orgId The ID of the organization
     * @param admin The address to revoke admin privileges from
     * @dev Only the platform admin can call this function
     */

    function removeOrgAdmin(uint256 orgId, address admin) external onlyPlatformAdmin{
        require (orgAdmins[orgId][admin], "Not an admin");

        orgAdmins[orgId][admin] = false;
        emit OrgAdminRemoved(orgId, admin, msg.sender);
    }

    /***
     * @notice Creates a new election for an organization
     * @param orgId The organization ID creating the elction
     * @param electionName The name/title of the election 
     * @param description Detailed description of the elction
     * @param startTime Unix timestamp when elction starts
     * @param endTime Unix timestamp when elction ends
     * @param candidates Array of candidate names/IDs
     * @return electionId the unique ID of the created elction
     * @dev Only Organizaton admins can create elections for their org
     */

    function createElection(
        uint256 orgId,
        string calldata electionName,
        string calldata description,
        uint256 startTime,
        uint256 endTime,
        string[] calldata candidates
    ) external 
      onlyOrgAdmin(orgId)
      notEmpty(electionName)
      validTimeRange(startTime,endTime)
      returns(uint256)

}
