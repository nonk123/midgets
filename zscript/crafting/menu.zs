class CraftingMenuEventHandler : EventHandler {
    override void NetworkProcess(ConsoleEvent event) {
        if (event.isManual || event.player < 0) {
            return;
        }

        if (event.name != "craft" || !event.args[1]) {
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
    bool m_recipesPopulated;

    OptionMenuItemMultilineStaticText m_required;
    OptionMenuItemMultilineStaticText m_owned;
    OptionMenuItemCanCraft m_canCraft;

    array<OptionMenuItemRecipe> m_recipes;
    bool m_bCanCraft;

    override void Init(Menu parent, OptionMenuDescriptor root) {
        super.Init(parent, root);

        m_root = root;

        m_required = OptionMenuItemMultilineStaticText(GetItem("RequiredMaterials"));
        m_owned = OptionMenuItemMultilineStaticText(GetItem("OwnedMaterials"));
        m_canCraft = OptionMenuItemCanCraft(GetItem("CanCraft"));

        UpdateLayout();
    }

    int GetSelectedRecipeIdx() {
        return m_root.mSelectedItem - m_root.mItems.Find(m_canCraft) - 3;
    }

    Recipe GetSelectedRecipe() {
        let it = ThinkerIterator.Create("Recipe", Thinker.STAT_STATIC);
        Recipe recipe;

        for (int i = 0; i <= GetSelectedRecipeIdx(); i++) {
            recipe = Recipe(it.Next());
        }

        return recipe;
    }

    void UpdateLayout() {
        let recipesBegin = m_root.mItems.Find(m_canCraft) + 3;

        if (m_root.mItems.Size() <= recipesBegin) {
            let it = ThinkerIterator.Create("Recipe", Thinker.STAT_STATIC);
            Recipe recipe;

            for (int i = 0; recipe = Recipe(it.Next()); i++) {
                if (recipe.GetClassName() != "Recipe") {
                    let item = new("OptionMenuItemRecipe");
                    item.Init(i);
                    m_root.mItems.Push(item);
                }
            }

            m_root.mSelectedItem = -1;
        }

        let playerInfo = players[consolePlayer];
        let player = MidgetPlayer(playerInfo.mo);

        if (!player) {
            return;
        }

        let materialsList = "";

        for (int i = 0; i < player.m_materials.m_materials.Size(); i++) {
            let materialCount = player.m_materials.m_materials[i];
            materialsList = materialsList .. materialCount.FormatLn();
        }

        if (materialsList) {
            // Get rid of the trailing newline.
            materialsList.DeleteLastCharacter();
        } else {
            materialsList = "None. You're poor!";
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
                let requiredMaterialCount = recipe.m_materials.m_materials[i];
                let requiredMaterial = requiredMaterialCount.m_material;

                materialsList = materialsList .. requiredMaterialCount.FormatLn();

                let materialFound = false;

                for (int j = 0; j < player.m_materials.m_materials.Size(); j++) {
                    let playerMaterialCount = player.m_materials.m_materials[j];
                    let playerMaterial = playerMaterialCount.m_material;

                    if (playerMaterial != requiredMaterial) {
                        continue;
                    }

                    materialFound = true;

                    if (playerMaterialCount.m_count < requiredMaterialCount.m_count) {
                        m_bCanCraft = false;
                        break;
                    }
                }

                if (!materialFound) {
                    m_bCanCraft = false;
                }
            }

            m_canCraft.mLabel = m_bCanCraft ? "Press Enter to craft" : "Not enough materials to craft";
        }

        // Get rid of the trailing newline.
        if (materialsList) {
            materialsList.DeleteLastCharacter();
        }

        m_required.mLabel = materialsList;
    }

    override void Ticker() {
        UpdateLayout();

        for (int i = 0; i < m_root.mItems.Size(); i++) {
            if (m_root.mItems[i] is "OptionMenuItemMultilineStaticText") {
                let item = OptionMenuItemMultilineStaticText(m_root.mItems[i]);
                item.UpdateLines();
            }
        }

        super.Ticker();

        let old = m_root.mScrollTop;
        m_root.mScrollTop = m_root.mItems.Find(m_canCraft) + 4;

        m_root.mSelectedItem += m_root.mScrollTop - old;
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

    override bool Activate() {
        let menu = CraftingMenu(Menu.GetCurrentMenu());
        EventHandler.SendNetworkEvent("craft", m_recipeIdx, menu.m_bCanCraft);
        return true;
    }
}

class OptionMenuItemMultilineStaticText : OptionMenuItemStaticText {
    array<OptionMenuItemStaticText> m_emptyLinesBelow;

    void Init(string text = "") {
        super.Init(text);
    }

    void UpdateLines() {
        let menu = CraftingMenu(Menu.GetCurrentMenu());
        let ourIdx = menu.m_root.mItems.Find(self);

        array<string> lines;
        mLabel.Split(lines, "\n");

        if (lines.Size() > 0) {
            mLabel = lines[0];
        }

        for (int i = m_emptyLinesBelow.Size() - 1; i >= 0; i--) {
            menu.m_root.mItems.Delete(ourIdx + i + 1);
            m_emptyLinesBelow.Delete(i);
        }

        for (int i = 0; i < lines.Size() - 1; i++) {
            let line = new("OptionMenuItemStaticText");
            line.Init(lines[i + 1]);

            menu.m_root.mItems.Insert(ourIdx + i + 1, line);
            m_emptyLinesBelow.Push(line);
        }
    }
}

class OptionMenuItemRequiredMaterials : OptionMenuItemMultilineStaticText {
    void Init() {
        super.Init();
    }

    override Name, int GetAction() {
        return "RequiredMaterials", 0;
    }
}

class OptionMenuItemOwnedMaterials : OptionMenuItemMultilineStaticText {
    void Init() {
        super.Init();
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
