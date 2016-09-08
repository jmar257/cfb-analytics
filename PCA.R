library(pca3d)
library(corrplot)
library(qtlcharts)

games.mav <- read.csv("~/games mav.csv")

#NEED TO REMOVE OTHER VARIABLES THAT HIGHLY CORRELATE
games.mav <- games.mav[, !names(games.mav) %in% c("Rush.Att", "Rush.TD", "Pass.Att",
                                                  "Pass.Comp", "Pass.TD", "Kickoff.Ret",
                                                  "Punt.Ret", "Fum.Ret.Yard", "Fum.Ret.TD",
                                                  "Int.Ret.Yard", "Int.Ret.TD", "Misc.Ret",
                                                  "Misc.Ret.TD", "Field.Goal.Att", 
                                                  "Off.XP.Kick.Att", "Off.2XP.Att",
                                                  "Def.2XP.Att", "Punt", "Kickoff", 
                                                  "Fumble", "Tackle.For.Loss",
                                                  "Sack", "Penalty.Yard", 
                                                  "Red.Zone.TD", "Red.Zone.Field.Goal")]

corr.matrix <- cor(games.mav[,11:50])

corrplot(corr.matrix, method = "circle")
iplotCorr(corr.matrix, reorder=TRUE)

write.csv(corr.matrix, file = "~/correlation matrix.csv")

games.pca <- prcomp(games.mav[,11:50],
                    center = TRUE,
                    scale. = TRUE,
                    retx = TRUE)#,
                    #tol = .6)

plot(games.pca, type = "l")
pca2d( games.pca, biplot= TRUE, shape= 19, col= "black"  )

write.csv(games.pca$rotation, file = "~/factor loadings.csv")

varimax <- varimax(games.pca$rotation)
rotated <-  as.data.frame(scale(games.mav[,11:75]) %*% varimax$loadings)

rotated <- cbind(games.mav[,1:10], rotated)

write.csv(rotated, file = "~/varimax factors.csv")
