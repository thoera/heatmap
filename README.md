# Heatmap in R and Python

This post shows how to draw a heatmap both in `R` and `Python` respectively with `ggplot2` and `seaborn`.

The data I used are last season's NBA statistics provided by [stats.nba.com](http://stats.nba.com/leaders#!?Season=2015-16&SeasonType=Regular%20Season). A txt-file is also available in this repository.

The `R` code is inspired by [Brian Diggs' answer](http://stackoverflow.com/questions/13016022/ggplot2-heatmaps-using-different-gradients-for-categories/13016912#13016912) on stackoverflow.

## In R

To go along with the `ggplot2` package, I'll use `dplyr` and `reshape2` for the data manipulation (yes, I'm a bit of a [Hadley](https://github.com/hadley) fan!).

The import is not a real challenge in `R`.

```R
library("dplyr")
library("ggplot2")

# Load the dataset.
nba <- read.table("nba_top50_2016.txt", sep = ";",
                  header = TRUE, stringsAsFactors = FALSE)
```

The dataframe has 50 rows (the top 50 scorers of the year) and 28 columns (you can use `str(nba)` to check that easily).

Before the actual plotting, a bit of data manipulation is necessary.
* Two variables are not numeric: the player name and the team. If we'll use the name as the "index", we'll drop the team.
* In `ggplot2`, in most cases, it's easier to work with data in long format. We'll reshape our data to that specific format with the `melt` function from the `reshape2` package.
* Last but not least, we scale the values of the game statistics between 0 and 1 to make them comparable.

```R
# Drop "TEAM", reshape the dataset to long format and
# rescale the values between 0 and 1 for each variable.
nba_long <- nba %>%
  select(-TEAM) %>%
  reshape2::melt(id.vars = "PLAYER") %>%
  group_by(variable) %>%
  mutate(rescale_value = scales::rescale(value)) %>%
  ungroup()
```

Rather than the variables names, we'll use custom labels.
```R
# A vector of labels.
labels = c("Age", "Games", "Wins", "Losses", "Minutes",
           "Points", "Field Goals Made", "Field Goals Attempted",
           "Field Goal Percentage", "Three-Point Made",
           "Three-Point Attempted", "Three-Point Percentage",
           "Free Throws Made", "Free Throws Attempted",
           "Free Throw Percentage", "Offensive Rebounds",
           "Defensive Rebounds", "Rebounds", "Assists", "Turnovers",
           "Steals", "Blocks", "Personal Fouls", "Double doubles",
           "Triple doubles", "Plus Minus")
```

The easiest way to draw a heatmap in `ggplot2` I'm aware of is to use `geom_tile` (or `geom_raster` if you want better performances but fewer options) and `scale_fill_gradient`. In the code below, only the first three lines are really necessary to create the plot. All the remaining is just appearence.

```R
# Plot the heatmap and tweak a bit the theme.
ggplot(nba_long, aes(x = variable, y = PLAYER)) +
  geom_raster(aes(fill = rescale_value), color = "white") +
  scale_fill_gradient(low = "white", high = "#7495b9") +
  scale_x_discrete(labels = labels, expand = c(0, 0)) +
  scale_y_discrete(limits = arrange(nba, PTS)[["PLAYER"]],
                   expand = c(0, 0)) +
  labs(title = "NBA's top 50 points leaders", subtitle = "Season 2015-16",
       caption = "data from stats.nba.com", x = "", y = "") +
  theme_minimal(base_size = 16) +
  theme(legend.position = "none",
        axis.ticks = element_blank(),
        axis.text.x = element_text(angle = 30, hjust = 1, color = "grey40"),
        axis.text.y = element_text(color = "grey40"),
        plot.title = element_text(size = 28, color = "grey30"),
        plot.subtitle = element_text(size = 22, color = "grey30"),
        plot.caption = element_text(size = 18, color = "grey30"))
```

![heatmap_ggplot2_1](/plots/heatmap_ggplot2_1.png?raw=true)

This is pretty nice! But can we use a different gradient for the different categories of statistics (offense, defense and other)?

In fact, this question is a bit challenging in `ggplot2`. One way to do it is to scale each group of statistics into different ranges that don't overlap and then use `scale_fill_gradientn` to map each of these regions to different color gradients (as Brian showed it [here](http://stackoverflow.com/questions/13016022/ggplot2-heatmaps-using-different-gradients-for-categories/13016912#13016912)).

We start by splitting up the variables in three sets (offense, defense and other) and by reordering the labels.

```R
# Split up the variables in three sets.
offense <- c("PTS", "FGM", "FGA", "FG_per", "X3PM",
             "X3PA", "X3P_per", "FTM", "FTA", "FT_per", "AST")
defense <- c("OREB", "DREB", "REB", "STL", "BLK")
other <- c("AGE", "GP", "W", "L", "MIN", "TOV",
           "PF", "DD2", "TD3", "plus_minus")

# Reorder the labels.
labels = c("Points", "Field Goals Made", "Field Goals Attempted",
           "Field Goal Percentage", "Three-Point Made",
           "Three-Point Attempted", "Three-Point Percentage",
           "Free Throws Made", "Free Throws Attempted",
           "Free Throw Percentage", "Assists", "Offensive Rebounds",
           "Defensive Rebounds", "Rebounds", "Steals", "Blocks",
           "Age", "Games", "Wins", "Losses", "Minutes", "Turnovers",
           "Personal Fouls", "Double doubles", "Triple doubles", "Plus Minus")
```

Then we scale each group of variables to non-overlapping ranges.
```R
# Create a variable "group_" that takes a different value (0, 1 or 2)
# for each set of statistics and a variable "rescale_offset" that scales each
# group of variables to non-overlapping ranges (0-1, 100-101 and 200-201).
nba_long <- nba_long %>%
  mutate(group_ = case_when(.$variable %in% offense ~ 0,
                            .$variable %in% defense ~ 1,
                            .$variable %in% other ~ 2),
         rescale_offset = rescale_value + 100 * group_)
```

The last step is to choose which colors we want to use and to map them to the three ranges.
```R
# Define the ranges and the colors to use.
gradientn <- range(nba_long$rescale_value) + rep(c(0, 100, 200), each = 2)
colors <- c("white", "#7495b9", "white", "#656684", "white", "#633a45")
```

*Et voilà!*

```R
# Plot the heatmap with a different color for each set of stats and
# order the variables by group.
ggplot(nba_long, aes(variable, PLAYER)) +
  geom_tile(aes(fill = rescale_offset), color = "white") +
  scale_fill_gradientn(colors = colors,
                       values = scales::rescale(gradientn)) +
  scale_x_discrete(limits = c(offense, defense, other), labels = labels,
                   expand = c(0, 0)) +
  scale_y_discrete(limits = arrange(nba, PTS)[["PLAYER"]],
                   expand = c(0, 0)) +
  labs(title = "NBA's top 50 points leaders", subtitle = "Season 2015-16",
       caption = "data from stats.nba.com", x = "", y = "") +
  theme_minimal(base_size = 16) +
  theme(legend.position = "none",
        axis.ticks = element_blank(),
        axis.text.x = element_text(angle = 30, hjust = 1, color = "grey40"),
        axis.text.y = element_text(color = "grey40"),
        plot.title = element_text(size = 28, color = "grey30"),
        plot.subtitle = element_text(size = 22, color = "grey30"),
        plot.caption = element_text(size = 18, color = "grey30"))
```

![heatmap_ggplot2_2](/plots/heatmap_ggplot2_2.png?raw=true)

## In Python

Let's try to replicate these two heatmaps with `seaborn`!
We'll use mainly `pandas` for the (small) data manipulation part.

As in `R`, the import step is pretty straightforward in `Python`.

```Python
# -*- coding: utf-8 -*-

import pandas as pd
from sklearn.preprocessing import MinMaxScaler
import matplotlib.pyplot as plt
import seaborn as sns

# Load the dataset.
nba = pd.read_csv("datasets/nba_top50_2016.txt", sep=";")
```

In `seaborn`, we do not have to reshape the data to long format. In consequence, we just have to remove the variable "TEAM" and scale the values.

```Python
# Use "PLAYER" as the index and drop "TEAM".
nba = nba.set_index("PLAYER").drop("TEAM", axis=1)

# Rescale the values between 0 and 1 for each variable.
nba = pd.DataFrame(MinMaxScaler().fit_transform(nba),
                   index=nba.index, columns=nba.columns)
```

It exists a heatmap function in `seaborn` which makes the plot quite easy.

```Python
# Plot the heatmap.
plt.figure(figsize=(16, 12))

heatmap = sns.heatmap(nba, linewidths=0.2, cbar=False,
                      cmap=sns.light_palette("#7495b9", as_cmap=True))

# Create the labels, remove the axis titles and add a title to the plot.
heatmap.set_xticklabels(["Age", "Games", "Wins", "Losses", "Minutes",
                         "Points", "Field Goals Made", "Field Goals Attempted",
                         "Field Goal Percentage", "Three-Point Made",
                         "Three-Point Attempted", "Three-Point Percentage",
                         "Free Throws Made", "Free Throws Attempted",
                         "Free Throw Percentage", "Offensive Rebounds",
                         "Defensive Rebounds", "Rebounds", "Assists",
                         "Turnovers", "Steals", "Blocks", "Personal Fouls",
                         "Double doubles", "Triple doubles", "Plus Minus"],
                        rotation=30, ha="right", fontsize=12, color="#666666")
heatmap.set_yticklabels(nba.index, fontsize=12, color="#666666")
plt.xlabel("")
plt.ylabel("")
plt.title("NBA's top 50 points leaders\nSeason 2015-16", loc="left",
          fontsize=28, color="#4d4d4d")
```

![heatmap_seaborn_1](/plots/heatmap_seaborn_1.png?raw=true)

It looks a lot like the `ggplot2` version, doesn't it?

Using a different gradient for the different categories of statistics is easier in `seaborn` thanks to the awesome `mask` argument which provides a way to hide data in a plot. To quote the documentation: "data will not be shown in cells where mask is True".

Like in `R`, we start by splitting up the variables in three sets (offense, defense and other), we reorder our columns and then we create three masks to hide alternatively the columns that we don't want to show.

```Python
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
```

Finally we plot three heatmaps with three different masks on the same figure. And as a result we get a nice heatmap with a different gradient for each category!

```Python
# Plot the three heatmaps.
plt.figure(figsize=(16, 12))

heatmap = sns.heatmap(nba, linewidths=0.2, cbar=False, mask=offense,
                      cmap=sns.light_palette("#7495b9", as_cmap=True))
heatmap = sns.heatmap(nba, linewidths=0.2, cbar=False, mask=defense,
                      cmap=sns.light_palette("#656684", as_cmap=True))
heatmap = sns.heatmap(nba, linewidths=0.2, cbar=False, mask=other,
                      cmap=sns.light_palette("#633a45", as_cmap=True))

# Reorder the labels, remove the axis titles and add a title to the plot.
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
                        rotation=30, ha="right", fontsize=12, color="#666666")
heatmap.set_yticklabels(nba.index, fontsize=12, color="#666666")
plt.xlabel("")
plt.ylabel("")
plt.title("NBA's top 50 points leaders\nSeason 2015-16", loc="left",
          fontsize=28, color="#4d4d4d")
```

![heatmap_seaborn_2](/plots/heatmap_seaborn_2.png?raw=true)
