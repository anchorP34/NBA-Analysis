-- Let's set up Dimension Table for game info
drop table if exists DimCalendar;
create table DimCalendar
(
    DimCalendarID INTEGER PRIMARY KEY 
    , Date TEXT NOT NULL
    , DayOfWeek INTEGER NOT NULL
    , DayOfWeekString TEXT not null
    , Month INTEGER NOT NULL
    , DayOfMonth INTEGER NOT NULL
    , Year INTEGER NOT NULL
);

INSERT INTO DimCalendar
(
    Date
    , DayOfWeek
    , DayOfWeekString
    , Month
    , DayOfMonth
    , Year
)
select distinct Date
, case when Date like 'Sun%' then 0
        when Date like 'Mon%' then 1
        when Date like 'Tue%' then 2
        when Date like 'Wed%' then 3
        when Date like 'Thu%' then 4
        when Date like 'Fri%' then 5
        when Date like 'Sat%' then 6
 end as DayOfWeek
 , case when Date like 'Sun%' then 'Sun'
        when Date like 'Mon%' then 'Mon'
        when Date like 'Tue%' then 'Tue'
        when Date like 'Wed%' then 'Wed'
        when Date like 'Thu%' then 'Thu'
        when Date like 'Fri%' then 'Fri'
        when Date like 'Sat%' then 'Sat'
 end as DayOfWeekString
, case when Date like '%Jan%' then 1
        when Date like '%Feb%' then 2
        when Date like '%Mar%' then 3
        when Date like '%Apr%' then 4
        when Date like '%May%' then 5
        when Date like '%Jun%' then 6
        when Date like '%Jul%' then 7
        when Date like '%Aug%' then 8
        when Date like '%Sep%' then 9
        when Date like '%Oct%' then 10
        when Date like '%Nov%' then 11
        when Date like '%Dec%' then 12
    end as Month
, case when Date like '%1,%' then 1
    when Date like '%2,%' then 2
    when Date like '%3,%' then 3
    when Date like '%4,%' then 4
    when Date like '%5,%' then 5
    when Date like '%6,%' then 6
    when Date like '%7,%' then 7
    when Date like '%8,%' then 8
    when Date like '%9,%' then 9
    when Date like '%10,%' then 10
    when Date like '%11,%' then 11
    when Date like '%12,%' then 12
    when Date like '%13,%' then 13
    when Date like '%14,%' then 14
    when Date like '%15,%' then 15
    when Date like '%16,%' then 16
    when Date like '%17,%' then 17
    when Date like '%18,%' then 18
    when Date like '%19,%' then 19
    when Date like '%20,%' then 20
    when Date like '%21,%' then 21
    when Date like '%22,%' then 22
    when Date like '%23,%' then 23
    when Date like '%24,%' then 24
    when Date like '%25,%' then 25
    when Date like '%26,%' then 26
    when Date like '%27,%' then 27
    when Date like '%28,%' then 28
    when Date like '%29,%' then 29
    when Date like '%30,%' then 30
    when Date like '%31,%' then 31
    end as DayOfMonth
, case when Date like '%2019' then 2019
        when Date like '%2020' then 2020
    end as Year
from game_info;


select *
from DimCalendar
limit 10;