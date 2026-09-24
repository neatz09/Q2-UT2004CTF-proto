class MutAutoTech extends Mutator;

var config bool bEnableAutoTech;
var localized string EnableAutoTechText;
var localized string EnableAutoTechDesc;

static function FillPlayInfo(PlayInfo PlayInfo)
{
    Super.FillPlayInfo(PlayInfo);
    PlayInfo.AddSetting(default.RulesGroup, "bEnableAutoTech", default.EnableAutoTechText, 0, 1, "Check");
}

static event string GetDescriptionText(string PropName)
{
    if (PropName == "bEnableAutoTech")
        return default.EnableAutoTechDesc;

    return Super.GetDescriptionText(PropName);
}

function bool IsAutoTechEnabled()
{
    local Mutator CurrentMutator;

    CurrentMutator = Level.Game.BaseMutator;
    while (CurrentMutator != None)
    {
        if (CurrentMutator.IsA('MutAutoTech'))
            return MutAutoTech(CurrentMutator).bEnableAutoTech;
        CurrentMutator = CurrentMutator.NextMutator;
    }

    return bEnableAutoTech;
}

function Mutate(string MutateString, PlayerController Sender)
{
    if (MutateString ~= "SelectGrapple")
    {
        SelectGrapple(Sender);
        return;
    }

    if (IsAutoTechEnabled() && MutateString ~= "DropRune")
    {
        DropRune(Sender);
        return;
    }

    Super.Mutate(MutateString, Sender);
}

function SelectGrapple(PlayerController Sender)
{
    if (Sender == None || Sender.Pawn == None)
        return;

    Sender.Pawn.SwitchWeapon(10);
}

function DropRune(PlayerController Sender)
{
    local Q2TechItem Tech;
    local vector X;
    local vector Y;
    local vector Z;
    local vector DropLocation;

    if (Sender == None || Sender.Pawn == None)
        return;

    Tech = Q2TechItem(Sender.Pawn.FindInventoryType(class'Q2TechItem'));
    if (Tech == None)
        return;

    GetAxes(Sender.Pawn.Rotation, X, Y, Z);
    DropLocation = Sender.Pawn.Location + X * (Sender.Pawn.CollisionRadius + 64.0) + Z * 20.0;
    Tech.Velocity = X * 325.0 + Z * 160.0;
    Tech.DropFrom(DropLocation);
}

function bool ReplacePickup(Actor Other)
{
    local Pickup OldPickup;
    local Pickup NewPickup;

    OldPickup = Pickup(Other);
    NewPickup = Spawn(class'AutoTechPickup', Other.Owner, Other.Tag, Other.Location, Other.Rotation);
    if (NewPickup == None)
        return false;

    NewPickup.RespawnTime = OldPickup.RespawnTime;
    NewPickup.Event = Other.Event;
    NewPickup.Tag = Other.Tag;
    if (OldPickup.MyMarker != None)
    {
        NewPickup.MyMarker = OldPickup.MyMarker;
        NewPickup.MyMarker.MarkedItem = NewPickup;
        NewPickup.SetLocation(NewPickup.Location
            + (NewPickup.CollisionHeight - OldPickup.CollisionHeight) * vect(0,0,1));
        OldPickup.MyMarker = None;
    }

    Other.Destroy();
    return true;
}

function bool CheckReplacement(Actor Other, out byte bSuperRelevant)
{
    if (Other.IsA('UDamagePack') && !Other.IsA('Q2QuadPickup'))
    {
        ReplaceWith(Other, "Q2CTFMod.Q2QuadPickup");
        return false;
    }

    return true;
}

defaultproperties
{
     bEnableAutoTech=True
     EnableAutoTechText="Enable AutoDoc"
     EnableAutoTechDesc="Replace UDamage pickups with the AutoDoc health and armour regeneration rune."
     GroupName="AutoTech"
     FriendlyName="AutoDoc"
     Description="Replaces the UDamage amp with the AutoDoc health and armour regeneration rune."
}
