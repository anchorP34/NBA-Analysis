drop table if exists DimPeriod;

create table DimPeriod
(
    DimPeriodID integer PRIMARY KEY
    , PeriodName TEXT
    , IsOvertime INTEGER
);

INSERT INTO DimPeriod (PeriodName, IsOvertime)
SELECT distinct Period
, CASE WHEN Period like '%Q' then 0 else 1 end
from nba_play_by_play;

SELECT *
FROM DimPeriod
limit 10;