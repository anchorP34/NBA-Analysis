import requests
from bs4 import BeautifulSoup
import pandas as pd
import get_starting_lineups

def game_load(game_dict, home_starting_lineup, away_starting_lineup):
    """
        This function loads in a game URL and returns a Pandas DataFrame
        with the play by play data of the game

        NEED TO CREATE CLASSES SO WE DON'T NEED TO TAKE IN THE ADDITIONAL PARAMETERS
    """

    def main_secondary_players(content_val):
        """
            Function gets the main and secondary players for each record in the play
            by play data. This is under the assumption that there is either 0 players 
            (example, a timeout), 1 player (example someone scores with no assist) or 2 players
            (example, a bucket scored with an assist)
        """
        players = content_val.find_all()
        
        if len(players) == 0:
            return None, None
        
        # If there's just one player in focus
        elif len(players) == 1:
            return players[0].attrs['href'], None
        
        else:
            return players[0].attrs['href'], players[1].attrs['href']

    game_url = 'https://www.basketball-reference.com{}'.format(game_dict['pbp_url'])
    game_request = requests.get(game_url)
    game_soup = BeautifulSoup(game_request.text, 'lxml')

    play_by_play = game_soup.find_all('tr')

    all_data = []

    for line in play_by_play:
        content_information = line.contents
        if len(content_information) == 3:
            period = content_information[1].text
            #print(period)
            continue
        elif len(content_information) == 9:
            time_remaining = content_information[1].text.strip()
            
            visiting_text = content_information[3].text.strip()
            
            visiting_points = content_information[4].text.strip()
            
            visiting_score = content_information[5].text.split('-')[0]
            home_score = content_information[5].text.split('-')[1]
            
            home_points = content_information[6].text.strip()
            home_text = content_information[7].text.strip()
            
            
            if home_text != '':
                main_player, secondary_player = main_secondary_players(content_information[7])
            
            else:
                main_player, secondary_player = main_secondary_players(content_information[3])
            
            
            data = [period, time_remaining, visiting_text, visiting_points, visiting_score, 
                    home_score, home_points, home_text,
                    main_player, secondary_player]
            
            all_data.append(data)

    df_columns = ['Period','Time','Away Posession','Away Points','Away Score',
        'Home Score','Home Points','Home Posession',
        'Main Player','Secondary Player']
    df = pd.DataFrame(all_data, columns = df_columns)

        # Home Action
    home_team_data = df[df['Home Posession'] != ''][['Period','Time','Home Posession','Home Points',
                                        'Home Score','Main Player','Secondary Player']]

    # Visiting Action
    away_team_data = df[df['Away Posession'] != ''][['Period','Time','Away Posession','Away Points',
                                        'Away Score','Main Player','Secondary Player']]

    full_columns = ['Period','Time','Posession','Points','Score','Main Player','Secondary Player','Team']

    home_team_data['Team'] = 'Home'
    home_team_data.columns = full_columns

    away_team_data['Team'] = 'Away'
    away_team_data.columns = full_columns


    full_df = home_team_data.append(away_team_data).sort_index()

    full_df['Playoff Game'] = 1 if "Series Summary" in game_request.text else 0

    full_df['Home Main Starter'] = full_df['Main Player'].apply(lambda x: 1 if x in home_starting_lineup else 0)
    full_df['Home Secondary Starter'] = full_df['Secondary Player'].apply(lambda x: 1 if x in home_starting_lineup else 0)

    full_df['Away Main Starter'] = full_df['Main Player'].apply(lambda x: 1 if x in away_starting_lineup else 0)
    full_df['Away Secondary Starter'] = full_df['Main Player'].apply(lambda x: 1 if x in away_starting_lineup else 0)

    return full_df
