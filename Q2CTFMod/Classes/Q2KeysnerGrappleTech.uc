//=============================================================================
// Q2KeysnerGrappleTech
// Dormant tech definition. It is intentionally not spawned by Q2CTFGame yet.
//=============================================================================
class Q2KeysnerGrappleTech extends Q2TechItem;

var config float GrappleSpeedMultiplier;
var xEmitter CarrierEffect;


function string GetTechName()
{
	return "Keysner Grapple";
}

function ApplyTechEffect(Pawn P, float DeltaTime);

function OnTechGained(Pawn P)
{
	local Q2PlayerPawn QP;

	QP = Q2PlayerPawn(P);
	if (QP != None)
	{
		QP.ResetTechState();
		QP.GrappleSpeedMultiplier = GrappleSpeedMultiplier;
	}

 	if (P.Role == ROLE_Authority)
	{
		CarrierEffect = Spawn(class'Q2KeysnerGrappleCarrierEffect', P,, P.Location, P.Rotation);
		if (CarrierEffect != None)
			CarrierEffect.SetBase(P);
	}
}

function OnTechLost(Pawn P)
{
	local Q2PlayerPawn QP;

	QP = Q2PlayerPawn(P);
	if (QP != None)
		QP.GrappleSpeedMultiplier = 1.0;

	if (CarrierEffect != None)
		CarrierEffect.Destroy();
	CarrierEffect = None;
}

simulated function Destroyed()
{
	if (CarrierEffect != None)
		CarrierEffect.Destroy();
	CarrierEffect = None;
	Super.Destroyed();
}

defaultproperties
{
     GrappleSpeedMultiplier=2.000000
     PickupClass=Class'Q2CTFMod.Q2KeysnerGrapplePickup'
     ItemName="Keysner Grapple"
}
