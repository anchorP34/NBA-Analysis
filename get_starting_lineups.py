import requests
from bs4 import BeautifulSoup

def get_starting_lineups(game_dict):
    """
        Gets the starting lineups of the home and away starting lineups
    """

    game_request = requests.get('https://www.basketball-reference.com{}'.format(game_dict['boxscore_url']))
    game_soup = BeautifulSoup(game_request.text, 'lxml')

    home_abbrev = game_dict['home_team']['Abbreviation']
    away_abbrev = game_dict['away_team']['Abbreviation']

    home_team_starting_roster = []
    away_team_starting_roster = []

    home_roster = game_soup.find_all(id = 'div_box-{}-game-basic'.format(home_abbrev)
                                )[0].find_all('tbody')[0].find_all('tr')
    
    away_roster = game_soup.find_all(id = 'div_box-{}-game-basic'.format(away_abbrev)
                                )[0].find_all('tbody')[0].find_all('tr')

    # Only need the first five records to get the starting 5 players
    for player in home_roster[:5]:
        home_team_starting_roster.append(player.contents[0].a.attrs['href'])

    # Only need the first five records to get the starting 5 players
    for player in away_roster[:5]:
        away_team_starting_roster.append(player.contents[0].a.attrs['href'])

    return home_team_starting_roster, away_team_starting_roster