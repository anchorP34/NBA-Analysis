# NBA-Foul-Analysis
Project relating to foul management in the NBA

# Overview

This project was built from the idea that coaches in the NBA were pulling their star players too early if they became in foul trouble. Using methods like K-means clustering and the Poisson distribution, a better idea of foul management can give coaches the gameplan to optimize their players time on the court and put their team in a better spot to win.

## Database Info

This folder holds the SQLite database used for this project. It also includes the CSV files that were loaded in the database and the SQL scripts that created the tables in the database. To have the raw table ingested correctly, run these commands when you're in the SQLite interpreter:

.mode csv

.headers on

.import NBA_Players_2020.csv players

.import NBA_Game_Info.csv game_info

.import NBA_Season_2020.csv nba_play_by_play

.import Cluster_Assignments.csv cluster_assignments

## Python Scripts

This folder includes all of the Python scripts to web scrape play by play data from a season. The play by play data is being scraped from basketball-reference.com

## Jupyter Notebooks

This folder shows the Jupyter notebooks used to testing out different ideas. There is not much helpful information in this folder but still wanted to include it for possible future use..

## R Scripts

R scripts for visual analysis and using for Cluster and Poisson data analysis.

## Screenshots

Different pictures to use for write up analysis.


