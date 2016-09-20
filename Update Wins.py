# -*- coding: utf-8 -*-
"""
Created on Fri Sep 16 14:56:41 2016

@author: jtmartin
"""
import numpy as np
import pandas as pd
import requests
from bs4 import BeautifulSoup
from datetime import datetime, date
import re, json
import sys

path = "C:/Users/jtmartin/Documents/College Football/Scrape ESPN/"
url = "http://www.cbssports.com/collegefootball/scoreboard/FBS/{0}/week{1}"
url2 = "http://www.cbssports.com/college-football/scoreboard/fbs/{0}/regular/{1}/"

old_games = pd.read_csv(path + "/FBS Data.csv")

year = 2016
week = 3
un_week = np.max(old_games['Unique Week']) + 1
BASE_URL = url2

if old_games.iloc[len(old_games["Week"])-1, 0] == week and old_games.iloc[len(old_games["Season"])-1, 2] == year:
    sys.exit("You already have this week of data downloaded!")

r = requests.get(BASE_URL.format(str(year), str(week)))
soup = BeautifulSoup(r.text, "lxml")

tables = soup.find_all('div', attrs={'class': "live-update"})

tables = pd.read_html(str(tables))

new_games = pd.DataFrame(columns = ["Week",  "Unique Week", "Season", "Home Ranking", "Home Team", "Home Score", "Away Ranking", "Away Team", "Away Score", "OT"])

weeks = []
date = []
home_team = []
home_score = []
away_team = []
away_score = []
OT = []
home_rankings = []
away_rankings = []
curr_season = []
day = []
uniq_week = []

for table in tables:
    #Home team is still on the bottom
    OT.append(1 if len(table.columns) > 6 else 0)
    home_row = 1
    away_row = 0   
    weeks.append(week if week <= 16 else 17)
    #date.append(str(table.iloc[0,0]).split('.')[1:] + ", " + str(year if "Jan" not in str(table.iloc[0,0]) else (year + 1)))
    #day.append(str(table.iloc[0,0]).split('.')[0] + ".")
    home = str(table.iloc[home_row,0])
    home_ranking = "NR"
    away_ranking = "NR"
    if home[0].isnumeric():
        home_ranking = "".join([letter for letter in home[:2] if letter.isnumeric() or letter.isspace()])
    home = "".join([letter for letter in home if letter.isalpha()])
    away = str(table.iloc[away_row,0]) 
    if away[0].isnumeric():
        away_ranking = "".join([letter for letter in away[:2] if letter.isnumeric() or letter.isspace()])
    away = "".join([letter for letter in away if letter.isalpha()])
    home_team.append(home)
    home_score.append(str(int(table.iloc[home_row, -1])))
    away_team.append(away)
    away_score.append(str(int(table.iloc[away_row, -1])))
    home_rankings.append(home_ranking)
    away_rankings.append(away_ranking)
    curr_season.append(year)

uniq_week.append(un_week)


new_games["Week"] = weeks
new_games["Unique Week"] = uniq_week * len(weeks)
new_games["Season"] = curr_season
#new_games["Day"] = day
#new_games["Date"] = date
new_games["Home Ranking"] = home_rankings
new_games["Home Team"] = home_team
new_games["Home Score"] = home_score
new_games["Away Ranking"] = away_rankings
new_games["Away Team"] = away_team
new_games["Away Score"] = away_score
new_games["OT"] = OT
updated_games = pd.concat([old_games, new_games])

updated_games = updated_games[["Week", "Unique Week", "Season",  "Date", "Home Ranking", "Home Team", "Home Score", "Away Ranking", "Away Team", "Away Score", "OT"]]

updated_games.to_csv(path + "/FBS Data.csv", index = False)
updated_games.to_csv(path + "/Other/FBS Data Backup Thru Week " + str(week) + ".csv", index = False)