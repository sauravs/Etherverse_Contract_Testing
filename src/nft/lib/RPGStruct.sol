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
