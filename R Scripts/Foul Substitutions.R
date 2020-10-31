con <- dbConnect(SQLite(), "NBA.db")

foul.substitutions.query <- dbSendQuery(con, "
with fouls as 
(
    select DimGameID
    , MainPlayer
    , Period
    , RemainingRegulationSeconds
    , SUM(PersonalFoul) over 
            (Partition by DimGameID
    , MainPlayer order by RemainingRegulationSeconds DESC) as GameFouls
    from FactPlayByPlay
    where PersonalFoul = 1
    and Posession not like '%turnover%'
)
, full_data as 
(
    -- This will get all of the times where a player fouled
    select DimGameID
    , MainPlayer
    , CASE WHEN GameFouls >= 2 and Period = '1st Q' then 1
        when GameFouls >= 3 and Period = '2nd Q' then 1
        when GameFouls >= 4 and Period = '3rd Q' then 1
        when GameFouls = 5 and Period = '4th Q' then 1
        else 0 end as QualifyingFoulTrouble 
    , Period
    , RemainingRegulationSeconds as Time
    , 'Foul' as Type
    from fouls

    union ALL

    -- This will get all of the substitution times
    select DimGameID
    , Player
    , NULL
    , NULL
    , EndingTime
    , 'Substitution' as Type
    from game_play_time
)
, comparisons as 
(
    select *
    , lead(Time) over (Partition by DimGameID, MainPlayer
                    order by Time DESC,
                    case when Type = 'Foul' then 0 else 1 end) as NextTime
    , lead(Type) over (Partition by DimGameID, MainPlayer
                    order by Time DESC,
                    case when Type = 'Foul' then 0 else 1 end) as NextType
    from full_data
)

select *
, case when Type = 'Foul'
        and NextType = 'Substitution'
        and NextTime = Time 
        then 1 else 0 end as ImmediateSub  
from comparisons
where type = 'Foul'
order by DimGameID, 
    MainPlayer, 
    Time DESC,
    case when Type = 'Foul' then 0 else 1 end")

foul.substituions <- dbFetch(foul.substitutions.query)
head(foul.substituions)

foul.substituions %>% 
  group_by(Period
           , QualifyingFoulTrouble = ifelse(QualifyingFoulTrouble == 0, 'No','Yes')) %>% 
  summarize( count = n()
            , sub_pct = mean(ImmediateSub)) %>% 
  ggplot(mapping = aes(x = Period, y = sub_pct, fill = QualifyingFoulTrouble)) +
  geom_bar(stat = 'identity', position = 'dodge') +
  ylab('Substitution Percentage') + labs(fill = "Qualifying Foul Trouble") +
scale_y_continuous(labels = scales::percent) +
  theme(text = element_text(size=20),
        axis.text.x = element_text(face="bold",size=20),
        axis.text.y = element_text(face="bold",size=20)) +
  theme(legend.position="top")
