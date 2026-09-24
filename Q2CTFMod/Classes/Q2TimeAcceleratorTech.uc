//=============================================================================
// Q2TimeAcceleratorTech
// Q2CTF's Haste-equivalent tech. Confirmed effect: doubles the fire rate of
// all weapons, and halves the delay on any weapon with a charge-up/spin-up.
//
// UNCERTAIN: whether the base tech also grants a movement speed boost on its
// own - the sources I found only describe a speed boost when combined with
// a separate "Haste" item, not from Time Accelerator alone. Treating this
// as fire-rate-only for now; check the GPL gamex86 source (see
// Q2ResistTech's header comment for where to find it) before
// adding a GroundSpeed change here.
//
// No per-tick effect - handled entirely by OnTechGained/OnTechLost setting
// the carrier's TechFireRateScale, which Q2Weapon.GetFireInterval reads.
//=============================================================================
class Q2TimeAcceleratorTech extends Q2TechItem;

var config float FireRateScale;   // < 1.0 = faster; 0.5 = double fire rate
var xEmitter BerserkEffect;

function string GetTechName()
{
	return "Time Accelerator";
}

function ApplyTechEffect(Pawn P, float DeltaTime);

function OnTechGained(Pawn P)
{
	local Q2PlayerPawn QP;

	QP = Q2PlayerPawn(P);
	if (QP != None)
	{
		QP.ResetTechState();
		QP.TechFireRateScale = FireRateScale;
		QP.UpdateTechFireRate();
	}

	if (P.Role == ROLE_Authority)
		BerserkEffect = Spawn(class'OffensiveEffect', P,, P.Location, P.Rotation);
}

function OnTechLost(Pawn P)
{
	local Q2PlayerPawn QP;

	QP = Q2PlayerPawn(P);
	if (QP != None)
	{
		QP.TechFireRateScale = 1.0;
		QP.UpdateTechFireRate();
	}

	if (BerserkEffect != None)
		BerserkEffect.Destroy();
	BerserkEffect = None;
}

defaultproperties
{
     FireRateScale=0.500000
     PickupClass=Class'Q2CTFMod.Q2TimeAcceleratorPickup'
     ItemName="Time Accelerator"
}
