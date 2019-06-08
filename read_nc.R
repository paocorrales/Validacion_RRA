#Read wrfout procesado con NPP

library(metR)
library(ggplot2)
library(interp)
library(patchwork)
file.nc <- 'NPP_2018-11-20_00_FC00.nc'

variables <- ReadNetCDF(file.nc, out = "vars") 

t2 <- ReadNetCDF(file.nc, vars = c("XLONG", "XLAT", "T2"), subset = list(ens = 1))
t2[, XLONG := ConvertLongitude(XLONG)]

t2.asim$fcst <- with(t2, interp(XLONG, XLAT, T2, output = 'points', 
                                xo = t2.asim$lon, yo = t2.asim$lat))[['z']]

topo <- GetTopography(360-67.5, 360-55, -24, -39, 0.25)
topo[, lon := ConvertLongitude(lon)]

p1 <- ggplot(t2.asim, aes(lon, lat)) +
  geom_contour(data = topo, aes(z = h), color = "darkgray") +
  geom_point(aes(color = obs-fcst)) +
  scale_color_divergent() +
  facet_wrap(~time.slot, ncol = 7)

p2 <- ggplot(t2.asim, aes(lon, lat)) +
  geom_contour(data = topo, aes(z = h), color = "darkgray") +
  geom_point(aes(color = obs)) +
  scale_color_continuous() +
  facet_wrap(~time.slot, ncol = 7)
  
p1/p2  

ggplot(t2, aes(XLONG, XLAT)) +
  geom_point(aes(color = T2)) 
