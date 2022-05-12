set.seed(12345)

library(tidyverse)
library(INLA)

### data 
data <- 
  read_rds("data/BfS/monthly_deaths/w_deaths_2015_2021_ar_pop.Rds") %>% 
  select(-ARGRNR, -ARGRNAME, -KTNAME) %>% 
  # mutate(id_time = as.numeric(as.factor(date))) %>% 
  # relocate(id_time, .after = month) %>% 
  # select(-date) %>% 
  mutate(id_year = year - 2014,
         observed = deaths,
         id_space = as.integer(as.factor(ARNR)),
         id_age = as.integer(as.factor(age))) %>% 
  mutate(deaths = if_else(year >= 2020, NA_integer_, observed)) %>% 
  relocate(id_space) %>% 
  relocate(id_age, .after = age) %>% 
  relocate(observed, .after = deaths) %>% 
  relocate(id_year, .after = year) 

groups <- read_rds("data/groups.Rds")


### INLA setup

# priors
hyper.iid <- list(theta = list(prior = "pc.prec", param = c(1, 0.01)))
hyper.bym <- list(theta1 = list("PCprior", c(1, 0.01)), 
                  theta2 = list("PCprior", c(0.5, 0.5)))

control.family <- inla.set.control.family.default()

threads = parallel::detectCores()

### Stratified modelling

formula_strat <-
  deaths ~ 1 + offset(log(population)) + 
  f(id_year, model = "iid", hyper = hyper.iid, constr = TRUE) +
  # f(month, model = "seasonal", hyper = hyper.iid, constr = TRUE, scale.model = TRUE, season.length = 12) +
  f(month, model = "rw1", hyper = hyper.iid, constr = TRUE, scale.model = TRUE, cyclic = TRUE) +
  # f(id_space, model = "bym2", graph = "data/nb/ar21_wm_q.adj", scale.model = TRUE, constr = TRUE, hyper = hyper.bym)
  # temp solution to save time
  f(id_space, model = "iid", constr = TRUE, hyper = hyper.iid)

results <- list()

for(j in 1:nrow(groups)){
  
  print(j)
  
  data_strat <- data %>% 
    filter(age == groups[j, ]$age & sex == groups[j, ]$sex) %>% 
    select(-age, -sex, -id_age)
  
  model_strat <- inla(formula_strat,
                      data = data_strat,
                      family = "Poisson",
                      # family = "zeroinflatedpoisson0",
                      # family = "zeroinflatedpoisson1",
                      # family = "zeroinflatednbinomial0",
                      # family = "zeroinflatednbinomial1",
                      # verbose = TRUE,
                      control.family = control.family,
                      control.compute = list(config = TRUE, 
                                             # return.marginals.predictor = TRUE,
                                             # cpo = TRUE, 
                                             dic = TRUE, waic = TRUE),
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
  
  name <- paste(groups[j, ]$age, groups[j, ]$sex)
  ar_strat_iid[[name]] <- model_strat
  
  rm(data_strat, model_strat); gc()
  
}

write_rds(ar_strat_iid, file = "results/ar_strat_iid.Rds")

### Adjusted modelling

formula_all <-
  deaths ~ 1 + offset(log(population)) + 
  
  sex +
  f(id_age, model = "iid", hyper = hyper.iid, constr = TRUE) +
  
  f(id_year, model = "iid", hyper = hyper.iid, constr = TRUE) +
  # f(month, model = "seasonal", hyper = hyper.iid, constr = TRUE, scale.model = TRUE, season.length = 12) +
  f(month, model = "rw1", hyper = hyper.iid, constr = TRUE, scale.model = TRUE, cyclic = TRUE) +
  # f(id_space, model = "bym2", graph = "data/nb/ar21_wm_q.adj", scale.model = TRUE, constr = TRUE, hyper = hyper.bym)
  # temp solution to save time
  f(id_space, model = "iid", constr = TRUE, hyper = hyper.iid)


ar_all_iid <- inla(formula_all,
                   data = data,
                   family = "Poisson",
                   # family = "zeroinflatedpoisson0",
                   # family = "zeroinflatedpoisson1",
                   # family = "zeroinflatednbinomial0",
                   # family = "zeroinflatednbinomial1",
                   # verbose = TRUE,
                   control.family = control.family,
                   control.compute = list(config = TRUE, 
                                          # return.marginals.predictor = TRUE,
                                          # cpo = TRUE, 
                                          dic = TRUE, waic = TRUE),
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

write_rds(ar_all_iid, "results/ar_all_iid.Rds")
