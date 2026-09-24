class Q2RuneHudOverlay extends HudOverlay;

#exec OBJ LOAD FILE=HudContent.utx

var PlayerController PlayerOwner;
var Texture RuneIcons[5];
var float IconSize;
var float IconGap;
var Font DamageFont;
var int DamageValues[8];
var float DamageExpireTimes[8];
var int DamageCount;

simulated function SetRunePlayer(PlayerController NewOwner)
{
	PlayerOwner = NewOwner;
}

simulated function Render(Canvas C)
{
	local Pawn P;
	local float X;
	local int Index;

	if (PlayerOwner == None || PlayerOwner.Pawn == None)
		return;

	P = PlayerOwner.Pawn;
	X = C.SizeX - (IconSize + IconGap) * 5.0;
	for (Index = 0; Index < 5; Index++)
	{
		if (HasRune(P, Index))
		{
			C.SetDrawColor(255, 255, 255, 255);
			C.SetPos(X + (IconSize + IconGap) * Index, 32.0);
			C.DrawIcon(RuneIcons[Index], IconSize / 64.0);
		}
	}

	if (Q2PlayerPawn(P) != None && Q2PlayerPawn(P).QuadDamageTime > Level.TimeSeconds)
		DrawQuadHud(C, int(Q2PlayerPawn(P).QuadDamageTime - Level.TimeSeconds + 0.99));

	DrawDamagePopups(C);
}

simulated function AddDamage(int DamageAmount)
{
	local int Index;

	if (DamageAmount <= 0)
		return;

	if (DamageCount < ArrayCount(DamageValues))
	{
		Index = DamageCount;
		DamageCount += 1;
	}
	else
	{
		for (Index = 1; Index < ArrayCount(DamageValues); Index++)
		{
			DamageValues[Index - 1] = DamageValues[Index];
			DamageExpireTimes[Index - 1] = DamageExpireTimes[Index];
		}
		Index = ArrayCount(DamageValues) - 1;
	}

	DamageValues[Index] = DamageAmount;
	DamageExpireTimes[Index] = Level.TimeSeconds + 1.0;
}

simulated function DrawDamagePopups(Canvas C)
{
	local int Index;
	local int ActiveCount;
	local float CenterX;
	local float StartY;
	local float DrawY;
	local float TextWidth;
	local float TextHeight;
	local color PopupColor;

	for (Index = 0; Index < DamageCount; Index++)
	{
		if (DamageExpireTimes[Index] > Level.TimeSeconds)
		{
			DamageValues[ActiveCount] = DamageValues[Index];
			DamageExpireTimes[ActiveCount] = DamageExpireTimes[Index];
			ActiveCount += 1;
		}
	}
	DamageCount = ActiveCount;
	if (DamageCount == 0)
		return;

	if (DamageFont == None)
		DamageFont = Font(DynamicLoadObject("UT2003Fonts.FontEurostile14", class'Font'));
	if (DamageFont == None)
		DamageFont = Font(DynamicLoadObject("Engine.DefaultFont", class'Font'));
	if (DamageFont != None)
		C.Font = DamageFont;

	CenterX = C.SizeX * 0.5;
	StartY = C.SizeY * 0.42;
	C.Style = ERenderStyle.STY_Alpha;
	for (Index = 0; Index < DamageCount; Index++)
	{
		if (DamageValues[Index] < 30)
		{
			PopupColor.R = 255;
			PopupColor.G = 255;
			PopupColor.B = 255;
		}
		else if (DamageValues[Index] < 50)
		{
			PopupColor.R = 64;
			PopupColor.G = 255;
			PopupColor.B = 64;
		}
		else if (DamageValues[Index] <= 70)
		{
			PopupColor.R = 255;
			PopupColor.G = 220;
			PopupColor.B = 32;
		}
		else
		{
			PopupColor.R = 255;
			PopupColor.G = 64;
			PopupColor.B = 64;
		}

		C.SetDrawColor(PopupColor.R, PopupColor.G, PopupColor.B, 255);
		C.TextSize(string(DamageValues[Index]), TextWidth, TextHeight);
		DrawY = StartY - (DamageCount - Index - 1) * (TextHeight + 4.0);
		C.SetPos(CenterX - TextWidth * 0.5, DrawY);
		C.DrawText(string(DamageValues[Index]), False);
	}
}

simulated function DrawQuadHud(Canvas C, int Seconds)
{
	local float CenterX;
	local float CenterY;
	local int Tens;
	local int Ones;

	CenterX = C.SizeX * 0.95;
	CenterY = C.SizeY * 0.75;
	Tens = Seconds / 10;
	Ones = Seconds - Tens * 10;

	C.Style = ERenderStyle.STY_Alpha;
	C.SetDrawColor(255, 255, 255, 255);
	C.SetPos(CenterX - 27.375, CenterY - 30.75);
	C.DrawTile(Material'HudContent.Generic.HUD', 54.75, 61.5, 0.0, 164.0, 73.0, 82.0);

	C.SetPos(CenterX - 19.11, CenterY - 9.31);
	C.DrawTile(Material'HudContent.Generic.HUD', 18.62, 18.62,
		Tens * 39.0, 0.0, 39.0, 38.0);
	C.SetPos(CenterX + 0.49, CenterY - 9.31);
	C.DrawTile(Material'HudContent.Generic.HUD', 18.62, 18.62,
		Ones * 39.0, 0.0, 39.0, 38.0);
}

simulated function bool HasRune(Pawn P, int RuneIndex)
{
	switch (RuneIndex)
	{
	case 0:
		return P.FindInventoryType(class'Q2PowerAmpTech') != None;
	case 1:
		return P.FindInventoryType(class'Q2ResistTech') != None;
	case 2:
		return P.FindInventoryType(class'AutoDocEffect') != None;
	case 3:
		return P.FindInventoryType(class'Q2TimeAcceleratorTech') != None;
	case 4:
		return P.FindInventoryType(class'Q2KeysnerGrappleTech') != None;
	}

	return False;
}

defaultproperties
{
     RuneIcons(0)=Texture'XRelicsTextures.HUD.STRmini'
     RuneIcons(1)=Texture'XRelicsTextures.HUD.DEFmini'
     RuneIcons(2)=Texture'XRelicsTextures.HUD.HEAmini'
     RuneIcons(3)=Texture'XRelicsTextures.HUD.HASmini'
     RuneIcons(4)=Texture'XRelicsTextures.HUD.AGImini'
     IconSize=48.000000
     IconGap=8.000000
}
