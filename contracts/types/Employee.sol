//  SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;


struct EmployeeProfile{
    uint256 id;
    string name;
    bool isHiring;
    address wallet;
}

struct CreateJobListiningProfile{
    string title;
    string job_description;
    uint256 deadline;
    uint256 fixed_pricein_wei;
}