with all_players as
(
    -- Find all of the starters for each game
    SELECT pbp_url
    , [Main Player] as Player
    , case when max(cast([Main Player Starter] as integer)) = 1 
        then 1 else 0 end as IsStarter
    from nba_play_by_play
    where [Main Player] != ''
    group by pbp_url
    , [Main Player]
)
, avail_periods as 
(
    SELECT distinct  Period
    from nba_play_by_play
    where Period not like '%OT%'
)
, fouls_per_period as
(
    select pbp_url
    , Period
    , [Main Player] as Player
    , sum(1) as Fouls
    from nba_play_by_play
    where  posession like '%foul%'
            and posession not like '%tech%'
            and posession not like '%turnover%'
    group by pbp_url
    , Period
    , [Main Player] 
) 
, results as 
(
    select s.pbp_url 
    , s.Player
    , s.IsStarter
    , p.Period
    , ifnull(Fouls, 0) as Fouls
    from all_players s
    cross join avail_periods p 
    left join fouls_per_period fpp on fpp.pbp_url = s.pbp_url
                                    and fpp.Player = s.Player
                                    and p.Period = fpp.Period
)
, final_game_fouls as
(
    select pbp_url
    , Player
    , sum(Fouls) as FinalFoulCount
    from results
    group by pbp_url
    , Player
    , IsStarter
)

select dg.DimGameID
, r.Player
, r.IsStarter
, r.Fouls
, sum(r.Fouls) over (partition by r.pbp_url, r.Player order by Period) as RollingFoulCount
, f.FinalFoulCount
from results r
join final_game_fouls f on f.pbp_url = r.pbp_url
                        and f.Player = r.Player
join DimGame dg on 'https://www.basketball-reference.com' || dg.PlayByPlayURL = r.pbp_url
where r.IsStarter = 1