//=============================================================================
// Q2TechItem
// Shared base for the Q2CTF "tech" powerups (AutoDoc, Resist,
// Time Accelerator, Power Amplifier). Handles the rules common to all of
// them:
//   - A player can only hold ONE tech at a time; picking up a new one drops
//     whatever tech they're currently carrying back into the world.
//   - A dropped tech pickup relocates to a random player start after 30 seconds.
//   - Tech is lost on death (dropped at the death location), same as flags.
//
// This extends Inventory directly rather than xPickups.Powerup, since Q2
// techs are untimed (held until death/drop/replacement), not a countdown
// buff like UDamage. Verify against actual XGame/XPickups source for the
// correct Touch()/GiveTo() override signatures on your patch level -
// written from general UE2 Inventory conventions.
//=============================================================================
class Q2TechItem extends Inventory
	abstract;

// Subclasses override this to apply their per-tick effect to the carrying Pawn.
// Leave as a no-op override for techs that only need OnTechGained/OnTechLost
// (e.g. a flat damage or speed multiplier) rather than a continuous effect.
function ApplyTechEffect(Pawn P, float DeltaTime);

// Subclasses override to name themselves for messages/HUD.
function string GetTechName()
{
	return "Tech";
}

// Called once when a Pawn is granted this tech (fresh pickup, or picking
// it back up after a drop). Use this for stat changes that apply for the
// whole time the tech is held, rather than accumulating per-tick.
function OnTechGained(Pawn P);

// Called when the tech leaves this Pawn's possession - dropped, replaced
// by picking up a different tech, or lost on death. MUST undo whatever
// OnTechGained applied, or the effect will incorrectly persist.
function OnTechLost(Pawn P);

simulated function Tick(float DeltaTime)
{
	local Pawn P;

	Super.Tick(DeltaTime);

	P = Instigator;
	if (P != None)
	{
		ApplyTechEffect(P, DeltaTime);
	}
}

// Enforce "one tech at a time": if the Pawn already carries a Q2TechItem,
// drop it into the world before granting this one.
function bool HandlePickupQuery(Pickup Item)
{
	if (Item.InventoryType == Class)
		return true;

	if (ClassIsChildOf(Item.InventoryType, class'Q2TechItem'))
		return false;

	return Super.HandlePickupQuery(Item);
}

// Fires once the item is actually attached to the new owner. Exact override
// point (GiveTo vs a Pickup-side call) needs checking against source - some
// UE2 games call this from the Pickup actor rather than the Inventory item
// itself, in which case move this call there instead.
function GiveTo(Pawn Other, optional Pickup Pickup)
{
	Super.GiveTo(Other, Pickup);
	OnTechGained(Other);
}

// Dropping (voluntary drop, or losing a tech to a new pickup via
// HandlePickupQuery above) must revert the effect before the item leaves
// the Pawn.
function DropFrom(vector StartLocation)
{
	local Pawn P;
	P = Instigator;
	if (P != None)
	{
		OnTechLost(P);
	}
	Super.DropFrom(StartLocation);
}

// Death also needs to revert the effect - if the tech is destroyed outright
// on death rather than dropped as a pickup, DropFrom above won't fire, so
// catch that path here too.
simulated function Destroyed()
{
	local Pawn P;
	P = Instigator;
	if (P != None)
	{
		OnTechLost(P);
	}
	Super.Destroyed();
}

defaultproperties
{
}
