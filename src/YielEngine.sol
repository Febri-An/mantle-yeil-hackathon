// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Yiel} from "src/Yiel.sol";
import {IProofOfReserveFeed} from "src/interfaces/IProofOfReserveFeed.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title YielEngine
 * @notice Manages yield distribution for staked YIEL tokens with proof of reserves
 * @dev Enhanced version with security improvements and gas optimizations
 */
contract YielEngine is Ownable, ReentrancyGuard {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error YielEngine__InvalidYielAddress();
    error YielEngine__InvalidProofOfReserveAddress();
    error YielEngine__InsufficientBalance();
    error YielEngine__InvalidAmount();
    error YielEngine__InvalidRound();
    error YielEngine__RoundNotCreated();
    error YielEngine__SnapshotIntervalNotMet();
    error YielEngine__NothingToClaim();
    error YielEngine__TransferFailed();

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    uint256 public constant YIELD_INTERVAL = 365 days;  // At least more than 365 days
    uint256 public constant FEE_PERCENTAGE = 2;         // 2% fee for protocol
    uint256 public constant OWNER_SHARE = 20;           // 20% of collected fee
    uint256 public constant COMMUNITY_SHARE = 80;       // 80% of collected fee
    uint256 public constant DIVISOR = 100;              // Used to calculate fee percentage

    Yiel public immutable yielToken;
    IProofOfReserveFeed public proofOfReserveFeed;

    uint256 public currentRound;
    uint256 public lastSnapshotTime;

    mapping(uint256 round => uint256 amount) public roundToAmount;
    mapping(address account => mapping(uint256 round=> bool claimed)) public hasClaimed;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event TokenizeStock(address indexed account, uint256 indexed amount);
    event RedeemStock(address indexed account, uint256 indexed amount);
    event YieldClaimed(address indexed user, uint256 indexed round, uint256 amount);
    event RoundCreated(uint256 indexed roundId, uint256 communityShare, uint256 ownerShare);

    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    constructor(
        address yielAddress
        // address proofOfReserveFeedAddress
    ) Ownable(msg.sender) {
        if (yielAddress == address(0)) {
            revert YielEngine__InvalidYielAddress();
        }
        // if (proofOfReserveFeedAddress == address(0)) {
        //     revert YielEngine__InvalidProofOfReserveAddress();
        // }

        yielToken = Yiel(yielAddress);
        // proofOfReserveFeed = IProofOfReserveFeed(proofOfReserveFeedAddress);
        lastSnapshotTime = block.timestamp;
    }

    /*//////////////////////////////////////////////////////////////
                            EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    function setProofOfReserveFeed(address proofOfReserveFeedAddress) external onlyOwner {
        if (proofOfReserveFeedAddress == address(0)) {
            revert YielEngine__InvalidProofOfReserveAddress();
        }
        proofOfReserveFeed = IProofOfReserveFeed(proofOfReserveFeedAddress);
    }

    /**
     * @notice Tokenize stock holdings into YIEL tokens
     * @param amount Amount to tokenize (use type(uint256).max for full balance)
     */
    function tokenizeStock(uint256 amount) external nonReentrant {
        if (amount <= 0) {
            revert YielEngine__InvalidAmount();
        }
        if (amount == type(uint256).max) {
            amount = uint256(proofOfReserveFeed.getAddressToAmount(msg.sender));
        }
        if (amount == 0) {
            revert YielEngine__InsufficientBalance();
        }
        uint256 currentBalance = yielToken.getBalance(msg.sender);
        uint256 amountToMint = amount - currentBalance;
        emit TokenizeStock(msg.sender, amountToMint);
        yielToken.mint(msg.sender, amountToMint);
    }

    /**
     * @notice Redeem YIEL tokens back to stock with 2% fee
     * @param amount Amount to redeem (use type(uint256).max for full balance)
     */
    function redeemStock(uint256 amount) external nonReentrant {
        uint256 userBalance = yielToken.getBalance(msg.sender);
        if (userBalance <= 0) {
            revert YielEngine__InsufficientBalance();
        }
        if (amount == 0) {
            revert YielEngine__InvalidAmount();
        }
        if (amount == type(uint256).max) {
            amount = userBalance;
        } else if (amount > userBalance) {
            revert YielEngine__InsufficientBalance();
        }

        // Update reserves before burning
        proofOfReserveFeed.updateReserves(msg.sender, -int256(amount));

        uint256 fee = amount * FEE_PERCENTAGE / DIVISOR;
        uint256 amountAfterFee = amount - fee;
        
        // Transfer fee to contract
        yielToken.transferFrom(msg.sender, address(this), fee);

        // Burn user's tokens (after fee)
        yielToken.burn(msg.sender, amountAfterFee);
        emit RedeemStock(msg.sender, amountAfterFee);
    }

    /**
     * @notice Claim yield from a specific round
     * @param round The round to claim from
     */
    function claimYield(uint256 round) external nonReentrant {
        if (round <= 0 || round > currentRound) {
            revert YielEngine__InvalidRound();
        }
        // if (roundToAmount[round] == 0) {
        //     revert YielEngine__RoundNotCreated();
        // }
        if (hasClaimed[msg.sender][round]) {
            revert YielEngine__NothingToClaim();
        }
        uint256 yieldAmount = _calculateYield(msg.sender, round);
        if (yieldAmount == 0) revert YielEngine__NothingToClaim();

        // Update state
        hasClaimed[msg.sender][round] = true;

        // yielToken.transferFrom(address(this), msg.sender, yieldAmount);
        bool success = yielToken.transfer(msg.sender, yieldAmount); // 🔴🟠🟡 need to test
        if (!success) revert YielEngine__TransferFailed();

        emit YieldClaimed(msg.sender, round, yieldAmount);
    }

    /**
     * @notice Create a new yield distribution round (owner only)
     */
    function createRound() external onlyOwner nonReentrant {
        if (block.timestamp < lastSnapshotTime + YIELD_INTERVAL) {
            revert YielEngine__SnapshotIntervalNotMet();
        }

        uint256 contractBalance = yielToken.getBalance(address(this));
        if (contractBalance <= 0) {
            revert YielEngine__InsufficientBalance();
        }

        // Create snapshot
        uint256 snapshotId = yielToken.snapshot();
        lastSnapshotTime = block.timestamp;
        currentRound = snapshotId + 1;

        // Calculate shares
        uint256 communityShare = (contractBalance * COMMUNITY_SHARE) / DIVISOR;
        uint256 ownerShare = (contractBalance * OWNER_SHARE) / DIVISOR;
        
        // Store community share for this round
        roundToAmount[snapshotId + 1] = communityShare;

        // Transfer owner share
        bool success = yielToken.transfer(owner(), ownerShare);
        if (!success) revert YielEngine__TransferFailed();
        
        emit RoundCreated(snapshotId + 1, communityShare, ownerShare);
    }

    /*//////////////////////////////////////////////////////////////
                            PUBLIC FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    function getClaimableYield(address user, uint256 round) public view returns (uint256) {
        if (hasClaimed[user][round]) {
            return 0;
        }
        return _calculateYield(user, round);
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /**
     * @dev Internal function to calculate yield
     */
    function _calculateYield(address user, uint256 round) internal view returns (uint256) {
        uint256 userBalance = yielToken.balanceOfAt(user, round - 1);
        if (userBalance == 0) return 0;
        
        uint256 totalRoundAmount = roundToAmount[round];
        if (totalRoundAmount == 0) return 0;
        
        uint256 totalSupply = yielToken.totalSupplyAt(round - 1);
        if (totalSupply == 0) return 0;
        
        return (userBalance * totalRoundAmount) / totalSupply;
    }

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /**
     * @dev Check if the token is fully backed by reserves
     * @return bool True if fully backed, false otherwise
     */
    function isFullyBacked() public view returns (bool) {
        return
            IERC20(address(yielToken)).totalSupply() <=
            uint256(getVerifiedReserves());
    }

    /**
     * @dev Get the latest verified reserve amount from the oracle feed
     */
    function getVerifiedReserves() public view returns (int256) {
        return proofOfReserveFeed.getLatestVerifiedReserves();
    }

    /**
     * @notice Get the time until next round can be created
     * @return Time in seconds (0 if can create now)
     */
    function timeUntilNextRound() external view returns (uint256) {
        uint256 nextAllowedTime = lastSnapshotTime + YIELD_INTERVAL;
        if (block.timestamp >= nextAllowedTime) {
            return 0;
        }
        return nextAllowedTime - block.timestamp;
    }
}
