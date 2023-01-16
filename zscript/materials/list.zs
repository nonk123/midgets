class MaterialCount {
    Material m_material;
    int m_count;

    string Format() {
        return String.Format("x%d %s", m_count, m_material.m_name);
    }

    string FormatLn() {
        return Format() .. "\n";
    }
}

class MaterialsList : Thinker {
    array<MaterialCount> m_materials;

    int Count(Material material) {
        for (int i = 0; i < m_materials.Size(); i++) {
            let materialCount = m_materials[i];

            if (materialCount.m_material == material) {
                return materialCount.m_count;
            }
        }

        return -1;
    }

    bool Contains(Material material) {
        return Count(material) != -1;
    }

    void Add(Material material, int count = 1) {
        for (int i = 0; i < m_materials.Size(); i++) {
            let materialCount = m_materials[i];

            if (materialCount.m_material == material) {
                materialCount.m_count += count;

                if (materialCount.m_count <= 0) {
                    m_materials.Delete(i);
                }

                return;
            }
        }

        if (count > 0) {
            let materialCount = new("MaterialCount");
            materialCount.m_material = material;
            materialCount.m_count = count;
            m_materials.Push(materialCount);
        }
    }

    void Take(Material material, int count) {
        Add(material, -count);
    }

    void Remove(Material material) {
        for (int i = 0; i < m_materials.Size(); i++) {
            let materialCount = m_materials[i];

            if (materialCount.m_material == material) {
                m_materials.Delete(i);
                return;
            }
        }
    }
}
