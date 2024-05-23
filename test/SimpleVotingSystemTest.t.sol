// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Test } from "forge-std/Test.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import { SimpleVotingSystem } from '../src/SimpleVotingSystem.sol';

contract SimpleVotingSystemTest is Test {
  
  SimpleVotingSystem votingSystem;
  address admin = makeAddr("admin");
  address founder = makeAddr("founder");
  address voter1 = makeAddr("voter1");
  address voter2 = makeAddr("voter2");
  address voter3 = makeAddr("voter3");

  function setUp() public {
    votingSystem = new SimpleVotingSystem();
    votingSystem.grantRole(votingSystem.ADMIN_ROLE(), admin);
    votingSystem.grantRole(votingSystem.FOUNDER_ROLE(), founder);
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
    vm.stopPrank();

    votingSystem.updateWorkflowStatus(SimpleVotingSystem.WorkflowStatus.VOTE);
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
    vm.stopPrank();

    vm.deal(founder, 1 ether);
  
    // Simulate sending funds
    vm.startPrank(founder);
    (bool sent, ) = address(votingSystem).call{value: 1 ether}(abi.encodeWithSignature("sendFundsToCandidate(uint256)", 1));
    vm.stopPrank();
    assertTrue(sent);
  }
}
