// SPDX-License-Identifier: MIT
pragma solidity 0.8.37;

import { EmployerProfile, FreelancerProfile, JobProfile, Hiring} from "./types/basic.sol";


contract Dework{

    address private initialWallet;
    EmployerProfile[] private employerList;
    FreelancerProfile[] private freelancerList;
    mapping (uint256 => address) private employerWallet; 
    mapping (uint256 => address) private freelancerWallet; 
    error Dework_IncorrectWeiLimit(uint256 employer,uint256 actual);
    error Dework_InvalidEmployer(uint256 employer,address caller);
    error Dework_InvalidFreelancer(uint256 freelancer,address caller);
    error Dework_ProfileIsNotOpenToWork(uint jobId);
    error Dework_UnAuthorizedJobProfile(uint256 jobId);

    constructor(address _account){
        initialWallet = _account;
    }
    function createEmployerProfile(string calldata _fullName,bool _hiring) external {
        EmployerProfile memory newEmployer = EmployerProfile({
            id:employerList.length,
            fullName: _fullName,
            isHiring: _hiring,
            wallet:msg.sender,
            profiles:new Hiring[](0)
        });
        employerList.push(newEmployer);
        employerWallet[newEmployer.id] = msg.sender;
    }

    function getEmployerProfiles() external view returns (EmployerProfile[] memory){
        return employerList;
    }

    function createFreelancerProfile(string calldata _name,uint256 _exp, bool _active, uint256 _paymentInWei) external {
            FreelancerProfile memory freelancer = FreelancerProfile({
                id:freelancerList.length,
                name: _name,
                isActive:_active,
                wallet:msg.sender,
                hourlyPayinWei:_paymentInWei,
                expeirence:_exp
            });
            freelancerList.push(freelancer);
            freelancerWallet[freelancer.id] = msg.sender;
    }

    function getFreelancerProfiles() external view returns (FreelancerProfile[] memory){
        return freelancerList;
    }

    function _getEmployerById(uint256 _empId) internal view returns(EmployerProfile storage){
        return employerList[_empId];
    }

    function _getHiringId(uint256 empId) internal view returns(uint256){
        return employerList[empId].profiles.length;
    }

    function createJobListings(uint256 _empId,JobProfile calldata _jobLists) external payable {
        EmployerProfile storage employer = _getEmployerById(_empId); 
        if (msg.value!=_jobLists.salaryinWei){
            revert Dework_IncorrectWeiLimit(_empId,msg.value);
        }
        uint256 jobId = _getHiringId(_empId);
        Hiring memory hiring = Hiring({
                id:jobId,
                title:_jobLists.title,
                description:_jobLists.description,
                deadlineTimestamp:_jobLists.deadlineTimestamp,
                isOpentoWork:true,
                fixedPriceInWei:_jobLists.salaryinWei,
                hiredFreelancerId:0,
                hasHiredFreelancer:false,
                isPaid:false
        });

        employer.profiles.push(hiring);
    }

    function _getJobDescription(uint256 _empId,uint256 _jobId) internal view returns (Hiring storage) {
            return employerList[_empId].profiles[_jobId];
    } 

    function _requiredJobisOpentoWork(Hiring memory jobs) internal pure{
        if (jobs.isOpentoWork!=true){
            revert Dework_ProfileIsNotOpenToWork(jobs.id);
        }
    }

    function getJobList(uint256 _empId) external view returns(Hiring[] memory){
        return employerList[_empId].profiles;
    }

    function EmployerHiringFreelancer(uint256 _empId,uint256 _jobId,uint256 _freelancerId) external{
            address employer = employerWallet[_empId];
            address freelancer = freelancerWallet[_freelancerId];

            uint256 jobListLength = employerList[_empId].profiles.length;
            if (msg.sender!=employer || employer==address(0)){
                revert Dework_InvalidEmployer(_empId,msg.sender);
            }

            if (freelancerList.length<=_freelancerId || freelancer==address(0)){
                revert Dework_InvalidFreelancer(_freelancerId,msg.sender);
            }
            if (jobListLength<=_jobId){
                revert Dework_UnAuthorizedJobProfile(_jobId);
            }
            _requiredJobisOpentoWork(employerList[_empId].profiles[_jobId]);
            Hiring storage freelancerHiring = _getJobDescription(_empId, _jobId);
            freelancerHiring.hiredFreelancerId = _freelancerId;
            freelancerHiring.hasHiredFreelancer = true;
            freelancerHiring.isPaid = true;
            freelancerHiring.isOpentoWork = false;
    }
}
