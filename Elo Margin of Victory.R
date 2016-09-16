elo.mov <- function(df, init, k) {
  #df['Time', 'Team 1', 'Team 2', 'Team 1 Score', 'Team 2 Score']
  
  
  for(i in 1:length(df[, 1])) {
    df[]
  }
}


games.for.elo.2 <- games[,c("Unique.Week", "Home.Name", "Away.Name", "Home.Points", "Away.Points")]

"elo" <- function(x, status=NULL, init=2200, gamma=0, kfac=27, history=FALSE, sort=TRUE, ...)
{
  if(length(init) != 1) stop("the length of 'init' must be one")
  if(ncol(x) != 4) stop("'x' must have four variables")
  if(nrow(x) == 0) {
    if(is.null(status)) stop("'x' is empty and 'status' is NULL")
    lout <- list(ratings = status, history = NULL, gamma = gamma, kfac=kfac, type = "Elo")
    class(lout) <- "rating"
    return(lout)
  }
  gammas <- rep(gamma, length.out = nrow(x))         
  names(x) <- c("Month","White","Black","White.Score", "Black.Score", "Score", "MoV")
  if(!is.numeric(x$Month)) 
    stop("Time period must be numeric")
  if(!is.numeric(x$White) && !is.character(x$White))
    stop("Player identifiers must be numeric or character")
  if(!is.numeric(x$Black) && !is.character(x$Black))
    stop("Player identifiers must be numeric or character")	
  
  play <- sort(unique(c(x$White,x$Black)))
  np <- length(play)
  x$White <- match(x$White, play)
  x$Black <- match(x$Black, play)
  x$Score <- ifelse(x$White.Score > x$Black.Score, 1, 0)
  x$MoV <- x$White.Score - x$Black.Score
  
  x$Score <- ((x$MoV + 3)^0.8) / (7.5 + 0.006 * (status))
  
  
  if(!is.null(status)) {
    npadd <- play[!(play %in% status$Player)]
    zv <- rep(0, length(npadd))
    npstatus <- data.frame(Player = npadd, Rating = rep(init,length(npadd)), Games = zv, 
                           Win = zv, Draw = zv, Loss = zv, Lag = zv)
    if(!("Games" %in% names(status))) status <- cbind(status, Games = 0)
    if(!("Win" %in% names(status))) status <- cbind(status, Win = 0)
    if(!("Draw" %in% names(status))) status <- cbind(status, Draw = 0)
    if(!("Loss" %in% names(status))) status <- cbind(status, Loss = 0)
    if(!("Lag" %in% names(status))) status <- cbind(status, Lag = 0)
    status <- rbind(status[,c("Player","Rating","Games","Win","Draw","Loss","Lag")], npstatus)
    rinit <- status[,2]
    ngames <- status[,3]
    nwin <- status[,4]
    ndraw <- status[,5]
    nloss <- status[,6]
    nlag <- status[,7]
    names(rinit) <- names(ngames) <- status$Player
  }
  else {
    rinit <- rep(init, length.out=np)
    ngames <- nwin <- ndraw <- nloss <- nlag <- rep(0, length.out=np)
    names(rinit) <- names(ngames) <- names(nlag) <- play
  }
  
  if(!all(names(rinit) == names(ngames)))
    stop("names of ratings and ngames are different")
  if(!all(play %in% names(rinit))) 
    stop("Players in data are not within current status")
  
  nm <- length(unique(x$Month))
  curplay <- match(play, names(rinit))
  orats <- rinit[-curplay] 
  ongames <- ngames[-curplay]
  onwin <- nwin[-curplay]
  ondraw <- ndraw[-curplay]
  onloss <- nloss[-curplay]
  olag <- nlag[-curplay]
  olag[ongames != 0] <- olag[ongames != 0] + nm
  crats <- rinit[curplay] 
  ngames <- ngames[curplay] 
  nwin <- nwin[curplay]
  ndraw <- ndraw[curplay]
  nloss <- nloss[curplay]
  nlag <- nlag[curplay]
  
  gammas <- split(gammas, x$Month)
  x <- split(x, x$Month)
  if(history) {
    histry <- array(NA, dim=c(np,nm,3), dimnames=list(play,1:nm,c("Rating","Games","Lag")))
  }
  
  for(i in 1:nm) {
    traini <- x[[i]]
    gammai <- gammas[[i]] 
    nr <- nrow(traini)
    dscore <- .C("elo_c",
                 as.integer(np), as.integer(nr), as.integer(traini$White-1), as.integer(traini$Black-1),
                 as.double(traini$Score), as.double(crats), as.double(gammai), dscore = double(np))$dscore
    if(!is.function(kfac)) {
      crats <- crats + kfac * dscore
    }
    else {
      crats <- crats + kfac(crats, ngames, ...) * dscore
    }
    trainipl <- c(traini$White,traini$Black)
    trainiplw <- c(traini$White[traini$Score==1],traini$Black[traini$Score==0])
    trainipld <- c(traini$White[traini$Score==0.5],traini$Black[traini$Score==0.5])
    trainipll <- c(traini$White[traini$Score==0],traini$Black[traini$Score==1])
    ngames <- ngames + tabulate(trainipl, np)
    nwin <- nwin + tabulate(trainiplw, np)
    ndraw <- ndraw + tabulate(trainipld, np)
    nloss <- nloss + tabulate(trainipll, np)
    playi <- unique(trainipl)
    nlag[ngames!=0] <- nlag[ngames!=0] + 1
    nlag[playi] <- 0
    
    if(history) {
      histry[,i,1] <- crats
      histry[,i,2] <- ngames
      histry[,i,3] <- nlag
    }
  }
  if(!history) histry <- NULL
  player <- suppressWarnings(as.numeric(names(c(crats,orats))))
  if (any(is.na(player))) player <- names(c(crats,orats))
  dfout <- data.frame(Player=player, Rating=c(crats,orats), Games=c(ngames,ongames), 
                      Win=c(nwin,onwin), Draw=c(ndraw,ondraw), Loss=c(nloss,onloss), Lag=c(nlag,olag),
                      stringsAsFactors = FALSE)
  if(sort) dfout <- dfout[order(dfout$Rating,decreasing=TRUE),] else dfout <- dfout[order(dfout$Player),]
  row.names(dfout) <- 1:nrow(dfout)  
  
  lout <- list(ratings = dfout, history = histry, gamma = gamma, kfac=kfac, type = "Elo")
  class(lout) <- "rating"
  lout
}