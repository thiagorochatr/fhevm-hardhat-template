// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import "fhevm/lib/TFHE.sol";
import { IIdentityManager } from "./IIdentityManager.sol";

/// @title VotingSystem Interface
/// @author Thiago
/// @notice This contract is the interface for the Voting System.
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

    // struct VoteResult {
    //     string[] winnerNames;
    //     uint64 voteCount;
    // }

    struct Vote {
        uint256 endBlock;
        // VoteResult result;
        uint256 result;
        uint256 voteCount;
        string description;
        VoteState state;
    }

    event VoteCreated(uint256 indexed voteId, string[] candidates);
    event VoteCasted(uint256 indexed voteId);
    event VoteRevealRequested(uint256 indexed voteId);
    event VoteRevealed(uint256 indexed voteId);
    event WinnerDeclared(uint256 indexed voteId, string winnerName, uint64 totalVotes);

    error AlreadyVoted();
    error VoteClosed();
    error VoteNotClosed();
    error VoteDoesNotExist();

    function createVote(uint256 endBlock, string[] calldata candidates, string calldata description) external;

    function castVote(uint256 voteId, einput encryptedSupport, bytes calldata supportProof) external;

    function getVote(uint256 voteId) external view returns (Vote memory);

    function requestWinnerDecryption(uint256 voteId) external;

    function callbackDecryption(uint256 requestId, uint64 decryptedVoteCount) external;

    function blockNumber() external view returns (uint256);
}
