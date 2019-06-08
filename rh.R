#Calculo de RH según LETKF

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

if (tc >= 0.0) { 
  es <- e0c * exp(al*tc/(bl + tc))
} else if (tc <= -15.0) { 
  es <- e0i * exp(ai*tc/(bi + tc))
} else { 
  es <- e0c * exp(al*tc/(bl + tc)) * (15.0+tc)/15.0 + 
    e0i * exp(ai*tc/(bi + tc)) * (-tc) / 15.0
}

return(e/es) 

} 





