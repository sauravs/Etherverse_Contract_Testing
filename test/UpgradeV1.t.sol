// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.20;

// import "forge-std/Test.sol";
// import "../src/nft/helpers/UpgradeV1.sol";
// import "../src/nft/lib/Utils.sol";
// import {Asset} from "../src/nft/lib/Structs.sol";
// import {IEtherverseNFT} from "../src/nft/interface/IEtherverseNFT.sol";

// contract UpgradeV1Test is Test {
//     UpgradeV1 upgradeV1;

//     function setUp() public {
//         upgradeV1 = new UpgradeV1();
//         console.log("UpgradeV1 address: ", address(upgradeV1));
//         //0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f
//     }

//     function testCalculateUpgrade() public {
//         Asset.Stat memory stat = Asset.Stat({stat1: 10, stat2: 20, stat3: 30});
//         Asset.Stat memory newStat = upgradeV1.calculateUpgrade(stat, 5);
//         assertEq(newStat.stat1, 15);
//         assertEq(newStat.stat2, 25);
//         assertEq(newStat.stat3, 35);
//     }

//     function testCalculateStat() public {
//         Asset.Stat memory stat = Asset.Stat({stat1: 10, stat2: 20, stat3: 30});
//         Asset.Stat memory newStat = upgradeV1.calculateStat(stat, 5);
//         assertEq(newStat.stat1, 15);
//         assertEq(newStat.stat2, 25);
//         assertEq(newStat.stat3, 35);
//     }

//     function testCalculatePrice() public {
//         Asset.Stat memory stat = Asset.Stat({stat1: 10, stat2: 20, stat3: 30});
//         uint256 price = upgradeV1.calculatePrice(100, stat);
//         assertEq(price, 2000);
//     }

//     function testGetStat() public {
//         // Mock the IEtherverseNFT interface
//         IEtherverseNFT nft = IEtherverseNFT(address(this));
//         Asset.StatType statLabel = Asset.StatType.STR;
//         uint256 tokenId = 1;

//         // Mock the return values
//         vm.mockCall(
//             address(nft),
//             abi.encodeWithSelector(IEtherverseNFT.statLabels.selector),
//             abi.encode([Asset.StatType.STR, Asset.StatType.DEX, Asset.StatType.CON])
//         );
//         vm.mockCall(
//             address(nft),
//             abi.encodeWithSelector(IEtherverseNFT.upgradeMapping.selector, tokenId),
//             abi.encode(Asset.Stat({stat1: 10, stat2: 20, stat3: 30}))
//         );
//         vm.mockCall(
//             address(nft),
//             abi.encodeWithSelector(IEtherverseNFT.baseStat.selector),
//             abi.encode(Asset.Stat({stat1: 5, stat2: 5, stat3: 5}))
//         );

//         uint8 stat = upgradeV1.getStat(statLabel, tokenId);
//         assertEq(stat, 15);

//         Asset.StatType statLabel2 = Asset.StatType.DEX;

//         uint8 stat2 = upgradeV1.getStat(statLabel2, tokenId);
//         assertEq(stat2, 25);

//         Asset.StatType statLabel3 = Asset.StatType.CON;

//         uint8 stat3 = upgradeV1.getStat(statLabel3, tokenId);
//         assertEq(stat3, 35);
//     }
// }
