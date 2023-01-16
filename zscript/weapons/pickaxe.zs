class PickaxePuff : Actor {
    Default {
        +PuffOnActors
        +NoExtremeDeath
    }

    States {
        Spawn:
            PUFF A 4 Bright;
            PUFF B 4;
            PUFF CD 4;
            Stop;
    }
}

class Pickaxe : MidgetWeapon {
    Default {
        Weapon.Kickback 32;
        Inventory.PickupMessage "Strike the earth!";
        Obituary "%o was mined by %k";
        +Weapon.MeleeWeapon
        +Weapon.NoAlert
    }

    action void A_Mine() {
        A_CustomPunch(64, true, CPF_NORANDOMPUFFZ, "PickaxePuff", 64, 0.0, 0.0, "ArmorBonus", "weapons/pickaxe/hit");
    }

    States {
        Ready:
            PICK A 1 A_WeaponReady;
            Loop;
        Deselect:
            PICK A 1 A_Lower;
            Loop;
        Select:
            PICK A 1 A_Raise;
            Loop;
        Fire:
            PICK A 5 A_WeaponOffset(0.0, -16.0, WOF_ADD);
        Refire:
            PICK B 7 A_WeaponOffset(32.0, -32.0, WOF_ADD);
            PICK C 1 A_StartSound("weapons/pickaxe/swing", CHAN_WEAPON);
            #### # 6 A_WeaponOffset(-64.0, 80.0, WOF_ADD);
            #### # 1 A_Mine();
            #### # 3;
            #### # 4 A_WeaponOffset(16.0, -16.0, WOF_ADD);
            PICK A 5 A_WeaponOffset(16.0, -16.0, WOF_ADD);
            #### # 3;
            #### # 1 A_Refire();
            #### # 4;
            Goto Ready;
        Hold:
            #### # 2 A_WeaponOffset(0.0, -16.0, WOF_ADD);
            Goto Refire;
    }
}
