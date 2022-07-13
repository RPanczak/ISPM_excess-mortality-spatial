# Distribute deaths by gemeinde to grid using weights from historical deaths
# Radek and Julien, 2022-03-29

geom_002_deaths_to_grid <- function(deaths_data, weight_data, pop_data, n_iter) {
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
