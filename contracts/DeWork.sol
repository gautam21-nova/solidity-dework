//  SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import { EmployeeProfile,CreateJobListiningProfile } from "./types/Employee.sol";


contract DeWork{

    EmployeeProfile[] public employeeProfiles;
    address initialAddress;
    mapping (uint256=>address) public employees;
    event EmployeeRegistered (uint256 employeeId,address caller);
    error DeWork_InvalidFee (uint256 actualFee, uint256 passedFee);

    constructor (address _initialAddress){
        initialAddress = _initialAddress;
    }

    function registerNewEmployee(string calldata _name,bool _isHiring) external {
        uint256 noEmployee = getTotalNumEmployees();
        EmployeeProfile memory newEmployeeProfile = EmployeeProfile({
            id:noEmployee,
            name:_name,
            isHiring:_isHiring,
            wallet:msg.sender
        });
        employeeProfiles.push(newEmployeeProfile);
        employees[noEmployee] = msg.sender;
        emit EmployeeRegistered(noEmployee, msg.sender);
    }
    function getTotalNumEmployees() public view returns(uint256){
            return employeeProfiles.length;
    }

    function getEmployeeProfile() public view returns(EmployeeProfile[] memory){
        return employeeProfiles;
    }

    function createJobListining (uint256 empId,CreateJobListiningProfile calldata jobListing) external payable {
                uint256 fixedPrice = jobListing.fixed_pricein_wei;
                if (msg.value != fixedPrice){
                    revert DeWork_InvalidFee(msg.value,fixedPrice);
                }
                empId;
    }

}