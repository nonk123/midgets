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
    OptionMenuItemPlaceRecipesBelow m_recipes;

    bool m_bCanCraft;

    override void Init(Menu parent, OptionMenuDescriptor root) {
        super.Init(parent, root);

        m_root = root;

        m_required = OptionMenuItemMultilineStaticText(GetItem("RequiredMaterials"));
        m_owned = OptionMenuItemMultilineStaticText(GetItem("OwnedMaterials"));
        m_canCraft = OptionMenuItemCanCraft(GetItem("CanCraft"));
        m_recipes = OptionMenuItemPlaceRecipesBelow(GetItem("PlaceRecipesBelow"));
    }

    int GetBottommostHeaderItemIdx() {
        return m_root.mItems.Find(m_recipes);
    }

    Recipe GetSelectedRecipe() {
        let recipeItemIdx = m_root.mSelectedItem;

        if (recipeItemIdx < 0 || recipeItemIdx >= m_root.mItems.Size()) {
            return null;
        }

        let recipeItem = OptionMenuItemRecipe(m_root.mItems[recipeItemIdx]);

        if (!recipeItem) {
            return null;
        }

        let it = ThinkerIterator.Create("Recipe", Thinker.STAT_STATIC);
        Recipe recipe;

        for (int i = 0; i <= recipeItem.m_recipeIdx; i++) {
            recipe = Recipe(it.Next());
        }

        return recipe;
    }

    void UpdateMaterials() {
        let playerInfo = players[consolePlayer];
        let player = MidgetPlayer(playerInfo.mo);

        let materialsList = "";

        if (player) {
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
        } else {
            materialsList = "You're dead!";
        }

        m_owned.mLabel = materialsList;
        materialsList = "";

        let selectedRecipe = GetSelectedRecipe();

        if (!selectedRecipe) {
            m_required.mLabel = "No recipe selected";
            return;
        }

        let recipesIt = ThinkerIterator.Create("Recipe", Thinker.STAT_STATIC);
        Recipe recipe;

        while (recipe = Recipe(recipesIt.Next())) {
            if (recipe != selectedRecipe) {
                continue;
            }

            m_bCanCraft = true;

            for (int i = 0; i < recipe.m_materials.m_materials.Size(); i++) {
                let requiredMaterialCount = recipe.m_materials.m_materials[i];
                let requiredMaterial = requiredMaterialCount.m_material;

                materialsList = materialsList .. requiredMaterialCount.FormatLn();

                if (!player) {
                    m_bCanCraft = false;
                    continue;
                }

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

    bool UpdateLayout() {
        UpdateMaterials();

        for (int i = 0; i < m_root.mItems.Size(); i++) {
            if (m_root.mItems[i] is "OptionMenuItemMultilineStaticText") {
                let item = OptionMenuItemMultilineStaticText(m_root.mItems[i]);
                item.UpdateLines();
            }
        }

        let wasDirty = m_recipes.m_isDirty;
        m_recipes.Populate();

        return wasDirty;
    }

    override void Ticker() {
        let recipesWasDirty = UpdateLayout();

        super.Ticker();

        let old = m_root.mScrollTop;
        m_root.mScrollTop = GetBottommostHeaderItemIdx() + 1;

        if (recipesWasDirty) {
            m_root.mSelectedItem = m_root.mScrollTop;
        } else {
            m_root.mSelectedItem += m_root.mScrollTop - old;
        }
    }
}

class OptionMenuItemPlaceRecipesBelow : OptionMenuItem {
    array<OptionMenuItemRecipe> m_recipes;
    bool m_isDirty;

    void Init() {
        mCentered = true;
        mAction = "PlaceRecipesBelow";
        m_isDirty = true;
    }

    protected void PopulateImpl() {
        let menu = CraftingMenu(Menu.GetCurrentMenu());

        for (int i = m_recipes.Size() - 1; i >= 0; i--) {
            let idx = menu.m_root.mItems.Find(m_recipes[i]);
            menu.m_root.mItems.Delete(idx);
            m_recipes.Delete(i);
        }

        let start = menu.m_root.mItems.Find(self);
        let offset = 1;

        let it = ThinkerIterator.Create("Recipe", Thinker.STAT_STATIC);
        Recipe recipe;

        for (int i = 0; recipe = Recipe(it.Next()); i++) {
            if (recipe.GetClassName() != "Recipe") {
                let item = new("OptionMenuItemRecipe");
                item.Init(i);

                menu.m_root.mItems.Insert(start + offset, item);
                m_recipes.Push(item);

                offset++;
            }
        }
    }

    void Populate() {
        if (m_isDirty) {
            PopulateImpl();
            m_isDirty = false;
        }
    }

    override bool Selectable() {
        return false;
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
            menu.m_root.mItems.Delete(ourIdx + 1 + i);
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
        mAction = "RequiredMaterials";
    }
}

class OptionMenuItemOwnedMaterials : OptionMenuItemMultilineStaticText {
    void Init() {
        super.Init();
        mAction = "OwnedMaterials";
    }
}

class OptionMenuItemCanCraft: OptionMenuItemStaticText {
    void Init() {
        super.Init("");
        mAction = "CanCraft";
    }
}
