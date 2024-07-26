// // SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {RPGItemNFT} from "../src/nft/RPG.sol";
import "../src/nft/lib/RPGStruct.sol";
import "../src/nft/lib/errors.sol";
import "../src/common/interface/IUSDC.sol";
import "../src/nft/Fee.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../src/mock/MockUSDC.sol";

contract RPGItemNFTTest is Test {
    RPGItemNFT public rpgItemNFT;
    address public owner = 0x762aD31Ff4bD1ceb5b3b5868672d5CBEaEf609dF;
    address public ccipHandler = 0x3c7444D7351027473698a7DCe751eE6Aea8036ee;
    address public whitelisted_user1 = address(0x3);
    address public user = address(0x4);
    address public minter1 = address(0x5);
    address public minter2 = address(0x6);
    address public nonWhitelistedUser = address(0x3);
    

    MockUSDC public usdc;

    bytes emptyAuthParams = "";

    function setUp() public {
        vm.startPrank(owner);
        rpgItemNFT = new RPGItemNFT();
        vm.stopPrank();

        // Deploy Mock USDC token
        usdc = new MockUSDC();

        // Set the USDC address in the RPGItemNFT contract
        vm.prank(owner);
        rpgItemNFT.setUSDC(address(usdc));

        //console.log("USDC address: ", address(usdc));

        // 100000 USDC with 6 decimals

        uint256 amount = 100000 * 10 ** 6;

        usdc.mint(whitelisted_user1, amount);

        // assert that the whitelisted_user1 account has 100 USDC

        assertEq(usdc.balanceOf(whitelisted_user1), amount);

        // set the whitelisted_user1 as whitelisted

        vm.prank(owner);
        rpgItemNFT.setWhitelisted(whitelisted_user1, true);

        //assert that the whitelisted_user1 is whitelisted
        assertTrue(rpgItemNFT.whitelisted(whitelisted_user1));
    }

    function testConstructor() public {
        // Check initial values set by the constructor
        assertEq(rpgItemNFT.name(), "Sword");
        assertEq(rpgItemNFT.symbol(), "SW");
        assertEq(rpgItemNFT.etherverseWallet(), 0x0C903F1C518724CBF9D00b18C2Db5341fF68269C);
        assertEq(rpgItemNFT.assetCreatorWallet(), 0xa1293A8bFf9323aAd0419E46Dd9846Cc7363D44b);
        assertEq(rpgItemNFT.USDC(), 0xFEfC6BAF87cF3684058D62Da40Ff3A795946Ab06);
        // assertEq(rpgItemNFT.baseStat().stat1, 10);
        // assertEq(rpgItemNFT.baseStat().stat2, 20);
        // assertEq(rpgItemNFT.baseStat().stat3, 30);

        (uint8 stat1, uint8 stat2, uint8 stat3) = rpgItemNFT.baseStat();
        assertEq(stat1, 10);
        assertEq(stat2, 20);
        assertEq(stat3, 30);

        assertEq(uint256(rpgItemNFT.statLabels(0)), uint256(Asset.StatType.STR));
        assertEq(uint256(rpgItemNFT.statLabels(1)), uint256(Asset.StatType.CON));
        assertEq(uint256(rpgItemNFT.statLabels(2)), uint256(Asset.StatType.DEX));
        assertEq(uint256(rpgItemNFT.AssetType()), uint256(Asset.Type.Weapon));
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
        vm.prank(owner);
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
        assertEq(uint256(statLabels[0]), uint256(Asset.StatType.STR));
        assertEq(uint256(statLabels[1]), uint256(Asset.StatType.CON));
        assertEq(uint256(statLabels[2]), uint256(Asset.StatType.DEX));
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

    function testSetSign() public {
        vm.startPrank(owner);
        rpgItemNFT.setSign(12345);
        assertEq(rpgItemNFT.sign(), 12345);
        vm.stopPrank();
    }

    function testSetWhitelisted() public {
        vm.startPrank(owner);
        rpgItemNFT.setWhitelisted(user, true);
        assertTrue(rpgItemNFT.whitelisted(user));
        vm.stopPrank();
    }

    function testChangeCCIP() public {
        vm.startPrank(owner);
        address newCCIP = address(0x4);
        rpgItemNFT.changeCCIP(newCCIP);
        assertEq(rpgItemNFT._ccipHandler(), newCCIP);
        vm.stopPrank();
    }

    function testChangeURI() public {
        vm.startPrank(owner);
        address newURI = address(0x5);
        rpgItemNFT.changeURI(newURI);
        assertEq(rpgItemNFT.uriAddress(), newURI);
        vm.stopPrank();
    }

    function testChangeImageUrl() public {
        vm.startPrank(owner);
        string memory newImageUrl = "https://newimage.url";
        rpgItemNFT.changeImageUrl(newImageUrl);
        assertEq(rpgItemNFT.itemImage(), newImageUrl);
        vm.stopPrank();
    }

    function testSetMintPrice() public {
        vm.startPrank(owner);
        rpgItemNFT.setMintPrice(200000);
        assertEq(rpgItemNFT.mintPrice(), 200000);
        vm.expectRevert(Errors.ZeroInput.selector);
        rpgItemNFT.setMintPrice(0);
        vm.stopPrank();
    }

    function testSetUpgradePrice() public {
        vm.startPrank(owner);
        rpgItemNFT.setWhitelisted(user, true);
        vm.stopPrank();

        vm.startPrank(user);
        rpgItemNFT.setUpgradePrice(50000);
        assertEq(rpgItemNFT.upgradePricing(user), 50000);
        vm.stopPrank();
    }

    // function mintNFT public {

    // }

    function testMintSuccess() public {
        // set the whitelisted_user1 as whitelisted

        vm.prank(owner);
        rpgItemNFT.setWhitelisted(whitelisted_user1, true);

        //assert that the whitelisted_user1 is whitelisted
        assertTrue(rpgItemNFT.whitelisted(whitelisted_user1));

        // set the mint price to 0.1 USDC(USDC has 6 decimals)
        vm.prank(owner);
        rpgItemNFT.setMintPrice(100000);

        //assert that mint price is set to 0.1 USDC

        assertEq(rpgItemNFT.mintPrice(), 100000);

        // top up the whitelisted_user1 account with 0.1 ether for purpose of paying transaction fee
        vm.deal(whitelisted_user1, 100000000000000000);

        // assert that the whitelisted_user1 account has 0.1 ether

        assertEq(address(whitelisted_user1).balance, 100000000000000000);

        // aprove the RPGItemNFT contract to spend 0.1 USDC on behalf of the whitelisted_user1

        vm.prank(whitelisted_user1);
        usdc.approve(address(rpgItemNFT), 100000);

        //mint the NFT to whitelisted_user1 by the whitelisted_user1
        vm.prank(whitelisted_user1);
        uint256 tokenId = rpgItemNFT.mint(whitelisted_user1, emptyAuthParams);

        // assert that the tokenId is 1000000
        assertEq(tokenId, 1000000);

        // assert that whitelisted_user1 is the owner of the minted tokenId

        assertEq(rpgItemNFT.ownerOf(tokenId), whitelisted_user1);
    }

    function testMintRevertNotWhitelisted() public {
        // set the mint price to 0.1 USDC(USDC has 6 decimals)
        vm.prank(owner);
        rpgItemNFT.setMintPrice(100000);

        //assert that mint price is set to 0.1 USDC

        assertEq(rpgItemNFT.mintPrice(), 100000);

        // top up the minter1 account with 0.1 ether for purpose of paying transaction fee
        vm.deal(minter1, 100000000000000000);

        // assert that the minter1 account has 0.1 ether

        assertEq(address(minter1).balance, 100000000000000000);

        // aprove the RPGItemNFT contract to spend 0.1 USDC on behalf of the minter1

        vm.prank(minter1);
        usdc.approve(address(rpgItemNFT), 100000);

        //try to mint the NFT to minter1 by the minter1 which is not whitelisted by owner
        vm.prank(minter1);
        vm.expectRevert(abi.encodeWithSelector(Errors.CallerMustBeWhitelisted.selector, minter1));

        uint256 tokenId = rpgItemNFT.mint(minter1, emptyAuthParams);
    }

    function testMintRevertInsufficientUSDC() public {
        // set the mint price to 0.1 USDC
        vm.prank(owner);
        rpgItemNFT.setMintPrice(100000);

        // top up the minter2 account with 0.1 ether for purpose of paying transaction fee
        vm.deal(minter2, 100000000000000000);

        // top up minter2 with insufficient USDC of amount 0.01USDC

        uint256 amount = 0.01 * 10 ** 6;

        usdc.mint(minter2, amount);

        // whitelist minter2 account by the owner

        vm.prank(owner);
        rpgItemNFT.setWhitelisted(minter2, true);

        // aprove the RPGItemNFT contract to spend 0.1 USDC on behalf of the minter2

        vm.prank(minter2);
        usdc.approve(address(rpgItemNFT), 100000);

        //try to mint the NFT to minter2 by the minter2 which has insufficient USDC
        vm.prank(minter2);
        vm.expectRevert("Insufficient balance");

        uint256 tokenId = rpgItemNFT.mint(minter2, emptyAuthParams);
    }

    function skiptestMintRevertExceedsCapacity() public {
        // set the whitelisted_user1 as whitelisted

        vm.prank(owner);
        rpgItemNFT.setWhitelisted(whitelisted_user1, true);

        uint256 STARTING_TOKEN_ID = 1000000;
        uint256 exceededTokenID = STARTING_TOKEN_ID + 100000 + 1;

        // set the mint price to 0.1 USDC(USDC has 6 decimals)
        vm.prank(owner);
        rpgItemNFT.setMintPrice(100000);

        //assert that mint price is set to 0.1 USDC

        assertEq(rpgItemNFT.mintPrice(), 100000);

        // top up the whitelisted_user1 account with 0.1 ether for purpose of paying transaction fee
        vm.deal(whitelisted_user1, 100000000000000000);

        // assert that the whitelisted_user1 account has 0.1 ether

        assertEq(address(whitelisted_user1).balance, 100000000000000000);

        // aprove the RPGItemNFT contract to spend 0.1 USDC on behalf of the whitelisted_user1

        vm.prank(whitelisted_user1);
        usdc.approve(address(rpgItemNFT), 100000);

        vm.prank(whitelisted_user1);

        for (uint256 i = 0; i <= exceededTokenID; i++) {
            if (i == exceededTokenID) {
                vm.expectRevert(abi.encodeWithSelector(Errors.ExceedsCapacity.selector, whitelisted_user1));

                rpgItemNFT.mint(whitelisted_user1, emptyAuthParams);
            }
            rpgItemNFT.mint(whitelisted_user1, emptyAuthParams);
        }
    }

    function testGetTokenStats() public {
        //mint the nft first

        vm.prank(whitelisted_user1);
        // approve the RPGItemNFT contract to spend 0.1 USDC on behalf of the whitelisted_user1

        usdc.approve(address(rpgItemNFT), 100000);

        //mint the NFT to whitelisted_user1 by the whitelisted_user1

        vm.prank(whitelisted_user1);
        uint256 tokenId = rpgItemNFT.mint(whitelisted_user1, emptyAuthParams);

        //assert that the tokenId is 1000000

        assertEq(tokenId, 1000000);

        // assert that whitelisted_user1 is the owner of the minted tokenId

        assertEq(rpgItemNFT.ownerOf(tokenId), whitelisted_user1);

        (uint8 stat1, uint8 stat2, uint8 stat3) = rpgItemNFT.getTokenStats(tokenId);
        assertEq(stat1, 10);
        assertEq(stat2, 20);
        assertEq(stat3, 30);
    }

    function testGetTokenStatsRevertNotMinted() public {
        vm.expectRevert(Errors.NotMinted.selector);
        rpgItemNFT.getTokenStats(9999999);
    }

    function testUpdateStats() public {
        // mint the NFT

        //mint the nft first

        vm.prank(whitelisted_user1);
        // approve the RPGItemNFT contract to spend 0.1 USDC on behalf of the whitelisted_user1

        usdc.approve(address(rpgItemNFT), 100000);

        //mint the NFT to whitelisted_user1 by the whitelisted_user1

        vm.prank(whitelisted_user1);
        uint256 tokenId = rpgItemNFT.mint(whitelisted_user1, emptyAuthParams);

        //assert that the tokenId is 1000000

        assertEq(tokenId, 1000000);

        // assert that whitelisted_user1 is the owner of the minted tokenId

        assertEq(rpgItemNFT.ownerOf(tokenId), whitelisted_user1);

        //update the stats

        vm.startPrank(ccipHandler);
        bool success = rpgItemNFT.updateStats(tokenId, user, 15, 25, 35);
        vm.stopPrank();

        assertTrue(success);

        (uint8 stat1, uint8 stat2, uint8 stat3) = rpgItemNFT.getTokenStats(tokenId);
        assertEq(stat1, 25); //10+15 (basestat + upgrade)
        assertEq(stat2, 45); //20+25
        assertEq(stat3, 65); // 30+35
    }

    function testUpdateStatsRevertZeroAddress() public {
        // mint the NFT

        vm.prank(whitelisted_user1);
        // approve the RPGItemNFT contract to spend 0.1 USDC on behalf of the whitelisted_user1

        usdc.approve(address(rpgItemNFT), 100000);

        //mint the NFT to whitelisted_user1 by the whitelisted_user1

        vm.prank(whitelisted_user1);
        uint256 tokenId = rpgItemNFT.mint(whitelisted_user1, emptyAuthParams);

        //assert that the tokenId is 1000000

        assertEq(tokenId, 1000000);

        // assert that whitelisted_user1 is the owner of the minted tokenId

        assertEq(rpgItemNFT.ownerOf(tokenId), whitelisted_user1);

        vm.startPrank(ccipHandler);
        vm.expectRevert(Errors.ZeroAddress.selector);
        rpgItemNFT.updateStats(tokenId, address(0), 15, 25, 35);
        vm.stopPrank();
    }

    function skiptestUpdateStatsRevertUnauthorizedAccess() public {
        // mint the NFT

        vm.prank(whitelisted_user1);
        // approve the RPGItemNFT contract to spend 0.1 USDC on behalf of the whitelisted_user1

        usdc.approve(address(rpgItemNFT), 100000);

        //mint the NFT to whitelisted_user1 by the whitelisted_user1

        vm.prank(whitelisted_user1);
        uint256 tokenId = rpgItemNFT.mint(whitelisted_user1, emptyAuthParams);

        //assert that the tokenId is 1000000

        assertEq(tokenId, 1000000);

        // assert that whitelisted_user1 is the owner of the minted tokenId

        assertEq(rpgItemNFT.ownerOf(tokenId), whitelisted_user1);

        vm.startPrank(minter1);
        vm.expectRevert(Errors.UnauthorizedAccess.selector);
        rpgItemNFT.updateStats(tokenId, minter1, 15, 25, 35);
        vm.stopPrank();
    }

    function testGetStatValid() public {
        // mint the NFT

        vm.prank(whitelisted_user1);
        // approve the RPGItemNFT contract to spend 0.1 USDC on behalf of the whitelisted_user1

        usdc.approve(address(rpgItemNFT), 100000);

        //mint the NFT to whitelisted_user1 by the whitelisted_user1

        vm.prank(whitelisted_user1);
        uint256 tokenId = rpgItemNFT.mint(whitelisted_user1, emptyAuthParams);

        //assert that the tokenId is 1000000

        assertEq(tokenId, 1000000);

        // assert that whitelisted_user1 is the owner of the minted tokenId

        assertEq(rpgItemNFT.ownerOf(tokenId), whitelisted_user1);

        uint8 stat = rpgItemNFT.getStat(Asset.StatType.STR, tokenId);
        assertEq(stat, 10);

        uint8 stat2 = rpgItemNFT.getStat(Asset.StatType.CON, tokenId);
        assertEq(stat2, 20);

        uint8 stat3 = rpgItemNFT.getStat(Asset.StatType.DEX, tokenId);
        assertEq(stat3, 30);
    }

    function testGetStatNotMinted() public {
        uint256 tokenId = 1;
        vm.expectRevert(Errors.NotMinted.selector);
        rpgItemNFT.getStat(Asset.StatType.STR, tokenId + 1);
    }

    function testGetStatLocked() public {
        // mint the NFT

        vm.prank(whitelisted_user1);
        // approve the RPGItemNFT contract to spend 0.1 USDC on behalf of the whitelisted_user1

        usdc.approve(address(rpgItemNFT), 100000);

        //mint the NFT to whitelisted_user1 by the whitelisted_user1

        vm.prank(whitelisted_user1);
        uint256 tokenId = rpgItemNFT.mint(whitelisted_user1, emptyAuthParams);

        //assert that the tokenId is 1000000

        assertEq(tokenId, 1000000);

        // assert that whitelisted_user1 is the owner of the minted tokenId

        assertEq(rpgItemNFT.ownerOf(tokenId), whitelisted_user1);

        vm.prank(ccipHandler);

        rpgItemNFT.setTokenLockStatus(tokenId, block.timestamp + 1 days);

        //check lockstatus

        assertEq(rpgItemNFT.lockStatus(tokenId), true);

        vm.expectRevert(abi.encodeWithSelector(Errors.Locked.selector, tokenId, block.timestamp));
        rpgItemNFT.getStat(Asset.StatType.STR, tokenId);
    }

    function skiptestTokenURIValid() public {
        // mint the NFT

        vm.prank(whitelisted_user1);
        // approve the RPGItemNFT contract to spend 0.1 USDC on behalf of the whitelisted_user1

        usdc.approve(address(rpgItemNFT), 100000);

        //mint the NFT to whitelisted_user1 by the whitelisted_user1

        vm.prank(whitelisted_user1);
        uint256 tokenId = rpgItemNFT.mint(whitelisted_user1, emptyAuthParams);

        //assert that the tokenId is 1000000

        assertEq(tokenId, 1000000);

        // assert that whitelisted_user1 is the owner of the minted tokenId

        assertEq(rpgItemNFT.ownerOf(tokenId), whitelisted_user1);

        string memory uri = rpgItemNFT.tokenURI(tokenId);
        assertEq(uri, "https://ipfs.io/ipfs/QmVQ2vpBD1U6P22V2xaHk5KF5x6mQAM7HmFsc8c2AsQhgo");
    }

    function testTransferFromSuccess() public {
        // mint the nft first

        vm.prank(whitelisted_user1);
        // approve the RPGItemNFT contract to spend 0.1 USDC on behalf of the whitelisted_user1

        usdc.approve(address(rpgItemNFT), 100000);

        //mint the NFT to whitelisted_user1 by the whitelisted_user1

        vm.prank(whitelisted_user1);
        uint256 tokenId = rpgItemNFT.mint(whitelisted_user1, emptyAuthParams);

        //assert that the tokenId is 1000000

        assertEq(tokenId, 1000000);

        // assert that whitelisted_user1 is the owner of the minted tokenId

        assertEq(rpgItemNFT.ownerOf(tokenId), whitelisted_user1);

        vm.prank(whitelisted_user1);
        rpgItemNFT.transferFrom(whitelisted_user1, minter1, tokenId);
        assertEq(rpgItemNFT.ownerOf(tokenId), minter1);
    }

     function testTransferFromZeroAddress() public {
        
        // mint the nft first

        vm.prank(whitelisted_user1);
        usdc.approve(address(rpgItemNFT), 100000);

        vm.prank(whitelisted_user1);
        uint256 tokenId = rpgItemNFT.mint(whitelisted_user1, emptyAuthParams);
        assertEq(rpgItemNFT.ownerOf(tokenId), whitelisted_user1);
        
        vm.prank(whitelisted_user1);
        vm.expectRevert(Errors.ZeroAddress.selector);
        rpgItemNFT.transferFrom(whitelisted_user1, address(0), tokenId);
    }


        function testTransferFromLockedToken() public {
        
        // mint the nft first

        vm.prank(whitelisted_user1);
        usdc.approve(address(rpgItemNFT), 100000);

        vm.prank(whitelisted_user1);
        uint256 tokenId = rpgItemNFT.mint(whitelisted_user1, emptyAuthParams);
        assertEq(rpgItemNFT.ownerOf(tokenId), whitelisted_user1);
        
        // lock the token
         vm.prank(ccipHandler);
        rpgItemNFT.setTokenLockStatus(tokenId, block.timestamp + 1 days);
        assertEq(rpgItemNFT.lockStatus(tokenId), true);
        
        vm.prank(whitelisted_user1);
        vm.expectRevert(abi.encodeWithSelector(Errors.Locked.selector, tokenId, block.timestamp));
        rpgItemNFT.transferFrom(whitelisted_user1, minter1, tokenId);
    }

     function testSafeTransferFromSuccess() public {
        
        
         // mint the nft first

        vm.prank(whitelisted_user1);
        usdc.approve(address(rpgItemNFT), 100000);

        vm.prank(whitelisted_user1);
        uint256 tokenId = rpgItemNFT.mint(whitelisted_user1, emptyAuthParams);
        assertEq(rpgItemNFT.ownerOf(tokenId), whitelisted_user1);
        
        
        
        vm.prank(whitelisted_user1);
        rpgItemNFT.safeTransferFrom(whitelisted_user1, minter1, tokenId,"");
        assertEq(rpgItemNFT.ownerOf(tokenId), minter1);
    }

    function testSafeTransferFromZeroAddress() public {
        
        
         // mint the nft first

        vm.prank(whitelisted_user1);
        usdc.approve(address(rpgItemNFT), 100000);

        vm.prank(whitelisted_user1);
        uint256 tokenId = rpgItemNFT.mint(whitelisted_user1, emptyAuthParams);
        assertEq(rpgItemNFT.ownerOf(tokenId), whitelisted_user1);
        
         vm.prank(whitelisted_user1);
        vm.expectRevert(Errors.ZeroAddress.selector);
        rpgItemNFT.safeTransferFrom(whitelisted_user1, address(0), tokenId ,"");
    }

    function testSafeTransferFromLockedToken() public {
        
         // mint the nft first

        vm.prank(whitelisted_user1);
        usdc.approve(address(rpgItemNFT), 100000);

        vm.prank(whitelisted_user1);
        uint256 tokenId = rpgItemNFT.mint(whitelisted_user1, emptyAuthParams);
        assertEq(rpgItemNFT.ownerOf(tokenId), whitelisted_user1);


          // lock the token
         vm.prank(ccipHandler);
        rpgItemNFT.setTokenLockStatus(tokenId, block.timestamp + 1 days);
        assertEq(rpgItemNFT.lockStatus(tokenId), true);
        
        vm.prank(whitelisted_user1);
        vm.expectRevert(abi.encodeWithSelector(Errors.Locked.selector, tokenId, block.timestamp));
        rpgItemNFT.safeTransferFrom(whitelisted_user1, minter1, tokenId,"");
    }


      function testWithdraw() public {


        
         // mint the nft first

        vm.prank(whitelisted_user1);
        usdc.approve(address(rpgItemNFT), 100000);

        vm.prank(whitelisted_user1);
        uint256 tokenId = rpgItemNFT.mint(whitelisted_user1, emptyAuthParams);
        assertEq(rpgItemNFT.ownerOf(tokenId), whitelisted_user1);

        // check the USDC balance of contract RPGItemNFT
       // after minting the NFT // it should be 50% of minting price which assetcreator can withdraw

        assertEq(IERC20(usdc).balanceOf(address(rpgItemNFT)), 50000);

   
        // vm.startPrank(owner);
        // IERC20(usdcToken).transfer(address(rpgItemNFT), 1000);
        // rpgItemNFT.withdraw(usdcToken);
        // assertEq(IERC20(usdcToken).balanceOf(owner), 1000);
        // vm.stopPrank();
    }

    // function testWithdrawNonZeroAddress() public {
    //     vm.startPrank(owner);
    //     vm.expectRevert(Errors.ZeroAddress.selector);
    //     rpgItemNFT.withdraw(address(0));
    //     vm.stopPrank();
    // }

}

