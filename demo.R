#setwd("project_root_dir")
source("config/Config.R")

Sys.setenv(tz="UTC")
btc.price <- FetchBTCInfo(param           = "market-price",   
                          data.identifier = "btc.close", 
                          date.start      = "2011-01-01")

par(mfrow=c(2, 2))
SimpleLogTrendRegression(data = btc.price, 
                         data.identifier = "BTC-price",
                         regression.type = "exponential",
                         nr.future=120, plot.2sd.log = TRUE, plot.2sd.levels = FALSE)

SimpleLogTrendRegression(data = btc.price, 
                         data.identifier = "BTC-price",
                         regression.type = "loess",
                         nr.future=120, plot.2sd.log = TRUE, plot.2sd.levels = TRUE)

SimpleLogTrendRegression(data            = btc.price,
                         data.identifier = "BTC-price",
                         regression.type = "logarithmic",
                         nr.future=120, plot.2sd.log = TRUE, plot.2sd.levels = TRUE)