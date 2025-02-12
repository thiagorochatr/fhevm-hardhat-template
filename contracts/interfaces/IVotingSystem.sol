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

    struct Candidate {
        string name;
        euint64 votes;
    }

    struct Vote {
        uint256 endBlock;
        euint64 encryptedResult;
        uint256 result;
        uint256 voteCount;
        string description;
        VoteState state;
    }

    event VoteCreated(uint256 indexed voteId);
    event VoteCasted(uint256 indexed voteId);
    event VoteRevealRequested(uint256 indexed voteId);
    event VoteRevealed(uint256 indexed voteId);
    event WinnerDeclared(uint256 voteId, string winnerName, uint64 totalVotes);

    error AlreadyVoted();
    error VoteDoesNotExist();
    error VoteNotClosed();
    error VoteClosed();

    function createVote(uint256 endBlock, string[] calldata candidates, string calldata description) external;

    function castVote(uint256 voteId, einput encryptedSupport, bytes calldata supportProof) external;

    function getVote(uint256 voteId) external view returns (Vote memory);

    function hasVoted(uint256 voteId, bytes32 voterId) external view returns (bool);

    function requestWinnerDecryption(uint256 voteId) external;

    function callbackDecryption(uint256 voteId, uint64 candidateIndex, uint64 decryptedVoteCount) external;
}
