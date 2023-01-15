class Materials : Thinker {
    array<Material> m_list;
    
    static Materials Get() {
        let it = ThinkerIterator.Create("Materials", STAT_STATIC);

        let materials = Materials(it.Next());
        
        if (!materials) {
            array<Material> list;

            for (int i = 0; i < AllClasses.Size(); i++) {
                let clazz = AllClasses[i];

                if (!(class<Material>)(clazz)) {
                    continue;
                }

                let material = Material(new(clazz));
                material.Init();

                if (material.m_name != "Base" && material.m_rarity > 0.0) {
                    list.Push(material);
                }
            }

            materials = new("Materials");
            materials.m_list.Move(list);
            materials.ChangeStatNum(STAT_STATIC);
        }

        return materials;
    }
}

class Material {
    string m_name;
    
    // The average number of kills required for the material to drop.
    float m_rarity;

    virtual void Init() {
        m_name = "Base";
        m_rarity = 0.0;
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
        m_name = "Iron bar";
        m_rarity = 12.0;
    }
}

class MatRock : Material {
    override void Init() {
        m_name = "Rock";
        m_rarity = 4.0;
    }
}
