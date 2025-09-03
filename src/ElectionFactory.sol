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



contract ElectionFactory {
     // ============ TYPE DECLARATIONS ============
     /// @notice Struct to store election metadata
     /// @dev This struct contains all the essential information for an election

     struct Election{
        uint256 orgId;
        uint256 electionId;
        string electionName;
        string description;
        uint256 startTime;
        uint256 endTime;
        bool isActive;
        string[] candidates;
        address cretaor;
        uint256 createdAt;
     }


/**
 * @notice mapping to all elections by their ID
 * @dev This mapping allows for quick access to election details
 * @dev electionID => Election
 */

mapping(uint256 => Election) public elections;

/***
 * @notice Mapping to track organization admins
 * @dev orgId => adminAddress => isAdmin
 */

mapping(uint256 =)
}