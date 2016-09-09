library(PlayerRatings)
library(dplyr)

# games <- read.csv("~/2005-2013 Unique Game.csv")
# 
# games.for.elo <- games[,c("Date", "Home.Team.Code", "Visit.Team.Code", "Home.Win")]
# 
# games.for.elo$Date <- as.numeric(as.POSIXlt(games.for.elo$Date, format="%m/%d/%Y"))
# 
# games.elo <- elo(games.for.elo, init = 1000, k = 15, sort = TRUE)

drives <- read.csv("~/2005-2013 Drives.csv")
drives$End.Reason <- as.factor(drives$End.Reason)
# end.reason <- drives$End.Reason
# dummies <- model.matrix(~drives$End.Reason)
# drives <- cbind(drives, dummies)
# drives$End.Reason <- end.reason

drives$Points <- ifelse(drives$End.Reason == "TOUCHDOWN", 7, 
                    ifelse(drives$End.Reason == "FIELD GOAL", 3, 
                           ifelse(drives$End.Reason == "SAFETY", -2, 0)))

drives$Start.Spot <- as.factor(drives$Start.Spot)

expected <- aggregate(drives$Points, by = list(drives$Start.Spot), mean)

expected$Group.1 <- (100 - as.numeric(expected$Group.1))

drives$Starting.Pos.To.EZ <- (100 - as.numeric(drives$Start.Spot))

colnames(expected) <- c("Starting.Pos.To.EZ", "Expected.Points")

drives <- merge(drives, expected, by="Starting.Pos.To.EZ")

l <- lm(Points ~ as.numeric(Starting.Pos.To.EZ), drives)
summary(l)


plot(expected, type = "c", xlab = "Yards to End Zone", ylab = "Expected Points")
lines(expected)
abline(l)

write.csv(drives, file = "~/Drives with Expected Points.csv", row.names = FALSE)

