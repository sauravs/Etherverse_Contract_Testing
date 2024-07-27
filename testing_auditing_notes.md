
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
























    



