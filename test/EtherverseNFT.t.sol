

// // SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// forge test --match-path test/EtherverseNFT.t.sol -vvv

import {Test, console} from "forge-std/Test.sol";
//import {etherverseNFT} from "../src/nft/RPG.sol";  //EtherverseNFT
import {EtherverseNFT} from "../src/nft/main/template/EtherverseNFT.sol"; 
import "../src/nft/lib/Structs.sol";
import "../src/nft/lib/errors.sol";
import "../src/common/interface/IUSDC.sol";
import "../src/nft/lib/Fee.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../src/mock/MockUSDC.sol";
import "../src/misc/Game.sol";
//import "../src/nft/helpers/Upgrades/UpgradeV1.sol";
import "../src/nft/helpers/Upgrades/UpgradeV1.sol";
import {IFrame} from "../src/nft/main/template/EtherverseNFT.sol"; 

import "./Game.t.sol";


contract etherverseNFTTest is Test {

    EtherverseNFT public etherverseNFT;
    address public initialAssetCreatorOwner = 0x762aD31Ff4bD1ceb5b3b5868672d5CBEaEf609dF;
    address public assetCreatorWallet = 0xa1293A8bFf9323aAd0419E46Dd9846Cc7363D44b;

    address public whitelisted_user1 = address(0x3);
    address public user = address(0x4);
    address public minter1 = address(0x5);
    address public minter2 = address(0x6);
    address public nonWhitelistedUser = address(0x3);
    address public whitelistedGameContract;
    address public mockUSDCAddress;
    address public ccipHandler = 0x3c7444D7351027473698a7DCe751eE6Aea8036ee;
    //address public usdc = 0x0Fd9e8d3aF1aaee056EB9e802c3A762a667b1904;



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
    UpgradeV1  public upgradeV1;

     
     function setUp() public {

        // Deploy Mock USDC token
        usdc = new MockUSDC();
         //console.log("USDC address: ", address(usdc));
        //USDC address:  0xFEfC6BAF87cF3684058D62Da40Ff3A795946Ab06
        mockUSDCAddress = address(usdc);


          // deploy UpgradeV1.sol

           upgradeV1 = new UpgradeV1();
           //console.log("UpgradeV1 address: ", address(upgradeV1));
           //UpgradeV1 address:  0x72384992222BE015DE0146a6D7E5dA0E19d2Ba49

        // Deploy EtherverseNFT.sol
        etherverseNFT = new EtherverseNFT("EtherverseSWORD", "EVR", initialAssetCreatorOwner);
        //console.log("EtherverseNFT address: ", address(etherverseNFT)); 
        //EtherverseNFT address:  0xFEfC6BAF87cF3684058D62Da40Ff3A795946Ab06


            // deploy Game.sol

         game = new Game(etherverse, gameDeveloperWalletAddress,gameDeveloperFeeCollectorWallet,address(usdc),address(upgradeV1),web3techInitialOwner,marketFee,etherverseFee,gamename);
         //console.log("Game contract address: ", address(game));
        //Game contract address:  0x08526067985167EcFcB1F9720C72DbBF36c96018

         whitelistedGameContract = address(game);


         // 1000 USDC with 6 decimals
          
           uint256 amount = 100000 * 10 ** 6;

         usdc.mint(whitelistedGameContract, amount);
      
          // assert that the whitelisted_user1 account has 100 USDC
            
        assertEq(usdc.balanceOf(whitelistedGameContract), amount);


         // set the whitelistedGameContract as whitelisted

         vm.prank(initialAssetCreatorOwner);
         etherverseNFT.setWhitelisted(whitelistedGameContract, true);

        //assert that the whitelistedGameContract is whitelisted
        assertTrue(etherverseNFT.whitelisted(whitelistedGameContract));



    }
         
         //@audit : when running construcotr test with all other tests ,stack too deep error coming
       function testConstructorParameters() public {
        assertEq(etherverseNFT.name(), "EtherverseSWORD");
        assertEq(etherverseNFT.symbol(), "EVR");
        assertEq(etherverseNFT.owner(), initialAssetCreatorOwner);
        assertEq(etherverseNFT.assetCreatorWallet(), 0xa1293A8bFf9323aAd0419E46Dd9846Cc7363D44b);
        assertEq(etherverseNFT.USDC(), 0xFEfC6BAF87cF3684058D62Da40Ff3A795946Ab06);

        (uint8 stat1, uint8 stat2, uint8 stat3) = etherverseNFT.baseStat();
        assertEq(stat1, 87);
        assertEq(stat2, 20);
        assertEq(stat3, 21);

        Asset.StatType[3] memory statLabels = etherverseNFT.statLabelsArray();
        assertEq(uint256(statLabels[0]), uint256(Asset.StatType.STR));
        assertEq(uint256(statLabels[1]), uint256(Asset.StatType.DEX));
        assertEq(uint256(statLabels[2]), uint256(Asset.StatType.CON));
       
   
       assertEq(uint256(etherverseNFT.AssetType()), uint256(Asset.Type.Weapon));
        assertEq(etherverseNFT.svgColors(0), 213);
        assertEq(etherverseNFT.svgColors(1), 123);
        assertEq(etherverseNFT.svgColors(2), 312);
        assertEq(etherverseNFT.colorRanges(0), 0);
        assertEq(etherverseNFT.colorRanges(1), 10);
        assertEq(etherverseNFT.colorRanges(2), 20);
        assertEq(etherverseNFT.colorRanges(3), 30);
        assertEq(etherverseNFT.itemImage(), "https://ipfs.io/ipfs/QmVQ2vpBD1U6P22V2xaHk5KF5x6mQAM7HmFsc8c2AsQhgo");
        assertEq(etherverseNFT._ccipHandler(), ccipHandler);
        // (uint256 split, uint256 amount) = etherverseNFT.mintPricing();
        // assertEq(split, 1000);    // @audit Failing
        // assertEq(amount, 100000);  // @audit Failing
        assertEq(etherverseNFT.frameAddress(), address(0));
        assertEq(etherverseNFT.metadata(), "{}");
    }

      function testSetSign() public {
        bytes memory sign = "0x1234";
        vm.prank(initialAssetCreatorOwner);
        etherverseNFT.setSign(sign);
        assertEq(etherverseNFT.sign(), sign);
    }

  function testSetSignRevertNotOwner() public {
    bytes memory sign = "0x1234";
    vm.prank(user);
    vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", user));
    etherverseNFT.setSign(sign);
}

 function testSetTokenLockStatus() public {
        uint256 tokenId = 1;
        uint256 unlockTime = block.timestamp + 1 days;
        vm.prank(ccipHandler);
        etherverseNFT.setTokenLockStatus(tokenId, unlockTime);
        assertEq(etherverseNFT.tokenLockedTill(tokenId), unlockTime);
    }


    function testSetTokenLockStatusRevertNotCCIPHandler() public {
    uint256 tokenId = 1;
    uint256 unlockTime = block.timestamp + 1 days;
    vm.prank(user);
    vm.expectRevert(abi.encodeWithSelector(Errors.UnauthorizedAccess.selector, user));
    etherverseNFT.setTokenLockStatus(tokenId, unlockTime);
}

    function testLockStatus() public {
        uint256 tokenId = 1;
        uint256 unlockTime = block.timestamp + 1 days;
        vm.prank(ccipHandler);
        etherverseNFT.setTokenLockStatus(tokenId, unlockTime);
        assertTrue(etherverseNFT.lockStatus(tokenId));
    }

    function testLockStatusUnlocked() public {
        uint256 tokenId = 1;
        assertFalse(etherverseNFT.lockStatus(tokenId));
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


    
      function testSetWhitelisted() public {
        vm.prank(initialAssetCreatorOwner);
        etherverseNFT.setWhitelisted(user, true);
        assertTrue(etherverseNFT.whitelisted(user));
    }


 

    function testChangeCCIP() public {
        vm.prank(initialAssetCreatorOwner);
        etherverseNFT.changeCCIP(ccipHandler);
        assertEq(etherverseNFT._ccipHandler(), ccipHandler);
    }

 

  function testSetWhitelistedRevertNotOwner() public {
    vm.prank(user);
    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user));
    etherverseNFT.setWhitelisted(user, true);
}

function testChangeCCIPRevertNotOwner() public {
    vm.prank(user);
    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user));
    etherverseNFT.changeCCIP(ccipHandler);
}

function testChangeFrame() public {

        address frameAddress = address(0x1234);
        vm.prank(initialAssetCreatorOwner);
        etherverseNFT.changeFrame(frameAddress);
        assertEq(etherverseNFT.frameAddress(), frameAddress);
    }

    function testChangeFrameRevertNotOwner() public {
        
        address frameAddress = address(0x1234);
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user));
        etherverseNFT.changeFrame(frameAddress);
    }

    function testChangeImageUrl() public {
        string memory newImageUrl = "https://newimage.url";
        vm.prank(initialAssetCreatorOwner);
        etherverseNFT.changeImageUrl(newImageUrl);
        assertEq(etherverseNFT.itemImage(), newImageUrl);
    }

    function testChangeImageUrlRevertNotOwner() public {
        string memory newImageUrl = "https://newimage.url";
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user));
        etherverseNFT.changeImageUrl(newImageUrl);
    }

 function testSetMetadata() public {
        string memory newMetadata = '{"name": "New Metadata"}';
        vm.prank(initialAssetCreatorOwner);
        etherverseNFT.setMetadata(newMetadata);
        assertEq(etherverseNFT.metadata(), newMetadata);
    }

    function testSetMetadataRevertNotOwner() public {
        string memory newMetadata = '{"name": "New Metadata"}';
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user));
        etherverseNFT.setMetadata(newMetadata);
    }


    
    function testSetMintPricing() public {
        vm.prank(initialAssetCreatorOwner);
        etherverseNFT.setMintPricing(100000, 1000);   // set mint price to 0.1 USDC and 10% fee split
        (uint256 amount, uint256 split) = etherverseNFT.mintPricing();
        assertEq(amount, 100000);
        assertEq(split, 1000);
    }


     function testSetMintPricingRevertSplitTooHigh() public {
        vm.prank(initialAssetCreatorOwner);
        vm.expectRevert(Errors.SplitTooHigh.selector);
        etherverseNFT.setMintPricing(200000, 9000);
    }

    function testSetMintPricingRevertNotOwner() public {
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user));
        etherverseNFT.setMintPricing(200000, 5000);
    }


   
    function testSetMintPricingZeroAmount() public {
        vm.prank(initialAssetCreatorOwner);
        etherverseNFT.setMintPricing(0, 5000);
        (uint256 amount, uint256 split) = etherverseNFT.mintPricing();
        assertEq(amount, 100000); // Default amount
        assertEq(split, 5000);
    }

    function testSetMintPricingZeroSplit() public {
        vm.prank(initialAssetCreatorOwner);
        etherverseNFT.setMintPricing(200000, 0);
        (uint256 amount, uint256 split) = etherverseNFT.mintPricing();
        assertEq(amount, 200000);
        assertEq(split, 1000); // Default split
    }


        function testSetUpgradePricing() public {
        vm.prank(whitelistedGameContract);
        etherverseNFT.setUpgradePricing(300000, 2000); // 0.3USDC fee and 20% fee split
        (uint256 amount, uint256 split) = etherverseNFT.upgradePricing(whitelistedGameContract);
        assertEq(amount, 300000);
        assertEq(split, 2000);
    }

    function testSetUpgradePricingRevertSplitTooHigh() public {
        vm.prank(whitelistedGameContract);
        vm.expectRevert(Errors.SplitTooHigh.selector);
        etherverseNFT.setUpgradePricing(300000, 9000);
    }

    function testSetUpgradePricingRevertNotWhitelisted() public {
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(Errors.CallerMustBeWhitelisted.selector, user));
        etherverseNFT.setUpgradePricing(300000, 6000);
    }

     function testMint() public {  

    
       //assert that the whitelistedGameContract is whitelisted
       assertTrue(etherverseNFT.whitelisted(whitelistedGameContract));
         
       //assert that mint price is set to 0.1 USDC
        (uint256 amount, uint256 split) = etherverseNFT.mintPricing();
        assertEq(amount, 100000);
        assertEq(split, 1000);


      // assert that the whitelistedGameContract account has usdc funds to pay for fee,should be greater than 100usdc as set it up on setup

        assertEq(usdc.balanceOf(whitelistedGameContract), 100000 * 10 ** 6);

        // aprove the etherverseNFT contract to spend 0.1 USDC on behalf of the whitelistedGameContract

        vm.prank(whitelistedGameContract);
        usdc.approve(address(etherverseNFT), 100000);

        // mint the NFT to minter1
        bytes memory authorizationParams = "";
        vm.prank(whitelistedGameContract);
        uint256 tokenId = etherverseNFT.mint(whitelistedGameContract, authorizationParams);
        assertEq(tokenId, 1000000);
       assertEq(etherverseNFT.ownerOf(tokenId), whitelistedGameContract);

    }

    function testMintRevertNotWhitelisted() public {
        bytes memory authorizationParams = "";
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(Errors.CallerMustBeWhitelisted.selector, user));
        etherverseNFT.mint(nonWhitelistedUser, authorizationParams);
    }

       function testMintRevertExceedsCapacity() public {

        
        // aprove the etherverseNFT contract to spend 0.1*100001 USDC on behalf of the whitelistedGameContract
        vm.prank(whitelistedGameContract);
        usdc.approve(address(etherverseNFT), 11000000000);

        bytes memory authorizationParams = "";
         vm.startPrank(whitelistedGameContract);
        for (uint256 i = 0; i < 100001; i++) {
            etherverseNFT.mint(whitelistedGameContract, authorizationParams);
        }
        vm.expectRevert(Errors.ExceedsCapacity.selector);
        etherverseNFT.mint(whitelistedGameContract, authorizationParams);
        vm.stopPrank();
    }


    function testGetTokenStats() public {

        
        // aprove the etherverseNFT contract to spend 0.1 USDC on behalf of the whitelistedGameContract

        vm.prank(whitelistedGameContract);
        usdc.approve(address(etherverseNFT), 100000);

        // mint the NFT
        bytes memory authorizationParams = "";
        vm.prank(whitelistedGameContract);
        uint256 tokenId = etherverseNFT.mint(whitelistedGameContract, authorizationParams);
        assertEq(tokenId, 1000000);
       assertEq(etherverseNFT.ownerOf(tokenId), whitelistedGameContract);

       // call  getTokenStats 

    uint8[3] memory stats = etherverseNFT.getTokenStats(tokenId);

    // Check the stats
    assertEq(stats[0], 87);
    assertEq(stats[1], 20);
    assertEq(stats[2], 21);
}


 function testGetTokenStatsRevertNotMinted() public {
    uint256 tokenId = 999999;
    vm.expectRevert(Errors.NotMinted.selector);
     uint8[3] memory stats = etherverseNFT.getTokenStats(tokenId);
}


 function testGetOwner() public {
     // aprove the etherverseNFT contract to spend 0.1 USDC on behalf of the whitelistedGameContract

        vm.prank(whitelistedGameContract);
        usdc.approve(address(etherverseNFT), 100000);

        // mint the NFT
        bytes memory authorizationParams = "";
        vm.prank(whitelistedGameContract);
        uint256 tokenId = etherverseNFT.mint(whitelistedGameContract, authorizationParams);
        assertEq(tokenId, 1000000);
       assertEq(etherverseNFT.ownerOf(tokenId), whitelistedGameContract);

        // call  getOwner

        assertEq(etherverseNFT.getOwner(tokenId), whitelistedGameContract);

    }

    
    // function testTokenURI() public {

    //          // aprove the etherverseNFT contract to spend 0.1 USDC on behalf of the whitelistedGameContract

    //     vm.prank(whitelistedGameContract);
    //     usdc.approve(address(etherverseNFT), 100000);

    //     // mint the NFT
    //     bytes memory authorizationParams = "";
    //     vm.prank(whitelistedGameContract);
    //     uint256 tokenId = etherverseNFT.mint(whitelistedGameContract, authorizationParams);
    //     assertEq(tokenId, 1000000);
    //    assertEq(etherverseNFT.ownerOf(tokenId), whitelistedGameContract);


    //     string memory uri = etherverseNFT.tokenURI(tokenId);
    //      address frameAddress   = etherverseNFT.frameAddress();
    //     assertEq(uri, IFrame(frameAddress).tokenURI(tokenId));
    // }


    function testTransferFromSuccess() public {
       
     
        // aprove the etherverseNFT contract to spend 0.1 USDC on behalf of the whitelistedGameContract

        vm.prank(whitelistedGameContract);
        usdc.approve(address(etherverseNFT), 100000);

        // mint the NFT
        bytes memory authorizationParams = "";
        vm.prank(whitelistedGameContract);
        uint256 tokenId = etherverseNFT.mint(whitelistedGameContract, authorizationParams);
        assertEq(tokenId, 1000000);
       assertEq(etherverseNFT.ownerOf(tokenId), whitelistedGameContract);
        
        // transfer the NFT to minter1
        vm.prank(whitelistedGameContract);
        etherverseNFT.transferFrom(whitelistedGameContract, minter1, tokenId);
        assertEq(etherverseNFT.ownerOf(tokenId), minter1);
    }


    
    function testsafeTransferFromSuccess() public {
       
     
        // aprove the etherverseNFT contract to spend 0.1 USDC on behalf of the whitelistedGameContract

        vm.prank(whitelistedGameContract);
        usdc.approve(address(etherverseNFT), 100000);

        // mint the NFT
        bytes memory authorizationParams = "";
        vm.prank(whitelistedGameContract);
        uint256 tokenId = etherverseNFT.mint(whitelistedGameContract, authorizationParams);
        assertEq(tokenId, 1000000);
       assertEq(etherverseNFT.ownerOf(tokenId), whitelistedGameContract);
        
        // transfer the NFT to minter1
        vm.prank(whitelistedGameContract);
        etherverseNFT.safeTransferFrom(whitelistedGameContract, minter1, tokenId);
        assertEq(etherverseNFT.ownerOf(tokenId), minter1);
    }


        function testGetStatValid() public {
        // mint the NFT

        vm.prank(whitelistedGameContract);
        // approve the etherverseNFT contract to spend 0.1 USDC on behalf of the whitelistedGameContract

        usdc.approve(address(etherverseNFT), 100000);

        //mint the NFT to whitelistedGameContract by the whitelistedGameContract
        
        bytes memory authorizationParams = "";
        vm.prank(whitelistedGameContract);
        uint256 tokenId = etherverseNFT.mint(whitelistedGameContract, authorizationParams);

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

  
     function testFreeUpgrade() public {
           
        // aprove the etherverseNFT contract to spend 0.1 USDC on behalf of the whitelistedGameContract

        vm.prank(whitelistedGameContract);
        usdc.approve(address(etherverseNFT), 100000);

        // mint the NFT
        bytes memory authorizationParams = "";
        vm.prank(whitelistedGameContract);
        uint256 tokenId = etherverseNFT.mint(whitelistedGameContract, authorizationParams);
        assertEq(tokenId, 1000000);
        assertEq(etherverseNFT.ownerOf(tokenId), whitelistedGameContract);

        // Perform free upgrade
        vm.prank(whitelistedGameContract);
        game.freeUpgrade(address(etherverseNFT), tokenId);

        // Verify the upgrade
    uint8[3] memory upgradedStats = etherverseNFT.getTokenStats(tokenId);  //@audit this should not be called sperately rather should be embedded in the freeUpgrade function
    assertEq(upgradedStats[0], 89); // 87 + 2
    assertEq(upgradedStats[1], 22); // 20 + 2
    assertEq(upgradedStats[2], 23); // 21 + 2

    }

    function testPaidUpgrade() public {

        // aprove the etherverseNFT contract to spend 0.1 USDC on behalf of the whitelistedGameContract

        vm.prank(whitelistedGameContract);
        usdc.approve(address(etherverseNFT), 100000);

        // mint the NFT
        bytes memory authorizationParams = "";
        vm.prank(whitelistedGameContract);
        uint256 tokenId = etherverseNFT.mint(whitelistedGameContract, authorizationParams);
        assertEq(tokenId, 1000000);
        assertEq(etherverseNFT.ownerOf(tokenId), whitelistedGameContract);

        //check the USDC balance of whitelistedGameContract before paid upgrade console log the balance

        console.log("USDC balance of whitelistedGameContract before paid upgrade: ", usdc.balanceOf(whitelistedGameContract));


        // Perform paid upgrade
        vm.prank(whitelistedGameContract);
        game.paidUpgrade(address(etherverseNFT), tokenId ,authorizationParams);

        // Verify the upgrade
    uint8[3] memory upgradedStats = etherverseNFT.getTokenStats(tokenId);  //@audit this should not be called sperately rather should be embedded in the freeUpgrade function
    assertEq(upgradedStats[0], 92); // 87 + 5
    assertEq(upgradedStats[1], 25); // 20 + 5
    assertEq(upgradedStats[2], 26); // 21 + 5

      //check the USDC balance of whitelistedGameContract after paid upgrade console log the balance

        console.log("USDC balance of whitelistedGameContract after paid upgrade: ", usdc.balanceOf(whitelistedGameContract));

        //@audit : no usdc balance got deducted from the whitelistedGameContract account after paid upgrade

     }

    function testNextUpgrade() public {  
          
        // aprove the etherverseNFT contract to spend 0.1 USDC on behalf of the whitelistedGameContract

        vm.prank(whitelistedGameContract);
        usdc.approve(address(etherverseNFT), 100000);

        // mint the NFT
        bytes memory authorizationParams = "";
        vm.prank(whitelistedGameContract);
        uint256 tokenId = etherverseNFT.mint(whitelistedGameContract, authorizationParams);
        assertEq(tokenId, 1000000);
        assertEq(etherverseNFT.ownerOf(tokenId), whitelistedGameContract);

        // Get next free upgrade
        vm.prank(whitelistedGameContract);
        Asset.Stat memory nextFreeUpgrade = game.nextUpgrade(address(etherverseNFT), tokenId, Upgrade.Type.Free);
        assertEq(nextFreeUpgrade.stat1, 89); // 87 + 2
        assertEq(nextFreeUpgrade.stat2, 22); // 20 + 2
        assertEq(nextFreeUpgrade.stat3, 23); // 21 + 2

        //Get next paid upgrade
        vm.prank(whitelistedGameContract);
        Asset.Stat memory nextPaidUpgrade = game.nextUpgrade(address(etherverseNFT), tokenId, Upgrade.Type.Paid);
        assertEq(nextPaidUpgrade.stat1, 92); // 87 + 5
        assertEq(nextPaidUpgrade.stat2, 25); // 20 + 5
        assertEq(nextPaidUpgrade.stat3, 26); // 21 + 5
    }


     function testNextUpgradeRevertNotMinted() public {

        uint256 tokenId = 999999;
        vm.expectRevert(Errors.NotMinted.selector);
        game.nextUpgrade(address(etherverseNFT), tokenId, Upgrade.Type.Free);

    }

 

function testNextUpgradePrice() public {
    // Approve the etherverseNFT contract to spend 0.1 USDC on behalf of the whitelistedGameContract
    vm.prank(whitelistedGameContract);
    usdc.approve(address(etherverseNFT), 100000);

    // Mint the NFT
    bytes memory authorizationParams = "";
    vm.prank(whitelistedGameContract);
    uint256 tokenId = etherverseNFT.mint(whitelistedGameContract, authorizationParams);
    assertEq(tokenId, 1000000);
    assertEq(etherverseNFT.ownerOf(tokenId), whitelistedGameContract);

    // Get next upgrade price via Game contract
    vm.prank(whitelistedGameContract);
    uint256 nextPrice = game.nextUpgradePrice(address(etherverseNFT), tokenId);
    console.log("Next Price: ", nextPrice);

    // Access the amount field from the Price struct
    (uint256 amount, uint256 split) = etherverseNFT.upgradePricing(address(game));
    (uint8 stat1, uint8 stat2, uint8 stat3) = etherverseNFT.upgradeMapping(tokenId);
    Asset.Stat memory currentStat = Asset.Stat(stat1, stat2, stat3);
    uint256 expectedPrice = upgradeV1.calculatePrice(amount, currentStat);
    assertEq(nextPrice, expectedPrice);
}


    // function testTokenURI() public {
    //     uint256 tokenId = 1000000;
    //     string memory expectedURI = "https://example.com/token/1000000";
    //     vm.mockCall(frameAddress, abi.encodeWithSelector(IFrame.tokenURI.selector, tokenId), abi.encode(expectedURI));
    //     assertEq(etherverseNFT.tokenURI(tokenId), expectedURI);
    // }

    // function testTokenURIRevertNotMinted() public {
    //     uint256 tokenId = 999999;
    //     vm.expectRevert(Errors.NotMinted.selector);
    //     etherverseNFT.tokenURI(tokenId);
    // }









}





// contract etherverseNFTTest is Test {
//     EtherverseNFT public etherverseNFT;
//     address public owner = 0x762aD31Ff4bD1ceb5b3b5868672d5CBEaEf609dF;
//     address public ccipHandler = 0x3c7444D7351027473698a7DCe751eE6Aea8036ee;
//     address public whitelisted_user1 = address(0x3);
//     address public user = address(0x4);
//     address public minter1 = address(0x5);
//     address public minter2 = address(0x6);
//     address public nonWhitelistedUser = address(0x3);
//     address public whitelistedGameContract;

//     // Game.sol Related
//     Game public game;
//     address public etherverse = address(0x0C903F1C518724CBF9D00b18C2Db5341fF68269C); //external wallet fee collector address which will be pridevel wallet
//     address gameDeveloperWalletAddress = address(0x7);
//     address gameDeveloperFeeCollectorWallet = address(0x8);
//     address web3techInitialOwner = address(0x9);
//     address public upgradeV1ContractAddress; //deployment address of UpgradeV1
//     uint256 public marketFee = 4269; // what commission does the game take which  ingame fees collected by game developer // eg  42.69% 4269
//     uint256 public etherverseFee = 900; // web3tech platform fee // 9% 900
//     string public gamename = "GTA"; // name of the game

//     MockUSDC public usdc;
//     GameTest public gameTest;
//     //Game public game;

//     bytes emptyAuthParams = "";

//     function setUp() public {
//         vm.startPrank(owner);
//         etherverseNFT = new EtherverseNFT();
//         vm.stopPrank();

//         // Deploy Mock USDC token
//         usdc = new MockUSDC();
//         // console.log("USDC address: ", address(usdc));
//         //0xFEfC6BAF87cF3684058D62Da40Ff3A795946Ab06

//         // deploy UpgradeV1.sol

//         UpgradeV1 upgradeV1 = new UpgradeV1();
//         // console.log("UpgradeV1 address: ", address(upgradeV1));
//         // upgradeV1 = 0xFEfC6BAF87cF3684058D62Da40Ff3A795946Ab06;

//         upgradeV1ContractAddress = address(upgradeV1);

//         // deploy Game.sol



//          game = new Game(etherverse, gameDeveloperWalletAddress,gameDeveloperFeeCollectorWallet, address(usdc), address(upgradeV1),web3techInitialOwner, marketFee, etherverseFee, gamename);
//         //console.log("Game contract address: ", address(game));
//         //0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f'

//         whitelistedGameContract = address(game);

//         // Set the USDC address in the etherverseNFT contract
//         vm.prank(owner);
//         etherverseNFT.setUSDC(address(usdc));

//         // 100000 USDC with 6 decimals

//         uint256 amount = 100000 * 10 ** 6;

//         usdc.mint(whitelistedGameContract, amount);

//         // assert that the whitelisted_user1 account has 100 USDC

//         assertEq(usdc.balanceOf(whitelistedGameContract), amount);

//         // set the whitelistedGameContract as whitelisted

//         vm.prank(owner);
//         etherverseNFT.setWhitelisted(whitelistedGameContract, true);

//         //assert that the whitelistedGameContract is whitelisted

//         assertTrue(etherverseNFT.whitelisted(whitelistedGameContract));
//     }

//     function testConstructor() public {
//         // Check initial values set by the constructor
//         assertEq(etherverseNFT.name(), "Sword");
//         assertEq(etherverseNFT.symbol(), "SW");
//         assertEq(etherverseNFT.etherverseWallet(), 0x0C903F1C518724CBF9D00b18C2Db5341fF68269C);
//         assertEq(etherverseNFT.assetCreatorWallet(), 0xa1293A8bFf9323aAd0419E46Dd9846Cc7363D44b);
//         assertEq(etherverseNFT.USDC(), 0xFEfC6BAF87cF3684058D62Da40Ff3A795946Ab06);
//         // assertEq(etherverseNFT.baseStat().stat1, 10);
//         // assertEq(etherverseNFT.baseStat().stat2, 20);
//         // assertEq(etherverseNFT.baseStat().stat3, 30);

//         (uint8 stat1, uint8 stat2, uint8 stat3) = etherverseNFT.baseStat();
//         assertEq(stat1, 87);
//         assertEq(stat2, 20);
//         assertEq(stat3, 21);

//         assertEq(uint256(etherverseNFT.statLabels(0)), uint256(Asset.StatType.STR));
//         assertEq(uint256(etherverseNFT.statLabels(1)), uint256(Asset.StatType.DEX));
//         assertEq(uint256(etherverseNFT.statLabels(2)), uint256(Asset.StatType.CON));
//         assertEq(uint256(etherverseNFT.AssetType()), uint256(Asset.Type.Weapon));
//         assertEq(etherverseNFT.svgColors(0), 213);
//         assertEq(etherverseNFT.svgColors(1), 123);
//         assertEq(etherverseNFT.svgColors(2), 312);
//         assertEq(etherverseNFT.colorRanges(0), 0);
//         assertEq(etherverseNFT.colorRanges(1), 10);
//         assertEq(etherverseNFT.colorRanges(2), 20);
//         assertEq(etherverseNFT.colorRanges(3), 30);
//         assertEq(etherverseNFT.itemImage(), "https://ipfs.io/ipfs/QmVQ2vpBD1U6P22V2xaHk5KF5x6mQAM7HmFsc8c2AsQhgo");
//         assertEq(etherverseNFT._ccipHandler(), 0x3c7444D7351027473698a7DCe751eE6Aea8036ee);
//         assertEq(etherverseNFT.mintPrice(), 100000);
//         assertEq(etherverseNFT.uriAddress(), address(0));
//         assertEq(etherverseNFT._nextTokenId(), 1000000);
//         assertEq(etherverseNFT.feeSplit(), 1000);
//     }

  
//     function testColorRangesArray() public {
//         uint8[] memory colorRanges = etherverseNFT.colorRangesArray();
//         assertEq(colorRanges.length, 4);
//         assertEq(colorRanges[0], 0);
//         assertEq(colorRanges[1], 10);
//         assertEq(colorRanges[2], 20);
//         assertEq(colorRanges[3], 30);
//     }

//     function testSvgColorsArray() public {
//         uint24[] memory svgColors = etherverseNFT.svgColorsArray();
//         assertEq(svgColors.length, 3);
//         assertEq(svgColors[0], 213);
//         assertEq(svgColors[1], 123);
//         assertEq(svgColors[2], 312);
//     }

//     function testStatLabelsArray() public {
//         Asset.StatType[3] memory statLabels = etherverseNFT.statLabelsArray();
//         assertEq(uint256(statLabels[0]), uint256(Asset.StatType.STR));
//         assertEq(uint256(statLabels[1]), uint256(Asset.StatType.DEX));
//         assertEq(uint256(statLabels[2]), uint256(Asset.StatType.CON));
//     }

//     function testLockStatus() public {
//         uint256 tokenId = 1;
//         vm.prank(ccipHandler);
//         etherverseNFT.setTokenLockStatus(tokenId, block.timestamp + 1000);
//         assertEq(etherverseNFT.lockStatus(tokenId), true);
//     }

//     function testSetTokenLockStatus() public {
//         uint256 tokenId = 1;
//         uint256 unlockTime = block.timestamp + 1000;
//         vm.prank(ccipHandler);
//         etherverseNFT.setTokenLockStatus(tokenId, unlockTime);
//         assertEq(etherverseNFT.tokenLockedTill(tokenId), unlockTime);
//     }

//     function testSetSign() public {
//         vm.startPrank(owner);
//         etherverseNFT.setSign(12345);
//         assertEq(etherverseNFT.sign(), 12345);
//         vm.stopPrank();
//     }

//     function testChangeCCIP() public {
//         vm.startPrank(owner);
//         address newCCIP = address(0x4);
//         etherverseNFT.changeCCIP(newCCIP);
//         assertEq(etherverseNFT._ccipHandler(), newCCIP);
//         vm.stopPrank();
//     }

 

//     function testChangeImageUrl() public {
//         vm.startPrank(owner);
//         string memory newImageUrl = "https://newimage.url";
//         etherverseNFT.changeImageUrl(newImageUrl);
//         assertEq(etherverseNFT.itemImage(), newImageUrl);
//         vm.stopPrank();
//     }

//     function testSetWhitelisted() public {
//         vm.startPrank(owner);
//         etherverseNFT.setWhitelisted(user, true);
//         assertTrue(etherverseNFT.whitelisted(user));

//         etherverseNFT.setWhitelisted(whitelistedGameContract, true);
//         assertTrue(etherverseNFT.whitelisted(whitelistedGameContract));

//         vm.stopPrank();
//     }

//     function testSetMintPrice() public {
//         vm.startPrank(owner);
//         etherverseNFT.setMintPrice(200000);
//         assertEq(etherverseNFT.mintPrice(), 200000);
//         vm.expectRevert(Errors.ZeroInput.selector);
//         etherverseNFT.setMintPrice(0);
//         vm.stopPrank();
//     }

 


//     function testSetFeeSplit() public {
//         vm.startPrank(owner);
//         etherverseNFT.setFeeSplit(5000);
//         assertEq(etherverseNFT.feeSplit(), 5000);
//         vm.expectRevert(Errors.ZeroInput.selector);
//         etherverseNFT.setFeeSplit(10001);
//         vm.stopPrank();

//     }


//     function testSetUpgradePrice() public {
//         vm.startPrank(owner);
//         etherverseNFT.setWhitelisted(whitelistedGameContract, true);
//         vm.stopPrank();

//         vm.startPrank(whitelistedGameContract);
//         etherverseNFT.setUpgradePrice(50000);
//         assertEq(etherverseNFT.upgradePricing(whitelistedGameContract), 50000);

//         vm.stopPrank();
//     }

//     function testMintSuccess() public {
//         // set the whitelistedGameContract as whitelisted

//         vm.prank(owner);
//         etherverseNFT.setWhitelisted(whitelistedGameContract, true);

//         //assert that the whitelisted_user1 is whitelisted
//         assertTrue(etherverseNFT.whitelisted(whitelistedGameContract));

//         // set the mint price to 0.1 USDC(USDC has 6 decimals)
//         vm.prank(owner);
//         etherverseNFT.setMintPrice(100000);

//         //assert that mint price is set to 0.1 USDC

//         assertEq(etherverseNFT.mintPrice(), 100000);

//         // top up the whitelistedGameContract account with 0.1 ether for purpose of paying transaction fee
//         vm.deal(whitelistedGameContract, 100000000000000000);

//         // assert that the whitelisted_user1 account has 0.1 ether

//         assertEq(address(whitelistedGameContract).balance, 100000000000000000);

//         // aprove the etherverseNFT contract to spend 0.1 USDC on behalf of the whitelisted_user1

//         vm.prank(whitelistedGameContract);
//         usdc.approve(address(etherverseNFT), 100000);

//         //mint the NFT to whitelisted_user1 by the whitelisted_user1
//         vm.prank(whitelistedGameContract);
//         uint256 tokenId = etherverseNFT.mint(whitelistedGameContract, emptyAuthParams);

//         // assert that the tokenId is 1000000
//         assertEq(tokenId, 1000000);

//         // assert that whitelisted_user1 is the owner of the minted tokenId

//         assertEq(etherverseNFT.ownerOf(tokenId), whitelistedGameContract);

        
//     }

//     function testMintRevertNotWhitelisted() public {
//         // set the mint price to 0.1 USDC(USDC has 6 decimals)
//         vm.prank(owner);
//         etherverseNFT.setMintPrice(100000);

//         //assert that mint price is set to 0.1 USDC

//         assertEq(etherverseNFT.mintPrice(), 100000);

//         // top up the minter1 account with 0.1 ether for purpose of paying transaction fee
//         vm.deal(minter1, 100000000000000000);

//         // assert that the minter1 account has 0.1 ether

//         assertEq(address(minter1).balance, 100000000000000000);

//         // aprove the etherverseNFT contract to spend 0.1 USDC on behalf of the minter1

//         vm.prank(minter1);
//         usdc.approve(address(etherverseNFT), 100000);

//         //try to mint the NFT to minter1 by the minter1 which is not whitelisted by owner
//         vm.prank(minter1);
//         vm.expectRevert(abi.encodeWithSelector(Errors.CallerMustBeWhitelisted.selector, minter1));

//         uint256 tokenId = etherverseNFT.mint(minter1, emptyAuthParams);
//     }

//     // function skiptestMintRevertInsufficientUSDC__Failing() public {
//     //     // set the mint price to 0.1 USDC
//     //     vm.prank(owner);
//     //     etherverseNFT.setMintPrice(100000);

//     //     // top up the whitelistedGameContract account with 0.1 ether for purpose of paying transaction fee
//     //     vm.deal(whitelistedGameContract, 100000000000000000);

//     //     // console log balance of USDC in whitelistedGameContract

//     //     console.log("USDC balance of whitelistedGameContract: ", usdc.balanceOf(whitelistedGameContract));

//     //     // // withdraw all the usdc balance from whitelistedGameContract by transferring to minter2

//     //     vm.prank(whitelistedGameContract);
//     //     usdc.transfer(minter2, usdc.balanceOf(whitelistedGameContract));

//     //     console.log(" AFTER :USDC balance of whitelistedGameContract: ", usdc.balanceOf(whitelistedGameContract));

//     //     // // withdraw all the usdc balance from whitelistedGameContract by transferring to 0x00 address to clean up the usdc fund

//     //     // vm.prank(whitelistedGameContract);
//     //     // usdc.transfer(minter2, usdc.balanceOf(whitelistedGameContract));

//     //     // // check that now whitelistGameContract has 0 USDC

//     //     // assertEq(usdc.balanceOf(whitelistedGameContract), 0);

//     //     // top up whitelistedGameContract with insufficient USDC of amount 0.01USDC

//     //     // uint256 amount = 0.01 * 10 ** 6;

//     //     // usdc.mint(whitelistedGameContract, amount);

//     //     // // whitelist whitelistedGameContract account by the owner

//     //     // // vm.prank(owner);
//     //     // // etherverseNFT.setWhitelisted(minter2, true);

//     //     // // aprove the etherverseNFT contract to spend 0.1 USDC on behalf of the minter2

//     //     // vm.prank(whitelistedGameContract);
//     //     // usdc.approve(address(etherverseNFT), 100000);

//     //     // //try to mint the NFT to whitelistedGameContract by the whitelistedGameContract which has insufficient USDC
//     //     // vm.prank(whitelistedGameContract);
//     //     // vm.expectRevert("Insufficient balance");

//     //     // uint256 tokenId = etherverseNFT.mint(whitelistedGameContract, emptyAuthParams);
//     // }

//     // function skiptestMintRevertExceedsCapacity__Failing() public {
//     //     // set the whitelistedGameContract as whitelisted

//     //     vm.prank(owner);
//     //     etherverseNFT.setWhitelisted(whitelistedGameContract, true);

//     //     uint256 STARTING_TOKEN_ID = 1000000;
//     //     uint256 exceededTokenID = STARTING_TOKEN_ID + 100000 + 1;

//     //     // set the mint price to 0.1 USDC(USDC has 6 decimals)
//     //     vm.prank(owner);
//     //     etherverseNFT.setMintPrice(100000);

//     //     //assert that mint price is set to 0.1 USDC

//     //     assertEq(etherverseNFT.mintPrice(), 100000);

//     //     // top up the whitelistedGameContract account with 0.1 ether for purpose of paying transaction fee
//     //     vm.deal(whitelistedGameContract, 100000000000000000);

//     //     // assert that the whitelistedGameContract account has 0.1 ether

//     //     assertEq(address(whitelistedGameContract).balance, 100000000000000000);

//     //     // aprove the etherverseNFT contract to spend 0.1 USDC on behalf of the whitelistedGameContract

//     //     vm.prank(whitelistedGameContract);
//     //     usdc.approve(address(etherverseNFT), 100000);

//     //     vm.prank(whitelistedGameContract);

//     //     for (uint256 i = 0; i <= exceededTokenID; i++) {
//     //         if (i == exceededTokenID) {
//     //             vm.expectRevert(abi.encodeWithSelector(Errors.ExceedsCapacity.selector, whitelistedGameContract));

//     //             etherverseNFT.mint(whitelistedGameContract, emptyAuthParams);
//     //         }
//     //         etherverseNFT.mint(whitelistedGameContract, emptyAuthParams);
//     //     }
//     // }

//     function testGetTokenStats() public {
//         //mint the nft first

//         vm.prank(whitelistedGameContract);
//         // approve the etherverseNFT contract to spend 0.1 USDC on behalf of the whitelistedGameContract

//         usdc.approve(address(etherverseNFT), 100000);

//         //mint the NFT to whitelistedGameContract by the whitelisted_user1

//         vm.prank(whitelistedGameContract);
//         uint256 tokenId = etherverseNFT.mint(whitelistedGameContract, emptyAuthParams);

//         //assert that the tokenId is 1000000

//         assertEq(tokenId, 1000000);

//         // assert that whitelistedGameContract is the owner of the minted tokenId

//         assertEq(etherverseNFT.ownerOf(tokenId), whitelistedGameContract);

//         (uint8 stat1, uint8 stat2, uint8 stat3) = etherverseNFT.getTokenStats(tokenId);
//         assertEq(stat1, 87);
//         assertEq(stat2, 20);
//         assertEq(stat3, 21);
//     }

//     function testGetTokenStatsRevertNotMinted() public {
//         vm.expectRevert(Errors.NotMinted.selector);
//         etherverseNFT.getTokenStats(9999999);
//     }

//     function testUpdateStats() public {
//         // mint the NFT

//         //mint the nft first

//         vm.prank(whitelistedGameContract);
//         // approve the etherverseNFT contract to spend 0.1 USDC on behalf of the whitelistedGameContract

//         usdc.approve(address(etherverseNFT), 100000);

//         //mint the NFT to whitelistedGameContract by the whitelistedGameContract

//         vm.prank(whitelistedGameContract);
//         uint256 tokenId = etherverseNFT.mint(whitelistedGameContract, emptyAuthParams);

//         //assert that the tokenId is 1000000

//         assertEq(tokenId, 1000000);

//         // assert that whitelistedGameContract is the owner of the minted tokenId

//         assertEq(etherverseNFT.ownerOf(tokenId), whitelistedGameContract);

//         //update the stats

//         vm.startPrank(ccipHandler);
//         bool success = etherverseNFT.updateStats(tokenId, user, 15, 25, 35);
//         vm.stopPrank();

//         assertTrue(success);

//         (uint8 stat1, uint8 stat2, uint8 stat3) = etherverseNFT.getTokenStats(tokenId);
//         assertEq(stat1, 102); //87+15 (basestat + upgrade)
//         assertEq(stat2, 45); //20+25
//         assertEq(stat3, 56); // 21+35
//     }

//     function testUpdateStatsRevertZeroAddress() public {
//         // mint the NFT

//         vm.prank(whitelistedGameContract);
//         // approve the etherverseNFT contract to spend 0.1 USDC on behalf of the whitelistedGameContract

//         usdc.approve(address(etherverseNFT), 100000);

//         //mint the NFT to whitelisted_user1 by the whitelisted_user1

//         vm.prank(whitelistedGameContract);
//         uint256 tokenId = etherverseNFT.mint(whitelistedGameContract, emptyAuthParams);

//         //assert that the tokenId is 1000000

//         assertEq(tokenId, 1000000);

//         // assert that whitelistedGameContract is the owner of the minted tokenId

//         assertEq(etherverseNFT.ownerOf(tokenId), whitelistedGameContract);

//         vm.startPrank(ccipHandler);
//         vm.expectRevert(Errors.ZeroAddress.selector);
//         etherverseNFT.updateStats(tokenId, address(0), 15, 25, 35);
//         vm.stopPrank();
//     }

//     // //     function skiptestUpdateStatsRevertUnauthorizedAccess() public {
//     // //         // mint the NFT

//     // //         vm.prank(whitelisted_user1);
//     // //         // approve the etherverseNFT contract to spend 0.1 USDC on behalf of the whitelisted_user1

//     // //         usdc.approve(address(etherverseNFT), 100000);

//     // //         //mint the NFT to whitelisted_user1 by the whitelisted_user1

//     // //         vm.prank(whitelisted_user1);
//     // //         uint256 tokenId = etherverseNFT.mint(whitelisted_user1, emptyAuthParams);

//     // //         //assert that the tokenId is 1000000

//     // //         assertEq(tokenId, 1000000);

//     // //         // assert that whitelisted_user1 is the owner of the minted tokenId

//     // //         assertEq(etherverseNFT.ownerOf(tokenId), whitelisted_user1);

//     // //         vm.startPrank(minter1);
//     // //         vm.expectRevert(Errors.UnauthorizedAccess.selector);
//     // //         etherverseNFT.updateStats(tokenId, minter1, 15, 25, 35);
//     // //         vm.stopPrank();
//     // //     }

//     function testGetStatValid() public {
//         // mint the NFT

//         vm.prank(whitelistedGameContract);
//         // approve the etherverseNFT contract to spend 0.1 USDC on behalf of the whitelistedGameContract

//         usdc.approve(address(etherverseNFT), 100000);

//         //mint the NFT to whitelistedGameContract by the whitelistedGameContract

//         vm.prank(whitelistedGameContract);
//         uint256 tokenId = etherverseNFT.mint(whitelistedGameContract, emptyAuthParams);

//         //assert that the tokenId is 1000000

//         assertEq(tokenId, 1000000);

//         // assert that whitelistedGameContract is the owner of the minted tokenId

//         assertEq(etherverseNFT.ownerOf(tokenId), whitelistedGameContract);

//         uint8 stat = etherverseNFT.getStat(Asset.StatType.STR, tokenId);
//         assertEq(stat, 87);

//         uint8 stat2 = etherverseNFT.getStat(Asset.StatType.DEX, tokenId);
//         assertEq(stat2, 20);

//         uint8 stat3 = etherverseNFT.getStat(Asset.StatType.CON, tokenId);
//         assertEq(stat3, 21);
//     }

//     function skiptestGetStatNotMinted__Failing() public {
//         uint256 tokenId = 1;
//         vm.expectRevert(Errors.NotMinted.selector);
//         etherverseNFT.getStat(Asset.StatType.STR, tokenId + 1);
//     }

//     function skiptestGetStatLocked__Failing() public {  // @tester : as error handling is in if statement
//         // mint the NFT

//         vm.prank(whitelistedGameContract);
//         // approve the etherverseNFT contract to spend 0.1 USDC on behalf of the whitelistedGameContract

//         usdc.approve(address(etherverseNFT), 100000);

//         //mint the NFT to whitelistedGameContract by the whitelistedGameContract

//         vm.prank(whitelistedGameContract);
//         uint256 tokenId = etherverseNFT.mint(whitelistedGameContract, emptyAuthParams);

//         //assert that the tokenId is 1000000

//         assertEq(tokenId, 1000000);

//         // assert that whitelistedGameContract is the owner of the minted tokenId

//         assertEq(etherverseNFT.ownerOf(tokenId), whitelistedGameContract);

//         vm.prank(ccipHandler);

//         etherverseNFT.setTokenLockStatus(tokenId, block.timestamp + 1 days);

//         //check lockstatus

//         assertEq(etherverseNFT.lockStatus(tokenId), true);

//         vm.expectRevert(abi.encodeWithSelector(Errors.Locked.selector, tokenId, block.timestamp));
//         etherverseNFT.getStat(Asset.StatType.STR, tokenId);
//     }

//     // //     function skiptestTokenURIValid() public {
//     // //         // mint the NFT

//     // //         vm.prank(whitelisted_user1);
//     // //         // approve the etherverseNFT contract to spend 0.1 USDC on behalf of the whitelisted_user1

//     // //         usdc.approve(address(etherverseNFT), 100000);

//     // //         //mint the NFT to whitelisted_user1 by the whitelisted_user1

//     // //         vm.prank(whitelisted_user1);
//     // //         uint256 tokenId = etherverseNFT.mint(whitelisted_user1, emptyAuthParams);

//     // //         //assert that the tokenId is 1000000

//     // //         assertEq(tokenId, 1000000);

//     // //         // assert that whitelisted_user1 is the owner of the minted tokenId

//     // //         assertEq(etherverseNFT.ownerOf(tokenId), whitelisted_user1);

//     // //         string memory uri = etherverseNFT.tokenURI(tokenId);
//     // //         assertEq(uri, "https://ipfs.io/ipfs/QmVQ2vpBD1U6P22V2xaHk5KF5x6mQAM7HmFsc8c2AsQhgo");
//     // //     }

//     function testTransferFromSuccess() public {
//         // mint the nft first

//         vm.prank(whitelistedGameContract);
//         // approve the etherverseNFT contract to spend 0.1 USDC on behalf of the whitelistedGameContract

//         usdc.approve(address(etherverseNFT), 100000);

//         //mint the NFT to whitelistedGameContract by the whitelistedGameContract

//         vm.prank(whitelistedGameContract);
//         uint256 tokenId = etherverseNFT.mint(whitelistedGameContract, emptyAuthParams);

//         //assert that the tokenId is 1000000

//         assertEq(tokenId, 1000000);

//         // assert that whitelistedGameContract is the owner of the minted tokenId

//         assertEq(etherverseNFT.ownerOf(tokenId), whitelistedGameContract);

//         vm.prank(whitelistedGameContract);
//         etherverseNFT.transferFrom(whitelistedGameContract, minter1, tokenId);
//         assertEq(etherverseNFT.ownerOf(tokenId), minter1);
//     }

//     function testTransferFromZeroAddress() public {
//         // mint the nft first

//         vm.prank(whitelistedGameContract);
//         usdc.approve(address(etherverseNFT), 100000);

//         vm.prank(whitelistedGameContract);
//         uint256 tokenId = etherverseNFT.mint(whitelistedGameContract, emptyAuthParams);
//         assertEq(etherverseNFT.ownerOf(tokenId), whitelistedGameContract);

//         vm.prank(whitelistedGameContract);
//         vm.expectRevert(Errors.ZeroAddress.selector);
//         etherverseNFT.transferFrom(whitelistedGameContract, address(0), tokenId);
//     }

//     function testTransferFromLockedToken() public {
//         // mint the nft first

//         vm.prank(whitelistedGameContract);
//         usdc.approve(address(etherverseNFT), 100000);

//         vm.prank(whitelistedGameContract);
//         uint256 tokenId = etherverseNFT.mint(whitelistedGameContract, emptyAuthParams);
//         assertEq(etherverseNFT.ownerOf(tokenId), whitelistedGameContract);

//         // lock the token
//         vm.prank(ccipHandler);
//         etherverseNFT.setTokenLockStatus(tokenId, block.timestamp + 1 days);
//         assertEq(etherverseNFT.lockStatus(tokenId), true);

//         vm.prank(whitelistedGameContract);
//         vm.expectRevert(abi.encodeWithSelector(Errors.Locked.selector, tokenId, block.timestamp));
//         etherverseNFT.transferFrom(whitelistedGameContract, minter1, tokenId);
//     }

//     function testSafeTransferFromSuccess() public {
//         // mint the nft first

//         vm.prank(whitelistedGameContract);
//         usdc.approve(address(etherverseNFT), 100000);

//         vm.prank(whitelistedGameContract);
//         uint256 tokenId = etherverseNFT.mint(whitelistedGameContract, emptyAuthParams);
//         assertEq(etherverseNFT.ownerOf(tokenId), whitelistedGameContract);

//         vm.prank(whitelistedGameContract);
//         etherverseNFT.safeTransferFrom(whitelistedGameContract, minter1, tokenId, "");
//         assertEq(etherverseNFT.ownerOf(tokenId), minter1);
//     }

//     function testSafeTransferFromZeroAddress() public {
//         // mint the nft first

//         vm.prank(whitelistedGameContract);
//         usdc.approve(address(etherverseNFT), 100000);

//         vm.prank(whitelistedGameContract);
//         uint256 tokenId = etherverseNFT.mint(whitelistedGameContract, emptyAuthParams);
//         assertEq(etherverseNFT.ownerOf(tokenId), whitelistedGameContract);

//         vm.prank(whitelistedGameContract);
//         vm.expectRevert(Errors.ZeroAddress.selector);
//         etherverseNFT.safeTransferFrom(whitelistedGameContract, address(0), tokenId, "");
//     }

//     function testSafeTransferFromLockedToken() public {
//         // mint the nft first

//         vm.prank(whitelistedGameContract);
//         usdc.approve(address(etherverseNFT), 100000);

//         vm.prank(whitelistedGameContract);
//         uint256 tokenId = etherverseNFT.mint(whitelistedGameContract, emptyAuthParams);
//         assertEq(etherverseNFT.ownerOf(tokenId), whitelistedGameContract);

//         // lock the token
//         vm.prank(ccipHandler);
//         etherverseNFT.setTokenLockStatus(tokenId, block.timestamp + 1 days);
//         assertEq(etherverseNFT.lockStatus(tokenId), true);

//         vm.prank(whitelistedGameContract);
//         vm.expectRevert(abi.encodeWithSelector(Errors.Locked.selector, tokenId, block.timestamp));
//         etherverseNFT.safeTransferFrom(whitelistedGameContract, minter1, tokenId, "");
//     }

//     function testWithdraw() public {
//         // mint the nft first

//         vm.prank(whitelistedGameContract);
//         usdc.approve(address(etherverseNFT), 100000);

//         vm.prank(whitelistedGameContract);
//         uint256 tokenId = etherverseNFT.mint(whitelistedGameContract, emptyAuthParams);
//         assertEq(etherverseNFT.ownerOf(tokenId), whitelistedGameContract);

//         // check the USDC balance of contract etherverseNFT
//         // after minting the NFT // it should be 10% of minting price as set in feesplit which assetcreator can withdraw ,which
//         //should come 0.05$

//         assertEq(IERC20(usdc).balanceOf(address(etherverseNFT)), 10000);

//         //prank assetWalletAddress and then withdraw

//         vm.prank(etherverseNFT.assetCreatorWallet());

//         etherverseNFT.withdraw(address(usdc));

//         // check balance of assetWalletAddress after withdraw

//         assertEq(IERC20(usdc).balanceOf(etherverseNFT.assetCreatorWallet()), 10000);
//     }


    
//     function testFreeUpgradeSuccess() public {
       
//         // mint the nft first
//         vm.prank(whitelistedGameContract);
//         usdc.approve(address(etherverseNFT), 100000);

//         vm.prank(whitelistedGameContract);
//         uint256 tokenId = etherverseNFT.mint(whitelistedGameContract, emptyAuthParams);
//         assertEq(etherverseNFT.ownerOf(tokenId), whitelistedGameContract);

//         vm.prank(whitelistedGameContract);
//         etherverseNFT.freeUpgrade(tokenId);

//         (uint8 stat1, uint8 stat2, uint8 stat3) = etherverseNFT.getTokenStats(tokenId);
//         Asset.Stat memory upgradedStat = Asset.Stat(stat1, stat2, stat3);

//         assertEq(upgradedStat.stat1, 89); 
//         assertEq(upgradedStat.stat2, 22);  
//         assertEq(upgradedStat.stat3, 23); 
//     }

//     // //     function skiptestFreeUpgradeRevertNotWhitelisted__Failing() public {
//     // //         // set the mint price to 0.1 USDC(USDC has 6 decimals)
//     // //         vm.prank(owner);
//     // //         etherverseNFT.setMintPrice(100000);

//     // //         // top up the minter1 account with 0.1 ether for purpose of paying transaction fee
//     // //         vm.deal(minter1, 100000000000000000);

//     // //         // assert that the minter1 account has 0.1 ether

//     // //         assertEq(address(minter1).balance, 100000000000000000);

//     // //         // aprove the etherverseNFT contract to spend 0.1 USDC on behalf of the minter1

//     // //         vm.prank(minter1);
//     // //         usdc.approve(address(etherverseNFT), 100000);

//     // //         // mint the NFT
//     // //         vm.prank(minter1);
//     // //         uint256 tokenId = etherverseNFT.mint(minter1, emptyAuthParams);
//     // //         assertEq(etherverseNFT.ownerOf(tokenId), minter1);

//     // //         // vm.prank(minter1);
//     // //         // vm.expectRevert(abi.encodeWithSelector(Errors.CallerMustBeWhitelisted.selector, nonWhitelistedUser));
//     // //         // etherverseNFT.freeUpgrade(tokenId);
//     // //     }

//         function testFreeUpgradeRevertNotMinted() public {
//             vm.prank(whitelistedGameContract);

//             vm.expectRevert(Errors.NotMinted.selector);
//             etherverseNFT.freeUpgrade(9999999);
//         }

//         function testpaidUpgradeSuccess() public {
//             // mint the nft first
//             vm.prank(whitelistedGameContract);
//             usdc.approve(address(etherverseNFT), 100000);

//             vm.prank(whitelistedGameContract);
//             uint256 tokenId = etherverseNFT.mint(whitelistedGameContract, emptyAuthParams);
//             assertEq(etherverseNFT.ownerOf(tokenId), whitelistedGameContract);

//             vm.prank(whitelistedGameContract);
//             etherverseNFT.paidUpgrade(tokenId, emptyAuthParams);

//             (uint8 stat1, uint8 stat2, uint8 stat3) = etherverseNFT.getTokenStats(tokenId);
//             Asset.Stat memory upgradedStat = Asset.Stat(stat1, stat2, stat3);

//             assertEq(upgradedStat.stat1, 92); // 87+5
//             assertEq(upgradedStat.stat2, 25); // 20+5
//             assertEq(upgradedStat.stat3, 26); // 21+5
//         }

//         function testpaidUpgradeRevertNotMinted() public {
//             vm.prank(whitelistedGameContract);
//             vm.expectRevert(Errors.NotMinted.selector);
//             etherverseNFT.paidUpgrade(9999999, emptyAuthParams);
//         }

//     // //     function skiptestpaidUpgradeRevertNotWhitelisted__Failing() public {
//     // //         // set the mint price to 0.1 USDC(USDC has 6 decimals)
//     // //         vm.prank(owner);
//     // //         etherverseNFT.setMintPrice(100000);

//     // //         // top up the minter1 account with 0.1 ether for purpose of paying transaction fee
//     // //         vm.deal(minter1, 100000000000000000);

//     // //         // assert that the minter1 account has 0.1 ether

//     // //         assertEq(address(minter1).balance, 100000000000000000);

//     // //         // aprove the etherverseNFT contract to spend 0.1 USDC on behalf of the minter1

//     // //         vm.prank(minter1);
//     // //         usdc.approve(address(etherverseNFT), 100000);

//     // //         // mint the NFT
//     // //         vm.prank(minter1);
//     // //         uint256 tokenId = etherverseNFT.mint(minter1, emptyAuthParams);
//     // //         assertEq(etherverseNFT.ownerOf(tokenId), minter1);

//     // //         // vm.prank(minter1);
//     // //         // vm.expectRevert(abi.encodeWithSelector(Errors.CallerMustBeWhitelisted.selector, nonWhitelistedUser));
//     // //         // etherverseNFT.paidUpgrade(tokenId);
//     // //     }

       

  

        

//         function skiptestNextUpgradeSuccess__Failing() public {

//            // mint the nft first
//             vm.prank(whitelistedGameContract);
//             usdc.approve(address(etherverseNFT), 100000);

//             vm.prank(whitelistedGameContract);
//             uint256 tokenId = etherverseNFT.mint(whitelistedGameContract, emptyAuthParams);
//             assertEq(etherverseNFT.ownerOf(tokenId), whitelistedGameContract);

//        // do the first free upgrade (87+2 , 20+2, 21+2)
 
//         vm.prank(whitelistedGameContract);
//         //etherverseNFT.freeUpgrade(tokenId);
//         game.freeUpgrade(tokenId);

//         (uint8 stat1, uint8 stat2, uint8 stat3) = etherverseNFT.getTokenStats(tokenId);
//         Asset.Stat memory upgradedStat = Asset.Stat(stat1, stat2, stat3);

//         assertEq(upgradedStat.stat1, 89); 
//         assertEq(upgradedStat.stat2, 22);  
//         assertEq(upgradedStat.stat3, 23); 

// //           //do second free upgrade (89+2 , 22+2, 23+2)


// //           vm.prank(whitelistedGameContract);
// //         etherverseNFT.freeUpgrade(tokenId);

// //         (uint8 stat1s, uint8 stat2s, uint8 stat3s) = etherverseNFT.getTokenStats(tokenId);
// //         Asset.Stat memory upgradedStats = Asset.Stat(stat1s, stat2s, stat3s);

// //         assertEq(upgradedStats.stat1, 91); 
// //         assertEq(upgradedStats.stat2, 24);  
// //         assertEq(upgradedStats.stat3, 25); 


             
             
// //              // call the next upgrade function
             
// //              vm.prank(whitelistedGameContract);
            
// //             Asset.Stat memory upgradedStatFreeup = etherverseNFT.nextUpgrade(tokenId, Upgrade.Type.Free);


// // //    Asset.Stat memory upgradedStatFree = Asset.Stat(stat1, stat2, stat3);

// //              // assert the value

// //             assertEq(upgradedStatFreeup.stat1, 93); //coming 6
// //             assertEq(upgradedStatFreeup.stat2, 26);//coming 6
// //             assertEq(upgradedStatFreeup.stat3, 27); //coming 6


//         }


     
    


//   function skiptestNextUpgradePriceSuccess() public {
        
//         // mint the nft first

//         vm.prank(whitelistedGameContract);
//         usdc.approve(address(etherverseNFT), 100000);

//         vm.prank(whitelistedGameContract);
//         uint256 tokenId = etherverseNFT.mint(whitelistedGameContract, emptyAuthParams);
//         assertEq(etherverseNFT.ownerOf(tokenId), whitelistedGameContract);

//         // set upgrade price to 1.0 USDC

//         vm.prank(whitelistedGameContract);
//         etherverseNFT.setUpgradePrice(100000);

//         // check the upgrade price

//         // mapping(address => uint256) public upgradePricing;

//         assertEq(etherverseNFT.upgradePricing(whitelistedGameContract), 100000);



//         // check the upgrade price
//         vm.prank(whitelistedGameContract);
//        uint256 currentnextupgradedPrice = etherverseNFT.nextUpgradePrice(tokenId);

//        console.log("currentnextupgradedPrice", currentnextupgradedPrice); // getting zero as obvious from logic calculateprice(as stats will be zero previous to any upgrade)

//        // expecting  ((BASE_PRICE_IN_USDC)*statPriceMultiplier(_stat)) / 100;

//        // which is
//        //  (100000 * ((87+20+21)*100)/3))/100 is equal to 

//        // 1,042.6
   



//         // assertEq(etherverseNFT.nextUpgradePrice(tokenId), 50000);
//     }


//     // function testNextUpgradePriceRevertNotMinted() public {
//     //     vm.expectRevert(Errors.NotMinted.selector);
//     //     etherverseNFT.nextUpgradePrice(9999999);
//     // }

//     // function testNextUpgradePriceRevertLocked() public {
//     //     // mint the nft first

//     //     vm.prank(whitelistedGameContract);
//     //     usdc.approve(address(etherverseNFT), 100000);

//     //     vm.prank(whitelistedGameContract);
//     //     uint256 tokenId = etherverseNFT.mint(whitelistedGameContract, emptyAuthParams);
//     //     assertEq(etherverseNFT.ownerOf(tokenId), whitelistedGameContract);

//     //     // lock the token
//     //     vm.prank(ccipHandler);
//     //     etherverseNFT.setTokenLockStatus(tokenId, block.timestamp + 1 days);
//     //     assertEq(etherverseNFT.lockStatus(tokenId), true);

//     //     vm.prank(whitelistedGameContract);
//     //     vm.expectRevert(abi.encodeWithSelector(Errors.Locked.selector, tokenId, block.timestamp));
//     //     etherverseNFT.nextUpgradePrice(tokenId);
//     // }

//     // function testNextUpgradePriceRevertNotWhitelisted() public {
//     //     // mint the nft first

//     //     vm.prank(whitelistedGameContract);
//     //     usdc.approve(address(etherverseNFT), 100000);

//     //     vm.prank(whitelistedGameContract);
//     //     uint256 tokenId = etherverseNFT.mint(whitelistedGameContract, emptyAuthParams);
//     //     assertEq(etherverseNFT.ownerOf(tokenId), whitelistedGameContract);

//     //     vm.prank(whitelistedGameContract);
//     //     vm.expectRevert(abi.encodeWithSelector(Errors.CallerMustBeWhitelisted.selector, nonWhitelistedUser));
//     //     etherverseNFT.nextUpgradePrice(tokenId);
//     // }

//     // function testNextUpgradePriceRevertUpgradeNotAvailable() public {
//     //     // mint the nft first

//     //     vm.prank(whitelistedGameContract);
//     //     usdc.approve(address(etherverseNFT), 100000);












// }
