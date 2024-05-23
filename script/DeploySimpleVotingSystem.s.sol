// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { Script } from "forge-std/Script.sol";
import { SimpleVotingSystem } from "../src/SimpleVotingSystem.sol";

contract DeploySimpleVotingSystem is Script {

  function run() external returns (SimpleVotingSystem) {
    vm.startBroadcast();
    SimpleVotingSystem simpleVotingSystem = new SimpleVotingSystem();
    vm.stopBroadcast();
    return simpleVotingSystem;
  }

}
