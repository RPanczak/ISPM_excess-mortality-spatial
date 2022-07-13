# Redistributing canton level expected deaths for 2020-2021 into grid level

# Multinormal distribution with weights corresponding to deaths 2014-2019
# We also insure that the number of deaths cannot be higher than population in the grid and stratum

library(readr)
library(dplyr)
library(tidyr)
library(tibble)

# function 
source("R/geom_004_expected_to_grid.R")
source("R/geom_005_weights_from_historical_deaths_canton.R")

# pop by grid
lu_grid_gem <- read_rds("data/blob/lu_grid_gem.Rds")

# historical deaths
historical_deaths <- read_rds("data/blob/st_grid_deaths_2014_2019.Rds") 

# create weights from deaths by grid 2015-2019
weights <- geom_005_weights_from_historical_deaths_canton(
  deaths_data=historical_deaths,
  lookup=lu_grid_gem)

# expected
expected_canton <- read_rds("data/blob/pois.samples.temp.bma.finmodel")

# job
st_grid_deaths_2020_2021 <- geom_004_expected_to_grid(
  expected_data = expected_canton,
  pop_data = lu_grid_gem,
  weight_data = weights,
  n_iter = 50 # choose number of replications
) 

write_rds(st_grid_deaths_2020_2021, "data/blob/st_grid_deaths_2020_2021.Rds")