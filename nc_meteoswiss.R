# #############################
library(sf)
library(ncdf4)
library(raster)
library(tidyverse)

# #############################
# nc

TabsD_14 <- nc_open('data-raw/meteoswiss/TabsD_ch01r.swiss.lv95_201401010000_201412310000.nc')

E <- ncvar_get(TabsD_14, "E") # X, lon
N <- ncvar_get(TabsD_14, "N") # Y, lat
t <- ncvar_get(TabsD_14, "time")

timestamp <- lubridate::as_date(t, origin = "1900-01-01")

data <- ncvar_get(TabsD_14, "TabsD") # store the data in a 3-dimensional array
dim(data) 

# NAs?
fillvalue <- ncatt_get(TabsD_14, "TabsD", "_FillValue")
fillvalue

# one pixel example 
plot(data.frame(date = timestamp,
                temp = data[100, 100, ]),
     type = "l")

# #############################
# raster solution 

# one day example
data_slice <- data[, , 1] 

timestamp[1]

# needs 90 degree counter clockwise rotation
data_slice <- apply(t(data_slice), 2, rev)
dim(data_slice) 

# st_crs(2056)$proj4string

r <- raster::raster(data_slice,
                    xmn = min(E), xmx = max(E), 
                    ymn = min(N), ymx = max(N), 
                    crs = st_crs(2056)$proj4string)


plot(r, main = "TabsD_14",
     col = rev(RColorBrewer::brewer.pal(11, "RdBu")))

# #############################
# brick solution 

b <- brick("data-raw/meteoswiss/TabsD_ch01r.swiss.lv95_201401010000_201412310000.nc",
           crs = st_crs(2056)$proj4string)

plot(b[[1]])

spplot(stack(b[[1]], b[[7]]))

# #############################
# getting origin 
origin <- st_as_sf(tibble(E = min(E), N = min(N)), 
                   coords = c("E", "N")) %>%
  st_set_crs(2056) 

origin

library(tmap)
tmap_mode("view")
qtm(origin)
