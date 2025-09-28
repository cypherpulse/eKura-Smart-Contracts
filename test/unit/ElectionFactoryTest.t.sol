// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {ElectionFactory} from "../../src/ElectionFactory.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {DeployElectionFactory} from "../../script/DeployElectionFactory.s.sol";

contract ElectionFactoryTest is Test{
    //EVENTS//

    event ElectionCreated(
        uint256 indexed orgId,
        uint256 indexed electionId,
        string indexed electionName,
        address creator,
        uint256  startTime,
        uint256 endTime
    )

    event orgAdminAdded(
        uint256 indexed orgId,
        address indexed admin,
        address indexed addedBy
    )

    //STATE VARIABLES//

    ElectionFactory public electionFactory;
    HelperConfig public helperConfig;

}