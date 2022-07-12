# ###############################
# Extrapolating pops
# lme4 multilevel solution

set.seed(12345)

library(tidyverse)
library(splines)
library(lme4)

# ###############################
# pop by grid
st_grid_pop_pred <- read_rds("data/blob/st_grid_pop_exp.Rds")

# sample dataset for testing
# st_grid_pop_pred <- st_grid_pop_pred %>%
#   mutate(ID2 = factor(ID)) %>%
#   filter(ID2 %in% sample(levels(ID2), 100)) %>%
#   mutate(ID2 = forcats::fct_drop(ID2))

# ###############################
# GLMER 1
m2 <- glmer(pop ~ age*sex + 
              ns(year, df = 5) +
              (1 | ID),
            data = st_grid_pop_pred,
            family = poisson(link = "log"))

st_grid_pop_pred$m2 <- as.integer(predict(m2, 
                                          st_grid_pop_pred, 
                                          type = "response"))

# ###############################
# GLMER 2
m3 <- glmer(pop ~ age*sex + 
              year +
              (year | ID),
            data = st_grid_pop_pred,
            family = poisson(link = "log")
)

st_grid_pop_pred$m3 <- as.integer(predict(m3,
                                          st_grid_pop_pred,
                                          type = "response"))

write_rds(m2, file = "data/blob/m2.Rds")
write_rds(m3, file = "data/blob/m3.Rds")

write_rds(st_grid_pop_pred, file = "data/blob/st_grid_pop_pred.Rds")