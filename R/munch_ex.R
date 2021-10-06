library(tidyverse)
library(munch)

# Gettnau (1130) - Am 1. Januar 2021 fusionierte sie mit der Gemeinde Willisau (1151).

swc_get_mun_history(1130) %>% 
  View()

mutations <- swc_get_mutations()

mutations %>% 
  filter(mId.y == 1130) %>% 
  View()

mutations %>% 
  filter(mId.y == 1151) %>% 
  View()


t <- dplyr::filter(mutations, mId.y == 1130) 

t_1 <- dplyr::filter(t, mHistId.y == max(mHistId.y)) %>% 
  View()

t_past <- add_past(t, mutations)

# no change here
swc_get_merger_mapping_table(2015, 2018, type = "compact") %>% 
  filter(mun_id_x == 1130)

# but change here
swc_get_merger_mapping_table(2015, 2021, type = "compact") %>% 
  filter(mun_id_x == 1130)



