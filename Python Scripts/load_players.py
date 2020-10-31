import requests
from bs4 import BeautifulSoup
import pandas as pd
import numpy as np
from datetime import datetime

def player_info(player_url):
    player_request = requests.get('https://www.basketball-reference.com{}'.format(player_url))
    player_soup = BeautifulSoup(player_request.text, 'lxml')

    player_name = player_soup.find_all('h1',attrs = {'itemprop':'name'})[0].text

    player_height = player_soup.find_all(attrs = {'itemprop':'height'})[0].text
    player_height_inches = int(player_height.split('-')[0]) * 12 + int(player_height.split('-')[1])
    player_birthday = player_soup.find_all(attrs = {'itemprop':'birthDate'})[0].text.replace('\n','').split()

    full_birthday_date = " ".join(player_birthday).replace(',','')
    birthday_datetime = datetime.strptime(full_birthday_date, '%B %d %Y')

    birth_year = birthday_datetime.year
    birth_month = '0{}'.format(birthday_datetime.month) if birthday_datetime.month < 10 else birthday_datetime.month
    birth_day = '0{}'.format(birthday_datetime.day) if birthday_datetime.day < 10 else birthday_datetime.day

    birth_yyyy_mm_dd = '{}-{}-{}'.format(birth_year,  birth_month, birth_day)


    return {'ID': player_url
            , 'Name': player_name
            , 'Height':player_height_inches
            , 'Birthday':birth_yyyy_mm_dd
           }


# First read in all of the players / coaches and load them into a list
nba_season = pd.read_csv('NBA_Season_2020.csv')
print('2020 NBA Season data has been loaded.')

main_players = list(nba_season['Main Player'])
print(main_players[:5])

secondary_players = list(nba_season['Secondary Player'])
print(secondary_players[:5])

all_players = set(main_players + secondary_players)

all_player_information = []

for player in all_players:
    print(player)
    if player != '' and pd.isnull(player) == False and 'coaches' not in player:
        player_data = player_info(player)
        all_player_information.append([
                player_data['ID']
                , player_data['Name']
                , player_data['Height']
                , player_data['Birthday']
                            ])
        #print("{}'s information has been loaded successfully".format(player))

player_df = pd.DataFrame(all_player_information, columns = ['ID','Name','Height','Birthday'])

player_df.to_csv('NBA_Players_2020.csv')






