// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;
import {Asset} from "../lib/Structs.sol";

interface IUpgradeV1 {
    function upgradeName() external view returns (string memory);

    function calculateUpgrade(
        Asset.Stat memory _stat,
        uint8 _increment
    ) external returns (Asset.Stat memory);

    function calculateStat(
        Asset.Stat memory _stat,
        uint8 _increment
    ) external pure returns (Asset.Stat memory);

    function getStat(
        Asset.StatType statLabel,
        uint256 tokenId
    ) external view returns (uint8 stat);

    function calculatePrice(
        uint256 BASE_PRICE_IN_USDC,
        Asset.Stat memory _stat
    ) external pure returns (uint256);
}
