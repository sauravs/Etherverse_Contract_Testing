

// // SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// forge test --match-path test/EtherverseNFT.t.sol -vvv

import {Test, console} from "forge-std/Test.sol";
//import {etherverseNFT} from "../src/nft/RPG.sol";  //EtherverseNFT
import {EtherverseNFT} from "../src/nft/EtherverseNFT.sol"; 
import "../src/nft/lib/Structs.sol";
import "../src/nft/lib/errors.sol";
import "../src/common/interface/IUSDC.sol";
import "../src/nft/lib/Fee.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../src/mock/MockUSDC.sol";
import "../src/misc/Game.sol";
import "../src/nft/helpers/UpgradeV1.sol";
import "./Game.t.sol";

contract etherverseNFTTest is Test {
    EtherverseNFT public etherverseNFT;
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
    address gameDeveloperWalletAddress = address(0x7);
    address gameDeveloperFeeCollectorWallet = address(0x8);
    address web3techInitialOwner = address(0x9);
    address public upgradeV1ContractAddress; //deployment address of UpgradeV1
    uint256 public marketFee = 4269; // what commission does the game take which  ingame fees collected by game developer // eg  42.69% 4269
    uint256 public etherverseFee = 900; // web3tech platform fee // 9% 900
    string public gamename = "GTA"; // name of the game

    MockUSDC public usdc;
    GameTest public gameTest;
    //Game public game;

    bytes emptyAuthParams = "";

    function setUp() public {
        vm.startPrank(owner);
        etherverseNFT = new EtherverseNFT();
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



         game = new Game(etherverse, gameDeveloperWalletAddress,gameDeveloperFeeCollectorWallet, address(usdc), address(upgradeV1),web3techInitialOwner, marketFee, etherverseFee, gamename);
        //console.log("Game contract address: ", address(game));
        //0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f'

        whitelistedGameContract = address(game);

        // Set the USDC address in the etherverseNFT contract
        vm.prank(owner);
        etherverseNFT.setUSDC(address(usdc));

        // 100000 USDC with 6 decimals

        uint256 amount = 100000 * 10 ** 6;

        usdc.mint(whitelistedGameContract, amount);

        // assert that the whitelisted_user1 account has 100 USDC

        assertEq(usdc.balanceOf(whitelistedGameContract), amount);

        // set the whitelistedGameContract as whitelisted

        vm.prank(owner);
        etherverseNFT.setWhitelisted(whitelistedGameContract, true);

        //assert that the whitelistedGameContract is whitelisted

        assertTrue(etherverseNFT.whitelisted(whitelistedGameContract));
    }

    function testConstructor() public {
        // Check initial values set by the constructor
        assertEq(etherverseNFT.name(), "Sword");
        assertEq(etherverseNFT.symbol(), "SW");
        assertEq(etherverseNFT.etherverseWallet(), 0x0C903F1C518724CBF9D00b18C2Db5341fF68269C);
        assertEq(etherverseNFT.assetCreatorWallet(), 0xa1293A8bFf9323aAd0419E46Dd9846Cc7363D44b);
        assertEq(etherverseNFT.USDC(), 0xFEfC6BAF87cF3684058D62Da40Ff3A795946Ab06);
        // assertEq(etherverseNFT.baseStat().stat1, 10);
        // assertEq(etherverseNFT.baseStat().stat2, 20);
        // assertEq(etherverseNFT.baseStat().stat3, 30);

        (uint8 stat1, uint8 stat2, uint8 stat3) = etherverseNFT.baseStat();
        assertEq(stat1, 87);
        assertEq(stat2, 20);
        assertEq(stat3, 21);

        assertEq(uint256(etherverseNFT.statLabels(0)), uint256(Asset.StatType.STR));
        assertEq(uint256(etherverseNFT.statLabels(1)), uint256(Asset.StatType.DEX));
        assertEq(uint256(etherverseNFT.statLabels(2)), uint256(Asset.StatType.CON));
        assertEq(uint256(etherverseNFT.AssetType()), uint256(Asset.Type.Weapon));
        assertEq(etherverseNFT.svgColors(0), 213);
        assertEq(etherverseNFT.svgColors(1), 123);
        assertEq(etherverseNFT.svgColors(2), 312);
        assertEq(etherverseNFT.colorRanges(0), 0);
        assertEq(etherverseNFT.colorRanges(1), 10);
        assertEq(etherverseNFT.colorRanges(2), 20);
        assertEq(etherverseNFT.colorRanges(3), 30);
        assertEq(etherverseNFT.itemImage(), "https://ipfs.io/ipfs/QmVQ2vpBD1U6P22V2xaHk5KF5x6mQAM7HmFsc8c2AsQhgo");
        assertEq(etherverseNFT._ccipHandler(), 0x3c7444D7351027473698a7DCe751eE6Aea8036ee);
        assertEq(etherverseNFT.mintPrice(), 100000);
        assertEq(etherverseNFT.uriAddress(), address(0));
        assertEq(etherverseNFT._nextTokenId(), 1000000);
        assertEq(etherverseNFT.feeSplit(), 1000);
    }

  
    function testColorRangesArray() public {
        uint8[] memory colorRanges = etherverseNFT.colorRangesArray();
        assertEq(colorRanges.length, 4);
        assertEq(colorRanges[0], 0);
        assertEq(colorRanges[1], 10);
        assertEq(colorRanges[2], 20);
        assertEq(colorRanges[3], 30);
    }

    function testSvgColorsArray() public {
        uint24[] memory svgColors = etherverseNFT.svgColorsArray();
        assertEq(svgColors.length, 3);
        assertEq(svgColors[0], 213);
        assertEq(svgColors[1], 123);
        assertEq(svgColors[2], 312);
    }

    function testStatLabelsArray() public {
        Asset.StatType[3] memory statLabels = etherverseNFT.statLabelsArray();
        assertEq(uint256(statLabels[0]), uint256(Asset.StatType.STR));
        assertEq(uint256(statLabels[1]), uint256(Asset.StatType.DEX));
        assertEq(uint256(statLabels[2]), uint256(Asset.StatType.CON));
    }

    function testLockStatus() public {
        uint256 tokenId = 1;
        vm.prank(ccipHandler);
        etherverseNFT.setTokenLockStatus(tokenId, block.timestamp + 1000);
        assertEq(etherverseNFT.lockStatus(tokenId), true);
    }

    function testSetTokenLockStatus() public {
        uint256 tokenId = 1;
        uint256 unlockTime = block.timestamp + 1000;
        vm.prank(ccipHandler);
        etherverseNFT.setTokenLockStatus(tokenId, unlockTime);
        assertEq(etherverseNFT.tokenLockedTill(tokenId), unlockTime);
    }

    function testSetSign() public {
        vm.startPrank(owner);
        etherverseNFT.setSign(12345);
        assertEq(etherverseNFT.sign(), 12345);
        vm.stopPrank();
    }

    function testChangeCCIP() public {
        vm.startPrank(owner);
        address newCCIP = address(0x4);
        etherverseNFT.changeCCIP(newCCIP);
        assertEq(etherverseNFT._ccipHandler(), newCCIP);
        vm.stopPrank();
    }

 

    function testChangeImageUrl() public {
        vm.startPrank(owner);
        string memory newImageUrl = "https://newimage.url";
        etherverseNFT.changeImageUrl(newImageUrl);
        assertEq(etherverseNFT.itemImage(), newImageUrl);
        vm.stopPrank();
    }

    function testSetWhitelisted() public {
        vm.startPrank(owner);
        etherverseNFT.setWhitelisted(user, true);
        assertTrue(etherverseNFT.whitelisted(user));

        etherverseNFT.setWhitelisted(whitelistedGameContract, true);
        assertTrue(etherverseNFT.whitelisted(whitelistedGameContract));

        vm.stopPrank();
    }

    function testSetMintPrice() public {
        vm.startPrank(owner);
        etherverseNFT.setMintPrice(200000);
        assertEq(etherverseNFT.mintPrice(), 200000);
        vm.expectRevert(Errors.ZeroInput.selector);
        etherverseNFT.setMintPrice(0);
        vm.stopPrank();
    }

 


    function testSetFeeSplit() public {
        vm.startPrank(owner);
        etherverseNFT.setFeeSplit(5000);
        assertEq(etherverseNFT.feeSplit(), 5000);
        vm.expectRevert(Errors.ZeroInput.selector);
        etherverseNFT.setFeeSplit(10001);
        vm.stopPrank();

    }


    function testSetUpgradePrice() public {
        vm.startPrank(owner);
        etherverseNFT.setWhitelisted(whitelistedGameContract, true);
        vm.stopPrank();

        vm.startPrank(whitelistedGameContract);
        etherverseNFT.setUpgradePrice(50000);
        assertEq(etherverseNFT.upgradePricing(whitelistedGameContract), 50000);

        vm.stopPrank();
    }

    function testMintSuccess() public {
        // set the whitelistedGameContract as whitelisted

        vm.prank(owner);
        etherverseNFT.setWhitelisted(whitelistedGameContract, true);

        //assert that the whitelisted_user1 is whitelisted
        assertTrue(etherverseNFT.whitelisted(whitelistedGameContract));

        // set the mint price to 0.1 USDC(USDC has 6 decimals)
        vm.prank(owner);
        etherverseNFT.setMintPrice(100000);

        //assert that mint price is set to 0.1 USDC

        assertEq(etherverseNFT.mintPrice(), 100000);

        // top up the whitelistedGameContract account with 0.1 ether for purpose of paying transaction fee
        vm.deal(whitelistedGameContract, 100000000000000000);

        // assert that the whitelisted_user1 account has 0.1 ether

        assertEq(address(whitelistedGameContract).balance, 100000000000000000);

        // aprove the etherverseNFT contract to spend 0.1 USDC on behalf of the whitelisted_user1

        vm.prank(whitelistedGameContract);
        usdc.approve(address(etherverseNFT), 100000);

        //mint the NFT to whitelisted_user1 by the whitelisted_user1
        vm.prank(whitelistedGameContract);
        uint256 tokenId = etherverseNFT.mint(whitelistedGameContract, emptyAuthParams);

        // assert that the tokenId is 1000000
        assertEq(tokenId, 1000000);

        // assert that whitelisted_user1 is the owner of the minted tokenId

        assertEq(etherverseNFT.ownerOf(tokenId), whitelistedGameContract);

        
    }

    function testMintRevertNotWhitelisted() public {
        // set the mint price to 0.1 USDC(USDC has 6 decimals)
        vm.prank(owner);
        etherverseNFT.setMintPrice(100000);

        //assert that mint price is set to 0.1 USDC

        assertEq(etherverseNFT.mintPrice(), 100000);

        // top up the minter1 account with 0.1 ether for purpose of paying transaction fee
        vm.deal(minter1, 100000000000000000);

        // assert that the minter1 account has 0.1 ether

        assertEq(address(minter1).balance, 100000000000000000);

        // aprove the etherverseNFT contract to spend 0.1 USDC on behalf of the minter1

        vm.prank(minter1);
        usdc.approve(address(etherverseNFT), 100000);

        //try to mint the NFT to minter1 by the minter1 which is not whitelisted by owner
        vm.prank(minter1);
        vm.expectRevert(abi.encodeWithSelector(Errors.CallerMustBeWhitelisted.selector, minter1));

        uint256 tokenId = etherverseNFT.mint(minter1, emptyAuthParams);
    }

    // function skiptestMintRevertInsufficientUSDC__Failing() public {
    //     // set the mint price to 0.1 USDC
    //     vm.prank(owner);
    //     etherverseNFT.setMintPrice(100000);

    //     // top up the whitelistedGameContract account with 0.1 ether for purpose of paying transaction fee
    //     vm.deal(whitelistedGameContract, 100000000000000000);

    //     // console log balance of USDC in whitelistedGameContract

    //     console.log("USDC balance of whitelistedGameContract: ", usdc.balanceOf(whitelistedGameContract));

    //     // // withdraw all the usdc balance from whitelistedGameContract by transferring to minter2

    //     vm.prank(whitelistedGameContract);
    //     usdc.transfer(minter2, usdc.balanceOf(whitelistedGameContract));

    //     console.log(" AFTER :USDC balance of whitelistedGameContract: ", usdc.balanceOf(whitelistedGameContract));

    //     // // withdraw all the usdc balance from whitelistedGameContract by transferring to 0x00 address to clean up the usdc fund

    //     // vm.prank(whitelistedGameContract);
    //     // usdc.transfer(minter2, usdc.balanceOf(whitelistedGameContract));

    //     // // check that now whitelistGameContract has 0 USDC

    //     // assertEq(usdc.balanceOf(whitelistedGameContract), 0);

    //     // top up whitelistedGameContract with insufficient USDC of amount 0.01USDC

    //     // uint256 amount = 0.01 * 10 ** 6;

    //     // usdc.mint(whitelistedGameContract, amount);

    //     // // whitelist whitelistedGameContract account by the owner

    //     // // vm.prank(owner);
    //     // // etherverseNFT.setWhitelisted(minter2, true);

    //     // // aprove the etherverseNFT contract to spend 0.1 USDC on behalf of the minter2

    //     // vm.prank(whitelistedGameContract);
    //     // usdc.approve(address(etherverseNFT), 100000);

    //     // //try to mint the NFT to whitelistedGameContract by the whitelistedGameContract which has insufficient USDC
    //     // vm.prank(whitelistedGameContract);
    //     // vm.expectRevert("Insufficient balance");

    //     // uint256 tokenId = etherverseNFT.mint(whitelistedGameContract, emptyAuthParams);
    // }

    // function skiptestMintRevertExceedsCapacity__Failing() public {
    //     // set the whitelistedGameContract as whitelisted

    //     vm.prank(owner);
    //     etherverseNFT.setWhitelisted(whitelistedGameContract, true);

    //     uint256 STARTING_TOKEN_ID = 1000000;
    //     uint256 exceededTokenID = STARTING_TOKEN_ID + 100000 + 1;

    //     // set the mint price to 0.1 USDC(USDC has 6 decimals)
    //     vm.prank(owner);
    //     etherverseNFT.setMintPrice(100000);

    //     //assert that mint price is set to 0.1 USDC

    //     assertEq(etherverseNFT.mintPrice(), 100000);

    //     // top up the whitelistedGameContract account with 0.1 ether for purpose of paying transaction fee
    //     vm.deal(whitelistedGameContract, 100000000000000000);

    //     // assert that the whitelistedGameContract account has 0.1 ether

    //     assertEq(address(whitelistedGameContract).balance, 100000000000000000);

    //     // aprove the etherverseNFT contract to spend 0.1 USDC on behalf of the whitelistedGameContract

    //     vm.prank(whitelistedGameContract);
    //     usdc.approve(address(etherverseNFT), 100000);

    //     vm.prank(whitelistedGameContract);

    //     for (uint256 i = 0; i <= exceededTokenID; i++) {
    //         if (i == exceededTokenID) {
    //             vm.expectRevert(abi.encodeWithSelector(Errors.ExceedsCapacity.selector, whitelistedGameContract));

    //             etherverseNFT.mint(whitelistedGameContract, emptyAuthParams);
    //         }
    //         etherverseNFT.mint(whitelistedGameContract, emptyAuthParams);
    //     }
    // }

    function testGetTokenStats() public {
        //mint the nft first

        vm.prank(whitelistedGameContract);
        // approve the etherverseNFT contract to spend 0.1 USDC on behalf of the whitelistedGameContract

        usdc.approve(address(etherverseNFT), 100000);

        //mint the NFT to whitelistedGameContract by the whitelisted_user1

        vm.prank(whitelistedGameContract);
        uint256 tokenId = etherverseNFT.mint(whitelistedGameContract, emptyAuthParams);

        //assert that the tokenId is 1000000

        assertEq(tokenId, 1000000);

        // assert that whitelistedGameContract is the owner of the minted tokenId

        assertEq(etherverseNFT.ownerOf(tokenId), whitelistedGameContract);

        (uint8 stat1, uint8 stat2, uint8 stat3) = etherverseNFT.getTokenStats(tokenId);
        assertEq(stat1, 87);
        assertEq(stat2, 20);
        assertEq(stat3, 21);
    }

    function testGetTokenStatsRevertNotMinted() public {
        vm.expectRevert(Errors.NotMinted.selector);
        etherverseNFT.getTokenStats(9999999);
    }

    function testUpdateStats() public {
        // mint the NFT

        //mint the nft first

        vm.prank(whitelistedGameContract);
        // approve the etherverseNFT contract to spend 0.1 USDC on behalf of the whitelistedGameContract

        usdc.approve(address(etherverseNFT), 100000);

        //mint the NFT to whitelistedGameContract by the whitelistedGameContract

        vm.prank(whitelistedGameContract);
        uint256 tokenId = etherverseNFT.mint(whitelistedGameContract, emptyAuthParams);

        //assert that the tokenId is 1000000

        assertEq(tokenId, 1000000);

        // assert that whitelistedGameContract is the owner of the minted tokenId

        assertEq(etherverseNFT.ownerOf(tokenId), whitelistedGameContract);

        //update the stats

        vm.startPrank(ccipHandler);
        bool success = etherverseNFT.updateStats(tokenId, user, 15, 25, 35);
        vm.stopPrank();

        assertTrue(success);

        (uint8 stat1, uint8 stat2, uint8 stat3) = etherverseNFT.getTokenStats(tokenId);
        assertEq(stat1, 102); //87+15 (basestat + upgrade)
        assertEq(stat2, 45); //20+25
        assertEq(stat3, 56); // 21+35
    }

    function testUpdateStatsRevertZeroAddress() public {
        // mint the NFT

        vm.prank(whitelistedGameContract);
        // approve the etherverseNFT contract to spend 0.1 USDC on behalf of the whitelistedGameContract

        usdc.approve(address(etherverseNFT), 100000);

        //mint the NFT to whitelisted_user1 by the whitelisted_user1

        vm.prank(whitelistedGameContract);
        uint256 tokenId = etherverseNFT.mint(whitelistedGameContract, emptyAuthParams);

        //assert that the tokenId is 1000000

        assertEq(tokenId, 1000000);

        // assert that whitelistedGameContract is the owner of the minted tokenId

        assertEq(etherverseNFT.ownerOf(tokenId), whitelistedGameContract);

        vm.startPrank(ccipHandler);
        vm.expectRevert(Errors.ZeroAddress.selector);
        etherverseNFT.updateStats(tokenId, address(0), 15, 25, 35);
        vm.stopPrank();
    }

    // //     function skiptestUpdateStatsRevertUnauthorizedAccess() public {
    // //         // mint the NFT

    // //         vm.prank(whitelisted_user1);
    // //         // approve the etherverseNFT contract to spend 0.1 USDC on behalf of the whitelisted_user1

    // //         usdc.approve(address(etherverseNFT), 100000);

    // //         //mint the NFT to whitelisted_user1 by the whitelisted_user1

    // //         vm.prank(whitelisted_user1);
    // //         uint256 tokenId = etherverseNFT.mint(whitelisted_user1, emptyAuthParams);

    // //         //assert that the tokenId is 1000000

    // //         assertEq(tokenId, 1000000);

    // //         // assert that whitelisted_user1 is the owner of the minted tokenId

    // //         assertEq(etherverseNFT.ownerOf(tokenId), whitelisted_user1);

    // //         vm.startPrank(minter1);
    // //         vm.expectRevert(Errors.UnauthorizedAccess.selector);
    // //         etherverseNFT.updateStats(tokenId, minter1, 15, 25, 35);
    // //         vm.stopPrank();
    // //     }

    function testGetStatValid() public {
        // mint the NFT

        vm.prank(whitelistedGameContract);
        // approve the etherverseNFT contract to spend 0.1 USDC on behalf of the whitelistedGameContract

        usdc.approve(address(etherverseNFT), 100000);

        //mint the NFT to whitelistedGameContract by the whitelistedGameContract

        vm.prank(whitelistedGameContract);
        uint256 tokenId = etherverseNFT.mint(whitelistedGameContract, emptyAuthParams);

        //assert that the tokenId is 1000000

        assertEq(tokenId, 1000000);

        // assert that whitelistedGameContract is the owner of the minted tokenId

        assertEq(etherverseNFT.ownerOf(tokenId), whitelistedGameContract);

        uint8 stat = etherverseNFT.getStat(Asset.StatType.STR, tokenId);
        assertEq(stat, 87);

        uint8 stat2 = etherverseNFT.getStat(Asset.StatType.DEX, tokenId);
        assertEq(stat2, 20);

        uint8 stat3 = etherverseNFT.getStat(Asset.StatType.CON, tokenId);
        assertEq(stat3, 21);
    }

    function skiptestGetStatNotMinted__Failing() public {
        uint256 tokenId = 1;
        vm.expectRevert(Errors.NotMinted.selector);
        etherverseNFT.getStat(Asset.StatType.STR, tokenId + 1);
    }

    function skiptestGetStatLocked__Failing() public {  // @tester : as error handling is in if statement
        // mint the NFT

        vm.prank(whitelistedGameContract);
        // approve the etherverseNFT contract to spend 0.1 USDC on behalf of the whitelistedGameContract

        usdc.approve(address(etherverseNFT), 100000);

        //mint the NFT to whitelistedGameContract by the whitelistedGameContract

        vm.prank(whitelistedGameContract);
        uint256 tokenId = etherverseNFT.mint(whitelistedGameContract, emptyAuthParams);

        //assert that the tokenId is 1000000

        assertEq(tokenId, 1000000);

        // assert that whitelistedGameContract is the owner of the minted tokenId

        assertEq(etherverseNFT.ownerOf(tokenId), whitelistedGameContract);

        vm.prank(ccipHandler);

        etherverseNFT.setTokenLockStatus(tokenId, block.timestamp + 1 days);

        //check lockstatus

        assertEq(etherverseNFT.lockStatus(tokenId), true);

        vm.expectRevert(abi.encodeWithSelector(Errors.Locked.selector, tokenId, block.timestamp));
        etherverseNFT.getStat(Asset.StatType.STR, tokenId);
    }

    // //     function skiptestTokenURIValid() public {
    // //         // mint the NFT

    // //         vm.prank(whitelisted_user1);
    // //         // approve the etherverseNFT contract to spend 0.1 USDC on behalf of the whitelisted_user1

    // //         usdc.approve(address(etherverseNFT), 100000);

    // //         //mint the NFT to whitelisted_user1 by the whitelisted_user1

    // //         vm.prank(whitelisted_user1);
    // //         uint256 tokenId = etherverseNFT.mint(whitelisted_user1, emptyAuthParams);

    // //         //assert that the tokenId is 1000000

    // //         assertEq(tokenId, 1000000);

    // //         // assert that whitelisted_user1 is the owner of the minted tokenId

    // //         assertEq(etherverseNFT.ownerOf(tokenId), whitelisted_user1);

    // //         string memory uri = etherverseNFT.tokenURI(tokenId);
    // //         assertEq(uri, "https://ipfs.io/ipfs/QmVQ2vpBD1U6P22V2xaHk5KF5x6mQAM7HmFsc8c2AsQhgo");
    // //     }

    function testTransferFromSuccess() public {
        // mint the nft first

        vm.prank(whitelistedGameContract);
        // approve the etherverseNFT contract to spend 0.1 USDC on behalf of the whitelistedGameContract

        usdc.approve(address(etherverseNFT), 100000);

        //mint the NFT to whitelistedGameContract by the whitelistedGameContract

        vm.prank(whitelistedGameContract);
        uint256 tokenId = etherverseNFT.mint(whitelistedGameContract, emptyAuthParams);

        //assert that the tokenId is 1000000

        assertEq(tokenId, 1000000);

        // assert that whitelistedGameContract is the owner of the minted tokenId

        assertEq(etherverseNFT.ownerOf(tokenId), whitelistedGameContract);

        vm.prank(whitelistedGameContract);
        etherverseNFT.transferFrom(whitelistedGameContract, minter1, tokenId);
        assertEq(etherverseNFT.ownerOf(tokenId), minter1);
    }

    function testTransferFromZeroAddress() public {
        // mint the nft first

        vm.prank(whitelistedGameContract);
        usdc.approve(address(etherverseNFT), 100000);

        vm.prank(whitelistedGameContract);
        uint256 tokenId = etherverseNFT.mint(whitelistedGameContract, emptyAuthParams);
        assertEq(etherverseNFT.ownerOf(tokenId), whitelistedGameContract);

        vm.prank(whitelistedGameContract);
        vm.expectRevert(Errors.ZeroAddress.selector);
        etherverseNFT.transferFrom(whitelistedGameContract, address(0), tokenId);
    }

    function testTransferFromLockedToken() public {
        // mint the nft first

        vm.prank(whitelistedGameContract);
        usdc.approve(address(etherverseNFT), 100000);

        vm.prank(whitelistedGameContract);
        uint256 tokenId = etherverseNFT.mint(whitelistedGameContract, emptyAuthParams);
        assertEq(etherverseNFT.ownerOf(tokenId), whitelistedGameContract);

        // lock the token
        vm.prank(ccipHandler);
        etherverseNFT.setTokenLockStatus(tokenId, block.timestamp + 1 days);
        assertEq(etherverseNFT.lockStatus(tokenId), true);

        vm.prank(whitelistedGameContract);
        vm.expectRevert(abi.encodeWithSelector(Errors.Locked.selector, tokenId, block.timestamp));
        etherverseNFT.transferFrom(whitelistedGameContract, minter1, tokenId);
    }

    function testSafeTransferFromSuccess() public {
        // mint the nft first

        vm.prank(whitelistedGameContract);
        usdc.approve(address(etherverseNFT), 100000);

        vm.prank(whitelistedGameContract);
        uint256 tokenId = etherverseNFT.mint(whitelistedGameContract, emptyAuthParams);
        assertEq(etherverseNFT.ownerOf(tokenId), whitelistedGameContract);

        vm.prank(whitelistedGameContract);
        etherverseNFT.safeTransferFrom(whitelistedGameContract, minter1, tokenId, "");
        assertEq(etherverseNFT.ownerOf(tokenId), minter1);
    }

    function testSafeTransferFromZeroAddress() public {
        // mint the nft first

        vm.prank(whitelistedGameContract);
        usdc.approve(address(etherverseNFT), 100000);

        vm.prank(whitelistedGameContract);
        uint256 tokenId = etherverseNFT.mint(whitelistedGameContract, emptyAuthParams);
        assertEq(etherverseNFT.ownerOf(tokenId), whitelistedGameContract);

        vm.prank(whitelistedGameContract);
        vm.expectRevert(Errors.ZeroAddress.selector);
        etherverseNFT.safeTransferFrom(whitelistedGameContract, address(0), tokenId, "");
    }

    function testSafeTransferFromLockedToken() public {
        // mint the nft first

        vm.prank(whitelistedGameContract);
        usdc.approve(address(etherverseNFT), 100000);

        vm.prank(whitelistedGameContract);
        uint256 tokenId = etherverseNFT.mint(whitelistedGameContract, emptyAuthParams);
        assertEq(etherverseNFT.ownerOf(tokenId), whitelistedGameContract);

        // lock the token
        vm.prank(ccipHandler);
        etherverseNFT.setTokenLockStatus(tokenId, block.timestamp + 1 days);
        assertEq(etherverseNFT.lockStatus(tokenId), true);

        vm.prank(whitelistedGameContract);
        vm.expectRevert(abi.encodeWithSelector(Errors.Locked.selector, tokenId, block.timestamp));
        etherverseNFT.safeTransferFrom(whitelistedGameContract, minter1, tokenId, "");
    }

    function testWithdraw() public {
        // mint the nft first

        vm.prank(whitelistedGameContract);
        usdc.approve(address(etherverseNFT), 100000);

        vm.prank(whitelistedGameContract);
        uint256 tokenId = etherverseNFT.mint(whitelistedGameContract, emptyAuthParams);
        assertEq(etherverseNFT.ownerOf(tokenId), whitelistedGameContract);

        // check the USDC balance of contract etherverseNFT
        // after minting the NFT // it should be 10% of minting price as set in feesplit which assetcreator can withdraw ,which
        //should come 0.05$

        assertEq(IERC20(usdc).balanceOf(address(etherverseNFT)), 10000);

        //prank assetWalletAddress and then withdraw

        vm.prank(etherverseNFT.assetCreatorWallet());

        etherverseNFT.withdraw(address(usdc));

        // check balance of assetWalletAddress after withdraw

        assertEq(IERC20(usdc).balanceOf(etherverseNFT.assetCreatorWallet()), 10000);
    }


    
    function testFreeUpgradeSuccess() public {
       
        // mint the nft first
        vm.prank(whitelistedGameContract);
        usdc.approve(address(etherverseNFT), 100000);

        vm.prank(whitelistedGameContract);
        uint256 tokenId = etherverseNFT.mint(whitelistedGameContract, emptyAuthParams);
        assertEq(etherverseNFT.ownerOf(tokenId), whitelistedGameContract);

        vm.prank(whitelistedGameContract);
        etherverseNFT.freeUpgrade(tokenId);

        (uint8 stat1, uint8 stat2, uint8 stat3) = etherverseNFT.getTokenStats(tokenId);
        Asset.Stat memory upgradedStat = Asset.Stat(stat1, stat2, stat3);

        assertEq(upgradedStat.stat1, 89); 
        assertEq(upgradedStat.stat2, 22);  
        assertEq(upgradedStat.stat3, 23); 
    }

    // //     function skiptestFreeUpgradeRevertNotWhitelisted__Failing() public {
    // //         // set the mint price to 0.1 USDC(USDC has 6 decimals)
    // //         vm.prank(owner);
    // //         etherverseNFT.setMintPrice(100000);

    // //         // top up the minter1 account with 0.1 ether for purpose of paying transaction fee
    // //         vm.deal(minter1, 100000000000000000);

    // //         // assert that the minter1 account has 0.1 ether

    // //         assertEq(address(minter1).balance, 100000000000000000);

    // //         // aprove the etherverseNFT contract to spend 0.1 USDC on behalf of the minter1

    // //         vm.prank(minter1);
    // //         usdc.approve(address(etherverseNFT), 100000);

    // //         // mint the NFT
    // //         vm.prank(minter1);
    // //         uint256 tokenId = etherverseNFT.mint(minter1, emptyAuthParams);
    // //         assertEq(etherverseNFT.ownerOf(tokenId), minter1);

    // //         // vm.prank(minter1);
    // //         // vm.expectRevert(abi.encodeWithSelector(Errors.CallerMustBeWhitelisted.selector, nonWhitelistedUser));
    // //         // etherverseNFT.freeUpgrade(tokenId);
    // //     }

        function testFreeUpgradeRevertNotMinted() public {
            vm.prank(whitelistedGameContract);

            vm.expectRevert(Errors.NotMinted.selector);
            etherverseNFT.freeUpgrade(9999999);
        }

        function testpaidUpgradeSuccess() public {
            // mint the nft first
            vm.prank(whitelistedGameContract);
            usdc.approve(address(etherverseNFT), 100000);

            vm.prank(whitelistedGameContract);
            uint256 tokenId = etherverseNFT.mint(whitelistedGameContract, emptyAuthParams);
            assertEq(etherverseNFT.ownerOf(tokenId), whitelistedGameContract);

            vm.prank(whitelistedGameContract);
            etherverseNFT.paidUpgrade(tokenId, emptyAuthParams);

            (uint8 stat1, uint8 stat2, uint8 stat3) = etherverseNFT.getTokenStats(tokenId);
            Asset.Stat memory upgradedStat = Asset.Stat(stat1, stat2, stat3);

            assertEq(upgradedStat.stat1, 92); // 87+5
            assertEq(upgradedStat.stat2, 25); // 20+5
            assertEq(upgradedStat.stat3, 26); // 21+5
        }

        function testpaidUpgradeRevertNotMinted() public {
            vm.prank(whitelistedGameContract);
            vm.expectRevert(Errors.NotMinted.selector);
            etherverseNFT.paidUpgrade(9999999, emptyAuthParams);
        }

    // //     function skiptestpaidUpgradeRevertNotWhitelisted__Failing() public {
    // //         // set the mint price to 0.1 USDC(USDC has 6 decimals)
    // //         vm.prank(owner);
    // //         etherverseNFT.setMintPrice(100000);

    // //         // top up the minter1 account with 0.1 ether for purpose of paying transaction fee
    // //         vm.deal(minter1, 100000000000000000);

    // //         // assert that the minter1 account has 0.1 ether

    // //         assertEq(address(minter1).balance, 100000000000000000);

    // //         // aprove the etherverseNFT contract to spend 0.1 USDC on behalf of the minter1

    // //         vm.prank(minter1);
    // //         usdc.approve(address(etherverseNFT), 100000);

    // //         // mint the NFT
    // //         vm.prank(minter1);
    // //         uint256 tokenId = etherverseNFT.mint(minter1, emptyAuthParams);
    // //         assertEq(etherverseNFT.ownerOf(tokenId), minter1);

    // //         // vm.prank(minter1);
    // //         // vm.expectRevert(abi.encodeWithSelector(Errors.CallerMustBeWhitelisted.selector, nonWhitelistedUser));
    // //         // etherverseNFT.paidUpgrade(tokenId);
    // //     }

       

  

        

    //     function testNextUpgradeSuccess__Failing() public {

    //        // mint the nft first
    //         vm.prank(whitelistedGameContract);
    //         usdc.approve(address(etherverseNFT), 100000);

    //         vm.prank(whitelistedGameContract);
    //         uint256 tokenId = etherverseNFT.mint(whitelistedGameContract, emptyAuthParams);
    //         assertEq(etherverseNFT.ownerOf(tokenId), whitelistedGameContract);

    //         vm.prank(whitelistedGameContract);
            
    //         etherverseNFT.nextUpgrade(tokenId, Upgrade.Type.Free);

    //         (uint8 stat1, uint8 stat2, uint8 stat3) = etherverseNFT.getTokenStats(tokenId);
    //      Asset.Stat memory upgradedStatFree = Asset.Stat(stat1, stat2, stat3);

    //          // assert the value

    //         assertEq(upgradedStatFree.stat1, 10); // expecting 12
    //         assertEq(upgradedStatFree.stat2, 20); // expecting 22
    //         assertEq(upgradedStatFree.stat3, 30); // expecting 32

    //         // do the free upgrade and then test the nextUpgrade for "Free" version again to see if the next stats are updated to 12,22,32

    //     vm.prank(whitelistedGameContract);
    //     etherverseNFT.freeUpgrade(tokenId);
  
    //     vm.prank(whitelistedGameContract);
    //     etherverseNFT.nextUpgrade(tokenId, Upgrade.Type.Free);

    //     (uint8 stat1Free, uint8 stat2Free, uint8 stat3Free) = etherverseNFT.getTokenStats(tokenId);

    //     Asset.Stat memory upgradedStatFreeNext = Asset.Stat(stat1Free, stat2Free, stat3Free);

    //     assertEq(upgradedStatFreeNext.stat1, 12); // expecting 12
    //     assertEq(upgradedStatFreeNext.stat2, 22); // expecting 22
    //     assertEq(upgradedStatFreeNext.stat3, 32); // expecting 32



    //       vm.prank(whitelistedGameContract);
            
    //         etherverseNFT.nextUpgrade(tokenId, Upgrade.Type.Paid);

    //         (uint8 stat1Paid, uint8 stat2Paid, uint8 stat3Paid) = etherverseNFT.getTokenStats(tokenId);
    //      Asset.Stat memory upgradedStatPaid = Asset.Stat(stat1Paid, stat2Paid, stat3Paid);

    //       assertEq(upgradedStatPaid.stat1, 12); 
    //     assertEq(upgradedStatPaid.stat2, 22); 
    //     assertEq(upgradedStatPaid.stat3, 32);


    //     }


     
    


    // function testNextUpgradePriceSuccess__Failing() public {

    //        // mint the nft first
    //         vm.prank(whitelistedGameContract);
    //         usdc.approve(address(etherverseNFT), 100000);

    //         vm.prank(whitelistedGameContract);
    //         uint256 tokenId = etherverseNFT.mint(whitelistedGameContract, emptyAuthParams);
    //         assertEq(etherverseNFT.ownerOf(tokenId), whitelistedGameContract);

    //         vm.prank(whitelistedGameContract);
            
    //          uint256 price = etherverseNFT.nextUpgradePrice(tokenId);

    //          // assert the value

    //         assertEq(price, 50000);

       // }
















}
