class Q2AutoDocPickup extends Q2TechPickup;

auto state Pickup
{
	function Touch(Actor Other)
	{
		local Inventory Copy;
		local Pawn OtherPawn;

		OtherPawn = Pawn(Other);
		if (OtherPawn == None || OtherPawn.FindInventoryType(class'Q2TechItem') != None)
			return;

		if (ValidTouch(Other))
		{
			Copy = SpawnCopy(OtherPawn);
			if (Copy == None)
				return;

			AnnouncePickup(OtherPawn);
			HideEffect();
			SetRespawn();
			Copy.PickupFunction(OtherPawn);
		}
	}
}

defaultproperties
{
     RelicIcon=Texture'XRelicsTextures.Icons.HEAicon'
     EffectClass=Class'Q2CTFMod.Q2AutoDocPickupEffect'
     InventoryType=Class'Q2CTFMod.AutoDocEffect'
     PickupMessage="AutoDoc"
}
