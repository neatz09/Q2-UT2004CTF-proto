class AutoTechPickup extends UDamagePack;

var AutoTechPickup OriginPickup;

function InitDroppedPickupFor(Inventory Inv)
{
    Super.InitDroppedPickupFor(Inv);
    if (AutoDocEffect(Inv) != None)
        OriginPickup = AutoDocEffect(Inv).OriginPickup;
    LifeSpan = 30.0;
}

function ReturnToOrigin()
{
    if (bDropped && OriginPickup != None && OriginPickup != self && !OriginPickup.bDeleteMe)
        OriginPickup.GotoState('Pickup');
}

function Destroyed()
{
    ReturnToOrigin();
    Super.Destroyed();
}

function float BotDesireability(Pawn Bot)
{
    return MaxDesireability;
}

auto state Pickup
{
    function Touch(Actor Other)
    {
        local Pawn P;
        local AutoDocEffect Effect;

        if (ValidTouch(Other))
        {
            P = Pawn(Other);
            if (!bDropped && OriginPickup == None)
                OriginPickup = self;
            Effect = AutoDocEffect(P.FindInventoryType(class'AutoDocEffect'));
            if (Effect == None)
            {
                Effect = Spawn(class'AutoDocEffect', P);
                if (Effect != None)
                    Effect.GiveTo(P);
            }
            if (Effect != None)
                Effect.OriginPickup = OriginPickup;
            AnnouncePickup(P);
            SetRespawn();
        }
    }
}

defaultproperties
{
     MaxDesireability=3.000000
     PickupMessage="AUTODOC: HEALTH AND ARMOUR REGEN"
}
