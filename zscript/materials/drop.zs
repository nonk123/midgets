class DropMaterials : EventHandler {
    override void WorldThingDied(WorldEvent event) {
        if (!event.thing || !event.thing.bIsMonster) {
            return;
        }

        let materialsIt = ThinkerIterator.Create("Material", Thinker.STAT_STATIC);
        Material material;

        while (material = Material(materialsIt.Next())) {
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
