//=============================================================================
// Q2CTFGame
// Quake 2 CTF conversion - core gametype.
// Extends UT2004's native CTF gametype rather than reimplementing flag/base
// logic from scratch. Verify the exact parent class name against your
// installed source build (XGame package, ~patch 3369) before compiling -
// class names have shifted slightly between UT2004 patch levels.
//=============================================================================
class Q2CTFGame extends xGame.xCTFGame
	config(Q2CTFMod);

var config bool bQ2ArmorModel;
var config bool bEnableGrappleHook;
var config float MinTechSpawnDistance;
	var config int FlagReturnFriendlyScore;
	var config int FlagReturnEnemyScore;
	var config int FlagDenialScore;
	var config int FlagFirstTouchScore;
	var config int FlagCaptureScore;
	var config int FlagAssistTotalScore;
	var config int FlagAssistMinimumScore;
	var config int FlagAssistMaximumScore;

function bool AllowTransloc()
{
	return false;
}

function PreBeginPlay()
{
	local xRealCTFBase FlagBase;

	Super.PreBeginPlay();

	foreach AllActors(class'xRealCTFBase', FlagBase)
	{
		if (FlagBase.DefenderTeamIndex == 0)
			FlagBase.FlagType = class'Q2RedFlag';
		else
			FlagBase.FlagType = class'Q2BlueFlag';
	}
}

function ScoreFlag(Controller Scorer, CTFFlag TheFlag)
{
	local float Distance;
	local float OpponentDistance;
	local float PointsPerPlayer;
	local float TouchCount;
	local vector FlagLocation;
	local int Index;

	if (Scorer.PlayerReplicationInfo.Team == TheFlag.Team)
	{
		Scorer.AwardAdrenaline(ADR_Return);
		FlagLocation = TheFlag.Position().Location;
		Distance = VSize(FlagLocation - TheFlag.HomeBase.Location);

		if (TheFlag.TeamNum == 0)
			OpponentDistance = VSize(FlagLocation - Teams[1].HomeBase.Location);
		else
			OpponentDistance = VSize(FlagLocation - Teams[0].HomeBase.Location);

		GameEvent("flag_returned", "" $ TheFlag.Team.TeamIndex, Scorer.PlayerReplicationInfo);
		BroadcastLocalizedMessage(class'CTFMessage', 1, Scorer.PlayerReplicationInfo, None, TheFlag.Team);

		if (Distance > 1024.0)
		{
			if (Distance <= OpponentDistance)
			{
				Scorer.PlayerReplicationInfo.Score += FlagReturnFriendlyScore;
				ScoreEvent(Scorer.PlayerReplicationInfo, FlagReturnFriendlyScore, "flag_ret_friendly");
				if (Scorer.Pawn != None)
					Scorer.Pawn.ReceiveLocalizedMessage(class'Q2CTFBonusMessage', 0);
			}
			else
			{
				Scorer.PlayerReplicationInfo.Score += FlagReturnEnemyScore;
				ScoreEvent(Scorer.PlayerReplicationInfo, FlagReturnEnemyScore, "flag_ret_enemy");
				if (Scorer.Pawn != None)
					Scorer.Pawn.ReceiveLocalizedMessage(class'Q2CTFBonusMessage', 1);

				if (OpponentDistance <= 1024.0)
				{
					Scorer.PlayerReplicationInfo.Score += FlagDenialScore;
					ScoreEvent(Scorer.PlayerReplicationInfo, FlagDenialScore, "flag_denial");
					if (Scorer.Pawn != None)
						Scorer.Pawn.ReceiveLocalizedMessage(class'Q2CTFBonusMessage', 2);
				}
			}
		}
		return;
	}

	if (TheFlag.FirstTouch != None)
	{
		TheFlag.FirstTouch.PlayerReplicationInfo.Score += FlagFirstTouchScore;
		TheFlag.FirstTouch.PlayerReplicationInfo.NetUpdateTime = Level.TimeSeconds - 1.0;
		ScoreEvent(TheFlag.FirstTouch.PlayerReplicationInfo, FlagFirstTouchScore, "flag_cap_1st_touch");
		if (TheFlag.FirstTouch.Pawn != None)
			TheFlag.FirstTouch.Pawn.ReceiveLocalizedMessage(class'Q2CTFBonusMessage', 3);
	}

	Scorer.PlayerReplicationInfo.Score += FlagCaptureScore;
	Scorer.PlayerReplicationInfo.NetUpdateTime = Level.TimeSeconds - 1.0;
	IncrementGoalsScored(Scorer.PlayerReplicationInfo);
	Scorer.AwardAdrenaline(ADR_Goal);
	Scorer.PlayerReplicationInfo.Team.Score += 1.0;
	Scorer.PlayerReplicationInfo.Team.NetUpdateTime = Level.TimeSeconds - 1.0;
	ScoreEvent(Scorer.PlayerReplicationInfo, FlagCaptureScore, "flag_cap_final");
	TeamScoreEvent(Scorer.PlayerReplicationInfo.Team.TeamIndex, 1, "flag_cap");
	GameEvent("flag_captured", "" $ TheFlag.Team.TeamIndex, Scorer.PlayerReplicationInfo);
	BroadcastLocalizedMessage(class'CTFMessage', 0, Scorer.PlayerReplicationInfo, None, TheFlag.Team);
	AnnounceScore(Scorer.PlayerReplicationInfo.Team.TeamIndex);

	for (Index = 0; Index < TheFlag.Assists.Length; Index++)
		if (TheFlag.Assists[Index] != None)
			TouchCount += 1.0;

	if (TouchCount > 0.0)
		PointsPerPlayer = FClamp(FlagAssistTotalScore / TouchCount,
			FlagAssistMinimumScore, FlagAssistMaximumScore);

	for (Index = 0; Index < TheFlag.Assists.Length; Index++)
	{
		if (TheFlag.Assists[Index] != None)
		{
			TheFlag.Assists[Index].PlayerReplicationInfo.Score += int(PointsPerPlayer);
			ScoreEvent(TheFlag.Assists[Index].PlayerReplicationInfo, PointsPerPlayer, "flag_cap_assist");
			if (TheFlag.Assists[Index] != Scorer && TheFlag.Assists[Index].Pawn != None)
				TheFlag.Assists[Index].Pawn.ReceiveLocalizedMessage(
					class'Q2CTFAssistMessage', int(PointsPerPlayer));
		}
	}

	CheckScore(Scorer.PlayerReplicationInfo);
	if (bOverTime)
		EndGame(Scorer.PlayerReplicationInfo, "timelimit");
}

function ScoreKill(Controller Killer, Controller Other)
{
	local Pawn Target;

	if (Killer != None && Other != None && Killer != Other
		&& Killer.bIsPlayer && Other.bIsPlayer
		&& Killer.PlayerReplicationInfo != None
		&& Other.PlayerReplicationInfo != None
		&& Killer.PlayerReplicationInfo.Team != Other.PlayerReplicationInfo.Team)
	{
		if (CriticalPlayer(Other) && Killer.Pawn != None)
			Killer.Pawn.ReceiveLocalizedMessage(class'Q2CTFBonusMessage', 4);

		if (bScoreVictimsTarget)
		{
			Target = FindVictimsTarget(Other);
			if (Target != None && Target.PlayerReplicationInfo != None
				&& Target.PlayerReplicationInfo.Team == Killer.PlayerReplicationInfo.Team
				&& CriticalPlayer(Target.Controller) && Killer.Pawn != None)
			{
				Killer.Pawn.ReceiveLocalizedMessage(class'Q2CTFBonusMessage', 5);
			}
		}
	}

	Super.ScoreKill(Killer, Other);
}

event InitGame(string Options, out string Error)
{
	Super.InitGame(Options, Error);
	AddGameModifier(Spawn(class'Q2CTFDamageRules'));
	AddGameModifier(Spawn(class'Q2QuadDamageRules'));
	EnsureDropRuneMutator();
}

function AddGameSpecificInventory(Pawn P)
{
	Super.AddGameSpecificInventory(P);

	if (bEnableGrappleHook && P.FindInventoryType(class'Q2GrappleHook') == None)
		P.CreateInventory("Q2CTFMod.Q2GrappleHook");
}

function DiscardInventory(Pawn Other)
{
	local Q2TechItem Tech;

	Tech = Q2TechItem(Other.FindInventoryType(class'Q2TechItem'));
	if (Tech != None)
		Tech.DropFrom(Other.Location);

	Super.DiscardInventory(Other);
}

function PostBeginPlay()
{
	Super.PostBeginPlay();
	EnsureDropRuneMutator();
	ReplaceAdrenalinePickups();
	ReplaceUDamagePickups();
	SpawnSingletonTechs();
}

function EnsureDropRuneMutator()
{
	local Mutator M;

	for (M = BaseMutator; M != None; M = M.NextMutator)
	{
		if (M.IsA('MutAutoTech'))
			return;
	}

	AddMutator("Q2CTFMod.MutAutoTech");
}

function ReplaceUDamagePickups()
{
	local Actor A;
	local Pickup OldPickup;
	local Pickup NewPickup;

	foreach AllActors(class'Actor', A)
	{
		if (A.IsA('UDamagePack'))
		{
			OldPickup = Pickup(A);
			NewPickup = Spawn(class'Q2QuadPickup', OldPickup.Owner, OldPickup.Tag,
				OldPickup.Location, OldPickup.Rotation);
			if (NewPickup != None)
			{
				NewPickup.Event = OldPickup.Event;
				NewPickup.Tag = OldPickup.Tag;
				if (OldPickup.MyMarker != None)
				{
					NewPickup.MyMarker = OldPickup.MyMarker;
					NewPickup.MyMarker.MarkedItem = NewPickup;
					OldPickup.MyMarker = None;
				}
				OldPickup.Destroy();
			}
		}
	}
}

function ReplaceAdrenalinePickups()
{
	local Actor A;
	local Pickup OldPickup;
	local Pickup NewPickup;

	foreach AllActors(class'Actor', A)
	{
		if (A.IsA('AdrenalinePickup'))
		{
			OldPickup = Pickup(A);
			NewPickup = Spawn(class'Q2ArmorShardPickup', OldPickup.Owner, OldPickup.Tag,
				OldPickup.Location, OldPickup.Rotation);
			if (NewPickup != None)
			{
				NewPickup.Event = OldPickup.Event;
				NewPickup.Tag = OldPickup.Tag;
				if (OldPickup.MyMarker != None)
				{
					NewPickup.MyMarker = OldPickup.MyMarker;
					NewPickup.MyMarker.MarkedItem = NewPickup;
					OldPickup.MyMarker = None;
				}
				OldPickup.Destroy();
			}
			else
			{
				Log("Q2CTFGame: failed to spawn Q2ArmorShardPickup at " $ OldPickup.Location);
			}
		}
	}
}

function RestartPlayer(Controller APlayer)
{
	APlayer.bAdrenalineEnabled = False;
	Super.RestartPlayer(APlayer);
}

event PostLogin(PlayerController NewPlayer)
{
	Super.PostLogin(NewPlayer);
	NewPlayer.bAdrenalineEnabled = False;
}

function SpawnSingletonTechs()
{
	local array<PlayerStart> Starts;
	local NavigationPoint N;
	local int Index;

	if (Level.NetMode == NM_Client)
		return;

	foreach AllActors(class'NavigationPoint', N)
	{
		if (PlayerStart(N) != None)
			Starts[Starts.Length] = PlayerStart(N);
	}

	if (Starts.Length == 0)
		return;

	Index = Rand(Starts.Length);
	SpawnTechAtStart(class'Q2AutoDocPickup', Starts[Index % Starts.Length]);
	SpawnTechAtStart(class'Q2ResistPickup', Starts[(Index + 1) % Starts.Length]);
	SpawnTechAtStart(class'Q2TimeAcceleratorPickup', Starts[(Index + 2) % Starts.Length]);
	SpawnTechAtStart(class'Q2PowerAmpPickup', Starts[(Index + 3) % Starts.Length]);
}

function SpawnTechAtStart(class<Pickup> PickupClass, PlayerStart Start)
{
	local Actor ExistingActor;
	local Pickup ExistingPickup;
	local Pickup NewPickup;

	foreach AllActors(PickupClass, ExistingActor)
	{
		ExistingPickup = Pickup(ExistingActor);
		if (ExistingPickup != None)
			ExistingPickup.Destroy();
	}

	if (Start == None)
		return;

	NewPickup = Spawn(PickupClass,,, Start.Location, Start.Rotation);
	if (NewPickup != None)
		NewPickup.SetCollision(True, False, False);
}

// Hook point for Q2's "quad damage" / "haste" / "resist" / "regen" tech
// items if you're porting those too - these were map-placed pickups in Q2
// CTF, not gametype-level rules, so they'll mostly live in a custom
// Q2TechPickup class rather than here. Left as a stub for now.

defaultproperties
{
     bQ2ArmorModel=True
     bEnableGrappleHook=True
     MinTechSpawnDistance=768.000000
     FlagReturnFriendlyScore=1
     FlagReturnEnemyScore=2
     FlagDenialScore=3
     FlagFirstTouchScore=5
     FlagCaptureScore=5
     FlagAssistTotalScore=20
     FlagAssistMinimumScore=1
     FlagAssistMaximumScore=5
     bBalanceTeams=False
     TeamAIType(0)=Class'Q2CTFMod.Q2CTFTeamAI'
     TeamAIType(1)=Class'Q2CTFMod.Q2CTFTeamAI'
     bAllowTrans=False
     bDefaultTranslocator=False
     bWaitForNetPlayers=False
     BotMode=5
     MinPlayers=3
     GameDifficulty=4.000000
     DefaultPlayerClassName="Q2CTFMod.Q2PlayerPawn"
     GoalScore=7
     DeathMessageClass=Class'Q2CTFMod.Q2ColorDeathMessage'
     GameName="Q2CTF UT Edition"
     Description="**Q2CTF UT Edition** fuses the industrial, fast-paced intensity of *Quake II* with the high-flying spectacle of *Unreal Tournament 2004*. Two teams battle across massive fortresses to steal the enemy's flag and return it to their own base. Movement is a weapon: combine physics-defying **dodge-jumps**, swift wall-dodges, and momentum-based **grappling hooks** to fly across the arena at breakneck speeds. Success requires tight team coordination, balancing aggressive flag runners with disciplined defenders while controlling the map to lock down devastating weapons and powerful **Tech Runes**."
}
