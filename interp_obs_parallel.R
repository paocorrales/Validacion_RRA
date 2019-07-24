# Script para interpolar el pronóstico a las observaciones
# Hay pronósticos cada 3 horas a 36 horas. El plan es generar un archivo .csv 
# para cada tipo de observación y para cada inicialización.

# Recibe argumentos:
# args = (filepath_nc, filepath_obs, var_rra, var_nc, fecha_ini)

args = commandArgs(trailingOnly=TRUE)

if (length(args)==0) {
  stop("Argumentos: filepath_nc, filepath_obs, var_rra, var_nc, fecha_ini (20181120_00)", call.=FALSE)
}

#Librerías
library(lubridate)
library(data.table)
library(metR)
library(dplyr)
library(interp)
library(foreach)
library(doParallel)

myCluster <- makeCluster(4)
registerDoParallel(myCluster)

# for (i in length(args)) {
#   print(length(args))
#   print(args[i])
#   print(class(args[i]))
# }


filepath_nc <- paste0(args[1], "/*.nc")
filepath_obs <- args[2]
var_rra <- args[3]
var_nc <- args[4]
fecha_ini <- ymd_h(args[5])
fecha_fin <- fecha_ini + hours(36)

# Leo el .csv con las observaciones y filtro el intervalo que me interesa.

obs <- fread(filepath_obs)
obs[, time := as_datetime(time)]
obs[, time.obs := as_datetime(time.obs)]
obs <- obs[time.obs %between% c(fecha_ini, fecha_fin)]

# Leo los .nc y me quedo solo con la parte que necesito. 
print(filepath_nc)
files <- as.list(Sys.glob(filepath_nc))
print(files)

out <- foreach(f = 1:length(files), 
               .packages = c("data.table", "interp", "metR", "lubridate")) %dopar% {

  fcst <- ReadNetCDF(files[f], vars = c("XLONG", "XLAT", var_nc))
  
  time_verif <- fecha_ini + hours(f - 1)
  print(time_verif)
  
  obs_subset <- subset(obs, time.obs == time_verif)
  
  # Interpolo
  temp <- fcst[, c(interp(XLONG, XLAT, T2, output = "points", 
                          xo = ConvertLongitude(obs_subset$lon), yo = obs_subset$lat),
                   list(time.slot = obs_subset$time.slot)),
               by = ens] %>% 
    .[, time.obs := time_verif] %>% 
    setnames(c("x", "y", "z"), c("lon", "lat", "fcst"))

  temp[, lon := ConvertLongitude(lon)]
  temp <- merge(temp, obs_subset, by = c("lon", "lat", "time.obs", "time.slot"), allow.cartesian = TRUE)

  # if (f == 1) {
  #   out <- temp
  # } else {
  #   out <- rbind(out, temp)
  # }
}

fwrite(out, paste0("../fcst_", var_rra, "_", format(fecha_ini, "%Y%m%d_%H"), ".csv"))


stopCluster(myCluster)
