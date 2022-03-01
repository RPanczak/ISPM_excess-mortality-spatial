# #############################
library(sf)
library(ncdf4)
library(raster)

# #############################
# data 

# download.file(url = "https://www.meteoswiss.admin.ch/content/dam/meteoswiss/de/Ungebundene-Seiten/Produkte/doc/tnorm9120.zip",
#               destfile = "data-raw/tnorm9120.zip")
# unzip("data-raw/tnorm9120.zip", exdir = "data-raw")
# unlink("data-raw/tnorm9120.zip")

filename <- "data-raw/tnorm9120/TnormM9120_ch01r.swiss.lv95_000001010000_000012010000.nc"

# #############################
# via ncdf4

tnorm9120 <- nc_open(filename)
tnorm9120

# EPSG 2056 coordinate system
E <- ncvar_get(tnorm9120, "E") # X, lon
N <- ncvar_get(tnorm9120, "N") # Y, lat
t <- ncvar_get(tnorm9120, "time")

# store the data in a 3-dimensional array
data <- ncvar_get(tnorm9120, "TnormM9120")
dim(data) 

# one pixel example 
plot(data.frame(date = t,
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

# one month example
data_slice <- data[, , 1] 

# needs 90 degree counter clockwise rotation
data_slice <- apply(t(data_slice), 2, rev)
dim(data_slice) 

r <- raster::raster(data_slice,
                    xmn = min(E), xmx = max(E), 
                    ymn = min(N), ymx = max(N), 
                    crs = st_crs(2056)$proj4string)

plot(r, main = "TnormM9120 - January",
     col = rev(RColorBrewer::brewer.pal(11, "RdBu")))

# extract by point
ex1 <- data.frame("X2014.12.27" = raster::extract(r, pt))

# #############################
# brick solution 

# 12 months combined 
b <- brick(filename,
           varname = "TnormM9120", 
           crs = paste(st_crs(2056)$proj4string))

nlayers(b)

# January
spplot(b[[1]])

# Jan vs Jul
spplot(stack(b[[1]], b[[7]]))

# extract by point
ex2 <- data.frame(raster::extract(b, pt))

# #############################
# terra solution

terra <- terra::rast(filename)
crs(terra) <- "epsg:2056"

# summary(data)
plot(terra, range = c(-20, 25))
plot(terra[[ c(1, 7) ]], range = c(-20, 25))

# extract by point
ex3 <- data.frame(terra::extract(terra, pt))

# t(ex3)
# seq(from = as.Date("2014-01-01"), to = as.Date("2014-12-31"), by = "day")

# #############################
# results

# one month
ex0$X1
ex1

# 12 months
ex0
ex2
ex3
