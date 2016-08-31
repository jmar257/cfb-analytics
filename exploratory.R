library(psych)
library(pROC)
library(caret)
library(e1071)
library(nnet)
library(plyr)
library(zoo)
library(reshape2)
library(TTR)
library(dplyr)
library( pca3d )

games <- read.csv("~/2005-2013.csv")
#games$Site.Dummy <- ifelse(games$Site == "Home", 1, 0)
games$Team.Code <- as.factor(games$Team.Code)

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


games <- games[complete.cases(games),]
games <- drop.factors(games, "Team.Code", 26)

games <- arrange(games, Team.Code, as.Date(games$Date, format="%m/%d/%Y"))

# games$mav.Pass.Yard <- ddply(games, "Team.Code", 
#              last26 = rollmean(x, 3, align="right", fill = NA))

games.mav <- games
games.mav <- games[,0:9]

#new.row <- data.frame(A=11, B="K", stringsAsFactors=F)
#games <- rbind.fill(games, new.row)

for(i in seq(length(games[,10:74]))){
  j <- i + 9
  #games[,j] <- lag(games[,j], n=1)
  games.mav[,j] <- as.vector(ave(games[,j], games$Team.Code, 
                  FUN= function(x) rollmean(x, k=26, align="right", na.pad=TRUE) ))
}

#games[,10:76] <- as.data.frame(apply(games[,10:12], 2, SMA, n=26))

#skoo <- ddply(games, .(Team.Code), transform, Pass.Yard.mav = SMA(games$Pass.Yard, n = 26))

#games.mav$Site.Dummy <- games$Site.Dummy
colnames(games.mav) <- colnames(games)
games.mav <- games.mav[complete.cases(games.mav),]

#wins <- games$Home.Win
#games.mav[,10:75] <- scale(games.mav[,10:75], center = TRUE, scale = TRUE)
games.mav <- as.data.frame(games.mav)
#games$Home.Win <- wins

games.pca <- prcomp(games.mav[,10:74],
                    center = TRUE,
                    scale. = TRUE)#,
                    #tol = .6)

plot(games.pca, type = "l")
pca2d( games.pca, biplot= TRUE, shape= 19, col= "black"  )

write.csv(games.pca$rotation, file = "~/factor loadings.csv")

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
