//=============================================================================
// Q2SilencerItem
// Standalone dormant inventory item. It is intentionally not spawned yet.
// Weapon-specific sound suppression will be implemented when the weapon set is
// fleshed out, because UT2004 stores fire sounds on individual WeaponFire classes.
//=============================================================================
class Q2SilencerItem extends Inventory;

var int ShotsRemaining;

function GiveTo(Pawn Other, optional Pickup Pickup)
{
	local Q2PlayerPawn QP;

	Super.GiveTo(Other, Pickup);
	QP = Q2PlayerPawn(Other);
	if (QP != None)
	{
		ShotsRemaining = 30;
		QP.SilencerShotsRemaining = ShotsRemaining;
		QP.ResetSilencerFireTracking();
	}
}

function DropFrom(vector StartLocation)
{
	// Silencer is pickup-only and expires through its shot count.
}

function Destroyed()
{
	local Q2PlayerPawn QP;

	QP = Q2PlayerPawn(Instigator);
	if (QP != None)
		QP.SilencerShotsRemaining = 0;
	Super.Destroyed();
}

function string GetTechName()
{
	return "Silencer";
}

defaultproperties
{
     PickupClass=Class'Q2CTFMod.Q2SilencerPickup'
     ItemName="Silencer"
}
