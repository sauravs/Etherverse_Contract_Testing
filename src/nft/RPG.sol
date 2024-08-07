// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "./RPGUtil.sol";
import {Asset, Upgrade} from "./lib/RPGStruct.sol";
//import "./lib/TokenIdUtil.sol";  //@tester should be removed
import "./interface/IUpgradeV1.sol";
import "./Fee.sol";
import "./lib/errors.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

//@dev trailing __ in var names means they will be hardcoded when contract is generated and depolyed by us
contract RPGItemNFT is ERC721, Ownable, ReentrancyGuard {
    using Strings for uint256;

    uint8[] public colorRanges;
    uint24[] public svgColors;
    uint256 public _nextTokenId; // @tester : updated to public for testing purpose (revert back to private before deployment to mainnet)
    uint256 private constant STARTING_TOKEN_ID = 1000000;
    uint256 private constant MINT_LIMIT = 999999;
    uint256 public mintPrice;
    uint256 public sign; //@dev sign is signature look at setter fun for more info

    string public itemImage;

    address public etherverseWallet;
    address public assetCreatorWallet;
    address public USDC;
    address public _ccipHandler;
    address public uriAddress;

    Asset.Stat public baseStat;
    Asset.Type public AssetType;
    Asset.StatType[3] public statLabels;

    mapping(address => bool) public whitelisted;
    mapping(uint256 => Asset.Stat) public upgradeMapping;
    mapping(address => uint256) public upgradePricing;
    mapping(uint256 => uint256) public tokenLockedTill; //@tester : updated to private for testing purpose (revert back to private before deployment to mainnet)
    mapping(uint256 => bool) public isDeployed;

    event NftMinted(address indexed recipient, uint256 indexed tokenId, uint256 indexed timestamp);
    event TokenLocked(uint256 indexed tokenId, uint256 indexed lockedAt, uint256 indexed lockedTill);

    modifier onlyCCIPRouter() {
        if (msg.sender != _ccipHandler) {
            revert Errors.UnauthorizedAccess(msg.sender);
        }
        _;
    }

    modifier isUnlocked(uint256 tokenId) {
        if (tokenLockedTill[tokenId] > block.timestamp) {
            revert Errors.Locked(tokenId, block.timestamp);
        }
        _;
    }

    modifier isTokenMinted(uint256 tokenId) {
        if (_ownerOf(tokenId) == address(0)) revert Errors.NotMinted();
        _;
    }
    // @dev Any function with this modifier can only be called by a whitelisted marketplace contract

    modifier isWhitelisted(address _address) {
        if (!whitelisted[_address]) {
            revert Errors.CallerMustBeWhitelisted(_address);
        }
        _;
    }

    modifier nonZeroAddress(address _address) {
        if (_address == address(0)) revert Errors.ZeroAddress();
        _;
    }

    constructor() ERC721("Sword", "SW") Ownable(0x762aD31Ff4bD1ceb5b3b5868672d5CBEaEf609dF) {
        etherverseWallet = 0x0C903F1C518724CBF9D00b18C2Db5341fF68269C;
        assetCreatorWallet = 0xa1293A8bFf9323aAd0419E46Dd9846Cc7363D44b;
        USDC = 0x0Fd9e8d3aF1aaee056EB9e802c3A762a667b1904;
        baseStat = Asset.Stat(10, 20, 30);
        statLabels = [Asset.StatType.STR, Asset.StatType.CON, Asset.StatType.DEX];
        AssetType = Asset.Type.Weapon;
        svgColors = [213, 123, 312];
        colorRanges = [0, 10, 20, 30];
        itemImage = "https://ipfs.io/ipfs/QmVQ2vpBD1U6P22V2xaHk5KF5x6mQAM7HmFsc8c2AsQhgo";
        _ccipHandler = 0x3c7444D7351027473698a7DCe751eE6Aea8036ee;
        mintPrice = 100000;
        isDeployed[block.chainid] = true;
        // TO-DO: Update the address before deployment
        uriAddress = address(0);
        _nextTokenId = STARTING_TOKEN_ID;
    }

    function setDeployed(uint256 chainId, bool _status) external onlyOwner {
        //@tester : why it is restricted to onlyOwner?
        isDeployed[chainId] = _status;
    }

    function colorRangesArray() external view returns (uint8[] memory) {
        return colorRanges;
    }

    function setUSDC(address _usdc) external onlyOwner {
        //@tester added this function for testing purpose
        USDC = _usdc;
    }

    function svgColorsArray() external view returns (uint24[] memory) {
        return svgColors;
    }

    function statLabelsArray() external view returns (Asset.StatType[3] memory) {
        return statLabels;
    }

    function lockStatus(uint256 tokenId) external view returns (bool) {
        return (tokenLockedTill[tokenId] > block.timestamp);
    }

    function setTokenLockStatus(
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
    function setSign(uint256 _sign) external onlyOwner {
        sign = _sign;
    }

    function setWhitelisted(address _address, bool _status) external onlyOwner {
        whitelisted[_address] = _status;
    }

    function changeCCIP(address newAdd) external onlyOwner {
        _ccipHandler = newAdd;
    }

    function changeURI(address _uri) external onlyOwner {
        uriAddress = _uri;
    }

    function changeImageUrl(string memory str) external onlyOwner {
        itemImage = str;
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        if (_mintPrice == 0) revert Errors.ZeroInput();
        mintPrice = _mintPrice;
    }

    function setUpgradePrice(uint256 _price) external isWhitelisted(msg.sender) {
        upgradePricing[msg.sender] = _price;
    }

    function getTokenStats(uint256 tokenId) external view isTokenMinted(tokenId) returns (uint8, uint8, uint8) {
        return (
            upgradeMapping[tokenId].stat1 + baseStat.stat1,
            upgradeMapping[tokenId].stat2 + baseStat.stat2,
            upgradeMapping[tokenId].stat3 + baseStat.stat3
        );
    }

    function updateStats(uint256 tokenId, address newOwner, uint8 stat1, uint8 stat2, uint8 stat3)
        external
        nonZeroAddress(newOwner)
        onlyCCIPRouter
        returns (
            bool //@tester : related to CCIP ? to transfer stats to other chain? why isTokenMinted check is not used here?
        )
    {
        address currentOwner = ownerOf(tokenId);

        if (currentOwner == address(0)) {
            _safeMint(newOwner, tokenId);
            tokenLockedTill[tokenId] = 0;
            emit NftMinted(newOwner, tokenId, block.timestamp);
        }

        upgradeMapping[tokenId] = Asset.Stat(stat1, stat2, stat3);
        return true;
    }

    function mint(address to, bytes memory authorizationParams)
        external
        isWhitelisted(msg.sender)
        nonReentrant
        returns (uint256)
    {
        Fee.receiveUSDC(to, mintPrice, USDC, authorizationParams);
        uint256 tokenId = _nextTokenId++;
        if (tokenId > STARTING_TOKEN_ID + 100000) {
            revert Errors.ExceedsCapacity();
        }
        _safeMint(to, tokenId);
        tokenLockedTill[tokenId] = 0;
      
        emit NftMinted(to, tokenId, block.timestamp);
        return tokenId;
    }

 

    function tokenURI(uint256 tokenId) public view override(ERC721) isTokenMinted(tokenId) returns (string memory) {
        return IImage(uriAddress).tokenURI(tokenId);
    }

    function freeUpgrade(
        uint256 tokenId //@tester: if token minted check is here,then their is no need of isWhitelisted modifier,because only whitelisted user can mint
    ) external isWhitelisted(msg.sender) isTokenMinted(tokenId) isUnlocked(tokenId) {
        upgradeMapping[tokenId] = _getUpgradeModule(msg.sender).calculateUpgrade(upgradeMapping[tokenId], 2);
    }

    function paidUpgrade(uint256 tokenId, bytes memory authorizationParams)
        external
        isWhitelisted(msg.sender)
        isTokenMinted(tokenId)
        isUnlocked(tokenId)
        nonReentrant
    {
        Asset.Stat memory newStat = _getUpgradeModule(msg.sender).calculateUpgrade(upgradeMapping[tokenId], 5);

        Fee.receiveUSDC(
            _ownerOf(tokenId),
            _getUpgradeModule(msg.sender).calculatePrice(upgradePricing[msg.sender], newStat),
            USDC,
            authorizationParams
        );
        upgradeMapping[tokenId] = newStat;
    }

    function nextUpgrade(uint256 tokenId, Upgrade.Type _type)
        external
        view
        isWhitelisted(msg.sender)
        isTokenMinted(tokenId)
        isUnlocked(tokenId)
        returns (
            Asset.Stat memory // Read only function
        )
    {
        if (_type == Upgrade.Type.Free) {
            return _getUpgradeModule(msg.sender).calculateStat(upgradeMapping[tokenId], 2);
        } else if (_type == Upgrade.Type.Paid) {
            return _getUpgradeModule(msg.sender).calculateStat(upgradeMapping[tokenId], 5);
        } else {
            revert("Invalid Type");
        }
    }

    function nextUpgradePrice(uint256 tokenId)
        external
        view
        isTokenMinted(tokenId)
        isUnlocked(tokenId)
        isWhitelisted(msg.sender)
        returns (
            uint256 // Read only function
        )
    {
        return _getUpgradeModule(msg.sender).calculatePrice(upgradePricing[msg.sender], upgradeMapping[tokenId]);
    }

    function resetUpgrades(uint256 tokenId)
        external
        isTokenMinted(tokenId)
        isUnlocked(tokenId)
        isWhitelisted(msg.sender)
    {
        upgradeMapping[tokenId] = Asset.Stat(0, 0, 0);
    }

    function getStat(Asset.StatType statLabel, uint256 tokenId)
        external
        view
        isTokenMinted(tokenId)
        isUnlocked(tokenId)
        returns (uint8 stat)
    {
        if (statLabel == statLabels[0]) {
            return upgradeMapping[tokenId].stat1 + baseStat.stat1;
        } else if (statLabel == statLabels[1]) {
            return upgradeMapping[tokenId].stat2 + baseStat.stat2;
        } else if (statLabel == statLabels[2]) {
            return upgradeMapping[tokenId].stat3 + baseStat.stat3;
        } else {
            return 0;
        }
    }

    function getOwner(uint256 tokenId) external view returns (address) {
        return _ownerOf(tokenId); //@tester no need of this function we can directly fetch owner detail with ownerOf(tokenID)
    }

    //@tester: why both transferFrom and safeTransferFrom provided??
    function transferFrom(address from, address to, uint256 tokenId)
        public
        override
        nonZeroAddress(to)
        isUnlocked(tokenId)
    //@tester : remove the nononReentrant gaurd from     transferFrom
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        nonReentrant
        nonZeroAddress(to)
        isUnlocked(tokenId)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function ccipTransfer(address from, address to, uint256 tokenId)
        external
        nonZeroAddress(to)
        nonReentrant
        onlyCCIPRouter
    {
        super.safeTransferFrom(from, to, tokenId, "");
    }

    function _getUpgradeModule(address _address) internal view returns (IUpgradeV1) {
        return IUpgradeV1(IGame(_address).upgradeAddress());
    }

    function withdraw(address token) external nonReentrant {
        Fee.withdraw(assetCreatorWallet, token);
    }
}

interface IImage {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface IGame {
    function upgradeAddress() external view returns (address);
}
