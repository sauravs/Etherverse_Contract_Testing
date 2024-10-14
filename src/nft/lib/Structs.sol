// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

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
        SpecialItem,
        Misc
    }
    enum StatType {
        STR,
        DEX,
        CON,
        WIS,
        CHA,
        INT
    }
}


interface Upgrade {   
    enum Type {
        Free,
        Paid
    }
}

struct Price {
    uint256 amount;
    uint256 split;
}
