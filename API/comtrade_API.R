# API для загрузки данных из базы UN COMTRADE
# февраль 2016
# Источник: http://comtrade.un.org/data/Doc/api/ex/r

# library('rjson')

get.Comtrade <- function(url = "http://comtrade.un.org/api/get?",
             maxrec = 50000,
             type = "C",
             freq = "A",
             px = "HS",
             ps = "now",
             r,
             p,
             rg = "all",
             cc = "TOTAL",
             fmt = "json") {
    string <- paste(url,
          "max=", maxrec, "&", # максимальное число записей в итоговой таблице
          "type=", type, "&",  # тип торговли (c = commodities)
          "freq=", freq, "&",  # частота
          "px=", px, "&",      # классификация
          "ps=", ps, "&",      # период времени
          "r=", r, "&",        # страна, подавшая отчёт об операции
          "p=", p, "&",        # страна-партнёр
          "rg=", rg, "&",      # торговый поток
          "cc=", cc, "&",      # классификационный код
          "fmt=", fmt,         # формат
          sep = "")
  
  if(fmt == "csv") {
    raw.data <- read.csv(string, header = TRUE)
    return(list(validation = NULL, data = raw.data))
  } else {
    if(fmt == "json" ) {
      raw.data <- fromJSON(file = string)
      data <- raw.data$dataset
      validation<- unlist(raw.data$validation, recursive = TRUE)
      ndata<- NULL
      if(length(data) > 0) {
        var.names <- names(data[[1]])
        data <- as.data.frame(t(sapply(data,rbind)))
        ndata <- NULL
        for(i in 1:ncol(data)){
          data[sapply(data[, i], is.null), i] <- NA
          ndata <- cbind(ndata, unlist(data[, i]))
        }
        ndata <- as.data.frame(ndata)
        colnames(ndata) <- var.names
      }
      return(list(validation = validation, data = ndata))
    }
  }
}