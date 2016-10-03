# -*- coding: utf-8 -*-
"""
Created on Wed Sep 21 14:23:40 2016

@author: jtmartin
"""

import numpy as np
import pandas as pd
from timeit import default_timer as timer
import math

class Team(object):
    """A college football team. Teans have the
    following properties:

    Attributes:
        name: A string representing the team's name.
        elo: Elo score of the team.
        historical_elo = Pandas dataframe of historical Elo ratings for the team.
        probation: A Boolean stating whether or not the team is on their probationary period.
        games: The number of games the team has played thus far.
        wins: The number of wins a team has had thus far.
        draws: The number of draws a team has had thus far.
        losses: The number of losses a team has had thus far.
    """

    def __init__(self, name, elo = 1500, historical_elo = [], probation = True, games_played = 0,
                 wins = 0, draws = 0, losses = 0, year = 1869):
        """Return a Team object whose name is *name* and starting
        elo is *elo*."""
        self.name = name
        self.avg_elo = elo
        self.elo = elo
        self.historical_elo = []
        self.probation = True
        self.games_played = 0
        self.wins = 0
        self.draws = 0
        self.losses = 0
        self.year = year

    def calc_elo(self, team_elo, other_elo, win, k = 20, opp_prob = False, season = 1869, pd = 0):
        #games = games.loc[(games['Home Team'] == self.name) | (games['Away Team'] == self.name)]
#        if self.elo > 1950:
#            k = 10
#        if self.elo < 1050:
#            k = 10
#        if 1050 < self.elo < 1950:
#            k = k
        if season == (self.year + 1):
            self.elo = (0.67 * self.elo) + (0.33 * self.avg_elo)
            self.year = season
        self.historical_elo.append(self.elo)
        if opp_prob == True:
            return int(self.elo)
        elo_diff = float(other_elo - team_elo)
        mov_mult = math.log(abs(pd) + 1.0) * (2.2 / (elo_diff * 0.001 + 2.2))
        win_prob = 1.0 / (1.0 + 10.0**(elo_diff / 400.0))
#        if self.name == "Idaho State":
#            print("Before Elo: ", str(self.elo))
#            print("K: ", str(k))
#            print("Win: ", str(win))
#            print("Win Probability: ", str(win_prob))
#            print("Points available: ", str(float(k) * (win - win_prob)))
        self.elo = float(team_elo) + (mov_mult * float(k) * (win - win_prob))
#        if self.name == "Idaho State":
#            print("After Elo: ", str(self.elo), "\n")
        return int(self.elo)

start = timer()
path = "C:/Users/jtmartin/Documents/College Football/Scrape ESPN/"
all_games = pd.read_csv(path + "/All FBS Data.csv", low_memory = False)
probation_limit = 13
k_factor = 25

all_games = all_games.loc[66000:]

total_teams = all_games["Home Team"].tolist() + all_games["Away Team"].tolist()
teams = np.unique(total_teams)
np.savetxt(path + "/Unique Teams.csv", teams, delimiter = ',', fmt = "%s")
team_objs = {}

for team in teams:
    #team_objs.append(Team(team))
    team_objs[team] = Team(team, year = np.min(all_games["Season"]))

#Elos are before matchup
all_games["Home Elo"] = np.nan
all_games["Away Elo"] = np.nan
all_games["Home Win"] = np.where(all_games["Home Score"] > all_games["Away Score"], 1.0, 0.0)
all_games["Home Win"] = np.where(all_games["Home Score"] == all_games["Away Score"], 0.5, all_games["Home Win"])
all_games["Away Win"] = np.where(all_games["Away Score"] > all_games["Home Score"], 1.0, 0.0)
all_games["Away Win"] = np.where(all_games["Away Score"] == all_games["Home Score"], 0.5, all_games["Away Win"])
all_games["Point Differential"] = np.absolute(all_games["Home Score"] - all_games["Away Score"])

for index, row in all_games.iterrows():
    home = team_objs[row['Home Team']]
    away = team_objs[row['Away Team']]
    row["Home Elo"] = home.elo
    row["Away Elo"] = away.elo
    season = row["Season"]
    home_win = row["Home Win"]
    away_win = row["Away Win"]
    point_diff = row["Point Differential"]
    home.elo = int(home.calc_elo(team_elo = home.elo, other_elo = away.elo, win = home_win, k = k_factor,
                                 opp_prob = away.probation, season = season, pd = point_diff))
    away.elo = int(away.calc_elo(team_elo = away.elo, other_elo = home.elo, win = away_win, k = k_factor,
                                 opp_prob = home.probation, season = season, pd = point_diff))
    home.games_played += 1
    away.games_played += 1
    if home_win == 1.0: home.wins += 1
    if home_win == 0.5: home.draws += 1
    if home_win == 0.0: home.losses += 1
    if away_win == 1.0: away.wins += 1
    if away_win == 0.5: away.draws += 1
    if away_win == 0.0: away.losses += 1
    if home.games_played > probation_limit:
        home.probation = False
    if away.games_played > probation_limit:
        away.probation = False
    team_objs[home.name] = home
    team_objs[away.name] = away
    all_games.loc[index] = row
    print(row['Date'])

print("\n")

to_df = {}
for key, value in team_objs.items():
    to_df[key] = (value.elo, value.probation, value.wins, value.draws, value.losses)

ratings = pd.DataFrame.from_dict(to_df, orient = "index")
ratings.reset_index(level=0, inplace=True)
ratings.columns = ["Team", "Elo Rating", "Probation", "Wins", "Draws", "Losses"]

history = {}
for key, value in team_objs.items():
    if value.historical_elo == []:
        continue
#    if len(value.historical_elo) < 15:
#        continue
    history[key] = value.historical_elo

#history = pd.DataFrame.from_records(history, index = [0])
history = pd.DataFrame({k : pd.Series(v) for k, v in history.items()})
end = timer()
print("Time to run:", '{}'.format(round(end - start)), "seconds")

#ratings = ratings[(ratings["Wins"] + ratings["Draws"] + ratings["Losses"]) > 300]

all_games["Elo Win"] = np.where((((all_games["Home Elo"] > all_games["Away Elo"]) & (all_games["Home Win"] == 1)) | 
        ((all_games["Away Elo"] > all_games["Home Elo"]) & (all_games["Away Win"] == 1))), 1.0, 0.0)

#Get hitrate for straight up wins
desired_season = 2014
test = all_games[all_games["Season"] >= desired_season]
pct = np.sum(test["Elo Win"]) / len(test["Elo Win"])
print("Test hitrate:", '{0:.1f}%'.format((pct * 100)))

#Get Naive Rule
all_games = all_games[all_games["Season"] >= 2003]
all_games["Home Ranking"] = np.where(all_games["Home Ranking"] == "NR", 26, all_games["Home Ranking"])
all_games["Away Ranking"] = np.where(all_games["Away Ranking"] == "NR", 26, all_games["Away Ranking"])
all_games["Home Ranking"] = all_games["Home Ranking"].astype(int)
all_games["Away Ranking"] = all_games["Away Ranking"].astype(int)
all_games["Rank Win"] = np.where((((all_games["Home Ranking"] < all_games["Away Ranking"]) & (all_games["Home Win"] == 1)) | 
        ((all_games["Away Ranking"] < all_games["Home Ranking"]) & (all_games["Away Win"] == 1))), 1, 0)
all_games["Rank Win"] = np.where(all_games["Home Ranking"] == all_games["Away Ranking"], 0.5, all_games["Rank Win"])
naive = np.sum(all_games["Rank Win"]) / len(all_games["Rank Win"])
print("Naive Rule:", '{0:.1f}%'.format((naive * 100)))

all_games.to_csv(path + "/All Games With Ratings.csv", index = False)

#all_games = pd.read_csv(path + "/All Games With Ratings 1869-2016.csv", low_memory = False)