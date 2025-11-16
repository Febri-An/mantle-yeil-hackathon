// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {Yiel} from "src/Yiel.sol";
import {YielEngine} from "src/YielEngine.sol";
import {DeployProtocol} from "script/DeployProtocol.s.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";

contract YielTest is Test {
    Yiel yiel;
    YielEngine engine;
    DeployProtocol deployer;
    HelperConfig config;

    string private constant TOKEN_NAME = "AAPL Yiel Token";
    string private constant TOKEN_SYMBOL = "AAPLY";

    function setUp() public {
        deployer = new DeployProtocol();
        console.log('msg.sender address:', msg.sender);
        console.log('address this:', address(this));
        (yiel, engine,, config) = deployer.run();
    }

    function testOwner() public view {
        address expectedOwner = address(engine);
        address owner = yiel.owner();
        assert(owner == expectedOwner);
    }

    function testTokenName() public view {
        string memory expectedName = TOKEN_NAME;
        string memory tokenName = yiel.getTokenName();
        assert(keccak256(abi.encodePacked(expectedName)) == keccak256(abi.encodePacked(tokenName)));
    }

    function testTokenSymbol() public view {
        string memory expectedSymbol = TOKEN_SYMBOL;
        string memory tokenSymbol = yiel.getTokenSymbol();
        assert(keccak256(abi.encodePacked(expectedSymbol)) == keccak256(abi.encodePacked(tokenSymbol)));
    }

    /*//////////////////////////////////////////////////////////////
                                SNAPSHOT
    //////////////////////////////////////////////////////////////*/
    function testBalanceOfAt() public {
        vm.roll(1);
        vm.prank(address(engine));
        uint48 snapshotId = yiel.snapshot(); // Create a snapshot at block 1

        uint256 balance = yiel.balanceOfAt(address(msg.sender), snapshotId);
        assert(balance == 0);
    }

    function testTotalSupplyAt() public {
        vm.roll(1);
        vm.prank(address(engine));
        uint48 snapshotId = yiel.snapshot(); // Create a snapshot at block 1
        
        uint256 totalSupply = yiel.totalSupplyAt(snapshotId);
        assert(totalSupply == 0);
    }
}
