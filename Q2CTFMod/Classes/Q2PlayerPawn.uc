//=============================================================================
// Q2PlayerPawn
// Player movement and damage hooks shared by the Q2CTF tech items.
//=============================================================================
class Q2PlayerPawn extends xPawn;

var float TechDamageMultiplier;
var float QuadDamageMultiplier;
var float QuadDamageTime;
var byte QuadOverlayTeam;
var transient bool bQuadVisualActive;
var transient Weapon QuadVisualWeapon;
var transient byte QuadVisualTeam;
var float ResistDamageScale;
var float TechFireRateScale;
var float AppliedTechFireRateScale;
var float GrappleSpeedMultiplier;
var int SilencerShotsRemaining;
var Weapon LastSilencerWeapon;
var int LastSilencerFireCount[2];
var Q2RuneHudOverlay RuneHudOverlay;
var byte GrappleFirePulse;
var transient byte LastGrappleFirePulse;

replication
{
	reliable if (Role == ROLE_Authority)
		TechDamageMultiplier, QuadDamageMultiplier, ResistDamageScale,
		TechFireRateScale, GrappleSpeedMultiplier, SilencerShotsRemaining,
		GrappleFirePulse, QuadOverlayTeam;

	reliable if (Role == ROLE_Authority)
		ClientSetQuadDamageTime;

	reliable if (Role == ROLE_Authority)
		ClientShowDamagePopup;
}

simulated function ClientShowDamagePopup(int DamageAmount)
{
	Log("Q2DamageTrace ClientShowDamagePopup mode="$Level.NetMode$" role="$Role$" damage="$DamageAmount, 'Q2Damage');
	if (DamageAmount <= 0)
		return;

	EnsureRuneHudOverlay();
	if (RuneHudOverlay != None)
		RuneHudOverlay.AddDamage(DamageAmount);
}

function ClientSetQuadDamageTime(float NewTime)
{
	QuadDamageTime = Level.TimeSeconds + NewTime;
	UpdateQuadVisual();
}

function SetQuadDamageDuration(float Duration)
{
	QuadDamageTime = Level.TimeSeconds + Duration;
	QuadOverlayTeam = GetTeamNum();
	ClientSetQuadDamageTime(Duration);
	UpdateQuadVisual();
}

function ClearQuadDamageTime()
{
	QuadDamageTime = Level.TimeSeconds - 1.0;
	ClientSetQuadDamageTime(-1.0);
}

simulated event PostNetBeginPlay()
{
	Super.PostNetBeginPlay();
	SetTimer(0.05, True);
}

simulated event PostNetReceive()
{
	Super.PostNetReceive();

	if (Role != ROLE_Authority && TechFireRateScale != AppliedTechFireRateScale)
		UpdateTechFireRate();
	UpdateQuadVisual();
	TryPlayGrappleFiring();
	if (Role != ROLE_Authority && GrappleFirePulse != LastGrappleFirePulse)
		SetTimer(0.05, False);
}

simulated function TryPlayGrappleFiring()
{
	local Q2GrappleFire FireMode;

	if (Role != ROLE_Authority && GrappleFirePulse != LastGrappleFirePulse)
	{
		if (Q2GrappleHook(Weapon) != None && IsLocallyControlled())
		{
			FireMode = Q2GrappleFire(Q2GrappleHook(Weapon).GetFireMode(0));
			if (FireMode != None)
			{
				LastGrappleFirePulse = GrappleFirePulse;
				FireMode.PlayFiring();
			}
		}
	}
}

simulated function EnsureRuneHudOverlay()
{
	local PlayerController PC;

	if (RuneHudOverlay != None)
		return;

	PC = Level.GetLocalPlayerController();
	if (PC == None || PC.Pawn != Self || PC.MyHUD == None)
		return;

	RuneHudOverlay = Spawn(class'Q2RuneHudOverlay');
	if (RuneHudOverlay != None)
	{
		RuneHudOverlay.SetRunePlayer(PC);
		PC.MyHUD.AddHudOverlay(RuneHudOverlay);
	}
}

simulated function Timer()
{
	TryPlayGrappleFiring();
	EnsureRuneHudOverlay();
	UpdateSilencerTracking();
	UpdateQuadVisual();
}

simulated function Destroyed()
{
	if (RuneHudOverlay != None && Level.GetLocalPlayerController() != None)
		Level.GetLocalPlayerController().MyHUD.RemoveHudOverlay(RuneHudOverlay);

	Super.Destroyed();
}

function AddDefaultInventory()
{
	Super.AddDefaultInventory();
}

simulated function ChangedWeapon()
{
	local Inventory Inv;

	if (Weapon == None && PendingWeapon == None)
	{
		for (Inv = Inventory; Inv != None; Inv = Inv.Inventory)
		{
			if (Weapon(Inv) != None)
			{
				PendingWeapon = Weapon(Inv);
				break;
			}
		}
	}

	Super.ChangedWeapon();
	UpdateTechFireRate();
	UpdateQuadVisual();
}

simulated function Material GetQuadOverlayMaterial()
{
	if (QuadOverlayTeam == 0)
		return Material(DynamicLoadObject(
			"XEffectMat.RedShell", class'Material'));
	if (QuadOverlayTeam == 1)
		return Material(DynamicLoadObject(
			"XEffectMat.BlueShell", class'Material'));

	return Material(DynamicLoadObject("Seismic.Skins.StrengthShellFader", class'Material'));
}

simulated function UpdateQuadVisual()
{
	local Material QuadOverlayMat;
	local byte TeamIndex;

	TeamIndex = GetTeamNum();

	if (QuadDamageMultiplier != 1.0)
	{
		if (Role == ROLE_Authority)
			QuadOverlayTeam = TeamIndex;

		if (bQuadVisualActive && QuadVisualWeapon == Weapon && QuadVisualTeam == QuadOverlayTeam)
			return;

		QuadOverlayMat = GetQuadOverlayMaterial();
		SetOverlayMaterial(QuadOverlayMat, 9999.0, True);
		SetWeaponOverlay(QuadOverlayMat, 9999.0, True);
		bQuadVisualActive = True;
		QuadVisualWeapon = Weapon;
		QuadVisualTeam = QuadOverlayTeam;
		return;
	}

	if (!bQuadVisualActive)
		return;

	SetOverlayMaterial(None, 0.0, True);
	SetWeaponOverlay(None, 0.0, True);
	bQuadVisualActive = False;
	QuadVisualWeapon = None;
	if (Role == ROLE_Authority)
		QuadOverlayTeam = 255;
}

function bool DoJump(bool bUpdating)
{
	local Q2GrappleHook Grapple;

	Grapple = Q2GrappleHook(Weapon);
	if (Grapple == None)
		Grapple = Q2GrappleHook(FindInventoryType(class'Q2GrappleHook'));
	if (Grapple != None)
		Grapple.RequestJumpDetachHook();

	return Super.DoJump(bUpdating);
}

function ResetSilencerFireTracking()
{
	local WeaponFire FireMode;

	LastSilencerWeapon = Weapon;
	LastSilencerFireCount[0] = 0;
	LastSilencerFireCount[1] = 0;
	if (Weapon == None)
		return;

	FireMode = Weapon.GetFireMode(0);
	if (FireMode != None)
		LastSilencerFireCount[0] = FireMode.FireCount;
	FireMode = Weapon.GetFireMode(1);
	if (FireMode != None)
		LastSilencerFireCount[1] = FireMode.FireCount;
}

function UpdateSilencerTracking()
{
	local WeaponFire FireMode;
	local Inventory Silencer;
	local int Mode;
	local int FiredShots;

	if (Role != ROLE_Authority || SilencerShotsRemaining <= 0)
		return;

	if (Weapon != LastSilencerWeapon)
	{
		LastSilencerWeapon = Weapon;
		LastSilencerFireCount[0] = 0;
		LastSilencerFireCount[1] = 0;
	}

	if (Weapon == None)
		return;

	for (Mode = 0; Mode < Weapon.NUM_FIRE_MODES; Mode++)
	{
		FireMode = Weapon.GetFireMode(Mode);
		if (FireMode == None)
			continue;

		if (FireMode.FireCount < LastSilencerFireCount[Mode])
			LastSilencerFireCount[Mode] = FireMode.FireCount;

		FiredShots = FireMode.FireCount - LastSilencerFireCount[Mode];
		LastSilencerFireCount[Mode] = FireMode.FireCount;
		SilencerShotsRemaining -= FiredShots;
	}

	if (SilencerShotsRemaining <= 0)
	{
		SilencerShotsRemaining = 0;
		Silencer = FindInventoryType(class'Q2SilencerItem');
		if (Silencer != None)
			Silencer.Destroy();
	}
}

function UpdateTechFireRate()
{
	local Inventory Inv;
	local WeaponFire FireMode;
	local int Mode;

	AppliedTechFireRateScale = TechFireRateScale;

	for (Inv = Inventory; Inv != None; Inv = Inv.Inventory)
	{
		if (Weapon(Inv) == None)
			continue;

		for (Mode = 0; Mode < Weapon.NUM_FIRE_MODES; Mode++)
		{
			FireMode = Weapon(Inv).GetFireMode(Mode);
			if (FireMode != None)
			{
				FireMode.FireRate = FireMode.default.FireRate * TechFireRateScale;
				FireMode.FireAnimRate = FireMode.default.FireAnimRate / TechFireRateScale;
				FireMode.ReloadAnimRate = FireMode.default.ReloadAnimRate / TechFireRateScale;
			}
		}
	}
}

function float GetEffectiveDamageMultiplier()
{
	return TechDamageMultiplier * QuadDamageMultiplier;
}

function ResetTechState()
{
	TechDamageMultiplier = 1.0;
	ResistDamageScale = 1.0;
	TechFireRateScale = 1.0;
	GrappleSpeedMultiplier = 1.0;
}

function TakeDamage(int Damage, Pawn InstigatedBy, vector HitLocation, vector Momentum, class<DamageType> DamageType)
{
	Super.TakeDamage(Damage, InstigatedBy, HitLocation, Momentum, DamageType);
}

// Pawn calls this after game damage reduction and before subtracting health.
function int ShieldAbsorb(int Damage)
{
	Damage = Super.ShieldAbsorb(Damage);
	if (ResistDamageScale != 1.0)
		Damage = Round(float(Damage) * ResistDamageScale);
	return Damage;
}

defaultproperties
{
     TechDamageMultiplier=1.000000
     QuadDamageMultiplier=1.000000
     ResistDamageScale=1.000000
     TechFireRateScale=1.000000
     AppliedTechFireRateScale=1.000000
     GrappleSpeedMultiplier=1.000000
     bCanDoubleJump=False
     AirSpeed=460.000000
     AirControl=0.500000
}
