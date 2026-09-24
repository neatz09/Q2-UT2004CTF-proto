//=============================================================================
// Q2ResistTech
// Q2CTF's Resist tech halves the damage that remains after normal
// armor/shield absorption.
//
// No per-tick effect - this is a flat scale applied once on pickup and
// reverted once dropped/lost, via OnTechGained/OnTechLost. The actual
// reduction happens in Q2PlayerPawn.ShieldAbsorb, after normal absorption.
//
// UNCERTAIN: whether the original applies this to self-damage (e.g. your
// own rocket splash) - the Quake 3 "Resistance" rune explicitly excludes
// self-damage, but I couldn't confirm the Q2CTF version does the same.
// Q2CTF's game logic is GPL and available (icculus.org/projects/quake2) -
// worth checking gamex86 source directly for the real behavior before
// treating bExcludeSelfDamage's default below as correct.
//=============================================================================
class Q2ResistTech extends Q2TechItem;

var config float HealthDamageScale;
var xEmitter CarrierEffect;

function string GetTechName()
{
	return "Resist";
}

// No continuous effect - the reduction is handled entirely by
// OnTechGained/OnTechLost setting the carrier's ResistDamageScale.
function ApplyTechEffect(Pawn P, float DeltaTime);

function OnTechGained(Pawn P)
{
	local Q2PlayerPawn QP;

	QP = Q2PlayerPawn(P);
	if (QP != None)
	{
		QP.ResetTechState();
		QP.ResistDamageScale = HealthDamageScale;
	}

	if (P.Role == ROLE_Authority)
	{
		CarrierEffect = Spawn(class'Q2ResistCarrierEffect', P,, P.Location, P.Rotation);
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
		QP.ResistDamageScale = 1.0;
	}

	if (CarrierEffect != None)
		CarrierEffect.Destroy();
	CarrierEffect = None;
}

defaultproperties
{
     HealthDamageScale=0.500000
     PickupClass=Class'Q2CTFMod.Q2ResistPickup'
     ItemName="Resist"
}
