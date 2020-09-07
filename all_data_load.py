from season_load import season_load
from game_load import game_load
from get_starting_lineups import get_starting_lineups

import pandas as pd


class all_data_load():

    def __init__(self, season):
        """

        """

        self.season = season

    def load(self):
    

        final_df = pd.DataFrame(columns = ['Period','Time','Posession','Points','Score','Main Player','Secondary Player','Team'
                                            , 'Playoff Game','Home Main Starter','Home Secondary Starter'
                                            ,'Away Main Starter','Away Secondary Starter', 'pbp_url'])
        season_df_data = []

        # First, get all the games for the given season
        season_games = season_load(self.season)
        print('\nThere are {:,} games in the season to be scraped'.format(len(season_games)))

        # Next, go through each game of the season_games and get the play by play info

        for idx, game in enumerate(season_games):
            # Get the starting rosters
            home_team_starting_roster, away_team_starting_roster = get_starting_lineups(game)

            play_by_play_data = game_load(game, home_team_starting_roster, away_team_starting_roster)

            is_playoff_game = max(play_by_play_data['Playoff Game'])

            season_games[idx]['Playoff Game'] = is_playoff_game

            final_df = final_df.append(play_by_play_data)

            game_data = [
                game['date']
                , game['away_team']['Name']
                , game['away_team']['Abbreviation']
                , game['home_team']['Name']
                , game['home_team']['Abbreviation']
                , game['Playoff Game']
                , game['boxscore_url']
                , game['pbp_url']               
            ]

            season_df_data.append(game_data)

            print('\nGame number {} ({} vs {}) has completed'.format(idx,game['away_team']['Name'],  game['home_team']['Name']))
            print('There were {:,} play by play records for this game'.format(play_by_play_data.shape[0]))
            print('There are now a total of {:,} play by play records for the whole season\n'.format(final_df.shape[0]))

        # Create data frame of information in the game dictionaries
        season_df = pd.DataFrame(data = season_df_data
                                , columns=['Date','Away Team Name','Away Team Abbreviation','Home Team Name','Home Team Abbreviation','Playoff Game'
                                ,'Boxscore URL','Play By Play URL'])

        return final_df, season_df