library(tidyverse)
library(rtweet)
library(gghighlight)
library(toOrdinal)
library(lubridate)
library(sf)

vzbot_token <-create_token(
  app = "vision_zero_bot",  # the name of the Twitter app
  consumer_key = Sys.getenv("TWITTER_CONSUMER_API_KEY"),
  consumer_secret = Sys.getenv("TWITTER_CONSUMER_API_SECRET"),
  access_token = Sys.getenv("TWITTER_ACCESS_TOKEN"),
  access_secret = Sys.getenv("TWITTER_ACCESS_TOKEN_SECRET")
)


# download 2022 crash data
download.file("https://CommunityMaps.wi.gov/crash/public/crashesKML.do?filetype=json&startyear=2022&injsvr=K&injsvr=A&county=dane", "crashes.json")
df <- st_read("crashes.json")

# download historic crash data and save it locally
# download.file("https://CommunityMaps.wi.gov/crash/public/crashesKML.do?filetype=json&startyear=2017&injsvr=K&injsvr=A&county=dane", "crashes_hist.json")
# df_hist <- st_read("crashes_hist.json")
# file.remove("crashes_hist.json")
# saveRDS(df_hist, "crashes_hist.RDS")
df_hist <- readRDS("crashes_hist.RDS")

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
rank_mo <- tail(rank(-ranked), n = 1)
rank_mo_str <- ifelse(rank_mo == 1, "", toOrdinal(rank_mo))
title_month <- paste0("Fatal and serious traffic injuries in Madison in ", last_month_long, ", 2017-2022")
subtitle_month <- paste0("With ", 
                         crashes_last_mo, 
                         " fatalities and serious injuries, this year's ", 
                         last_month_long ,
                         " was the ",
                         rank_mo_str,
                         " worst ",
                         "since 2017."
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

ggsave("monthly_comparison.png", p, width = 1200, height = 675, units = "px", scale = 2 )

tweet <- paste0(
  "#VisionZero monthly recap for ",
  last_month_long,
  " in #MadisonWI: With ",
  crashes_last_mo,
  " fatalities and serious injuries, this year's ",
  last_month_long ,
  " was the ",
  rank_mo_str,
  " worst in the years 2017-2022. #StopTrafficViolence"
)

# alt text requires development version of rtweet
# alt_text <- paste0(
#   "A bar graph faceted by month, showing the number of fatatlies and serious traffic injuries in Madison between 2017 and 2018. The past month is highlighted."
# )





post_tweet(status = tweet,
           media = "monthly_comparison.png")
#           media_alt_text = alt_text)

