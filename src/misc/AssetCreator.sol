//SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";          //@audit imported safeerc20 but where it is being used?
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol"; //@audit imported safeerc20 but where it is being used?
import "../common/EtherverseUser.sol";

contract AssetCreator is EtherverseUser {
    constructor(
        address _etherverse,  // web3tech fee collector waller(eoa)
        address _user,        
        address _userWallet,
        address initialOwner,
        uint256 _etherverseFee
    )
        EtherverseUser(
            _etherverse,
            _user,
            _userWallet,
            _etherverseFee,
            initialOwner
        )
    {}
}


// Step-1 :First entry point : will deploy AssetCreator.sol first(only if it is not already deployed)

// Step-2 : Now deploy EtherverseNFT 