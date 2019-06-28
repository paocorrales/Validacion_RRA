# Read obs data and write a csv file per day only with convenitional observations

library(lubridate)
source("/home/pao/RRA/read_files.R")

ini_date <- seq(20181120, 20181121, 1)
path_out <- "/home/pao/"

for (j in 1:length(ini_date)) {
  filepath <- paste0("/home/pao/obs_", ini_date[j],"*")
  obs <- read.obs.asim(filepath = filepath)
  
  write.csv2(obs, file = paste0(path_out, "conv_", ini_date[j], ".csv"))
  
}
