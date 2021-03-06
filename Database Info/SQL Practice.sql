/*
=======================================
SECTION: 
======================================= 
Description: Select all of the columns
from the FactPlayByPlay table but
only include 10 rows

======================================= 
======================================= 
*/

select *
from FactPlayByPlay
limit 10;


/*
=======================================
SECTION: Where clause
======================================= 
Description: How many points and rebounds 
did LeBron James have this regular season?

======================================= 
======================================= 
*/

select sum(Points) as TotalPoints
, sum(IsRebound) as TotalRebounds
, count(distinct DimGameID) as DistinctNumberOfGames
from FactPlayByPlay
where MainPlayer = '/players/j/jamesle01.html';


/*
=======================================
SECTION: Group By
======================================= 
Description: Who had the most total
points this year?

======================================= 
======================================= 
*/

select MainPlayer 
, sum(Points) as TotalPoints
from FactPlayByPlay
group by MainPlayer
order by sum(Points) DESC
limit 5;


/*
=======================================
SECTION: Which games went into overtime?
======================================= 
Description:

======================================= 
======================================= 
*/

select pbp_url
, max(case when Period like '%OT%' then 1.0 else 0 end) as AnyOvertime
from nba_play_by_play
group by pbp_url;

-- What is the percentage of games that went into OT?

select avg(AnyOvertime)
from (
    select pbp_url
    , max(case when Period like '%OT%' then 1.0 else 0 end) as AnyOvertime
    from nba_play_by_play
    group by pbp_url
) x

-- Another way using a CTE
with games as 
(
    select pbp_url
    , max(case when Period like '%OT%' then 1.0 else 0 end) as AnyOvertime
    from nba_play_by_play
    group by pbp_url
)
select avg(AnyOvertime)
from games;

/*
=======================================
SECTION: INNER Joins
======================================= 
Description: Which day of the week had
the most number of games?

======================================= 
======================================= 
*/

select *
from DimCalendar
limit 10;

select *
from game_info
limit 10;

select dc.DayOfWeekString
, count(*) as NumberOfGames
from game_info game
inner join DimCalendar dc on game.Date = dc.Date
group by dc.DayOfWeekString
order by count(*) desc;


/*
=======================================
SECTION: Left Joins
======================================= 
Description: Left joins have a main table 
and a secondary table. If the join criteria 
from the seondary table matches, it will show
in the results. If it does not match, those values
will come up as NULL

Example: Are there any "players" who got a foul
that are not in the players table?

======================================= 
======================================= 
*/

select *
from foul_information
limit 10;

select *
from DimPlayer
limit 10;


select *
from foul_information fi
left join DimPlayer dp on dp.PlayerURL = fi.Player
where dp.ID is NULL;


/*
=======================================
SECTION: FULL OUTTER JOIN
======================================= 
Description: Both tables show values
that did and did not match. You can see
NULL values in both the left and right 
tables.

======================================= 
======================================= 
*/


/*
=======================================
SECTION: Group by / Having
======================================= 
Description: How many players started at
least 50 games this year?

What was the order the query is executed in?

1. From
2. Where
3. Group By
4. Having 
5. SELECT
6. order By

======================================= 
======================================= 
*/

select MainPlayer
, count(distinct DimGameID) as GamesPlayed
from FactPlayByPlay
where MainPlayer != ''
and MainPlayerStarter = 1.0
group by MainPlayer
having count(distinct DimGameID) >= 50
order by count(distinct DimGameID) desc;

/*
=======================================
SECTION: 
======================================= 
Description: 

======================================= 
======================================= 
*/

select *
from nba_players;