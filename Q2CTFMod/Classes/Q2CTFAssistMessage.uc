class Q2CTFAssistMessage extends LocalMessage;

var localized string Bonus;
var localized string Assist;

static function string GetString(
	optional int Switch,
	optional PlayerReplicationInfo RelatedPRI_1,
	optional PlayerReplicationInfo RelatedPRI_2,
	optional Object OptionalObject
)
{
	return default.Bonus $ Switch $ default.Assist;
}

defaultproperties
{
     Bonus="You received "
     Assist=" assist points"
     bIsSpecial=False
}
