# ###############################
# Extrapolating pops
# INLA solution

library(readr)
library(dplyr)
library(tidyr)
library(tibble)

# ###############################
# pop by grid
st_grid_pop_pred <- read_rds("data/blob/st_grid_pop_exp.Rds")

# ###############################
# INLA

library(INLA)

hyper.iid <- list(theta = list(prior = "pc.prec", param = c(1, 0.01)))
control.family <- inla.set.control.family.default()
threads <- parallel::detectCores()

# Stratified

data_stratified <- st_grid_pop_pred %>%
  filter(age == "<40", sex == "Female")

formula <- pop ~ 
  year +
  # f(id_year, model = "iid", hyper = hyper.iid, constr = TRUE) +
  # temp solution to save time
  f(ID, model = "iid", constr = TRUE, hyper = hyper.iid)

results <- inla(formula,
                data = data_stratified,
                # family = "Poisson",
                family = "zeroinflatedpoisson0",
                # family = "zeroinflatedpoisson1",
                # family = "zeroinflatednbinomial0",
                # family = "zeroinflatednbinomial1",
                verbose = TRUE,
                control.family = control.family,
                control.compute = list(
                  config = TRUE,
                  # return.marginals.predictor = TRUE,
                  # cpo = TRUE,
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

# Adjusted
# FIXME: year via iid? above then too!

formula <- pop ~ 
  sex +
  f(id_age, model = "iid", hyper = hyper.iid, constr = TRUE) +
  f(id_year, model = "iid", hyper = hyper.iid, constr = TRUE) +
  # f(ID, model = "bym2", graph = "data/nb/ar21_wm_q.adj", scale.model = TRUE, constr = TRUE, hyper = hyper.bym)
  # temp solution to save time
  f(ID, model = "iid", constr = TRUE, hyper = hyper.iid)

results <- inla(formula,
                data = st_grid_pop_pred,
                family = "Poisson",
                # family = "zeroinflatedpoisson0",
                # family = "zeroinflatedpoisson1",
                # family = "zeroinflatednbinomial0",
                # family = "zeroinflatednbinomial1",
                verbose = TRUE,
                control.family = control.family,
                control.compute = list(
                  config = TRUE,
                  # return.marginals.predictor = TRUE,
                  # cpo = TRUE,
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

# FIXME: new / better naming?

write_rds(st_grid_pop_pred, file = "data/blob/st_grid_pop_pred.Rds")