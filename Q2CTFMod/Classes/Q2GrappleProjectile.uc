//=============================================================================
// Q2GrappleProjectile
// The flying hook launched by Q2GrappleHook. Travels in a straight line at
// a fixed velocity (set by the weapon at spawn) until it either hits solid
// world geometry - at which point it attaches and stops - or travels
// MaxRange without hitting anything, at which point it fizzles out.
//
// Per documented Q2CTF behavior: only attaches to solid objects (walls,
// ceilings, static geometry), never to players, and cannot attach to sky.
//
// Physics setup (PHYS_Projectile, collision flags) and the exact
// Touch()/HitWall() signatures below follow common UE2 Actor conventions,
// but need confirming against real Engine.Actor source - in particular
// whether UT2004 delivers a fast-moving-actor-vs-BSP hit through Touch(),
// HitWall(), or a native collision callback with a different name.
//=============================================================================
class Q2GrappleProjectile extends Projectile;

var Q2GrappleHook OwnerWeapon;
var Q2GrappleRope Rope;
var float MaxRange;
var float DistanceTravelled;
var vector PreviousLocation;
var config string SkyGrappleMaps;
var config string SkyCeilingMaps;
var bool bAttached;
var bool bLoggedFastPull;

function DismountBot(Bot BotController, optional Actor Target)
{
	if (BotController != None)
	{
		if (Target != None)
			BotController.Focus = Target;
		BotController.bPreparingMove = False;
		BotController.bTranslocatorHop = False;
		BotController.TranslocationTarget = None;
		BotController.RealTranslocationTarget = None;
	}

	if (OwnerWeapon != None)
		OwnerWeapon.DetachHook();
	if (BotController != None)
		BotController.WhatToDoNext(77);
}

replication
{
	reliable if (Role == ROLE_Authority)
		OwnerWeapon, MaxRange, bAttached;
}

simulated function PostBeginPlay()
{
	local int TeamIndex;

	Super.PostBeginPlay();
	SetPhysics(PHYS_Projectile);
	bCollideWorld = True;
	PreviousLocation = Location;

	if (Instigator != None && Instigator.PlayerReplicationInfo != None
		&& Instigator.PlayerReplicationInfo.Team != None)
	{
		TeamIndex = Instigator.PlayerReplicationInfo.Team.TeamIndex;
		if (TeamIndex == 0)
			Rope = Spawn(class'Q2RedRope', Self,, Location);
		else if (TeamIndex == 1)
			Rope = Spawn(class'Q2BlueRope', Self,, Location);
	}

	if (Rope == None)
		Rope = Spawn(class'Q2GrappleRope', Self,, Location);
	if (Rope != None)
	{
		Rope.Hook = Self;
		Rope.Instigator = Instigator;
		Rope.SetBase(Self);
	}
}

simulated function Tick(float DeltaTime)
{
	local vector HitLocation, HitNormal;
	local Actor HitActor;
	local Material HitMaterial;

	Super.Tick(DeltaTime);

	if (Role != ROLE_Authority || bAttached)
	{
		return;
	}

	if (VSize(Location - PreviousLocation) > 0.0)
	{
		HitActor = Trace(HitLocation, HitNormal, Location, PreviousLocation, False,, HitMaterial);
		if (HitActor != None)
		{
			HandleImpact(HitNormal, HitActor, HitMaterial, HitLocation);
			if (bAttached)
				return;
		}
	}
	PreviousLocation = Location;

	// Auto-miss once MaxRange is exceeded without a hit, so an errant throw
	// into open space doesn't fly forever.
	DistanceTravelled += VSize(Velocity) * DeltaTime;
	if (DistanceTravelled >= MaxRange)
	{
		if (OwnerWeapon != None)
		{
			OwnerWeapon.NotifyHookMissed();
		}
		Destroy();
	}
}

// Fires when the projectile touches another Actor mid-flight. Players are
// explicitly excluded - the original grapple only latches onto world
// geometry, not other Pawns.
simulated singular function Touch(Actor Other)
{
	if (Role != ROLE_Authority || bAttached || Pawn(Other) != None)
	{
		return;
	}

	HandleImpact(Normal(Location - Other.Location), Other, None, Location);
}

// Fires when the projectile hits static BSP/world geometry rather than
// another Actor - the more common case for a grapple shot at a wall.
simulated function HitWall(vector HitNormal, Actor Wall)
{
	local vector HitLocation, TraceNormal;
	local Material HitMaterial;

	if (Role != ROLE_Authority || bAttached)
	{
		return;
	}

	Trace(HitLocation, TraceNormal, Location - HitNormal * 16.0,
		Location + HitNormal * 16.0, False,, HitMaterial);
	HandleImpact(HitNormal, Wall, HitMaterial, Location);
}

function AttachAt(vector AttachPoint)
{
	if (Role != ROLE_Authority)
		return;

	bAttached = True;
	SetPhysics(PHYS_None);
	Velocity = vect(0, 0, 0);
	SetCollision(False, False, False);
	bCollideWorld = False;

	if (OwnerWeapon != None)
	{
		OwnerWeapon.NotifyHookAttached(AttachPoint);
	}

	GotoState('Hooked');

	// TODO: this is also the spot to kick off the visual rope/beam effect
	// between the carrier and AttachPoint, once weapon art exists.
}

function bool IsSkyImpact(Actor HitActor, vector HitNormal, optional Material SurfaceMaterial)
{
	local vector TraceLocation, TraceNormal;
	local Material HitMaterial;
	local string MaterialName;

	if (InStr("," $ Caps(SkyGrappleMaps) $ ",",
			"," $ Caps(GetURLMap(False)) $ ",") < 0)
		return False;

	if (InStr("," $ Caps(SkyCeilingMaps) $ ",",
			"," $ Caps(GetURLMap(False)) $ ",") >= 0
		&& HitNormal.Z < -0.5)
		return True;

	if (SkyZoneInfo(HitActor) != None)
		return True;

	if (SurfaceMaterial != None)
		HitMaterial = SurfaceMaterial;
	else
		Trace(TraceLocation, TraceNormal, Location - HitNormal * 16.0,
			Location + HitNormal * 16.0, False,, HitMaterial);

	if (HitMaterial == None)
		return False;

	MaterialName = Caps(string(HitMaterial));
	return InStr(MaterialName, "SKY") >= 0
		|| InStr(MaterialName, "CLOUD") >= 0
		|| InStr(MaterialName, "SUNDOM") >= 0
		|| InStr(MaterialName, "SUN-DOM") >= 0
		|| InStr(MaterialName, "SEPSKYA") >= 0
		|| InStr(MaterialName, "ICEFIELDSSKYPAN") >= 0
		|| InStr(MaterialName, "BR_ICELANDS") >= 0
		|| InStr(MaterialName, "COGSKY") >= 0
		|| InStr(MaterialName, "AZSKY") >= 0;
}

function HandleImpact(vector HitNormal, optional Actor HitActor, optional Material SurfaceMaterial, optional vector ImpactLocation)
{
	if (Role != ROLE_Authority || bAttached)
		return;

	if (IsSkyImpact(HitActor, HitNormal, SurfaceMaterial))
	{
		Destroy();
		return;
	}

	if (ImpactLocation == vect(0, 0, 0))
		ImpactLocation = Location;
	AttachAt(ImpactLocation);
}

event Landed(vector HitNormal)
{
	HandleImpact(HitNormal);
}

state Hooked
{
	function Tick(float DeltaTime)
	{
		local vector PullDir;
		local float CurrentPullSpeed;
		local Bot BotController;
		local Actor TranslocationTarget;

		Global.Tick(DeltaTime);

		if (Role != ROLE_Authority || OwnerWeapon == None || Instigator == None)
			return;

		if (PlayerController(Instigator.Controller) != None
			&& PlayerController(Instigator.Controller).bPressedJump)
		{
			OwnerWeapon.RequestJumpDetachHook();
			return;
		}

		OwnerWeapon.BotHookTime += DeltaTime;
		CurrentPullSpeed = OwnerWeapon.PullSpeed;
		if (OwnerWeapon.bFastPull)
			CurrentPullSpeed = OwnerWeapon.FastPullSpeed;
		if (OwnerWeapon.bFastPull && !bLoggedFastPull)
		{
			Log("Q2Grapple: projectile fast pull speed "$CurrentPullSpeed, 'Q2Grapple');
			bLoggedFastPull = True;
		}
		if (Q2PlayerPawn(Instigator) != None)
			CurrentPullSpeed *= Q2PlayerPawn(Instigator).GrappleSpeedMultiplier;

		Instigator.SetPhysics(PHYS_Flying);
		Instigator.AirSpeed = CurrentPullSpeed;
		PullDir = Normal(Location - Instigator.Location);
		if (VSize(Location - Instigator.Location) <= 64.0)
		{
			Instigator.Velocity = vect(0, 0, 0);
			Instigator.Acceleration = vect(0, 0, 0);
		}
		else
			Instigator.AddVelocity(PullDir * CurrentPullSpeed);

		BotController = Bot(Instigator.Controller);
		if (BotController != None)
		{
			TranslocationTarget = BotController.TranslocationTarget;
			if (TranslocationTarget != None
				&& (VSize(Instigator.Location - TranslocationTarget.Location) <= 96.0
					|| Instigator.Location.Z > TranslocationTarget.Location.Z))
			{
				DismountBot(BotController, TranslocationTarget);
				return;
			}
		}
		if (BotController != None && OwnerWeapon.BotHookTime >= OwnerWeapon.BotHookTimeout)
		{
			DismountBot(BotController);
		}
	}
}

simulated function Destroyed()
{
	if (Rope != None)
	{
		Rope.Destroy();
		Rope = None;
	}

	Super.Destroyed();
	if (Role == ROLE_Authority && OwnerWeapon != None && OwnerWeapon.ActiveHook == Self)
		OwnerWeapon.NotifyHookMissed();
}

defaultproperties
{
     SkyGrappleMaps="CTF-1ON1-JOUST"
     SkyCeilingMaps="CTF-1ON1-JOUST"
     NetPriority=3.000000
     Mesh=SkeletalMesh'Weapons.TransBeacon'
     bHardAttach=True
     CollisionRadius=5.000000
     CollisionHeight=5.000000
     bBlockActors=True
     bBlockProjectiles=True
}
