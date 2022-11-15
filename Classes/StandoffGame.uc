class StandoffGame extends CTFGame;

var bool bShouldRandomizeFlags;
var int NextRoundCountdown;
var bool bRoundOver;

event InitGame( string Options, out string Error )
{
  Super.InitGame(Options, Error);
  bRoundOver = True;
}

function Timer()
{
  local Pawn P;

  Super.Timer();

  // if (bShouldRandomizeFlags) {
  //   bShouldRandomizeFlags = false;

  //   foreach AllActors(class'CTFFlag', Flag) {
  //     for (t = 0; t < MaxTeams; t++) {
  //       if (t != Flag.Team) {
  //         j = Rand(Teams[t].Size);
  //         for (P = Level.PawnList; P != None; P = P.nextPawn) {
  //           if (P.bIsPlayer && P.PlayerReplicationInfo.Team == t) {
  //             if (j == 0) {
  //               Level.Game.RestartPlayer(P);
  //               Flag.Touch(P);
  //               break;
  //             }
  //             j--;
  //           }
  //         }
  //       }
  //     }
  //   }
  // }

  /*
    - Look at StartMatch/PlayerRestartState to control respawn state
      between rounds
    - Look at TeamScoreboard as an example of looping through pawn list
      and splitting into teams
  */
  if (!bGameEnded) {
    if (!bRequireReady || CountDown <= 0) {
      if (bRoundOver) {
        if (NextRoundCountdown > 0) {
          for (P = Level.PawnList; P != None; P = P.nextPawn) {
            if (P.IsA('PlayerPawn')) {
              PlayerPawn(P).ClearProgressMessages();
              if ( (NextRoundCountdown < 11) && P.IsA('TournamentPlayer') )
                TournamentPlayer(P).TimeMessage(NextRoundCountdown);
              else
                PlayerPawn(P).SetProgressMessage(NextRoundCountdown$CountDownMessage, 0);
            }
          }
          NextRoundCountdown--;
        } else {
          bRoundOver = false;
          BeginRound();
        }
      }
    }
  }
}

function StartMatch() {
  Super.StartMatch();
  BeginRound();
}

function EndRound() {
  // bShouldRandomizeFlags = true;
  bRoundOver = true;
  NextRoundCountdown = 3;
}

function BeginRound() {
  local Pawn P;
  local int t;
  local int ChosenFlagHolder[4];
  local int TeamLoopIndex[4];
  local CTFFlag Flags[4];
  local CTFFlag Flag;

  // Store a reference to each flag by team index
  foreach AllActors(class'CTFFlag', Flag) {
    Flags[Flag.Team] = Flag;
  }

  // Select one player on each team at random and give them the opposing team's
  // flag and spawn them at their own flag.
  for (t = 0; t < MaxTeams; t++) {
    ChosenFlagHolder[t] = Rand(Teams[t].Size);
  }

  for (P = Level.PawnList; P != None; P = P.nextPawn) {
    if (P.PlayerReplicationInfo.Team >= 0 && P.PlayerReplicationInfo.Team <= 4) {

      if (TeamLoopIndex[P.PlayerReplicationInfo.Team] == ChosenFlagHolder[P.PlayerReplicationInfo.Team]) {
        // Give the flag to the designated flag holder
        Flags[P.PlayerReplicationInfo.Team ^ 1].Touch(P);

        // Warp them to their own flag stand
        // P.SetLocation(Flags[P.PlayerReplicationInfo.Team].HomeBase.Location);
        // P.SetRotation(Flags[P.PlayerReplicationInfo.Team].HomeBase.Rotation);
      }

      TeamLoopIndex[P.PlayerReplicationInfo.Team]++;
    }
  }
}

function ScoreFlag(Pawn Scorer, CTFFlag theFlag)
{
  local pawn TeamMate;
  local Actor A;

  if ( Scorer.PlayerReplicationInfo.Team == theFlag.Team )
  {
    if (Level.Game.WorldLog != None)
    {
      Level.Game.WorldLog.LogSpecialEvent("flag_returned", Scorer.PlayerReplicationInfo.PlayerID, Teams[theFlag.Team].TeamIndex);
    }
    if (Level.Game.LocalLog != None)
    {
      Level.Game.LocalLog.LogSpecialEvent("flag_returned", Scorer.PlayerReplicationInfo.PlayerID, Teams[theFlag.Team].TeamIndex);
    }
    BroadcastLocalizedMessage( class'CTFMessage', 1, Scorer.PlayerReplicationInfo, None, TheFlag );
    for ( TeamMate=Level.PawnList; TeamMate!=None; TeamMate=TeamMate.NextPawn )
    {
      if ( TeamMate.IsA('PlayerPawn') )
        PlayerPawn(TeamMate).ClientPlaySound(ReturnSound);
      else if ( TeamMate.IsA('Bot') )
        Bot(TeamMate).SetOrders(BotReplicationInfo(TeamMate.PlayerReplicationInfo).RealOrders, BotReplicationInfo(TeamMate.PlayerReplicationInfo).RealOrderGiver, true);
    }
    return;
  }

  if ( bRatedGame && Scorer.IsA('PlayerPawn') )
    bFulfilledSpecial = true;
  Scorer.PlayerReplicationInfo.Score += 7;
  Teams[Scorer.PlayerReplicationInfo.Team].Score += 1.0;

  for ( TeamMate=Level.PawnList; TeamMate!=None; TeamMate=TeamMate.NextPawn )
  {
    if ( TeamMate.IsA('PlayerPawn') )
      PlayerPawn(TeamMate).ClientPlaySound(CaptureSound[Scorer.PlayerReplicationInfo.Team]);
    else if ( TeamMate.IsA('Bot') )
      Bot(TeamMate).SetOrders(BotReplicationInfo(TeamMate.PlayerReplicationInfo).RealOrders, BotReplicationInfo(TeamMate.PlayerReplicationInfo).RealOrderGiver, true);
  }

  if (Level.Game.WorldLog != None)
  {
    Level.Game.WorldLog.LogSpecialEvent("flag_captured", Scorer.PlayerReplicationInfo.PlayerID, Teams[theFlag.Team].TeamIndex);
  }
  if (Level.Game.LocalLog != None)
  {
    Level.Game.LocalLog.LogSpecialEvent("flag_captured", Scorer.PlayerReplicationInfo.PlayerID, Teams[theFlag.Team].TeamIndex);
  }
  EndStatsClass.Default.TotalFlags++;
  BroadcastLocalizedMessage( class'CTFMessage', 0, Scorer.PlayerReplicationInfo, None, TheFlag );
  if ( theFlag.HomeBase.Event != '' )
    foreach AllActors(class'Actor', A, theFlag.HomeBase.Event )
      A.Trigger(theFlag.HomeBase,	Scorer);

  if ( (bOverTime || (GoalTeamScore != 0)) && (Teams[Scorer.PlayerReplicationInfo.Team].Score >= GoalTeamScore) )
    EndGame("teamscorelimit");
  else if ( bOverTime )
    EndGame("timelimit");

  EndRound();
}