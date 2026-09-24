class Q2QuadDamageRules extends GameRules;

function ScoreKill(Controller Killer, Controller Killed)
{
	local Q2PlayerPawn DeadPawn;
	local Q2QuadPickup DroppedQuad;
	local float RemainingTime;

	if (Killed != None)
	{
		DeadPawn = Q2PlayerPawn(Killed.Pawn);
		if (DeadPawn != None && DeadPawn.QuadDamageMultiplier != 1.0)
		{
			RemainingTime = DeadPawn.QuadDamageTime - Level.TimeSeconds;
			if (RemainingTime > 0.0)
			{
				DroppedQuad = Spawn(class'Q2QuadPickup',,, DeadPawn.Location);
				if (DroppedQuad != None)
				{
					DroppedQuad.RemainingTime = RemainingTime;
					DroppedQuad.DropStartTime = Level.TimeSeconds;
					DroppedQuad.bDropped = True;
					DroppedQuad.AddToNavigation();
					DroppedQuad.SetPhysics(PHYS_Falling);
					DroppedQuad.Velocity = vect(0,0,200);
					DroppedQuad.SetTimer(RemainingTime, False);
				}
			}

			DeadPawn.QuadDamageMultiplier = 1.0;
			DeadPawn.ClearQuadDamageTime();
		}
	}

	Super.ScoreKill(Killer, Killed);
}

defaultproperties
{
}
