# Redistributing municipality level deaths for 2020-2021 into grid

library(readr)
library(dplyr)
library(tidyr)
library(tibble)

# pop bt grid
lu_grid_gem <- read_rds("data/blob/lu_grid_gem.Rds")

# monthly data by municipality
st_gem_deaths_2020_2021 <-
  read_rds("data/BfS-closed/monthly_deaths/w_deaths_2015_2021_pop.Rds") %>%
  select(GMDNR, GMDNAME, year, month, age, sex, deaths) %>%
  distinct() %>%
  filter(year >= 2020)

# function 
source("R/geom_002_deaths_to_grid.R")

# job
st_grid_deaths_2020_2021 <- geom_002_deaths_to_grid(
  deaths_data = st_gem_deaths_2020_2021,
  pop_data = lu_grid_gem,
  n_iter = 50 # choose number of replications
) 

write_rds(st_grid_deaths_2020_2021, "data/blob/st_grid_deaths_2020_2021.Rds")