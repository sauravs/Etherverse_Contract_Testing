//SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../common/Etherverse.sol";

contract AssetCreator is EtherverseUser {
    constructor(address _etherverse, address _owner, uint256 _etherverseFee)
        EtherverseUser(_etherverse, _owner, _etherverseFee)
    {}
}
