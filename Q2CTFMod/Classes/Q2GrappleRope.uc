class Q2GrappleRope extends xEmitter;

var Q2GrappleProjectile Hook;

simulated function Tick(float DeltaTime)
{
	local vector StartPoint;

	Super.Tick(DeltaTime);

	if (Hook == None || Hook.bDeleteMe || Instigator == None || Instigator.Controller == None)
	{
		Destroy();
		return;
	}

	StartPoint = Instigator.Location + Instigator.EyePosition();
	mSpawnVecA = StartPoint;
	mSpawnVecB = Hook.Location;
}

defaultproperties
{
     mParticleType=PT_Beam
     mMaxParticles=1
     mLifeRange(0)=1.000000
     mRegenDist=90.000000
     mSizeRange(0)=0.300000
     mSizeRange(1)=0.600000
     mColorRange(0)=(B=50,G=50,R=50)
     mColorRange(1)=(B=50,G=50,R=50)
     mMeshNodes(0)=StaticMesh'XEffects.ShockCoil'
     bNetTemporary=False
     bReplicateInstigator=True
     bReplicateMovement=False
     Physics=PHYS_Trailer
     RemoteRole=ROLE_SimulatedProxy
     NetPriority=3.000000
     LifeSpan=180.000000
     DrawScale3D=(X=3.000000,Y=15.000000,Z=15.000000)
     Skins(0)=FinalBlend'XEffectMat.Shock.ShockCoilFB'
}
