# Create weights for distributing deaths from gemeinde to grid
# Julien, 2022-07-13

geom_003_weights_from_historical_deaths <- function(deaths_data, lookup) {
  
  # filter out small bits of grids corresponding to other gemeinde 
  lookup_unique <- lookup %>% 
    dplyr::filter(year==2014,age=="<40",sex=="Female") %>% 
    dplyr::select(ID,ID2,area,area2,GMDNR,GMDNAME,KTNR,KTNAME) %>% 
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
    dplyr::group_by(GMDNR,sex,age) %>% 
    dplyr::mutate(deaths_by_gem=sum(deaths)) %>% 
    dplyr::group_by(ID,sex,age) %>% 
    dplyr::mutate(deaths_by_grid=sum(deaths)) %>% 
    dplyr::group_by(ID,sex,age) %>% 
    dplyr::summarise(weight=mean(deaths_by_grid/(deaths_by_gem+1e-10)),.groups="drop")
  
  return(weights)
}
