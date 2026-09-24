class Q2CTFDamageRules extends GameRules;

var config int DarkMatterGunDamage;
var config int RailgunDamage;

function int NetDamage(int OriginalDamage, int Damage, Pawn Injured, Pawn InstigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType)
{
	local Q2PlayerPawn Attacker;

	Log("Q2DamageTrace NetDamage mode="$Level.NetMode$" damage="$Damage$" instigator="$InstigatedBy, 'Q2Damage');
	Attacker = Q2PlayerPawn(InstigatedBy);
	if (Attacker != None)
	{
		Damage = Round(float(Damage) * Attacker.GetEffectiveDamageMultiplier());
		Log("Q2DamageTrace scaled damage="$Damage$" pawnRole="$Attacker.Role$" remoteRole="$Attacker.RemoteRole, 'Q2Damage');
		if (Damage > 0)
			Attacker.ClientShowDamagePopup(Damage);
	}
	else
		Log("Q2DamageTrace no Q2PlayerPawn cast, popup skipped, instigator="$InstigatedBy, 'Q2Damage');

	if (NextGameRules != None)
		return NextGameRules.NetDamage(OriginalDamage, Damage, Injured, InstigatedBy, HitLocation, Momentum, DamageType);

	return Damage;
}

defaultproperties
{
     DarkMatterGunDamage=200
     RailgunDamage=125
}
