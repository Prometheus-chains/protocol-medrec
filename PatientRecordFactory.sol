// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import "./PatientRecord.sol";

/// @title PatientRecordFactory - deploys one PatientRecord per caller
contract PatientRecordFactory {
    /// @dev Maps each patient address to their deployed PatientRecord contract address.
    ///      Public mapping gives you an auto-generated getter: recordOf(patient) -> record address.
    mapping(address => address) public recordOf;

    event RecordCreated(address indexed patient, address indexed record);

    /// @notice Create your PatientRecord (one per address). Reverts if it already exists.
    /// @return record The address of your newly deployed PatientRecord
    function createRecord() external returns (address record) {
        require(recordOf[msg.sender] == address(0), "record exists");
        record = address(new PatientRecord(msg.sender));
        recordOf[msg.sender] = record;
        emit RecordCreated(msg.sender, record);
    }

    /// @notice Check if a record exists for a given patient address.
    function hasRecord(address patient) external view returns (bool) {
        return recordOf[patient] != address(0);
    }
}
