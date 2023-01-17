class MaterialType : Thinker abstract {
    static void Populate() {
        for (int i = 0; i < AllClasses.Size(); i++) {
            let clazz = AllClasses[i];

            if (!(class<MaterialType>)(clazz) || clazz.IsAbstract()) {
                continue;
            }

            let materialType = MaterialType(new(clazz));
            materialType.ChangeStatNum(STAT_STATIC);
            materialType.InitMaterials();
        }
    }

    protected abstract void InitMaterials();
}

class Material : Thinker {
    string m_name;

    // The average number of kills required for the material to drop.
    float m_rarity;

    // Whether to use a or an with this material's name.
    bool m_an;

    virtual void Init(string name, float rarity, bool an = false) {
        m_name = name;
        m_rarity = rarity;
        m_an = an;
        ChangeStatNum(STAT_STATIC);
    }

    clearscope virtual bool InStock(MidgetPlayer player, int required) {
        return GetCount(player) >= required;
    }

    clearscope virtual int GetCount(MidgetPlayer player) {
        return player.m_materials.Count(self);
    }
}

class MTBasic : MaterialType {
    override void InitMaterials() {
        new("Material").Init("Wooden Stick", 3.0);
        new("Material").Init("Rock", 4.0);
        new("Material").Init("Iron Bar", 12.0, true);
    }
}

class WeaponMaterial : Material {
    class<Weapon> m_weapon;

    override bool InStock(MidgetPlayer player, int required) {
        return GetCount(player) > 0;
    }

    override int GetCount(MidgetPlayer player) {
        return player.CountInv(m_weapon);
    }
}

class MTWeapon : MaterialType {
    override void InitMaterials() {
        for (int i = 0; i < AllClasses.Size(); i++) {
            let cls = AllClasses[i];
            class<Weapon> clsW;

            if (!(clsW = (class<Weapon>)(cls)) || cls.IsAbstract()) {
                continue;
            }

            array<MaterialCount> tmp;
            let weaponName = RTWeapon.GetWeaponMaterials(clsW, tmp);

            let material = new("WeaponMaterial");
            material.Init(weaponName, -1.0);
            material.m_weapon = clsW;
        }
    }
}
