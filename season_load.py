from bs4 import BeautifulSoup
import requests

def season_load(season):
    """
        This will load all of the main contents of all the games that have a box score
        and return an array of dictionaries for each game
    """
    print("\n\n\n\n{} season is loading...\n\n\n\n".format(season))
    season_games = []

    all_listed_games = []

    months = ['october','november','december','january','february','march',
            'april','may','june','july','august','september']

    for m in months:
        season_request = requests.get('https://www.basketball-reference.com/leagues/NBA_{}_games-{}.html'.format(season,m))
        print('https://www.basketball-reference.com/leagues/NBA_{}_games-{}.html'.format(season,m))
        season_soup = BeautifulSoup(season_request.text, 'lxml')

        try:
            # See if there are any games in the month
            season_tbody = season_soup.find_all('tbody')[0]

            # If there is a box score associated with the game
            # then we want to grab it
            for game in season_tbody.find_all('tr'):
                if game.contents[6].text == 'Box Score':
                    all_listed_games.append(game)
        except IndexError:
            # There are no games with a Box Score for this month. 
            # Necessary due to the COVID season
            pass
    
    for game in all_listed_games:
        game_data = {}
        game_info = game.contents
        game_data['date'] = game_info[0].string
        game_data['away_team'] = {'Name': game_info[2].string
                                , 'Abbreviation': game_info[2].a.attrs['href'].replace('/teams/','').replace('/{}.html'.format(season), '')
                                }
        game_data['home_team'] = {'Name': game_info[4].string
                                , 'Abbreviation': game_info[4].a.attrs['href'].replace('/teams/','').replace('/{}.html'.format(season), '')
                                }
        game_data['boxscore_url'] = game_info[6].contents[0].attrs['href']
        game_data['pbp_url'] = game_data['boxscore_url'].replace('boxscores/','boxscores/pbp/')
        season_games.append(game_data)

    return season_games