class Q2CTFFlagMessage extends LocalMessage;

var localized string CaptureTime;
var localized string Red;
var localized string Blue;
var localized string FlagLabel;
var localized string Seconds;
var(Message) color RedColor;
var(Message) color BlueColor;

static function color GetColor(
	optional int Switch,
	optional PlayerReplicationInfo RelatedPRI_1,
	optional PlayerReplicationInfo RelatedPRI_2
)
{
	if (RelatedPRI_1 != None && RelatedPRI_1.Team != None)
	{
		if (RelatedPRI_1.Team.TeamIndex == 0)
			return default.BlueColor;

		return default.RedColor;
	}

	return default.DrawColor;
}

static function string GetString(
	optional int Switch,
	optional PlayerReplicationInfo RelatedPRI_1,
	optional PlayerReplicationInfo RelatedPRI_2,
	optional Object OptionalObject
)
{
	local string TeamColor;
	local CTFFlag HeldFlag;
	local color TeamColorValue;

	HeldFlag = CTFFlag(OptionalObject);
	if (HeldFlag == None && RelatedPRI_1 != None)
		HeldFlag = CTFFlag(RelatedPRI_1.HasFlag);

	if (HeldFlag != None && HeldFlag.TeamNum == 0)
	{
		TeamColor = default.Red;
		TeamColorValue = default.RedColor;
	}
	else if (HeldFlag != None)
	{
		TeamColor = default.Blue;
		TeamColorValue = default.BlueColor;
	}
	else
	{
		TeamColor = default.FlagLabel;
		TeamColorValue = default.DrawColor;
	}

	return ColorCode(TeamColorValue)
		$ TeamColor $ default.CaptureTime $ Switch $ default.Seconds
		$ ColorCode(default.DrawColor);
}

static function string ColorCode(color ColorValue)
{
	return Chr(27) $ Chr(Max(ColorValue.R, 1))
		$ Chr(Max(ColorValue.G, 1)) $ Chr(Max(ColorValue.B, 1));
}

defaultproperties
{
     CaptureTime=" flag captured in "
     Red="Red"
     Blue="Blue"
     FlagLabel="Flag"
     Seconds=" seconds"
     RedColor=(B=80,G=80,R=255,A=255)
     BlueColor=(B=255,G=190,R=100,A=255)
     bIsSpecial=False
}
