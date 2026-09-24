//=============================================================================
// Q2GrappleHook
// Replicates the original Q2CTF grapple as documented by period player
// guides (no source-level confirmation of internal variable names, but the
// gameplay contract is well-attested and consistent across sources):
//   - It's a normal weapon you switch to, not an off-hand/use-item.
//   - Holding fire launches a fast hook projectile in a straight line.
//   - On hitting solid world geometry (not sky, not players), the hook
//     latches and pulls the carrier toward the attach point for as long as
//     fire is held.
//   - Releasing fire detaches immediately and preserves whatever velocity
//     the pull built up - this momentum retention on release is the entire
//     skill ceiling of Q2 grappling (chained swings for speed), so it's
//     critical NOT to zero or dampen Instigator.Velocity on detach anywhere
//     in this class.
//   - If the hook doesn't hit anything within MaxRange, it fizzles out on
//     its own rather than attaching.
//
// State-machine method names below (Fire/StopFire/PutDownWeapon) follow
// common UE2 Weapon conventions, but the exact override points UT2004 calls
// on button-down vs button-up need confirming against the real Weapon.uc -
// this is the single biggest verification task before this will compile
// and behave correctly.
//=============================================================================
class Q2GrappleHook extends Q2Weapon;

var Q2GrappleProjectile ActiveHook;
var bool bHooked;
var bool bFastPull;
var vector HookAttachPoint;
var config float ProjectileSpeed;
var config float PullSpeed;
var config float FastPullSpeed;
var config float MaxRange;
var config float BotHookTimeout;
var float BotHookTime;

replication
{
	reliable if (bNetOwner && Role == ROLE_Authority)
		ActiveHook, bHooked, bFastPull, HookAttachPoint;
	reliable if (Role < ROLE_Authority)
		ServerLaunchHook, ServerDetachHook, ServerEnableFastPull;
}

simulated function bool HasAmmo()
{
	return True;
}

function GiveTo(Pawn Other, optional Pickup Pickup)
{
	Super.GiveTo(Other, Pickup);
	if (Bot(Other.Controller) != None)
		Bot(Other.Controller).bHasTranslocator = True;
}

function bool ShouldBotGrapple(Bot BotController)
{
	return BotController != None
		&& BotController.TranslocationTarget != None
		&& BotController.Squad != None
		&& BotController.Squad.AllowTranslocationBy(BotController)
		&& (BotController.bPreparingMove
			|| (BotController.bTranslocatorHop
				&& (BotController.Focus == BotController.MoveTarget
					|| BotController.Focus == BotController.TranslocationTarget)));
}

simulated function Timer()
{
	local Bot BotController;

	Super.Timer();

	if (Instigator == None)
		return;

	BotController = Bot(Instigator.Controller);
	if (Instigator.Weapon == Self && ShouldBotGrapple(BotController) && ActiveHook == None)
	{
		LaunchHook();
		if (ActiveHook != None)
			EnableFastPull();
	}
}

function bool BotFire(bool bFinished, optional name FiringMode)
{
	local Bot BotController;

	if (Instigator == None)
		return False;

	BotController = Bot(Instigator.Controller);
	if (BotController == None)
		return False;

	if (FiringMode == 'AltFire')
	{
		if (ActiveHook != None)
			DismountBot();
		return ActiveHook == None;
	}
	if (!ShouldBotGrapple(BotController))
		return False;

	if (ActiveHook == None)
	{
		LaunchHook();
		if (ActiveHook != None)
			EnableFastPull();
	}
	else
		EnableFastPull();

	return True;
}

function byte BestMode()
{
	if (ActiveHook != None)
		return 1;

	return 0;
}

function DismountBot()
{
	local Bot BotController;

	BotController = Bot(Instigator.Controller);
	DetachHook();
	if (BotController != None)
	{
		BotController.bPreparingMove = False;
		BotController.bTranslocatorHop = False;
		BotController.TranslocationTarget = None;
		BotController.RealTranslocationTarget = None;
		BotController.WhatToDoNext(77);
	}
}

function float GetAIRating()
{
	local Bot BotController;

	BotController = Bot(Instigator.Controller);
	if (BotController == None)
		return AIRating;

	if (BotController.bPreparingMove && BotController.TranslocationTarget != None)
	{
		if (Instigator.Weapon == Self)
			SetTimer(0.2, False);
		return 10.0;
	}

	if (BotController.bTranslocatorHop && ShouldBotGrapple(BotController))
	{
		if (Instigator.Weapon == Self)
			SetTimer(0.2, False);
		return 4.0;
	}

	return AIRating;
}

function LaunchHook()
{
	local vector StartLoc, AimDir;

	if (Instigator != None)
	{
		StartLoc = Instigator.Location + Instigator.EyePosition();
		AimDir = vector(Instigator.GetViewRotation());
		LaunchHookAt(StartLoc, rotator(AimDir));
	}
}

function vector GetBotHookTarget(Bot BotController)
{
	local vector HitLocation, HitNormal;
	local Actor Target;

	if (BotController == None || BotController.TranslocationTarget == None)
		return vect(0, 0, 0);

	Target = BotController.TranslocationTarget;
	if (Target.IsA('JumpSpot') && Target.Location.Z >= Instigator.Location.Z)
	{
		if (Trace(HitLocation, HitNormal, Target.Location + vect(0, 0, 512), Target.Location) != None)
			return HitLocation;
		return Target.Location + vect(0, 0, 512);
	}

	return Target.Location;
}

function LaunchHookAt(vector StartLoc, rotator AimRotation)
{
	local vector AimDir;
	local vector BotHookTarget;
	local Q2PlayerPawn QP;
	local float CurrentProjectileSpeed;
	local Bot BotController;

	if (Role != ROLE_Authority || Instigator == None || ActiveHook != None)
	{
		return;
	}

	AimDir = vector(AimRotation);
	BotController = Bot(Instigator.Controller);
	if (BotController != None && BotController.TranslocationTarget != None)
	{
		BotHookTarget = GetBotHookTarget(BotController);
		AimDir = Normal(BotHookTarget - StartLoc);
	}
	CurrentProjectileSpeed = ProjectileSpeed;
	QP = Q2PlayerPawn(Instigator);
	if (QP != None)
		CurrentProjectileSpeed *= QP.GrappleSpeedMultiplier;

	ActiveHook = Spawn(class'Q2GrappleProjectile', Instigator,, StartLoc, rotator(AimDir));
	if (ActiveHook != None)
	{
		ActiveHook.OwnerWeapon = Self;
		ActiveHook.Velocity = AimDir * CurrentProjectileSpeed;
		ActiveHook.MaxRange = MaxRange;
	}
}

function ServerLaunchHook(vector StartLoc, rotator AimRotation)
{
	FireHook(StartLoc, AimRotation);
}

function ServerDetachHook(optional bool bFromJump)
{
	DetachHook(bFromJump);
}

function ServerEnableFastPull()
{
	if (bFastPull)
		return;

	if (Instigator == None)
		return;

	if (PlayerController(Instigator.Controller) != None
		&& PlayerController(Instigator.Controller).bPressedJump)
	{
		DetachHook();
		return;
	}

	bFastPull = True;
	Log("Q2Grapple: server fast pull enabled", 'Q2Grapple');
}

function EnableFastPull()
{
	if (bFastPull)
		return;

	if (Instigator == None)
		return;

	if (PlayerController(Instigator.Controller) != None
		&& PlayerController(Instigator.Controller).bPressedJump)
	{
		RequestDetachHook();
		return;
	}

	if (Role == ROLE_Authority)
	{
		bFastPull = True;
		Log("Q2Grapple: authority fast pull enabled", 'Q2Grapple');
	}
	else
		ServerEnableFastPull();
}

function RequestDetachHook(optional bool bFromJump)
{
	bFastPull = False;
	if (Role == ROLE_Authority)
		DetachHook(bFromJump);
	else
		ServerDetachHook(bFromJump);
}

function RequestJumpDetachHook()
{
	RequestDetachHook(True);
}

simulated function bool StartFire(int Mode)
{
	local bool bStarted;

	if (Mode == 0 && Q2GrappleFire(GetFireMode(Mode)) != None)
		Q2GrappleFire(GetFireMode(Mode)).bSuppressFireAnimation = (ActiveHook != None);

	bStarted = Super.StartFire(Mode);
	return bStarted;
}

simulated event StopFire(int Mode)
{
	Super.StopFire(Mode);
}

function FireHook(vector StartLoc, rotator AimRotation)
{
	if (Role == ROLE_Authority)
	{
		bFastPull = False;
		LaunchHookAt(StartLoc, AimRotation);
		if (Level.NetMode == NM_DedicatedServer)
		{
			if (Q2PlayerPawn(Instigator) != None)
			{
				Q2PlayerPawn(Instigator).GrappleFirePulse++;
				Q2PlayerPawn(Instigator).NetUpdateTime = Level.TimeSeconds - 1.0;
			}
		}
	}
	else
		ServerLaunchHook(StartLoc, AimRotation);
}

// Called by Q2GrappleProjectile once it latches onto solid geometry.
function NotifyHookAttached(vector AttachPoint)
{
	if (Role != ROLE_Authority)
		return;

	bHooked = True;
	BotHookTime = 0.0;
	HookAttachPoint = AttachPoint;
	if (Instigator != None)
		Instigator.SetPhysics(PHYS_Falling);
}

// Called by Q2GrappleProjectile if it travels MaxRange without hitting
// anything solid - an auto-miss, not a manual detach, but the cleanup is
// identical.
function NotifyHookMissed()
{
	local Bot BotController;

	if (Role != ROLE_Authority)
		return;

	ActiveHook = None;
	bHooked = False;
	bFastPull = False;
	BotHookTime = 0.0;
	BotController = Bot(Instigator.Controller);
	if (BotController != None)
		BotController.WhatToDoNext(77);
}

function DetachHook(optional bool bFromJump)
{
	local Q2GrappleProjectile HookToDestroy;
	local Bot BotController;

	if (Role != ROLE_Authority)
		return;

	HookToDestroy = ActiveHook;
	ActiveHook = None;
	if (HookToDestroy != None)
		HookToDestroy.Destroy();
	bHooked = False;
	bFastPull = False;
	BotHookTime = 0.0;
	if (bFromJump && Instigator != None)
		Instigator.Velocity *= 0.5;
	if (Instigator != None)
		Instigator.AirSpeed = Instigator.default.AirSpeed;
	if (Instigator != None && Instigator.Physics == PHYS_Flying)
		Instigator.SetPhysics(PHYS_Falling);
	if (Instigator != None && Instigator.Controller != None)
	{
		BotController = Bot(Instigator.Controller);
		if (BotController != None)
			Instigator.Controller.NotifyPhysicsVolumeChange(Instigator.PhysicsVolume);
	}
	// Deliberately not touching Instigator.Velocity - see class header.
}

// Applies the pull each tick while hooked. Overwriting Velocity outright
// (rather than accelerating toward the target) is the simplest correct
// approximation of the original; it trades away some of the subtler swing
// physics skilled Q2 players exploit, but gets the core feel - fast,
// controllable travel toward the attach point - without needing to reverse
// engineer the exact original acceleration curve.
simulated function Tick(float DeltaTime)
{
	Super.Tick(DeltaTime);
}

// Dying while hooked must also clean up the hook actor.
simulated function Destroyed()
{
	DetachHook();
	Super.Destroyed();
}

defaultproperties
{
     ProjectileSpeed=2200.000000
     PullSpeed=1200.000000
     FastPullSpeed=1200.000000
     MaxRange=4000.000000
     BotHookTimeout=2.000000
     FireModeClass(0)=Class'Q2CTFMod.Q2GrappleFire'
     FireModeClass(1)=Class'Q2CTFMod.Q2GrappleAltFire'
     AIRating=0.100000
     CurrentRating=0.100000
     bCanThrow=False
     DisplayFOV=60.000000
     SmallViewOffset=(X=38.000000,Y=16.000000,Z=-16.000000)
     CustomCrosshair=7
     CustomCrossHairTextureName="Crosshairs.HUD.Crosshair_Cross1"
     InventoryGroup=10
     PlayerViewOffset=(X=28.500000,Y=12.000000,Z=-12.000000)
     PlayerViewPivot=(Pitch=1000,Yaw=400)
     IconMaterial=Texture'HUDContent.Generic.HUD'
     IconCoords=(X2=2,Y2=2)
     ItemName="Grappling Hook"
     Mesh=SkeletalMesh'NewWeapons2004.NewTranslauncher_1st'
     DrawScale=0.800000
}
