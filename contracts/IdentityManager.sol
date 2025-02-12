// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import { IIdentityManager } from "./interfaces/IIdentityManager.sol";

contract IdentityManager is IIdentityManager {
    address[] private _allowedVoters;

    constructor(address[] memory allowedVoters) {
        _allowedVoters = allowedVoters;
    }

    /// @inheritdoc IIdentityManager
    function verifyProofAndGetVoterId() public view returns (bytes32) {
        // Convert sender address to bytes32 hash for security
        bytes32 voterId = keccak256(abi.encodePacked(msg.sender));

        // Verify sender is in allowed voters list
        bool isAllowed = false;
        for (uint i = 0; i < _allowedVoters.length; i++) {
            if (_allowedVoters[i] == msg.sender) {
                isAllowed = true;
                break;
            }
        }

        if (!isAllowed) revert NotAllowed();

        return voterId;
    }
}
