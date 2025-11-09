// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Script} from "forge-std/Script.sol";
import {ProofOfReserveFeed} from "src/oracles/ProofOfReserveFeed.sol";

contract DeployPorFeed is Script {
    function run() external returns (ProofOfReserveFeed) {
        vm.startBroadcast();
        ProofOfReserveFeed porFeed = new ProofOfReserveFeed(msg.sender);
        vm.stopBroadcast();

        return porFeed;
    }
}