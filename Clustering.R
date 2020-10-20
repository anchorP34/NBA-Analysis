install.packages("RSQLite")
install.packages("factoextra")
library(RSQLite)
library(tidyverse)
library(cluster)
library(factoextra)
con <- dbConnect(SQLite(), "NBA.db")

set.seed(534)

FactPlayByPlay <-  dbReadTable(con, 'FactPlayByPlay')
game.play.time <- dbReadTable(con, 'game_play_time')
players <- dbReadTable(con, 'DimPlayer')

main.stats.query <- dbSendQuery(con, "
with players as
(
  select DimGameID
  , MainPlayer as Player
  , max(MainPlayerStarter) as GameStarter
  from FactPlayByPlay
  where MainPlayer != ''
  group by DimGameID
  , MainPlayer
  
  union
  
  select DimGameID
  , SecondaryPlayer
  , max(SecondaryPlayerStarter)
  from FactPlayByPlay
  where SecondaryPlayer != ''
  group by DimGameID
  , SecondaryPlayer
)
, games_played as
(
  SELECT Player
  , sum(GameStarter) as GameStarts
  , count(DISTINCT DimGameID) as GamesPlayed
  from players
  group by Player
)
, scoring_stats as 
(
  select MainPlayer as Player
  , sum(IsRebound) as Rebounds
  , sum(MissedShot) as MissedShots
  , sum(MadeShot) as MadeShots
  , sum(ThreePointAttempt) as ThreePointAttempts
  , sum(case when MadeShot = 1 and ThreePointAttempt = 1 then 1 else 0 end) as ThreePointsMade
  , sum(TwoPointAttempt) as TwoPointAttempts
  , sum(case when MadeShot = 1 and TwoPointAttempt = 1 then 1 else 0 end) as TwoPointsMade
  , sum(Points) as Points
  , sum(FreeThrow) as FreeThrowAttempts
  , sum(PersonalFoul) as PersonalFouls
  from FactPlayByPlay
  where MainPlayer != ''
  group by MainPlayer
  
)
, assists as
(
  select SecondaryPlayer as Player
  , sum(AssistOnPosession) as Assists
  from FactPlayByPlay
  where SecondaryPlayer != ''
  group by SecondaryPlayer
  
)
, time_played as 
(
  select Player
  , sum(TotalTime) as TotalTimePlayed
  , sum(TotalTime) / count(Distinct DimGameID) as SecondsPerGame
  from game_play_time
  group by Player
)

select gp.Player
, gp.GameStarts
, gp.GamesPlayed
, ifnull(ss.Rebounds, 0) as Rebounds
, ifnull(ss.MissedShots, 0) as MissedShots
, ifnull(ss.MadeShots, 0) as MadeShots
, ifnull(ss.ThreePointAttempts, 0) as ThreePointAttempts
, ifnull(ss.ThreePointsMade, 0) as ThreePointsMade
, ifnull(ss.TwoPointAttempts, 0) as TwoPointAttempts
, ifnull(ss.TwoPointsMade, 0) as TwoPointsMade
, ifnull(ss.Points, 0) as Points
, ifnull(ss.FreeThrowAttempts, 0) as FreeThrowAttempts
, ifnull(ss.PersonalFouls, 0) as PersonalFouls
, ifnull(a.Assists, 0) as Assists
, ifnull(tp.TotalTimePlayed, 0) / 60.0 as TotalMinutesPlayed
, ifnull(tp.SecondsPerGame, 0) / 60.0 as MinutesPerGame
from games_played gp
left join scoring_stats ss on ss.Player = gp.player
left join assists a on a.Player = gp.Player
left join time_played tp on tp.Player = gp.Player
where gp.GamesPlayed >= 10
and ifnull(TotalTimePlayed, 0) > 28800 
and ifnull(ss.Points, 0) > 0")
                                     
main.stats <- dbFetch(main.stats.query)
head(main.stats)



main.stats <- main.stats %>% 
  mutate(
    start_pct = GameStarts / GamesPlayed
    , field_goal_pct = MadeShots / (MissedShots + MadeShots) 
    , two_point_pct = TwoPointsMade / TwoPointAttempts
    , two_points_per_minute = TwoPointsMade / TotalMinutesPlayed
    , three_point_pct = ThreePointsMade / ThreePointAttempts
    , three_points_per_minute = ThreePointsMade / TotalMinutesPlayed
    , points_per_minute = Points / TotalMinutesPlayed
    , assists_per_minute = Assists / TotalMinutesPlayed
    , rebounds_per_miute = Rebounds / TotalMinutesPlayed
    , free_throws_per_minute = FreeThrowAttempts / TotalMinutesPlayed 
    , fouls_per_minute = PersonalFouls / TotalMinutesPlayed
  )
# Replace all NULL values with 0
main.stats[is.na(main.stats)] <- 0



normalize.function <- function(arr){
  column.mean <- mean(arr)
  column.std <- sqrt(var(arr))
  z.scores <- ((arr - column.mean) / column.std)
  percentiles <- pnorm(z.scores)
  return(percentiles)
}


# For loop to normalize each column

for (col in colnames(main.stats)){
  if (col != 'Player') {
    main.stats[col] <- normalize.function(main.stats[,col])
  }
}


# All values have been normalized into percentiles, time to run K means
cluster.df <- main.stats %>% 
  select(Player
         , GamesPlayed
         , MinutesPerGame
         , start_pct
         , field_goal_pct
         , two_point_pct
         , two_points_per_minute
         , three_point_pct
         , three_points_per_minute
         , points_per_minute
         , assists_per_minute
         , rebounds_per_miute
         , free_throws_per_minute
         , fouls_per_minute
         )
# Make Player the Index Column
rownames(cluster.df) <- cluster.df$Player
# Get rid of the player column (still leave the index)
cluster.df <- cluster.df[, -1]

fviz_nbclust(cluster.df, kmeans, method = "wss")

clusters3 <- kmeans(cluster.df, centers = 3, nstart = 25)
clusters5 <- kmeans(cluster.df, centers = 5, nstart = 25)

cluster.df['AssignedCluster3'] <- clusters3$cluster
cluster.df['AssignedCluster5'] <- clusters5$cluster

table(cluster.df['AssignedCluster3'])
table(cluster.df['AssignedCluster5'])

# LeBron is group 3 for AssignedGroup3, 2 for AssignedGroup5
cluster.df['/players/j/jamesle01.html',]

# Field Goal Pct
cluster.df %>% 
  select(AssignedCluster5, field_goal_pct) %>% 
  ggplot(mapping = aes(x = AssignedCluster5, y = field_goal_pct, group = AssignedCluster5)) +
  geom_boxplot()

# Points Per Minute
cluster.df %>% 
  select(AssignedCluster5, points_per_minute) %>% 
  ggplot(mapping = aes(x = AssignedCluster5, y = points_per_minute, group = AssignedCluster5)) +
  geom_boxplot()

# Fouls Per Minute
cluster.df %>% 
  select(AssignedCluster5, fouls_per_minute) %>% 
  ggplot(mapping = aes(x = AssignedCluster5, y = fouls_per_minute, group = AssignedCluster5)) +
  geom_boxplot()

# Rebounds Per Minute
cluster.df %>% 
  select(AssignedCluster5, rebounds_per_miute) %>% 
  ggplot(mapping = aes(x = AssignedCluster5, y = rebounds_per_miute, group = AssignedCluster5)) +
  geom_boxplot()

##################################################################
##################################################################

# Field Goal Pct
cluster.df %>% 
  select(AssignedCluster3, field_goal_pct) %>% 
  ggplot(mapping = aes(x = AssignedCluster3, y = field_goal_pct, group = AssignedCluster3)) +
  geom_boxplot()

# Points Per Minute
cluster.df %>% 
  select(AssignedCluster3, points_per_minute) %>% 
  ggplot(mapping = aes(x = AssignedCluster3, y = points_per_minute, group = AssignedCluster3)) +
  geom_boxplot()

# Fouls Per Minute
cluster.df %>% 
  select(AssignedCluster3, fouls_per_minute) %>% 
  ggplot(mapping = aes(x = AssignedCluster3, y = fouls_per_minute, group = AssignedCluster3)) +
  geom_boxplot()

# Rebounds Per Minute
cluster.df %>% 
  select(AssignedCluster3, rebounds_per_miute) %>% 
  ggplot(mapping = aes(x = AssignedCluster3, y = rebounds_per_miute, group = AssignedCluster3)) +
  geom_boxplot()