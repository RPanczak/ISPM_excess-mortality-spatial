# https://rivasiker.github.io/ggHoriPlot/

library(tidyverse)
library(ggHoriPlot) 
library(ggthemes)

w_deaths_2015_2021_ar <- read_rds("data/BfS-closed/w_deaths_2015_2021_ar.Rds") %>% 
  group_by(ARGRNAME, date) %>% 
  summarise(deaths = sum(deaths)) %>% 
  ungroup()

cutpoints <- w_deaths_2015_2021_ar  %>% 
  mutate(
    outlier = between(
      deaths, 
      quantile(deaths, 0.25, na.rm=T)-
        1.5*IQR(deaths, na.rm=T),
      quantile(deaths, 0.75, na.rm=T)+
        1.5*IQR(deaths, na.rm=T))) %>% 
  filter(outlier)

ori <- sum(range(cutpoints$deaths))/2
sca <- seq(range(cutpoints$deaths)[1], 
           range(cutpoints$deaths)[2], 
           length.out = 7)[-4]

round(ori, 2) # The origin

round(sca, 2) # The horizon scale cutpoints

w_deaths_2015_2021_ar %>% 
  ggplot() +
  geom_horizon(aes(date, 
                   deaths,
                   fill = ..Cutpoints..), 
               origin = ori, horizonscale = sca) +
  scale_fill_hcl(palette = "RdBu", reverse = T) +
  facet_grid(ARGRNAME ~ .) +
  theme_few() +
  theme(
    panel.spacing.y=unit(0, "lines"),
    strip.text.y = element_text(size = 7, angle = 0, hjust = 0),
    axis.text.y = element_blank(),
    axis.title.y = element_blank(),
    axis.ticks.y = element_blank(),
    panel.border = element_blank()
  ) +
  scale_x_date(expand=c(0,0), 
               date_breaks = "1 year", 
               date_labels = "%b %y") +
  xlab("Date") +
  ggtitle("Monthly number of deaths in region", 
          "from I 2015 to VI 2021")

w_deaths_2015_2021_ar %>%  
  ggplot() +
  geom_horizon(aes(date, deaths), 
               origin = "median", horizonscale = 5) +
  scale_fill_hcl(palette = "BluGrn", reverse = T) +
  facet_grid(ARGRNAME~.) +
  theme_few() +
  theme(
    panel.spacing.y=unit(0, "lines"),
    strip.text.y = element_text(size = 7, angle = 0, hjust = 0),
    legend.position = "none",
    axis.text.y = element_blank(),
    axis.title.y = element_blank(),
    axis.ticks.y = element_blank(),
    panel.border = element_blank()
  ) +
  scale_x_date(expand=c(0,0), date_breaks = "12 months", date_labels = "%b %y") +
  ggtitle("Monthly number of deaths in region, 2015-2021") +
  xlab("")
