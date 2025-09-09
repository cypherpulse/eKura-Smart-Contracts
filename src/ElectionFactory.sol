// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/**
 * @title ElectionFactory
 * @author eKura Team
 * @notice This contract manages the creation and administration of elections for multiple organizations
 * @dev Implements multi-tenant election management with role-based access control
 */
contract ElectionFactory {
    
    ////////////////////////////////////////////////////////////////////////////
    ////                            ERRORS                                  ////
    ////////////////////////////////////////////////////////////////////////////
    
    error ElectionFactory__NotPlatformAdmin();
    error ElectionFactory__NotOrgAdmin();
    error ElectionFactory__InvalidAdminAddress();
    error ElectionFactory__AlreadyAnAdmin();
    error ElectionFactory__NotAnAdmin();
    error ElectionFactory__ElectionNotFound();
    error ElectionFactory__InvalidTimeRange();
    error ElectionFactory__StartTimeMustBeInFuture();
    error ElectionFactory__EmptyInput();
    error ElectionFactory__NoCandidatesProvided();

    ////////////////////////////////////////////////////////////////////////////
    ////                        TYPE DECLARATIONS                           ////
    ////////////////////////////////////////////////////////////////////////////
    
    /**
     * @notice Struct containing all election metadata
     * @param orgId Organization identifier
     * @param electionId Unique election identifier  
     * @param electionName Human-readable election title
     * @param description Detailed election description
     * @param startTime Unix timestamp when voting begins
     * @param endTime Unix timestamp when voting ends
     * @param isActive Emergency toggle for election status
     * @param candidates Array of candidate names/IDs
     * @param creator Address of the org admin who created the election
     * @param createdAt Unix timestamp of election creation
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

    ////////////////////////////////////////////////////////////////////////////
    ////                         STATE VARIABLES                           ////
    ////////////////////////////////////////////////////////////////////////////
    
    /// @dev Mapping from election ID to Election struct
    mapping(uint256 => Election) private s_elections;
    
    /// @dev Nested mapping: orgId => adminAddress => isAdmin
    mapping(uint256 => mapping(address => bool)) private s_orgAdmins;
    
    /// @dev Mapping from organization ID to array of election IDs
    mapping(uint256 => uint256[]) private s_orgElections;
    
    /// @dev Counter for generating unique election IDs (starts at 1)
    uint256 private s_nextElectionId;
    
    /// @dev Address with platform-level administrative privileges
    address private immutable i_platformAdmin;

    ////////////////////////////////////////////////////////////////////////////
    ////                            EVENTS                                  ////
    ////////////////////////////////////////////////////////////////////////////
    
    event ElectionCreated(
        uint256 indexed orgId,
        uint256 indexed electionId,
        string indexed electionName,
        address creator,
        uint256 startTime,
        uint256 endTime
    );
    
    event OrgAdminAdded(
        uint256 indexed orgId,
        address indexed admin,
        address indexed addedBy
    );
    
    event OrgAdminRemoved(
        uint256 indexed orgId,
        address indexed admin,
        address indexed removedBy
    );
    
    event ElectionStatusChanged(
        uint256 indexed electionId,
        bool isActive,
        address indexed changedBy
    );

    ////////////////////////////////////////////////////////////////////////////
    ////                           MODIFIERS                                ////
    ////////////////////////////////////////////////////////////////////////////
    
    modifier onlyPlatformAdmin() {
        if (msg.sender != i_platformAdmin) {
            revert ElectionFactory__NotPlatformAdmin();
        }
        _;
    }
    
    modifier onlyOrgAdmin(uint256 orgId) {
        if (!s_orgAdmins[orgId][msg.sender]) {
            revert ElectionFactory__NotOrgAdmin();
        }
        _;
    }
    
    modifier validElection(uint256 electionId) {
        if (s_elections[electionId].electionId == 0) {
            revert ElectionFactory__ElectionNotFound();
        }
        _;
    }

    ////////////////////////////////////////////////////////////////////////////
    ////                           FUNCTIONS                                ////
    ////////////////////////////////////////////////////////////////////////////
    
    constructor() {
        i_platformAdmin = msg.sender;
        s_nextElectionId = 1; // Start at 1 so 0 indicates non-existent election
    }

    ////////////////////////////////////////////////////////////////////////////
    ////                       EXTERNAL FUNCTIONS                           ////
    ////////////////////////////////////////////////////////////////////////////
    
    /**
     * @notice Grants organization admin privileges to an address
     * @param orgId The organization identifier
     * @param admin The address to grant admin privileges
     * @dev Only callable by platform admin
     */
    function addOrgAdmin(uint256 orgId, address admin) external onlyPlatformAdmin {
        if (admin == address(0)) {
            revert ElectionFactory__InvalidAdminAddress();
        }
        if (s_orgAdmins[orgId][admin]) {
            revert ElectionFactory__AlreadyAnAdmin();
        }
        
        s_orgAdmins[orgId][admin] = true;
        emit OrgAdminAdded(orgId, admin, msg.sender);
    }

    /**
     * @notice Revokes organization admin privileges from an address
     * @param orgId The organization identifier
     * @param admin The address to revoke admin privileges
     * @dev Only callable by platform admin
     */
    function removeOrgAdmin(uint256 orgId, address admin) external onlyPlatformAdmin {
        if (!s_orgAdmins[orgId][admin]) {
            revert ElectionFactory__NotAnAdmin();
        }
        
        s_orgAdmins[orgId][admin] = false;
        emit OrgAdminRemoved(orgId, admin, msg.sender);
    }

    /**
     * @notice Creates a new election for an organization
     * @param orgId Organization creating the election
     * @param electionName Title of the election
     * @param description Detailed election description
     * @param startTime Unix timestamp when voting begins
     * @param endTime Unix timestamp when voting ends  
     * @param candidates Array of candidate names/identifiers
     * @return electionId Unique identifier of the created election
     * @dev Only callable by organization admins
     */
    function createElection(
        uint256 orgId,
        string calldata electionName,
        string calldata description,
        uint256 startTime,
        uint256 endTime,
        string[] calldata candidates
    ) external onlyOrgAdmin(orgId) returns (uint256) {
        // Input validation
        if (bytes(electionName).length == 0) {
            revert ElectionFactory__EmptyInput();
        }
        if (startTime <= block.timestamp) {
            revert ElectionFactory__StartTimeMustBeInFuture();
        }
        if (endTime <= startTime) {
            revert ElectionFactory__InvalidTimeRange();
        }
        if (candidates.length == 0) {
            revert ElectionFactory__NoCandidatesProvided();
        }

        uint256 electionId = s_nextElectionId++;

        // Create election struct - using storage assignment to avoid stack too deep
        Election storage newElection = s_elections[electionId];
        newElection.orgId = orgId;
        newElection.electionId = electionId;
        newElection.electionName = electionName;
        newElection.description = description;
        newElection.startTime = startTime;
        newElection.endTime = endTime;
        newElection.isActive = true;
        
        // Copy candidates array manually to avoid calldata to storage issue
        for (uint256 i = 0; i < candidates.length; i++) {
            newElection.candidates.push(candidates[i]);
        }
        
        newElection.creator = msg.sender;
        newElection.createdAt = block.timestamp;

        s_orgElections[orgId].push(electionId);

        emit ElectionCreated(orgId, electionId, electionName, msg.sender, startTime, endTime);

        return electionId;
    }

    /**
     * @notice Toggles an election's active status (emergency function)
     * @param electionId The election to toggle
     * @dev Only callable by platform admin
     */
    function toggleElectionStatus(uint256 electionId) 
        external 
        onlyPlatformAdmin 
        validElection(electionId) 
    {
        s_elections[electionId].isActive = !s_elections[electionId].isActive;
        emit ElectionStatusChanged(electionId, s_elections[electionId].isActive, msg.sender);
    }

    ////////////////////////////////////////////////////////////////////////////
    ////                        VIEW FUNCTIONS                              ////
    ////////////////////////////////////////////////////////////////////////////

    /**
     * @notice Returns complete election details
     * @param electionId The election identifier
     * @return Election struct containing all election data
     */
    function getElection(uint256 electionId) 
        external 
        view 
        validElection(electionId) 
        returns (Election memory) 
    {
        return s_elections[electionId];
    }

    /**
     * @notice Checks if an election is currently active and within voting period
     * @param electionId The election identifier
     * @return True if election is active and within time bounds
     */
    function isElectionActive(uint256 electionId) 
        external 
        view 
        validElection(electionId) 
        returns (bool) 
    {
        Election storage election = s_elections[electionId];
        return election.isActive && 
               block.timestamp >= election.startTime && 
               block.timestamp <= election.endTime;
    }

    /**
     * @notice Returns all election IDs for an organization
     * @param orgId The organization identifier
     * @return Array of election IDs
     */
    function getOrgElections(uint256 orgId) external view returns (uint256[] memory) {
        return s_orgElections[orgId];
    }

    /**
     * @notice Checks if an address has admin privileges for an organization
     * @param orgId The organization identifier
     * @param admin The address to check
     * @return True if address is an org admin
     */
    function isOrgAdmin(uint256 orgId, address admin) external view returns (bool) {
        return s_orgAdmins[orgId][admin];
    }

    /**
     * @notice Returns the platform admin address
     * @return The platform admin address
     */
    function getPlatformAdmin() external view returns (address) {
        return i_platformAdmin;
    }

    /**
     * @notice Returns the total number of elections created
     * @return Total count of elections
     */
    function getTotalElections() external view returns (uint256) {
        return s_nextElectionId - 1;
    }
}