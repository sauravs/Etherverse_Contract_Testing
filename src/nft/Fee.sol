// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "../common/interface/IUSDC.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

library Fee {
    using SafeERC20 for IUSDC;

    function receiveUSDC(
        address from,
        uint256 value,
        address token,
        bytes memory authorizationParams
    ) internal {
        IUSDC USDCToken = IUSDC(token);
        require(USDCToken.balanceOf(from) >= value, "Insufficient balance");

        if (
            authorizationParams.length == 0 ||
            keccak256(authorizationParams) == keccak256("")
        ) {
            USDCToken.transferFrom(from, address(this), value);
        } else {
            (
                uint256 validAfter,
                uint256 validBefore,
                bytes32 nonce,
                bytes memory signature
            ) = abi.decode(
                    authorizationParams,
                    (uint256, uint256, bytes32, bytes)
                );

            USDCToken.receiveWithAuthorization(
                from,
                address(this),
                value,
                validAfter,
                validBefore,
                nonce,
                signature
            );
        }
        // Game developer's commission 50%
        USDCToken.transfer(msg.sender, (value * 50) / 100);
    }

    function withdraw(
        address assetCreator,
        address token
    ) public {
        if (token == address(0)) {
            payable(assetCreator).transfer(address(this).balance);
        } else {
            IUSDC USDCToken = IUSDC(token);
            // uint256 amount = USDCToken.balanceOf(address(this));
            // USDCToken.safeTransfer(etherverse, (amount * 45) / 1000);
            uint256 balance = USDCToken.balanceOf(address(this));
            USDCToken.safeTransfer(assetCreator, balance);
        }
    }
}
