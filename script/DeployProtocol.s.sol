// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Script} from "forge-std/Script.sol";
import {Yiel} from "src/Yiel.sol";
import {YielEngine} from "src/YielEngine.sol";
import {ProofOfReserveFeedMock} from "test/mocks/ProofOfReserveFeedMock.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";

contract DeployProtocol is Script {
    function run() external returns (Yiel, YielEngine, ProofOfReserveFeedMock, HelperConfig) {
        HelperConfig config = new HelperConfig();

        (string memory tokenName, string memory tokenSymbol) = config.activeNetworkConfig();

        vm.startBroadcast();
        Yiel yiel = new Yiel(tokenName, tokenSymbol);
        YielEngine engine = new YielEngine(address(yiel));
        ProofOfReserveFeedMock por = new ProofOfReserveFeedMock(msg.sender, address(engine));
        
        yiel.transferOwnership(address(engine));
        engine.setProofOfReserveFeed(address(por));
        vm.stopBroadcast();

        return (yiel, engine, por, config);
    }
}
