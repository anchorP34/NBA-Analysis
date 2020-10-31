foul.time.remaining.query <- dbSendQuery(con, "
with fouls as 
(
    select DimGameID
    , MainPlayer as Player
    , Period
    , RemainingRegulationSeconds as Time
    , SUM(PersonalFoul) over 
            (Partition by DimGameID
    , MainPlayer order by RemainingRegulationSeconds DESC) as GameFouls
    from FactPlayByPlay
    where PersonalFoul = 1
    and Posession not like '%turnover%'
)
, play_info as 
(
  -- This will get all of the times where a player fouled
    select gpt.DimGameID
    , gpt.Player
    , gpt.StartingTime
    , gpt.EndingTime
    , gpt.TotalTime
    , case when f.Time between gpt.EndingTime and gpt.StartingTime
                        then  gpt.StartingTime - f.Time
            else TotalTime end as TimeThatCounts
    , f.GameFouls
    , f.Period
    , f.Time

    from fouls f
    inner join game_play_time gpt on gpt.DimGameID = f.DimGameID
          and gpt.Player = f.Player
          and gpt.StartingTime >= f.Time
--where f.DimGameID = 1
--and f.Player = '/players/a/anunoog01.html'
--and f.GameFouls = 1
)
select pi.DimGameID
, pi.Player
, ca.Cluster
, case when ca.Cluster = 1 then .07
       when ca.Cluster = 2 then .11
       when ca.Cluster = 3 then .08
      end as ClusterLambda
, pi.GameFouls
, pi.Period
, CASE WHEN pi.GameFouls >= 2 and pi.Period = '1st Q' then 1
        when pi.GameFouls >= 3 and pi.Period = '2nd Q' then 1
        when pi.GameFouls >= 4 and pi.Period = '3rd Q' then 1
        when pi.GameFouls = 5 and pi.Period = '4th Q' then 1
        else 0 end as QualifyingFoulTrouble 
, pi.Time
, sum(pi.TimeThatCounts) as CumulativeTimePlayed
, avg(avg_game_play) as avg_game_play
, (avg(avg_game_play) - sum(pi.TimeThatCounts)) / 60 as expected_minutes_remaining
from play_info pi
inner join cluster_assignments ca on ca.Player = pi.Player
left join avg_clean_play_time acpt on acpt.Player = pi.Player

group by pi.DimGameID
, pi.Player
, ca.Cluster
, case when ca.Cluster = 1 then .07
       when ca.Cluster = 2 then .11
       when ca.Cluster = 3 then .08
      end 
, pi.GameFouls
, pi.Period
, CASE WHEN pi.GameFouls >= 2 and pi.Period = '1st Q' then 1
        when pi.GameFouls >= 3 and pi.Period = '2nd Q' then 1
        when pi.GameFouls >= 4 and pi.Period = '3rd Q' then 1
        when pi.GameFouls = 5 and pi.Period = '4th Q' then 1
        else 0 end
, pi.Time")

foul.time.remaining <- dbFetch(foul.time.remaining.query)
head(foul.time.remaining)

poisson.cdf.function <- function(lambda, game_fouls) {
  cdf.val <- 0
  fouls_remaining <- 5 - game_fouls
  
  for (i in 0: fouls_remaining) {
    cdf.val <- cdf.val +  ((lambda**i) * (exp(-lambda)) / factorial(i))
  }
  
  return (1-cdf.val)
  
}
# What is the probability LeBron fouls out when he has 2 fouls
# and he averages .1 fouls per minute over 24 minutes of playing time
poisson.cdf.function(2.4, 2)
poisson.cdf.function(2.07533333, 4)

foul.time.remaining %>% 
  filter(GameFouls < 6) %>% 
  mutate(expected_fouls = Time / 60 * ClusterLambda
    , foul_out_probability = mapply(poisson.cdf.function, expected_fouls, GameFouls)
    , Time = Time / 60
    ) %>% 
  select(Cluster, GameFouls, Period, foul_out_probability, Time) %>% 
  ggplot(mapping = aes(x = Time
                       , y = foul_out_probability
                       , color = as.factor(GameFouls)
                       , linetype = as.factor(Cluster)
                       )
         ) +
  geom_line(size = 1.5)


            

