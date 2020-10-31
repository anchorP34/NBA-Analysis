create VIEW avg_clean_play_time as

with foul_games as 
(
    select DimGameID
    , Player
    , max(case when Period = '1st Q' and RollingFoulCount > 1 then 1
            when Period = '2nd Q' and RollingFoulCount > 2 then 1
            when Period = '3rd Q' and RollingFoulCount > 3 then 1
            when Period = '4th Q' and RollingFoulCount in (5,6) then 1
            else 0 end
    ) as FoulTroubleGame
    from foul_information fi
    group by DimGameID
    , Player
)
, non_foul_trouble_play_time as
(
    SELECT gpt.DimGameID
    , gpt.Player
    , sum(TotalTime) as GamePlayTime
    from game_play_time gpt
    inner join foul_games fg on fg.Player = gpt.Player
                            and fg.DimGameID = gpt.DimGameID
    where FoulTroubleGame = 0
    group by gpt.DimGameID
    , gpt.Player
)
SELECT Player
, ROUND(avg(GamePlayTime)) as avg_game_play
from non_foul_trouble_play_time
--where Player = '/players/a/anunoog01.html'
group by Player