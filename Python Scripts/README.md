# Python NBA Web Scraping Program

Thesese files work together to pull play by play information for each game in a selected NBA season. All data is extracted from www.basketball-reference.com

## app.py

This is the main file to run when you're ready to start the web scraping application. You will see in the file there is a season_year = 2020. That can be changed to whatever season desired to load.

## season_load.py

This takes all of the information needed to load data for each game in the selected season. 

## game_load.py

This extracts all of the play by play data for a given game URL

## get_starting_lineups.py

This file finds the starting lineup for each game. This is helpful for analysis if you're wanting to only look at players who started.

## load_players.py

This file runs separately from the main app.py process. This file takes in a given year and gets all of the players from each game and finds their attributes like name, birthday, and height.
Run this file after you have loaded the season in the app.py process. 
