library(pca3d)

games <- read.csv("~/games mav.csv")
games.pca <- prcomp(games.mav[,11:75],
                    center = TRUE,
                    scale. = TRUE)#
#tol = .6)



plot(games.pca, type = "l")
pca2d( games.pca, biplot= TRUE, shape= 19, col= "black"  )

write.csv(games.pca$rotation, file = "~/factor loadings.csv")