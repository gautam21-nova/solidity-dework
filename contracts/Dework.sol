// SPDX-License-Identifier: MIT
pragma solidity 0.8.37;

import { EmployerProfile, FreelancerProfile, JobProfile, Hiring} from "./types/basic.sol";


contract Dework{


    uint256 private constant LATE_PENALTY_BPS_PER_DAY = 500;
    uint256 private constant BPS_DENOMINATOR = 10_000;
    address private initialWallet;
    EmployerProfile[] private employerList;
    FreelancerProfile[] private freelancerList;
    mapping (uint256 => address) private employerWallet; 
    mapping (uint256 => address) private freelancerWallet; 
    mapping (uint256 => uint256) private employerBalance;
    error Dework_IncorrectWeiLimit(uint256 employer,uint256 actual);
    error Dework_InvalidEmployer(uint256 employer,address caller);
    error Dework_InvalidFreelancer(uint256 freelancer,address caller);
    error Dework_ProfileIsNotOpenToWork(uint jobId);
    error Dework_UnAuthorizedJobProfile(uint256 jobId);
    error Dework_InSufficientBalance(uint256 employerId,uint256 amountToSend);
    error Dework_InValidFreelancerToJob(uint256 expectedFreelancerId, uint256 actualFreelancerId);
    error Dework_FreelancerAlreadyPaid(uint256 jobId);
    error DeworK_PaymentFailedToFreelancerWallet(uint256 freelancerId,uint256 amount);
    error Dework_unAuthorizedOwner(address expectedOwner,address actualOwner);

    constructor(address _account){
        initialWallet = _account;
    }

     modifier onlyAuthEmployer(uint256 empId){
        address employer = employerWallet[empId];
        if (msg.sender!=employer || employer==address(0)){
            revert Dework_InvalidEmployer(empId,msg.sender);
        }
        _;
    }

    modifier onlyAuthorizedOwner(){
        if (msg.sender!=initialWallet){
            revert Dework_unAuthorizedOwner(msg.sender,initialWallet);
        }

        _;
    }

    modifier onlyAuthFreelancer(uint256 freelancerId){
        address freelancer = freelancerWallet[freelancerId];
        if (freelancerList.length<=freelancerId || freelancer==address(0)){
                revert Dework_InvalidFreelancer(freelancerId,msg.sender);
            }
        _;
    }

    modifier validationJobListing(uint256 empId,uint256 jobId){
         uint256 jobListLength = employerList[empId].profiles.length;
         if (jobListLength<=jobId){
                revert Dework_UnAuthorizedJobProfile(jobId);
            }
        _;
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

    function createJobListings(uint256 _empId,JobProfile calldata _jobLists) external payable onlyAuthEmployer(_empId) {
        EmployerProfile storage employer = _getEmployerById(_empId); 
        if (msg.value!=_jobLists.fixedPriceinWei){
            revert Dework_IncorrectWeiLimit(_empId,msg.value);
        }
        uint256 jobId = _getHiringId(_empId);
        Hiring memory hiring = Hiring({
                id:jobId,
                title:_jobLists.title,
                description:_jobLists.description,
                deadlineTimestamp:block.timestamp + _jobLists.deadlineTimestamp,
                isOpentoWork:true,
                fixedPriceInWei:_jobLists.fixedPriceinWei,
                hiredFreelancerId:0,
                hasHiredFreelancer:false,
                isPaid:false
        });
        employerBalance[_empId] += _jobLists.fixedPriceinWei;
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

    function _calculatePayment(uint256 amountTosend, uint256 deadlineTimeStamp) internal view returns(uint256) {

            if (block.timestamp<=deadlineTimeStamp){
                return amountTosend;
            }
            uint256 delayedInCompletion = block.timestamp - deadlineTimeStamp;
            uint256 delayInDays = (delayedInCompletion + 1 days -1)/1 days;
            uint256 deductionBps = delayInDays * LATE_PENALTY_BPS_PER_DAY;

            if (deductionBps>BPS_DENOMINATOR){
                deductionBps = BPS_DENOMINATOR;
            }
            uint256 deductionAmount = (amountTosend*deductionBps)/BPS_DENOMINATOR;
            return amountTosend - deductionAmount;
    }
    function _sendEthToFreelancer(uint256 freelancerId,uint256 paymentAmount)internal{
            address freelancerAddress = freelancerWallet[freelancerId];
            (bool success,) = freelancerAddress.call{value:paymentAmount}("");
            if (success!=true){
                revert DeworK_PaymentFailedToFreelancerWallet(freelancerId,paymentAmount);
            }
    }

    function EmployerHiringFreelancer(uint256 _empId,uint256 _jobId,uint256 _freelancerId) external onlyAuthEmployer(_empId) onlyAuthFreelancer(_freelancerId) validationJobListing(_empId,_jobId) {
            
            _requiredJobisOpentoWork(employerList[_empId].profiles[_jobId]);
            Hiring storage freelancerHiring = _getJobDescription(_empId, _jobId);
            freelancerHiring.hiredFreelancerId = _freelancerId;
            freelancerHiring.hasHiredFreelancer = true;
            freelancerHiring.isPaid = true;
            freelancerHiring.isOpentoWork = false;
    }
    function releaseEscrowPayment(uint256 empId,uint256 freelancerId,uint256 jobId)public onlyAuthEmployer(empId) onlyAuthFreelancer(freelancerId) validationJobListing(empId,jobId) {
        Hiring storage jobPf = _getJobDescription(empId,jobId);
        uint256 amountToSend = jobPf.fixedPriceInWei;
        if (employerBalance[empId]<amountToSend){
            revert Dework_InSufficientBalance(empId,amountToSend);
        }
        if (freelancerId != jobPf.hiredFreelancerId){
            revert Dework_InValidFreelancerToJob(jobPf.hiredFreelancerId,freelancerId);
        }
        if (jobPf.isPaid == true){
            revert Dework_FreelancerAlreadyPaid(jobId);
        }
        jobPf.isPaid = true;
        employerBalance[empId] -= amountToSend;
        uint256 paymentAmount = _calculatePayment(amountToSend,jobPf.deadlineTimestamp);
        _sendEthToFreelancer(freelancerId,paymentAmount);
    }

    function changeOwnerAccount(address _newAccount) external onlyAuthorizedOwner{
        initialWallet = _newAccount;
    }

    function withdrawAmount(uint256 empId,uint256 withdrawalAmount) external onlyAuthEmployer(empId) {
        if (employerBalance[empId]<withdrawalAmount){
            revert Dework_InSufficientBalance(empId,employerBalance[empId]);
        }

        employerBalance[empId] -= withdrawalAmount;
        (bool success,) = employerWallet[empId].call{value: employerBalance[empId] }("");
        require (success==false, "Transfer Unsuccessful");
    }
}
