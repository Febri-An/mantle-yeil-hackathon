// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Script} from "forge-std/Script.sol";
import {ProofOfReserveFeedMock} from "test/mocks/ProofOfReserveFeedMock.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        string tokenName;
        string tokenSymbol;
    }

    string private constant TOKEN_NAME = "AAPL Yiel Token";
    string private constant TOKEN_SYMBOL = "AAPLY";
    uint256 private DEFAULT_ANVIL_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    NetworkConfig public activeNetworkConfig;

    constructor() {
        if (block.chainid == 5001) {
            activeNetworkConfig = getMentleTestnetConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    // should be configure with actual ProofOfReserveFeed from Chainlink on testnet soon
    function getMentleTestnetConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            tokenName: TOKEN_NAME,
            tokenSymbol: TOKEN_SYMBOL
        });
    }

    function getOrCreateAnvilEthConfig() public view returns (NetworkConfig memory) {
        if (bytes(activeNetworkConfig.tokenName).length != 0) {
            return activeNetworkConfig;
        }

        return NetworkConfig({
            tokenName: TOKEN_NAME,
            tokenSymbol: TOKEN_SYMBOL
        });
    }
}
