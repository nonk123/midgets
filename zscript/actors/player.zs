class MaterialCount {
    Material m_material;
    int m_count;
}

class MidgetPlayer : PlayerPawn {
    array<MaterialCount> m_materials;

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
    
    void AddMaterial(Material material, int count) {
        for (int i = 0; i < m_materials.Size(); i++) {
            let material_count = m_materials[i];

            if (material_count.m_material == material) {
                material_count.m_count += count;
                return;
            }
        }
        
        let material_count = new("MaterialCount");
        material_count.m_material = material;
        material_count.m_count = count;
        m_materials.Push(material_count);
    }
}
