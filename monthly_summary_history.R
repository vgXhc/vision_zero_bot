library(tidyverse)
library(rtoot)
library(gghighlight)
library(toOrdinal)
library(lubridate)
library(sf)

# read token from Github Actions environment
token <- structure(
  list(
    bearer = Sys.getenv("RTOOT_DEFAULT_TOKEN"),
    type = "user",
    instance = "botsin.space"
  ),
  class = "rtoot_bearer"
)


# download 2022 crash data
download.file("https://CommunityMaps.wi.gov/crash/public/crashesKML.do?filetype=json&startyear=2022&injsvr=K&injsvr=A&county=dane", "crashes.json")
df <- st_read("crashes.json")

# download historic crash data and save it locally
# 
download.file("https://CommunityMaps.wi.gov/crash/public/crashesKML.do?filetype=json&startyear=2017&injsvr=K&injsvr=A&county=dane", "crashes_hist.json")
df_hist <- st_read("crashes_hist.json")


# set up time intervals
d <- today()

crashes <- df %>%
  mutate(date = mdy(date),
         totfatl = as.numeric(totfatl),
         totinj = as.numeric(totinj)) %>%
  st_drop_geometry() %>% 
  filter(muniname == "MADISON")

# historic numbers
crashes_hist <- df_hist %>%
  filter(muniname == "MADISON") %>% 
  mutate(date = mdy(date),
         totfatl = as.numeric(totfatl),
         totinj = as.numeric(totinj),
         year = year(date),
         month = month(date, label = T)) %>%
  st_drop_geometry()

last_month <- month(floor_date(d, unit = "month") -1, label = T, abbr = T)
last_month_long <- month(floor_date(d, unit = "month") -1, label = T, abbr = F)

crashes_hist_by_mo <-  crashes_hist %>% 
  group_by(year, month) %>% 
  summarize(tot_fat_mo = sum(totfatl), 
            tot_inj_mo = sum(totinj), 
            tot_fat_inj_mo = tot_fat_mo + tot_inj_mo
  ) %>% 
  group_by(month) %>% 
  summarise(year, tot_fat_inj_mo, max_fat_inj_mo = max(tot_fat_inj_mo))

ranked <- crashes_hist_by_mo %>% 
  filter(month == last_month) %>% 
  pull(tot_fat_inj_mo)
crashes_last_mo <- tail(ranked, 1)
rank_mo <- tail(rank(-round(ranked)), n = 1)
if (rank_mo == 1){
  rank_mo_str <- "highest"
  } else if (rank_mo == length(ranked)) {
    rank_mo_str <- "lowest"
  } else{
    rank_mo_str <- paste0(toOrdinal(rank_mo), " highest")
  }

title_month <- paste0("Fatal and serious traffic injuries in Madison in ", last_month_long, ", 2017-2022")
subtitle_month <- paste0("With ", 
                         crashes_last_mo, 
                         " fatalities and serious injuries, this year's ", 
                         last_month_long ,
                         " had the ",
                         rank_mo_str,
                         " numbers since 2017."
)

p <- crashes_hist_by_mo %>% 
  ggplot(aes(year, tot_fat_inj_mo, fill = tot_fat_inj_mo)) +
  scale_fill_viridis_c()+
  geom_col() +
  scale_x_continuous() +
  scale_y_continuous(breaks = NULL)+
  gghighlight(month(floor_date(d, unit = "month") -1, label = T)  == month) +
  geom_text(aes(label = tot_fat_inj_mo), nudge_y = 4.5) +
  facet_wrap(~month, ncol = 3) +
  #gghighlight(tot_fat_inj_mo == max_fat_inj_mo, max_highlight = 12L, calculate_per_facet = F) +
  theme_minimal()+
  labs(x = element_blank(),
       y = "Fatal and serious injuries",
       title = title_month,
       subtitle = subtitle_month) +
  theme(legend.position = "none",
        axis.text.y = element_blank())

ggsave("monthly_comparison.png", p, width = 1200, height = 675, units = "px", scale = 2, bg = 'white' )

toot <- paste0(
  "#VisionZero monthly recap for ",
  last_month_long,
  " in #MadisonWI: With ",
  crashes_last_mo,
  " fatalities and serious injuries, this year's ",
  last_month_long ,
  " had the ",
  rank_mo_str,
  " number of fatalities/serious injuries since 2017. #StopTrafficViolence"
)

# alt text for tweet
alt_text <- paste0(
  "A bar graph faceted by month, showing the number of fatalities and serious traffic injuries in Madison between 2017 and 2018. The past month is highlighted."
)


# post a media file with alt text
post_toot(toot,
          media = "monthly_comparison.png",
          alt_text = alt_text, 
          visibility = "private",
          language = "EN",
          token = token
)

