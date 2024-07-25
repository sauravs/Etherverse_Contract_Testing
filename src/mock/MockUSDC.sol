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

// pragma solidity ^0.8.20;

// import "forge-std/Test.sol";
// import "../contracts/MockUSDC.sol";

// contract RPGItemNFTTest is Test {
//     MockUSDC public usdc;
//     address public whitelisted_user1 = address(0x3);

//     function setUp() public {
//         // Deploy Mock USDC token
//         usdc = new MockUSDC();

//         // Mint 100 USDC to whitelisted_user1
//         uint256 amount = 100 * 10**6; // 100 USDC with 6 decimals
//         usdc.mint(whitelisted_user1, amount);
//     }

//     function testBalanceOfWhitelistedUser1() public {
//         uint256 balance = usdc.balanceOf(whitelisted_user1);
//         assertEq(balance, 100 * 10**6); // Check if the balance is 100 USDC
//     }
// }
