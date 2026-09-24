class Q2CTFFlag extends CTFFlag;

#exec OBJ LOAD FILE=XGameShaders.utx
#exec OBJ LOAD FILE=XGameShaders2004.utx
#exec OBJ LOAD FILE=TeamSymbols_UT2003.utx

var xEmitter Trail;
var class<xEmitter> TrailClass;

simulated function PostBeginPlay()
{
	Super.PostBeginPlay();
	LoopAnim('flag', 0.8);
	SimAnim.bAnimLoop = True;
}

simulated event PostNetReceive()
{
	Super.PostNetReceive();
	if (bHome && !bHeld)
		bHidden = True;
	else
		bHidden = False;
}

function Score()
{
	Spawn(class'ComboActivation',,,Location, Rotation);
	Super.Score();
}

simulated function DestroyTrail()
{
	if (Trail != None)
	{
		Trail.mRegen = False;
		Trail.Destroy();
		Trail = None;
	}
}

state Held
{
	simulated function BeginState()
	{
		Super.BeginState();
		bHidden = False;
		if (TrailClass != None && Holder != None)
		{
			Trail = Spawn(TrailClass, Holder,, Holder.Location, Holder.Rotation);
			if (Trail != None)
				Trail.SetBase(Holder);
		}
	}

	simulated function EndState()
	{
		DestroyTrail();
		Super.EndState();
	}
}

state Dropped
{
	simulated function BeginState()
	{
		DestroyTrail();
		Super.BeginState();
	}
}

auto state Home
{
	function SameTeamTouch(Controller C)
	{
		if (C.PlayerReplicationInfo.HasFlag == None)
			return;

		BroadcastLocalizedMessage(class'Q2CTFFlagMessage',
			Level.TimeSeconds - GameObject(C.PlayerReplicationInfo.HasFlag).TakenTime,
			C.PlayerReplicationInfo,
			None,
			self);
		Super.SameTeamTouch(C);
	}

	simulated function BeginState()
	{
		DestroyTrail();
		Super.BeginState();
	}
}

defaultproperties
{
     Mesh=VertMesh'XGame_rc.FlagMesh'
     DrawScale=0.900000
}
