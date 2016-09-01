# -*- coding: utf-8 -*-
"""
Created on Wed Aug 31 09:47:32 2016

@author: jtmartin
"""

import pandas as pd,  numpy as np, os
pd.set_option('display.float_format', lambda x:'%f'%x)

cfb = 'C:/Users/jtmartin/Documents/College Football/'
    
years = list(range(2005, 2014))

years = [str(year) for year in years]

l = []
    
for year in years:
    location = 'C:/Users/jtmartin/Documents/College Football/' + year + '/'
    games = pd.read_csv(location + 'team-game-statistics.csv', dtype = {'Game Code': object})
    teams = pd.read_csv(location + 'team.csv')
    game_master = pd.read_csv(location + 'game.csv', dtype = {'Game Code': object})
    games = pd.merge(game_master, games, how = 'left', on = ['Game Code'])
    games = pd.merge(teams, games, how = 'left', on = ['Team Code'])
    l.append(games)
    
total = pd.DataFrame()         
total = pd.concat(l)

#uniq_games = pd.read_csv(cfb + '2005-2013 Unique Game.csv', dtype = {'Game Code': object})
#
#uniq_games['Winner Code'] = np.where(uniq_games['Home Points'] > uniq_games['Away Points'], uniq_games['Home Team Code'], uniq_games['Visit Team Code'])
#scores = uniq_games[["Game Code", "Home Team Code", "Home Points", "Visit Team Code", "Away Points"]]
#
#winners = uniq_games[["Game Code", "Winner Code"]].astype(object)
#total = pd.merge(total, winners, how = "inner", on = "Game Code")

total.to_csv(cfb + '2005-2013.csv', index = False)