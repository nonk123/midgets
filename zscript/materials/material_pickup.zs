class MaterialPickup : Inventory {
    Material m_material;

    override string PickupMessage() {
        return "You got a " .. m_material.m_name .. "!";
    }

    override void AttachToOwner(Actor other) {
        super.AttachToOwner(other);

        if (owner && owner is "MidgetPlayer") {
            let ownr = MidgetPlayer(owner);
            ownr.m_materials.Add(m_material);
            Destroy();
        }
    }

    States {
        Spawn:
            CHST A -1;
            Stop;
    }
}
