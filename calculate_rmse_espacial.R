library(data.table)
library(lubridate)
library(dplyr)
library(foreach)
library(doParallel)

myCluster <- makeCluster(4)
registerDoParallel(myCluster)

path <- "/home/paola.corrales/datosmunin/RRA_Fcst/interpolados/fcst_83331_2018**"
files <- Sys.glob(path)

out <- foreach(f = 1:length(files),
               .packages = c("data.table", "lubridate", "dplyr"),
               .export = c("files"),
               .combine = "rbind") %dopar% {
                 
                 cat("Leyendo el pronóstico ", basename(files[f]), "\n")
                 fcst <- fread(files[f])
                 
                 fecha_ini <- ymd_h(stringr::str_extract(files[f], "\\d{8}_\\d{2}"))
                 
                 temp <- fcst[, `:=`(obs.fcst = obs - fcst,
                                     fecha.ini = fecha_ini,
                                     verif = as.numeric(as.duration(as_datetime(time.obs) - fecha_ini), "hour"))] %>%
		   .[, obs.fcst := mean(obs.fcst, na.rm = TRUE), by = .(verif, fecha.ini, lon, lat)] %>%
                   .[, .(rmse = sqrt(mean(obs.fcst^2, na.rm = TRUE)), 
                         bias = mean(obs.fcst, na.rm = TRUE)), by = .(verif, fecha.ini, lon, lat)]
               }

fwrite(out, "/home/paola.corrales/datosmunin/RRA_Fcst/estadisticos/espacial_rmse_83331.csv")
