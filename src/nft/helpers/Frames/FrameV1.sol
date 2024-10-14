// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import {Asset} from "../../lib/Utils.sol";
import {IEtherverseNFT} from "../../interface/IEtherverseNFT.sol";

contract Frame {
    using Strings for uint8;
    using Strings for uint256;
    bytes16 private constant HEX_DIGITS = "0123456789abcdef";
    string public constant FrameName = "Basic Frame";
    struct StatDisplay {
        string value;
        string label;
        string valuePos;
        string labelPos;
    }
    struct FrameData {
        string name;
        string image;
        string textColor;
        string powerColor;
        string powerLevel;
        string[3] stats;
        string[3] statLabels;
    }
    struct JSONData {
        string name; 
        string sign;
        string image;
        string metadata;
        string svg;
    }

    function preview(address _nft) external view returns (string memory) {
        IEtherverseNFT nft = IEtherverseNFT(_nft);
        Asset.StatType[3] memory statLabel = nft.statLabelsArray();
        uint256 sign = nft.sign();

        string memory textColor = getColor(powerLevelColor(0, _nft));
        string memory powerColor = toHexString(powerLevelColor(0, _nft), 3);

        string memory svg = generateFrame(FrameData(
            nft.name(),
            nft.itemImage(),
            textColor,
            powerColor,
            "???",
            ["???", "???", "???"],
            statLabelFromEnum(statLabel)
        )
        );

        return generateJSON(JSONData(nft.name(), sign.toString(), nft.itemImage(), nft.metadata(), svg));
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        IEtherverseNFT nft = IEtherverseNFT(msg.sender);
        Asset.StatType[3] memory _statLabels = nft.statLabelsArray();
        bool tokenLockStatus = nft.lockStatus(tokenId);
        string[3] memory _stats = _getStats(_statLabels, tokenId, nft);
        string[3] memory lockedStats = ["???", "???", "???"];
        string memory svg = generateFrame(FrameData(
            nft.name(),
            tokenLockStatus
                ? "https://ipfs.io/ipfs/QmaXD4NLN9hn5cb9jTd78faMvU3RNmf34gvhLGsnq67zs3"
                : nft.itemImage(),
            tokenLockStatus
                ? getColor(8421504)
                : getColor(powerLevelColor(tokenId, msg.sender)),
            tokenLockStatus
                ? "#808080"
                : toHexString(powerLevelColor(tokenId, msg.sender), 3),
            tokenLockStatus
                ? "???"
                : powerLevelStr(tokenId, msg.sender),
            tokenLockStatus ? lockedStats : _stats,
            statLabelFromEnum(_statLabels)
        ));

        return
            generateJSON(JSONData(
                nft.name(),
                nft.sign().toString(),
                            tokenLockStatus
                ? "https://ipfs.io/ipfs/QmaXD4NLN9hn5cb9jTd78faMvU3RNmf34gvhLGsnq67zs3"
                : nft.itemImage(),

                nft.metadata(),
                svg
            ));
    }

function generateFrame(
    FrameData memory data
) internal pure returns (string memory) {
    string memory header = svgHeader();
    string memory imageBorder = svgImageBorder(data.image, data.powerColor);
    string memory name = svgName(data.powerColor, data.textColor, data.name);
    string memory powerLvl = svgPowerLevel(data.powerLevel);
    string memory stats = string(abi.encodePacked(                                  //@audit-ad-High Use `abi.encode()` instead which will pad items to 32 bytes, which will [prevent hash collisions
        svgStatDisplay(StatDisplay(data.stats[0], data.statLabels[0], "409.13", "412.87")),
        svgStatDisplay(StatDisplay(data.stats[1], data.statLabels[1], "1301.49", "1305.23")),
        svgStatDisplay(StatDisplay(data.stats[2], data.statLabels[2], "2224.06", "2227.8"))
    ));

    return string(abi.encodePacked(    //@audit-ad-High Use `abi.encode()` instead which will pad items to 32 bytes, which will [prevent hash collisions
        "<svg xmlns='http://www.w3.org/2000/svg' xmlSpace='preserve' width='3in' height='4in' version='1.1' style='shape-rendering:geometricPrecision; text-rendering:geometricPrecision; fill-rule:evenodd; clip-rule:evenodd;' viewBox='0 0 4133.28 5464.82'>",
        header,
        "<g>",
        imageBorder,
        name,
        powerLvl,
        stats,
        "</g>",
        "</g>",
        "</svg>"
    ));
}


    function getColor(uint24 decimal) public pure returns (string memory) {
        uint8 r = uint8((decimal >> 16) & 0xFF);
        uint8 g = uint8((decimal >> 8) & 0xFF);
        uint8 b = uint8(decimal & 0xFF);

        uint32 luminance = (299 * uint32(r) + 587 * uint32(g) + 114 * uint32(b)) / 1000;

        if (luminance > 127) {
            return "#111111";
        } else {
            return "#EEEEEE";
        }
    }

    function statLabelFromEnum(Asset.StatType[3] memory _stat)
        internal
        pure
        returns (string[3] memory)
    {
        string[3] memory label;
        for (uint256 i; i<3; i++) {
            if (_stat[i] == Asset.StatType.STR) {
                label[i]= "STR";
            } else if (_stat[i] == Asset.StatType.DEX) {
                label[i]= "DEX";
            } else if (_stat[i] == Asset.StatType.CON) {
                label[i]= "CON";
            } else if (_stat[i] == Asset.StatType.INT) {
                label[i]= "INT";
            } else if (_stat[i] == Asset.StatType.CHA) {
                label[i]= "CHR";
            } else if (_stat[i] == Asset.StatType.WIS) {
                label[i]= "WIS";
            }
        }
        return label;
    }

    function generateJSON(JSONData memory data) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            string(
                                abi.encodePacked(
                                    "{",
                                    keyValue("name", data.name, true),
                                    keyValue("signature", data.sign, true),
                                    keyValue("metadata", string(
                                            abi.encodePacked(
                                                "data:application/json;base64,",
                                                Base64.encode(bytes(data.metadata))
                                            )
                                        ), true),
                                    keyValue("image", data.image, true),
                                    keyValue(
                                        "animation_url",
                                        string(
                                            abi.encodePacked(
                                                "data:image/svg+xml;base64,",
                                                Base64.encode(bytes(data.svg))
                                            )
                                        ),
                                        false
                                    ),
                                    "}"
                                )
                            )
                        )
                    )
                )
            );
    }


    function keyValue(
        string memory key,
        string memory value,
        bool comma
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked('"', key, '":"', value, comma ? '",' : '"')
            );
    }

    function powerLevelStr(uint256 tokenId, address nftAddress)
        internal
        view
        returns(string memory){
            return Strings.toString(powerLevel(tokenId, nftAddress));
        }
    function powerLevel(uint256 tokenId, address nftAddress)
        internal
        view
        returns (uint256)
    {
        IEtherverseNFT nft = IEtherverseNFT(nftAddress);
        Asset.Stat memory previousStat = nft.upgradeMapping(tokenId);
        Asset.Stat memory baseStat = nft.baseStat();

        return
            (previousStat.stat1 +
                baseStat.stat1 +
                previousStat.stat2 +
                baseStat.stat2 +
                previousStat.stat3 +
                baseStat.stat3) / 3;
    }

    function powerLevelColor(uint256 tokenId, address nftAddress)
        internal
        view
        returns (uint24)
    {
        IEtherverseNFT nft = IEtherverseNFT(nftAddress);
        uint256 plvl = powerLevel(tokenId, nftAddress);
        uint8[] memory colorRanges = nft.colorRangesArray();
        uint24[] memory svgColors = nft.svgColorsArray();
        if (plvl == 0) return svgColors[0];
        for (uint256 i; i < colorRanges.length - 1; i++) {
            if (plvl >= colorRanges[i] && plvl < colorRanges[i + 1]) {
                return svgColors[i];
            }
        }
        return svgColors[0];
    }

    function _getStats(Asset.StatType[3] memory stats, uint256 tokenId, IEtherverseNFT nft) internal view returns(string[3] memory){
        string[3] memory statsStr;
        for(uint8 i; i<3;i++){
            statsStr[i] = Strings.toString(nft.getStat(stats[0], tokenId));
        }
        return statsStr;
}
    
    function toHexString(uint24 value, uint8 length)
        internal
        pure
        returns (string memory)
    {
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
        return string(abi.encodePacked("#",string(buffer)));
    }

    function svgHeader() internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "<defs>",
                    "<style type='text/css'>",
                    "@font-face {font-family: 'Arial';font-variant: normal;font-style: normal;font-weight: normal;src: url('#FontID2') format(svg);}",
                    "@font-face {font-family: 'Arial';font-variant: normal;font-style: normal;font-weight: bold;src: url('#FontID1') format(svg);}",
                    "@font-face {font-family: 'Helvetica';font-variant: normal;font-weight: bold;src: url('#FontID0') format(svg);}",
                    "</style>",
                    "<clipPath id='id0'>",
                    "<path d='M434.84 69.35l3263.62 0c201.01,0 365.48,164.47 365.48,365.44l0 4960.67 -3994.58 0 0 -4960.67c0,-200.99 164.47,-365.44 365.48,-365.44z'/>",
                    "</clipPath>",
                    "<clipPath id='id1'>",
                    "<path d='M434.84 69.35l3263.62 0c201.01,0 365.48,164.47 365.48,365.44l0 4960.67 -3994.58 0 0 -4960.67c0,-200.99 164.47,-365.44 365.48,-365.44z'/>",
                    "</clipPath>",
                    "<clipPath id='id2'>",
                    "<path d='M434.84 69.35l3263.62 0c201.01,0 365.48,164.47 365.48,365.44l0 4960.67 -3994.58 0 0 -4960.67c0,-200.99 164.47,-365.44 365.48,-365.44z'/>",
                    "</clipPath>",
                    "</defs>"
                )
            );
    }

    function svgImageBorder(string memory itemImage, string memory powerColor)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "<g style='clip-path:url(#id0)'>",
                        "<g style='clip-path:url(#id1)'>",
                            "<image x='57.68' y='69.35' width='4017.92' height='5362.73' preserveAspectRatio='xMidYMid slice' href='",
                            itemImage,
                            "' />",
                        "</g>",
                        "<g style='clip-path:url(#id2)'>",
                            "<path style='fill:#111111; fill-opacity:0.5;' d='M135.75 5412.11l3861.78 0 0 -841.06c0,-128.02 -104.74,-232.75 -232.75,-232.75l-3396.28 0c-128.02,0 -232.75,104.74 -232.75,232.75l0 841.06z'/>",
                        "</g>",
                    "</g>",
                    // <border>
                    "<path style='stroke:",
                    powerColor,
                    "; stroke-width:100; stroke-linecap:round; stroke-linejoin:round; stroke-miterlimit:2.61313; text-align:center; align-items:center; fill:none;' d='M434.84 69.35l3263.62 0c201.01,0 365.48,164.47 365.48,365.44l0 4960.67 -3994.58 0 0 -4960.67c0,-200.99 164.47,-365.44 365.48,-365.44z' />"
                    // </border>

                )
            );
    }

    function svgName(string memory powerColor,string memory textColor, string memory name)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(

                    // <name background>
                    "<rect style='fill:",
                    powerColor,
                    ";' x='566.64' y='4114.1' width='3000' height='426.26' rx='50' ry='50' />"
                    // </name background>
                    // <name text>
                    "<text x='50%' y='4350' dominant-baseline='middle' text-anchor='middle' font-size='20' style='fill:",
                    textColor,
                    "; font-size:226.29px; font-family:Helvetica; font-weight:bold;' >",
                    name,
                    "</text>"
                    // </name text>

                )
            );
    }

    function svgPowerLevel(string memory _powerLevel) internal pure returns (string memory) {
        return string(abi.encodePacked(                    
            // <power level>
            "<g>",
            "<circle id='myCircle' cx='80%' cy='90%' r='300' fill='#111111;' opacity='0.5'/>",
            "<text class='centered-text' fill='#eeeeee' style='dominant-baseline:middle; text-anchor:middle' x='80%' y='90.5%' font-size='280' font-family='Arial' font-weight='bold' >",
            _powerLevel,
            "</text>"
            // </power level>
        ));
    }

    function svgStatDisplay(StatDisplay memory data ) internal pure returns (string memory) { 
        return string(abi.encodePacked(                   
            // <stat1>
            "<text x='",
            data.valuePos,
            "' y='4945.63' style='fill:#eeeeee; font-size:265.03px; font-family:Arial; font-weight:bold;' >",
            data.value,
            "</text>",
            // </stat1>

            // <stat1 label>
            "<text x='",
            data.labelPos,
            "' y='5149.19' style='fill:#eeeeee; font-size:192.54px; font-family:Arial; font-weight:normal;' >",
            data.label,
            "</text>"
            // </stat1 label>
        ));
    }
}
