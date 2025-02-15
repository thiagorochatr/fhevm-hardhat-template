// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

/// @title IdentityManager Interface
/// @author Thiago
/// @notice This contract is the interface for the IdentityManager contract.
interface IIdentityManager {
    /// @notice Error thrown when sender is not in the allowed voters list
    error NotAllowed();

    /// @notice Verifies if the sender is an allowed voter and returns their voter ID
    /// @return bytes32 Hash of the sender's address as their voter ID
    function verifyProofAndGetVoterId() external view returns (bytes32);
}
