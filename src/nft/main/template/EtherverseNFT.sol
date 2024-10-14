// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IUpgrade} from "../../interface/IUpgradeV1.sol";
import {Asset, Upgrade, Price} from "../../lib/Structs.sol";
import "../../lib/Fee.sol";
import "../../lib/errors.sol";


// @all please do not remove any comment starting with marker

contract EtherverseNFT is ERC721, Ownable, ReentrancyGuard {
    using Strings for uint256; // To easily convert numbers to strings
    uint8[] public colorRanges; // Ranges for color assignment
    uint24[] public svgColors; // SVG color values
    uint256 private _nextTokenId; // Tracks the next token ID to be minted

    // marker STARTING_TOKEN_ID
    uint256 private constant STARTING_TOKEN_ID = 1000000; // @audit why starting token ID this number?
    // marker STARTING_TOKEN_ID
    uint256 private constant MINT_LIMIT = 999999;

    bytes public sign; // Signature for cross-verification to verify nft belongs from etherverse

    string public itemImage; // URL for the item's image
    string public metadata; // Metadata string

    address public assetCreatorWallet; // Wallet for the asset creator's revenue
    address public USDC; // Address for USDC token        @auditcp-gas immutable can be used
    address public _ccipHandler; // Handler for cross-chain integration (via CCIP)
    address public frameAddress; // Frame contract address

    Asset.Stat public baseStat; // Base stats of the asset (like strength, dexterity, etc.)
    Asset.Type public AssetType; // Type of the asset (like weapon, shield, etc.)
    Asset.StatType[3] public statLabels; // Labels for the stats

    Price public mintPricing; // creating new struct using Price

    // Mapping to store white-listed addresses, upgrades, upgrade pricing, and token lock statuses
    mapping(address => bool) public whitelisted;
    mapping(uint256 => Asset.Stat) public upgradeMapping;
    mapping(address => Price) public upgradePricing;
    mapping(uint256 => uint256) public tokenLockedTill; //@audit made it public for testing purpose, revert it back to private before final deployment

    // Event for NFT minting and locking a token
    event NftMinted(
        address indexed recipient,
        uint256 indexed tokenId,
        uint256 indexed timestamp
    );
    event TokenLocked(
        uint256 indexed tokenId,
        uint256 indexed lockedAt,
        uint256 indexed lockedTill
    );

    // Modifier to restrict access to CCIP handler only
    modifier onlyCCIPRouter() {
        if (msg.sender != _ccipHandler)
            revert Errors.UnauthorizedAccess(msg.sender);
        _;
    }

    // Modifier to check if a token is unlocked
    modifier isUnlocked(uint256 tokenId) {
        if (tokenLockedTill[tokenId] > block.timestamp)
            revert Errors.Locked(tokenId, block.timestamp);
        _;
    }

    // Modifier to ensure that the token exists
    modifier isTokenMinted(uint256 tokenId) {
        if (_ownerOf(tokenId) == address(0)) revert Errors.NotMinted();
        _;
    }

    // Modifier to ensure function caller is white-listed
    modifier isWhitelisted(address _address) {
        if (!whitelisted[_address])
            revert Errors.CallerMustBeWhitelisted(_address);
        _;
    }

    // Modifier to ensure address is non-zero
    modifier nonZeroAddress(address _address) {
        if (_address == address(0)) revert Errors.ZeroAddress();
        _;
    }

    // Constructor to initialize contract with name, symbol, and initial owner
    constructor(
        string memory name,
        string memory symbol,
        address initialOwner
    ) ERC721(name, symbol) Ownable(initialOwner) {
        // marker assetCreatorWallet
        assetCreatorWallet = 0xa1293A8bFf9323aAd0419E46Dd9846Cc7363D44b; // this is the address of deployed AssetCreator.sol address
        // marker assetCreatorWallet

        // marker USDC
        USDC = 0xFEfC6BAF87cF3684058D62Da40Ff3A795946Ab06;  //@audit updating temporary USDC address 0x0Fd9e8d3aF1aaee056EB9e802c3A762a667b1904 (polygon mainnet) from 0x2a9e8fa175F45b235efDdD97d2727741EF4Eee63 (foundry local mockUSDC address)
        
         //@audit why not make USDC address dynamic or passing through constructor,why harcoding?also better to provide  setter function for this so that later on we would be able to change it

        // marker USDC
        // marker baseStat
        baseStat = Asset.Stat(87, 20, 21);
        // marker baseStat
        // marker statLabels
        statLabels = [
            Asset.StatType.STR,
            Asset.StatType.DEX,
            Asset.StatType.CON
        ];
        // marker statLabels
        // marker assetType
        AssetType = Asset.Type.Weapon;
        // marker assetType
        // marker svgColors
        svgColors = [213, 123, 312];
        // marker svgColors
        // marker colorRanges
        colorRanges = [0, 10, 20, 30];
        // marker colorRanges
        // marker itemImage
        itemImage = "https://ipfs.io/ipfs/QmVQ2vpBD1U6P22V2xaHk5KF5x6mQAM7HmFsc8c2AsQhgo";
        // marker itemImage

        // TODO: Update the address before deployment
        // marker ccipHandler
        _ccipHandler = 0x3c7444D7351027473698a7DCe751eE6Aea8036ee;   //@audit why not making it dynamic,why harcoding?
        // marker ccipHandler

        // 1000 means 10% of the mint price goes to the creator
        // marker mintPricing.split
        mintPricing.split = 1000;
        // marker mintPricing.split

        // marker mintPricing.amount
        mintPricing.amount = 100000;   // @audit means 0.1 USDC?
        // marker mintPricing.amount

        // TODO: Update the address before deployment
        // marker frameAddress
        frameAddress = address(0);
        // marker frameAddress
        _nextTokenId = STARTING_TOKEN_ID;
        metadata = "{}";
    }

    // Getter function for color ranges array
    function colorRangesArray() external view returns (uint8[] memory) {
        return colorRanges;
    }

    // Getter function for SVG colors array
    // colors for each level definted in colorRangesArray
    function svgColorsArray() external view returns (uint24[] memory) {
        return svgColors;
    }

    // Getter function for stat labels array
    // stats labels in total 3 stat we have
    function statLabelsArray()
        external
        view
        returns (Asset.StatType[3] memory)
    {
        return statLabels;
    }

    // Getter function to check if a token is locked
    function lockStatus(uint256 tokenId) external view returns (bool) {
        return (tokenLockedTill[tokenId] > block.timestamp);
    }

    // Setter function to lock a token for a specific duration until token is transferred
    function setTokenLockStatus(          //@audit how it will come to know if that tokenID token is minted?
        uint256 tokenId,
        uint256 unlockTime //CCIP use
    ) external onlyCCIPRouter {
        tokenLockedTill[tokenId] = unlockTime;
        emit TokenLocked(tokenId, block.timestamp, unlockTime);
    }

    // This function sets the signature used to verify that the NFT was minted by Game-X.
    // Once the contract is deployed, this signature is set and is used for cross-verification.
    // When checking the minted NFT, this signature is compared against the signature stored in the NFT metadata
    // to ensure authenticity and confirm that it was minted by our Game-X software.
    function setSign(bytes memory _sign) external onlyOwner {
        sign = _sign;
    }

    // Setter function to whitelist an address
    //authenticating a game dev, they (game dev) have integrated this asset
    function setWhitelisted(address _address, bool _status) external onlyOwner {
        whitelisted[_address] = _status;
    }

    // Change CCIP handler address
    // for cross chain
    function changeCCIP(address newAdd) external onlyOwner {
        _ccipHandler = newAdd;
    }

    // Change the frame address (for rendering the NFT)
    // Frame is nothing but token uri
    function changeFrame(address _frameAddress) external onlyOwner {
        frameAddress = _frameAddress;
    }

    // Change the image URL of the NFT
    function changeImageUrl(string memory str) external onlyOwner {
        itemImage = str;
    }

    // Update metadata of the NFT
    // metadata for nfts
    function setMetadata(string memory str) external onlyOwner {
        metadata = str;
    }

    function setMintPricing(            
        uint256 _amount,
        uint256 _split
    ) external onlyOwner {
        if (_split > 8000) revert Errors.SplitTooHigh();
        mintPricing.amount = _amount == 0 ? mintPricing.amount : _amount;
        mintPricing.split = _split == 0 ? mintPricing.split : _split;
    }

    function setUpgradePricing(        
        uint256 _price,
        uint256 _split
    ) external isWhitelisted(msg.sender) {
        if (_split > 8000) revert Errors.SplitTooHigh();
        upgradePricing[msg.sender].split = _split;
        upgradePricing[msg.sender].amount = _price;
    }

    function getTokenStats(   
        uint256 tokenId
    ) external view isTokenMinted(tokenId) returns (uint8[3] memory) {
        return [
            upgradeMapping[tokenId].stat1 + baseStat.stat1,
            upgradeMapping[tokenId].stat2 + baseStat.stat2,
            upgradeMapping[tokenId].stat3 + baseStat.stat3
        ];
    }

    function updateStats(                                              //@audit skipped testing as of now,related to ccip
        uint256 tokenId,
        address newOwner,
        uint8[3] memory stats
    ) external nonZeroAddress(newOwner) onlyCCIPRouter returns (bool) {
        address currentOwner = ownerOf(tokenId);

        if (currentOwner == address(0)) {
            _safeMint(newOwner, tokenId);
            tokenLockedTill[tokenId] = 0;
            emit NftMinted(newOwner, tokenId, block.timestamp);
        }

        upgradeMapping[tokenId] = Asset.Stat(stats[0], stats[1], stats[2]);
        return true;
    }

    function mint(
        address to,
        bytes memory authorizationParams
    ) external isWhitelisted(msg.sender) nonReentrant returns (uint256) {
        Fee.receiveUSDC(
            to,
            mintPricing.amount,
            USDC,
            mintPricing.split,
            authorizationParams
        );
        uint256 tokenId = _nextTokenId++;                 //@auditcp-gas unchecked can be used
        if (tokenId > STARTING_TOKEN_ID + 100000)
            revert Errors.ExceedsCapacity();
        _safeMint(to, tokenId);                             //@auditcp-gas repeated Storage Reads
        tokenLockedTill[tokenId] = 0;
        emit NftMinted(to, tokenId, block.timestamp);
        return tokenId;
    }

    function tokenURI(        //@audit test failing
        uint256 tokenId
    ) public view override(ERC721) returns (string memory) {
        return IFrame(frameAddress).tokenURI(tokenId);
    }



    function freeUpgrade(               //@audit to correctly test this function ,need to call getTokenStats before calling this function // why not getTokenStats logic embedded in this function?because if we call this function only will receive value 2 every time
        uint256 tokenId
    )
        external
        isWhitelisted(msg.sender)
        isTokenMinted(tokenId)
        isUnlocked(tokenId)
    {
        upgradeMapping[tokenId] = _getUpgradeModule(msg.sender)
            .calculateUpgrade(upgradeMapping[tokenId], 2);
    }

    function paidUpgrade(
        uint256 tokenId,
        bytes memory authorizationParams                  //@auditcp-gas calldata can be used instead of memory
    )
        external
        isWhitelisted(msg.sender)
        isTokenMinted(tokenId)
        isUnlocked(tokenId)
        nonReentrant
    {
        Asset.Stat memory newStat = _getUpgradeModule(msg.sender)
            .calculateUpgrade(upgradeMapping[tokenId], 5);

        Fee.receiveUSDC(
            _ownerOf(tokenId),
            _getUpgradeModule(msg.sender).calculatePrice(
                upgradePricing[msg.sender].amount,
                newStat
            ),
            USDC,
            10000 - upgradePricing[msg.sender].split,
            authorizationParams
        );
        upgradeMapping[tokenId] = newStat;
    }

    function nextUpgrade(          //testing done
        uint256 tokenId,
        Upgrade.Type _type
    )
        external
        view
        isWhitelisted(msg.sender)
        isTokenMinted(tokenId)
        isUnlocked(tokenId)
        returns (Asset.Stat memory)
    {
        if (_type == Upgrade.Type.Free) {
            return
                _getUpgradeModule(msg.sender).calculateStat(
                    upgradeMapping[tokenId],
                    2
                );
        } else if (_type == Upgrade.Type.Paid) {
            return
                _getUpgradeModule(msg.sender).calculateStat(
                    upgradeMapping[tokenId],
                    5
                );
        } else revert("Invalid Type");
    }

    function nextUpgradePrice(
        uint256 tokenId
    )
        external
        view
        isTokenMinted(tokenId)
        isUnlocked(tokenId)
        isWhitelisted(msg.sender)
        returns (uint256)
    {
        return
            _getUpgradeModule(msg.sender).calculatePrice(
                upgradePricing[msg.sender].amount,
                upgradeMapping[tokenId]
            );
    }

    function getStat(
        Asset.StatType statLabel,
        uint256 tokenId
    ) external view returns (uint8 stat) {
        if (
            _ownerOf(tokenId) != address(0) || // isTokenMinted
            tokenLockedTill[tokenId] < block.timestamp || // isUnlocked
            msg.sender == frameAddress // bypass all the logic if it is being called by Frame contract.
        ) {
            if (statLabel == statLabels[0])
                return upgradeMapping[tokenId].stat1 + baseStat.stat1;
            else if (statLabel == statLabels[1])
                return upgradeMapping[tokenId].stat2 + baseStat.stat2;
            else if (statLabel == statLabels[2])
                return upgradeMapping[tokenId].stat3 + baseStat.stat3;
            else return 0;
        } else revert Errors.Locked(tokenId, block.timestamp);
    }

    function getOwner(uint256 tokenId) external view returns (address) {
        return _ownerOf(tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override nonZeroAddress(to) isUnlocked(tokenId) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override nonZeroAddress(to) isUnlocked(tokenId) nonReentrant {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function ccipTransfer(
        address from,
        address to,
        uint256 tokenId
    ) external nonZeroAddress(to) nonReentrant onlyCCIPRouter {
        super.safeTransferFrom(from, to, tokenId, "");
    }

    function _getUpgradeModule(
        address _address
    ) internal view returns (IUpgrade) {
        return IUpgrade(IGame(_address).upgradeAddress());
    }

    function withdraw(address token) external nonReentrant {
        Fee.withdraw(assetCreatorWallet, token);
    }
}

interface IFrame {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface IGame {
    function upgradeAddress() external view returns (address);
}
