#Para archivos con obs asimiladas

#Estructura
#-------------------------------------------------------------
# Código de observación (ver abajo)
# Longitud (0-360)
# Latitud
# Elevación (en hPa o msnm para radar y conv en superficie)
# Observación (K, m/s, %, dbz, m/s)
# Error
# "Sub.id"
# Distancia entre la media del ensamble y la obs
# Distancia entre la media del analisis y la obs
# Time slot

# id_u_obs=2819
# id_v_obs=2820
# id_t_obs=3073
# id_q_obs=3330
# id_rh_obs=3331
# id_tv_obs=3079
#
# !surface observations codes > 9999
# id_ps_obs=14593
# id_us_obs=82819
# id_vs_obs=82820
# id_ts_obs=83073
# id_qs_obs=83330
# id_rhs_obs=83331
# id_pwv_obs=83344
# id_rain_obs=19999
# id_tclon_obs=99991
# id_tclat_obs=99992
# id_tcmip_obs=99993
# id_tcr15_obs=99994
# id_tcr25_obs=99995
#
# !radar observation codes
# id_reflectivity_obs=4001
# id_radialwind_obs  =4002
# id_pseudorh_obs    =4003
# !chem observation codes
# id_totco_obs=5001
# id_co_obs = 5002



read.obs.asim <- function(filename, keep.obs = c(14593, 82819, 82820, 83073, 83330, 83331)) { 
  to.read <- file(filename, 'rb')
  all.data <- readBin(to.read, 'numeric', size = 4, n = file.size(filename)/4, endian = "little")
  close(to.read)
  obs <- all.data[all.data != all.data[1]]
  obs <- data.table::as.data.table(matrix(obs, ncol = 10, byrow = TRUE))
  colnames(obs) <- c("obs.id", "lon", "lat", "elev", "obs", "error", "sub.id", "ens.obs", "ana.obs", "time.slot")
  
  obs <- obs[obs.id %in% keep.obs] #Filter obs in keep.obs

  return(obs)
}


read.obs <- function(filepath) {
  files <- Sys.glob(filepath)
  #Para archivos con obs cada 10 minutos
  
  date <- lubridate::ymd_hm(stringi::stri_sub(basename(files), 5, 16))
  for (i in 1:length(files)) {
    to.read <- file(files[i], 'rb')
    all.data <- readBin(to.read, 'numeric', size = 4, n = file.size(files[i])/4, endian = "little")
    close(to.read)
    
    obs <- all.data[all.data != all.data[1]]
    obs <- data.table::as.data.table(matrix(obs, ncol = 7, byrow = TRUE))
    
    colnames(obs) <- c("obs.id", "lon", "lat", "elev", "obs", "error", "sub.id")
    date_obs <- date[i]
    obs[, time := date_obs]

    if (i == 1) {
      out <- obs
    } else {
      out <- rbind(out, obs)
    }
  }
  return(out)
}