class Q2QuadPickup extends Q2TechPickup;

var float RemainingTime;
var float DropStartTime;

function float GetRemainingTime()
{
	if (RemainingTime <= 0.0)
		return 0.0;

	if (DropStartTime > 0.0)
		return FMax(0.0, RemainingTime - (Level.TimeSeconds - DropStartTime));

	return RemainingTime;
}

#exec OBJ LOAD FILE=E_Pickups.usx
#exec OBJ LOAD FILE=PickupSounds.uax

auto state Pickup
{
	function BeginState()
	{
		if (Role == ROLE_Authority)
		{
			AddToNavigation();
			if (bDropped && RemainingTime > 0.0)
				SetTimer(RemainingTime, False);
		}
	}

	function Timer()
	{
		if (bDropped)
			Destroy();
	}

	function Touch(Actor Other)
	{
		local Inventory Copy;
		local Pawn OtherPawn;
		local Q2QuadDamagePickup ExistingQuad;
		local float PickupDuration;

		OtherPawn = Pawn(Other);
		if (OtherPawn == None)
			return;

		if (!ValidTouch(Other))
			return;

		PickupDuration = DurationForPickup();

		ExistingQuad = Q2QuadDamagePickup(
			OtherPawn.FindInventoryType(class'Q2QuadDamagePickup'));
		if (ExistingQuad != None)
		{
			ExistingQuad.RemainingTime = FMax(ExistingQuad.RemainingTime, PickupDuration);
			ExistingQuad.SetTimer(ExistingQuad.RemainingTime, False);
			Q2PlayerPawn(OtherPawn).SetQuadDamageDuration(ExistingQuad.RemainingTime);
			AnnouncePickup(OtherPawn);
			SetRespawn();
			return;
		}

		Copy = SpawnCopy(OtherPawn);
		if (Copy == None)
			return;

		AnnouncePickup(OtherPawn);
		SetRespawn();
		Copy.PickupFunction(OtherPawn);
	}

	function float DurationForPickup()
	{
		if (GetRemainingTime() > 0.0)
			return GetRemainingTime();

		return class'Q2QuadDamagePickup'.default.Duration;
	}
}

defaultproperties
{
     MaxDesireability=2.000000
     InventoryType=Class'Q2CTFMod.Q2QuadDamagePickup'
     RespawnTime=60.000000
     PickupMessage="QUAD DAMAGE!"
     PickupSound=Sound'PickupSounds.UDamagePickup'
     PickupForce="UDamagePickup"
     StaticMesh=StaticMesh'E_Pickups.General.Udamage'
     DrawScale=0.900000
     CollisionHeight=23.000000
}
