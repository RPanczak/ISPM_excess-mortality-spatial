# Distribute expected by canton to grid using population weights
# Julien, 2022-07-13

geom_004_expected_to_grid <- function(expected_data, weight_data, pop_data, n_iter) {
  # select expected after 2020
  samples_temp = expected_data[,unique(names(expected_data))] %>% 
    as_tibble() %>% 
    dplyr::filter(year>=2020)
  # samples from the INLA model with temperature
  samples_temp = samples_temp %>% 
    dplyr::rename(age=age.group,
                  week_raw=EURO_LABEL,
                  canton_id=ID_space,
                  KTNAME=canton_name) %>%
    dplyr::mutate(week=ISOweek::ISOweek2date(paste0(week_raw,"-1")),
                  age2=factor(age,
                             levels=c("less40","40-59","60-69","70-79","80plus"),
                             labels=c("<40","40-59","60-69","70-79","80+")),
                  sex=factor(sex,
                             levels=c("female","male"),
                             labels=c("Female","Male")),
                  KTNAME=as.character(KTNAME),
                  KTNAME=if_else(canton_id=="CH033","AG",KTNAME)) %>%
    dplyr::filter(KTNAME != "FL") %>%
    dplyr::ungroup() %>% 
    dplyr::select(-canton_id,-deaths)
  # extract pop and pivot
  samples_pop = samples_temp %>% 
    dplyr::select(-starts_with("V")) %>% 
    tidyr::pivot_longer(starts_with("pop"),names_to="it_pop",values_to="population") %>% 
    dplyr::mutate(it_pop=as.numeric(gsub("pop_","",it_pop)))
  # extract exp and pivot
  samples_exp = samples_temp %>% 
    dplyr::select(-starts_with("pop")) %>% 
    tidyr::pivot_longer(starts_with("V"),names_to="it",values_to="exp_deaths") %>% 
    dplyr::mutate(it=gsub("V","",it)) %>% 
    tidyr::separate(it,"_",into=c("it_exp","it_pop")) %>% 
    dplyr::mutate(it_pop=as.numeric(it_pop),
                  it_exp=as.numeric(it_exp))
  # merge
  samples_temp = samples_exp %>% 
    dplyr::left_join(samples_pop) %>% 
    dplyr::select(year,week,
                  canton,canton_id,canton_name,
                  age_group,sex,
                  it_exp,it_pop,deaths,exp_deaths,
                  population)
  
  
  
  
  
  
  # keep only latest pop estimate
  pop_data <- dplyr::filter(pop_data, year == 2019) %>%
    dplyr::select(-year) %>%
    tidyr::expand_grid(month = 1:12)
  # join
  merged_data <- dplyr::left_join(pop_data, deaths_data, by = c("GMDNR", "GMDNAME", "age", "sex", "month")) %>%
    dplyr::left_join(weight_data, by = c("ID", "age", "sex")) %>% 
    dplyr::filter(!is.na(year)) %>%
    dplyr::rename(deaths_by_gem = deaths)
  # function to distribute deaths deaths from gemeinde to grid using weights
  distribute_deaths <- function(n, d, w, p) {
    l <- length(d)
    r <- rmultinom(n, size = d, prob = w + 1e-10) # add small number to avoid numerical issues with pop=0
    while (any(r > p)) { # check that deaths never exceed pop
      r <- unlist(rmultinom(n, size = d, prob = w + 1e-10))
    }
    return(r)
  }
  # distribute
  imputed_data <- merged_data %>%
    dplyr::filter(pop>0 & weight>0) %>% 
    dplyr::group_by(year, month, GMDNAME, GMDNR, age, sex) %>%
    dplyr::mutate(dist_deaths = distribute_deaths(n_iter, deaths_by_gem, weight, pop)) %>%
    dplyr::ungroup()
  # bring back places with pop 0 or weight 0
  imputed_data <- merged_data %>%
    dplyr::filter(!(pop>0 & weight>0)) %>% 
    dplyr::bind_rows(imputed_data) %>% 
    tidyr::replace_na(list(dist_deaths=0)) %>% 
    dplyr::arrange(ID,age,sex,year,month)
  # format
  imputed_data <- imputed_data$dist_deaths %>%
    tibble::as_tibble() %>%
    dplyr::rename_with(~ gsub("V", "dist_deaths_", .x)) %>%
    dplyr::bind_cols(merged_data, .)
  # aggregate by ID
  imputed_data_grid <- imputed_data %>%
    dplyr::group_by(year, month, ID, age, sex) %>%
    dplyr::summarise(across(c(tidyselect::starts_with("dist_deaths"), pop), ~ sum(.x)),.groups="drop")
  return(imputed_data_grid)
}