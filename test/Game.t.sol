// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import "../src/misc/Game.sol";
import "../src/nft/helpers/Upgrades/UpgradeV1.sol";
import "../src/common/EtherverseUser.sol";
import {EtherverseNFT} from "../src/nft/main/template/EtherverseNFT.sol"; 
import "../src/mock/MockUSDC.sol";



//import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";


//forge test --match-path test/Game.t.sol -vvv

contract GameTest is Test {
    Game game;
    EtherverseNFT public etherverseNFT;
    address public initialAssetCreatorOwner = 0x762aD31Ff4bD1ceb5b3b5868672d5CBEaEf609dF;

    address public etherverse = address(0x0C903F1C518724CBF9D00b18C2Db5341fF68269C); //external wallet fee collector address which will be pridevel wallet
    address gameDeveloperWalletAddress = address(0x7);
    address gameDeveloperFeeCollectorWallet = address(0x8);
    address gameDeveloperInitialOwner = address(0x10);
    address web3techInitialOwner = address(0x9);
    address nonOwner = address(0x11);
    address public minter1 = address(0x5);
    address public minter2 = address(0x6);
    address public nftSeller1 = address(0x12);
    address public nftSeller2 = address(0x13);

    address public whitelistedGameContract;


    uint256 public marketFee = 4269; // what commission does the game take which  ingame fees collected by game developer // eg  42.69% 4269
    uint256 public etherverseFee = 900; // web3tech platform fee // 9% 900
    string public gamename = "GTA"; // name of the game
    address public mockUSDCAddress;
    address public upgradeV1Address;
        
    MockUSDC public usdc;
    EtherverseUser public etherverseUser;



    function setUp() public {
        
        
        
          // Deploy Mock USDC token
        usdc = new MockUSDC();
        //console.log("USDC address: ", address(usdc));
        //USDC address:  0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f
        mockUSDCAddress = address(usdc);
        
        
        
        // deploy UpgradeV1.sol

        UpgradeV1 upgradeV1 = new UpgradeV1();
        upgradeV1Address = address(upgradeV1);
        //console.log("UpgradeV1 address: ", address(upgradeV1));
        //UpgradeV1 address: 0x2e234DAe75C793f67A35089C9d99245E1C58470b
        

            // deploy Game.sol

         game = new Game(etherverse, gameDeveloperWalletAddress,gameDeveloperFeeCollectorWallet,mockUSDCAddress,address(upgradeV1),web3techInitialOwner,marketFee,etherverseFee,gamename);
         //console.log("Game contract address: ", address(game));
        //Game contract address:  0xF62849F9A0B5Bf2913b396098F7c7019b51A820a

        whitelistedGameContract = address(game);



         // Deploy EtherverseNFT.sol
        etherverseNFT = new EtherverseNFT("EtherverseSWORD", "EVR", initialAssetCreatorOwner);
        //console.log("EtherverseNFT address: ", address(etherverseNFT)); 
       // EtherverseNFT address:  0x08526067985167EcFcB1F9720C72DbBF36c96018



    }

    function testConstructorParameters() public {
        assertEq(game.name(), gamename);
        assertEq(address(game.USDC()), mockUSDCAddress);
        assertEq(game.marketFee(), marketFee);
        assertEq(game.upgradeAddress(), upgradeV1Address);
    }



        function testSetMarketFee() public {
        vm.prank(web3techInitialOwner);
        game.setMarketFee(500); // 5%
        assertEq(game.marketFee(), 500);
    }

    function testSetMarketFeeRevert() public {
        vm.prank(web3techInitialOwner);
        vm.expectRevert("Market fee must be less than 100%");
        game.setMarketFee(11000); // 110%
    }


    function testSetMarketFeeRevertNonOwner() public {
        vm.prank(nonOwner);
        vm.expectRevert("Unauthorized Access");
        game.setMarketFee(500); // 5%
    }


    
    function testCreateOrder() public {

    
     // set the whitelistedGameContract as whitelisted

         vm.prank(initialAssetCreatorOwner);
         etherverseNFT.setWhitelisted(whitelistedGameContract, true);

        //assert that the whitelistedGameContract is whitelisted
        assertTrue(etherverseNFT.whitelisted(whitelistedGameContract));
    
    
      //assert that mint price is set to 0.1 USDC
        (uint256 amount, uint256 split) = etherverseNFT.mintPricing();
        assertEq(amount, 100000);
        assertEq(split, 1000);
       
       
      // assert that the whitelistedGameContract account has usdc funds to pay for fee,should be greater than 100usdc as set it up on setup

              // 1000 USDC with 6 decimals
          
        uint256 usdcAmount = 100000 * 10 ** 6;

         usdc.mint(whitelistedGameContract, usdcAmount);
      
          // assert that the whitelisted_user1 account has 100000 USDC
            
        assertEq(usdc.balanceOf(whitelistedGameContract), usdcAmount);


         // aprove the etherverseNFT contract to spend 0.1 USDC on behalf of the whitelistedGameContract

        vm.prank(whitelistedGameContract);
        usdc.approve(address(etherverseNFT), 100000);
    
     
        // mint the NFT whitelistedGameContract
        bytes memory authorizationParams = "";
        vm.prank(whitelistedGameContract);
        uint256 tokenId = etherverseNFT.mint(whitelistedGameContract, authorizationParams);
        assertEq(tokenId, 1000000);
       assertEq(etherverseNFT.ownerOf(tokenId), whitelistedGameContract);

       // transfer the minted NFT to the nftSeller1

        vm.prank(whitelistedGameContract);
        etherverseNFT.transferFrom(whitelistedGameContract, nftSeller1, tokenId);
        assertEq(etherverseNFT.ownerOf(tokenId), nftSeller1);


   
        // vm.prank(nftSeller1);
        // game.createOrder(address(nft), 1, 1000);

        // Game.Order memory order = game.getOrder(0);
        // assertEq(order.nft, address(nft));
        // assertEq(order.tokenId, 1);
        // assertEq(order.price, 900); // 1000 - 10% fee
        // assertEq(order.fee, 100);   // 10% fee
        // assertEq(order.totalPrice, 1000);
        // assertEq(order.orderCompleted, 0);
    }

    // function testCreateOrderRevert() public {
    //     vm.prank(user);
    //     vm.expectRevert("Invalid Address");
    //     game.createOrder(address(0), 1, 1000);

    //     nft.mint(user, 1);
    //     vm.prank(user);
    //     vm.expectRevert("Contract not approved to transfer NFT");
    //     game.createOrder(address(nft), 1, 1000);
    // }


    // Implement the onERC721Received function
    // function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
    //     external
    //     override
    //     returns (bytes4)
    // {
    //     // Return the selector to confirm the token transfer
    //     return this.onERC721Received.selector;
    // }
}
