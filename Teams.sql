drop table if exists DimTeam;
create table DimTeam
(
    DimTeamID integer primary KEY
    , TeamName TEXT not NULL
    , TeamAbbrev TEXT not null
);

INSERT INTO DimTeam (TeamName, TeamAbbrev)
select distinct [Away Team Name]
, [Away Team Abbreviation]
from game_info;

select *
from DimTeam;