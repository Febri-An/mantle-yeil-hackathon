// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test, console2} from "forge-std/Test.sol";
import {YielEngine} from "src/YielEngine.sol";
import {Yiel} from "src/Yiel.sol";
import {DeployProtocol} from "script/DeployProtocol.s.sol";
import {ProofOfReserveFeedMock} from "./mocks/ProofOfReserveFeedMock.sol";

contract YielEngineTest is Test {
    YielEngine public engine;
    Yiel public token;
    ProofOfReserveFeedMock public por;
    
    address public owner;
    address public user1;
    address public user2;
    address public user3;
    
    uint256 constant INITIAL_RESERVES = 1_000_000e18;
    uint256 constant TOKENIZED_AMOUNT = 100e18;
    
    event DepositStock(address indexed account, uint256 indexed amount);
    event WithdrawStock(address indexed account, uint256 indexed amount, uint256 fee);
    event RoundCreated(uint256 indexed roundId, uint256 communityShare, uint256 ownerShare);
    event YieldClaimed(address indexed user, uint256 indexed round, uint256 amount);
    
    function setUp() public {
        owner = msg.sender;
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        user3 = makeAddr("user3");
        
        (token, engine, por, ) = new DeployProtocol().run();
        
        // Grant minter role to YieldEngine
        // token.grantRole(token.MINTER_ROLE(), address(engine));
        // token.grantRole(token.BURNER_ROLE(), address(engine));
        // token.grantRole(token.SNAPSHOT_ROLE(), address(engine));
        // token.transferOwnership(address(engine));
    }
    
    /*//////////////////////////////////////////////////////////////
                           CONSTRUCTOR TESTS
    //////////////////////////////////////////////////////////////*/
    
    function test_Constructor() public view {
        assertEq(address(engine.yielToken()), address(token));
        // assertEq(address(engine.proofOfReserveFeed()), address(por));
        assertEq(engine.owner(), owner);
        assertGt(engine.lastSnapshotTime(), 0);
    }
    
    function test_Constructor_RevertIf_InvalidYielAddress() public {
        vm.expectRevert(YielEngine.YielEngine__InvalidYielAddress.selector);
        new YielEngine(address(0));
        // new YielEngine(address(0), address(proofOfReserveFeed));
    }
    
    // function test_Constructor_RevertIf_InvalidPoRAddress() public {
    //     vm.expectRevert("Invalid PoR address");
    //     new YeildEngine(address(yeilToken), address(0));
    // }
    
    /*//////////////////////////////////////////////////////////////
                            DEPOSIT TESTS
    //////////////////////////////////////////////////////////////*/
    
    function test_TokenizeStock_Success() public {
        por.updateReserves(user1, int256(TOKENIZED_AMOUNT));

        vm.prank(user1);
        vm.expectEmit(true, true, false, true);
        emit YielEngine.TokenizeStock(user1, TOKENIZED_AMOUNT);
        engine.tokenizeStock(TOKENIZED_AMOUNT);
        
        assertEq(token.balanceOf(user1), TOKENIZED_AMOUNT);
    }
    
    function test_TokenizeStock_MaxAmount() public {
        por.updateReserves(user1, int256(TOKENIZED_AMOUNT));

        uint256 initialBalance = token.getBalance(user1);
        vm.prank(user1);
        engine.tokenizeStock(type(uint256).max);
        
        assertEq(token.balanceOf(user1), initialBalance + TOKENIZED_AMOUNT);
    }
    
    function test_TokenizeStock_RevertIf_ZeroAmount() public {
        vm.prank(user1);
        vm.expectRevert(YielEngine.YielEngine__InvalidAmount.selector);
        engine.tokenizeStock(0);
    }
    
    function test_TokenizeStock_RevertIf_MaxAmountButZeroBalance() public {
        vm.prank(user1);
        vm.expectRevert(YielEngine.YielEngine__InsufficientBalance.selector);
        engine.tokenizeStock(type(uint256).max);
    }
    
    // function test_TokenizeStock_MultipleUsers() public {
    //     vm.prank(user1);
    //     engine.tokenizeStock(TOKENIZED_AMOUNT);
        
    //     vm.prank(user2);
    //     engine.tokenizeStock(TOKENIZED_AMOUNT * 2);
        
    //     assertEq(token.balanceOf(user1), TOKENIZED_AMOUNT);
    //     assertEq(token.balanceOf(user2), TOKENIZED_AMOUNT * 2);
    // }
    
    // /*//////////////////////////////////////////////////////////////
    //                        WITHDRAW TESTS
    // //////////////////////////////////////////////////////////////*/

    modifier tokenizedStock() {
        por.updateReserves(user1, int256(TOKENIZED_AMOUNT));
        vm.prank(user1);
        engine.tokenizeStock(TOKENIZED_AMOUNT);
        _;
    }
    
    function test_RedeemStock_Success() public tokenizedStock {
        assertEq(token.balanceOf(user1), TOKENIZED_AMOUNT);
        uint256 fee = (TOKENIZED_AMOUNT * engine.FEE_PERCENTAGE()) / engine.DIVISOR();
        uint256 amountAfterFee = TOKENIZED_AMOUNT - fee;
        
        vm.startPrank(user1);
        token.approve(address(engine), fee);

        vm.expectEmit(true, true, false, true);
        emit YielEngine.RedeemStock(user1, amountAfterFee);
        engine.redeemStock(TOKENIZED_AMOUNT);
        vm.stopPrank();
        
        assertEq(token.balanceOf(user1), 0);
        assertEq(token.balanceOf(address(engine)), fee);
    }
    
    function test_RedeemStock_MaxAmount() public tokenizedStock {
        uint256 fee = (TOKENIZED_AMOUNT * engine.FEE_PERCENTAGE()) / engine.DIVISOR();
        vm.startPrank(user1);
        token.approve(address(engine), fee);
        engine.redeemStock(type(uint256).max);
        vm.stopPrank();
        
        assertEq(token.balanceOf(user1), 0);
        assertEq(token.balanceOf(address(engine)), fee);
    }
    
    function test_RedeemStock_PartialAmount() public tokenizedStock {
        uint256 withdrawAmount = TOKENIZED_AMOUNT / 2;
        uint256 fee = (withdrawAmount * engine.FEE_PERCENTAGE()) / engine.DIVISOR();
        
        vm.startPrank(user1);
        token.approve(address(engine), fee);
        engine.redeemStock(withdrawAmount);
        vm.stopPrank();
        
        assertEq(token.balanceOf(user1), TOKENIZED_AMOUNT - withdrawAmount);
        assertEq(token.balanceOf(address(engine)), fee);
    }
    
    function test_RedeemStock_RevertIf_InsufficientBalance() public {
        vm.prank(user1);
        vm.expectRevert(YielEngine.YielEngine__InsufficientBalance.selector);
        engine.redeemStock(TOKENIZED_AMOUNT);
    }
    
    function test_RedeemStock_RevertIf_ZeroAmount() public tokenizedStock {
        vm.prank(user1);
        vm.expectRevert(YielEngine.YielEngine__InvalidAmount.selector);
        engine.redeemStock(0);
    }
    
    function test_RedeemStock_RevertIf_AmountExceedsBalance() public tokenizedStock {
        vm.prank(user1);
        vm.expectRevert(YielEngine.YielEngine__InsufficientBalance.selector);
        engine.redeemStock(TOKENIZED_AMOUNT * 2);
    }
    
    function test_RedeemStock_UpdatesReserves() public tokenizedStock {
        uint256 withdrawAmount = TOKENIZED_AMOUNT;
        uint256 fee = (withdrawAmount * engine.FEE_PERCENTAGE()) / engine.DIVISOR();
        
        int256 reservesBefore = por.getLatestVerifiedReserves();

        vm.startPrank(user1);
        token.approve(address(engine), fee);
        engine.redeemStock(withdrawAmount);
        vm.stopPrank();
        
        int256 reservesAfter = por.getLatestVerifiedReserves();
        assertEq(reservesAfter, reservesBefore - int256(TOKENIZED_AMOUNT));
    }
    
    /*//////////////////////////////////////////////////////////////
                         CREATE ROUND TESTS
    //////////////////////////////////////////////////////////////*/

    modifier redeemedStock(uint256 divider) {
        uint256 withdrawAmount = TOKENIZED_AMOUNT;
        uint256 fee = (withdrawAmount * engine.FEE_PERCENTAGE()) / engine.DIVISOR();

        vm.startPrank(user1);
        token.approve(address(engine), fee);
        engine.redeemStock(TOKENIZED_AMOUNT / divider);
        vm.stopPrank();
        _;
    }
    
    function test_CreateRound_Success() public tokenizedStock redeemedStock(1) {
        uint256 contractBalance = token.balanceOf(address(engine));
        uint256 communityShare = (contractBalance * engine.COMMUNITY_SHARE()) / engine.DIVISOR();
        uint256 ownerShare = (contractBalance * engine.OWNER_SHARE()) / engine.DIVISOR();
        
        // Fast forward time
        vm.warp(block.timestamp + engine.YIELD_INTERVAL() + 1);
        
        vm.prank(msg.sender);
        vm.expectEmit(true, false, false, true);
        emit YielEngine.RoundCreated(1, communityShare, ownerShare);
        engine.createRound();
        
        assertEq(engine.currentRound(), 1);
        assertEq(engine.roundToAmount(1), communityShare);
        assertEq(token.balanceOf(owner), ownerShare);
    }
    
    function test_CreateRound_RevertIf_IntervalNotMet() public tokenizedStock redeemedStock(1) {
        // Don't fast forward enough time
        vm.warp(block.timestamp + engine.YIELD_INTERVAL() - 1);
        
        vm.prank(msg.sender);
        vm.expectRevert(YielEngine.YielEngine__SnapshotIntervalNotMet.selector);
        engine.createRound();
    }
    
    function test_CreateRound_RevertIf_InsufficientBalance() public {
        vm.warp(block.timestamp + engine.YIELD_INTERVAL() + 1);
        
        vm.prank(msg.sender);
        vm.expectRevert(YielEngine.YielEngine__InsufficientBalance.selector);
        engine.createRound();
    }
    
    function test_CreateRound_RevertIf_NotOwner() public tokenizedStock redeemedStock(1) {
        vm.warp(block.timestamp + engine.YIELD_INTERVAL() + 1);
        
        vm.prank(user1);
        vm.expectRevert();
        engine.createRound();
    }
    
    function test_CreateRound_MultipleRounds() public tokenizedStock redeemedStock(2) {
        vm.warp(block.timestamp + engine.YIELD_INTERVAL() + 1);
        vm.prank(msg.sender);
        engine.createRound();
        
        // Round 2
        por.updateReserves(user1, int256(TOKENIZED_AMOUNT) * 2);
        vm.prank(user1);
        engine.tokenizeStock(TOKENIZED_AMOUNT * 2);

        uint256 withdrawAmount = TOKENIZED_AMOUNT;
        uint256 fee = (withdrawAmount * engine.FEE_PERCENTAGE()) / engine.DIVISOR();

        vm.startPrank(user1);
        token.approve(address(engine), fee);
        engine.redeemStock(TOKENIZED_AMOUNT);
        vm.stopPrank();
        
        vm.warp(block.timestamp + engine.YIELD_INTERVAL() + 1);
        vm.prank(msg.sender);
        engine.createRound();
        
        assertEq(engine.currentRound(), 2);
        assertGt(engine.roundToAmount(1), 0);
        assertGt(engine.roundToAmount(2), 0);
    }
    
    // /*//////////////////////////////////////////////////////////////
    //                      CLAIM YIELD TESTS
    // //////////////////////////////////////////////////////////////*/

    modifier tokenizedStock2() {
        por.updateReserves(user2, int256(TOKENIZED_AMOUNT * 2));
        vm.prank(user2);
        engine.tokenizeStock(TOKENIZED_AMOUNT * 2);
        _;
    }

    modifier redeemedStock2(uint256 divider) {
        uint256 withdrawAmount = TOKENIZED_AMOUNT;
        uint256 fee = (withdrawAmount * engine.FEE_PERCENTAGE()) / engine.DIVISOR();

        vm.startPrank(user2);
        token.approve(address(engine), fee);
        engine.redeemStock(TOKENIZED_AMOUNT / divider);
        vm.stopPrank();
        _;
    }
    
    function test_ClaimYield_Success() public tokenizedStock tokenizedStock2 redeemedStock2(1) {
        // Create round
        vm.warp(block.timestamp + engine.YIELD_INTERVAL() + 1);
        vm.prank(msg.sender);
        engine.createRound();
        
        uint256 claimableYield = engine.getClaimableYield(user1, 1);
        assertGt(claimableYield, 0);
        
        uint256 balanceBefore = token.balanceOf(user1);
        
        vm.prank(user1);
        vm.expectEmit(true, true, false, true);
        emit YielEngine.YieldClaimed(user1, 1, claimableYield);
        engine.claimYield(1);
        
        assertEq(token.balanceOf(user1), balanceBefore + claimableYield);
        assertTrue(engine.hasClaimed(user1, 1));
    }
    
    function test_ClaimYield_MultipleUsers() public tokenizedStock tokenizedStock2 {
        // Generate fees from user3
        por.updateReserves(user3, int256(TOKENIZED_AMOUNT));
        vm.prank(user3);
        engine.tokenizeStock(TOKENIZED_AMOUNT);

        uint256 withdrawAmount = TOKENIZED_AMOUNT;
        uint256 fee = (withdrawAmount * engine.FEE_PERCENTAGE()) / engine.DIVISOR();

        vm.startPrank(user3);
        token.approve(address(engine), fee);
        engine.redeemStock(TOKENIZED_AMOUNT);
        vm.stopPrank();
        
        // Create round
        vm.warp(block.timestamp + engine.YIELD_INTERVAL() + 1);
        vm.prank(msg.sender);
        engine.createRound();
        
        uint256 user1Yield = engine.getClaimableYield(user1, 1);
        uint256 user2Yield = engine.getClaimableYield(user2, 1);
        
        // User2 should get more yield since they have more tokens
        assertGt(user2Yield, user1Yield);
        
        vm.prank(user1);
        engine.claimYield(1);
        
        vm.prank(user2);
        engine.claimYield(1);
        
        assertTrue(engine.hasClaimed(user1, 1));
        assertTrue(engine.hasClaimed(user2, 1));
    }
    
    function test_ClaimYield_RevertIf_InvalidRound() public {
        vm.prank(user1);
        vm.expectRevert(YielEngine.YielEngine__InvalidRound.selector);
        engine.claimYield(0);
        
        vm.prank(user1);
        vm.expectRevert(YielEngine.YielEngine__InvalidRound.selector);
        engine.claimYield(999);
    }
    
    // function test_ClaimYield_RevertIf_RoundNotCreated() public {
    //     // Manually set currentRound without creating actual round
    //     vm.store(
    //         address(engine),
    //         bytes32(uint256(5)), // Storage slot for currentRound
    //         bytes32(uint256(1))
    //     );
        
    //     vm.prank(user1);
    //     vm.expectRevert(YielEngine.YielEngine__RoundNotCreated.selector);
    //     engine.claimYield(1);
    // }
    
    function test_ClaimYield_RevertIf_AlreadyClaimed() public tokenizedStock tokenizedStock2 redeemedStock2(2) {        
        vm.warp(block.timestamp + engine.YIELD_INTERVAL() + 1);
        vm.prank(msg.sender);
        engine.createRound();
        
        vm.prank(user1);
        engine.claimYield(1);
        
        // Try to claim again
        vm.prank(user1);
        vm.expectRevert(YielEngine.YielEngine__NothingToClaim.selector);
        engine.claimYield(1);
    }
    
    function test_ClaimYield_RevertIf_NoBalance() public tokenizedStock redeemedStock(2) {     
        vm.warp(block.timestamp + engine.YIELD_INTERVAL() + 1);
        vm.prank(msg.sender);
        engine.createRound();
        
        // User2 never deposited, so should have nothing to claim
        vm.prank(user2);
        vm.expectRevert(YielEngine.YielEngine__NothingToClaim.selector);
        engine.claimYield(1);
    }
    
    /*//////////////////////////////////////////////////////////////
                           VIEW FUNCTION TESTS
    //////////////////////////////////////////////////////////////*/
    
    function test_GetClaimableYield() public tokenizedStock tokenizedStock2 redeemedStock2(1) {
        vm.warp(block.timestamp + engine.YIELD_INTERVAL() + 1);

        vm.prank(msg.sender);
        engine.createRound();
        
        uint256 claimableYield = engine.getClaimableYield(user1, 1);
        assertGt(claimableYield, 0);
        
        // After claiming, should be 0
        vm.prank(user1);
        engine.claimYield(1);
        
        assertEq(engine.getClaimableYield(user1, 1), 0);
    }
    
    function test_IsFullyBacked_True() public tokenizedStock {
        console2.log("Lates verified reserve:", por.getLatestVerifiedReserves());
        assertTrue(engine.isFullyBacked());
    }
    
    function test_IsFullyBacked_False() public {
        vm.prank(address(engine));
        token.mint(address(engine), 100e18);
        assertFalse(engine.isFullyBacked());
    }
    
    function test_GetVerifiedReserves() public {
        por.updateReserves(user1, int256(TOKENIZED_AMOUNT));
        int256 reserves = engine.getVerifiedReserves();
        assertEq(reserves, int256(TOKENIZED_AMOUNT));
    }
    
    function test_TimeUntilNextRound() public {
        uint256 timeUntil = engine.timeUntilNextRound();
        assertEq(timeUntil, engine.YIELD_INTERVAL());
        
        vm.warp(block.timestamp + engine.YIELD_INTERVAL() + 1);
        
        timeUntil = engine.timeUntilNextRound();
        assertEq(timeUntil, 0);
    }
    
    // /*//////////////////////////////////////////////////////////////
    //                       INTEGRATION TESTS
    // //////////////////////////////////////////////////////////////*/
    
    function test_FullWorkflow() public tokenizedStock tokenizedStock2 redeemedStock(2) {
        // Create first round
        vm.warp(block.timestamp + engine.YIELD_INTERVAL() + 1);
        vm.prank(msg.sender);
        engine.createRound();
        
        // Check claimable yields
        uint256 user1Yield = engine.getClaimableYield(user1, 1);
        uint256 user2Yield = engine.getClaimableYield(user2, 1);
        
        assertGt(user1Yield, 0);
        assertGt(user2Yield, user1Yield); // user2 has more tokens
        
        // Users claim yields
        vm.prank(user1);
        engine.claimYield(1);
        
        vm.prank(user2);
        engine.claimYield(1);
        
        // Generate more fees
        uint256 withdrawAmount = TOKENIZED_AMOUNT;
        uint256 fee = (withdrawAmount * engine.FEE_PERCENTAGE()) / engine.DIVISOR();

        vm.startPrank(user2);
        token.approve(address(engine), fee);
        engine.redeemStock(TOKENIZED_AMOUNT / 2);
        vm.stopPrank();
        
        // Create second round
        vm.warp(block.timestamp + engine.YIELD_INTERVAL() + 1);
        vm.prank(msg.sender);
        engine.createRound();
        
        // Verify second round works
        assertEq(engine.currentRound(), 2);
        assertGt(engine.roundToAmount(2), 0);
    }
    
    function testFuzz_Deposit(uint256 amount) public {
        amount = bound(amount, 1, 1_000_000e18);
        
        vm.prank(user1);
        engine.tokenizeStock(amount);
        
        assertEq(token.balanceOf(user1), amount);
    }
    
    function testFuzz_RedeemStock(uint256 tokenizedAmount, uint256 redeemAmount) public {
        tokenizedAmount = bound(tokenizedAmount, 100, 1_000_000e18);
        redeemAmount = bound(redeemAmount, 1, tokenizedAmount);
        
        por.updateReserves(user1, int256(tokenizedAmount));
        vm.prank(user1);
        engine.tokenizeStock(tokenizedAmount);
        
        uint256 fee = (redeemAmount * engine.FEE_PERCENTAGE()) / engine.DIVISOR();
        
        vm.startPrank(user1);
        token.approve(address(engine), redeemAmount);
        engine.redeemStock(redeemAmount);
        vm.stopPrank();
        
        assertEq(token.balanceOf(address(engine)), fee);
    }
}