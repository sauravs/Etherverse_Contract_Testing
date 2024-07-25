// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {Asset, Upgrade} from "../lib/RPGStruct.sol";

interface IRPGV1 is IERC721 {
    function setDeployed(uint256 chainId, bool _status) external;

    function colorRangesArray() external view returns (uint8[] memory);

    function svgColorsArray() external view returns (uint24[] memory);

    function statLabelsArray() external view returns (Asset.StatType[] memory);

    function lockStatus(uint256 tokenId) external view returns (bool);

    function setTokenLockStatus(uint256 tokenId, uint256 unlockTime) external;

    function setSign(uint256 _sign) external;

    function setWhitelisted(address _address, bool _status) external;

    function changeCCIP(address newAdd) external;

    function changeURI(address _uri) external;

    function changeImageUrl(string calldata str) external;

    function setMintPrice(uint256 _mintPrice) external;

    function setUpgradePrice(uint256 _price) external;

    function getTokenStats(uint256 tokenId) external view returns (uint8, uint8, uint8);

    function updateStats(uint256 tokenId, address newOwner, uint8 stat1, uint8 stat2, uint8 stat3)
        external
        returns (bool);

    function mint(address to, bytes memory authorizationParams) external returns (uint256 tokenId);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function freeUpgrade(uint256 tokenId) external;

    function paidUpgrade(uint256 tokenId, bytes memory authorizationParams) external;

    function resetUpgrades(uint256 tokenId) external;

    function nextUpgrade(uint256 tokenId, Upgrade.Type _type) external view returns (Asset.Stat memory);

    function nextUpgradePrice(uint256 tokenId) external view returns (uint256);

    function getStat(Asset.StatType statLabel, uint256 tokenId) external view returns (uint8 stat);

    function getOwner(uint256 tokenId) external view returns (address);

    function transferFrom(address from, address to, uint256 tokenId) external;

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) external;

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

    function uriAddress() external view returns (address);

    function sign() external view returns (uint256);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function mintPrice() external view returns (uint256);

    function upgradePricing(address _address) external view returns (uint256);

    function tokenLockedTill(uint256 tokenId) external view returns (uint256);

    function whitelisted(address _address) external view returns (bool);

    function upgradeMapping(uint256 tokenId) external view returns (Asset.Stat memory);

    function isDeployed(uint256 chainId) external view returns (bool);
}
