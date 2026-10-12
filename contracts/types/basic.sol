// SPDX-License-Identifier: MIT
pragma solidity 0.8.37;



struct EmployerProfile{
    uint256 id;
    string fullName;
    address wallet;
    bool isHiring;
    Hiring[] profiles;
}

struct JobProfile{
    uint256 id;
    string title;
    string description;
    uint256 deadlineTimestamp;
    uint256 requiredExpeirence;
    uint256 salaryinWei;
}


struct FreelancerProfile{
    uint256 id;
    string name;
    uint256 expeirence;
    bool isActive;
    uint256 hourlyPayinWei;
    address wallet;
}

struct Hiring{
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
