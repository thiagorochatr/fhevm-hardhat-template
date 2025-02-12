// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import "fhevm/lib/TFHE.sol";
import { SepoliaZamaFHEVMConfig } from "fhevm/config/ZamaFHEVMConfig.sol";
import { GatewayCaller, Gateway } from "fhevm/gateway/GatewayCaller.sol";
import { SepoliaZamaGatewayConfig } from "fhevm/config/ZamaGatewayConfig.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IdentityManager } from "./IdentityManager.sol";
import { IVotingSystem } from "./interfaces/IVotingSystem.sol";

contract VotingSystem is
    IVotingSystem,
    IdentityManager,
    SepoliaZamaFHEVMConfig,
    SepoliaZamaGatewayConfig,
    GatewayCaller,
    Ownable
{
    // Mapping of vote IDs to Vote structs containing vote details
    mapping(uint256 => Vote) private _votes;
    // Double mapping tracking which voters have cast votes for each vote ID
    mapping(uint256 => mapping(bytes32 => bool)) private _castedVotes;
    // We keep candidates outside of the Vote struct
    mapping(uint256 => mapping(uint256 => Candidate)) public _candidates;
    // Number of candidates for each vote
    mapping(uint256 => uint256) public _voteCandidateCount;
    // Counter for generating unique vote IDs
    uint256 public numberOfVotes;
    // Temporarily stores decrypted votes
    mapping(uint256 => mapping(uint256 => uint64)) public decryptedVotes;
    // Counter for generating unique vote IDs
    mapping(uint256 => uint256) public decryptedVotesReceived;

    euint64 private _number;
    euint64 private _sum;
    uint64 public _numberDecrypted;
    constructor(uint64 number_, address[] memory allowedVoters) IdentityManager(allowedVoters) Ownable(msg.sender) {
        _number = TFHE.asEuint64(number_);
        TFHE.allowThis(_number); // Permite o contrato acessar o valor criptografado
    }

    function createVote(
        uint256 endBlock,
        string[] calldata candidates,
        string calldata description
    ) external onlyOwner {
        uint256 voteId = numberOfVotes;
        _votes[voteId] = Vote(endBlock, TFHE.asEuint64(0), 0, 0, description, VoteState.Created);
        TFHE.allow(_votes[voteId].encryptedResult, address(this));

        for (uint256 i = 0; i < candidates.length; i++) {
            _candidates[voteId][i] = Candidate(candidates[i], TFHE.asEuint64(0));
            TFHE.allow(_candidates[voteId][i].votes, address(this));
        }

        _voteCandidateCount[voteId] = candidates.length;

        numberOfVotes++;
        emit VoteCreated(voteId);
    }

    function castVote(uint256 voteId, einput encryptedSupport, bytes calldata supportProof) external {
        bytes32 voterId = verifyProofAndGetVoterId();
        if (_castedVotes[voteId][voterId]) revert AlreadyVoted();
        _castedVotes[voteId][voterId] = true;

        Vote storage vote = _getVote(voteId);
        if (block.number > vote.endBlock) revert VoteClosed();

        // Convert and validate the encrypted vote
        euint64 candidateIndex = TFHE.asEuint64(encryptedSupport, supportProof);

        ebool isCandidateIndexValid = TFHE.lt(candidateIndex, TFHE.asEuint64(_voteCandidateCount[voteId]));
        require(TFHE.isSenderAllowed(isCandidateIndexValid), "Invalid candidate.");

        // Increment the vote count for this specific vote
        vote.voteCount++;

        // Update vote tallies if vote is valid
        _candidates[voteId][candidateIndex].votes = TFHE.add(
            _candidates[voteId][candidateIndex].votes,
            TFHE.asEuint64(1)
        );

        TFHE.allow(_candidates[voteId][candidateIndex].votes, address(this));

        emit VoteCasted(voteId);
    }

    function getVote(uint256 voteId) external view returns (Vote memory) {
        return _getVote(voteId);
    }

    function hasVoted(uint256 voteId, bytes32 voterId) external view returns (bool) {
        return _castedVotes[voteId][voterId];
    }

    function number() public view returns (euint64) {
        return _number;
    }

    function getDoubleNumber() public view returns (euint64) {
        return _sum;
    }

    function doubleNumber() public {
        _sum = TFHE.add(_number, _number);
        TFHE.allowThis(_sum); // Permite acesso ao resultado da soma
    }

    function requestWinnerDecryption(uint256 voteId) external {
        Vote storage vote = _getVote(voteId);
        if (block.number <= vote.endBlock) revert VoteNotClosed();
        vote.state = VoteState.RequestedToReveal;
        emit VoteRevealRequested(voteId);

        uint256 numCandidates = _voteCandidateCount[voteId];

        uint256[] memory cts = new uint256[](1);

        for (uint256 i = 0; i < numCandidates; i++) {
            uint256;
            cts[0] = Gateway.toUint256(_candidates[voteId][i].votes);

            Gateway.requestDecryption(cts, this.callbackDecryption.selector, voteId, i, block.timestamp + 100, false);
        }
    }

    function callbackDecryption(uint256 voteId, uint64 candidateIndex, uint64 decryptedVoteCount) external onlyGateway {
        decryptedVotes[voteId][candidateIndex] = decryptedVoteCount;
        decryptedVotesReceived[voteId]++;

        if (decryptedVotesReceived[voteId] == _voteCandidateCount[voteId]) {
            determineWinner(voteId);
            _getVote(voteId).state = VoteState.Revealed;
            emit VoteRevealed(voteId);
        }
    }

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

        emit WinnerDeclared(voteId, _candidates[voteId][winnerIndex], maxVotes);
    }

    function blockNumber() public view returns (uint256) {
        return block.number; // or block.timestamp
    }

    function _getVote(uint256 voteId) internal view returns (Vote storage) {
        Vote storage vote = _votes[voteId];
        if (vote.endBlock == 0) revert VoteDoesNotExist();
        return vote;
    }
}
