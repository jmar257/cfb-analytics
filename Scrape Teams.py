# -*- coding: utf-8 -*-
"""
Created on Wed Sep 14 13:35:06 2016

@author: jtmartin
"""

import pandas as pd
import requests
from bs4 import BeautifulSoup

path = "C:/Users/jtmartin/Documents/College Football/Scrape ESPN/"

url = 'http://www.espn.com/college-football/teams'
r = requests.get(url)

soup = BeautifulSoup(r.text)
tables = soup.find_all('ul', class_='medium-logos')

teams = []
prefix_1 = []
prefix_2 = []
teams_urls = []
for table in tables:
    lis = table.find_all('li')
    for li in lis:
        info = li.h5.a
        teams.append(info.text)
        url = info['href']
        teams_urls.append(url)
        prefix_1.append(url.split('/')[-2])
        prefix_2.append(url.split('/')[-1])


dic = {'url': teams_urls, 'prefix_2': prefix_2, 'prefix_1': prefix_1}
teams = pd.DataFrame(dic, index=teams)
teams.index.name = 'team'
print(teams)

teams.to_csv(path + "teams_raw.csv", index = False)