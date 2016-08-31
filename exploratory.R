library(psych)
library(pROC)
library(caret)
library(e1071)
library(nnet)
library(plyr)
library(zoo)
library(reshape2)

#full.data <- read.csv("~/2005-2013.csv")
full.data <- read.csv("C:/Users/John/Documents/College Football/2005-2013.csv")
full.data$Site.Dummy <- ifelse(full.data$Site == "Home", 1, 0)

#WILL BE WRONG ON NEUTRAL FIELDS
full.data$Pct.Capacity <- full.data$Attendance / full.data$Capacity

games <- full.data[, !names(full.data) %in% c(#"Home.Team.Code", 
                                              "Date", "Game.Code", "Visit.Team.Code", 
                                              "Stadium.Code", "Site",
                                              "Duration", "Stadium", "Attendance", "City",
                                              "State", "Capacity", "Surface", "Year.Opened",
                                              "Home.Team.Name", "Home.Conference.Code", 
                                              "Away.Team.Name", "Away.Conference.Code",
                                              "Home.Conference", "Home.Subdivision",
                                              "Away.Conference", "Away.Subdivision",
                                              "Home.Points", "Away")]#, 
                                              #"Home.Win")] 

mav <- ddply(games, "Home.Team.Code", 
             last26 = rollmean(games$Home.Pass.Yard, 3, align="left", fill = NA))

# games.pca <- prcomp(games,
#                     center = TRUE,
#                     scale. = TRUE)
# 
# plot(games.pca, type = "l")

wins <- games$Home.Win
games <- scale(games, center = TRUE, scale = TRUE)
games <- as.data.frame(games)
games$Home.Win <- wins

#LOGISTIC REGRESSION
model <- glm(Home.Win ~ Home.Pass.Yard + Home.Rush.Yard + Home.Sack
             + Home.Time.Of.Possession
             + Home.Tackle.Solo + Home.Tackle.Assist + Home.Kickoff,family=binomial(link='logit'),data=games)
summary(model)
prob <- predict(model,Home.Win=c(1))
games$prob <- as.numeric(prob)

g <- roc(Home.Win ~ prob, data = games)
plot(g)  

coords(g, "best")

games$prediction <- ifelse(prob > 0.5,1,0)

confusionMatrix(games$prediction,games$Home.Win, positive = '1')


#NEURAL NET
net <- nnet(Home.Win ~ Home.Pass.Yard + Home.Rush.Yard + Home.Sack
            + Home.Penalty.Yard + Home.Time.Of.Possession
            + Home.Tackle.Solo + Home.Tackle.Assist + Home.Kickoff, data = games, size = 10)
summary(net)

net.prob <- predict(net, Home.Win=c(1))
games$net.prob=net.prob

games$net.prediction <- ifelse(net.prob > 0.5,1,0)

confusionMatrix(games$net.prediction, games$Home.Win, positive = '1')
