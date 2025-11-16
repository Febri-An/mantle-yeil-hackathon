// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {IProofOfReserveFeed} from "src/interfaces/IProofOfReserveFeed.sol";

contract ProofOfReserveFeedMock is IProofOfReserveFeed {
    error ProofOfReserveFeedMock__NotAuthorized();

    int256 private s_verifiedReserves;
    uint256 private s_lastUpdated;
    address public s_updater; // oracle or custodian address
    address public s_engine; // YielEngine contract address
    mapping(address => int256) s_addressToAmount;

    event ReservesUpdated(int256 newReserve, uint256 timestamp);

    /**
     * @notice Initializes the ProofOfReserveFeed contract with an authorized updater address
     * @dev Sets the updater address who will be authorized to update the proof of reserve data
     * @param updater The address that will be authorized to update the reserve feed
     * @param engine The address of the YielEngine contract
     */
    constructor(address updater, address engine) {
        s_updater = updater;
        s_engine = engine;
    }

    modifier onlyUpdaterOrEngine() {
        require(
            msg.sender == s_updater || msg.sender == s_engine,
            ProofOfReserveFeedMock__NotAuthorized()
        );
        _;
    }

    /**
     * @notice Updates the verified reserves with a new value
     * @dev Can only be called by an address with the updater role. Updates both the reserve amount and timestamp
     * @param account The address of the account whose reserves are being updated
     * @param newReserve The new reserve amount to be set as verified reserves
     * @custom:emits Should emit an event when reserves are updated (if implemented)
     * @custom:security Only callable by updater role via onlyUpdater modifier
     */
    function updateReserves(
        address account,
        int256 newReserve
    ) external onlyUpdaterOrEngine {
        s_verifiedReserves += newReserve;
        s_lastUpdated = block.timestamp;
        s_addressToAmount[account] += newReserve;
        emit ReservesUpdated(newReserve, block.timestamp);
    }

    function getAddressToAmount(
        address account
    ) external view returns (int256) {
        return s_addressToAmount[account];
    }

    function getLatestVerifiedReserves() external view returns (int256) {
        return s_verifiedReserves;
    }

    function getLastUpdatedAt() external view returns (uint256) {
        return s_lastUpdated;
    }
}
