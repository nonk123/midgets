class MidgetPlayer : PlayerPawn {
    MaterialsList m_materials;

    Default {
        Speed 0.8;
        Health 100;
        Radius 18;
        Height 40;
        Mass 80;
        PainChance 255;
        Player.ViewHeight 30;
        Player.DisplayName "Midget";
        Player.StartItem "Pickaxe";
        Player.WeaponSlot 1, "Pickaxe";
    }

    override void BeginPlay() {
        m_materials = new("MaterialsList");
        super.BeginPlay();
    }

    bool PressingCraft() {
        return player.cmd.buttons & BT_USER1;
    }

    bool HoldingCraft() {
        return player.oldbuttons & BT_USER1;
    }

    override void Tick() {
        if (!player || !player.mo || player.mo != self) {
            Super.Tick();
            return;
        }

        if (PressingCraft() && !HoldingCraft()) {
            Menu.SetMenu("CraftingMenu");
        }

        Super.Tick();
    }

    override bool CanTouchItem(Inventory item) {
        if (!(item is "Weapon")) {
            return true;
        }

        let it = ThinkerIterator.Create("DisassemblyRecipe", STAT_STATIC);
        DisassemblyRecipe recipe;

        while (recipe = DisassemblyRecipe(it.Next())) {
            if (recipe.m_resultingItem == item.GetClassName()) {
                recipe.GiveResult(self);
                item.Destroy();

                A_Log("\cgDisassembled " .. recipe.m_weaponName);
                A_StartSound(recipe.m_craftSound, CHAN_ITEM);

                return false;
            }
        }

        return true;
    }
}
