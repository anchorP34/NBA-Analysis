with players as
(
    select DimGameID
    , MainPlayer as Player
    , max(MainPlayerStarter) as GameStarter
    from FactPlayByPlay
    where MainPlayer != ''
    group by DimGameID
    , MainPlayer

    union

    select DimGameID
    , SecondaryPlayer
    , max(SecondaryPlayerStarter)
    from FactPlayByPlay
    where SecondaryPlayer != ''
    group by DimGameID
    , SecondaryPlayer
)
, games_played as
(
    SELECT Player
    , sum(GameStarter) as GameStarts
    , count(DISTINCT DimGameID) as GamesPlayed
    from players
    group by Player
)
, scoring_stats as 
(
    select MainPlayer as Player
    , sum(IsRebound) as Rebounds
    , sum(MissedShot) as MissedShots
    , sum(MadeShot) as MadeShots
    , sum(ThreePointAttempt) as ThreePointAttempts
    , sum(case when MadeShot = 1 and ThreePointAttempt = 1 then 1 else 0 end) as ThreePointsMade
    , sum(TwoPointAttempt) as TwoPointAttempts
    , sum(case when MadeShot = 1 and TwoPointAttempt = 1 then 1 else 0 end) as TwoPointsMade
    , sum(Points) as Points
    , sum(FreeThrow) as FreeThrowAttempts
    , sum(PersonalFoul) as PersonalFouls
    from FactPlayByPlay
    where MainPlayer != ''
    group by MainPlayer

)
, assists as
(
    select SecondaryPlayer as Player
    , sum(AssistOnPosession) as Assists
    from FactPlayByPlay
    where SecondaryPlayer != ''
    group by SecondaryPlayer

)
, time_played as 
(
    select Player
    , sum(TotalTime) as TotalTimePlayed
    , sum(TotalTime) / count(Distinct DimGameID) as SecondsPerGame
    from game_play_time
    group by Player
)

select gp.Player
, gp.GameStarts
, gp.GamesPlayed
, ifnull(ss.Rebounds, 0) as Rebounds
, ifnull(ss.MissedShots, 0) as MissedShots
, ifnull(ss.MadeShots, 0) as MadeShots
, ifnull(ss.ThreePointAttempts, 0) as ThreePointAttempts
, ifnull(ss.ThreePointsMade, 0) as ThreePointsMade
, ifnull(ss.TwoPointAttempts, 0) as TwoPointAttempts
, ifnull(ss.TwoPointsMade, 0) as TwoPointsMade
, ifnull(ss.Points, 0) as Points
, ifnull(ss.FreeThrowsMade, 0) as FreeThrowsMade
, ifnull(ss.PersonalFouls, 0) as PersonalFouls
, ifnull(a.Assists, 0) as Assists
, ifnull(tp.TotalTimePlayed, 0) as TotalTimePlayed
, ifnull(tp.SecondsPerGame, 0) as SecondsPerGame
from games_played gp
left join scoring_stats ss on ss.Player = gp.player
left join assists a on a.Player = gp.Player
left join time_played tp on tp.Player = gp.Player
where gp.GamesPlayed >= 10
and ifnull(TotalTimePlayed, 0) > 28800 
and ifnull(ss.Points, 0) > 0

