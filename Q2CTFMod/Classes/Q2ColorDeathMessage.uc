class Q2ColorDeathMessage extends xDeathMessage;

static function color GetConsoleColor(PlayerReplicationInfo RelatedPRI_1)
{
	return default.DrawColor;
}

static function string GetString(
	optional int Switch,
	optional PlayerReplicationInfo RelatedPRI_1,
	optional PlayerReplicationInfo RelatedPRI_2,
	optional Object OptionalObject
)
{
	if (Class<DamageType>(OptionalObject) == None)
		return "";

	if (Switch == 1)
		return ColorCode(default.DrawColor)
			$ class'GameInfo'.Static.ParseKillMessage(
				GetPlayerName(RelatedPRI_1),
				GetPlayerName(RelatedPRI_2),
				StripCodes(Class<DamageType>(OptionalObject).Static.SuicideMessage(RelatedPRI_2)))
			$ ColorCode(default.DrawColor);

	return ColorCode(default.DrawColor)
		$ class'GameInfo'.Static.ParseKillMessage(
			GetPlayerName(RelatedPRI_1),
			GetPlayerName(RelatedPRI_2),
			StripCodes(Class<DamageType>(OptionalObject).Static.DeathMessage(RelatedPRI_1, RelatedPRI_2)))
		$ ColorCode(default.DrawColor);
}

static function string GetPlayerName(PlayerReplicationInfo PRI)
{
	if (PRI == None)
		return default.SomeoneString;

	return ColorCode(class'SayMessagePlus'.Static.GetConsoleColor(PRI))
		$ StripCodes(PRI.PlayerName)
		$ ColorCode(default.DrawColor);
}

static function string StripCodes(coerce string Input)
{
	local int Index;

	Index = InStr(Input, Chr(27));
	while (Index != -1)
	{
		Input = Left(Input, Index) $ Mid(Input, Index + 4);
		Index = InStr(Input, Chr(27));
	}

	return Input;
}

static function string ColorCode(color ColorValue)
{
	return Chr(27) $ Chr(Max(ColorValue.R, 1))
		$ Chr(Max(ColorValue.G, 1)) $ Chr(Max(ColorValue.B, 1));
}

defaultproperties
{
     DrawColor=(B=255,G=255)
}
