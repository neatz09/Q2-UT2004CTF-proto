class Q2GrappleFire extends WeaponFire;

var() vector ProjSpawnOffset;
var transient bool bSuppressFireAnimation;

simulated function bool AllowFire()
{
	return True;
}

function DoFireEffect()
{
	local vector X, Y, Z;
	local vector StartTrace, StartProjectile;
	local vector HitLocation, HitNormal;
	local Actor HitActor;
	local Rotator AimRotation;
	local Q2GrappleHook Grapple;

	Grapple = Q2GrappleHook(Weapon);
	if (Grapple == None || Instigator == None)
		return;

	if (Grapple.ActiveHook != None)
	{
		Grapple.EnableFastPull();
		return;
	}

	Weapon.GetViewAxes(X, Y, Z);
	StartTrace = Instigator.Location + Instigator.EyePosition();
	StartProjectile = StartTrace + X * ProjSpawnOffset.X + Y * ProjSpawnOffset.Y + Z * ProjSpawnOffset.Z;
	HitActor = Trace(HitLocation, HitNormal, StartProjectile, StartTrace, False);
	if (HitActor != None)
		StartProjectile = HitLocation;

	AimRotation = AdjustAim(StartProjectile, AimError);
	Grapple.FireHook(StartProjectile, AimRotation);
}

simulated function PlayFiring()
{
	if (bSuppressFireAnimation)
	{
		bSuppressFireAnimation = False;
		return;
	}

	Weapon.PlayOwnedSound(FireSound, SLOT_Interact, TransientSoundVolume,,, Default.FireAnimRate / FireAnimRate, False);
	Weapon.PlayAnim(FireAnim, FireAnimRate, TweenTime);
	ClientPlayForceFeedback("TranslocatorFire");
}

function ServerPlayFiring()
{
	Weapon.PlayOwnedSound(FireSound, SLOT_Interact, TransientSoundVolume,,, Default.FireAnimRate / FireAnimRate, False);
}

function ModeHoldFire()
{
}

defaultproperties
{
     ProjSpawnOffset=(X=25.000000,Y=8.000000)
     bInstantHit=False
     bWaitForRelease=True
     FireRate=0.100000
     ProjectileClass=Class'Q2CTFMod.Q2GrappleProjectile'
     BotRefireRate=0.300000
}
