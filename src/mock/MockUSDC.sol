// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
//import "../src/common/interface/IUSDC.sol";

contract MockUSDC is ERC20 {
    constructor() ERC20("Mock USDC", "USDC") {}

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}



// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// contract RoboToken is ERC20 {
//     constructor() ERC20("Robo Token", "RS") {
//         _mint(msg.sender, 10000 * 10 ** decimals());
//     }

//     function decimals() public view virtual override returns (uint8) {
//         return 6;
//     }
// }