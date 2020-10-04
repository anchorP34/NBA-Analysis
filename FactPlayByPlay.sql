drop view if exists FactPlayByPlay;

create view FactPlayByPlay
AS

select dg.DimGameID
, cast(nba_pbp.[Index] as integer) as GameIndex
, DimTeamID_Away
, away_team.TeamName as AwayTeam
, DimTeamID_Home
, home_team.TeamName as HomeTeam
, case when nba_pbp.Team = 'Home' then home_team.TeamName 
        else away_team.TeamName end as PosessionTeam
, nba_pbp.Team as PosessionTeamType
, dp.DimPeriodID
, nba_pbp.Period
, time
, cast(substr( time, 1, 2 ) as integer) * 60
    + cast(substr( time, 4, 2 ) as integer) as RemainigPeriodSeconds
, case when Period = '1st Q' then case when INSTR(Time, ':') = 3 
                                then cast(substr( time, 1, 2 ) as integer)
                                else cast(substr( time, 1, 1 ) as integer) end  * 60
                + case when INSTR(Time, ':') = 3 
                then cast(substr( time, 4, 2 ) as integer)
                else cast(substr( time, 3, 2 ) as integer) end  + 3 * 12 * 60

        when Period = '2nd Q' then case when INSTR(Time, ':') = 3 
                                    then cast(substr( time, 1, 2 ) as integer)
                                    else cast(substr( time, 1, 1 ) as integer) end  * 60
                + case when INSTR(Time, ':') = 3 
                then cast(substr( time, 4, 2 ) as integer)
                else cast(substr( time, 3, 2 ) as integer) end  + 2 * 12 * 60

        when Period = '3rd Q' then case when INSTR(Time, ':') = 3 
                                        then cast(substr( time, 1, 2 ) as integer)
                                        else cast(substr( time, 1, 1 ) as integer) end  * 60
                + case when INSTR(Time, ':') = 3 
                then cast(substr( time, 4, 2 ) as integer)
                else cast(substr( time, 3, 2 ) as integer) end  + 1 * 12 * 60

        when Period = '4th Q' then case when INSTR(Time, ':') = 3 
                                        then cast(substr( time, 1, 2 ) as integer)
                                        else cast(substr( time, 1, 1 ) as integer) end  * 60
                + case when INSTR(Time, ':') = 3 
                then cast(substr( time, 4, 2 ) as integer)
                else cast(substr( time, 3, 2 ) as integer) end 

    else 0 end as RemainingRegulationSeconds
, Posession
, [Main Player] as MainPlayer
, [Secondary Player] as SecondaryPlayer
, [Main Player Starter] as MainPlayerStarter
, [Secondary Player Starter] as SecondaryPlayerStarter
, case when Posession like 'Offensive rebound%'
       or Posession like 'Defensive rebound%'
       or Posession like '%rebound%' then 1
       else 0 end as IsRebound
, case when Posession like 'Offensive rebound%' then 1 else 0 end OffensiveRebound
, case when Posession like 'Defensive rebound%' then 1 else 0 end DefensiveRebound
, case when Posession like '%misses%' then 1 else 0 end as MissedShot
, case when Posession like '%makes%' then 1 else 0 end as MadeShot
, case when Posession like '%3-pt%' then 1 else 0 end as ThreePointAttempt
, case when Posession like '%2-pt%' then 1 else 0 end as TwoPointAttempt
, case when Posession like '%assist%' then 1 else 0 end as AssistOnPosession
, case when Points != '' then cast(substr( Points, 2, 1 ) as integer) else 0 end as Points
, case when Posession like '%free throw%' then 1 else 0 end as FreeThrow
, case when Posession like '%foul%' and Posession not like '%tech%' then 1 else 0 end as PersonalFoul
, case when Posession like '%foul%' and Posession like '%tech%' then 1 else 0 end as TechnicalFoul
, case when Posession like '%timeout%' then 1 else 0 end as Timeout
, case when Posession like '%enters the game%' then 1 else 0 end as Substitution
from nba_play_by_play nba_pbp
inner join DimPeriod dp on dp.PeriodName = nba_pbp.Period
inner join DimGame dg on dg.PlayByPlayURL  = nba_pbp.pbp_url
inner join DimTeam home_team on home_team.DimTeamID = dg.DimTeamID_Home
inner join DimTeam away_team on away_team.DimTeamID = dg.DimTeamID_Away
where dp.IsOvertime = 0 -- Look for Quarters 1-4
order by dg.DimGameID
    , GameIndex
--limit 100;


select *
from FactPlayByPlay
limit 10;