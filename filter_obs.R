# Script para extraer observaciones convencionales de los .dat asimilados

library(data.table)
source('read_files.R')

# Quiero un archivo para cada tipo de observacion 
var <- "82819"
path_in <- "/home/paola.corrales/datosmunin/RRA_Obs/asimiladas/obs_2018*_*_asimiladas.dat"
path_out <- paste0("/home/paola.corrales/datosmunin/RRA_Obs/filtradas/obs_", var, ".csv")

obs <- read.obs.asim(path_in, keep.obs = c(var), keep.time.slot = c(7))
fwrite(obs, path_out)
