// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import "../src/misc/Game.sol"; 
contract GameTest is Test {
    Game game;
    address etherverse = address(0x0C903F1C518724CBF9D00b18C2Db5341fF68269C);
    address owner = address(0x7);
    address usdcToken = address(0x2a9e8fa175F45b235efDdD97d2727741EF4Eee63);
    address upgrade = address(0xFEfC6BAF87cF3684058D62Da40Ff3A795946Ab06);
    uint256 marketFee = 4269;
    uint256 etherverseFee = 900;
    string name = "GTA";
    address public gameContractdeployedAddress;

    function setUp() public {
        game = new Game(etherverse, owner, usdcToken, upgrade, marketFee, etherverseFee, name);
        //console.log("Game contract address: ", address(game));
        //0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f'

        gameContractdeployedAddress = address(game);

        console.log("Game contract address: ", gameContractdeployedAddress);
    }

    function testConstructorParameters() public {
        assertEq(game.name(), name);
        assertEq(address(game.USDC()), usdcToken);
        assertEq(game.marketFee(), marketFee);
        assertEq(game.upgradeAddress(), upgrade);
    }

}