# #############################
library(sf)
library(ncdf4)
library(raster)

# #############################
# via RNetCDF

# library(RNetCDF)
# TabsD_14 <- open.nc(filename)
# print.nc(TabsD_14)
# 
# TabsD_14 <- read.nc(open.nc(filename))
# 
# TabsD_14$E
# TabsD_14$TabsD
# 
# att.get.nc(open.nc(filename), "time", "units")

# #############################
# via ncdf4

filename <- "data-raw/meteoswiss/TabsD_ch01r.swiss.lv95_201401010000_201412310000.nc"

TabsD_14 <- nc_open(filename)

# library(ncmeta)
# nc_inq(filename)     ## one-row summary of file
# nc_dims(filename)    ## all dimensions

E <- ncvar_get(TabsD_14, "E") # X, lon
N <- ncvar_get(TabsD_14, "N") # Y, lat
t <- ncvar_get(TabsD_14, "time")

timestamp <- lubridate::as_date(t, origin = "1900-01-01")

# store the data in a 3-dimensional array
data <- ncvar_get(TabsD_14, "TabsD") 
dim(data) 

# NAs?
fillvalue <- ncatt_get(TabsD_14, "TabsD", "_FillValue")
fillvalue

# one pixel example 
plot(data.frame(date = timestamp,
                temp = data[100, 100, ]),
     type = "l")

# #############################
# two example points to extract 
data[100, 100, ]
data[200, 200, ]

ex0 <- data.frame(rbind(data[100, 100, ],
                        data[200, 200, ]))

pt <- cbind(c(E[100], E[200]), 
            c(N[100], N[200]))

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

plot(r, main = "TabsD_14 - 1st January 2014",
     col = rev(RColorBrewer::brewer.pal(11, "RdBu")))

# extract by point
ex1 <- data.frame("X2014.12.27" = raster::extract(r, pt))

# #############################
# brick solution 

# 12 months combined 
b <- brick(filename)
# raster::crs(b) <- "EPSG:2056"

nlayers(b)

spplot(b[[1]])

spplot(stack(b[[1]], b[[182]]))

# extract by point
ex2 <- data.frame(raster::extract(b, pt))

# #############################
# terra solution

terra <- terra::rast(filename)
crs(terra) <- "epsg:2056"

# summary(data)
plot(terra[[ c(1, 182) ]], range = c(-20, 25))

time(terra)

# extract by point
ex3 <- data.frame(terra::extract(terra, pt))

# #############################
# results

# one month
ex0$X1
ex1

# 12 months
ex0
ex2
ex3
