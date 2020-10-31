/*
=======================================
SECTION: Foul Trouble Subs
======================================= 
Description: How often does someone get a foul
and then immediately get taken out of the game?

Is there a difference between whether they are in
foul trouble or not?

======================================= 
======================================= 
*/

with fouls as 
(
    select DimGameID
    , MainPlayer
    , Period
    , RemainingRegulationSeconds
    , SUM(PersonalFoul) over 
            (Partition by DimGameID
    , MainPlayer order by RemainingRegulationSeconds DESC) as GameFouls
    from FactPlayByPlay
    where PersonalFoul = 1
    and Posession not like '%turnover%'
)
, full_data as 
(
    -- This will get all of the times where a player fouled
    select DimGameID
    , MainPlayer
    , CASE WHEN GameFouls >= 2 and Period = '1st Q' then 1
        when GameFouls >= 3 and Period = '2nd Q' then 1
        when GameFouls >= 4 and Period = '3rd Q' then 1
        when GameFouls = 5 and Period = '4th Q' then 1
        else 0 end as QualifyingFoulTrouble 
    , Period
    , RemainingRegulationSeconds as Time
    , 'Foul' as Type
    from fouls

    union ALL

    -- This will get all of the substitution times
    select DimGameID
    , Player
    , NULL
    , NULL
    , EndingTime
    , 'Substitution' as Type
    from game_play_time
)
, comparisons as 
(
    select *
    , lead(Time) over (Partition by DimGameID, MainPlayer
                    order by Time DESC,
                    case when Type = 'Foul' then 0 else 1 end) as NextTime
    , lead(Type) over (Partition by DimGameID, MainPlayer
                    order by Time DESC,
                    case when Type = 'Foul' then 0 else 1 end) as NextType
    from full_data
--    where DimGameID = 2
--    and MainPlayer = '/players/b/beverpa01.html'
--    order by Time DESC,
--        case when Type = 'Foul' then 0 else 1 end
)

select *
, case when Type = 'Foul'
        and NextType = 'Substitution'
        and NextTime = Time 
        then 1 else 0 end as ImmediateSub
from comparisons
where type = 'Foul'
order by DimGameID, 
    MainPlayer, 
    Time DESC,
    case when Type = 'Foul' then 0 else 1 end