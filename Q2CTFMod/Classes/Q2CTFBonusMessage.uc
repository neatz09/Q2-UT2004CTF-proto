class Q2CTFBonusMessage extends LocalMessage;

var localized string Bonus[6];

static function string GetString(
	optional int Switch,
	optional PlayerReplicationInfo RelatedPRI_1,
	optional PlayerReplicationInfo RelatedPRI_2,
	optional Object OptionalObject
)
{
	return default.Bonus[Switch];
}

defaultproperties
{
     Bonus(0)="Bonus: +1 points for returning the flag!"
     Bonus(1)="Bonus: +2 points for recovering the flag!"
     Bonus(2)="Bonus: +3 points for preventing a capture!"
     Bonus(3)="Bonus: +5 points for grabbing the flag!"
     Bonus(4)="Bonus: +2 points for fragging the enemy flag carrier!"
     Bonus(5)="Bonus: +1 point for defending the flag carrier!"
     bIsSpecial=False
}
