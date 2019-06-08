library(metR)
library(ggplot2)
library(interp)
library(patchwork)
library(data.table)

obs[, sqrt(sum(ana.obs^2)/.N), by = .(obs.id, time.slot)] %>% 
  ggplot(aes(time.slot, V1)) + 
  geom_col() + 
  
  facet_wrap(~obs.id, scales = "free")

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
  scale_color_viridis_c() +
  facet_wrap(~time.slot, ncol = 7)

p1/p2  

uv[sub.id == 1] %>% 
  .[obs.id == 2819] %>%
  ggplot(aes(lon, elev)) +
  # geom_contour(data = topo, aes(z = h), color = "darkgray") +
  geom_point(aes(color = obs)) +
  scale_y_level()

             