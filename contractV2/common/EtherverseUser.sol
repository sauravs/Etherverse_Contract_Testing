//SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract EtherverseUser is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;
    address public etherverse;
    address public user;
    address private candidate;
    uint256 private candidateTimeout;
    address public userWallet;
    address private walletCandidate;
    uint256 private walletCandidateTimeout;
    uint256 public etherverseFee;

    event CandidateProposed(
        address indexed currentUser,
        address indexed candidate,
        uint256 timestamp
    );
    event ProposalAccepted(address indexed newUser, uint256 timestamp);

    event EtherWithdraw(uint256 indexed amount, uint256 indexed timestamp);
    event ERC20Withdraw(
        address indexed token,
        uint256 indexed amount,
        uint256 indexed timestamp
    );

    constructor(
        address _etherverse,
        address _user,
        address _userWallet,
        uint256 _fee,
        address initalOwner
    ) Ownable(initalOwner) {
        etherverse = _etherverse;
        // 0x0C903F1C518724CBF9D00b18C2Db5341fF68269C;
        user = _user;
        user = _userWallet;
        // 0xa1293A8bFf9323aAd0419E46Dd9846Cc7363D44b;
        etherverseFee = _fee;
    }

    modifier onlyOwnerOr(address _address) {
        require(
            msg.sender == _address || msg.sender == owner(),
            "Unauthorized Access"
        );
        _;
    }

    function setUser(address _user) external onlyOwner {
        require(_user == address(0), "User already set");
        user = _user;
    }

    function setUserWallet(address _userWallet) external onlyOwnerOr(user) {
        require(_userWallet != address(0), "Invalid Address");
        userWallet = _userWallet;
    }

    function proposeCandidate(address _candidate) external onlyOwnerOr(user) {
        require(
            _candidate != address(0) || _candidate != user,
            "Invalid Address"
        );
        candidate = _candidate;
        candidateTimeout = block.timestamp + 1 days;
        emit CandidateProposed(user, _candidate, block.timestamp);
    }

    function cancelProposal() external onlyOwnerOr(user) {
        candidate = address(0);
        candidateTimeout = 0;
    }

    function acceptProposal() external onlyOwnerOr(candidate) {
        require(candidateTimeout > block.timestamp, "Timeout expired");
        user = candidate;
        candidate = address(0);
        candidateTimeout = 0;
        emit ProposalAccepted(user, block.timestamp);
    }

    function withdraw(
        address _token,
        uint256 _percentage
    ) external nonReentrant {
        require(_percentage <= 100, "Invalid percentage");
        require(userWallet != address(0), "Wallet not set");
        if (_token == address(0)) {
            uint256 amount = (address(this).balance * _percentage) / 100;
            uint256 fee = (amount * etherverseFee) / 10000;
            payable(etherverse).transfer(fee);
            uint256 balance = amount - fee;
            payable(userWallet).transfer(balance);
            emit EtherWithdraw(balance, block.timestamp);
        } else {
            IERC20 token = IERC20(_token);
            uint256 amount = (token.balanceOf(address(this)) * _percentage) /
                100;
            uint256 fee = (amount * etherverseFee) / 10000;
            token.safeTransfer(etherverse, (amount * etherverseFee) / 10000);
            uint256 balance = amount - fee;
            token.safeTransfer(userWallet, balance);
            emit ERC20Withdraw(_token, balance, block.timestamp);
        }
    }

    function updateEtherverseFee(uint256 _fee) external onlyOwner {
        require(_fee < 15000, "Fee can never be more than 15%");
        etherverseFee = _fee;
    }
}
