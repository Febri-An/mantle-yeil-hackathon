// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Script} from "forge-std/Script.sol";
import {Yeil} from "src/Yeil.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";

contract DeployYeil is Script {
    function run() external returns (Yeil, HelperConfig) {
        HelperConfig config = new HelperConfig();

        (
            address proofOfReserveFeed,
            string memory tokenName, 
            string memory tokenSymbol
        ) = config.activeNetworkConfig();

        vm.startBroadcast();
        Yeil yeil = new Yeil(
            proofOfReserveFeed,
            tokenName,
            tokenSymbol
        );
        vm.stopBroadcast();
        
        return (yeil, config);
    }
}
