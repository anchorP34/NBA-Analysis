/*
Some notes about finding when a player enters or exits:

1. There are some examples where a player is playing in the 3rd quarter
    and then his next PosessionType is "Entering" when its the next quarter. 
    We're going to assume that at the end of the quarter there were substituions 
    made but not reported. Those need to be adjusted to exited at the end of the quarter.

2. There are games where the coach gets technical fouls, so we need to exclude him
    from being considered a player in the game

3. If a player enters in a quarter and then shows entering again the next quarter
    , we should assume they were taken out at the quarter

4. If a player was not in the game in the previous quarter and then has game play
    in the next quarter, we should assume they were substituded in at the beginning of the quarter


*/

drop view game_play_time ;

create table game_play_time 
(
    ID INTEGER PRIMARY KEY
    , DimGameID integer
    , Player TEXT
    , StartingTime integer
    , EndingTime integer
    , TotalTime integer
);

INSERT INTO game_play_time
(
    DimGameID
    , Player
    , StartingTime
    , EndingTime
    , TotalTime
)

with starting_players AS
(
    -- Find all of the starters for each game
    SELECT pbp_url
    , [Main Player] as Player
    from nba_play_by_play
    where [Main Player] != ''
    group by pbp_url
    , [Main Player]
    HAVING max(cast([Main Player Starter] as integer)) = 1 

    UNION

    SELECT pbp_url
    , [Secondary Player] as Player
    from nba_play_by_play
    where [Secondary Player] != ''
    group by pbp_url
    , [Secondary Player]
    HAVING max(cast([Secondary Player Starter] as integer)) = 1 
)

--select *
--from starting_players

, game_actions as 
(

SELECT -1 as GameIndex
, '1st Q' as Period
, '12:00:0' as Time
, pbp_url
, 4 * 12 * 60 as RemainingGameSeconds
, Player
, 'Starting of Game' as Posession
, 'Entering Game' as PosessionType
FROM starting_players

union all 

SELECT cast([Index] as integer) as GameIndex
, Period
, Time
, pbp_url
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

    else 0 end as RemainingGameSeconds
, [Main Player] as Player
, Posession
, case when Posession like '%enters%' then 'Entering Game' 
        else 'Other' end as PosessionType
from nba_play_by_play
where [Main Player] != ''
and Period not like '%OT%'

union ALL


SELECT cast([Index] as integer) as GameIndex
, Period
, Time
, pbp_url

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

    else 0 end as RemainingGameSeconds

, [Secondary Player] as Player
, Posession
, case when Posession like '%enters%' then 'Exiting Game' 
        else 'Other' end as PosessionType
from nba_play_by_play
where [Secondary Player] != ''
and Period not like '%OT%'

)

--select *
--from game_actions

, complete_involvement as 
(
    select dg.DimGameID
    , dg.PlayByPlayURL
    , ga.Period
    , ga.Time
    , ga.GameIndex
    , RemainingGameSeconds
    , Player
    , Posession
    , PosessionType
    , ifnull(lead(PosessionType) over (Partition by dg.DimGameID, Player order by ga.GameIndex), 'Game Completion') as NextPosessionType
    , ifnull(lead(RemainingGameSeconds) over (Partition by dg.DimGameID, Player order by ga.GameIndex), 0) as NextTimeGameSeconds
    , lead(Period) over (Partition by dg.DimGameID, Player order by ga.GameIndex) as NextPeriod
    , lead(ga.GameIndex) over (Partition by dg.DimGameID, Player order by ga.GameIndex) as PreviousGameIndex
    , ifnull(lag(PosessionType) over (Partition by dg.DimGameID, Player order by ga.GameIndex), 'Entering Game') as PreviousPosessionType
    , ifnull(lag(RemainingGameSeconds) over (Partition by dg.DimGameID, Player order by ga.GameIndex), 0) as PreviousTimeGameSeconds
    , lag(Period) over (Partition by dg.DimGameID, Player order by ga.GameIndex) as PreviousPeriod
    , lag(ga.GameIndex) over (Partition by dg.DimGameID, Player order by ga.GameIndex) as PreviousGameIndex
    from game_actions ga 
    inner join DimGame dg on dg.PlayByPlayURL  = ga.pbp_url
    where 1=1
--  and dg.DimGameID = 589

)
/*
select *
from complete_involvement
order by GameIndex
*/

, full_data as 
(
-- Should have been substituted out at the quarter
select DimGameID
--, PlayByPlayURL
, ifnull(NextPeriod, 
    case when Period = '1st Q' then '2nd Q'
        when Period = '2nd Q' then '3rd Q'
        when Period = '3rd Q' then '4th Q'
        end ) as Period
, GameIndex + 1 as GameIndex
, ifnull(
    case when NextPeriod = '2nd Q' then 12 * 60 * 3
        when NextPeriod = '3rd Q' then 12 * 60 * 2
        when NextPeriod = '4th Q' then 12 * 60 
    End 
    ,    case when Period = '1st Q' then 12 * 60 * 3
        when Period = '2nd Q' then 12 * 60 * 2
        when Period = '3rd Q' then 12 * 60 
        end )
    as GameRemainingSeconds
, Player
, 'Substituted Out During Period End' as Posession
, 'Exiting Game' as PosessionType
from complete_involvement
where (
        PosessionType = 'Other'
        and NextPosessionType = 'Entering Game'
        and Period != NextPeriod
    )
    or 
    (
        PosessionType = 'Entering Game'
        and NextPosessionType = 'Entering Game'
        and Period != NextPeriod
    )
    or 
    (
        -- People who miss a full quarter of play
        -- But ended the previous quarter
        Period != ifnull(NextPeriod, '')
        and Period != '4th Q'
        and NextPosessionType = 'Game Completion'


    )

union all 

-- Should have been entered in the game at the quarter
select DimGameID
--, PlayByPlayURL
, NextPeriod as Period
, GameIndex + 1 as GameIndex
, case when NextPeriod = '2nd Q' then 12 * 60 * 3
        when NextPeriod = '3rd Q' then 12 * 60 * 2
        when NextPeriod = '4th Q' then 12 * 60 
    End as GameRemainingSeconds
, Player
, 'Substituted In During Period End' as Posession
, 'Entering Game' as PosessionType
from complete_involvement
where (PosessionType = 'Exiting Game'
         and (NextPosessionType = 'Other' or NextPosessionType = 'Exiting Game')
         and Period != NextPeriod
    )
    OR
    (
        PosessionType = 'Other'
        and PreviousPosessionType = 'Entering Game'
        and Period != ifnull(PreviousPeriod, '')

    )
    

union ALL

-- Rest of the values that make sense
select DimGameID
--    , PlayByPlayURL
    , Period
    , GameIndex
    , RemainingGameSeconds
    , Player
    , Posession
    , PosessionType
from complete_involvement
where PosessionType != NextPosessionType

UNION ALL

-- Data point for completion of game for those who were in it
-- Want to exclude anyone who didn't play in the 4th Q
select DimGameID
--    , PlayByPlayURL
    , Period
    , GameIndex + 1
    , 0 as RemainingGameSeconds
    , Player
    , 'Game Completion' as Posession
    , 'Exiting Game' as PosessionType
from complete_involvement
where PosessionType in  ('Entering Game','Other')
    and NextPosessionType = 'Game Completion'
    and Period = '4th Q'

--order by GameIndex

)

/*
select *
from full_data
order by Player, GameIndex;
*/

, cleaned_data as 
(
    select *
    , lead(GameRemainingSeconds) over (Partition by DimGameID, Player order by GameIndex) as NextTime
    from full_data
    where PosessionType != 'Other'
 --   order by GameIndex
)

/*
select *
from cleaned_data
order by GameIndex
*/

select DimGameID
, Player
, GameRemainingSeconds as StartingTime
, ifnull(NextTime, 0) as EndingTime
, GameRemainingSeconds - ifnull(NextTime, 0) as TotalTime
from cleaned_data
where PosessionType = 'Entering Game'
and Player not like '/coaches/%'
--order by Player, StartingTime desc