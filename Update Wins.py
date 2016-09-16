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

path = "C:/Users/jtmartin/Documents/College Football/Scrape ESPN/"
url2 = "http://www.cbssports.com/collegefootball/scoreboard/FBS/{0}/week{1}"

year = 2014
week = 1
un_week = 1
BASE_URL = url

all_games = pd.DataFrame(columns = ["Week", "Unique Week", "Season",  "Day", "Date", "Home Ranking", "Home Team", "Home Score", "Away Ranking", "Away Team", "Away Score", "OT"])

#Won't need to iterate through years, but possibly multiple weeks. Will need to figure out unique_weeks as well
for year in list(range(2003, 2017)): 
    season = pd.DataFrame(columns = ["Week", "Unique Week", "Season",  "Day", "Date", "Home Ranking", "Home Team", "Home Score", "Away Ranking", "Away Team", "Away Score", "OT"])
        
    for week in list(range(1,19)):
        r = requests.get(BASE_URL.format(str(year), str(week)))
        soup = BeautifulSoup(r.text, "lxml")
        
        #for tag in soup.find_all(True):
        #    print(tag.name)
        
        
        tables = soup.find_all('table', attrs={'class': "lineScore postEvent"})
        
        if tables == []:
            continue
        tables = pd.read_html(str(tables))
        
        games = pd.DataFrame(columns = ["Week",  "Unique Week", "Season", "Day", "Date", "Home Ranking", "Home Team", "Home Score", "Away Ranking", "Away Team", "Away Score", "OT"])
        
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
            #Home team is on the bottom
            OT.append(1 if len(table.columns) > 6 else 0)
            home_row = 3 if len(table.columns) > 6 else 2
            away_row = 2 if len(table.columns) > 6 else 1    
            weeks.append(week if week <= 16 else 17)
            date.append(str(table.iloc[0,0]).split('.')[1:] + ", " + str(year if "Jan" not in str(table.iloc[0,0]) else (year + 1)))
            day.append(str(table.iloc[0,0]).split('.')[0] + ".")
            home = str(table.iloc[home_row,0])
            home_ranking = "NR"
            away_ranking = "NR"
            if "(" in home:
                home = home.split('(')[0]
            if "#" in home:
                home_ranking = home.split('#')[1]
                home = home.split('#')[0]
            away = str(table.iloc[away_row,0]) 
            if "(" in away:
                away = away.split('(')[0]
            if "#" in away:
                away_ranking = away.split('#')[1]
                away = away.split('#')[0]
            home_team.append(home)
            home_score.append(str(int(table.iloc[home_row, -1])))
            away_team.append(away)
            away_score.append(str(int(table.iloc[away_row, -1])))
            home_rankings.append(home_ranking)
            away_rankings.append(away_ranking)
            curr_season.append(year)
        
        uniq_week.append(un_week)
        un_week += 1
        
        games["Week"] = weeks
        games["Unique Week"] = uniq_week * len(weeks)
        games["Season"] = curr_season
        games["Day"] = day
        games["Date"] = date
        games["Home Ranking"] = home_rankings
        games["Home Team"] = home_team
        games["Home Score"] = home_score
        games["Away Ranking"] = away_rankings
        games["Away Team"] = away_team
        games["Away Score"] = away_score
        games["OT"] = OT
        season = pd.concat([season, games])
        
    season.to_csv(path + "/Yearly Data/" + str(year) + ".csv", index = False)
    
    all_games = pd.concat([all_games, season])
     
#DON'T RUN...CBS LAYOUT CHANGED
#all_games.to_csv(path + "FBS Data.csv", index = False)