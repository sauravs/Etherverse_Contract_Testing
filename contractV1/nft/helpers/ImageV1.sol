// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import {Asset} from "../RPGUtil.sol";
import {IRPGV1} from "../interface/IRPG.sol";

contract Image {
    using Strings for uint8;
    using Strings for uint256;

    bytes16 private constant HEX_DIGITS = "0123456789abcdef";

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        IRPGV1 nft = IRPGV1(msg.sender);
        Asset.StatType[] memory statLabels = nft.statLabelsArray();
        bool tokenLockStatus = nft.lockStatus(tokenId);

        string memory imgSVG = generateSVG(
            tokenLockStatus ? "#808080" : powerLevelColor(tokenId, msg.sender),
            tokenLockStatus ? "??" : Strings.toString(nft.getStat(statLabels[0], tokenId)),
            tokenLockStatus ? "??" : Strings.toString(nft.getStat(statLabels[1], tokenId)),
            tokenLockStatus ? "??" : Strings.toString(nft.getStat(statLabels[2], tokenId)),
            tokenLockStatus ? "??" : Strings.toString(powerLevel(tokenId, msg.sender)),
            tokenLockStatus ? "https://ipfs.io/ipfs/QmaXD4NLN9hn5cb9jTd78faMvU3RNmf34gvhLGsnq67zs3" : nft.itemImage(),
            nft.name()
        );

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name":',
                        '"',
                        nft.name(),
                        '",',
                        '"signature":',
                        '"',
                        nft.sign().toString(),
                        '",',
                        '"image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(imgSVG)),
                        '"}'
                    )
                )
            )
        );

        string memory finalTokenURI = string(abi.encodePacked("data:application/json;base64,", json));
        return finalTokenURI;
    }

    function generateSVG(
        string memory color,
        string memory stat1,
        string memory stat2,
        string memory stat3,
        string memory powerLvl,
        string memory image,
        string memory name
    ) internal pure returns (string memory) {
        return string(
            abi.encodePacked(
                "<svg xmlns='http://www.w3.org/2000/svg' version='1.1' xmlns:xlink='http://www.w3.org/1999/xlink' xmlns:svgjs='http://svgjs.com/svgjs' width='300' height='300' preserveAspectRatio='none' viewBox='0 0 500 500'>",
                "<rect width='100%' height='100%' fill='",
                color,
                "'/>",
                generateCircle(stat1, "80"),
                generateCircle(stat2, "180"),
                generateCircle(stat3, "280"),
                generateCircle(powerLvl, "380"),
                "<image x='100' y='50' width='300' height='300' href='",
                image,
                "'/>",
                "<text x='250' y='420' fill='black' font-size='24' dominant-baseline='middle' text-anchor='middle'>",
                name,
                "</text>",
                "<rect x='0' y='0' width='500' height='500' fill='none' stroke='#000000' stroke-width='5' rx='15' ry='15'/>",
                "</svg>"
            )
        );
    }

    function generateCircle(string memory value, string memory loc) internal pure returns (string memory) {
        return string(
            abi.encodePacked(
                "<circle cx='50' cy='",
                loc,
                "' r='40' fill='#00aaff' stroke='#000000' stroke-width='3' />",
                "<text x='50' y='",
                loc,
                "' fill='black' font-size='24' dominant-baseline='middle' text-anchor='middle'>",
                value,
                "</text>"
            )
        );
    }

    function powerLevel(uint256 tokenId, address nftAddress) internal view returns (uint256) {
        IRPGV1 nft = IRPGV1(nftAddress);
        Asset.Stat memory previousStat = nft.upgradeMapping(tokenId);
        Asset.Stat memory baseStat = nft.baseStat();

        return (
            previousStat.stat1 + baseStat.stat1 + previousStat.stat2 + baseStat.stat2 + previousStat.stat3
                + baseStat.stat3
        ) / 3;
    }

    function powerLevelColor(uint256 tokenId, address nftAddress) internal view returns (string memory) {
        IRPGV1 nft = IRPGV1(nftAddress);
        uint256 plvl = powerLevel(tokenId, nftAddress);
        uint8[] memory colorRanges = nft.colorRangesArray();
        uint24[] memory svgColors = nft.svgColorsArray();
        if (plvl == 0) return toHexString(svgColors[0], 3);
        for (uint256 i; i < colorRanges.length - 1; i++) {
            if (plvl >= colorRanges[i] && plvl < colorRanges[i + 1]) {
                return toHexString(svgColors[i], 3);
            }
        }
        return toHexString(svgColors[0], 3);
    }

    function toHexString(uint24 value, uint8 length) internal pure returns (string memory) {
        uint24 localValue = value;
        bytes memory buffer = new bytes(2 * length);
        for (uint8 i = 2 * length - 1; i >= 0; --i) {
            buffer[i] = HEX_DIGITS[localValue & 0xf];
            localValue >>= 4;
            if (i == 0) break; // Prevent underflow
        }
        if (localValue != 0) {
            revert("Hex length insufficient");
        }
        return string(buffer);
    }
}
