packages <- c("httr", "XML", "zoo", "xts", "lubridate")

packages <- lapply(packages, FUN = function(x) {
  if (!require(x, character.only = TRUE)) {
    install.packages(x)
    library(x, character.only = TRUE)
  }
})

Sys.setenv(TZ='UTC')

source("functions/FetchBTCInfo.R")
source("functions/SimpleLogTrendRegression.R")
source("functions/FetchCryptocurrencyMarketCapitalizations.R")
