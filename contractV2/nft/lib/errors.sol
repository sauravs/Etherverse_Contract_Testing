// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

interface Errors {
    error UnauthorizedAccess(address caller);
    error CallerMustBeWhitelisted(address caller);
    error Locked(uint256 tokenId, uint256 timestamp);
    error ZeroAddress();
    error NotMinted();
    error ExceedsCapacity();
    error ZeroInput();
}
