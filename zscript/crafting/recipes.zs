class Recipe : Thinker {
    string m_name;
    MaterialsList m_materials;

    virtual void Init() {
    }

    void AddMaterial(class<Material> material_class, int count = 1) {
        let it = ThinkerIterator.Create(material_class, STAT_STATIC);
        let material = Material(it.Next());

        if (!material) {
            Console.PrintF("Warning: failed to get material %s", material_class.GetClassName());
            return;
        }

        m_materials.Add(material, count);
    }

    virtual RecipeOutput Craft() {
        return new("RecipeOutput");
    }

    static void Populate() {
        for (int i = 0; i < AllClasses.Size(); i++) {
            let clazz = AllClasses[i];

            if ((class<Recipe>)(clazz) && clazz != "Recipe") {
                let recipe = Recipe(new(clazz));
                recipe.m_materials= new("MaterialsList");
                recipe.ChangeStatNum(STAT_STATIC);
                recipe.Init();
            }
        }
    }
}

class RecipeOutput {
    class<Weapon> m_weapon;

    static RecipeOutput Weapon(class<Weapon> weapon) {
        let output = new("RecipeOutput");
        output.m_weapon = weapon;
        return output;
    }

    play void Give(MidgetPlayer player) {
        if (m_weapon) {
            player.GiveInventoryType(m_weapon);
        }
    }
}

class RecipeTest1 : Recipe {
    override void Init() {
        m_name = "Test1";
        AddMaterial("MatWoodenStick", 1);
    }

    override RecipeOutput Craft() {
        return RecipeOutput.Weapon("Pistol");
    }
}

class RecipeTest2 : Recipe {
    override void Init() {
        m_name = "Test2";
        AddMaterial("MatRock", 2);
    }

    override RecipeOutput Craft() {
        return RecipeOutput.Weapon("Shotgun");
    }
}
