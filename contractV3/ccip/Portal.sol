// SPDX-License-Identifier: MIT

//https://docs.chain.link/ccip/tutorials/send-arbitrary-data
pragma solidity ^0.8.24;

import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {OwnerIsCreator} from "@chainlink/contracts-ccip/src/v0.8/shared/access/OwnerIsCreator.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {IERC20} from "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../nft/interface/IEtherverseNFT.sol";
import {Errors} from "./interface/errors.sol";

contract Portal is CCIPReceiver, OwnerIsCreator {
    using Strings for uint256;
    uint256 private _gasLimit;

    // The unique ID of the CCIP message.
    // The chain selector of the destination chain.
    // The address of the receiver on the destination chain.
    // The text being sent.
    // the token address used to pay CCIP fees.
    // The fees paid for sending the CCIP message.
    event MessageSent(
        bytes32 indexed messageId,
        uint64 indexed destinationChainSelector,
        address receiver,
        string text,
        address feeToken,
        uint256 fees
    );

    // The unique ID of the CCIP message.
    // The chain selector of the source chain.
    // The address of the sender from the source chain.
    // The text that was received.
    event MessageReceived(
        bytes32 indexed messageId,
        uint64 indexed sourceChainSelector,
        address sender,
        string text
    );

    mapping(uint64 => bool) public allowlistedDestinationChains;

    mapping(uint64 => bool) public allowlistedSourceChains;

    mapping(address => bool) public allowlistedSenders;

    constructor(address _router, uint256 gasLimit) CCIPReceiver(_router) {
        _gasLimit = gasLimit;
    }

    modifier onlyAllowlistedDestinationChain(uint64 _destinationChainSelector) {
        if (!allowlistedDestinationChains[_destinationChainSelector])
            revert Errors.DestinationChainNotAllowlisted(
                _destinationChainSelector
            );
        _;
    }

    modifier onlyAllowlisted(uint64 _sourceChainSelector, address _sender) {
        if (!allowlistedSourceChains[_sourceChainSelector])
            revert Errors.SourceChainNotAllowlisted(_sourceChainSelector);
        if (!allowlistedSenders[_sender])
            revert Errors.SenderNotAllowlisted(_sender);
        _;
    }

    modifier validateReceiver(address _receiver) {
        if (_receiver == address(0)) revert Errors.InvalidReceiverAddress();
        _;
    }

    function getHash(
        address contractAddress // used to generate the hash of given contract will used in verification that it is deployed by us
    ) public view returns (string memory) {
        return uint256(keccak256(address(contractAddress).code)).toString();
    }

    function getMultipleHash(
        address[] calldata contractAddresses
    ) public view returns (string[] memory) {
        string[] memory hashArray = new string[](contractAddresses.length);
        for (uint256 i; i < contractAddresses.length; i++) {
            hashArray[i] = getHash(contractAddresses[i]);
        }
        return hashArray;
    }

    function allowlistDestinationChain(
        uint64 _destinationChainSelector,
        bool allowed
    ) external onlyOwner {
        allowlistedDestinationChains[_destinationChainSelector] = allowed;
    }

    function allowlistSourceChain(
        uint64 _sourceChainSelector,
        bool allowed
    ) external onlyOwner {
        allowlistedSourceChains[_sourceChainSelector] = allowed;
    }

    function allowlistSender(address _sender, bool allowed) external onlyOwner {
        allowlistedSenders[_sender] = allowed;
    }

    function setGasLimit(uint256 _limit) external onlyOwner {
        _gasLimit = _limit;
    }

    function getMessageFee(
        uint64 destinationChainSelector,
        address _receiver,
        string memory _text
    )
        public
        view
        returns (Client.EVM2AnyMessage memory evm2AnyMessage, uint256 fees)
    {
        evm2AnyMessage = _buildCCIPMessage(
            _receiver,
            _text,
            address(0),
            _gasLimit
        );

        IRouterClient router = IRouterClient(this.getRouter());
        fees = router.getFee(destinationChainSelector, evm2AnyMessage);
    }

    function transferNft(
        uint256 _tokenId,
        address nftAddress,
        uint64 destinationChainId,
        //ccip receiver opposite chain
        address _receiver
    ) public payable {
        IEtherverseNFT nftContract = IEtherverseNFT(nftAddress);
        address nftOwner = nftContract.getOwner(_tokenId);
        if (nftOwner == address(0)) revert Errors.InvalidToken();
        if (!nftContract.isApprovedForAll(nftOwner, address(this)))
            revert Errors.TokenApprovalError();
        if (nftContract.lockStatus(_tokenId)) revert Errors.LockedToken();

        // Create an array of stats
        uint8[3] memory stats = nftContract.getTokenStats(_tokenId);

        string memory message = utils.encodeMessage(
            _tokenId,
            nftOwner,
            nftAddress,
            uint8(utils.MessageType.TRANSFER),
            stats
        );

        uint256 unlockTime = block.timestamp + 2 hours;
        nftContract.setTokenLockStatus(_tokenId, unlockTime);
        this.sendMessage{value: msg.value}(
            destinationChainId,
            _receiver,
            message
        );
    }

    // fees from user
    function sendMessage(
        uint64 _destinationChainSelector,
        address _receiver,
        string calldata _text
    )
        external
        payable
        onlyAllowlistedDestinationChain(_destinationChainSelector)
        validateReceiver(_receiver)
        returns (bytes32 messageId)
    {
        (
            Client.EVM2AnyMessage memory evm2AnyMessage,
            uint256 fees
        ) = getMessageFee(_destinationChainSelector, _receiver, _text);

        if (fees > msg.value)
            revert Errors.InsufficientBalance(msg.value, fees);
        messageId = IRouterClient(this.getRouter()).ccipSend{value: fees}(
            _destinationChainSelector,
            evm2AnyMessage
        );

        emit MessageSent(
            messageId,
            _destinationChainSelector,
            _receiver,
            _text,
            address(0),
            fees
        );
    }

    function _ccipReceive(
        Client.Any2EVMMessage memory any2EvmMessage
    )
        internal
        override
        onlyAllowlisted(
            any2EvmMessage.sourceChainSelector,
            abi.decode(any2EvmMessage.sender, (address))
        )
    {
        bytes32 messageId = any2EvmMessage.messageId;
        (
            uint256 tokenId,
            address newOwner,
            address nftAddress,
            utils.MessageType messageType,
            uint8[3] memory stats
        ) = utils.decodeMessage(abi.decode(any2EvmMessage.data, (string)));

        if (messageType == utils.MessageType.TRANSFER) {
            IEtherverseNFT nft = IEtherverseNFT(nftAddress);
            address nftOwner = nft.getOwner(tokenId);
            bool locked = nft.lockStatus(tokenId);
            if (locked) {
                nft.setTokenLockStatus(tokenId, 0);
            }

            if (nftOwner != address(0) || nftOwner != newOwner) {
                nft.ccipTransfer(nftOwner, newOwner, tokenId);
            }

            nft.updateStats(tokenId, newOwner, stats);
            string memory message = utils.encodeMessage(
                tokenId,
                newOwner,
                nftAddress,
                uint8(utils.MessageType.ACK),
                stats
            );
            this.sendMessage( //@audit
                any2EvmMessage.sourceChainSelector,
                abi.decode(any2EvmMessage.sender, (address)),
                message
            );
        } else {
            IEtherverseNFT nft = IEtherverseNFT(nftAddress);
            uint256 unlockTime = type(uint256).max;
            nft.setTokenLockStatus(tokenId, unlockTime);
        }

        emit MessageReceived(
            messageId,
            any2EvmMessage.sourceChainSelector,
            abi.decode(any2EvmMessage.sender, (address)),
            abi.decode(any2EvmMessage.data, (string))
        );
    }

    function _buildCCIPMessage(
        address _receiver,
        string memory _text,
        address _feeTokenAddress,
        uint256 gasLimit
    ) private pure returns (Client.EVM2AnyMessage memory) {
        return
            Client.EVM2AnyMessage({
                receiver: abi.encode(_receiver),
                data: abi.encode(_text),
                tokenAmounts: new Client.EVMTokenAmount[](0),
                extraArgs: Client._argsToBytes(
                    Client.EVMExtraArgsV1({gasLimit: gasLimit})
                ),
                feeToken: _feeTokenAddress
            });
    }

    receive() external payable {}

    function withdraw(address _beneficiary, uint256 _amount) public onlyOwner {
        uint256 amount = address(this).balance;
        if (_amount > amount)
            revert Errors.InsufficientBalance(amount, _amount);
        (bool sent, ) = _beneficiary.call{value: amount}("");

        if (!sent)
            revert Errors.WithdrawFailed(_beneficiary, address(0), amount);
    }

    function withdrawToken(
        address _beneficiary,
        address _token,
        uint256 _amount
    ) public onlyOwner {
        // Retrieve the balance of this contract
        uint256 amount = IERC20(_token).balanceOf(address(this));

        // Revert if there is nothing to withdraw
        if (amount == 0) revert Errors.InsufficientBalance(0, _amount);
        try IERC20(_token).transfer(_beneficiary, amount) {} catch {
            revert Errors.WithdrawFailed(_beneficiary, _token, amount);
        }
    }
}

library utils {
    enum MessageType {
        TRANSFER,
        ACK
    }
    
    error InvalidMessageType();

    function compareString(
        string memory a,
        string memory b
    ) public pure returns (bool) {
        bytes memory aBytes = bytes(a);
        bytes memory bBytes = bytes(b);
        return
            (aBytes.length == bBytes.length) &&
            (keccak256(aBytes) == keccak256(bBytes));
    }

    function encodeMessage(
        uint256 tokenId,
        address newOwner,
        address nftAddress,
        uint8 messageType,
        uint8[3] memory stats
    ) public pure returns (string memory) {
        if (messageType > uint8(type(MessageType).max))
            revert InvalidMessageType();
        bytes memory packed = abi.encodePacked(
            tokenId,
            newOwner,
            nftAddress,
            messageType,
            stats[0],
            stats[1],
            stats[2]
        );
        return bytesToHexString(packed);
    }

    function decodeMessage(
        string memory encodedData
    )
        public
        pure
        returns (
            uint256 tokenId,
            address newOwner,
            address nftAddress,
            MessageType messageType,
            uint8[3] memory stats
        )
    {
        bytes memory packed = hexStringToBytes(encodedData);

        require(packed.length == 76, "Invalid encoded data length");
        uint8 a;
        uint8 b;
        uint8 c;

        assembly {
            tokenId := mload(add(packed, 32))
            newOwner := and(
                mload(add(packed, 52)),
                0xffffffffffffffffffffffffffffffffffffffff
            )
            nftAddress := and(
                mload(add(packed, 72)),
                0xffffffffffffffffffffffffffffffffffffffff
            )
            let lastWord := mload(add(packed, 76))
            messageType := and(shr(24, lastWord), 0xff)
            a := and(shr(16, lastWord), 0xff)
            b := and(shr(8, lastWord), 0xff)
            c := and(lastWord, 0xff)
        }
        messageType = MessageType(messageType);
        stats = [a, b, c];
    }

    function bytesToHexString(
        bytes memory data
    ) internal pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(2 * data.length + 2);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < data.length; i++) {
            str[2 * i + 2] = alphabet[uint8(data[i] >> 4)];
            str[2 * i + 3] = alphabet[uint8(data[i] & 0x0f)];
        }
        return string(str);
    }

    function hexStringToBytes(
        string memory s
    ) internal pure returns (bytes memory) {
        require(
            bytes(s).length >= 2 && bytes(s)[0] == "0" && bytes(s)[1] == "x",
            "Invalid hex string"
        );
        bytes memory ss = bytes(s);
        require((ss.length - 2) % 2 == 0, "Invalid hex string length");
        bytes memory r = new bytes((ss.length - 2) / 2);
        for (uint256 i = 2; i < ss.length; i += 2) {
            r[i / 2 - 1] = bytes1(
                fromHexChar(uint8(ss[i])) * 16 + fromHexChar(uint8(ss[i + 1]))
            );
        }
        return r;
    }

    function fromHexChar(uint8 c) internal pure returns (uint8) {
        if (c >= 48 && c <= 57) return c - 48; // 0-9
        if (c >= 65 && c <= 70) return c - 55; // A-F
        if (c >= 97 && c <= 102) return c - 87; // a-f
        revert("Invalid hex character");
    }
}
