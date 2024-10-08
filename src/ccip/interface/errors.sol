// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

interface Errors {
    error InsufficientBalance(uint256 currentBalance, uint256 requestedBalance);
    error WithdrawFailed(address target, address token, uint256 value);
    // Used when the destination chain has not been allowlisted by the contract owner.
    error DestinationChainNotAllowlisted(uint64 destinationChainSelector);
    // Used when the source chain has not been allowlisted by the contract owner.
    error SourceChainNotAllowlisted(uint64 sourceChainSelector);
    // Used when the sender has not been allowlisted by the contract owner.
    error SenderNotAllowlisted(address sender);
    // Used when the receiver address is 0.
    error InvalidReceiverAddress();
    error NonNumericValue();
    error InvalidToken();
    error TokenApprovalError();
    error LockedToken();
}
