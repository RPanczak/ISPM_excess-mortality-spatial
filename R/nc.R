library(sf)
library(ncdf4)
library(raster)
library(tidyverse)

era5_monthly <- nc_open('data-raw/ERA5/era5_monthly.nc')

lon <- ncvar_get(era5_monthly, "longitude")
lat <- ncvar_get(era5_monthly, "latitude", verbose = F)
t <- ncvar_get(era5_monthly, "time")

timestamp <- lubridate::as_datetime(c(t*60*60), origin = "1900-01-01")

data <- ncvar_get(era5_monthly, "t2m") # store the data in a 3-dimensional array
dim(data) 

# NAs?
fillvalue <- ncatt_get(era5_monthly, "t2m", "_FillValue")
fillvalue

# one pixel example 
plot(data.frame(date = timestamp,
                ta = data[1, 1, ] - 273.15),
     type = "l")

# one month example
data_slice <- data[, , 1] 

timestamp[1]

r <- raster::raster(data_slice, 
                    xmn = min(lon), xmx = max(lon), ymn = min(lat), ymx = max(lat), 
                    crs = sp::CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs+ towgs84=0,0,0"))

values(r) <- values(r) - 273.15

plot(r, main = "ERA-5 (2m Temperature)")
maps::map("world", add = TRUE)







# create all the combinations of lon-lat
lonlat <- expand.grid(lon = lon, lat = lat)

coord <- st_as_sf(lonlat, coords = c("lon","lat")) %>%
  st_set_crs(4326)

plot(st_geometry(coord))
