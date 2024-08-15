// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.24;

// import "forge-std/Test.sol";
// import "../src/misc/Game.sol";
// import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
// import "../src/nft/helpers/UpgradeV1.sol";

// contract GameTest is Test, IERC721Receiver {
//     Game game;
//     address etherverse = address(0x0C903F1C518724CBF9D00b18C2Db5341fF68269C);
//     address owner_web3tech = address(0x7);
//     address usdcToken = address(0x2a9e8fa175F45b235efDdD97d2727741EF4Eee63);
//     address public upgradeV1ContractAddress;
//     uint256 marketFee = 4269;
//     uint256 etherverseFee = 900;
//     string name = "GTA";
//     address public gameContractdeployedAddress;

//     function setUp() public {
//         // deploy UpgradeV1.sol

//         UpgradeV1 upgradeV1 = new UpgradeV1();
//         console.log("UpgradeV1 address: ", address(upgradeV1));

//         upgradeV1ContractAddress = address(upgradeV1);

//         //0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f

//         game = new Game(etherverse, owner_web3tech, usdcToken, address(upgradeV1), marketFee, etherverseFee, name);
//         //console.log("Game contract address: ", address(game));
//         //0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f'

//         gameContractdeployedAddress = address(game);

//         console.log("Game contract address: ", gameContractdeployedAddress);
//     }

//     function testConstructorParameters() public {
//         assertEq(game.name(), name);
//         assertEq(address(game.USDC()), usdcToken);
//         assertEq(game.marketFee(), marketFee);
//         assertEq(game.upgradeAddress(), upgradeV1ContractAddress);
//     }

//     // Implement the onERC721Received function
//     function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
//         external
//         override
//         returns (bytes4)
//     {
//         // Return the selector to confirm the token transfer
//         return this.onERC721Received.selector;
//     }
// }
