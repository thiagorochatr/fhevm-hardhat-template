// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import "fhevm/lib/TFHE.sol";
import { IIdentityManager } from "./IIdentityManager.sol";

interface IVotingSystem is IIdentityManager {
    enum VoteState {
        NotCreated,
        Created,
        RequestedToReveal,
        Revealed
    }

    struct Vote {
        uint256 endBlock;
        string description;
        string[] candidates;
        euint64 encryptedResult;
        uint256 result;
        uint256 voteCount;
        VoteState state;
    }

    event VoteCasted(uint256 indexed voteId);
    event VoteCreated(uint256 indexed voteId);
    event VoteRevealRequested(uint256 indexed voteId);
    event VoteRevealed(uint256 indexed voteId);

    error AlreadyVoted();
    error VoteDoesNotExist();
    error VoteNotClosed();
    error VoteClosed();

    function createVote(uint256 endBlock, string[] calldata candidates, string calldata description) external;

    function castVote(uint256 voteId, einput encryptedSupport, bytes calldata supportProof) external;

    function getVote(uint256 voteId) external view returns (Vote memory);

    function hasVoted(uint256 voteId, bytes32 voterId) external view returns (bool);

    function isVotePassed(uint256 voteId) external view returns (bool);

    function requestRevealVote(uint256 voteId) external;

    function revealVote(uint256 requestId, uint256 encryptedResult) external;
}
