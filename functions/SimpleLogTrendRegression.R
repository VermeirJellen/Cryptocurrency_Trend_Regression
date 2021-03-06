SimpleLogTrendRegression <- function(data, 
                                     data.identifier = "BTC-price", 
                                     regression.type = "loess",
                                     data.frequency  = "daily",
                                     nr.future       = 340, 
                                     log.base        = exp(1),
                                     loess.degree    = 1, 
                                     plot.2sd.log    = TRUE, 
                                     plot.2sd.levels = FALSE){
  
  to.fit        <- data.frame(log(data, base=log.base), seq_along(data))
  names(to.fit) <- c("ln.data", "time")
  freq.str      <- ifelse(data.frequency == "daily", "nr.days", "nr.weeks")
  
  if(regression.type == "loess"){
    model.fit <- loess(ln.data ~ time, to.fit, 
                       degree  = loess.degree,
                       control = loess.control(surface = "direct"))
    
    plot.txt.log <- paste("log(", data.identifier, ") ~ loess", sep="")
    plot.txt.lvl <- paste(data.identifier, " ~ exp(loess)", sep="")
  }
  else if(regression.type == "exponential"){
    
    # y = A(r^x)
    # ln(y) = ln(A) + ln(r)*x =>
    # => ln(y) ~ b + mx => A = exp(b); r = exp(m)
    model.fit <- lm(ln.data ~ time, to.fit)
    b <- model.fit$coefficients[1]; A <- exp(b)
    m <- model.fit$coefficients[2]; r <- exp(m)
    
    plot.txt.log <- paste("log(", data.identifier, ") ~ ", round(b, 4), 
                          " + ", round(m, 4), " *", freq.str, sep="")
    plot.txt.lvl <- paste(data.identifier, " ~ ",   round(A, 4), 
                          " * (", round(r, 4), "^", freq.str, ")", sep="")
  }
  else{ # regression.type = "logarithmic"
    
    # y = A*(x^r)
    # ln(y) = ln(A) + r*ln(x)
    # => ln(y) = b + r*ln(x) => A = exp(b);
    model.fit <- lm(ln.data ~ log(time, base=log.base), to.fit)
    b <- model.fit$coefficients[1]; A <- exp(b)
    r <- model.fit$coefficients[2]
    
    plot.txt.log <- paste("log(", data.identifier, ") ~ ", round(b, 4), 
                          " + ", round(r, 4), "*log(", freq.str, ")", sep="")
    plot.txt.lvl <- paste(data.identifier, " ~ ",   round(A, 6),
                          " * (", freq.str, "^", round(r, 4), ")", sep="")
    
  }
  
  nr.idx      <- nrow(to.fit)
  future.idx  <- seq(nr.idx+1, nr.idx+nr.future)
  future.pred <- predict(model.fit, data.frame(time=future.idx))
  
  timestamps <- index(data)
  model.sd   <- sd(model.fit$residuals)
  model.pred <- predict(model.fit)
  
  first.date     <- head(timestamps, 1)
  latest.date    <- tail(timestamps, 1)
  
  if(data.frequency == "daily"){
    timestamps.oos <- seq(latest.date + lubridate::days(1), 
                          latest.date + lubridate::days(nr.future), by="days")
  }
  else {
    timestamps.oos <- seq(latest.date + lubridate::weeks(1), 
                          latest.date + lubridate::weeks(nr.future), by="weeks")
  }
  model.pred.oos <- predict(model.fit, data.frame(time=seq(nr.idx+1, nr.idx+nr.future)))
  
  #################
  ### Plotting ####
  #################
  
  ###########################################
  # logarithmic chart #######################
  ###########################################
  y.lim.sd   <- ifelse(plot.2sd.log, 2, 1)
  plot(timestamps, log(data, base=log.base), lty=1, type="l",
       main=plot.txt.log,
       xlim = c(first.date, tail(timestamps.oos, 1)), xlab="Time",
       ylim = c(min(log(data, base=log.base), model.pred - y.lim.sd*model.sd), 
                max(log(data, base=log.base), model.pred.oos + y.lim.sd*model.sd)), 
       ylab="Log Price")
  
  lines(timestamps, model.pred, col="green", lwd=2)
  lines(timestamps, model.pred + model.sd, col="purple", lwd="2");
  lines(timestamps, model.pred - model.sd, col="purple", lwd="2"); 
  
  # future
  lines(timestamps.oos, model.pred.oos, col="green", lwd=2)
  lines(timestamps.oos, model.pred.oos + model.sd, col="purple", lwd="2")
  lines(timestamps.oos, model.pred.oos - model.sd, col="purple", lwd="2")
  
  if(plot.2sd.log){
    lines(timestamps, model.pred + 2*model.sd, col="red", lwd="2");
    lines(timestamps, model.pred - 2*model.sd, col="red", lwd="2"); 
    
    lines(timestamps.oos, model.pred.oos + 2*model.sd, col="red", lwd="2")
    lines(timestamps.oos, model.pred.oos - 2*model.sd, col="red", lwd="2")
  }
  
  
  ########################################
  # Logarithmic chart: Spread ############
  ########################################
  log.spread.predictions <- log(data, base=log.base) - predict(model.fit)
  plot(timestamps, log.spread.predictions, lty=1, type="l",
       main = paste("Log(", data.identifier, ") - Spread", sep=""),
       xlim = c(first.date, tail(timestamps.oos, 1)), 
       ylim = c(min(log.spread.predictions, -y.lim.sd*model.sd), max(log.spread.predictions, y.lim.sd*model.sd)),
       xlab="Time", ylab="Trend Deviation")
  
  nr.timestamps <- length(timestamps)
  lines(timestamps, rep(0, length(timestamps)), col="green", lwd=2)
  lines(timestamps, rep(model.sd, length(timestamps)), col="purple", lwd="2")
  lines(timestamps, rep(-model.sd, length(timestamps)), col="purple", lwd="2")
  
  # future
  nr.timestamps.oos <- length(timestamps.oos)
  lines(timestamps.oos, rep(0, nr.timestamps.oos), col="green", lwd=2)
  lines(timestamps.oos, rep(model.sd, nr.timestamps.oos), col="purple", lwd="2")
  lines(timestamps.oos, rep(-model.sd, nr.timestamps.oos), col="purple", lwd="2")
  
  if(plot.2sd.log){
    lines(timestamps, rep(2*model.sd, length(timestamps)), col="red", lwd="2")
    lines(timestamps, rep(-2*model.sd, length(timestamps)), col="red", lwd="2")
    
    lines(timestamps.oos, rep(2*model.sd, nr.timestamps.oos), col="red", lwd="2")
    lines(timestamps.oos, rep(-2*model.sd, nr.timestamps.oos), col="red", lwd="2")
  }
  
  
  ###########################################
  # Level chart #############################
  ###########################################
  fit.levels <- exp(predict(model.fit))
  y.lim.sd   <- ifelse(plot.2sd.levels, 2, 1)
  plot(timestamps, data, lty=1, type="l",
       main = plot.txt.lvl,
       xlim = c(first.date, tail(timestamps.oos, 1)), xlab="Time",
       ylim = c(0, max(data, exp(model.pred.oos + y.lim.sd*model.sd))))
       # ylim = c(0, max(exp(model.pred.oos + y.lim.sd*model.sd))), ylab="Price")
  lines(timestamps, exp(model.pred), col="green", lwd=2)
  lines(timestamps, exp(model.pred + model.sd), col="purple", lwd=2)
  lines(timestamps, exp(model.pred - model.sd), col="purple", lwd=2)
  
  lines(timestamps.oos, exp(model.pred.oos), col="green", lwd=2)
  lines(timestamps.oos, exp(model.pred.oos + model.sd), col="purple", lwd="2")
  lines(timestamps.oos, exp(model.pred.oos - model.sd), col="purple", lwd="2")
  
  if(plot.2sd.levels){
    lines(timestamps, exp(model.pred + 2*model.sd), col="red", lwd=2)
    lines(timestamps, exp(model.pred - 2*model.sd), col="red", lwd=2)
    
    lines(timestamps.oos, exp(model.pred.oos + 2*model.sd), col="red", lwd="2")
    lines(timestamps.oos, exp(model.pred.oos - 2*model.sd), col="red", lwd="2")
  }

  
  ###########################################
  # Level chart - Spread ####################
  ###########################################
  oos.down <- exp(model.pred.oos - y.lim.sd*model.sd) - exp(model.pred.oos)
  oos.up   <- exp(model.pred.oos + y.lim.sd*model.sd) - exp(model.pred.oos)
  plot(timestamps, data - exp(model.pred), lty=1, type="l",
       main = paste(data.identifier, " - Spread", sep=""),
       xlim = c(first.date, tail(timestamps.oos, 1)), xlab="Time",
       ylim = c(min(data - exp(model.pred), oos.down), max(data - exp(model.pred), oos.up)), 
       ylab="Trend Deviation")
  lines(timestamps, rep(0, length(timestamps)), col="green", lwd=2)
  lines(timestamps, exp(model.pred + model.sd) - exp(model.pred), col="purple", lwd=2)
  lines(timestamps, exp(model.pred - model.sd) - exp(model.pred), col="purple", lwd=2)
  
  lines(timestamps.oos, rep(0, length(timestamps.oos)), col="green", lwd=2)
  lines(timestamps.oos, exp(model.pred.oos + model.sd) - exp(model.pred.oos), col="purple", lwd=2)
  lines(timestamps.oos, exp(model.pred.oos - model.sd) - exp(model.pred.oos), col="purple", lwd=2)
  
  if(plot.2sd.levels){
    lines(timestamps, exp(model.pred + 2*model.sd) - exp(model.pred), col="red", lwd=2)
    lines(timestamps, exp(model.pred - 2*model.sd) - exp(model.pred), col="red", lwd=2)
    
    lines(timestamps.oos, exp(model.pred.oos + 2*model.sd) - exp(model.pred.oos), col="red", lwd=2)
    lines(timestamps.oos, exp(model.pred.oos - 2*model.sd) - exp(model.pred.oos), col="red", lwd=2)
  }
}