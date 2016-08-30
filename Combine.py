# -*- coding: utf-8 -*-
"""
Created on Tue Aug 30 11:32:32 2016

@author: jtmartin
"""

import pandas as pd, numpy as np, os

cfb = 'C:/Users/jtmartin/Documents/College Football/'
csvs = 'Yearly .csv Data/'

l = []


for file in os.listdir(cfb + csvs):
        if '.csv' in file:
                df = pd.read_csv(cfb + csvs + file)
                l.append(df)


total = pd.DataFrame()         
total = pd.concat(l)

total.to_csv(cfb + '2005-2013.csv', index = False)