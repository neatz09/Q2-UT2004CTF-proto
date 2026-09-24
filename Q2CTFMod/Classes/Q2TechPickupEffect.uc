class Q2TechPickupEffect extends xEmitter;

#exec OBJ LOAD FILE=XEffectMat.utx

defaultproperties
{
     mParticleType=PT_Line
     mSpawningType=ST_Explode
     mStartParticles=0
     mMaxParticles=75
     mLifeRange(0)=0.500000
     mLifeRange(1)=0.500000
     mRegenRange(0)=50.000000
     mRegenRange(1)=50.000000
     mPosDev=(X=50.000000,Y=50.000000,Z=50.000000)
     mSpawnVecB=(X=5.000000,Z=0.080000)
     mSpeedRange(0)=-100.000000
     mSpeedRange(1)=-100.000000
     mAirResistance=0.000000
     mSizeRange(0)=2.000000
     mSizeRange(1)=2.000000
     Physics=PHYS_Trailer
     RemoteRole=ROLE_SimulatedProxy
     LifeSpan=180.000000
     Skins(0)=FinalBlend'XEffectMat.Ion.IonParticleBeamFB'
     Style=STY_Additive
}
