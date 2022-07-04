# Extract population by grid/gemeinde from STATPOP
# Radek and Julien, 2022-07-04

geom_001_pe_to_grid = function(path) {
  r_pe <- read_delim(path, 
                     delim = ";", escape_double = FALSE, 
                     col_types = cols(STATYEAR = col_integer(), 
                                      SEX = col_integer(), 
                                      TYPEOFRESIDENCE = col_integer(), 
                                      POPULATIONTYPE = col_integer(), 
                                      AGE = col_integer(), 
                                      CLASSAGEFIVEYEARS = col_integer(), 
                                      NATIONALITYCATEGORY = col_integer(), 
                                      MAINRESIDENCECATEGORY = col_integer(), 
                                      GEOCOORDE = col_integer(), 
                                      GEOCOORDN = col_integer(), 
                                      INDIC_EGID = col_integer(), 
                                      statdate = col_date(format = "%d/%m/%Y")), 
                     trim_ws = TRUE) %>% 
    janitor::remove_empty(c("rows", "cols")) %>% janitor::clean_names() %>% 
    rename(egid = federalbuildingid) %>% 
    filter(typeofresidence == 1) %>% 
    filter(populationtype == 1) %>% 
    filter(mainresidencecategory == 1) %>% 
    filter(indic_egid == 1) %>% 
    dplyr::select(-statyear, -statdate, 
                  -typeofresidence, -populationtype, -mainresidencecategory,
                  -indic_egid) %>% 
    mutate(
      sex = if_else(sex == "2", "Female", "Male"),
      sex = factor(sex),
      age = cut(age, 
                breaks = c(0, 40, seq(50, 80, 10), 120), right = FALSE, 
                labels = c("<40", "40-49", "50-59", "60-69", "70-79", "80+"))) %>% 
    group_by(egid, geocoorde, geocoordn) %>% 
    summarise(n = n()) %>% 
    ungroup() %>% 
    st_as_sf(coords = c("geocoorde", "geocoordn"), 
             crs = 2056,
             remove = TRUE) %>% 
    st_join(., grid_1km_over, join = st_intersects) %>% 
    relocate(geometry, .after = last_col())
  return(r_pe)
}