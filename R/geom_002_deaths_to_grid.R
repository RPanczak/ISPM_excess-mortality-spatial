# Distribute deaths by gemeinde to grid using population weights
# Radek and Julien, 2022-03-29

# deaths_data = st_gem_deaths_2020_2021
# pop_data = lu_grid_gem

geom_002_deaths_to_grid <- function(deaths_data, pop_data, n_iter) {
  # keep only latest pop estimate
  pop_data <- dplyr::filter(pop_data, year == 2019) %>%
    dplyr::select(-year) %>%
    tidyr::expand_grid(month = 1:12)
  # join
  merged_data <- dplyr::left_join(pop_data, deaths_data, by = c("GMDNR", "GMDNAME", "age", "sex", "month")) %>%
    dplyr::filter(!is.na(year)) %>%
    dplyr::rename(deaths_by_gem = deaths)
  # function to distribute deaths deaths by gemeinde to grid using population weights
  distribute_deaths <- function(n, d, p) {
    l <- length(d)
    r <- rmultinom(n, size = d, prob = p + 1e-10) # add small number to avoid numerical issues with pop=0
    while (any(r > p)) { # check that deaths never exceed pop
      r <- rmultinom(n, size = d, prob = p + 1e-10)
    }
    return(r)
  }
  # distribute
  imputed_data <- merged_data %>%
    dplyr::group_by(year, month, GMDNAME, GMDNR, age, sex) %>%
    dplyr::mutate(dist_deaths = distribute_deaths(n_iter, deaths_by_gem, pop)) %>%
    dplyr::ungroup()
  # format
  imputed_data <- imputed_data$dist_deaths %>%
    tibble::as_tibble() %>%
    dplyr::rename_with(~ gsub("V", "dist_deaths_", .x)) %>%
    dplyr::bind_cols(merged_data, .)
  # aggregate by ID
  imputed_data_grid <- imputed_data %>%
    dplyr::group_by(year, month, ID, age, sex) %>%
    dplyr::summarise(across(c(tidyselect::starts_with("dist_deaths"), pop), ~ sum(.x)))
  return(imputed_data_grid)
}
