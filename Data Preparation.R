library(caret)
library(plyr)
library(zoo)
library(reshape2)
library(TTR)
library(dplyr)

drop.factors <- function (df, column, threshold) { 
  size <- nrow(df) 
  if (threshold < 1) threshold <- threshold * size 
  tab <- table(df[[column]]) 
  keep <- names(tab)[tab >  threshold] 
  drop <- names(tab)[tab <= threshold] 
  cat("Keep(",column,")",length(keep),"\n"); print(tab[keep]) 
  cat("Drop(",column,")",length(drop),"\n"); print(tab[drop]) 
  str(df) 
  df <- df[df[[column]] %in% keep, ] 
  str(df) 
  size1 <- nrow(df) 
  cat("Rows:",size,"-->",size1,"(dropped",100*(size-size1)/size,"%)\n") 
  df[[column]] <- factor(df[[column]], levels=keep) 
  df 
}

roll <- function(x, n) { 
  rollapply(x, list(-seq(n)), mean, fill = NA)
}

games <- read.csv("~/2005-2013.csv")
games$Team.Code <- as.factor(games$Team.Code)

#Make sure there's two instances of every game code
games <- drop.factors(games, "Game.Code", 1)

#Create win column
games <- games %>% group_by("Game.Code") %>% 
  mutate("Win"=if(first(Points) > last(Points)) as.integer(c(1,0)) else as.integer(c(0,1)))

games <- subset(games, select=c(1:2,76, 3:75))

games <- games[, !names(games) %in% c("Points")]#"Home.Team.Code", 
#   "Date", "Game.Code", "Visit.Team.Code", 
#   "Stadium.Code", "Site",
#   "Duration", "Stadium", "Attendance", "City",
#   "State", "Capacity", "Surface", "Year.Opened",
#   "Home.Team.Name", "Home.Conference.Code", 
#   "Away.Team.Name", "Away.Conference.Code",
#   "Home.Conference", "Home.Subdivision",
#   "Away.Conference", "Away.Subdivision",
#   "Home.Points", "Away")]#, 
#"Home.Win")] 

games <- games[complete.cases(games),]
games <- drop.factors(games, "Team.Code", 26)

games <- arrange(games, Team.Code, as.Date(games$Date, format="%m/%d/%Y"))

games.mav <- games
games.mav <- games[,0:10]

games.mav[,11:75] <- apply(games[, 11:75], 2, function(x) x = ave(x, games$Team.Code, FUN = function(y) roll(y, 26)))

games.mav <- as.data.frame(games.mav)
colnames(games.mav) <- colnames(games)
games.mav <- games.mav[complete.cases(games.mav),]
write.csv(games.mav, file = "~/games mav.csv", row.names = FALSE)