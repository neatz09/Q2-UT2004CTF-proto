//=============================================================================
// Q2TechPickup
// A non-respawning world pickup for a singleton Q2CTF tech.
//=============================================================================
class Q2TechPickup extends Pickup
	abstract;

#exec OBJ LOAD FILE=E_Pickups.usx
#exec OBJ LOAD FILE=XRelicsSM.usx
#exec OBJ LOAD FILE=XRelicsTextures.utx

var float GroundTime;
var() Texture RelicIcon;
var() class<xEmitter> EffectClass;
var xEmitter Effect;

event float BotDesireability(Pawn Bot)
{
	if (Bot.FindInventoryType(class'Q2TechItem') != None)
		return -1.0;

	return MaxDesireability;
}

function float DetourWeight(Pawn Other, float PathWeight)
{
	if (PathWeight <= 0.0)
		return 0.0;

	return 0.1 / PathWeight;
}

simulated event PostNetBeginPlay()
{
	Super.PostNetBeginPlay();
	ShowEffect();

	if (RelicIcon != None)
	{
		Skins[0] = RelicIcon;
		RepSkin = RelicIcon;
	}
}

simulated function ShowEffect()
{
	if (Effect != None || EffectClass == None || bHidden)
		return;

	Effect = Spawn(EffectClass, Self,, Location);
	if (Effect != None)
	{
		Effect.SetBase(Self);
		Effect.SetLocation(Location);
	}
}

simulated function HideEffect()
{
	if (Effect != None)
	{
		Effect.Destroy();
		Effect = None;
	}
}

simulated function Destroyed()
{
	if (Effect != None)
	{
		Effect.Destroy();
		Effect = None;
	}

	Super.Destroyed();
}

function Tick(float DeltaTime)
{
	local NavigationPoint N;
	local array<PlayerStart> Starts;
	local int Index;

	Super.Tick(DeltaTime);

	if (!bDropped)
		return;

	GroundTime += DeltaTime;
	if (GroundTime < 30.0)
		return;

	foreach AllActors(class'NavigationPoint', N)
	{
		if (PlayerStart(N) != None)
			Starts[Starts.Length] = PlayerStart(N);
	}

	if (Starts.Length > 0)
	{
		Index = Rand(Starts.Length);
		SetPhysics(PHYS_None);
		SetLocation(Starts[Index].Location);
		SetRotation(Starts[Index].Rotation);
		bDropped = False;
		GroundTime = 0.0;
		GotoState('Pickup');
	}
}

auto state Pickup
{
	simulated function BeginState()
	{
		ShowEffect();
		if (Role == ROLE_Authority)
			AddToNavigation();
	}

	function Touch(Actor Other)
	{
		local Inventory Copy;
		local Pawn OtherPawn;
		local Q2TechItem ExistingTech;

		OtherPawn = Pawn(Other);
		if (OtherPawn == None)
			return;

		ExistingTech = Q2TechItem(OtherPawn.FindInventoryType(class'Q2TechItem'));
		if (ExistingTech != None)
			return;

		if (ValidTouch(Other))
		{
			Copy = SpawnCopy(OtherPawn);
			if (Copy == None)
				return;

			AnnouncePickup(OtherPawn);
			HideEffect();
			SetRespawn();
			Copy.PickupFunction(OtherPawn);
		}
	}
}

defaultproperties
{
     MaxDesireability=50.000000
     RespawnTime=30.000000
     PickupSound=Sound'PickupSounds.LargeHealthPickup'
     PickupForce="LargeHealthPickup"
     DrawType=DT_StaticMesh
     StaticMesh=StaticMesh'XRelicsSM.XRelic'
     Physics=PHYS_Rotating
     DrawScale=0.500000
     ScaleGlow=0.600000
     Style=STY_AlphaZ
     CollisionRadius=32.000000
     CollisionHeight=32.000000
     RotationRate=(Yaw=24000)
     MessageClass=Class'UnrealGame.PickupMessagePlus'
}
