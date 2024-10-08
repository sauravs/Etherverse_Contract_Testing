// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {Asset, Upgrade, Price} from "../lib/Structs.sol";

interface IEtherverseNFT is IERC721 {
    function setDeployed(uint256 chainId, bool _status) external;

    function colorRangesArray() external view returns (uint8[] memory);

    function svgColorsArray() external view returns (uint24[] memory);

    function statLabelsArray() external view returns (Asset.StatType[3] memory);

    function lockStatus(uint256 tokenId) external view returns (bool);

    function setTokenLockStatus(uint256 tokenId, uint256 unlockTime) external;

    function setSign(uint256 _sign) external;

    function setWhitelisted(address _address, bool _status) external;

    function changeCCIP(address newAdd) external;

    function changeURI(address _uri) external;

    function changeImageUrl(string calldata str) external;

    function setMintPricing(uint256 _amount, uint256 _split) external;

    function setUpgradePricing(uint256 _price, uint256 _split) external;

    function getTokenStats(
        uint256 tokenId
    ) external view returns (uint8[3] memory stats);

    function updateStats(
        uint256 tokenId,
        address newOwner,
        uint8[3] memory stats
    ) external returns (bool);

    function mint(
        address to,
        bytes memory authorizationParams
    ) external returns (uint256 tokenId);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function freeUpgrade(uint256 tokenId) external;

    function paidUpgrade(
        uint256 tokenId,
        bytes memory authorizationParams
    ) external;

    function resetUpgrades(uint256 tokenId) external;

    function nextUpgrade(
        uint256 tokenId,
        Upgrade.Type _type
    ) external view returns (Asset.Stat memory);

    function nextUpgradePrice(uint256 tokenId) external view returns (uint256);

    function getStat(
        Asset.StatType statLabel,
        uint256 tokenId
    ) external view returns (uint8 stat);

    function getOwner(uint256 tokenId) external view returns (address);

    function transferFrom(address from, address to, uint256 tokenId) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) external;

    function ccipTransfer(address from, address to, uint256 tokenId) external;

    function withdraw(address token) external;

    function colorRanges() external view returns (uint8[] memory);

    function svgColors() external view returns (uint24[] memory);

    function baseStat() external view returns (Asset.Stat memory);

    function assetType() external view returns (Asset.Type);

    function statLabels() external view returns (Asset.StatType[3] memory);

    function itemImage() external view returns (string memory);

    function etherverseWallet() external view returns (address);

    function assetCreatorWallet() external view returns (address);

    function USDC() external view returns (address);

    function ccipHandler() external view returns (address);

    function frameAddress() external view returns (address);

    function sign() external view returns (uint256);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function metadata() external view returns (string memory);

    function mintPricing() external view returns (Price memory);

    function upgradePricing(
        address _address
    ) external view returns (Price memory);

    function tokenLockedTill(uint256 tokenId) external view returns (uint256);

    function whitelisted(address _address) external view returns (bool);

    function upgradeMapping(
        uint256 tokenId
    ) external view returns (Asset.Stat memory);

    function isDeployed(uint256 chainId) external view returns (bool);
}
