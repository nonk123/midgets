class MaterialPickup : CustomInventory {
    Material m_material;

    override string PickupMessage() {
        return "You got a " .. m_material.m_name .. "!";
    }

    States {
        Spawn:
            CHST A -1;
            Stop;
        Pickup:
            TNT1 A 0 {
                let ownr = MidgetPlayer(invoker.owner);

                if (ownr) {
                    ownr.AddMaterial(invoker.m_material, 1);
                }
            }
            Stop;
    }
}
