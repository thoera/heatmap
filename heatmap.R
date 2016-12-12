library("dplyr")
library("ggplot2")

# Load the dataset.
nba <- read.table("nba_top50_2016.txt", sep = ";",
                  header = TRUE, stringsAsFactors = FALSE)
str(nba)

# Drop "TEAM", reshape the dataset to long format and
# rescale the values between 0 and 1 for each variable.
nba_long <- nba %>%
  select(-TEAM) %>%
  reshape2::melt(id.vars = "PLAYER") %>%
  group_by(variable) %>%
  mutate(rescale_value = scales::rescale(value)) %>%
  ungroup()

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

# Plot the heatmap and tweak a bit the theme.
ggplot(nba_long, aes(x = variable, y = PLAYER)) +
  geom_tile(aes(fill = rescale_value), color = "white") +
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

# -----

# We would like to use a different color for each group of statistics (offense,
# defense, other). But using different gradient colors for different categories
# is not that easy in ggplot2.
# One way to do it is to scale each group of variables into different
# ranges that don't overlap and then use scale_fill_gradientn to map
# each of these regions to different color gradients.

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

# Create a variable "group_" that takes a different value (0, 1 or 2)
# for each set of statistics and a variable "rescale_offset" that scales each
# group of variables to non-overlapping ranges (0-1, 100-101 and 200-201).
nba_long <- nba_long %>%
  mutate(group_ = case_when(.$variable %in% offense ~ 0,
                            .$variable %in% defense ~ 1,
                            .$variable %in% other ~ 2),
         rescale_offset = rescale_value + 100 * group_)

# Define the ranges and the colors to use.
gradientn <- range(nba_long$rescale_value) + rep(c(0, 100, 200), each = 2)
colors <- c("white", "#7495b9", "white", "#656684", "white", "#633a45")

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
