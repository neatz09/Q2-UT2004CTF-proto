//=============================================================================
// Q2PowerAmpTech
// Q2CTF's Strength-equivalent tech. Confirmed effect: doubles the carrier's
// weapon damage for as long as it's held - conveniently the same 2x factor
// as UT2004's own UDamage/Amplifier pickup, just delivered as a persistent
// tech instead of a timed powerup.
//
// No per-tick effect needed - this is a flat multiplier applied once on
// pickup and reverted once dropped/lost, via the OnTechGained/OnTechLost
// hooks on Q2TechItem. The actual multiplication happens in
// Q2PlayerPawn.TakeDamage, on the victim's side, checking the attacker's
// TechDamageMultiplier.
//=============================================================================
class Q2PowerAmpTech extends Q2TechItem;

var config float DamageMultiplier;
var xEmitter CarrierEffect;

function string GetTechName()
{
	return "Power Amplifier";
}

// No continuous effect - damage scaling is handled entirely by
// OnTechGained/OnTechLost setting the carrier's TechDamageMultiplier.
function ApplyTechEffect(Pawn P, float DeltaTime);

function OnTechGained(Pawn P)
{
	local Q2PlayerPawn QP;

	QP = Q2PlayerPawn(P);
	if (QP != None)
	{
		QP.ResetTechState();
		QP.TechDamageMultiplier = DamageMultiplier;
	}

	if (P.Role == ROLE_Authority)
	{
		CarrierEffect = Spawn(class'Q2PowerAmpCarrierEffect', P,, P.Location, P.Rotation);
		if (CarrierEffect != None)
			CarrierEffect.SetBase(P);
	}
}

function OnTechLost(Pawn P)
{
	local Q2PlayerPawn QP;

	QP = Q2PlayerPawn(P);
	if (QP != None)
	{
		QP.TechDamageMultiplier = 1.0;
	}

	if (CarrierEffect != None)
		CarrierEffect.Destroy();
	CarrierEffect = None;
}

defaultproperties
{
     DamageMultiplier=2.000000
     PickupClass=Class'Q2CTFMod.Q2PowerAmpPickup'
     ItemName="Power Amplifier"
}
