// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Test } from "forge-std/Test.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import { SimpleVotingSystem } from '../src/SimpleVotingSystem.sol';
import { DeploySimpleVotingSystem } from '../script/DeploySimpleVotingSystem.s.sol';

contract SimpleVotingSystemTest is Test {
  
  DeploySimpleVotingSystem votingSystemDeployer;
  SimpleVotingSystem votingSystem;
  address admin = makeAddr("admin");
  address founder = makeAddr("founder");
  address voter1 = makeAddr("voter1");
  address voter2 = makeAddr("voter2");
  address voter3 = makeAddr("voter3");

  function setUp() public {
    votingSystemDeployer = new DeploySimpleVotingSystem();
    votingSystem = votingSystemDeployer.run();
    vm.startBroadcast();
    votingSystem.grantRole(votingSystem.ADMIN_ROLE(), admin);
    votingSystem.grantRole(votingSystem.FOUNDER_ROLE(), founder);
    vm.stopBroadcast();
  }

  function testAddCandidate() public {
    vm.startPrank(admin);
    votingSystem.updateWorkflowStatus(SimpleVotingSystem.WorkflowStatus.REGISTER_CANDIDATES);
    votingSystem.addCandidate("Alice");
    vm.stopPrank();

    SimpleVotingSystem.Candidate memory candidate = votingSystem.getCandidate(1);
    assertEq(candidate.name, "Alice");
    assertEq(candidate.id, 1);
  }

  function testUpdateWorkflowStatus() public {
    vm.startPrank(admin);
    votingSystem.updateWorkflowStatus(SimpleVotingSystem.WorkflowStatus.VOTE);
    vm.stopPrank();

    assertEq(uint(votingSystem.status()), uint(SimpleVotingSystem.WorkflowStatus.VOTE));
  }

  function testCannotVoteBeforeVotingPeriod() public {
    vm.startPrank(admin);
    votingSystem.updateWorkflowStatus(SimpleVotingSystem.WorkflowStatus.REGISTER_CANDIDATES);
    votingSystem.addCandidate("Alice");
    votingSystem.updateWorkflowStatus(SimpleVotingSystem.WorkflowStatus.VOTE);
    vm.stopPrank();

    try votingSystem.vote(1) {
      fail();
    } catch Error(string memory reason) {
      assertEq(reason, "Voting is not allowed at this time");
    }
  }

  function testVoteAfterVotingPeriod() public {
    vm.startPrank(admin);
    votingSystem.updateWorkflowStatus(SimpleVotingSystem.WorkflowStatus.REGISTER_CANDIDATES);
    votingSystem.addCandidate("Alice");
    votingSystem.updateWorkflowStatus(SimpleVotingSystem.WorkflowStatus.VOTE);
    vm.stopPrank();

    vm.warp(block.timestamp + 1 hours);
    votingSystem.vote(1);

    SimpleVotingSystem.Candidate memory candidate = votingSystem.getCandidate(1);
    assertEq(candidate.voteCount, 1);
  }

  function testDesignateWinner() public {
    vm.startPrank(admin);
    votingSystem.updateWorkflowStatus(SimpleVotingSystem.WorkflowStatus.REGISTER_CANDIDATES);
    votingSystem.addCandidate("Alice");
    votingSystem.addCandidate("Bob");
    votingSystem.updateWorkflowStatus(SimpleVotingSystem.WorkflowStatus.VOTE);
    vm.stopPrank();

    vm.warp(block.timestamp + 1 hours);
    
    vm.startPrank(voter1);
    votingSystem.vote(1);
    vm.stopPrank();
    
    vm.startPrank(voter2);
    votingSystem.vote(2);
    vm.stopPrank();

    vm.startPrank(voter3);
    votingSystem.vote(2);
    vm.stopPrank();

    vm.startPrank(admin);
    votingSystem.updateWorkflowStatus(SimpleVotingSystem.WorkflowStatus.COMPLETED);
    vm.stopPrank();

    SimpleVotingSystem.Candidate memory winner = votingSystem.designateWinner();
    assertEq(winner.name, "Bob");
  }

  function testSendFundsToCandidate() public {
    vm.startPrank(admin);
    votingSystem.updateWorkflowStatus(SimpleVotingSystem.WorkflowStatus.REGISTER_CANDIDATES);
    votingSystem.addCandidate("Alice");
    votingSystem.addCandidate("Bob");
    votingSystem.updateWorkflowStatus(SimpleVotingSystem.WorkflowStatus.FOUND_CANDIDATES);
    vm.stopPrank();

    vm.deal(founder, 1 ether);
  
    // Simulate sending funds
    vm.startPrank(founder);
    (bool sent, ) = address(votingSystem).call{value: 1 ether}(abi.encodeWithSignature("sendFundsToCandidate(uint256)", 1));
    vm.stopPrank();
    assertTrue(sent);
  }

  function testCandidatesCount() public {
    vm.startPrank(admin);
    votingSystem.updateWorkflowStatus(SimpleVotingSystem.WorkflowStatus.REGISTER_CANDIDATES);
    votingSystem.addCandidate("Alice");
    votingSystem.addCandidate("Bob");
    votingSystem.addCandidate("Charlie");
    vm.stopPrank();

    assertEq(votingSystem.getCandidatesCount(), 3);
  }

  function testTotalVotes() public {
    vm.startPrank(admin);
    votingSystem.updateWorkflowStatus(SimpleVotingSystem.WorkflowStatus.REGISTER_CANDIDATES);
    votingSystem.addCandidate("Alice");
    votingSystem.addCandidate("Bob");
    votingSystem.addCandidate("Charlie");
    votingSystem.updateWorkflowStatus(SimpleVotingSystem.WorkflowStatus.VOTE);
    vm.stopPrank();

    vm.warp(block.timestamp + 1 hours);

    vm.startPrank(voter1);
    votingSystem.vote(1);
    vm.stopPrank();

    vm.startPrank(voter2);
    votingSystem.vote(3);
    vm.stopPrank();

    vm.startPrank(voter3);
    votingSystem.vote(1);
    vm.stopPrank();

    assertEq(votingSystem.getTotalVotes(1), 2);
  }
}
