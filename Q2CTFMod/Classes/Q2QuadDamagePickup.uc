//=============================================================================
// Q2QuadDamagePickup
// Standard Quake 2 deathmatch powerup, not a Threewave CTF tech - confirmed
// behavior: multiplies weapon damage by 4x, lasts 30 seconds, and (per
// standard multiplayer dmflags) activates instantly on pickup rather than
// sitting in inventory for later use. In CTF specifically, the carrier
// glows their team's color instead of the usual purple/gold - that's a
// visual-only detail, flagged below as a TODO once weapon/effect art exists.
//
// Deliberately does NOT extend Q2TechItem - Quad and a tech (e.g. Power
// Amp) can be held simultaneously, so the "one tech at a time" exclusivity
// and ground-timer relocation rules in Q2TechItem don't apply here. This
// uses ordinary timed-pickup respawn behavior instead.
//
// GiveTo/Touch override points are the same category of guess as everywhere
// else in this mod - verify against actual Inventory/Pickup source.
//=============================================================================
class Q2QuadDamagePickup extends Inventory;

var config float DamageMultiplier;   // 4.0 per confirmed Q2 behavior
var config float Duration;           // 30.0 seconds per confirmed Q2 behavior
var config bool bInstantActivate;    // standard MP behavior; expose in case a
                                      // server wants classic inventory-hold rules
var float RemainingTime;

function bool HandlePickupQuery(Pickup Item)
{
	// Unlike Q2TechItem, no exclusivity check needed here - Quad stacks
	// with whatever tech (if any) the player is already carrying.
	return Super.HandlePickupQuery(Item);
}

function GiveTo(Pawn Other, optional Pickup Pickup)
{
	local Q2PlayerPawn QP;
	local Q2QuadPickup DroppedPickup;
	local float PickupDuration;

	Super.GiveTo(Other, Pickup);

	PickupDuration = Duration;
	DroppedPickup = Q2QuadPickup(Pickup);
	if (DroppedPickup != None && DroppedPickup.GetRemainingTime() > 0.0)
		PickupDuration = DroppedPickup.GetRemainingTime();

	RemainingTime = PickupDuration;
	if (bInstantActivate)
		SetTimer(PickupDuration, False);

	if (bInstantActivate)
	{
		QP = Q2PlayerPawn(Other);
		if (QP != None)
		{
			QP.QuadDamageMultiplier = DamageMultiplier;
			QP.SetQuadDamageDuration(PickupDuration);
		}
	}

	// TODO: trigger the team-colored glow effect on Other here once
	// materials/particle effects exist for it.
}

function Timer()
{
	if (!bInstantActivate)
	{
		return;
	}

	RemainingTime = 0.0;
	Expire();
}

function Expire()
{
	local Q2PlayerPawn QP;

	QP = Q2PlayerPawn(Instigator);
	if (QP != None)
	{
		QP.QuadDamageMultiplier = 1.0;
		QP.ClearQuadDamageTime();
	}

	Destroy();
}

// Dying while Quad is active must also revert the multiplier, same as the
// tech items - otherwise a dead carrier's stale multiplier could leak onto
// whatever picks the item up next if cleanup order goes wrong.
simulated function Destroyed()
{
	local Q2PlayerPawn QP;

	QP = Q2PlayerPawn(Instigator);
	if (QP != None && QP.QuadDamageMultiplier != 1.0)
	{
		QP.QuadDamageMultiplier = 1.0;
		QP.ClearQuadDamageTime();
	}

	Super.Destroyed();
}

defaultproperties
{
     DamageMultiplier=4.000000
     Duration=30.000000
     bInstantActivate=True
     PickupClass=Class'Q2CTFMod.Q2QuadPickup'
     ItemName="Quad Damage"
}
