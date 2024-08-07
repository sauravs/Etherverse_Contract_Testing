    
    interface Asset {
    struct Stat {
        uint8 stat1;
        uint8 stat2;
        uint8 stat3;
    }

    enum Type {
        Weapon,
        Armor,
        Character,
        SpecialItem
    }
    enum StatType {
        STR,
        DEX,
        CON,
        WIS,
        CHR,
        INT
    }
}

interface Upgrade {
    enum Type {
        Free,
        Paid
    }
}

       
       
       
        mapping(uint256 => Asset.Stat) public upgradeMapping;



    function freeUpgrade(
        uint256 tokenId //@tester: if token minted check is here,then their is no need of isWhitelisted modifier,because only whitelisted user can mint
    ) external isWhitelisted(msg.sender) isTokenMinted(tokenId) isUnlocked(tokenId) {
        upgradeMapping[tokenId] = _getUpgradeModule(msg.sender).calculateUpgrade(upgradeMapping[tokenId], 2);
    }


     function _getUpgradeModule(address _address) internal view returns (IUpgradeV1) {
        return IUpgradeV1(IGame(_address).upgradeAddress());
    }


      function calculateUpgrade(Asset.Stat memory _stat, uint8 _increment) external returns (Asset.Stat memory) {
        bytes32 hash = RPGUtil._generateStatHash(_stat);
        Asset.Stat memory newStat = newStatMap[hash];
        if (RPGUtil.isEmptyStat(newStat)) {
            newStat = calculateStat(_stat, _increment);
            newStatMap[hash] = newStat;
        }
        return newStat;
    }

    
    function isEmptyStat(Asset.Stat memory newStat) internal pure returns (bool) {
        return newStat.stat1 == 0 && newStat.stat2 == 0 && newStat.stat3 == 0;
    }

interface IGame {
    function upgradeAddress() external view returns (address);
}

interface IUpgradeV1 {
    function calculateUpgrade(Asset.Stat memory _stat, uint8 _increment) external returns (Asset.Stat memory);

    function calculateStat(Asset.Stat memory _stat, uint8 _increment) external pure returns (Asset.Stat memory);

    function getStat(Asset.StatType statLabel, uint256 tokenId) external view returns (uint8 stat);

    function calculatePrice(uint256 BASE_PRICE_IN_USDC, Asset.Stat memory _stat) external pure returns (uint256);
}




