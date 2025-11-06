 // SPDX-License-Identifier: MIT
 pragma solidity 0.8.30;
 
 import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
 import {ERC20Votes} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
 import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
 import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
 import {IProofOfReserveFeed} from "./interfaces/IProofOfReserveFeed.sol";

contract Yeil is ERC20Votes, Ownable {
    IProofOfReserveFeed private proofFeed;
    uint48 private _snapshotId;

    event ERC20SnapshotCheckpointed(uint48 snapshotId);

    constructor(
        address _proofFeed,
        string memory tokenName,
        string memory tokenSymbol
    ) 
        ERC20(tokenName, tokenSymbol)
        EIP712(tokenName, "1")
        Ownable(msg.sender)
    {
        proofFeed = IProofOfReserveFeed(_proofFeed);
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external onlyOwner {
        _burn(from, amount);
    }

    /**
     * @dev Check if the token is fully backed by reserves
     * @return bool True if fully backed, false otherwise
     */
    function isFullyBacked() public view returns (bool) {
        return ERC20(address(this)).totalSupply() <= getVerifiedReserves();
    }

    /**
     * @dev Get the latest verified reserve amount from the oracle feed
     */
    function getVerifiedReserves() public view returns (uint256) {
        return proofFeed.latestVerifiedReserves();
    }

    // Override clock to act like snapshotId
    function clock() public view virtual override returns (uint48) {
        return _snapshotId;
    }

    function CLOCK_MODE() public view virtual override returns (string memory) {
        return "mode=counter";
    }

    // Make every address delegate to itself by default
    function delegates(address account) public pure override returns (address) {
        return account;
    }

    // Manual snapshot trigger
    function snapshot() external onlyOwner returns (uint48) {
        emit ERC20SnapshotCheckpointed(_snapshotId);
        return _snapshotId++;
    }

    /**
     * @dev Get balance at a specific snapshot ID (used for dividend calculation)
     * @param account Address to check
     * @param snapshotId Snapshot ID to check balance at
     */
    function balanceOfAt(
        address account,
        uint256 snapshotId
    ) external view returns (uint256) {
        return getPastVotes(account, snapshotId);
    }
    
    /**
     * @dev Get total supply at a specific snapshot ID
     * @param snapshotId Snapshot ID to check total supply at
     */
    function totalSupplyAt(uint256 snapshotId) external view returns (uint256) {
        return getPastTotalSupply(snapshotId);
    }

    // Required override from ERC20Votes  
    function _update(
        address from,
        address to,
        uint256 value
    ) internal override {
        super._update(from, to, value);
    }

    function getBalance(address account) external view returns (uint256) {
        return balanceOf(account);
    }

    function getTokenName() external view returns (string memory) {
        return name();
    }

    function getTokenSymbol() external view returns (string memory) {
        return symbol();
    }

    function getProofOfReserveAddress() external view returns (address) {
        return address(proofFeed);
    }
}
