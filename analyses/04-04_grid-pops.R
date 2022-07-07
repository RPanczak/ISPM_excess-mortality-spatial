# ###############################
# Extrapolating pops
# INLA solution

set.seed(12345)

library(readr)
library(dplyr)
library(tidyr)
library(tibble)

library(INLA)

# ###############################
# pop by grid
st_grid_pop_exp <- read_rds("data/blob/st_grid_pop_exp.Rds")

# sample dataset for testing
st_grid_pop_exp <- st_grid_pop_exp %>%
  mutate(ID = factor(ID)) %>%
  filter(ID %in% sample(levels(ID), 100)) %>% 
  mutate(ID = forcats::fct_drop(ID))

# length(unique(st_grid_pop_exp$ID))

# ###############################
# setup

hyper.iid <- list(theta = list(prior = "pc.prec", param = c(1, 0.01)))

control.family <- inla.set.control.family.default()
threads <- parallel::detectCores()

# family = "Poisson"
family = "zeroinflatedpoisson0"
# family = "zeroinflatedpoisson1"
# family = "zeroinflatednbinomial0"
# family = "zeroinflatednbinomial1"

# ###############################
# models

# Adjusted 1

f2 <- pop ~ 
  sex + age +
  f(id_year, model = "iid", hyper = hyper.iid, constr = TRUE) +
  f(ID, model = "iid", constr = TRUE, hyper = hyper.iid)

m2_zip0 <- inla(f2,
                data = st_grid_pop_exp,
                family = family,
                verbose = TRUE,
                control.family = control.family,
                control.compute = list(
                  config = TRUE,
                  # return.marginals.predictor = TRUE,
                  cpo = TRUE,
                  dic = TRUE, waic = TRUE
                ),
                control.mode = list(restart = TRUE),
                num.threads = threads,
                control.predictor = list(compute = TRUE, link = 1),
                control.inla = list(
                  strategy = "simplified.laplace", # default
                  # strategy = "adaptive",
                  # strategy = "gaussian",
                  # strategy = "laplace", #npoints = 21,
                  int.strategy = "ccd" # default
                  # int.strategy = "grid", diff.logdens = 4
                )
)

summary(m2_zip0)

# Adjusted 2

f3 <- pop ~ 
  sex +
  f(id_age, model = "iid", hyper = hyper.iid, constr = TRUE) +
  f(id_year, model = "iid", hyper = hyper.iid, constr = TRUE) +
  f(ID, model = "iid", constr = TRUE, hyper = hyper.iid)

m3_zip0 <- inla(f3,
                data = st_grid_pop_exp,
                family = family,
                verbose = TRUE,
                control.family = control.family,
                control.compute = list(
                  config = TRUE,
                  # return.marginals.predictor = TRUE,
                  cpo = TRUE,
                  dic = TRUE, waic = TRUE
                ),
                control.mode = list(restart = TRUE),
                num.threads = threads,
                control.predictor = list(compute = TRUE, link = 1),
                control.inla = list(
                  strategy = "simplified.laplace", # default
                  # strategy = "adaptive",
                  # strategy = "gaussian",
                  # strategy = "laplace", #npoints = 21,
                  int.strategy = "ccd" # default
                  # int.strategy = "grid", diff.logdens = 4
                )
)

summary(m3_zip0)

write_rds(m1_zip0, "data/blob/m1_zip0.Rds")
write_rds(m2_zip0, "data/blob/m2_zip0.Rds")
write_rds(m3_zip0, "data/blob/m3_zip0.Rds")