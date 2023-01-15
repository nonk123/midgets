class DropMaterials : EventHandler {
    override void WorldThingDied(WorldEvent event) 
    {
        if (!event.thing || !event.thing.bIsMonster) {
            return;
        }
        
        let materials = Materials.Get();

        for (int i = 0; i < materials.m_list.Size(); i++) {
            let material = materials.m_list[i];

            let probability = 1.0 / material.m_rarity;
            let result = FRandom[MaterialRng](0.0, 1.0);

            if (result > probability) {
                continue;
            }

            let pickup = MaterialPickup(Actor.Spawn("MaterialPickup", event.thing.Pos));

            if (!pickup) {
                continue;
            }
            
            pickup.m_material = material;
        }
    }
}
