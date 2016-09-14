library(shiny)
library(ggvis)
library(magrittr)
library(PlayerRatings)

loc <- 'C:/Users/John/Documents/College Football/'

games <- read.csv("C:/Users/John/Documents/College Football/2005-2013 Unique Game Weeks.csv")
teams <- read.csv("C:/Users/John/Documents/College Football/team.csv")

games <- merge(games, teams[,1:2], by.x="Home.Team.Code", by.y="Team.Code")
games <- rename(games, c("Name" = "Home.Name"))
games <- merge(games, teams[,1:2], by.x="Visit.Team.Code", by.y="Team.Code")
games <- rename(games, c("Name" = "Away.Name"))

games$Home.Name <- as.character(games$Home.Name)
games$Away.Name <- as.character(games$Away.Name)


games.for.elo <- games[,c("Unique.Week", "Home.Name", "Away.Name", "Home.Win")]

games.elo <- elo(games.for.elo, init = 1500, k = 25, sort = TRUE, history = TRUE)
ratings <- games.elo$ratings
history <- as.data.frame(t(as.data.frame(games.elo$history)))
history <- history[1:137, ]

shinyServer(
  function(input, output) {
    
  teamInput <- reactive({
    teams <- cbind(1:length(subset(history, select=c(input$team))), subset(history, select=c(input$team)))
    colnames(teams) <- c("Game", "Elo")
    })
    
  output$plot1  <- reactive({    
    teamInput() %>% 
      ggvis(~as.name(Game), ~as.name(Elo)) %>%
      layer_lines(fill := 'black') 
  }) %>% bind_shiny(c("ggvis"))
    
#     reactive({
#     plot(x = 1:length(history$teamInput), y = history$teamInput, 
#                         type='c', xlab = history$teamInput, ylab = 'Elo Rating')
#   })
  #lines(history$teamInput)
  
})


