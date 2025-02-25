// SPDX-License-Identifier: BSD-3-Clause-Clear

import "fhevm/lib/TFHE.sol";
import "fhevm/config/ZamaFHEVMConfig.sol";
import { GatewayCaller, Gateway } from "fhevm/gateway/GatewayCaller.sol";
import { SepoliaZamaGatewayConfig } from "fhevm/config/ZamaGatewayConfig.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IdentityManager } from "./IdentityManager.sol";
import { IVotingSystem } from "./interfaces/IVotingSystem.sol";

pragma solidity ^0.8.24;

contract VotingSystem is
    IVotingSystem,
    IdentityManager,
    SepoliaZamaFHEVMConfig,
    SepoliaZamaGatewayConfig,
    GatewayCaller,
    Ownable
{
    uint256 public numberOfVotes;
    mapping(uint256 => Vote) private _votes;
    mapping(uint256 => mapping(bytes32 => bool)) private _castedVotes;
    mapping(uint256 => mapping(uint256 => Candidate)) public _candidates;
    mapping(uint256 => uint256) public _voteCandidateCount;
    mapping(uint256 => mapping(uint256 => uint64)) public decryptedVotes;
    mapping(uint256 => uint256) public decryptedVotesReceived;

    constructor(address[] memory allowedVoters) IdentityManager(allowedVoters) Ownable(msg.sender) {}

    function createVote(
        uint256 endBlock,
        string[] calldata candidates,
        string calldata description
    ) external onlyOwner {
        uint256 voteId = numberOfVotes;

        _votes[voteId] = Vote(endBlock, 0, description, VoteState.NotCreated);

        for (uint256 i = 0; i < candidates.length; i++) {
            _candidates[voteId][i] = Candidate(candidates[i], TFHE.asEuint64(0));
            TFHE.allow(_candidates[voteId][i].votes, address(this));
        }

        _voteCandidateCount[voteId] = candidates.length;

        _votes[voteId].state = VoteState.Created;

        numberOfVotes++;
        emit VoteCreated(voteId, candidates);
    }

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

    function getVote(uint256 voteId) external view returns (Vote memory) {
        return _getVote(voteId);
    }

    function blockNumber() external view returns (uint256) {
        return block.number;
    }

    function _getVote(uint256 voteId) internal view returns (Vote storage) {
        Vote storage vote = _votes[voteId];
        if (vote.endBlock == 0) revert VoteDoesNotExist();
        return vote;
    }

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
}
