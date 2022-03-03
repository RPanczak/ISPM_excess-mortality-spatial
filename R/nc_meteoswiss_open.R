# #############################
library(sf)
library(raster)
library(ncdf4)
library(RNetCDF)
library(terra)

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

# creating raster from scratch
# one month example
data_slice <- data[, , 1] 

# needs 90 degree counter clockwise rotation
data_slice <- apply(t(data_slice), 2, rev)
dim(data_slice) 

r <- raster::raster(data_slice,
                    xmn = min(E), xmx = max(E), 
                    ymn = min(N), ymx = max(N), 
                    crs = st_crs(2056)$proj4string)

# alternative solution
# without using data slice
# for one day
r <- raster::raster(filename, band = 1)

plot(r, main = "TnormM9120 - January",
     col = rev(RColorBrewer::brewer.pal(11, "RdBu")))

# extract by point
ex1 <- raster::extract(r, pt, df = TRUE)
colnames(ex1)[2] <- "X2014-01-01"

# all bands with stack
r <- raster::stack(filename)

crs(r) <- st_crs(2056)$proj4string

plot(r[[ c(1, 7) ]], main = "TnormM9120 - January & July",
     col = rev(RColorBrewer::brewer.pal(11, "RdBu")))

# extract by point
ex1 <- raster::extract(r, pt, df = TRUE)

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

time(terra)

# summary(data)
plot(terra, range = c(-20, 25))
plot(terra[[ c(1, 7) ]], range = c(-20, 25))

# extract by point
ex3 <- data.frame(terra::extract(terra, pt))

# #############################
# via terra with extent from RNetCDF

read_cf16 <- function(x, crs = NULL) {
  nc <- RNetCDF::open.nc(x)
  on.exit(RNetCDF::close.nc(nc), add = TRUE)
  Conventions <- RNetCDF::att.get.nc(nc, "NC_GLOBAL", "Conventions")
  if (!Conventions == "CF-1.6") {
    message("file does not seem to be CF-1.6, may not work")
  }
  E <- RNetCDF::var.get.nc(nc, "E")
  N <- RNetCDF::var.get.nc(nc, "N")
  dxdy <- c(unique(diff(E)), unique(diff(N)))
  if (length(dxdy) > 2) message("bad E,N coords")
  ## ok let's keep going
  ex <- c(min(E) - dxdy[1L]/2, max(E) + dxdy[1L]/2, 
          min(N) - dxdy[2L]/2, max(N) + dxdy[2L]/2)
  out <- terra::rast(x)
  terra::ext(out) <- terra::ext(ex)
  ## crs: find a var called "*_coordinates"?
  # float swiss_lv95_coordinates ;
  #          swiss_lv95_coordinates:_FillValue = -1.f ;
  #          swiss_lv95_coordinates:grid_mapping_name = "Oblique Mercator (LV95 - CH1903+)" ;
  #          swiss_lv95_coordinates:longitude_of_projection_center = 7.43958333 ;
  #          swiss_lv95_coordinates:latitude_of_projection_center = 46.9524056 ;
  #          swiss_lv95_coordinates:false_easting = 2600000. ;
  #          swiss_lv95_coordinates:false_northing = 1200000. ;
  #          swiss_lv95_coordinates:inverse_flattening = 299.1528128 ;
  #          swiss_lv95_coordinates:semi_major_axis = 6377397.155 ;
  # 
  # 
  # vars <- ncmeta::nc_vars(x)
  # coordvar <- grep(".*_coordinates", vars$name, value = TRUE)[1L]
  # GIVE UP
  if (!is.null(crs)) {
    terra::crs(out) <- crs
  }
  out
}

terra2 <- read_cf16(filename)

plot(terra2[[ c(1, 7) ]], range = c(-20, 25))

# extract by point
ex4 <- data.frame(terra::extract(terra2, pt))

# #############################
# results

# one month
ex0$X1
ex1

# 12 months
ex0
ex2
ex3
ex4
