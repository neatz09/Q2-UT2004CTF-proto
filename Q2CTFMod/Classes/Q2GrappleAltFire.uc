class Q2GrappleAltFire extends WeaponFire;

function DoFireEffect()
{
	local Q2GrappleHook Grapple;

	Grapple = Q2GrappleHook(Weapon);
	if (Grapple != None)
		Grapple.RequestDetachHook();
}

function ServerPlayFiring()
{
	Weapon.PlayOwnedSound(FireSound, SLOT_Interact, TransientSoundVolume,,, Default.FireAnimRate / FireAnimRate, False);
}

simulated function PlayFiring()
{
	Weapon.PlayOwnedSound(FireSound, SLOT_Interact, TransientSoundVolume,,, Default.FireAnimRate / FireAnimRate, False);
	ClientPlayForceFeedback("TranslocatorModuleRegeneration");
}

defaultproperties
{
     bInstantHit=False
     FireAnim=
     FireRate=0.100000
}
