# Leer y guardar satwind
# 1. Leo dos tiempos filtrando solo las obs de satelite
# 2. Filtro para quedarme con una ventana de 1 hora centrada
# 3. Filtro espacialmente
# 4. Formateo el data.frame para que prepbufr_gen lo acepte
# 5. Escribo un csv con nombre YYYYMMDDHH.csv

library(lubridate)
library(ggplot2)
library(data.table)
library(dplyr)

ana_date <- as_datetime("20181120 18:00:00")

obs <- read.obs("../20181120_18/*0.dat", 
                     keep.obs = c(2819, 2820),
                     keep.sub.obs = c(4))
obs <- rbind(obs, read.obs("../20181120_19/*0.dat", 
                           keep.obs = c(2819, 2820),
                           keep.sub.obs = c(4)))

obs <- obs[time %between% c(ana_date - minutes(30), ana_date + minutes(30))] %>% 
  .[lon %between% c(287, 307) & lat %between% c(-43, -19)]

obs <- dcast(obs, ... ~ obs.id, value.var = "obs")

setnames(obs, c("elev", "2819", "2820"), c("pob", "uob", "vob"))

obs[, time := strftime(time, "%Y%m%d%H%M%S", tz = "UTC")]

fwrite(obs, "../2018112018.csv", row.names = FALSE, col.names = FALSE)

# Chequeo para ver si todo funciona.

obs_pb <- fread('../log.csv', 
                na.strings = "100000000000.000")
colnames(obs_pb) <- c("obs.id", "time", "station", "lon", "lat", "dhr", "sub.id", "station.elev", "p", "q", "t", "elev", "u", "v", "pwo", "cat", "press")

obs_pb[, time := ymd_h(time)]
obs_pb[, time.obs := time + as.period(as.duration(days(x=1))*(dhr/24))]

obs_pb <- obs_pb[obs.id == "SATWND"] %>% 
  .[lon %between% c(290, 310) & lat %between% c(-45, -20)]