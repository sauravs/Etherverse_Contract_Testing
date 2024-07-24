// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/RPGItemNFT.sol";
import "../src/lib/RPGStruct.sol";
import "../src/lib/errors.sol";

contract RPGItemNFTTest is Test {
    RPGItemNFT public rpgItemNFT;
    address public owner = address(0x762aD31Ff4bD1ceb5b3b5868672d5CBEaEf609dF);
    address public ccipHandler = 0x3c7444D7351027473698a7DCe751eE6Aea8036ee;

    function setUp() public {
        rpgItemNFT = new RPGItemNFT();
    }

    function testConstructor() public {
        // Check initial values set by the constructor
        assertEq(rpgItemNFT.name(), "Sword");
        assertEq(rpgItemNFT.symbol(), "SW");
        assertEq(rpgItemNFT.etherverseWallet(), 0x0C903F1C518724CBF9D00b18C2Db5341fF68269C);
        assertEq(rpgItemNFT.assetCreatorWallet(), 0xa1293A8bFf9323aAd0419E46Dd9846Cc7363D44b);
        assertEq(rpgItemNFT.USDC(), 0x0Fd9e8d3aF1aaee056EB9e802c3A762a667b1904);
        assertEq(rpgItemNFT.baseStat().stat1, 10);
        assertEq(rpgItemNFT.baseStat().stat2, 20);
        assertEq(rpgItemNFT.baseStat().stat3, 30);
        assertEq(uint(rpgItemNFT.statLabels(0)), uint(Asset.StatType.STR));
        assertEq(uint(rpgItemNFT.statLabels(1)), uint(Asset.StatType.CON));
        assertEq(uint(rpgItemNFT.statLabels(2)), uint(Asset.StatType.DEX));
        assertEq(uint(rpgItemNFT.AssetType()), uint(Asset.Type.Weapon));
        assertEq(rpgItemNFT.svgColors(0), 213);
        assertEq(rpgItemNFT.svgColors(1), 123);
        assertEq(rpgItemNFT.svgColors(2), 312);
        assertEq(rpgItemNFT.colorRanges(0), 0);
        assertEq(rpgItemNFT.colorRanges(1), 10);
        assertEq(rpgItemNFT.colorRanges(2), 20);
        assertEq(rpgItemNFT.colorRanges(3), 30);
        assertEq(rpgItemNFT.itemImage(), "https://ipfs.io/ipfs/QmVQ2vpBD1U6P22V2xaHk5KF5x6mQAM7HmFsc8c2AsQhgo");
        assertEq(rpgItemNFT._ccipHandler(), 0x3c7444D7351027473698a7DCe751eE6Aea8036ee);
        assertEq(rpgItemNFT.mintPrice(), 100000);
        assertEq(rpgItemNFT.isDeployed(block.chainid), true);
        assertEq(rpgItemNFT.uriAddress(), address(0));
        assertEq(rpgItemNFT._nextTokenId(), 1000000);
    }

    function testSetDeployed() public {
        rpgItemNFT.setDeployed(1, true);
        assertEq(rpgItemNFT.isDeployed(1), true);
    }

    function testColorRangesArray() public {
        uint8[] memory colorRanges = rpgItemNFT.colorRangesArray();
        assertEq(colorRanges.length, 4);
        assertEq(colorRanges[0], 0);
        assertEq(colorRanges[1], 10);
        assertEq(colorRanges[2], 20);
        assertEq(colorRanges[3], 30);
    }

    function testSvgColorsArray() public {
        uint24[] memory svgColors = rpgItemNFT.svgColorsArray();
        assertEq(svgColors.length, 3);
        assertEq(svgColors[0], 213);
        assertEq(svgColors[1], 123);
        assertEq(svgColors[2], 312);
    }

    function testStatLabelsArray() public {
        Asset.StatType[3] memory statLabels = rpgItemNFT.statLabelsArray();
        assertEq(uint(statLabels[0]), uint(Asset.StatType.STR));
        assertEq(uint(statLabels[1]), uint(Asset.StatType.CON));
        assertEq(uint(statLabels[2]), uint(Asset.StatType.DEX));
    }

    function testLockStatus() public {
        uint256 tokenId = 1;
        vm.prank(ccipHandler);
        rpgItemNFT.setTokenLockStatus(tokenId, block.timestamp + 1000);
        assertEq(rpgItemNFT.lockStatus(tokenId), true);
    }

    function testSetTokenLockStatus() public {
        uint256 tokenId = 1;
        uint256 unlockTime = block.timestamp + 1000;
        vm.prank(ccipHandler);
        rpgItemNFT.setTokenLockStatus(tokenId, unlockTime);
        assertEq(rpgItemNFT.tokenLockedTill(tokenId), unlockTime);
    }
}


/////////////////////////////////////////////////////////////

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/RPGItemNFT.sol";
import "../src/lib/RPGStruct.sol";
import "../src/lib/errors.sol";

contract RPGItemNFTTest is Test {
    RPGItemNFT public rpgItemNFT;
    address public owner = 0x762aD31Ff4bD1ceb5b3b5868672d5CBEaEf609dF;
    address public ccipHandler = 0x3c7444D7351027473698a7DCe751eE6Aea8036ee;
    address public user = address(0x3);

    function setUp() public {
        vm.startPrank(owner);
        rpgItemNFT = new RPGItemNFT();
        vm.stopPrank();
    }

    function testConstructor() public {
        // Check initial values set by the constructor
        assertEq(rpgItemNFT.name(), "Sword");
        assertEq(rpgItemNFT.symbol(), "SW");
        assertEq(rpgItemNFT.etherverseWallet(), 0x0C903F1C518724CBF9D00b18C2Db5341fF68269C);
        assertEq(rpgItemNFT.assetCreatorWallet(), 0xa1293A8bFf9323aAd0419E46Dd9846Cc7363D44b);
        assertEq(rpgItemNFT.USDC(), 0x0Fd9e8d3aF1aaee056EB9e802c3A762a667b1904);

        // Destructure the tuple returned by baseStat
        (uint8 stat1, uint8 stat2, uint8 stat3) = rpgItemNFT.baseStat();
        assertEq(stat1, 10);
        assertEq(stat2, 20);
        assertEq(stat3, 30);

        assertEq(uint(rpgItemNFT.statLabels(0)), uint(Asset.StatType.STR));
        assertEq(uint(rpgItemNFT.statLabels(1)), uint(Asset.StatType.CON));
        assertEq(uint(rpgItemNFT.statLabels(2)), uint(Asset.StatType.DEX));
        assertEq(uint(rpgItemNFT.AssetType()), uint(Asset.Type.Weapon));
        assertEq(rpgItemNFT.svgColors(0), 213);
        assertEq(rpgItemNFT.svgColors(1), 123);
        assertEq(rpgItemNFT.svgColors(2), 312);
    }
}