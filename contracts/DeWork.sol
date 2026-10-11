//  SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import { EmployeeProfile } from "./types/Employee.sol";


contract DeWork{

    EmployeeProfile[] public employeeProfiles;
    address initialAddress;

    constructor (address _initialAddress){
        initialAddress=_initialAddress;
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
    }
    function getTotalNumEmployees() public view returns(uint256){
            return employeeProfiles.length;
    }

    function getEmployeeProfile() public view returns(EmployeeProfile[] memory){
        return employeeProfiles;
    }

}