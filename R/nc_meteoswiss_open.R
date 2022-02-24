# #############################
library(sf)
library(ncdf4)
library(raster)
library(tidyverse)

# #############################
# data 

download.file(url = "https://www.meteoswiss.admin.ch/content/dam/meteoswiss/de/Ungebundene-Seiten/Produkte/doc/tnorm9120.zip",
              destfile = "data-raw/tnorm9120.zip")
unzip("data-raw/tnorm9120.zip", exdir = "data-raw")
unlink("data-raw/tnorm9120.zip")

# #############################
# nc

tnorm9120 <- nc_open("data-raw/tnorm9120/TnormM9120_ch01r.swiss.lv95_000001010000_000012010000.nc")
tnorm9120

E <- ncvar_get(tnorm9120, "E") # X, lon
N <- ncvar_get(tnorm9120, "N") # Y, lat
t <- ncvar_get(tnorm9120, "time")

data <- ncvar_get(tnorm9120, "TnormM9120") # store the data in a 3-dimensional array
dim(data) 

# NAs?
fillvalue <- ncatt_get(tnorm9120, "TnormM9120", "_FillValue")
fillvalue

# one pixel example 
plot(data.frame(date = t,
                temp = data[100, 100, ]),
     type = "l")

# #############################
# raster solution 

# one month example
data_slice <- data[, , 1] 

# needs 90 degree counter clockwise rotation
data_slice <- apply(t(data_slice), 2, rev)
dim(data_slice) 

# st_crs(2056)$proj4string

r <- raster::raster(data_slice,
                    xmn = min(E), xmx = max(E), 
                    ymn = min(N), ymx = max(N), 
                    crs = st_crs(2056)$proj4string)


plot(r, main = "TnormM9120 - January",
     col = rev(RColorBrewer::brewer.pal(11, "RdBu")))

# #############################
# brick solution 

b <- brick("data-raw/tnorm9120/TnormM9120_ch01r.swiss.lv95_000001010000_000012010000.nc",
           crs = st_crs(2056)$proj4string)

# Jamuary
plot(b[[1]])

# Jan vs Jul
spplot(stack(b[[1]], b[[7]]))

