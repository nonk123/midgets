class CraftingMenuEventHandler : EventHandler {
    override void NetworkProcess(ConsoleEvent event) {
        if (event.isManual || event.player < 0) {
            return;
        }

        if (event.name != "craft") {
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

        if (recipe && recipe.CanCraft(player)) {
            recipe.TakeMaterials(player);
            recipe.GiveResult(player);
        }
    }
}

class CraftingMenu : GenericMenu {
    BaseStatusBar m_hud;

    int m_selectedRecipeIdx;
    int m_selectedRecipeTypeIdx;

    string m_ownedMaterials;

    string m_requiredText;
    string m_requiredMaterials;

    string m_canCraft;

    string m_category;
    array<Recipe> m_recipes;

    override void Init(Menu parent) {
        super.Init(parent);

        m_hud = StatusBar;

        m_selectedRecipeIdx = 0;
        m_selectedRecipeTypeIdx = 0;
    }

    MidgetPlayer, bool GetPlayer() {
        let player = m_hud.cPlayer;
        let isUs = player == players[consolePlayer];
        return MidgetPlayer(player.mo), isUs;
    }

    Recipe GetSelectedRecipe() {
        if (m_recipes.Size() == 0) {
            return Recipe.GetEmpty();
        }

        if (m_selectedRecipeIdx < 0) {
            m_selectedRecipeIdx = m_recipes.Size() - 1;
        }

        if (m_selectedRecipeIdx >= m_recipes.Size()) {
            m_selectedRecipeIdx = 0;
        }

        return m_recipes[m_selectedRecipeIdx];
    }

    RecipeType GetSelectedRecipeType() {
        let it = ThinkerIterator.Create("RecipeType", Thinker.STAT_STATIC);
        RecipeType type;

        int i = 0;

        for (; type = RecipeType(it.Next()); i++) {
            if (i == m_selectedRecipeTypeIdx) {
                return type;
            }
        }

        if (m_selectedRecipeTypeIdx < 0) {
            m_selectedRecipeTypeIdx = i - 1;
        } else {
            m_selectedRecipeTypeIdx = 0;
        }

        return GetSelectedRecipeType();
    }

    static void SplitLines(string text, in out array<string> lines) {
        text.Split(lines, "\n");

        if (lines.Size() > 0 && !lines[lines.Size() - 1]) {
            lines.Pop();
        }
    }

    void UpdateMaterials() {
        let player = GetPlayer();

        let materialsList = "";

        if (player) {
            for (int i = 0; i < player.m_materials.m_materials.Size(); i++) {
                let materialCount = player.m_materials.m_materials[i];
                materialsList = materialsList .. materialCount.FormatLn();
            }

            if (!materialsList) {
                materialsList = "None. You're poor!";
            }
        } else {
            m_ownedMaterials = "You're dead!";
            m_canCraft = "The dead can't craft";
            GetSelectedRecipe(); // update the selection indices anyway
            return;
        }

        m_ownedMaterials = materialsList;

        materialsList = "";

        let selectedRecipe = GetSelectedRecipe();

        if (selectedRecipe.GetIndex() == 0) {
            m_requiredMaterials = "No recipe selected";
            m_canCraft = "";
            return;
        }

        m_requiredText = selectedRecipe.GetRequiredText();

        for (int i = 0; i < selectedRecipe.m_materials.m_materials.Size(); i++) {
            let requiredMaterialCount = selectedRecipe.m_materials.m_materials[i];
            materialsList = materialsList .. requiredMaterialCount.FormatLn();
        }

        m_requiredMaterials = materialsList;

        let canCraft = player && selectedRecipe.CanCraft(player);
        m_canCraft = canCraft ? "Press Enter to craft" : "Not enough materials to craft";
    }

    void PopulateRecipes() {
        m_recipes.Clear();

        let type = GetSelectedRecipeType();
        m_category = type.GetCategoryName();

        let it = ThinkerIterator.Create("Recipe", Thinker.STAT_STATIC);
        Recipe recipe;

        let player = GetPlayer();

        if (!player) {
            return;
        }

        bool isDirty = false;

        for (int i = 0; recipe = Recipe(it.Next()); i++) {
            if (player && recipe.m_type == type && recipe.Display(player)) {
                m_recipes.Push(recipe);
            } else if (recipe.WasDisplayed()) {
                isDirty = true;
            }
        }

        if (m_recipes.Size() == 0) {
            m_recipes.Push(Recipe.GetEmpty());
        }

        if (isDirty) {
            m_selectedRecipeIdx = 0;
        }
    }

    override void Ticker() {
        super.Ticker();
        PopulateRecipes();
        UpdateMaterials();
    }

    override void Drawer() {
        super.Drawer();

        let ownedMaterials = new("ScreenColumn");
        ownedMaterials.Header("Owned materials:");

        array<string> lines;
        SplitLines(m_ownedMaterials, lines);

        let owned = new("ScreenColumn");

        for (int i = 0; i < lines.Size(); i++) {
            owned.Normal(lines[i]);
        }

        let requiredMaterials = new("ScreenColumn");
        requiredMaterials.Header(m_requiredText);

        lines.Clear();
        SplitLines(m_requiredMaterials, lines);

        let required = new("ScreenColumn");

        for (int i = 0; i < lines.Size(); i++) {
            required.Normal(lines[i]);
        }

        required.Space();

        let selectedRecipe = GetSelectedRecipe();
        let player = GetPlayer();

        let chooseARecipe = new("ScreenColumn");
        chooseARecipe.Header("Choose a recipe:");

        let category = new("ScreenColumn");
        category.Important("◀ " .. m_category .. " ▶");

        let recipes = new("ScreenColumn");

        for (int i = 0; i < m_recipes.Size(); i++) {
            let recipe = m_recipes[i];

            if (recipe == Recipe.GetEmpty()) {
                recipes.Important(recipe.m_name);
            } else {
                let prefix = recipe == selectedRecipe ? "-> " : "   ";
                let suffix = "   ";

                let color = recipe.CanCraft(player) ? Font.CR_GRAY : Font.CR_RED;

                recipes.Normal(prefix .. recipe.m_name .. suffix, color);
            }
        }

        let canCraft = new("ScreenColumn");
        let canCraftColor = selectedRecipe.CanCraft(player) ? Font.CR_GREEN : Font.CR_RED;
        canCraft.Important(m_canCraft, canCraftColor);

        requiredMaterials.Draw(0.0, 0.0, 0.5);
        required.Draw(0.0, 0.05, 0.5);

        ownedMaterials.Draw(0.0, 0.3, 0.5);
        owned.Draw(0.0, 0.35, 0.5);

        canCraft.Draw(0.0, 0.85, 1.0);

        chooseARecipe.Draw(0.5, 0.0, 0.5);
        category.Draw(0.5, 0.05, 0.5);
        recipes.Draw(0.5, 0.09, 0.5);
    }

    override bool MenuEvent(int menuKey, bool fromController) {
        let oldTypeIdx = m_selectedRecipeTypeIdx;
        let oldRecipeIdx = m_selectedRecipeIdx;

        switch (menuKey) {
        case MKEY_UP:
            m_selectedRecipeIdx--;
            break;
        case MKEY_DOWN:
            m_selectedRecipeIdx++;
            break;
        case MKEY_LEFT:
            m_selectedRecipeTypeIdx--;
            break;
        case MKEY_RIGHT:
            m_selectedRecipeTypeIdx++;
            break;
        case MKEY_ENTER:
            MidgetPlayer player;
            bool isUs;

            [player, isUs] = GetPlayer();

            if (!isUs) {
                break;
            }

            let recipe = GetSelectedRecipe();

            if (!recipe || !player || !recipe.CanCraft(player)) {
                MenuSound("menu/invalid");
                break;
            }

            EventHandler.SendNetworkEvent("craft", recipe.GetIndex());

            string sound = recipe.m_craftSound;
            MenuSound(sound);

            break;
        default:
            return super.MenuEvent(menuKey, fromController);
        }

        if (m_selectedRecipeTypeIdx != oldTypeIdx || m_selectedRecipeIdx != oldRecipeIdx) {
            MenuSound("menu/cursor");
        }

        return true;
    }
}

class ScreenColumn {
    const LINE_SPACING = 20.0;

    const WIDTH = 896;
    const HEIGHT = 504;

    array<ScreenLine> m_lines;

    void Add(string text, double scale, int color) {
        let line = new("ScreenLine");

        line.m_text = text;
        line.m_scale = scale;
        line.m_color = color;

        m_lines.Push(line);
    }

    void Normal(string text, int color = Font.CR_GRAY) {
        Add(text, 1.2, color);
    }

    void Header(string text, int color = Font.CR_RED) {
        Add(text, 2.5, color);
    }

    void Important(string text, int color = Font.CR_RED) {
        Add(text, 1.8, color);
    }

    void Space() {
        Add("", 1.0, Font.CR_UNTRANSLATED);
    }

    void Draw(double indent, double offset, double cWidth) {
        let sWidth = double(Screen.GetWidth());
        let sHeight = double(Screen.GetHeight());

        let ogAr = WIDTH / HEIGHT;
        let targetAr = sWidth / sHeight;

        double scale;

        if (targetAr > ogAr) {
            let barWidth = 0.5 * (sWidth - sHeight * ogAr);
            let vWidth = sWidth - 2.0 * barWidth;

            indent *= vWidth;
            indent += barWidth;

            cWidth *= vWidth;

            offset *= sHeight;

            scale = vWidth / WIDTH;
        } else {
            let barHeight = 0.5 * (sHeight - sWidth / ogAr);
            let vHeight = sHeight - 2.0 * barHeight;

            offset *= sHeight - 2.0 * barHeight;
            offset += barHeight;

            indent *= sWidth;
            cWidth *= sWidth;

            scale = vHeight / HEIGHT;
        }

        let font = newSmallFont;

        let maxWidth = 0;

        for (int i = 0; i < m_lines.Size(); i++) {
            let line = m_lines[i];
            let lineWidth = font.StringWidth(line.m_text) * line.m_scale * scale;
            maxWidth = Max(lineWidth, maxWidth);
        }

        indent += 0.5 * (cWidth - maxWidth);

        for (int i = 0; i < m_lines.Size(); i++) {
            let line = m_lines[i];

            let lineHeight = LINE_SPACING * line.m_scale * scale;
            Screen.DrawText(font, line.m_color, indent, offset, line.m_text, DTA_ScaleX, line.m_scale * scale, DTA_ScaleY, line.m_scale * scale);

            offset += lineHeight;
        }
    }
}

class ScreenLine {
    string m_text;
    double m_scale;
    int m_color;
}
