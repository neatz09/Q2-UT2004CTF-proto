class Q2DamagePopup extends xEmitter;

var int Damage;
var color FontColor;
var ScriptedTexture DamageTexture;
var TexRotator DamageRotator;
var Material TextureFallback;
var Font DrawFont;

static function ShowDamage(Actor Dest, vector ShowLocation, int DamageAmount)
{
	local Q2DamagePopup Popup;

	if (Dest == None || DamageAmount <= 0)
		return;

	Popup = Dest.Spawn(class'Q2DamagePopup',,, ShowLocation, rot(16384, 0, 0));
	Log("Q2DamageTrace ShowDamage mode="$Dest.Level.NetMode$" amount="$DamageAmount$" popup="$Popup, 'Q2Damage');
	if (Popup == None)
		return;

	Popup.Damage = DamageAmount;
	if (Dest.Level.NetMode != NM_DedicatedServer)
		Popup.PostNetBeginPlay();
}

simulated event Destroyed()
{
	if (DamageTexture != None)
	{
		DamageTexture.Client = None;
		Level.ObjectPool.FreeObject(DamageTexture);
	}

	if (DamageRotator != None)
		Level.ObjectPool.FreeObject(DamageRotator);

	Super.Destroyed();
}

simulated function PostNetBeginPlay()
{
	local rotator NewRotation;

	DamageTexture = ScriptedTexture(Level.ObjectPool.AllocateObject(class'ScriptedTexture'));
	DamageRotator = TexRotator(Level.ObjectPool.AllocateObject(class'TexRotator'));
	Log("Q2DamageTrace PostNetBeginPlay mode="$Level.NetMode$" role="$Role$" texture="$DamageTexture$" rotator="$DamageRotator, 'Q2Damage');
	if (DamageTexture == None || DamageRotator == None)
	{
		Destroy();
		return;
	}

	DamageTexture.SetSize(64, 64);
	DamageTexture.Client = Self;
	DamageTexture.Revision++;
	DamageRotator.Material = DamageTexture;
	DamageRotator.Rotation.Yaw = 8191;
	DamageRotator.UOffset = 32;
	DamageRotator.VOffset = 32;
	DrawFont = Font(DynamicLoadObject("UT2003Fonts.FontEurostile14", class'Font'));
	if (DrawFont == None)
		DrawFont = Font(DynamicLoadObject("Engine.DefaultFont", class'Font'));
	Log("Q2DamageTrace font="$DrawFont$" texture="$Texture, 'Q2Damage');

	Texture = DamageRotator;
	Skins[0] = DamageRotator;
	NewRotation.Yaw = Rand(65536);
	NewRotation.Pitch = 12384 + Rand(7000);
	SetRotation(NewRotation);
	mStartParticles = 1;
}

simulated event RenderTexture(ScriptedTexture Texture)
{
	local int TextWidth;
	local int TextHeight;
	local color ClearColor;
	local string DamageText;

	Log("Q2DamageTrace RenderTexture mode="$Level.NetMode$" role="$Role$" texture="$Texture$" font="$DrawFont$" damage="$Damage, 'Q2Damage');
	if (Texture == None || DrawFont == None)
	{
		Log("Q2DamageTrace RenderTexture skipped texture/font missing", 'Q2Damage');
		return;
	}

	DamageText = string(Damage);
	Texture.TextSize(DamageText, DrawFont, TextWidth, TextHeight);
	Texture.DrawTile(0, 0, Texture.USize, Texture.VSize, 0, 0,
		Texture.USize, Texture.VSize, TextureFallback, ClearColor);
	Texture.DrawText((Texture.USize - TextWidth) * 0.5, 8,
		DamageText, DrawFont, FontColor);
}

defaultproperties
{
     Damage=9998
     FontColor=(B=255,G=255,R=255,A=255)
     mStartParticles=0
     mMaxParticles=1
     mSpeedRange(0)=350.000000
     mSpeedRange(1)=350.000000
     mMassRange(0)=2.000000
     mMassRange(1)=2.000000
     mAirResistance=1.000000
     mSizeRange(0)=40.000000
     mSizeRange(1)=40.000000
     mAttenuate=False
     DrawType=DT_Sprite
     RemoteRole=ROLE_SimulatedProxy
     LifeSpan=1.000000
     Rotation=(Pitch=16383)
     Texture=None
     Skins(0)=None
     Style=STY_Alpha
}
