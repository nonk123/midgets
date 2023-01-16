const ITEMS_IN_MENU = 13;

class CraftingMenuEventHandler : EventHandler {
    override void NetworkProcess(ConsoleEvent event) {
        if (event.isManual || event.player < 0) {
            return;
        }

        if (event.name != "craft") {
            return;
        }

        if (!event.args[1]) {
            return;
        }

        let playerInfo = players[event.player];

        if (!playerInfo) {
            return;
        }

        let player = MidgetPlayer(playerInfo.mo);

        if (!player) {
            return;
        }

        let it = ThinkerIterator.Create("Recipe", Thinker.STAT_STATIC);
        Recipe recipe;

        for (int i = 0; i <= event.args[0]; i++) {
            recipe = Recipe(it.Next());
        }

        for (int i = 0; i < recipe.m_materials.m_materials.Size(); i++) {
            let materialCount = recipe.m_materials.m_materials[i];
            player.m_materials.Take(materialCount.m_material, materialCount.m_count);
        }

        recipe.Craft().Give(player);
    }
}

class CraftingMenu : OptionMenu {
    OptionMenuDescriptor m_root;

    OptionMenuItemRequiredMaterials m_required;
    OptionMenuItemOwnedMaterials m_owned;
    OptionMenuItemCanCraft m_canCraft;

    array<OptionMenuItemRecipe> m_recipes;
    bool m_bCanCraft;

    override void Init(Menu parent, OptionMenuDescriptor root) {
        super.Init(parent, root);

        m_root = root;

        m_required = OptionMenuItemRequiredMaterials(GetItem("RequiredMaterials"));
        m_owned = OptionMenuItemOwnedMaterials(GetItem("OwnedMaterials"));
        m_canCraft = OptionMenuItemCanCraft(GetItem("CanCraft"));

        for (int i = root.mItems.Size() - 1; i >= ITEMS_IN_MENU - 1; i--) {
            root.mItems.Delete(i);
        }

        let it = ThinkerIterator.Create("Recipe", Thinker.STAT_STATIC);
        Recipe recipe;

        for (int i = 0; recipe = Recipe(it.Next()); i++) {
            if (recipe.GetClassName() != "Recipe") {
                let item = new("OptionMenuItemRecipe");
                item.Init(i);
                m_root.mItems.Push(item);
            }
        }
    }

    int GetSelectedRecipeIdx() {
        return m_root.mSelectedItem - ITEMS_IN_MENU + 1;
    }

    Recipe GetSelectedRecipe() {
        let it = ThinkerIterator.Create("Recipe", Thinker.STAT_STATIC);
        Recipe recipe;

        for (int i = 0; i <= GetSelectedRecipeIdx(); i++) {
            recipe = Recipe(it.Next());
        }

        return recipe;
    }

    override void Ticker() {
        super.Ticker();

        let playerInfo = players[consolePlayer];
        let player = MidgetPlayer(playerInfo.mo);

        if (!player) {
            return;
        }

        let materialsList = "";

        for (int i = 0; i < player.m_materials.m_materials.Size(); i++) {
            let materialCount = player.m_materials.m_materials[i];
            let material = materialCount.m_material;

            let name = material.m_name;
            let count = materialCount.m_count;

            let comma = i == 0 ? "" : ", ";
            materialsList.AppendFormat("%s%d %s", comma, count, name);
        }

        m_owned.mLabel = materialsList;
        materialsList = "";

        let recipesIt = ThinkerIterator.Create("Recipe", Thinker.STAT_STATIC);
        Recipe recipe;

        let selectedRecipe = GetSelectedRecipe();

        while (recipe = Recipe(recipesIt.Next())) {
            if (recipe != selectedRecipe) {
                continue;
            }

            m_bCanCraft = true;

            for (int i = 0; i < recipe.m_materials.m_materials.Size(); i++) {
                let materialCount = recipe.m_materials.m_materials[i];
                let material = materialCount.m_material;

                let name = material.m_name;
                let count = materialCount.m_count;

                materialsList.AppendFormat("%d %s\n", count, name);

                let materialFound = false;

                for (int j = 0; j < player.m_materials.m_materials.Size(); j++) {
                    let otherMaterialCount = player.m_materials.m_materials[j];
                    let otherMaterial = otherMaterialCount.m_material;

                    if (otherMaterial != material) {
                        continue;
                    }

                    materialFound = true;

                    if (otherMaterialCount.m_count < materialCount.m_count) {
                        m_bCanCraft = false;
                        break;
                    }
                }

                if (!materialFound) {
                    m_bCanCraft = false;
                    break;
                }
            }

            m_canCraft.mLabel = m_bCanCraft ? "Press Enter to craft" : "Not enough materials to craft";
        }

        m_required.mLabel = materialsList;
    }
}

class OptionMenuItemRecipe : OptionMenuItemSubmenu {
    int m_recipeIdx;

    void Init(int recipeIdx) {
        m_recipeIdx = recipeIdx;

        let it = ThinkerIterator.Create("Recipe", Thinker.STAT_STATIC);
        Recipe recipe;

        for (int i = 0; i <= m_recipeIdx; i++) {
            recipe = Recipe(it.Next());
        }

        super.Init(recipe.m_name, "", true);
    }

    override bool Selectable() {
        return true;
    }

    override bool Activate() {
        let menu = CraftingMenu(Menu.GetCurrentMenu());
        EventHandler.SendNetworkEvent("craft", m_recipeIdx, menu.m_bCanCraft);
        return true;
    }
}

class OptionMenuItemRequiredMaterials : OptionMenuItemStaticText {
    void Init() {
        super.Init("");
    }

    override Name, int GetAction() {
        return "RequiredMaterials", 0;
    }
}

class OptionMenuItemOwnedMaterials : OptionMenuItemStaticText {
    void Init() {
        super.Init("");
    }

    override Name, int GetAction() {
        return "OwnedMaterials", 0;
    }
}

class OptionMenuItemCanCraft: OptionMenuItemStaticText {
    void Init() {
        super.Init("");
    }

    override Name, int GetAction() {
        return "CanCraft", 0;
    }
}
