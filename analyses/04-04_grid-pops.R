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
st_grid_pop_pred <- read_rds("data/blob/st_grid_pop_exp.Rds")

# sample dataset for testing
# st_grid_pop_pred <- st_grid_pop_pred %>% 
#   mutate(ID = factor(ID)) %>% 
#   filter(ID %in% sample(levels(ID), 10))

# ###############################
# INLA

hyper.iid <- list(theta = list(prior = "pc.prec", param = c(1, 0.01)))

# hyper.bym <- list(theta1 = list("PCprior", c(1, 0.01)), 
#                   theta2 = list("PCprior", c(0.5, 0.5)))

control.family <- inla.set.control.family.default()
threads <- parallel::detectCores()

# Stratified

data_stratified <- st_grid_pop_pred %>%
  filter(age == "<40", sex == "Female")

f1 <- pop ~ 
  # year +
  f(id_year, model = "iid", hyper = hyper.iid, constr = TRUE) +
  f(ID, model = "iid", hyper = hyper.iid, constr = TRUE)

m1 <- inla(f1,
                data = data_stratified,
                family = "Poisson",
                # family = "zeroinflatedpoisson0",
                # family = "zeroinflatedpoisson1",
                # family = "zeroinflatednbinomial0",
                # family = "zeroinflatednbinomial1",
                # verbose = TRUE,
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

f2 <- pop ~ 
  sex + age +
  f(id_year, model = "iid", hyper = hyper.iid, constr = TRUE) +
  # f(ID, model = "bym2", graph = "data/nb/ar21_wm_q.adj", scale.model = TRUE, constr = TRUE, hyper = hyper.bym)
  f(ID, model = "iid", constr = TRUE, hyper = hyper.iid)

m2 <- inla(f2,
                data = st_grid_pop_pred,
                family = "Poisson",
                # family = "zeroinflatedpoisson0",
                # family = "zeroinflatedpoisson1",
                # family = "zeroinflatednbinomial0",
                # family = "zeroinflatednbinomial1",
                # verbose = TRUE,
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

f3 <- pop ~ 
  sex +
  f(id_age, model = "iid", hyper = hyper.iid, constr = TRUE) +
  f(id_year, model = "iid", hyper = hyper.iid, constr = TRUE) +
  # f(ID, model = "bym2", graph = "data/nb/ar21_wm_q.adj", scale.model = TRUE, constr = TRUE, hyper = hyper.bym)
  f(ID, model = "iid", constr = TRUE, hyper = hyper.iid)

m3 <- inla(f3,
                data = st_grid_pop_pred,
                family = "Poisson",
                # family = "zeroinflatedpoisson0",
                # family = "zeroinflatedpoisson1",
                # family = "zeroinflatednbinomial0",
                # family = "zeroinflatednbinomial1",
                # verbose = TRUE,
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

write_rds(m1, file = "data/blob/m1.Rds")
write_rds(m2, file = "data/blob/m2.Rds")
write_rds(m3, file = "data/blob/m3.Rds")

# write_rds(st_grid_pop_pred, file = "data/blob/st_grid_pop_pred.Rds")