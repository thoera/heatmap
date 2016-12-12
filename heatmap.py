# -*- coding: utf-8 -*-

import pandas as pd
from sklearn.preprocessing import MinMaxScaler
import matplotlib.pyplot as plt
import seaborn as sns

# Load the dataset.
nba = pd.read_csv("datasets/nba_top50_2016.txt", sep=";")

# Use "PLAYER" as the index and drop "TEAM".
nba = nba.set_index("PLAYER").drop("TEAM", axis=1)

# Rescale the values between 0 and 1 for each variable.
nba = pd.DataFrame(MinMaxScaler().fit_transform(nba),
                   index=nba.index, columns=nba.columns)

# Plot the heatmap.
plt.figure(figsize=(12, 9))

heatmap = sns.heatmap(nba, linewidths=0.2, cbar=False,
                      cmap=sns.light_palette("#7495b9", as_cmap=True))

# A vector of labels.
heatmap.set_xticklabels(["Age", "Games", "Wins", "Losses", "Minutes",
                         "Points", "Field Goals Made", "Field Goals Attempted",
                         "Field Goal Percentage", "Three-Point Made",
                         "Three-Point Attempted", "Three-Point Percentage",
                         "Free Throws Made", "Free Throws Attempted",
                         "Free Throw Percentage", "Offensive Rebounds",
                         "Defensive Rebounds", "Rebounds", "Assists",
                         "Turnovers", "Steals", "Blocks", "Personal Fouls",
                         "Double doubles", "Triple doubles", "Plus Minus"],
                        rotation=30, ha="right")

# Remove the axis titles and add a title to the plot.
plt.xlabel("")
plt.ylabel("")
plt.title("NBA's top 50 points leaders\nSeason 2015-16", loc="left",
          fontsize=22)

# -----

# We would like to use a different color for each group of statistics (offense,
# defense, other).
# One way to do it is to use masks and plot several times the heatmap with
# different color gradients.

# Split up the variables in three sets.
offense = ["PTS", "FGM", "FGA", "FG_per", "3PM", "3PA",
           "3P_per", "FTM", "FTA", "FT_per", "AST"]
defense = ["OREB", "DREB", "REB", "STL", "BLK"]
other = ["AGE", "GP", "W", "L", "MIN", "TOV",
         "PF", "DD2", "TD3", "plus_minus"]

# Reorder the columns.
nba = nba[offense + defense + other]

# Create the masks.
offense = (nba == nba) & [col not in offense for col in nba.columns]
defense = (nba == nba) & [col not in defense for col in nba.columns]
other = (nba == nba) & [col not in other for col in nba.columns]

# Plot the three heatmaps.
plt.figure(figsize=(12, 9))

heatmap = sns.heatmap(nba, linewidths=0.2, cbar=False, mask=offense,
                      cmap=sns.light_palette("#7495b9", as_cmap=True))
heatmap = sns.heatmap(nba, linewidths=0.2, cbar=False, mask=defense,
                      cmap=sns.light_palette("#656684", as_cmap=True))
heatmap = sns.heatmap(nba, linewidths=0.2, cbar=False, mask=other,
                      cmap=sns.light_palette("#633a45", as_cmap=True))

# Reorder the labels.
heatmap.set_xticklabels(["Points", "Field Goals Made", "Field Goals Attempted",
                         "Field Goal Percentage", "Three-Point Made",
                         "Three-Point Attempted", "Three-Point Percentage",
                         "Free Throws Made", "Free Throws Attempted",
                         "Free Throw Percentage", "Assists",
                         "Offensive Rebounds", "Defensive Rebounds",
                         "Rebounds", "Steals", "Blocks", "Age", "Games",
                         "Wins", "Losses", "Minutes", "Turnovers",
                         "Personal Fouls", "Double doubles",
                         "Triple doubles", "Plus Minus"],
                        rotation=30, ha="right")

# Remove the axis titles and add a title to the plot.
plt.xlabel("")
plt.ylabel("")
plt.title("NBA's top 50 points leaders\nSeason 2015-16", loc="left",
          fontsize=22)
