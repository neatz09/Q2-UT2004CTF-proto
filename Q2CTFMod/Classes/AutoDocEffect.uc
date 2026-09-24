class AutoDocEffect extends Q2TechItem;

const AUTODOC_MAX_VALUE = 150;

var AutoTechPickup OriginPickup;
var xEmitter BoosterEffect;

function OnTechGained(Pawn P)
{
    if (P.Role == ROLE_Authority)
        BoosterEffect = Spawn(class'RegenCrosses', P,, P.Location, P.Rotation);
}

function OnTechLost(Pawn P)
{
    if (BoosterEffect != None)
        BoosterEffect.Destroy();
    BoosterEffect = None;
}

function PostBeginPlay()
{
    Super.PostBeginPlay();
    SetTimer(1.0, true);
}

function Timer()
{
    local Pawn P;
    local float HealthValue;
    local float ArmorValue;
    local int HealthAmount;
    local int ArmorAmount;

    P = Pawn(Owner);
    if (P == None || P.Health <= 0)
        return;

    HealthValue = P.Health;
    ArmorValue = P.GetShieldStrength();

    if (HealthValue >= AUTODOC_MAX_VALUE && ArmorValue >= AUTODOC_MAX_VALUE)
        return;

    if (HealthValue >= AUTODOC_MAX_VALUE)
    {
        ArmorAmount = 10;
        HealthAmount = 0;
    }
    else if (ArmorValue >= AUTODOC_MAX_VALUE)
    {
        HealthAmount = 10;
        ArmorAmount = 0;
    }
    else
    {
        HealthAmount = 5;
        ArmorAmount = 5;
    }

    if (HealthAmount > 0)
        P.Health = FMin(AUTODOC_MAX_VALUE, HealthValue + HealthAmount);
    if (ArmorAmount > 0)
        P.AddShieldStrength(ArmorAmount);
}

defaultproperties
{
     PickupClass=Class'Q2CTFMod.Q2AutoDocPickup'
}
