//=============================================================================
// Q2ArmorShardPickup
// Temporary armor shard using the stock adrenaline texture until custom art exists.
//=============================================================================
class Q2ArmorShardPickup extends ShieldPickUp;

#exec OBJ LOAD FILE="ArmorShardSounds.uax" PACKAGE=Q2CTFMod
#exec OBJ LOAD FILE="ArmorShardTextures.utx" PACKAGE=Q2CTFMod

var() int ArmorAmount;

static function StaticPrecache(LevelInfo L)
{
	L.AddPrecacheStaticMesh(StaticMesh'XPickups_rc.AdrenalinePack');
}

auto state Pickup
{
	function Touch(Actor Other)
	{
		local xPawn XP;

		if (!ValidTouch(Other))
			return;

		XP = xPawn(Other);
		if (XP == None || !XP.AddShieldStrength(ArmorAmount))
			return;

		AnnouncePickup(XP);
		SetRespawn();
	}
}

defaultproperties
{
     ArmorAmount=2
     RespawnTime=35.000000
     PickupMessage="You picked up an Armor Shard +"
     PickupSound=Sound'Q2CTFMod.ArmorShardPickup'
     PickupForce="HealthPack"
     DrawType=DT_StaticMesh
     StaticMesh=StaticMesh'far.rock01'
     CullDistance=5500.000000
     bNetInitialRotation=True
     Physics=PHYS_Rotating
     DrawScale=0.100000
     DrawScale3D=(X=0.300000,Y=0.300000,Z=2.500000)
     Skins(0)=Combiner'AW-2004Particles.Energy.Combiner3'
     AmbientGlow=48
     ScaleGlow=0.600000
     Style=STY_AlphaZ
     CollisionRadius=32.000000
     RotationRate=(Yaw=18000)
}
