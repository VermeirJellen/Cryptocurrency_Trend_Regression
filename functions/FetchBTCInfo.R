FetchBTCInfo <- function(param, data.identifier, date.start = "2011-01-01"){
  
  request.str <- paste("https://api.blockchain.info/charts/", param, "?", 
                       "timespan=15years&start=", date.start, sep="")
  
  response  <- httr::GET(request.str)
  resp.code <- httr::status_code(response)
  
  if (resp.code == "200"){
    resp.content <- httr::content(response)
    resp.status <- resp.content$status
    if (resp.status == "ok"){
      
      data.idx    <- as.POSIXct(vapply(resp.content$values, 
                                       FUN="[[", FUN.VALUE=numeric(1), 1),
                                origin = "1970-01-01", tz="UTC")
      data.values <- vapply(resp.content$values, FUN="[[", FUN.VALUE=numeric(1), 2)
      data.xts    <- xts::as.xts(data.values, order.by = data.idx)
      names(data.xts) <- data.identifier
      
      return (data.xts)
    }
    else{
      stop (paste("blockchain.info returned \"",
                  resp.status, "\" response error while processing ",
                  request.str, sep=""))
    }
  }
  else{
    stop (paste("Unable to connect to ",
                request.str, " (", resp.code, ")", sep=""))
  }
}