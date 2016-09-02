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
library(pca3d)

games <- read.csv("~/2005-2013.csv")
games$Team.Code <- as.factor(games$Team.Code)

#games <- games[, !names(games) %in% c("Points")]#"Home.Team.Code", 
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

roll <- function(x, n) { 
  rollapply(x, list(-seq(n)), mean, fill = NA)
}


games <- games[complete.cases(games),]
games <- drop.factors(games, "Team.Code", 26)

games <- arrange(games, Team.Code, as.Date(games$Date, format="%m/%d/%Y"))

games.mav <- games
games.mav <- games[,0:9]

games.mav[,10:length(colnames(games))] <- apply(games[, 10:length(colnames(games))], 2, function(x) x = ave(x, games$Team.Code, FUN = function(y) roll(y, 26)))

games.mav <- as.data.frame(games.mav)
colnames(games.mav) <- colnames(games)
games.mav <- games.mav[complete.cases(games.mav),]
write.csv(games.mav, file = "~/games mav.csv", row.names = FALSE)

#PRINCIPAL COMPONENT ANALYSIS
games.pca <- prcomp(games.mav[,10:length(colnames(games.mav))],
                    center = TRUE,
                    scale. = TRUE)#
#tol = .6)



plot(games.pca, type = "l")
pca2d( games.pca, biplot= TRUE, shape= 19, col= "black"  )

write.csv(games.pca$rotation, file = "~/factor loadings.csv", row.names = FALSE)

#CENTER AND SCALE
games.mav[,10:length(colnames(games.mav))] <- scale(games.mav[,10:length(colnames(games.mav))], center = TRUE, scale = TRUE)
write.csv(games.mav, file = "~/standardized games mav.csv", row.names = FALSE)

#REGRESSION ON RUSH TDS
fit <- lm(Rush.TD ~ Rush.Yard, data=games)
summary(fit)
coefficients(fit) # model coefficients
confint(fit, level=0.95) # CIs for model parameters 
fitted(fit) # predicted values
residuals(fit) # residuals
anova(fit) # anova table 
vcov(fit) # covariance matrix for model parameters 
influence(fit) # regression diagnostics

#CLUSTER ANALYSIS
set.seed(69)
games.cluster <- kmeans(games.mav[, 10:length(colnames(games.mav))], 5, nstart = 20)
games.cluster

games.cluster$cluster <- as.factor(games.cluster$cluster)
ggplot(games.mav, aes(Penalty.Yard, Rush.Att, color = games.cluster$cluster)) + geom_point()

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
