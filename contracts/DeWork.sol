//  SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import { EmployerProfile,CreateJobListiningProfile,JobListings } from "./types/Employee.sol";


contract DeWork{

    EmployerProfile[] public employeeProfiles;
    address initialAddress;
    mapping (uint256=>address) public employees;
    event EmployeeRegistered (uint256 employeeId,address caller);
    error DeWork_InvalidFee (uint256 actualFee, uint256 passedFee);
    error DeWork_FreelancerNotFreetoWork(uint256 jobId);
    error  DeWork_UnAuthorized(uint256 employerId,address caller);

    constructor (address _initialAddress){
        initialAddress = _initialAddress;
    }

    function registerEmployerProfile(string calldata _name,bool _isHiring) external {
        uint256 noEmployee = getTotalNumEmployees();
        EmployerProfile memory newEmployerProfile = EmployerProfile({
            id:noEmployee,
            name:_name,
            isHiring:_isHiring,
            wallet:msg.sender,
            jobLists:new JobListings[](0)
        });
        employeeProfiles.push(newEmployerProfile);
        employees[noEmployee] = msg.sender;
        emit EmployeeRegistered(noEmployee, msg.sender);
    }
    function getTotalNumEmployees() public view returns(uint256){
            return employeeProfiles.length;
    }

    function getEmployeeProfile() public view returns(EmployerProfile[] memory){
        return employeeProfiles;
    }

    function getCreatedJobListId(uint256 empId) public view returns (uint256){
        return employeeProfiles[empId].jobLists.length;
    }

    function _getEmployerProfile(uint256 empId) internal view returns (EmployerProfile storage){
      return  employeeProfiles[empId];
    }

    function createJobListining (uint256 empId,CreateJobListiningProfile calldata jobListingInput) external payable {
                uint256 fixedPrice = jobListingInput.fixed_pricein_wei;
                if (msg.value != fixedPrice){
                    revert DeWork_InvalidFee(msg.value,fixedPrice);
                }
                EmployerProfile storage employerProfile = _getEmployerProfile(empId);
                uint256 jobId = getCreatedJobListId(empId);
                JobListings memory jobListings = JobListings({
                    id:jobId,
                    title:jobListingInput.title,
                    description:jobListingInput.job_description,
                    deadlineTimestamp:jobListingInput.deadline,
                    isOpentoWork:true,
                    fixedPriceInWei:jobListingInput.fixed_pricein_wei,
                    hiredFreelancerId:0,
                    hasHiredFreelancer:false,
                    isPaid:false
                });
                employerProfile.jobLists.push(jobListings);
    }

    function _requireFreelancer(JobListings memory job) internal pure{
        if (job.isOpentoWork!=true){
            revert DeWork_FreelancerNotFreetoWork(job.id);
        }
    }

    function _getJobs(uint256 employerId, uint256 jobId) internal view returns(JobListings storage){
        return employeeProfiles[employerId].jobLists[jobId];
    }

    function hireFreelancer(uint256 employerId,uint256 freelancerId,uint256 jobId) public{
        
        address employer = employees[employerId];

        if (employer!=msg.sender || employer==address(0)){
            revert DeWork_UnAuthorized(employerId,msg.sender);
        }
        
        JobListings storage newjobListings = _getJobs(employerId,jobId);
        newjobListings.hiredFreelancerId = freelancerId;
        newjobListings.hasHiredFreelancer = true;
        newjobListings.isPaid = true;

        newjobListings.isOpentoWork = false;

    }
}