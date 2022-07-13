# Create weights for distributing deaths from canton to grid
# Julien, 2022-07-13

geom_005_weights_from_historical_deaths_canton <- function(deaths_data, lookup) {
  
  # filter out small bits of grids corresponding to other cantons 
  lookup_unique <- lookup %>% 
    dplyr::filter(year==2014,age=="<40",sex=="Female") %>% 
    dplyr::select(ID,ID2,area,area2,KTNR,KTNAME) %>% 
    dplyr::group_by(ID) %>% 
    dplyr::mutate(rank=min_rank(-area2)) %>% 
    dplyr::filter(rank==1) %>% 
    dplyr::ungroup()
  
  # merge with deaths
  merged_data <- deaths_data %>% 
    dplyr::left_join(lookup_unique,by = "ID") %>% 
    dplyr::select(-rank)
  
  # create weights based on the average distribution of gemeinde-level deaths across grids
  weights <- merged_data %>% 
    dplyr::group_by(KTNR,sex,age) %>% 
    dplyr::mutate(deaths_by_canton=sum(deaths)) %>% 
    dplyr::group_by(ID,sex,age) %>% 
    dplyr::mutate(deaths_by_grid=sum(deaths)) %>% 
    dplyr::group_by(ID,sex,age) %>% 
    dplyr::summarise(weight=mean(deaths_by_grid/(deaths_by_canton+1e-10)),.groups="drop")
  
  return(weights)
}
