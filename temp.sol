// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/RPGItemNFT.sol";
import "../src/lib/RPGStruct.sol";
import "../src/Fee.sol";
import "../src/interface/IUSDC.sol";
import "../src/lib/errors.sol";

contract RPGItemNFTTest is Test {
    RPGItemNFT public rpgItemNFT;
    address public owner = address(0x1);
    address public user = address(0x2);
    address public ccipHandler = address(0x3);
    address public usdc = address(0x4);

    function setUp() public {
        vm.startPrank(owner);
        rpgItemNFT = new RPGItemNFT();
        rpgItemNFT.transferOwnership(owner);
        vm.stopPrank();
    }

    function testConstructor() public {
        assertEq(rpgItemNFT.etherverseWallet(), 0x0C903F1C518724CBF9D00b18C2Db5341fF68269C);
        assertEq(rpgItemNFT.assetCreatorWallet(), 0xa1293A8bFf9323aAd0419E46Dd9846Cc7363D44b);
        assertEq(rpgItemNFT.USDC(), 0x0Fd9e8d3aF1aaee056EB9e802c3A762a667b1904);
        assertEq(rpgItemNFT.mintPrice(), 100000);
        assertEq(rpgItemNFT._nextTokenId(), 1000000);
    }

    function testGetTokenStats() public {
        vm.startPrank(owner);
        rpgItemNFT.mint(user, "");
        vm.stopPrank();

        (uint8 stat1, uint8 stat2, uint8 stat3) = rpgItemNFT.getTokenStats(1000000);
        assertEq(stat1, 10);
        assertEq(stat2, 20);
        assertEq(stat3, 30);
    }

    function testUpdateStats() public {
        vm.startPrank(owner);
        rpgItemNFT.mint(user, "");
        vm.stopPrank();

        vm.startPrank(ccipHandler);
        rpgItemNFT.updateStats(1000000, user, 15, 25, 35);
        vm.stopPrank();

        (uint8 stat1, uint8 stat2, uint8 stat3) = rpgItemNFT.getTokenStats(1000000);
        assertEq(stat1, 15);
        assertEq(stat2, 25);
        assertEq(stat3, 35);
    }

    function testMint() public {
        vm.startPrank(owner);
        rpgItemNFT.whitelistAddress(owner);
        vm.stopPrank();

        vm.startPrank(owner);
        uint256 tokenId = rpgItemNFT.mint(user, "");
        vm.stopPrank();

        assertEq(tokenId, 1000000);
        assertEq(rpgItemNFT.ownerOf(tokenId), user);
    }
}