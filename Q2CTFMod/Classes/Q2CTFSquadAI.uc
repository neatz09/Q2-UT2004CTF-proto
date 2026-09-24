//=============================================================================
// Q2CTFSquadAI
// Q2 grapples are allowed while carrying the enemy flag, matching Seismic.
//=============================================================================
class Q2CTFSquadAI extends CTFSquadAI;

function bool AllowTranslocationBy(Bot B)
{
	return True;
}

defaultproperties
{
}
