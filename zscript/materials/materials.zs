class Material : Thinker {
    string m_name;

    // The average number of kills required for the material to drop.
    float m_rarity;

    virtual void Init() {
    }

    static void Populate() {
        for (int i = 0; i < AllClasses.Size(); i++) {
            let clazz = AllClasses[i];

            if ((class<Material>)(clazz) && clazz != "Material") {
                let material = Material(new(clazz));
                material.ChangeStatNum(STAT_STATIC);
                material.Init();
            }
        }
    }
}

class MatWoodenStick : Material {
    override void Init() {
        m_name = "Wooden stick";
        m_rarity = 3.0;
    }
}

class MatIronBar : Material {
    override void Init() {
        m_name = "Bar of iron";
        m_rarity = 12.0;
    }
}

class MatRock : Material {
    override void Init() {
        m_name = "Rock";
        m_rarity = 4.0;
    }
}
