const SCRAP_MATERIAL_MULTIPLIER = 0.6;

class Recipe : Thinker {
    RecipeType m_type;
    string m_name;
    MaterialsList m_materials;
    class<Inventory> m_resultingItem;
    sound m_craftSound;

    ui bool m_wasDisplayed;

    virtual void Init(string name, class<Inventory> resultingItem) {
        m_materials = new("MaterialsList");
        m_name = name;
        m_resultingItem = resultingItem;
        m_craftSound = "misc/assembly";
        ChangeStatNum(STAT_STATIC);
    }

    bool Craft(MidgetPlayer player) {
        if (CanCraft(player)) {
            TakeMaterials(player);
            GiveResult(player);

            return true;
        }

        return false;
    }

    virtual void TakeMaterials(MidgetPlayer player) {
        for (int i = 0; i < m_materials.m_materials.Size(); i++) {
            let materialCount = m_materials.m_materials[i];
            player.m_materials.Take(materialCount.m_material, materialCount.m_count);
        }
    }

    virtual void GiveResult(MidgetPlayer player) {
        player.GiveInventoryType(m_resultingItem);
    }

    clearscope virtual bool CanCraft(MidgetPlayer player) {
        for (int i = 0; i < m_materials.m_materials.Size(); i++) {
            let requiredMaterialCount = m_materials.m_materials[i];
            let requiredMaterial = requiredMaterialCount.m_material;

            if (!requiredMaterial.InStock(player, requiredMaterialCount.m_count)) {
                return false;
            }
        }

        return true;
    }

    ui virtual string GetRequiredText() {
        return "Materials required:";
    }

    ui bool Display(MidgetPlayer player) {
        let result = ShouldDisplay(player);

        if (result) {
            m_wasDisplayed = true;
        }

        return result;
    }

    ui virtual bool ShouldDisplay(MidgetPlayer player) {
        return true;
    }

    ui bool WasDisplayed() {
        let tmp = m_wasDisplayed;
        m_wasDisplayed = false;
        return tmp;
    }

    void AddMaterial(Material material, int count = 1) {
        m_materials.Add(material, count);
    }
}

class NoRecipe : Recipe {
    override bool CanCraft(MidgetPlayer player) {
        return false;
    }
}

class RecipeType : Thinker abstract {
    static void Populate() {
        let noRecipe = new("NoRecipe");
        noRecipe.Init("No recipes available in this category", "Inventory");

        for (int i = 0; i < AllClasses.Size(); i++) {
            let cls = AllClasses[i];

            if (!(class<RecipeType>)(cls) || cls.IsAbstract()) {
                continue;
            }

            let it = ThinkerIterator.Create("Recipe", STAT_STATIC);
            let start = 0;

            for (; it.Next(); start++) {
            }

            let recipeType = RecipeType(new(cls));
            recipeType.ChangeStatNum(STAT_STATIC);
            recipeType.InitRecipes();

            it = ThinkerIterator.Create("Recipe", STAT_STATIC);
            Recipe recipe;

            for (int i = 0; recipe = Recipe(it.Next()); i++) {
                if (i >= start) {
                    recipe.m_type = recipeType;
                }
            }
        }
    }

    protected abstract void InitRecipes();

    ui abstract string GetCategoryName();
}

class WeaponRecipe : Recipe {
    override bool ShouldDisplay(MidgetPlayer player) {
        return player.CountInv(m_resultingItem) == 0;
    }
}

class RTWeapon: RecipeType {
    static String GetWeaponMaterials(class<Weapon> cls, out array<MaterialCount> materials) {
        let cVarName = "mdgt_weaponrecipe_" .. cls.GetClassName();
        let cv = CVar.GetCVar(cVarName);

        if (!cv) {
            return "";
        }

        cv.ResetToDefault();
        let value = cv.GetString();

        array<string> components;
        value.Split(components, ":");

        if (components.Size() % 2 == 0 || components.Size() < 3) {
            Console.PrintF("Incorrect format for " .. cVarName);
            return "";
        }

        let weaponName = components[0];

        for (int i = 1; i < components.Size(); i += 2) {
            let count = components[i].ToInt();
            let matName = components[i + 1];

            let it = ThinkerIterator.Create("Material", STAT_STATIC);
            Material material;

            while (material = Material(it.Next())) {
                if (material.m_name == matName) {
                    break;
                }
            }

            if (!material) {
                Console.PrintF("Warning: material not found: " .. matName);
                return "";
            }

            let materialCount = new("MaterialCount");
            materialCount.m_material = material;
            materialCount.m_count = count;
            materials.Push(materialCount);
        }

        return weaponName;
    }

    override void InitRecipes() {
        for (int i = 0; i < AllClasses.Size(); i++) {
            let cls = AllClasses[i];
            class<Weapon> clsW;

            if (!(clsW = (class<Weapon>)(cls)) || cls.IsAbstract()) {
                continue;
            }

            array<MaterialCount> materials;
            let weaponName = GetWeaponMaterials(clsW, materials);

            if (!weaponName) {
                continue;
            }

            let recipe = new("WeaponRecipe");
            recipe.Init(weaponName, clsW);

            for (int i = 0; i < materials.Size(); i++) {
                recipe.AddMaterial(materials[i].m_material, materials[i].m_count);
            }
        }
    }

    override string GetCategoryName() {
        return "Weapons";
    }
}

class DisassemblyRecipe : Recipe {
    string m_weaponName;

    override void Init(string weaponName, class<Inventory> resultingItem) {
        super.Init("Disassemble " .. weaponName, resultingItem);
        m_craftSound = "misc/disassembly";
    }

    override bool ShouldDisplay(MidgetPlayer player) {
        return CanCraft(player);
    }

    override bool CanCraft(MidgetPlayer player) {
        return player.CountInv(m_resultingItem) > 0;
    }

    override void TakeMaterials(MidgetPlayer player) {
        player.TakeInventory(m_resultingItem, 1);
    }

    override void GiveResult(MidgetPlayer player) {
        for (int i = 0; i < m_materials.m_materials.Size(); i++) {
            let materialCount = m_materials.m_materials[i];
            player.m_materials.Add(materialCount.m_material, materialCount.m_count);
        }
    }

    override string GetRequiredText() {
        return "Materials recovered:";
    }
}

class RTDisassembly : RecipeType {
    override void InitRecipes() {
        for (int i = 0; i < AllClasses.Size(); i++) {
            let cls = AllClasses[i];
            class<Weapon> clsW;

            if (!(clsW = (class<Weapon>)(cls)) || cls.IsAbstract()) {
                continue;
            }

            array<MaterialCount> materials;
            let weaponName = RTWeapon.GetWeaponMaterials(clsW, materials);

            if (!weaponName) {
                continue;
            }

            let recipe = DisassemblyRecipe(new("DisassemblyRecipe"));
            recipe.Init(weaponName, clsW);
            recipe.m_weaponName = weaponName;

            for (int i = 0; i < materials.Size(); i++) {
                let count = int(materials[i].m_count * SCRAP_MATERIAL_MULTIPLIER);
                recipe.AddMaterial(materials[i].m_material, count);
            }
        }
    }

    override string GetCategoryName() {
        return "Disassembly";
    }
}
