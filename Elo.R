library(PlayerRatings)
library(dplyr)
library(plyr)
library(magrittr)
library(ggvis)

games <- read.csv("~/2005-2013 Unique Game Weeks.csv")
teams <- read.csv("~/team.csv")

games <- merge(games, teams[,1:2], by.x="Home.Team.Code", by.y="Team.Code")
games <- rename(games, c("Name" = "Home.Name"))
games <- merge(games, teams[,1:2], by.x="Visit.Team.Code", by.y="Team.Code")
games <- rename(games, c("Name" = "Away.Name"))

games$Home.Name <- as.character(games$Home.Name)
games$Away.Name <- as.character(games$Away.Name)


games.for.elo <- games[,c("Unique.Week", "Home.Name", "Away.Name", "Home.Win")]

#games.for.elo$Date <- as.numeric(as.POSIXlt(games.for.elo$Date, format="%m/%d/%Y"))

games.elo <- elo(games.for.elo, init = 1500, k = 25, sort = TRUE, history = TRUE)
ratings <- games.elo$ratings
history <- as.data.frame(t(as.data.frame(games.elo$history)))
history <- history[1:137, ]

team <- "Duke"
team2 <- "Clemson"

plot(x = 1:length(history[, team]), y = history[, team], type='c', xlab = team,
     ylab = 'Elo Rating', xlim=c(1, 137), ylim=c(1200, 1950))
lines(history[, team], col = "red")
lines(history[, team2], col = "orange")

for(i in 1:217) {
  lines(history[, i])
}

lines(1:137, rep(1500, 137), col = "yellow")


