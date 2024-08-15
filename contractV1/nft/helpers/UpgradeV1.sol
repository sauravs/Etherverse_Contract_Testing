// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/Strings.sol";
import "../RPGUtil.sol";
import {Asset} from "../lib/RPGStruct.sol";
import {IRPGV1} from "../interface/IRPG.sol";

contract UpgradeV1 {
    mapping(bytes32 => Asset.Stat) newStatMap;

    function calculateUpgrade(Asset.Stat memory _stat, uint8 _increment) external returns (Asset.Stat memory) {
        bytes32 hash = RPGUtil._generateStatHash(_stat);
        Asset.Stat memory newStat = newStatMap[hash];
        if (RPGUtil.isEmptyStat(newStat)) {
            newStat = calculateStat(_stat, _increment);
            newStatMap[hash] = newStat;
        }
        return newStat;
    }

    function calculateStat(Asset.Stat memory _stat, uint8 _increment) public pure returns (Asset.Stat memory) {
        _stat.stat1 = _stat.stat1 + _increment < 100 ? _stat.stat1 + _increment : 100;

        _stat.stat2 = _stat.stat2 + _increment < 100 ? _stat.stat2 + _increment : 100;

        _stat.stat3 = _stat.stat3 + _increment < 100 ? _stat.stat3 + _increment : 100;

        return _stat;
    }

    function statPriceMultiplier(Asset.Stat memory _stat) internal pure returns (uint256) {
        return ((uint256(_stat.stat1) + uint256(_stat.stat2) + uint256(_stat.stat3)) * 100) / 3;
    }

    function calculatePrice(
        uint256 BASE_PRICE_IN_USDC,
        Asset.Stat memory _stat // @dev updated working
    ) external pure returns (uint256) {
        return ((BASE_PRICE_IN_USDC) * statPriceMultiplier(_stat)) / 100;
    }
       //stats value 10,20,30 = (60/3 ) * setUpgradePrice/upgradePricing()->in RPG.sol)

    function getStat(Asset.StatType statLabel, uint256 tokenId) external view returns (uint8 stat) {
        IRPGV1 nft = IRPGV1(msg.sender);
        Asset.StatType[3] memory statLabels = nft.statLabels();
        if (statLabel == statLabels[0]) {
            return nft.upgradeMapping(tokenId).stat1 + nft.baseStat().stat1;
        } else if (statLabel == statLabels[1]) {
            return nft.upgradeMapping(tokenId).stat2 + nft.baseStat().stat2;
        } else if (statLabel == statLabels[2]) {
            return nft.upgradeMapping(tokenId).stat3 + nft.baseStat().stat3;
        } else {
            return 0;
        }
    }
}
