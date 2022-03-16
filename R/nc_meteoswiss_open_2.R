# #############################
library(sf)
library(raster)
library(ncdf4)
library(RNetCDF)
library(terra)
library(stars)

# #############################
# data 

# library(curl)
filename <- "data-raw/meteoswiss/TminM_ch01r.swisscors_201903010000_201903010000.nc"
# curl_fetch_disk("ftp://ftp.cscs.ch/out/stockli/swisscors/TminM_ch01r.swisscors_201903010000_201903010000.nc",
#                 filename)

# #############################
# via ncdf4

TminM <- nc_open(filename)
TminM

# EPSG 21781 coordinate system
E <- ncvar_get(TminM, "chx") # X, lon
N <- ncvar_get(TminM, "chy") # Y, lat
t <- ncvar_get(TminM, "time")

# store the data in a 3-dimensional array
data <- ncvar_get(TminM, "TminM")
dim(data) 

# #############################
# two example points to extract 
data[100, 100]
data[200, 200]

ex0 <- data.frame(rbind(data[100, 100],
                        data[200, 200]))

pt <- cbind(c(E[100], E[200]), 
            c(N[100], N[200]))

# #############################
# raster solution 

# creating raster from scratch
# needs 90 degree counter clockwise rotation
data_slice <- apply(t(data), 2, rev)
dim(data_slice) 

r <- raster::raster(data_slice,
                    xmn = min(E), xmx = max(E), 
                    ymn = min(N), ymx = max(N), 
                    crs = st_crs(21781)$proj4string)

plot(r, main = "TminM",
     col = rev(RColorBrewer::brewer.pal(11, "RdBu")))

# alternative solution
# without using data slice
# for one day
r <- raster::raster(filename, band = 1)

plot(r, main = "TminM",
     col = rev(RColorBrewer::brewer.pal(11, "RdBu")))

# extract by point
ex1 <- raster::extract(r, pt, df = TRUE)
colnames(ex1)[2] <- "X2019-03-01"

# all bands with stack
r <- raster::stack(filename)

crs(r) <- st_crs(21781)$proj4string

plot(r, main = "TminM - 2019-03-01",
     col = rev(RColorBrewer::brewer.pal(11, "RdBu")))

# extract by point
ex1 <- raster::extract(r, pt, df = TRUE)

# #############################
# brick solution 

b <- brick(filename,
           varname = "TminM", 
           crs = paste(st_crs(21781)$proj4string))

nlayers(b)

# January
spplot(b[[1]])

# extract by point
ex2 <- data.frame(raster::extract(b, pt))

# #############################
# terra solution

terra <- terra::rast(filename)
terra::ext(terra)

terra::crs(terra)
terra::crs(terra) <- "epsg:21781"

time(terra)

# summary(data)
plot(terra)

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
  E <- RNetCDF::var.get.nc(nc, "chx")
  N <- RNetCDF::var.get.nc(nc, "chy")
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
terra2 <- read_cf16(filename, "epsg:21781")

plot(terra2)

# extract by point
ex4 <- data.frame(terra::extract(terra2, pt))

# #############################
# stars solution
stars <- stars::read_stars(filename)
stars <- stars::read_ncdf(filename, var = "TminM")

st_crs(stars) <- st_crs(21781)

# extract by point
# ex5 <- stars::st_extract(stars, pt)

# #############################
# results

# 12 months
ex0
ex1
ex2
ex3
ex4
# ex5

# unlink("data-raw/meteoswiss/TminM_ch01r.swisscors_201903010000_201903010000.nc")

