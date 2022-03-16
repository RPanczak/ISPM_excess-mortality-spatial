# #############################
library(sf)
library(raster)
library(ncdf4)

# #############################
# via ncdf4

filename <- "data-raw/meteoswiss/TabsM_ch01r.swiss.lv95_201401010000_201412010000.nc"
# filename <- "data-raw/meteoswiss/TabsD_ch01r.swiss.lv95_201401010000_201412310000.nc"

TabsM_14 <- nc_open(filename)

# library(ncmeta)
# ncmeta::nc_inq(filename)     ## one-row summary of file
# ncmeta::nc_dims(filename)    ## all dimensions

E <- ncvar_get(TabsM_14, "E") # X, lon
N <- ncvar_get(TabsM_14, "N") # Y, lat
t <- ncvar_get(TabsM_14, "time")

# timestamp <- lubridate::as_date(month(t), origin = "1900-01-01")

# store the data in a 3-dimensional array
data <- ncvar_get(TabsM_14, "TabsM") 
dim(data) 

# NAs?
fillvalue <- ncatt_get(TabsM_14, "TabsM", "_FillValue")
fillvalue

# one pixel example 
E[100]
N[100]

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

# alternative solution
# without using data slice
# for one day
r <- raster::raster(filename, band = 1)
raster::crs(r) <- st_crs(2056)$proj4string

plot(r, main = "TabsM_14 - 1st January 2014",
     col = rev(RColorBrewer::brewer.pal(11, "RdBu")))

# extract by point
ex1 <- raster::extract(r, pt, df = TRUE)
colnames(ex1)[2] <- "X2014-01-01"

# all bands with stack
r <- raster::stack(filename)
raster::crs(r) <- st_crs(2056)$proj4string

nlayers(r)

plot(r[[ c(1, 7) ]], main = "TabsM_14 - January & July",
     zlim = c(-20, 25), 
     col = rev(RColorBrewer::brewer.pal(11, "RdBu")))

# extract by point
ex1 <- raster::extract(r, pt, df = TRUE)

# #############################
# brick solution 

# 12 months combined 
b <- raster::brick(filename)
raster::crs(b) <- st_crs(2056)$proj4string

nlayers(b)

plot(b[[ c(1, 7) ]], main = "TabsM_14 - January & July",
     zlim = c(-20, 25), 
     col = rev(RColorBrewer::brewer.pal(11, "RdBu")))

# extract by point
ex2 <- data.frame(raster::extract(b, pt))

# #############################
# terra solution

library(terra)

terra <- terra::rast(filename)
crs(terra) <- "epsg:2056"

time(terra)

# summary(data)
plot(terra[[ c(1, 182) ]], range = c(-20, 25),
     col = rev(RColorBrewer::brewer.pal(11, "RdBu")))

# extract by point
ex3 <- data.frame(terra::extract(terra, pt))

# t(ex3)
# seq(from = as.Date("2014-01-01"), to = as.Date("2014-12-31"), by = "day")

# #############################
# via terra with extent from RNetCDF

library(RNetCDF)

# library(RNetCDF)
# TabsM_14 <- open.nc(filename)
# print.nc(TabsM_14)
# 
# TabsM_14 <- read.nc(open.nc(filename))
# 
# TabsM_14$E
# TabsM_14$TabsD
# 
# att.get.nc(open.nc(filename), "time", "units")

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

plot(terra2[[ c(1, 7) ]], range = c(-20, 25),
     col = rev(RColorBrewer::brewer.pal(11, "RdBu")))

# extract by point
ex4 <- data.frame(terra::extract(terra2, pt))

# #############################
# stars solution

library(stars)

stars <- stars::read_stars(filename)
stars <- stars::read_ncdf(filename, var = "TabsM")

st_crs(stars) <- st_crs(2056)

plot(stars, max_times = 1)

# extract by point
# ex5 <- stars::st_extract(stars, pt)


# #############################
# results for 12 months
# achtung - some have ID column, some not
ex0
ex1
ex2
ex3
ex4
# ex5