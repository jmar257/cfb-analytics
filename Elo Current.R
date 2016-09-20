library(PlayerRatings)
library(dplyr)
library(plyr)
library(magrittr)

games <- read.csv("~/FBS Data.csv")

games$Home.Win <- ifelse(games$Home.Score > games$Away.Score, 1, 0)
games$Home.Team <- as.character(games$Home.Team)
games$Away.Team <- as.character(games$Away.Team)

games.for.elo <- games[,c("Unique.Week", "Home.Team", "Away.Team", "Home.Win")]

numteams <- length(unique(c(games$Home.Team, games$Away.Team)))
numweeks <- length(unique(games$Unique.Week))

numweeks <- 221

games.for.elo <- games.for.elo[games.for.elo$Unique.Week <= numweeks,]

games.elo <- elo(games.for.elo, init = 1500, k = 25, sort = TRUE, history = TRUE)
ratings <- games.elo$ratings
history <- as.data.frame(t(as.data.frame(games.elo$history)))
history <- history[1:(numweeks-1), ]

hist(ratings$Rating, breaks = 9, xlab = "Elo Rating", ylab = "Frequency", main = "Distribution of Ratings")
#curve(dnorm(mean = 1500),add=T,col="blue")

team <- "Louisville"
team2 <- "Florida State"
#weeks <- unique(games$Unique.Week)
# years <- merge(x = as.data.frame(weeks), y = games[,2:5], by.x = "weeks",
#                by.y = "Unique.Week", all.x = TRUE)
# years <- years[years$Day == "Sat.",]
# years <- subset(years, !duplicated(weeks))
# years$Date <- gsub("Sept.", "Sep.", years$Date)
# years$Date <- as.Date(years$Date, "%b. %d, %Y")
                
plot(x = 2:numweeks, y = NULL, type='l', xlab = team,
     ylab = 'Elo Rating',  xlim=c(1, numweeks),ylim=c(1150, 2050)) 
#axis(1, at = 1:219, labels = format(years$Date, "%Y"), cex.axis = 1)

#ggplot( data = as.data.frame(cbind(years$Date[2:221], history[, team])), aes( V1, V2 )) + geom_line() 

# Graph every team
# for(i in 1:numteams) {
#   lines(history[, i])

lines(1:numweeks, rep(1500, numweeks), col = "black")
lines(history[, team], col = "red")
lines(history[, team2], col = "blue")

#Calculate probabilities
#P(A) = 1/(1+10^m) where m = team2.score - team.score / 400
team.score <- ratings[ratings$Player == team, "Rating"]
team2.score <- ratings[ratings$Player == team2, "Rating"]
m <- (team2.score - team.score) / 400
prob.a <- 1 / (1 + (10^m))
print(team.score)
print(team2.score)
prob.a


#write.csv(history, "~/historical elo.csv", row.names = FALSE)




set.seed(69)
ratings <- ratings[(ratings$Win + ratings$Loss) > 50,]

cluster <- kmeans(ratings[,2], 3, nstart = 20)
summary(cluster)

cluster$cluster <- as.factor(cluster$cluster)
ggplot(ratings, aes(Rating, Win, color = cluster$cluster)) + geom_point()

