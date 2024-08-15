// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {AssetCreator} from "./misc/AssetCreator.sol";
import {EtherverseUser} from "./common/EtherverseUser.sol";
import {Game} from "./misc/Game.sol";

// import {EtherverseNFT} from "./nft/EtherverseNFT.sol";

contract creationCodeGenerator {
    constructor() {}

    function assetCreator(
        address _etherverse,
        address _user,
        address _userWallet,
        address initalOwner,
        uint256 _etherverseFee
    ) public pure returns (bytes memory) {
        bytes memory code = abi.encodePacked(
            type(AssetCreator).creationCode,
            abi.encode(
                _etherverse,
                _user,
                _userWallet,
                initalOwner,
                _etherverseFee
            )
        );
        return code;
    }

    function etherverseUser(
        address _etherverse,
        address _user,
        address _userWallet,
        uint256 _fee,
        address initalOwner
    ) public pure returns (bytes memory) {
        bytes memory code = abi.encodePacked(
            type(EtherverseUser).creationCode,
            abi.encode(_etherverse, _user, _userWallet, _fee, initalOwner)
        );
        return code;
    }

    function game(
        address _etherverse,
        address _user,
        address _userWallet,
        address _usdcToken,
        address _upgrade,
        address initalOwner,
        uint256 _marketFee,
        uint256 _etherverseFee,
        string memory _name
    ) public pure returns (bytes memory) {
        bytes memory code = abi.encodePacked(
            type(Game).creationCode,
            abi.encode(
                _etherverse,
                _user,
                _userWallet,
                _usdcToken,
                _upgrade,
                initalOwner,
                _marketFee,
                _etherverseFee,
                _name
            )
        );
        return code;
    }

    // function EtherverseNFTContract() public pure returns (bytes memory) {
    //     bytes memory code = abi.encodePacked(type(EtherverseNFT).creationCode);
    //     return code;
    // }
}
