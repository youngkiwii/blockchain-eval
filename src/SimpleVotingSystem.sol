// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract SimpleVotingSystem is AccessControl {

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant FOUNDER_ROLE = keccak256("FOUNDER_ROLE");

    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }

    enum WorkflowStatus {
        REGISTER_CANDIDATES,
        FOUND_CANDIDATES,
        VOTE,
        COMPLETED
    }
    
    mapping(uint => Candidate) public candidates;
    mapping(address => bool) public voters;
    mapping(address => uint256) public funds;
    uint[] private candidateIds;
    uint public votingStartTime;
    WorkflowStatus public status;

    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender), "Only the contract admin can perform this action");
        _;
    }

    modifier inWorkflowStatus(WorkflowStatus _status) {
        require(status == _status, "Invalid workflow status for this action");
        _;
    }
 
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
    }
 
    function addCandidate(string memory _name) public onlyAdmin inWorkflowStatus(WorkflowStatus.REGISTER_CANDIDATES) {
        require(bytes(_name).length > 0, "Candidate name cannot be empty");
        uint candidateId = candidateIds.length + 1;
        candidates[candidateId] = Candidate(candidateId, _name, 0);
        candidateIds.push(candidateId);
    }
 
    function vote(uint _candidateId) public inWorkflowStatus(WorkflowStatus.VOTE) {
		require(block.timestamp >= votingStartTime + 1 hours, "Voting is not allowed at this time");
        require(!voters[msg.sender], "You have already voted");
        require(_candidateId > 0 && _candidateId <= candidateIds.length, "Invalid candidate ID");
 
        voters[msg.sender] = true;
        candidates[_candidateId].voteCount += 1;
    }
 
    function getTotalVotes(uint _candidateId) public view returns (uint) {
        require(_candidateId > 0 && _candidateId <= candidateIds.length, "Invalid candidate ID");
        return candidates[_candidateId].voteCount;
    }
 
    function getCandidatesCount() public view returns (uint) {
        return candidateIds.length;
    }
 
    // Optional: Function to get candidate details by ID
    function getCandidate(uint _candidateId) public view returns (Candidate memory) {
        require(_candidateId > 0 && _candidateId <= candidateIds.length, "Invalid candidate ID");
        return candidates[_candidateId];
    }

    function updateWorkflowStatus(WorkflowStatus _status) public onlyAdmin {
        status = _status;

        if (status == WorkflowStatus.VOTE) {
            votingStartTime = block.timestamp;
        }
    }

	function designateWinner() public view inWorkflowStatus(WorkflowStatus.COMPLETED) returns (Candidate memory) {
		uint maxVotes = 0;
		uint winningCandidateId = 0;
		for (uint i = 1; i <= candidateIds.length; i++) {
			if (candidates[i].voteCount > maxVotes) {
				maxVotes = candidates[i].voteCount;
				winningCandidateId = i;
			}
		}
		return candidates[winningCandidateId];
	}

	function sendFundsToCandidate(uint _candidateId) public payable inWorkflowStatus(WorkflowStatus.FOUND_CANDIDATES) {
        require(hasRole(FOUNDER_ROLE, msg.sender), "Only founders can send funds");
        require(_candidateId > 0 && _candidateId <= candidateIds.length, "Invalid candidate ID");

        address payable candidateAddress = payable(msg.sender);
        candidateAddress.transfer(msg.value);
    }
}
