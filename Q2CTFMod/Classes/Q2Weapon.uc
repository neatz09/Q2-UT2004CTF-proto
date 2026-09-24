//=============================================================================
// Q2Weapon
// Base class for all Q2CTF-conversion weapons. Every custom weapon in this
// mod should extend this (rather than Weapon directly) so Time Accelerator's
// fire-rate effect applies uniformly, instead of needing a bespoke hook in
// each weapon.
//
// GetFireInterval's exact name/signature is an educated guess based on
// common UE2 Weapon conventions (a per-mode fire interval lookup that
// FireWeapon/Timer-driven refire logic calls) - confirm the real function
// name in UT2004's Weapon.uc source before relying on this override actually
// being called. If UT2004 instead reads FireInterval[Mode] directly without
// going through a virtual accessor, this needs to become a Tick-based
// override of FireInterval itself instead.
//=============================================================================
class Q2Weapon extends Weapon
	abstract;

// TODO once real weapons exist: any weapon with a charge-up/spin-up delay
// (BFG-style charge, minigun-style spin-up) needs that delay scaled by the
// same TechFireRateScale, separately from GetFireInterval - Time
// Accelerator halves both per the original mod's documented behavior.

defaultproperties
{
}
