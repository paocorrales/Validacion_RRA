#Calculo de RH según LETKF
#Ojo: Presión en pascales, humedad en g/g y temperatura en K!

rh <- function(t, q, p) { 

t0 <- 273.15
e0c <- 6.11
al <- 17.3
bl=237.3
e0i <- 6.1121
ai <- 22.587
bi <- 273.86

e <- q * p * 0.01 / (0.378 * q + 0.622)

tc <-  t - t0

es <- case_when(tc >= 0 ~ e0c * exp(al*tc/(bl + tc)),
                tc <= -15 ~ e0i * exp(ai*tc/(bi + tc)),
                TRUE ~ e0c * exp(al*tc/(bl + tc)) * (15.0+tc)/15.0 + e0i * exp(ai*tc/(bi + tc)) * (-tc) / 15.0)

return(e/es) 
} 





