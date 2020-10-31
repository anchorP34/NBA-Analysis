drop table if exists DimGame;
create table DimGame
(
    DimGameID INTEGER PRIMARY KEY
    , DimCalendarID INTEGER
    , DimTeamID_Away INTEGER
    , DimTeamID_Home INTEGER
    , AwayScore INTEGER
    , HomeScore INTEGER
    , IsOvertimeGame INTEGER
    , IsPlayoffGame INTEGER
    , BoxscoreURL TEXT
    , PlayByPlayURL TEXT
);

INSERT INTO DimGame
(
    DimCalendarID 
    , DimTeamID_Away 
    , DimTeamID_Home 
    , AwayScore 
    , HomeScore 
    , IsOvertimeGame 
    , IsPlayoffGame 
    , BoxscoreURL 
    , PlayByPlayURL     
)

select dc.DimCalendarID
, away_team.DimTeamID as DimTeamID_Away
, home_team.DimTeamID as DimTeamID_Home
, game_results.AwayScore 
, game_results.HomeScore 
, game_results.IsOvertimeGame
, gi.[Playoff Game] as IsPlayoffGame
, gi.[Boxscore URL] as BoxscoreURL 
, gi.[Play By Play URL] as PlayByPlayURL
from game_info gi
inner join (
    SELECT pbp_url
    , max(case when Team = 'Away' then cast(Score as integer) else NULL end) as AwayScore
    , max(case when Team = 'Home' then cast(Score as integer) else NULL end) as HomeScore
    , max(case when Period like '%OT' then 1 else 0 end) as IsOvertimeGame
    from nba_play_by_play
    group by pbp_url
) game_results on game_results.pbp_url = 'https://www.basketball-reference.com' || gi.[Play By Play URL]
inner join DimCalendar dc on dc.Date = gi.Date
inner join DimTeam away_team on away_team.TeamName = gi.[Away Team Name]
inner join DimTeam home_team on home_team.TeamName = gi.[Home Team Name];

SELECT *
FROM DimGame 
limit 10;