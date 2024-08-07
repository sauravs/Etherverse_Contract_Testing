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
import "../src/misc/Game.sol";
import "../src/nft/helpers/UpgradeV1.sol";
import "./Game.t.sol";

contract RPGItemNFTTest is Test {
    RPGItemNFT public rpgItemNFT;
    address public owner = 0x762aD31Ff4bD1ceb5b3b5868672d5CBEaEf609dF;
    address public ccipHandler = 0x3c7444D7351027473698a7DCe751eE6Aea8036ee;
    address public whitelisted_user1 = address(0x3);
    address public user = address(0x4);
    address public minter1 = address(0x5);
    address public minter2 = address(0x6);
    address public nonWhitelistedUser = address(0x3);
    address public whitelistedGameContract;

    // Game.sol Related
    Game public game;
    address public etherverse = address(0x0C903F1C518724CBF9D00b18C2Db5341fF68269C); //external wallet fee collector address which will be pridevel wallet
    address public owner_web3tech = address(0x7); //// web3tech backend pvt key store on web3tech server
    address public upgradeV1ContractAddress; //eployment address of UpgradeV1
    uint256 public marketFee = 4269; // what commission does the game take which  ingame fees collected by game developer // eg  42.69% 4269
    uint256 public etherverseFee = 900; // web3tech platform fee // 9% 900
    string public gamename = "GTA"; // name of the game

    MockUSDC public usdc;
    GameTest public gameTest;
    //Game public game;

    bytes emptyAuthParams = "";

    function setUp() public {
        vm.startPrank(owner);
        rpgItemNFT = new RPGItemNFT();
        vm.stopPrank();

        // Deploy Mock USDC token
        usdc = new MockUSDC();
        // console.log("USDC address: ", address(usdc));
        //0xFEfC6BAF87cF3684058D62Da40Ff3A795946Ab06

        // deploy UpgradeV1.sol

        UpgradeV1 upgradeV1 = new UpgradeV1();
        // console.log("UpgradeV1 address: ", address(upgradeV1));
        // upgradeV1 = 0xFEfC6BAF87cF3684058D62Da40Ff3A795946Ab06;

        upgradeV1ContractAddress = address(upgradeV1);

        // deploy Game.sol

        game =
            new Game(etherverse, owner_web3tech, address(usdc), address(upgradeV1), marketFee, etherverseFee, gamename);

        //console.log("Game contract address: ", address(game));

        whitelistedGameContract = address(game);

        // Set the USDC address in the RPGItemNFT contract
        vm.prank(owner);
        rpgItemNFT.setUSDC(address(usdc));

        // 100000 USDC with 6 decimals

        uint256 amount = 100000 * 10 ** 6;

        usdc.mint(whitelistedGameContract, amount);

        // assert that the whitelisted_user1 account has 100 USDC

        assertEq(usdc.balanceOf(whitelistedGameContract), amount);

        // set the whitelistedGameContract as whitelisted

        vm.prank(owner);
        rpgItemNFT.setWhitelisted(whitelistedGameContract, true);

        //assert that the whitelistedGameContract is whitelisted

        assertTrue(rpgItemNFT.whitelisted(whitelistedGameContract));
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

    function testSetWhitelisted() public {
        vm.startPrank(owner);
        rpgItemNFT.setWhitelisted(user, true);
        assertTrue(rpgItemNFT.whitelisted(user));

        rpgItemNFT.setWhitelisted(whitelistedGameContract, true);
        assertTrue(rpgItemNFT.whitelisted(whitelistedGameContract));

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
        rpgItemNFT.setWhitelisted(whitelistedGameContract, true);
        vm.stopPrank();

        vm.startPrank(whitelistedGameContract);
        rpgItemNFT.setUpgradePrice(50000);
        assertEq(rpgItemNFT.upgradePricing(whitelistedGameContract), 50000);

        vm.stopPrank();
    }

    function testMintSuccess() public {
        // set the whitelistedGameContract as whitelisted

        vm.prank(owner);
        rpgItemNFT.setWhitelisted(whitelistedGameContract, true);

        //assert that the whitelisted_user1 is whitelisted
        assertTrue(rpgItemNFT.whitelisted(whitelistedGameContract));

        // set the mint price to 0.1 USDC(USDC has 6 decimals)
        vm.prank(owner);
        rpgItemNFT.setMintPrice(100000);

        //assert that mint price is set to 0.1 USDC

        assertEq(rpgItemNFT.mintPrice(), 100000);

        // top up the whitelistedGameContract account with 0.1 ether for purpose of paying transaction fee
        vm.deal(whitelistedGameContract, 100000000000000000);

        // assert that the whitelisted_user1 account has 0.1 ether

        assertEq(address(whitelistedGameContract).balance, 100000000000000000);

        // aprove the RPGItemNFT contract to spend 0.1 USDC on behalf of the whitelisted_user1

        vm.prank(whitelistedGameContract);
        usdc.approve(address(rpgItemNFT), 100000);

        //mint the NFT to whitelisted_user1 by the whitelisted_user1
        vm.prank(whitelistedGameContract);
        uint256 tokenId = rpgItemNFT.mint(whitelistedGameContract, emptyAuthParams);

        // assert that the tokenId is 1000000
        assertEq(tokenId, 1000000);

        // assert that whitelisted_user1 is the owner of the minted tokenId

        assertEq(rpgItemNFT.ownerOf(tokenId), whitelistedGameContract);

        
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

    function skiptestMintRevertInsufficientUSDC__Failing() public {
        // set the mint price to 0.1 USDC
        vm.prank(owner);
        rpgItemNFT.setMintPrice(100000);

        // top up the whitelistedGameContract account with 0.1 ether for purpose of paying transaction fee
        vm.deal(whitelistedGameContract, 100000000000000000);

        // console log balance of USDC in whitelistedGameContract

        console.log("USDC balance of whitelistedGameContract: ", usdc.balanceOf(whitelistedGameContract));

        // // withdraw all the usdc balance from whitelistedGameContract by transferring to minter2

        vm.prank(whitelistedGameContract);
        usdc.transfer(minter2, usdc.balanceOf(whitelistedGameContract));

        console.log(" AFTER :USDC balance of whitelistedGameContract: ", usdc.balanceOf(whitelistedGameContract));

        // // withdraw all the usdc balance from whitelistedGameContract by transferring to 0x00 address to clean up the usdc fund

        // vm.prank(whitelistedGameContract);
        // usdc.transfer(minter2, usdc.balanceOf(whitelistedGameContract));

        // // check that now whitelistGameContract has 0 USDC

        // assertEq(usdc.balanceOf(whitelistedGameContract), 0);

        // top up whitelistedGameContract with insufficient USDC of amount 0.01USDC

        // uint256 amount = 0.01 * 10 ** 6;

        // usdc.mint(whitelistedGameContract, amount);

        // // whitelist whitelistedGameContract account by the owner

        // // vm.prank(owner);
        // // rpgItemNFT.setWhitelisted(minter2, true);

        // // aprove the RPGItemNFT contract to spend 0.1 USDC on behalf of the minter2

        // vm.prank(whitelistedGameContract);
        // usdc.approve(address(rpgItemNFT), 100000);

        // //try to mint the NFT to whitelistedGameContract by the whitelistedGameContract which has insufficient USDC
        // vm.prank(whitelistedGameContract);
        // vm.expectRevert("Insufficient balance");

        // uint256 tokenId = rpgItemNFT.mint(whitelistedGameContract, emptyAuthParams);
    }

    function skiptestMintRevertExceedsCapacity__Failing() public {
        // set the whitelistedGameContract as whitelisted

        vm.prank(owner);
        rpgItemNFT.setWhitelisted(whitelistedGameContract, true);

        uint256 STARTING_TOKEN_ID = 1000000;
        uint256 exceededTokenID = STARTING_TOKEN_ID + 100000 + 1;

        // set the mint price to 0.1 USDC(USDC has 6 decimals)
        vm.prank(owner);
        rpgItemNFT.setMintPrice(100000);

        //assert that mint price is set to 0.1 USDC

        assertEq(rpgItemNFT.mintPrice(), 100000);

        // top up the whitelistedGameContract account with 0.1 ether for purpose of paying transaction fee
        vm.deal(whitelistedGameContract, 100000000000000000);

        // assert that the whitelistedGameContract account has 0.1 ether

        assertEq(address(whitelistedGameContract).balance, 100000000000000000);

        // aprove the RPGItemNFT contract to spend 0.1 USDC on behalf of the whitelistedGameContract

        vm.prank(whitelistedGameContract);
        usdc.approve(address(rpgItemNFT), 100000);

        vm.prank(whitelistedGameContract);

        for (uint256 i = 0; i <= exceededTokenID; i++) {
            if (i == exceededTokenID) {
                vm.expectRevert(abi.encodeWithSelector(Errors.ExceedsCapacity.selector, whitelistedGameContract));

                rpgItemNFT.mint(whitelistedGameContract, emptyAuthParams);
            }
            rpgItemNFT.mint(whitelistedGameContract, emptyAuthParams);
        }
    }

    function testGetTokenStats() public {
        //mint the nft first

        vm.prank(whitelistedGameContract);
        // approve the RPGItemNFT contract to spend 0.1 USDC on behalf of the whitelistedGameContract

        usdc.approve(address(rpgItemNFT), 100000);

        //mint the NFT to whitelistedGameContract by the whitelisted_user1

        vm.prank(whitelistedGameContract);
        uint256 tokenId = rpgItemNFT.mint(whitelistedGameContract, emptyAuthParams);

        //assert that the tokenId is 1000000

        assertEq(tokenId, 1000000);

        // assert that whitelistedGameContract is the owner of the minted tokenId

        assertEq(rpgItemNFT.ownerOf(tokenId), whitelistedGameContract);

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

        vm.prank(whitelistedGameContract);
        // approve the RPGItemNFT contract to spend 0.1 USDC on behalf of the whitelistedGameContract

        usdc.approve(address(rpgItemNFT), 100000);

        //mint the NFT to whitelistedGameContract by the whitelistedGameContract

        vm.prank(whitelistedGameContract);
        uint256 tokenId = rpgItemNFT.mint(whitelistedGameContract, emptyAuthParams);

        //assert that the tokenId is 1000000

        assertEq(tokenId, 1000000);

        // assert that whitelistedGameContract is the owner of the minted tokenId

        assertEq(rpgItemNFT.ownerOf(tokenId), whitelistedGameContract);

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

        vm.prank(whitelistedGameContract);
        // approve the RPGItemNFT contract to spend 0.1 USDC on behalf of the whitelistedGameContract

        usdc.approve(address(rpgItemNFT), 100000);

        //mint the NFT to whitelisted_user1 by the whitelisted_user1

        vm.prank(whitelistedGameContract);
        uint256 tokenId = rpgItemNFT.mint(whitelistedGameContract, emptyAuthParams);

        //assert that the tokenId is 1000000

        assertEq(tokenId, 1000000);

        // assert that whitelistedGameContract is the owner of the minted tokenId

        assertEq(rpgItemNFT.ownerOf(tokenId), whitelistedGameContract);

        vm.startPrank(ccipHandler);
        vm.expectRevert(Errors.ZeroAddress.selector);
        rpgItemNFT.updateStats(tokenId, address(0), 15, 25, 35);
        vm.stopPrank();
    }

    //     function skiptestUpdateStatsRevertUnauthorizedAccess() public {
    //         // mint the NFT

    //         vm.prank(whitelisted_user1);
    //         // approve the RPGItemNFT contract to spend 0.1 USDC on behalf of the whitelisted_user1

    //         usdc.approve(address(rpgItemNFT), 100000);

    //         //mint the NFT to whitelisted_user1 by the whitelisted_user1

    //         vm.prank(whitelisted_user1);
    //         uint256 tokenId = rpgItemNFT.mint(whitelisted_user1, emptyAuthParams);

    //         //assert that the tokenId is 1000000

    //         assertEq(tokenId, 1000000);

    //         // assert that whitelisted_user1 is the owner of the minted tokenId

    //         assertEq(rpgItemNFT.ownerOf(tokenId), whitelisted_user1);

    //         vm.startPrank(minter1);
    //         vm.expectRevert(Errors.UnauthorizedAccess.selector);
    //         rpgItemNFT.updateStats(tokenId, minter1, 15, 25, 35);
    //         vm.stopPrank();
    //     }

    function testGetStatValid() public {
        // mint the NFT

        vm.prank(whitelistedGameContract);
        // approve the RPGItemNFT contract to spend 0.1 USDC on behalf of the whitelistedGameContract

        usdc.approve(address(rpgItemNFT), 100000);

        //mint the NFT to whitelistedGameContract by the whitelistedGameContract

        vm.prank(whitelistedGameContract);
        uint256 tokenId = rpgItemNFT.mint(whitelistedGameContract, emptyAuthParams);

        //assert that the tokenId is 1000000

        assertEq(tokenId, 1000000);

        // assert that whitelistedGameContract is the owner of the minted tokenId

        assertEq(rpgItemNFT.ownerOf(tokenId), whitelistedGameContract);

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

        vm.prank(whitelistedGameContract);
        // approve the RPGItemNFT contract to spend 0.1 USDC on behalf of the whitelistedGameContract

        usdc.approve(address(rpgItemNFT), 100000);

        //mint the NFT to whitelistedGameContract by the whitelistedGameContract

        vm.prank(whitelistedGameContract);
        uint256 tokenId = rpgItemNFT.mint(whitelistedGameContract, emptyAuthParams);

        //assert that the tokenId is 1000000

        assertEq(tokenId, 1000000);

        // assert that whitelistedGameContract is the owner of the minted tokenId

        assertEq(rpgItemNFT.ownerOf(tokenId), whitelistedGameContract);

        vm.prank(ccipHandler);

        rpgItemNFT.setTokenLockStatus(tokenId, block.timestamp + 1 days);

        //check lockstatus

        assertEq(rpgItemNFT.lockStatus(tokenId), true);

        vm.expectRevert(abi.encodeWithSelector(Errors.Locked.selector, tokenId, block.timestamp));
        rpgItemNFT.getStat(Asset.StatType.STR, tokenId);
    }

    //     function skiptestTokenURIValid() public {
    //         // mint the NFT

    //         vm.prank(whitelisted_user1);
    //         // approve the RPGItemNFT contract to spend 0.1 USDC on behalf of the whitelisted_user1

    //         usdc.approve(address(rpgItemNFT), 100000);

    //         //mint the NFT to whitelisted_user1 by the whitelisted_user1

    //         vm.prank(whitelisted_user1);
    //         uint256 tokenId = rpgItemNFT.mint(whitelisted_user1, emptyAuthParams);

    //         //assert that the tokenId is 1000000

    //         assertEq(tokenId, 1000000);

    //         // assert that whitelisted_user1 is the owner of the minted tokenId

    //         assertEq(rpgItemNFT.ownerOf(tokenId), whitelisted_user1);

    //         string memory uri = rpgItemNFT.tokenURI(tokenId);
    //         assertEq(uri, "https://ipfs.io/ipfs/QmVQ2vpBD1U6P22V2xaHk5KF5x6mQAM7HmFsc8c2AsQhgo");
    //     }

    function testTransferFromSuccess() public {
        // mint the nft first

        vm.prank(whitelistedGameContract);
        // approve the RPGItemNFT contract to spend 0.1 USDC on behalf of the whitelistedGameContract

        usdc.approve(address(rpgItemNFT), 100000);

        //mint the NFT to whitelistedGameContract by the whitelistedGameContract

        vm.prank(whitelistedGameContract);
        uint256 tokenId = rpgItemNFT.mint(whitelistedGameContract, emptyAuthParams);

        //assert that the tokenId is 1000000

        assertEq(tokenId, 1000000);

        // assert that whitelistedGameContract is the owner of the minted tokenId

        assertEq(rpgItemNFT.ownerOf(tokenId), whitelistedGameContract);

        vm.prank(whitelistedGameContract);
        rpgItemNFT.transferFrom(whitelistedGameContract, minter1, tokenId);
        assertEq(rpgItemNFT.ownerOf(tokenId), minter1);
    }

    function testTransferFromZeroAddress() public {
        // mint the nft first

        vm.prank(whitelistedGameContract);
        usdc.approve(address(rpgItemNFT), 100000);

        vm.prank(whitelistedGameContract);
        uint256 tokenId = rpgItemNFT.mint(whitelistedGameContract, emptyAuthParams);
        assertEq(rpgItemNFT.ownerOf(tokenId), whitelistedGameContract);

        vm.prank(whitelistedGameContract);
        vm.expectRevert(Errors.ZeroAddress.selector);
        rpgItemNFT.transferFrom(whitelistedGameContract, address(0), tokenId);
    }

    function testTransferFromLockedToken() public {
        // mint the nft first

        vm.prank(whitelistedGameContract);
        usdc.approve(address(rpgItemNFT), 100000);

        vm.prank(whitelistedGameContract);
        uint256 tokenId = rpgItemNFT.mint(whitelistedGameContract, emptyAuthParams);
        assertEq(rpgItemNFT.ownerOf(tokenId), whitelistedGameContract);

        // lock the token
        vm.prank(ccipHandler);
        rpgItemNFT.setTokenLockStatus(tokenId, block.timestamp + 1 days);
        assertEq(rpgItemNFT.lockStatus(tokenId), true);

        vm.prank(whitelistedGameContract);
        vm.expectRevert(abi.encodeWithSelector(Errors.Locked.selector, tokenId, block.timestamp));
        rpgItemNFT.transferFrom(whitelistedGameContract, minter1, tokenId);
    }

    function testSafeTransferFromSuccess() public {
        // mint the nft first

        vm.prank(whitelistedGameContract);
        usdc.approve(address(rpgItemNFT), 100000);

        vm.prank(whitelistedGameContract);
        uint256 tokenId = rpgItemNFT.mint(whitelistedGameContract, emptyAuthParams);
        assertEq(rpgItemNFT.ownerOf(tokenId), whitelistedGameContract);

        vm.prank(whitelistedGameContract);
        rpgItemNFT.safeTransferFrom(whitelistedGameContract, minter1, tokenId, "");
        assertEq(rpgItemNFT.ownerOf(tokenId), minter1);
    }

    function testSafeTransferFromZeroAddress() public {
        // mint the nft first

        vm.prank(whitelistedGameContract);
        usdc.approve(address(rpgItemNFT), 100000);

        vm.prank(whitelistedGameContract);
        uint256 tokenId = rpgItemNFT.mint(whitelistedGameContract, emptyAuthParams);
        assertEq(rpgItemNFT.ownerOf(tokenId), whitelistedGameContract);

        vm.prank(whitelistedGameContract);
        vm.expectRevert(Errors.ZeroAddress.selector);
        rpgItemNFT.safeTransferFrom(whitelistedGameContract, address(0), tokenId, "");
    }

    function testSafeTransferFromLockedToken() public {
        // mint the nft first

        vm.prank(whitelistedGameContract);
        usdc.approve(address(rpgItemNFT), 100000);

        vm.prank(whitelistedGameContract);
        uint256 tokenId = rpgItemNFT.mint(whitelistedGameContract, emptyAuthParams);
        assertEq(rpgItemNFT.ownerOf(tokenId), whitelistedGameContract);

        // lock the token
        vm.prank(ccipHandler);
        rpgItemNFT.setTokenLockStatus(tokenId, block.timestamp + 1 days);
        assertEq(rpgItemNFT.lockStatus(tokenId), true);

        vm.prank(whitelistedGameContract);
        vm.expectRevert(abi.encodeWithSelector(Errors.Locked.selector, tokenId, block.timestamp));
        rpgItemNFT.safeTransferFrom(whitelistedGameContract, minter1, tokenId, "");
    }

    function testWithdraw() public {
        // mint the nft first

        vm.prank(whitelistedGameContract);
        usdc.approve(address(rpgItemNFT), 100000);

        vm.prank(whitelistedGameContract);
        uint256 tokenId = rpgItemNFT.mint(whitelistedGameContract, emptyAuthParams);
        assertEq(rpgItemNFT.ownerOf(tokenId), whitelistedGameContract);

        // check the USDC balance of contract RPGItemNFT
        // after minting the NFT // it should be 50% of minting price which assetcreator can withdraw ,which
        //should come 0.05$

        assertEq(IERC20(usdc).balanceOf(address(rpgItemNFT)), 50000);

        //prank assetWalletAddress and then withdraw

        vm.prank(rpgItemNFT.assetCreatorWallet());

        rpgItemNFT.withdraw(address(usdc));

        // check balance of assetWalletAddress after withdraw

        assertEq(IERC20(usdc).balanceOf(rpgItemNFT.assetCreatorWallet()), 50000);
    }


     function testresetUpgradesSuccess() public {
            // mint the nft first
            vm.prank(whitelistedGameContract);
            usdc.approve(address(rpgItemNFT), 100000);

            vm.prank(whitelistedGameContract);
            uint256 tokenId = rpgItemNFT.mint(whitelistedGameContract, emptyAuthParams);
            assertEq(rpgItemNFT.ownerOf(tokenId), whitelistedGameContract);

            vm.prank(whitelistedGameContract);
            rpgItemNFT.resetUpgrades(tokenId);

            (uint8 stat1, uint8 stat2, uint8 stat3) = rpgItemNFT.upgradeMapping(tokenId);
            Asset.Stat memory upgradedStat = Asset.Stat(stat1, stat2, stat3);

            assertEq(upgradedStat.stat1, 0);
            assertEq(upgradedStat.stat2, 0);
            assertEq(upgradedStat.stat3, 0);
        }

        function testresetUpgradesRevertNotMinted() public {
            vm.prank(whitelistedGameContract);
            vm.expectRevert(Errors.NotMinted.selector);
            rpgItemNFT.resetUpgrades(9999999);
        }

    function testFreeUpgradeSuccess__Failing() public {
       
        // mint the nft first
        vm.prank(whitelistedGameContract);
        usdc.approve(address(rpgItemNFT), 100000);

        vm.prank(whitelistedGameContract);
        uint256 tokenId = rpgItemNFT.mint(whitelistedGameContract, emptyAuthParams);
        assertEq(rpgItemNFT.ownerOf(tokenId), whitelistedGameContract);

        vm.prank(whitelistedGameContract);
        rpgItemNFT.freeUpgrade(tokenId);

        (uint8 stat1, uint8 stat2, uint8 stat3) = rpgItemNFT.upgradeMapping(tokenId);
        Asset.Stat memory upgradedStat = Asset.Stat(stat1, stat2, stat3);

        assertEq(upgradedStat.stat1, 12); // expecting 12
        assertEq(upgradedStat.stat2, 22);  // expecting 22
        assertEq(upgradedStat.stat3, 32);  // expecting 32
    }

    //     function skiptestFreeUpgradeRevertNotWhitelisted__Failing() public {
    //         // set the mint price to 0.1 USDC(USDC has 6 decimals)
    //         vm.prank(owner);
    //         rpgItemNFT.setMintPrice(100000);

    //         // top up the minter1 account with 0.1 ether for purpose of paying transaction fee
    //         vm.deal(minter1, 100000000000000000);

    //         // assert that the minter1 account has 0.1 ether

    //         assertEq(address(minter1).balance, 100000000000000000);

    //         // aprove the RPGItemNFT contract to spend 0.1 USDC on behalf of the minter1

    //         vm.prank(minter1);
    //         usdc.approve(address(rpgItemNFT), 100000);

    //         // mint the NFT
    //         vm.prank(minter1);
    //         uint256 tokenId = rpgItemNFT.mint(minter1, emptyAuthParams);
    //         assertEq(rpgItemNFT.ownerOf(tokenId), minter1);

    //         // vm.prank(minter1);
    //         // vm.expectRevert(abi.encodeWithSelector(Errors.CallerMustBeWhitelisted.selector, nonWhitelistedUser));
    //         // rpgItemNFT.freeUpgrade(tokenId);
    //     }

        function testFreeUpgradeRevertNotMinted() public {
            vm.prank(whitelistedGameContract);

            vm.expectRevert(Errors.NotMinted.selector);
            rpgItemNFT.freeUpgrade(9999999);
        }

        function testpaidUpgradeSuccess__Failing() public {
            // mint the nft first
            vm.prank(whitelistedGameContract);
            usdc.approve(address(rpgItemNFT), 100000);

            vm.prank(whitelistedGameContract);
            uint256 tokenId = rpgItemNFT.mint(whitelistedGameContract, emptyAuthParams);
            assertEq(rpgItemNFT.ownerOf(tokenId), whitelistedGameContract);

            vm.prank(whitelistedGameContract);
            rpgItemNFT.paidUpgrade(tokenId, emptyAuthParams);

            (uint8 stat1, uint8 stat2, uint8 stat3) = rpgItemNFT.upgradeMapping(tokenId);
            Asset.Stat memory upgradedStat = Asset.Stat(stat1, stat2, stat3);

            assertEq(upgradedStat.stat1, 15);
            assertEq(upgradedStat.stat2, 25);
            assertEq(upgradedStat.stat3, 35);
        }

        function testpaidUpgradeRevertNotMinted() public {
            vm.prank(whitelistedGameContract);
            vm.expectRevert(Errors.NotMinted.selector);
            rpgItemNFT.paidUpgrade(9999999, emptyAuthParams);
        }

    //     function skiptestpaidUpgradeRevertNotWhitelisted__Failing() public {
    //         // set the mint price to 0.1 USDC(USDC has 6 decimals)
    //         vm.prank(owner);
    //         rpgItemNFT.setMintPrice(100000);

    //         // top up the minter1 account with 0.1 ether for purpose of paying transaction fee
    //         vm.deal(minter1, 100000000000000000);

    //         // assert that the minter1 account has 0.1 ether

    //         assertEq(address(minter1).balance, 100000000000000000);

    //         // aprove the RPGItemNFT contract to spend 0.1 USDC on behalf of the minter1

    //         vm.prank(minter1);
    //         usdc.approve(address(rpgItemNFT), 100000);

    //         // mint the NFT
    //         vm.prank(minter1);
    //         uint256 tokenId = rpgItemNFT.mint(minter1, emptyAuthParams);
    //         assertEq(rpgItemNFT.ownerOf(tokenId), minter1);

    //         // vm.prank(minter1);
    //         // vm.expectRevert(abi.encodeWithSelector(Errors.CallerMustBeWhitelisted.selector, nonWhitelistedUser));
    //         // rpgItemNFT.paidUpgrade(tokenId);
    //     }

       

  

        

        function testNextUpgradeSuccess__Failing() public {

           // mint the nft first
            vm.prank(whitelistedGameContract);
            usdc.approve(address(rpgItemNFT), 100000);

            vm.prank(whitelistedGameContract);
            uint256 tokenId = rpgItemNFT.mint(whitelistedGameContract, emptyAuthParams);
            assertEq(rpgItemNFT.ownerOf(tokenId), whitelistedGameContract);

            vm.prank(whitelistedGameContract);
            
             Asset.Stat memory upgradedStat = rpgItemNFT.nextUpgrade(tokenId, Upgrade.Type.Free);

            // //  (uint8 stat1, uint8 stat2, uint8 stat3) = rpgItemNFT.upgradeMapping(tokenId);
            // // Asset.Stat memory upgradedStat = Asset.Stat(stat1, stat2, stat3);

             // assert the value

            assertEq(upgradedStat.stat1, 12);
            assertEq(upgradedStat.stat2, 22);
            assertEq(upgradedStat.stat3, 32);

        }
}
