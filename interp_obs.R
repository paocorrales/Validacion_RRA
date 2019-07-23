# Script para interpolar el pronóstico a las observaciones
# Hay pronósticos cada 3 horas a 36 horas. El plan es generar un archivo .csv 
# para cada tipo de observación y para cada inicialización.


filepath_nc <- "../obs_RRA/20181120_00F/*.nc"
var <- 83073
var2 <- "T2"
fecha_ini <- as_datetime("2018-11-20T00:00:00Z")
fecha_fin <- fecha_ini + hours(36)

# Leo el .csv con las observaciones y filtro el intervalo que me interesa.
obs <- fread("../obs_83073.csv")

obs <- fread(paste0("obs_", var, ".csv"))
obs[, time := as_datetime(time)]
obs[, time.obs := as_datetime(time.obs)]
obs <- obs[time.obs %between% c(fecha_ini, fecha_fin)]

# Leo los .nc y me quedo solo con la parte que necesito. 

files <- Sys.glob(filepath_nc)

for (f in 1:length(files)) { 

  fcst <- ReadNetCDF(files[f], vars = c("XLONG", "XLAT", var2))
  
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

  if (f == 1) {
    out <- temp
  } else {
    out <- rbind(out, temp)
  }
}

fwrite(out, paste0("../fcst_", var, "_", format(fecha_ini, "%Y%m%d_%H"), ".csv"))


