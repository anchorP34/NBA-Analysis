drop table if exists DimTeams;
create table DimTeams 
(
    DimTeamsID integer primary KEY
    , TeamName TEXT not NULL
    , TeamAbbrev TEXT not null
);

INSERT INTO DimTeams (TeamName, TeamAbbrev)
select distinct [Away Team Name]
, [Away Team Abbreviation]
from game_info;

select *
from DimTeams;