# Extract population by grid/gemeinde from STATPOP
# Radek and Julien, 2022-03-08

geom_001_pe_to_grid = function(path) {
  r_pe <- read_dta(path) %>% 
    zap_label() %>% zap_formats() %>% 
    # check sex coding since it seems to be different than SNC?
    mutate(
      sex = if_else(sex == "2", "Female", "Male"),
      sex = factor(sex),
      age = cut(age, 
                breaks = c(0, 40, seq(50, 80, 10), 120), right = FALSE, 
                labels = c("<40", "40-49", "50-59", "60-69", "70-79", "80+"))) %>% 
    group_by(year, geocoorde, geocoordn, sex, age) %>% 
    summarise(n = n()) %>% 
    ungroup()  %>% 
    st_as_sf(coords = c("geocoorde", "geocoordn"), 
             crs = 2056,
             remove = TRUE) %>% 
    st_join(., grid_1km_over, join = st_intersects) %>% 
    relocate(geometry, .after = last_col())
  return(r_pe)
}