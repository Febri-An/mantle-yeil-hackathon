// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {IProofOfReserveFeed} from "src/interfaces/IProofOfReserveFeed.sol";

contract ProofOfReserveFeed is IProofOfReserveFeed {
    event ReservesUpdated(uint256 newReserve, uint256 timestamp);

    uint256 private verifiedReserves;
    uint256 private lastUpdated;
    address public updater; // oracle or custodian address

    modifier onlyUpdater() {
        require(msg.sender == updater, "Not authorized");
        _;
    }

    /**
     * @notice Initializes the ProofOfReserveFeed contract with an authorized updater address
     * @dev Sets the updater address who will be authorized to update the proof of reserve data
     * @param _updater The address that will be authorized to update the reserve feed
     */
    constructor(address _updater) {
        updater = _updater;
    }

    /**
     * @notice Updates the verified reserves with a new value
     * @dev Can only be called by an address with the updater role. Updates both the reserve amount and timestamp
     * @param _newReserve The new reserve amount to be set as verified reserves
     * @custom:emits Should emit an event when reserves are updated (if implemented)
     * @custom:security Only callable by updater role via onlyUpdater modifier
     */
    function updateReserves(uint256 _newReserve) external onlyUpdater {
        verifiedReserves = _newReserve;
        lastUpdated = block.timestamp;
        emit ReservesUpdated(_newReserve, block.timestamp);
    }

    function latestVerifiedReserves() external view returns (uint256) {
        return verifiedReserves;
    }

    function lastUpdatedAt() external view returns (uint256) {
        return lastUpdated;
    }
}
