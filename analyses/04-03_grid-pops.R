# ###############################
# Extrapolating pops
# ML solution

library(readr)
library(dplyr)
library(tidyr)
library(tibble)

# ###############################
# pop by grid
st_grid_pop_pred <- read_rds("data/blob/st_grid_pop_exp.Rds")

# ###############################
# GLM
# m1 <- glm(pop ~ age + sex + year,
#           data = st_grid_pop_pred,
#           family = poisson(link = "log"))
# 
# st_grid_pop_pred$m1 <- as.integer(predict(m1, 
#                                           st_grid_pop_pred, 
#                                           type = "response"))

# ###############################
# GLMER 1
library(lme4)

m2 <- glmer(pop ~ age + sex + year + (1 | ID),
            data = st_grid_pop_pred,
            family = poisson(link = "log"))

st_grid_pop_pred$m2 <- as.integer(predict(m2, 
                                          st_grid_pop_pred, 
                                          type = "response"))

# ###############################
# GLMER 2
m3 <- glmer(pop ~ age + sex + year + (year | ID),
            data = st_grid_pop_pred,
            family = poisson(link = "log")
)

st_grid_pop_pred$m3 <- as.integer(predict(m3, 
                                          st_grid_pop_pred, 
                                          type = "response"))

write_rds(st_grid_pop_pred, file = "data/blob/st_grid_pop_pred.Rds")