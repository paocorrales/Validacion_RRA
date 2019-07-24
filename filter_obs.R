# Script para extraer observaciones convencionales de los .dat asimilados

library(data.table)
source('read_files.R')

# Quiero un archivo para cada tipo de observacion 
var <- NULL
path_in <- "/home/paola.corrales/datosmunin/RRA_Obs/asimiladas/obs_20181120_*_asimiladas.dat"
path_out <- paste0("/home/paola.corrales/datosmunin/RRA_Obs/filtradas/obs_", var, ".csv")

obs <- read.obs.asim(path_in, keep.obs = c(83073), keep.time.slot = c(7))
fwrite(obs, path_out)
