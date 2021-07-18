library(tidyverse)
library(data.table)
library(metR)
library(lubridate)

read_radiosonde_relampago <- function(file){
  # Leo línea por línea
  lines <- readLines(file)
  
  # Indices donde comienza cada sondeo
  idx <- which(grepl("Data Type:", lines))
  idx <- c(idx, length(lines)+1)
  soundings <- list()
  for (i in seq_len(length(idx)-1)) { 
    
    out <- read.table(text = lines[(idx[i] + 15):(idx[i + 1] - 1)]) %>% 
      as.data.table()
    
    names <- strsplit(lines[idx[i] + 12], " ")[[1]]
    names <- names[names != ""]
    colnames(out) <- names
    
    launch <- lubridate::ymd_hms(strsplit(lines[idx[i] + 4], "    ")[[1]][2])
    nominal_launch <- lubridate::ymd_hms(strsplit(lines[idx[i] + 11], "):")[[1]][2])
    site <- strsplit(lines[idx[i] + 2], "         ")[[1]][2]  
    
    out <- out[, ":="(Site = site,
                      Nominal_launch_time = nominal_launch,
                      Launch_time = launch)] %>% 
      .[, Time := seconds(Time) + Launch_time] %>% 
      .[, lapply(.SD, function(x) replace(x, as.character(x) %in% c("999", "9999", "999.0"), NA))] %>% 
      .[]
    if (length(colnames(out) == 24)) {
      colnames(out) <- c("time", "p", "t", "td", "rh", "u", "v", "spd", "dir", "w", "lon", "lat", "ele", 
                         "azi", "alt", "qp", "qt", "qrh", "qu", "qv", "qdZ", "site", "nominal_launch_time", 
                         "launch_time")
    } else {
      colnames(out) <- c("time", "p", "t", "td", "rh", "u", "v", "spd", "dir", "w", "lon", "lat", "ele", 
                         "azi", "alt", "qp", "qt", "qrh", "qu", "qv", "qdZ", "site", "nominal_launch_time", 
                         "launch_time", "mixr", "ptmp")
    }
    if (site == "Sao Borja, Brazil") {
      out <- out[, ":="(lon = data.table::nafill(lon, "locf"),
                        lat = data.table::nafill(lat, "locf"))]
    }
    
    soundings[[i]] <- out
  }
  soundings <- rbindlist(soundings, fill=TRUE)
}

DewPoint2 <- function (p, ws, td, epsilon = 0.622) 
{
  if (hasArg(p) & hasArg(ws) & !hasArg(td)) {
    if (is.na(ws)) {
      return(ws)
    }
    .dew <- function(td) {
      es <- ClausiusClapeyron(td)
      ws - epsilon * es/(p - es)
    }
    t <- seq(10, 273 + 100, length.out = 100)
    samples <- .dew(t)
    i <- which(samples < 0)[1]
    tm <- t[i]
    
    td <- try(uniroot(.dew, c(10, tm))$root, silent = TRUE)
    if (inherits(td, "try-error"))  {
      browser()    
      
      return(NA_real_)
    }
    return(td)
  }
  else if (hasArg(p) & !hasArg(ws) & hasArg(td)) {
    es <- ClausiusClapeyron(td)
    return(epsilon * es/(p - es))
  }
  else if (!hasArg(p) & hasArg(ws) & hasArg(td)) {
    es <- ClausiusClapeyron(td)
    return(es * (1 + epsilon/ws))
  }
  else if (hasArg(p) & hasArg(ws) & hasArg(td)) {
    stop("Too many state variables.")
  }
  else {
    stop("Too few stat variables.")
  }
}


td <- function(lev, q) {
  # browser()
  lev <- lev*100
  q <- q/1000
  
  td <- if_else(is.na(q) | q < 1e-10, NA_real_, map2_dbl(lev, q, ~ DewPoint2(.x, .y)))
}


# leo sondeos -------------------------------------------------------------


files <- list.files(path = "/home/paola.corrales/datosmunin3/DATA/RELAMPAGO/sondeos_raw",
                    pattern = "cls", full.names = TRUE)

sondeos <- purrr::map(files, ~ read_radiosonde_relampago(.x)) %>%
  rbindlist() %>% 
  .[site == "M1: Cordoba, Argentina"]

print("Listo los sondeos, no podrían ser más!")

# leo e interpolo modelo --------------------------------------------------


# path_npp <- "/datosalertar1/paula.maldonado/RRA_VERIF/data/raw/gfs_raw"
path_npp <- "/home/paola.corrales/datosmunin3/RRA_Validacion/raw/RRA_Fcst/"
path_out <- "/home/paola.corrales/datosmunin3/RRA_Validacion/interp_sondeos_fcst/"

# first_date <- ymd_hms("20181109000000")
first_date <- ymd_hms("20181109210000")

# dates <- seq(first_date, by = "6 hour",
#              length.out = 163) #163
dates <- seq(first_date, by = "24 hour",
             length.out = 41) #163

for (d in seq_along(dates)) {
  
  ini_date <- dates[d]
  
  print(ini_date)
  
  lead_time <- c(0:36)
  
  dir <- paste0(path_npp, "/", format(ini_date, "%Y%m%d_%H"), "F")
  
  if (!dir.exists(dir)) {
    print("no existe")
    next
  }

  file_wrf <- paste0(path_npp, "/", 
                     format(ini_date, "%Y%m%d_%H"), "F/NPP_",
                     format(ini_date, "%Y"), "-",
                     format(ini_date, "%m"), "-",
                     format(ini_date, "%d"), "_",
                     format(ini_date, "%H"), "_FC",
                     formatC(lead_time, width = 2, flag = "0"),
                     ".nc")
  
  out <- purrr::map_df(file_wrf, function(f) {  
    
    if (!file.exists(f)) {
      return(NULL)
    }
    # print(basename(f))
    meta <- unglue::unglue(f, "/home/paola.corrales/datosmunin3/RRA_Validacion/raw/RRA_Fcst/{fecha_ini}F/NPP_{fecha_ini2}_FC{fcst_hour}.nc")
    
    fcst <- ReadNetCDF(f,
                       vars = c(gp = "yacanto/Z", t = "yacanto/T", u = "yacanto/U", v = "yacanto/V", q = "yacanto/Q")) %>%
      # na.omit() %>%
      .[, ":="(td = td(`yacanto/lev`, q) - 273.15,
               t = t - 273.15,
               fecha_ini = ymd_h(meta[[1]][["fecha_ini"]]),
               fecha = ymd_h(meta[[1]][["fecha_ini"]]) + hours(meta[[1]][["fcst_hour"]]))] %>%
      setnames(c("yacanto/ens", "yacanto/lev"), c("ens", "lev"))
    
    levs <- fcst[ens == 1, lev]
    
    fcst_time <- ymd_h(meta[[1]][["fecha_ini"]]) + hours(meta[[1]][["fcst_hour"]])
    intervalo <- interval(fcst_time - minutes(30), fcst_time + minutes(30))
    
    subset <- sondeos[launch_time %within% intervalo] 
    
    # message(paste0(nrow(subset), " observaciones de sondeos en este tiempo"))
    
    if (nrow(subset) > 1) {
      subset <- subset %>% 
        melt(measure.vars = c("t", "td", "u", "v"), value.name = "obs_value") %>% 
        .[, c("p", "site", "launch_time", "variable", "obs_value")] %>% 
        .[, .(obs_value = mean(obs_value, na.rm = TRUE)), by = .(site, launch_time, variable, p)] %>% 
        
        .[, .(obs_value = approx(p, obs_value, xout = levs)$y,
              lev = levs), 
          by = .(variable)] 
      
      fcst <- fcst %>% 
        melt(measure.vars = c("t", "td", "u", "v"), value.name = "fcst_value") %>% 
        .[, c("ens", "lev", "fecha_ini", "fecha", "variable", "fcst_value")] %>% 
        subset[., on = c("variable", "lev")]
      
    } 
    
  })
  write_csv(out, paste0(path_out, "sondeo_", format(ini_date, "%Y%m%d_%H"), "F.csv"))
  print("Done!")
}
