# -*- coding: utf-8 -*-
"""
Created on Mon Aug 29 14:13:10 2016

@author: jtmartin
"""
import pandas as pd,  numpy as np, os
pd.set_option('display.float_format', lambda x:'%f'%x)

year = '2013'
cfb = 'C:/Users/jtmartin/Documents/College Football/Yearly .csv Data'
location = 'C:/Users/jtmartin/Documents/College Football/' + year + '/'

games_raw = pd.read_csv(location + 'team-game-statistics.csv', dtype = {'Game Code': object})
teams = pd.read_csv(location + 'team.csv')
game_master = pd.read_csv(location + 'game.csv', dtype = {'Game Code': object})
game_stats = pd.read_csv(location + 'game-statistics.csv', dtype = {'Game Code': object})
stadium = pd.read_csv(location + 'stadium.csv')
conference = pd.read_csv(location + 'conference.csv')

games = pd.merge(game_master, games_raw, how = 'left', left_on = ['Home Team Code', 'Game Code'], right_on = ['Team Code', 'Game Code'])

games['Site'][games['Site'].str.contains('TEAM')] = 'Home'
games['Site'][games['Site'].str.contains('NEUTRAL')] = 'Neutral'


cols = games.columns.values
for i in range(len(games.columns)):
    if i >= 7:
        cols[i] = 'Home ' + games.columns[i]
    else:
        cols[i] = games.columns[i]
        
games.columns = cols

games = pd.merge(games, games_raw, how = 'left', left_on = ['Visit Team Code', 'Game Code'], right_on = ['Team Code', 'Game Code'])

cols = games.columns.values
for i in range(len(games.columns)):
    if i >= 74:
        cols[i] = 'Away ' + games.columns[i]
    else:
        cols[i] = games.columns[i]
        
games.columns = cols

games.drop('Team Code_x', inplace = True, axis = 1)
games.drop('Team Code_y', inplace = True, axis = 1)

games = pd.merge(games, game_stats, how = 'left', on = 'Game Code')
games = pd.merge(games, stadium, how = 'left', on = 'Stadium Code')
games = pd.merge(games, teams, how = 'left', left_on = 'Home Team Code', right_on = 'Team Code')
games.rename(columns={'Name_x': 'Stadium', 'Name_y': 'Home Team Name', 'Conference Code': 'Home Conference Code'}, inplace=True)
games.drop('Team Code', inplace = True, axis = 1)

games = pd.merge(games, teams, how = 'left', left_on = 'Visit Team Code', right_on = 'Team Code')
games.rename(columns={'Name': 'Away Team Name', 'Conference Code': 'Away Conference Code'}, inplace=True)
games.drop('Team Code', inplace = True, axis = 1)

games = pd.merge(games, conference, how = 'left', left_on = 'Home Conference Code', right_on = 'Conference Code')
games.rename(columns={'Name': 'Home Conference', 'Subdivision': 'Home Subdivision'}, inplace=True)
games.drop('Conference Code', inplace = True, axis = 1)

games = pd.merge(games, conference, how = 'left', left_on = 'Away Conference Code', right_on = 'Conference Code')
games.rename(columns={'Name': 'Away Conference', 'Subdivision': 'Away Subdivision'}, inplace=True)
games.drop('Conference Code', inplace = True, axis = 1)

games['Home Win'] = np.where(games['Home Points'] > games['Away Points'], 1, 0)

games.to_csv(cfb + year + '.csv', index = False)