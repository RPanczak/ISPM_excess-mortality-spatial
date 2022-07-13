# Redistributing municipality level deaths for 2020-2021 into grid level

# Multinormal distribution with weights corresponding to deaths 2014-2019
# We also insure that the number of deaths cannot be higher than population in the grid and stratum

library(readr)
library(dplyr)
library(tidyr)
library(tibble)

# function 
source("R/geom_002_deaths_to_grid.R")
source("R/geom_003_weights_from_historical_deaths.R")

# pop by grid
lu_grid_gem <- read_rds("data/blob/lu_grid_gem.Rds")

# historical deaths
# TODO: replace by deaths by ID AND ID2 instead of deaths by ID only
historical_deaths <- read_rds("data/blob/st_grid_deaths_2014_2019.Rds") 

# create weights from deaths by grid 2015-2019
weights <- geom_003_weights_from_historical_deaths(
    deaths_data=historical_deaths,
    lookup=lu_grid_gem)

# monthly deaths by municipality 2020+
st_gem_deaths_2020_2021 <- read_rds("data/BfS-closed/monthly_deaths/w_deaths_2015_2021_exp.Rds") %>%
  select(GMDNR, GMDNAME, year, month, age, sex, deaths) %>%
  distinct() %>%
  filter(year >= 2020)

# job
st_grid_deaths_2020_2021 <- geom_002_deaths_to_grid(
  deaths_data = st_gem_deaths_2020_2021,
  pop_data = lu_grid_gem,
  weight_data = weights,
  n_iter = 50 # choose number of replications
) 

write_rds(st_grid_deaths_2020_2021, "data/blob/st_grid_deaths_2020_2021.Rds")
