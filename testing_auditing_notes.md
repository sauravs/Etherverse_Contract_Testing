
Commit ID : https://github.com/PrideVelConsulting/GameX-Contracts/commit/04817b60c22602968f3368aea57e5653f2da4be5

Main Files To Test And Audit:

RPG.sol 
ImageV1.sol
Fee.sol
RPGUtil.sol

RPGStruct.sol
errors.sol
IRPG.sol
IUpgradeV1.sol


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

RPG.sol : mint isWhitelisted()

// @dev Any function with this modifier can only be called by a whitelisted marketplace contract
    modifier isWhitelisted(address _address) {
        if (!whitelisted[_address])
            revert Errors.CallerMustBeWhitelisted(_address);
        _;
    }

    Q: so mint should only be called by contract?
///////////////////////////////////////////////////

   Issues:

   function freeUpgrade(uint256 tokenId) : 

   same for paidUpgrade() and resetUpgrades()

/@tester: if token minted check is here,then their is no need of isWhitelisted modifier,because only whitelisted user can mint 

//@tester: if token is minted


difference between free and paid upgrade is +2 and +5?


////////////////////////////////////////////////////////////

Game.sol while minting NFT ->
ERC721InvalidReceiver

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract GameTest is IERC721Receiver {
    // Implement the onERC721Received function
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        // Return the selector to confirm the token transfer
        return this.onERC721Received.selector;
    }
}
































    



