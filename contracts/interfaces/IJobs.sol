// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.17;

interface IJobs {

    struct KolsInfo {
        address kolAddress;
        uint256[] tokenIds;             // List soul bound token 
        uint256[] jobsIds;              // List jobs
        uint256 price;      
        uint256 creditPoints;
        uint256[] listAppliedJobs;
        uint256[] listInvitationJobs;

    }

    struct JobInfo {
        uint256 id;
        address creator;
        uint256 budget;
        uint256 reward;
        bool isStarted;
        bool isCompleted;
        string detail;
        address[] listApplicants;
        address kol;
        address[] listInvitationKols;
        bool[2] cancelApproval;            // [creator, kols]
        bool[2] completedApproval;         // [creator, kols]

    }

    event CreateProfile(address indexed kolAddress ,uint256 indexed price);

    event CreateJob(address indexed creator, uint256 budget, uint256 reward, uint256 jobId);

    event JobApplied(address indexed kolAddress, uint256 indexed jobId);

    event StartJob(uint256 indexed jobId, address indexed kolAddress);

    event InviteKol(uint256 indexed jobId, address indexed kolAddress);

    event CancelJob(uint256 indexed jobId);

    event CompletedJob(uint256 indexed jobId, address indexed kolAddress);
}