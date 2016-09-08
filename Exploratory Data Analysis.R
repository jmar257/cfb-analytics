library(pROC)
library(caret)
library(nnet)
library(TTR)
library(magrittr)
library(randomForest)
library(caTools)
library(flexclust)
library(ggplot2)

games.mav <- read.csv("~/games mav.csv")

#CENTER AND SCALE
games.mav[,11:75] <- scale(games.mav[,11:75], center = TRUE, scale = TRUE)
write.csv(games.mav, file = "~/standardized games mav.csv", row.names = FALSE)

set.seed(69)
games.mav$Win <- as.factor(games.mav$Win)
x <- sample.split (games.mav, SplitRatio= 0.7)
train <- games.mav[x,]
test <- games.mav[!x,]

#LOGISTIC REGRESSION
model <- glm(train$Win ~ .
               #Pass.Yard + Rush.Yard + Sack.Yard + Time.Of.Possession + Tackle.Solo 
             #+ Tackle.Assist + Kickoff.Yard
             ,family=binomial(link='logit'),data=train[,11:75])

model <- step(model,scope=formula(model),
     direction="backward",k=2)  

#BACKWARD STEPWISE CHOSE THIS
model <- glm(train$Win ~ Rush.Yard + Rush.TD + Pass.TD + Kickoff.Ret + Kickoff.Ret.TD + 
  Punt.Ret.TD + Fum.Ret.TD + Int.Ret + Int.Ret.TD + Misc.Ret.Yard + 
  Off.XP.Kick.Att + Off.XP.Kick.Made + Off.2XP.Att + Def.2XP.Att + 
  Safety + Punt.Yard + Kickoff.Yard + Tackle.Solo + Tackle.Assist + 
  Sack + Fumble.Forced + X1st.Down.Rush + X1st.Down.Penalty + 
  Time.Of.Possession + Penalty + Penalty.Yard + Fourth.Down.Att
  ,family=binomial(link='logit'),data=train[,11:75])

summary(model)
prob <- predict(model, test[,11:75])
test$prob <- as.numeric(prob)

g <- roc(Win ~ prob, data = test)
plot(g)  

coords(g, "best")

test$prediction <- ifelse(prob > 0.5,1,0)

confusionMatrix(test$prediction,test$Win, positive = '1')



#NEURAL NET
train$Win <- as.factor(train$Win)
test$Win <- as.factor(test$Win)
#train$Y <- class.ind(train$Win)
#train$Win <- NULL

net <- nnet(train$Win ~ ., data = train[,11:75], size = 10, MaxNWts = 2500)#, 
            #softmax=TRUE, entropy = TRUE)

net.prob <- predict(net, test[,11:75])
test$net.prob <- net.prob

test$net.prediction <- ifelse(net.prob > 0.5,1,0)

confusionMatrix(test$net.prediction, test$Win, positive = '1')


#RANDOM FOREST
train$Win <- as.factor(train$Win)
test$Win <- as.factor(test$Win)

forest <- randomForest(formula = train$Win ~ . , data = train[,11:75], ntree = 100)

forest.prediction <- predict(forest, test[,11:75])
test$forest.prediction <- forest.prediction

confusionMatrix(test$forest.prediction, test$Win, positive = '1')


#K MEANS CLUSTERING
set.seed(420)

games.cluster <- kmeans(train[,11:75], 2, nstart = 20)
summary(games.cluster)

games.cluster$cluster <- as.factor(games.cluster$cluster)
ggplot(train[,11:75], aes(Pass.TD + Rush.TD, Sack, color = games.cluster$cluster)) + geom_point()

games.cluster <- as.kcca(games.cluster, data=train[,11:75])


#Mess Around with linear regression
l <- lm(Pass.TD + Rush.TD ~ . + train$Time.Of.Possession, train[,11:25])
summary(l)



