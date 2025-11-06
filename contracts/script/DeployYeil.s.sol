// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Script} from "forge-std/Script.sol";
import {Yeil} from "../src/Yeil.sol";
import {ProofOfReserveFeed} from "../src/oracles/ProofOfReserveFeed.sol";

contract DeployYeil is Script {
    function run() external returns (Yeil, ProofOfReserveFeed) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);

        // Deploy ProofOfReserveFeed first
        ProofOfReserveFeed proofFeed = new ProofOfReserveFeed(vm.addr(deployerPrivateKey));
        
        // Deploy Yeil token
        Yeil yeil = new Yeil(
            address(proofFeed),
            "Yeil Token",
            "YL"
        );

        vm.stopBroadcast();

        return (yeil, proofFeed);
    }
}
