drop table if exists DimPlayer;

CREATE TABLE DimPlayer
(
    ID integer primary KEY
    , PlayerURL text
    , Name text
    , Height integer
    , Birthday TEXT
    , Cluster INTeger
);


insert into DimPlayer
(
    PlayerURL
    , Name
    , Height
    , Birthday
    , Cluster
)

select ID, Name, Height, Birthday, c.Cluster
from nba_players nba
left join cluster_assignments c on nba.ID = c.Player;

select *
from DimPlayer


