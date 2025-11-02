// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/**
 * @title IProofOfReserveFeed
 * @notice Interface for accessing verified reserve data from a Proof of Reserve oracle feed
 * @dev This interface is typically implemented by oracle contracts that provide
 * verified on-chain proof of off-chain asset reserves
 */
interface IProofOfReserveFeed {
    function latestVerifiedReserves() external view returns (uint256);
    function lastUpdatedAt() external view returns (uint256);
}
