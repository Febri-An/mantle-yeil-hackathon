// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {Yeil} from "src/Yeil.sol";
import {DeployYeil} from "script/DeployYeil.s.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";

contract YeilTest is Test {
    Yeil yeil;
    DeployYeil deployer;
    HelperConfig config;

    string private constant TOKEN_NAME = "AAPL Yeil Token";
    string private constant TOKEN_SYMBOL = "AAPLY";

    function setUp() public {
        deployer = new DeployYeil();
        (yeil, config) = deployer.run();
    }

    function testOwner() public view {
        address expectedOwner = address(msg.sender);
        address owner = yeil.owner();
        assert(owner == expectedOwner);
    }

    function testTokenName() public view {
        string memory expectedName = TOKEN_NAME;
        string memory tokenName = yeil.getTokenName();
        assert(keccak256(abi.encodePacked(expectedName)) == keccak256(abi.encodePacked(tokenName)));
    }

    function testTokenSymbol() public view {
        string memory expectedSymbol = TOKEN_SYMBOL;
        string memory tokenSymbol = yeil.getTokenSymbol();
        assert(keccak256(abi.encodePacked(expectedSymbol)) == keccak256(abi.encodePacked(tokenSymbol)));
    }

    /*//////////////////////////////////////////////////////////////
                                SNAPSHOT
    //////////////////////////////////////////////////////////////*/
    function testBalanceOfAt() public {
        vm.roll(1);
        vm.prank(msg.sender);
        uint48 snapshotId = yeil.snapshot(); // Create a snapshot at block 1

        uint256 balance = yeil.balanceOfAt(address(msg.sender), snapshotId);
        assert(balance == 0);
    }

    function testTotalSupplyAt() public {
        vm.roll(1);
        vm.prank(msg.sender);
        uint48 snapshotId = yeil.snapshot(); // Create a snapshot at block 1
        
        uint256 totalSupply = yeil.totalSupplyAt(snapshotId);
        assert(totalSupply == 0);
    }
}
