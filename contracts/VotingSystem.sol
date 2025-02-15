// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import "fhevm/lib/TFHE.sol";
import { SepoliaZamaFHEVMConfig } from "fhevm/config/ZamaFHEVMConfig.sol";
import { GatewayCaller, Gateway } from "fhevm/gateway/GatewayCaller.sol";
import { SepoliaZamaGatewayConfig } from "fhevm/config/ZamaGatewayConfig.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IdentityManager } from "./IdentityManager.sol";
import { IVotingSystem } from "./interfaces/IVotingSystem.sol";

/// @title VotingSystem Contract
/// @author Thiago
/// @notice This contract implements a private voting system using FHE (Fully Homomorphic Encryption)
/// @dev Inherits from IdentityManager for voter verification and uses TFHE for encrypted vote handling
contract VotingSystem is
    IVotingSystem,
    IdentityManager,
    SepoliaZamaFHEVMConfig,
    SepoliaZamaGatewayConfig,
    GatewayCaller,
    Ownable
{
    /// Total number of votes created, counter for generating unique vote IDs
    uint256 public numberOfVotes;
    /// Mapping of vote IDs to Vote struct containing vote details
    mapping(uint256 => Vote) private _votes;
    /// Tracks if a voter has already cast their vote for a specific vote ID
    mapping(uint256 => mapping(bytes32 => bool)) private _castedVotes;
    /// Stores candidates for each vote
    mapping(uint256 => mapping(uint256 => Candidate)) public _candidates;
    /// Number of candidates for each vote
    mapping(uint256 => uint256) public _voteCandidateCount;
    /// Stores decrypted vote counts for each candidate
    mapping(uint256 => mapping(uint256 => uint64)) public decryptedVotes;
    /// Tracks number of decrypted votes received for each vote
    mapping(uint256 => uint256) public decryptedVotesReceived;

    /// @dev Initializes the contract with a list of allowed voters
    /// @param allowedVoters Array of voter addresses that are allowed to participate
    constructor(address[] memory allowedVoters) IdentityManager(allowedVoters) Ownable(msg.sender) {}

    /// @notice Creates a new vote with specified parameters
    /// @param endBlock Block number when the vote ends
    /// @param candidates Array of candidate names
    /// @param description Description of the vote
    /// @dev Only the contract owner can create votes
    function createVote(
        uint256 endBlock,
        string[] calldata candidates,
        string calldata description
    ) external onlyOwner {
        uint256 voteId = numberOfVotes;

        _votes[voteId] = Vote(endBlock, 0, 0, description, VoteState.NotCreated);

        for (uint256 i = 0; i < candidates.length; i++) {
            _candidates[voteId][i] = Candidate(candidates[i], TFHE.asEuint64(0));
            TFHE.allow(_candidates[voteId][i].votes, address(this));
        }

        _voteCandidateCount[voteId] = candidates.length;

        _votes[voteId].state = VoteState.Created;

        numberOfVotes++;
        emit VoteCreated(voteId, candidates);
    }

    /// @notice Allows a voter to cast their vote
    /// @param voteId ID of the vote
    /// @param encryptedSupport Encrypted vote data
    /// @param supportProof Proof of valid vote
    /// @dev Uses FHE to maintain vote privacy
    function castVote(uint256 voteId, einput encryptedSupport, bytes calldata supportProof) external {
        bytes32 voterId = verifyProofAndGetVoterId();
        if (_castedVotes[voteId][voterId]) revert AlreadyVoted();
        _castedVotes[voteId][voterId] = true;

        Vote storage vote = _getVote(voteId);
        if (block.number > vote.endBlock) revert VoteClosed();

        // Validate the encrypted vote
        euint64 candidateIndex = TFHE.asEuint64(encryptedSupport, supportProof);
        TFHE.allowThis(candidateIndex);

        // Increment the vote count for this specific vote
        vote.voteCount++;

        // Increment the vote count for the specific candidate
        for (uint256 i = 0; i < _voteCandidateCount[voteId]; i++) {
            ebool isCandidate = TFHE.eq(candidateIndex, TFHE.asEuint64(i));

            euint64 voteValue = TFHE.select(isCandidate, TFHE.asEuint64(1), TFHE.asEuint64(0));

            _candidates[voteId][i].votes = TFHE.add(_candidates[voteId][i].votes, voteValue);
            TFHE.allowThis(_candidates[voteId][i].votes);
        }

        emit VoteCasted(voteId);
    }

    /// @notice Retrieves vote information
    /// @param voteId ID of the vote to query
    /// @return Vote struct containing vote details
    function getVote(uint256 voteId) external view returns (Vote memory) {
        return _getVote(voteId);
    }

    /// @notice Initiates the process to decrypt and reveal vote results
    /// @param voteId ID of the vote to reveal
    /// @dev Can only be called after vote end block
    function requestWinnerDecryption(uint256 voteId) external {
        Vote storage vote = _getVote(voteId);
        if (block.number <= vote.endBlock) revert VoteNotClosed();
        vote.state = VoteState.RequestedToReveal;
        emit VoteRevealRequested(voteId);

        uint256 numCandidates = _voteCandidateCount[voteId];

        uint256[] memory cts = new uint256[](1);

        for (uint256 i = 0; i < numCandidates; i++) {
            cts[0] = Gateway.toUint256(_candidates[voteId][i].votes);

            uint256 requestId = Gateway.requestDecryption(
                cts,
                this.callbackDecryption.selector,
                0,
                block.timestamp + 100,
                false
            );
            addParamsUint256(requestId, voteId);
            addParamsUint256(requestId, i);
        }
    }

    /// @notice Callback function for processing decrypted votes
    /// @param requestId ID of the decryption request
    /// @param decryptedVoteCount The decrypted vote count
    /// @dev Only callable by the gateway
    function callbackDecryption(uint256 requestId, uint64 decryptedVoteCount) external onlyGateway {
        uint256[] memory params = getParamsUint256(requestId);
        uint256 voteId = params[0];
        uint256 candidateIndex = params[1];

        decryptedVotes[voteId][candidateIndex] = decryptedVoteCount;
        decryptedVotesReceived[voteId]++;

        if (decryptedVotesReceived[voteId] == _voteCandidateCount[voteId]) {
            determineWinner(voteId);
            _getVote(voteId).state = VoteState.Revealed;
            emit VoteRevealed(voteId);
        }
    }

    /// @notice Internal function to determine the winner of a vote
    /// @param voteId ID of the vote
    /// @dev Emits WinnerDeclared event with results
    function determineWinner(uint256 voteId) internal {
        uint256 numCandidates = _voteCandidateCount[voteId];
        uint256 winnerIndex = 0;
        uint64 maxVotes = decryptedVotes[voteId][0];

        for (uint256 i = 1; i < numCandidates; i++) {
            if (decryptedVotes[voteId][i] > maxVotes) {
                maxVotes = decryptedVotes[voteId][i];
                winnerIndex = i;
            }
        }

        emit WinnerDeclared(voteId, _candidates[voteId][winnerIndex].name, maxVotes);
    }

    /// @notice Returns the current block number
    /// @return Current block number
    function blockNumber() external view returns (uint256) {
        return block.number;
    }

    /// @notice Internal helper function to retrieve vote information
    /// @param voteId ID of the vote to query
    /// @return Vote storage pointer
    /// @dev Reverts if vote doesn't exist
    function _getVote(uint256 voteId) internal view returns (Vote storage) {
        Vote storage vote = _votes[voteId];
        if (vote.endBlock == 0) revert VoteDoesNotExist();
        return vote;
    }
}
