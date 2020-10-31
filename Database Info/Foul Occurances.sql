with all_players as
(
    -- Find all of the starters for each game
    SELECT DimGameID
    , MainPlayer as Player
    , case when max(cast(MainPlayerStarter as integer)) = 1 
        then 1 else 0 end as IsStarter
    from FactPlayByPlay
    where MainPlayer != ''
    and MainPlayer not like '%coach%'
    group by DimGameID
    , MainPlayer

    UNION

    SELECT DimGameID
    , SecondaryPlayer as Player
    , case when max(cast(SecondaryPlayerStarter as integer)) = 1 
        then 1 else 0 end as IsStarter
    from FactPlayByPlay
    where SecondaryPlayer != ''
    and SecondaryPlayer not like '%coach%'
    group by DimGameID
    , SecondaryPlayer

)
, avail_periods as 
(
    SELECT distinct  Period
    from nba_play_by_play
    where Period not like '%OT%'
)
, game_fouls as
(
    select DimGameID
    , Period
    , MainPlayer as Player
    , PersonalFoul
    , sum(PersonalFoul) over (Partition By DimGameID, MainPlayer order by GameIndex) as GameFouls
    from FactPlayByPlay
    where  PersonalFoul = 1
            and posession not like '%tech%'
            and posession not like '%turnover%'
) 
, foul_out_players as 
(
    select DimGameID
    , Player
    from game_fouls
    where GameFouls = 6

)

select players.DimGameID
, players.Player
, periods.Period
, max(ifnull(f.GameFouls,0)) over (Partition by players.DimGameID, players.Player
                        order by periods.Period, ifnull(f.GameFouls, 0)
                        ) as GameFouls
, case when foul_out.Player is null then 0 else 1 end as FouledOutOfGame
from all_players players
cross join avail_periods periods
left join game_fouls f on f.DimGameID = players.DimGameID 
                        and f.Player = players.Player
                        and f.Period = periods.Period
left join foul_out_players foul_out on foul_out.DimGameID = players.DimGameID
                                    and foul_out.Player = players.Player
where isStarter = 1
--and players.DimGameID = 1 
--and players.Player = '/players/a/alexani01.html'