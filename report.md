# Aderyn Analysis Report

This report was generated by [Aderyn](https://github.com/Cyfrin/aderyn), a static analysis tool built by [Cyfrin](https://cyfrin.io), a blockchain security company. This report is not a substitute for manual audit or security review. It should not be relied upon for any purpose other than to assist in the identification of potential security vulnerabilities.
# Table of Contents

- [Summary](#summary)
  - [Files Summary](#files-summary)
  - [Files Details](#files-details)
  - [Issue Summary](#issue-summary)
- [High Issues](#high-issues)
  - [H-1: `abi.encodePacked()` should not be used with dynamic types when passing the result to a hash function such as `keccak256()`](#h-1-abiencodepacked-should-not-be-used-with-dynamic-types-when-passing-the-result-to-a-hash-function-such-as-keccak256)
  - [H-2: Arbitrary `from` passed to `transferFrom` (or `safeTransferFrom`)](#h-2-arbitrary-from-passed-to-transferfrom-or-safetransferfrom)
  - [H-3: Uninitialized State Variables](#h-3-uninitialized-state-variables)
  - [H-4: Sending native Eth is not protected from these functions.](#h-4-sending-native-eth-is-not-protected-from-these-functions)
  - [H-5: Tautology or Contradiction in comparison.](#h-5-tautology-or-contradiction-in-comparison)
- [Low Issues](#low-issues)
  - [L-1: Centralization Risk for trusted owners](#l-1-centralization-risk-for-trusted-owners)
  - [L-2: Unsafe ERC20 Operations should not be used](#l-2-unsafe-erc20-operations-should-not-be-used)
  - [L-3: Solidity pragma should be specific, not wide](#l-3-solidity-pragma-should-be-specific-not-wide)
  - [L-4: Missing checks for `address(0)` when assigning values to address state variables](#l-4-missing-checks-for-address0-when-assigning-values-to-address-state-variables)
  - [L-5: `public` functions not used internally could be marked `external`](#l-5-public-functions-not-used-internally-could-be-marked-external)
  - [L-6: Define and use `constant` variables instead of using literals](#l-6-define-and-use-constant-variables-instead-of-using-literals)
  - [L-7: Event is missing `indexed` fields](#l-7-event-is-missing-indexed-fields)
  - [L-8: The `nonReentrant` `modifier` should occur before all other modifiers](#l-8-the-nonreentrant-modifier-should-occur-before-all-other-modifiers)
  - [L-9: PUSH0 is not supported by all chains](#l-9-push0-is-not-supported-by-all-chains)
  - [L-10: Large literal values multiples of 10000 can be replaced with scientific notation](#l-10-large-literal-values-multiples-of-10000-can-be-replaced-with-scientific-notation)
  - [L-11: Internal functions called only once can be inlined](#l-11-internal-functions-called-only-once-can-be-inlined)
  - [L-12: Contract still has TODOs](#l-12-contract-still-has-todos)


# Summary

## Files Summary

| Key | Value |
| --- | --- |
| .sol Files | 10 |
| Total nSLOC | 1090 |


## Files Details

| Filepath | nSLOC |
| --- | --- |
| src/common/EtherverseUser.sol | 102 |
| src/common/interface/IUSDC.sol | 13 |
| src/misc/AssetCreator.sol | 21 |
| src/misc/Game.sol | 164 |
| src/mock/MockUSDC.sol | 8 |
| src/nft/EtherverseNFT.sol | 325 |
| src/nft/helpers/FrameV1.sol | 291 |
| src/nft/helpers/UpgradeV1.sol | 64 |
| src/nft/interface/IEtherverseNFT.sol | 81 |
| src/nft/interface/IUpgradeV1.sol | 21 |
| **Total** | **1090** |


## Issue Summary

| Category | No. of Issues |
| --- | --- |
| High | 5 |
| Low | 12 |


# High Issues

## H-1: `abi.encodePacked()` should not be used with dynamic types when passing the result to a hash function such as `keccak256()`

Use `abi.encode()` instead which will pad items to 32 bytes, which will [prevent hash collisions](https://docs.soliditylang.org/en/v0.8.13/abi-spec.html#non-standard-packed-mode) (e.g. `abi.encodePacked(0x123,0x456)` => `0x123456` => `abi.encodePacked(0x1,0x23456)`, but `abi.encode(0x123,0x456)` => `0x0...1230...456`). Unless there is a compelling reason, `abi.encode` should be preferred. If there is only one argument to `abi.encodePacked()` it can often be cast to `bytes()` or `bytes32()` [instead](https://ethereum.stackexchange.com/questions/30912/how-to-compare-strings-in-solidity#answer-82739).
If all arguments are strings and or bytes, `bytes.concat()` should be used instead.

<details><summary>12 Found Instances</summary>


- Found in src/nft/helpers/FrameV1.sol [Line: 102](src/nft/helpers/FrameV1.sol#L102)

	```solidity
	    string memory stats = string(abi.encodePacked(
	```

- Found in src/nft/helpers/FrameV1.sol [Line: 108](src/nft/helpers/FrameV1.sol#L108)

	```solidity
	    return string(abi.encodePacked(
	```

- Found in src/nft/helpers/FrameV1.sol [Line: 164](src/nft/helpers/FrameV1.sol#L164)

	```solidity
	                abi.encodePacked(
	```

- Found in src/nft/helpers/FrameV1.sol [Line: 169](src/nft/helpers/FrameV1.sol#L169)

	```solidity
	                                abi.encodePacked(
	```

- Found in src/nft/helpers/FrameV1.sol [Line: 178](src/nft/helpers/FrameV1.sol#L178)

	```solidity
	                                            abi.encodePacked(
	```

- Found in src/nft/helpers/FrameV1.sol [Line: 201](src/nft/helpers/FrameV1.sol#L201)

	```solidity
	                abi.encodePacked('"', key, '":"', value, comma ? '",' : '"')
	```

- Found in src/nft/helpers/FrameV1.sol [Line: 270](src/nft/helpers/FrameV1.sol#L270)

	```solidity
	        return string(abi.encodePacked("#",string(buffer)));
	```

- Found in src/nft/helpers/FrameV1.sol [Line: 276](src/nft/helpers/FrameV1.sol#L276)

	```solidity
	                abi.encodePacked(
	```

- Found in src/nft/helpers/FrameV1.sol [Line: 304](src/nft/helpers/FrameV1.sol#L304)

	```solidity
	                abi.encodePacked(
	```

- Found in src/nft/helpers/FrameV1.sol [Line: 332](src/nft/helpers/FrameV1.sol#L332)

	```solidity
	                abi.encodePacked(
	```

- Found in src/nft/helpers/FrameV1.sol [Line: 352](src/nft/helpers/FrameV1.sol#L352)

	```solidity
	        return string(abi.encodePacked(                    
	```

- Found in src/nft/helpers/FrameV1.sol [Line: 364](src/nft/helpers/FrameV1.sol#L364)

	```solidity
	        return string(abi.encodePacked(                   
	```

</details>



## H-2: Arbitrary `from` passed to `transferFrom` (or `safeTransferFrom`)

Passing an arbitrary `from` address to `transferFrom` (or `safeTransferFrom`) can lead to loss of funds, because anyone can transfer tokens from the `from` address if an approval is made.  

<details><summary>4 Found Instances</summary>


- Found in src/misc/Game.sol [Line: 120](src/misc/Game.sol#L120)

	```solidity
	        nft.safeTransferFrom(nftOwner, msg.sender, order.tokenId);
	```

- Found in src/nft/EtherverseNFT.sol [Line: 347](src/nft/EtherverseNFT.sol#L347)

	```solidity
	        super.transferFrom(from, to, tokenId);
	```

- Found in src/nft/EtherverseNFT.sol [Line: 356](src/nft/EtherverseNFT.sol#L356)

	```solidity
	        super.safeTransferFrom(from, to, tokenId, data);
	```

- Found in src/nft/EtherverseNFT.sol [Line: 364](src/nft/EtherverseNFT.sol#L364)

	```solidity
	        super.safeTransferFrom(from, to, tokenId, "");
	```

</details>



## H-3: Uninitialized State Variables

Solidity does initialize variables by default when you declare them, however it's good practice to explicitly declare an initial value. For example, if you transfer money to an address we must make sure that the address has been initialized.

<details><summary>5 Found Instances</summary>


- Found in src/common/EtherverseUser.sol [Line: 17](src/common/EtherverseUser.sol#L17)

	```solidity
	    address private walletCandidate;
	```

- Found in src/common/EtherverseUser.sol [Line: 18](src/common/EtherverseUser.sol#L18)

	```solidity
	    uint256 private walletCandidateTimeout;
	```

- Found in src/misc/Game.sol [Line: 33](src/misc/Game.sol#L33)

	```solidity
	    uint256 public freeUpgradeInput;
	```

- Found in src/misc/Game.sol [Line: 34](src/misc/Game.sol#L34)

	```solidity
	    uint256 public paidUpgradeInput;
	```

- Found in src/misc/Game.sol [Line: 35](src/misc/Game.sol#L35)

	```solidity
	    uint256 public orderCount;
	```

</details>



## H-4: Sending native Eth is not protected from these functions.

Introduce checks for `msg.sender` in the function

<details><summary>1 Found Instances</summary>


- Found in src/common/EtherverseUser.sol [Line: 91](src/common/EtherverseUser.sol#L91)

	```solidity
	    function withdraw(
	```

</details>



## H-5: Tautology or Contradiction in comparison.

The condition has been determined to be either always true or always false due to the integer range in which we're operating.

<details><summary>1 Found Instances</summary>


- Found in src/nft/helpers/FrameV1.sol [Line: 262](src/nft/helpers/FrameV1.sol#L262)

	```solidity
	        for (uint8 i = 2 * length - 1; i >= 0; --i) {
	```

</details>



# Low Issues

## L-1: Centralization Risk for trusted owners

Contracts have owners with privileged rights to perform admin tasks and need to be trusted to not perform malicious updates or drain funds.

<details><summary>14 Found Instances</summary>


- Found in src/common/EtherverseUser.sol [Line: 10](src/common/EtherverseUser.sol#L10)

	```solidity
	contract EtherverseUser is ReentrancyGuard, Ownable {
	```

- Found in src/common/EtherverseUser.sol [Line: 58](src/common/EtherverseUser.sol#L58)

	```solidity
	    function setUser(address _user) external onlyOwner {
	```

- Found in src/common/EtherverseUser.sol [Line: 116](src/common/EtherverseUser.sol#L116)

	```solidity
	    function updateEtherverseFee(uint256 _fee) external onlyOwner {
	```

- Found in src/misc/Game.sol [Line: 138](src/misc/Game.sol#L138)

	```solidity
	    function setUpgradeModule(address _upgrade) external onlyOwner {
	```

- Found in src/nft/EtherverseNFT.sol [Line: 14](src/nft/EtherverseNFT.sol#L14)

	```solidity
	contract EtherverseNFT is ERC721, Ownable, ReentrancyGuard {
	```

- Found in src/nft/EtherverseNFT.sol [Line: 143](src/nft/EtherverseNFT.sol#L143)

	```solidity
	    function setSign(uint256 _sign) external onlyOwner {
	```

- Found in src/nft/EtherverseNFT.sol [Line: 147](src/nft/EtherverseNFT.sol#L147)

	```solidity
	    function setWhitelisted(address _address, bool _status) external onlyOwner {
	```

- Found in src/nft/EtherverseNFT.sol [Line: 151](src/nft/EtherverseNFT.sol#L151)

	```solidity
	    function changeCCIP(address newAdd) external onlyOwner {
	```

- Found in src/nft/EtherverseNFT.sol [Line: 155](src/nft/EtherverseNFT.sol#L155)

	```solidity
	    function changeFrame(address _uri) external onlyOwner {
	```

- Found in src/nft/EtherverseNFT.sol [Line: 160](src/nft/EtherverseNFT.sol#L160)

	```solidity
	    function setUSDC(address _usdc) external onlyOwner {
	```

- Found in src/nft/EtherverseNFT.sol [Line: 165](src/nft/EtherverseNFT.sol#L165)

	```solidity
	    function changeImageUrl(string memory str) external onlyOwner {
	```

- Found in src/nft/EtherverseNFT.sol [Line: 169](src/nft/EtherverseNFT.sol#L169)

	```solidity
	    function setMetadata(string memory str) external onlyOwner {
	```

- Found in src/nft/EtherverseNFT.sol [Line: 173](src/nft/EtherverseNFT.sol#L173)

	```solidity
	    function setMintPrice(uint256 _mintPrice) external onlyOwner {
	```

- Found in src/nft/EtherverseNFT.sol [Line: 178](src/nft/EtherverseNFT.sol#L178)

	```solidity
	    function setFeeSplit(uint256 _split) external onlyOwner {  //@tester : wrong error msg
	```

</details>



## L-2: Unsafe ERC20 Operations should not be used

ERC20 functions may not behave as expected. For example: return values are not always meaningful. It is recommended to use OpenZeppelin's SafeERC20 library.

<details><summary>3 Found Instances</summary>


- Found in src/common/EtherverseUser.sol [Line: 100](src/common/EtherverseUser.sol#L100)

	```solidity
	            payable(etherverse).transfer(fee);
	```

- Found in src/common/EtherverseUser.sol [Line: 102](src/common/EtherverseUser.sol#L102)

	```solidity
	            payable(userWallet).transfer(balance);
	```

- Found in src/nft/EtherverseNFT.sol [Line: 347](src/nft/EtherverseNFT.sol#L347)

	```solidity
	        super.transferFrom(from, to, tokenId);
	```

</details>



## L-3: Solidity pragma should be specific, not wide

Consider using a specific version of Solidity in your contracts instead of a wide version. For example, instead of `pragma solidity ^0.8.0;`, use `pragma solidity 0.8.0;`

<details><summary>5 Found Instances</summary>


- Found in src/common/interface/IUSDC.sol [Line: 2](src/common/interface/IUSDC.sol#L2)

	```solidity
	pragma solidity ^0.8.20;
	```

- Found in src/mock/MockUSDC.sol [Line: 2](src/mock/MockUSDC.sol#L2)

	```solidity
	pragma solidity ^0.8.20;
	```

- Found in src/nft/EtherverseNFT.sol [Line: 2](src/nft/EtherverseNFT.sol#L2)

	```solidity
	pragma solidity ^0.8.24;
	```

- Found in src/nft/helpers/UpgradeV1.sol [Line: 2](src/nft/helpers/UpgradeV1.sol#L2)

	```solidity
	pragma solidity ^0.8.20;
	```

- Found in src/nft/interface/IEtherverseNFT.sol [Line: 2](src/nft/interface/IEtherverseNFT.sol#L2)

	```solidity
	pragma solidity ^0.8.20;
	```

</details>



## L-4: Missing checks for `address(0)` when assigning values to address state variables

Check for `address(0)` when assigning values to address state variables.

<details><summary>9 Found Instances</summary>


- Found in src/common/EtherverseUser.sol [Line: 42](src/common/EtherverseUser.sol#L42)

	```solidity
	        etherverse = _etherverse;
	```

- Found in src/common/EtherverseUser.sol [Line: 44](src/common/EtherverseUser.sol#L44)

	```solidity
	        user = _user;
	```

- Found in src/common/EtherverseUser.sol [Line: 45](src/common/EtherverseUser.sol#L45)

	```solidity
	        user = _userWallet;
	```

- Found in src/misc/Game.sol [Line: 77](src/misc/Game.sol#L77)

	```solidity
	        USDC = IERC20(_usdcToken);
	```

- Found in src/misc/Game.sol [Line: 81](src/misc/Game.sol#L81)

	```solidity
	        upgradeAddress = _upgrade;
	```

- Found in src/misc/Game.sol [Line: 139](src/misc/Game.sol#L139)

	```solidity
	        upgradeAddress = _upgrade;
	```

- Found in src/nft/EtherverseNFT.sol [Line: 152](src/nft/EtherverseNFT.sol#L152)

	```solidity
	        _ccipHandler = newAdd;
	```

- Found in src/nft/EtherverseNFT.sol [Line: 156](src/nft/EtherverseNFT.sol#L156)

	```solidity
	        uriAddress = _uri;
	```

- Found in src/nft/EtherverseNFT.sol [Line: 162](src/nft/EtherverseNFT.sol#L162)

	```solidity
	        USDC = _usdc;
	```

</details>



## L-5: `public` functions not used internally could be marked `external`

Instead of marking a function as `public`, consider marking it as `external` if it is not used internally.

<details><summary>4 Found Instances</summary>


- Found in src/mock/MockUSDC.sol [Line: 10](src/mock/MockUSDC.sol#L10)

	```solidity
	    function mint(address to, uint256 amount) public {
	```

- Found in src/nft/EtherverseNFT.sol [Line: 232](src/nft/EtherverseNFT.sol#L232)

	```solidity
	    function tokenURI(
	```

- Found in src/nft/EtherverseNFT.sol [Line: 342](src/nft/EtherverseNFT.sol#L342)

	```solidity
	    function transferFrom(
	```

- Found in src/nft/EtherverseNFT.sol [Line: 350](src/nft/EtherverseNFT.sol#L350)

	```solidity
	    function safeTransferFrom(
	```

</details>



## L-6: Define and use `constant` variables instead of using literals

If the same constant literal value is used multiple times, create a constant state variable and reference it throughout the contract.

<details><summary>42 Found Instances</summary>


- Found in src/common/EtherverseUser.sol [Line: 95](src/common/EtherverseUser.sol#L95)

	```solidity
	        require(_percentage <= 100, "Invalid percentage");
	```

- Found in src/common/EtherverseUser.sol [Line: 98](src/common/EtherverseUser.sol#L98)

	```solidity
	            uint256 amount = (address(this).balance * _percentage) / 100;
	```

- Found in src/common/EtherverseUser.sol [Line: 99](src/common/EtherverseUser.sol#L99)

	```solidity
	            uint256 fee = (amount * etherverseFee) / 10000;
	```

- Found in src/common/EtherverseUser.sol [Line: 107](src/common/EtherverseUser.sol#L107)

	```solidity
	                100;
	```

- Found in src/common/EtherverseUser.sol [Line: 108](src/common/EtherverseUser.sol#L108)

	```solidity
	            uint256 fee = (amount * etherverseFee) / 10000;
	```

- Found in src/common/EtherverseUser.sol [Line: 109](src/common/EtherverseUser.sol#L109)

	```solidity
	            token.safeTransfer(etherverse, (amount * etherverseFee) / 10000);
	```

- Found in src/nft/EtherverseNFT.sol [Line: 87](src/nft/EtherverseNFT.sol#L87)

	```solidity
	        baseStat = Asset.Stat(87, 20, 21);
	```

- Found in src/nft/EtherverseNFT.sol [Line: 95](src/nft/EtherverseNFT.sol#L95)

	```solidity
	        colorRanges = [0, 10, 20, 30];
	```

- Found in src/nft/EtherverseNFT.sol [Line: 100](src/nft/EtherverseNFT.sol#L100)

	```solidity
	        mintPrice = 100000;
	```

- Found in src/nft/EtherverseNFT.sol [Line: 224](src/nft/EtherverseNFT.sol#L224)

	```solidity
	        if (tokenId > STARTING_TOKEN_ID + 100000)
	```

- Found in src/nft/EtherverseNFT.sol [Line: 261](src/nft/EtherverseNFT.sol#L261)

	```solidity
	            .calculateUpgrade(upgradeMapping[tokenId], 5);
	```

- Found in src/nft/EtherverseNFT.sol [Line: 297](src/nft/EtherverseNFT.sol#L297)

	```solidity
	                    5
	```

- Found in src/nft/helpers/FrameV1.sol [Line: 38](src/nft/helpers/FrameV1.sol#L38)

	```solidity
	        Asset.StatType[3] memory statLabel = nft.statLabelsArray();
	```

- Found in src/nft/helpers/FrameV1.sol [Line: 42](src/nft/helpers/FrameV1.sol#L42)

	```solidity
	        string memory powerColor = toHexString(powerLevelColor(0, _nft), 3);
	```

- Found in src/nft/helpers/FrameV1.sol [Line: 60](src/nft/helpers/FrameV1.sol#L60)

	```solidity
	        Asset.StatType[3] memory _statLabels = nft.statLabelsArray();
	```

- Found in src/nft/helpers/FrameV1.sol [Line: 62](src/nft/helpers/FrameV1.sol#L62)

	```solidity
	        string[3] memory _stats = _getStats(_statLabels, tokenId, nft);
	```

- Found in src/nft/helpers/FrameV1.sol [Line: 63](src/nft/helpers/FrameV1.sol#L63)

	```solidity
	        string[3] memory lockedStats = ["???", "???", "???"];
	```

- Found in src/nft/helpers/FrameV1.sol [Line: 74](src/nft/helpers/FrameV1.sol#L74)

	```solidity
	                : toHexString(powerLevelColor(tokenId, msg.sender), 3),
	```

- Found in src/nft/helpers/FrameV1.sol [Line: 124](src/nft/helpers/FrameV1.sol#L124)

	```solidity
	        uint8 r = uint8((decimal >> 16) & 0xFF);
	```

- Found in src/nft/helpers/FrameV1.sol [Line: 125](src/nft/helpers/FrameV1.sol#L125)

	```solidity
	        uint8 g = uint8((decimal >> 8) & 0xFF);
	```

- Found in src/nft/helpers/FrameV1.sol [Line: 126](src/nft/helpers/FrameV1.sol#L126)

	```solidity
	        uint8 b = uint8(decimal & 0xFF);
	```

- Found in src/nft/helpers/FrameV1.sol [Line: 137](src/nft/helpers/FrameV1.sol#L137)

	```solidity
	    function statLabelFromEnum(Asset.StatType[3] memory _stat)
	```

- Found in src/nft/helpers/FrameV1.sol [Line: 140](src/nft/helpers/FrameV1.sol#L140)

	```solidity
	        returns (string[3] memory)
	```

- Found in src/nft/helpers/FrameV1.sol [Line: 142](src/nft/helpers/FrameV1.sol#L142)

	```solidity
	        string[3] memory label;
	```

- Found in src/nft/helpers/FrameV1.sol [Line: 143](src/nft/helpers/FrameV1.sol#L143)

	```solidity
	        for (uint256 i; i<3; i++) {
	```

- Found in src/nft/helpers/FrameV1.sol [Line: 226](src/nft/helpers/FrameV1.sol#L226)

	```solidity
	                baseStat.stat3) / 3;
	```

- Found in src/nft/helpers/FrameV1.sol [Line: 247](src/nft/helpers/FrameV1.sol#L247)

	```solidity
	    function _getStats(Asset.StatType[3] memory stats, uint256 tokenId, IEtherverseNFT nft) internal view returns(string[3] memory){
	```

- Found in src/nft/helpers/FrameV1.sol [Line: 248](src/nft/helpers/FrameV1.sol#L248)

	```solidity
	        string[3] memory statsStr;
	```

- Found in src/nft/helpers/FrameV1.sol [Line: 249](src/nft/helpers/FrameV1.sol#L249)

	```solidity
	        for(uint8 i; i<3;i++){
	```

- Found in src/nft/helpers/UpgradeV1.sol [Line: 29](src/nft/helpers/UpgradeV1.sol#L29)

	```solidity
	        _stat.stat1 = _stat.stat1 + _increment < 100
	```

- Found in src/nft/helpers/UpgradeV1.sol [Line: 31](src/nft/helpers/UpgradeV1.sol#L31)

	```solidity
	            : 100;
	```

- Found in src/nft/helpers/UpgradeV1.sol [Line: 33](src/nft/helpers/UpgradeV1.sol#L33)

	```solidity
	        _stat.stat2 = _stat.stat2 + _increment < 100
	```

- Found in src/nft/helpers/UpgradeV1.sol [Line: 35](src/nft/helpers/UpgradeV1.sol#L35)

	```solidity
	            : 100;
	```

- Found in src/nft/helpers/UpgradeV1.sol [Line: 37](src/nft/helpers/UpgradeV1.sol#L37)

	```solidity
	        _stat.stat3 = _stat.stat3 + _increment < 100
	```

- Found in src/nft/helpers/UpgradeV1.sol [Line: 39](src/nft/helpers/UpgradeV1.sol#L39)

	```solidity
	            : 100;
	```

- Found in src/nft/helpers/UpgradeV1.sol [Line: 50](src/nft/helpers/UpgradeV1.sol#L50)

	```solidity
	                uint256(_stat.stat3)) * 100) / 3;
	```

- Found in src/nft/helpers/UpgradeV1.sol [Line: 57](src/nft/helpers/UpgradeV1.sol#L57)

	```solidity
	        return ((BASE_PRICE_IN_USDC) * statPriceMultiplier(_stat)) / 100;
	```

- Found in src/nft/helpers/UpgradeV1.sol [Line: 65](src/nft/helpers/UpgradeV1.sol#L65)

	```solidity
	        Asset.StatType[3] memory statLabels = nft.statLabels();
	```

- Found in src/nft/interface/IEtherverseNFT.sol [Line: 13](src/nft/interface/IEtherverseNFT.sol#L13)

	```solidity
	    function statLabelsArray() external view returns (Asset.StatType[3] memory);
	```

- Found in src/nft/interface/IEtherverseNFT.sol [Line: 96](src/nft/interface/IEtherverseNFT.sol#L96)

	```solidity
	    function statLabels() external view returns (Asset.StatType[3] memory);
	```

</details>



## L-7: Event is missing `indexed` fields

Index event fields make the field more quickly accessible to off-chain tools that parse events. However, note that each index field costs extra gas during emission, so it's not necessarily best to index the maximum allowed per event (three fields). Each event should use three indexed fields if there are three or more fields, and gas usage is not particularly of concern for the events in question. If there are fewer than three fields, all of the fields should be indexed.

<details><summary>2 Found Instances</summary>


- Found in src/common/EtherverseUser.sol [Line: 21](src/common/EtherverseUser.sol#L21)

	```solidity
	    event CandidateProposed(
	```

- Found in src/common/EtherverseUser.sol [Line: 26](src/common/EtherverseUser.sol#L26)

	```solidity
	    event ProposalAccepted(address indexed newUser, uint256 timestamp);
	```

</details>



## L-8: The `nonReentrant` `modifier` should occur before all other modifiers

This is a best-practice to protect against reentrancy in other modifiers.

<details><summary>4 Found Instances</summary>


- Found in src/nft/EtherverseNFT.sol [Line: 221](src/nft/EtherverseNFT.sol#L221)

	```solidity
	    ) external isWhitelisted(msg.sender) nonReentrant returns (uint256) {
	```

- Found in src/nft/EtherverseNFT.sol [Line: 258](src/nft/EtherverseNFT.sol#L258)

	```solidity
	        nonReentrant
	```

- Found in src/nft/EtherverseNFT.sol [Line: 355](src/nft/EtherverseNFT.sol#L355)

	```solidity
	    ) public override nonZeroAddress(to) isUnlocked(tokenId) nonReentrant {
	```

- Found in src/nft/EtherverseNFT.sol [Line: 363](src/nft/EtherverseNFT.sol#L363)

	```solidity
	    ) external nonZeroAddress(to) nonReentrant onlyCCIPRouter {
	```

</details>



## L-9: PUSH0 is not supported by all chains

Solc compiler version 0.8.20 switches the default target EVM version to Shanghai, which means that the generated bytecode will include PUSH0 opcodes. Be sure to select the appropriate EVM version in case you intend to deploy on a chain other than mainnet like L2 chains that may not support PUSH0, otherwise deployment of your contracts will fail.

<details><summary>5 Found Instances</summary>


- Found in src/common/interface/IUSDC.sol [Line: 2](src/common/interface/IUSDC.sol#L2)

	```solidity
	pragma solidity ^0.8.20;
	```

- Found in src/mock/MockUSDC.sol [Line: 2](src/mock/MockUSDC.sol#L2)

	```solidity
	pragma solidity ^0.8.20;
	```

- Found in src/nft/EtherverseNFT.sol [Line: 2](src/nft/EtherverseNFT.sol#L2)

	```solidity
	pragma solidity ^0.8.24;
	```

- Found in src/nft/helpers/UpgradeV1.sol [Line: 2](src/nft/helpers/UpgradeV1.sol#L2)

	```solidity
	pragma solidity ^0.8.20;
	```

- Found in src/nft/interface/IEtherverseNFT.sol [Line: 2](src/nft/interface/IEtherverseNFT.sol#L2)

	```solidity
	pragma solidity ^0.8.20;
	```

</details>



## L-10: Large literal values multiples of 10000 can be replaced with scientific notation

Use `e` notation, for example: `1e18`, instead of its full numeric value.

<details><summary>7 Found Instances</summary>


- Found in src/common/EtherverseUser.sol [Line: 99](src/common/EtherverseUser.sol#L99)

	```solidity
	            uint256 fee = (amount * etherverseFee) / 10000;
	```

- Found in src/common/EtherverseUser.sol [Line: 108](src/common/EtherverseUser.sol#L108)

	```solidity
	            uint256 fee = (amount * etherverseFee) / 10000;
	```

- Found in src/common/EtherverseUser.sol [Line: 109](src/common/EtherverseUser.sol#L109)

	```solidity
	            token.safeTransfer(etherverse, (amount * etherverseFee) / 10000);
	```

- Found in src/nft/EtherverseNFT.sol [Line: 20](src/nft/EtherverseNFT.sol#L20)

	```solidity
	    uint256 private constant STARTING_TOKEN_ID = 1000000;
	```

- Found in src/nft/EtherverseNFT.sol [Line: 100](src/nft/EtherverseNFT.sol#L100)

	```solidity
	        mintPrice = 100000;
	```

- Found in src/nft/EtherverseNFT.sol [Line: 179](src/nft/EtherverseNFT.sol#L179)

	```solidity
	        if (_split > 10000) revert Errors.ZeroInput();  
	```

- Found in src/nft/EtherverseNFT.sol [Line: 224](src/nft/EtherverseNFT.sol#L224)

	```solidity
	        if (tokenId > STARTING_TOKEN_ID + 100000)
	```

</details>



## L-11: Internal functions called only once can be inlined

Instead of separating the logic into a separate function, consider inlining the logic into the calling function. This can reduce the number of function calls and improve readability.

<details><summary>6 Found Instances</summary>


- Found in src/nft/helpers/FrameV1.sol [Line: 205](src/nft/helpers/FrameV1.sol#L205)

	```solidity
	    function powerLevelStr(uint256 tokenId, address nftAddress)
	```

- Found in src/nft/helpers/FrameV1.sol [Line: 273](src/nft/helpers/FrameV1.sol#L273)

	```solidity
	    function svgHeader() internal pure returns (string memory) {
	```

- Found in src/nft/helpers/FrameV1.sol [Line: 297](src/nft/helpers/FrameV1.sol#L297)

	```solidity
	    function svgImageBorder(string memory itemImage, string memory powerColor)
	```

- Found in src/nft/helpers/FrameV1.sol [Line: 325](src/nft/helpers/FrameV1.sol#L325)

	```solidity
	    function svgName(string memory powerColor,string memory textColor, string memory name)
	```

- Found in src/nft/helpers/FrameV1.sol [Line: 351](src/nft/helpers/FrameV1.sol#L351)

	```solidity
	    function svgPowerLevel(string memory _powerLevel) internal pure returns (string memory) {
	```

- Found in src/nft/helpers/UpgradeV1.sol [Line: 44](src/nft/helpers/UpgradeV1.sol#L44)

	```solidity
	    function statPriceMultiplier(
	```

</details>



## L-12: Contract still has TODOs

Contract contains comments with TODOS

<details><summary>1 Found Instances</summary>


- Found in src/nft/EtherverseNFT.sol [Line: 14](src/nft/EtherverseNFT.sol#L14)

	```solidity
	contract EtherverseNFT is ERC721, Ownable, ReentrancyGuard {
	```

</details>


