// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

interface IIdentityManager {
    error NotAllowed();

    function verifyProofAndGetVoterId() external view returns (bytes32);
}
