# -*- coding: utf-8 -*-
"""
Created on Tue Sep 20 16:30:29 2016

@author: jtmartin
"""
import numpy as np
import pandas as pd
import requests
from bs4 import BeautifulSoup
from datetime import datetime, date
import re, json

path = "C:/Users/jtmartin/Documents/College Football/Scrape ESPN/"
data = pd.DataFrame()

#Date, Away Team, Away Score, Home Team, Home Score, Location (if there is one)
for year in list(range(1869, 2011)):
    if year == 1871: continue
    table = pd.read_fwf("http://homepages.cae.wisc.edu/~dwilson/rsfc/history/howell/cf" + str(year) + "gms.txt", 
                          header = None, colspecs = [(0,10), (11,37), (38,42), (43,68), (69,73), (74,150)])
    table = table.dropna(axis = 1, how = "all")
    data = pd.concat([data, table])
    
data.columns = ['Date', 'Away Team', 'Away Score', 'Home Team', 'Home Score', 'Location']
    
data.to_csv(path + "Historical Data.csv", index = False)