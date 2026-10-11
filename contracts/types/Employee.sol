//  SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;


struct EmployerProfile{
    uint256 id;
    string name;
    bool isHiring;
    address wallet;
    JobListings[] jobLists;
}

struct CreateJobListiningProfile{
    string title;
    string job_description;
    uint256 deadline;
    uint256 fixed_pricein_wei;
}

struct JobListings{
    uint256 id;
    string title;
    string description;
    uint256 deadlineTimestamp;
    bool isOpentoWork;
    uint256 fixedPriceInWei;
    uint256 hiredFreelancerId;
    bool hasHiredFreelancer;
    bool isPaid;
}