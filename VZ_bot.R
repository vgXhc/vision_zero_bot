library(tidyverse)
library(rtweet)
library(sf)
library(lubridate)
library(jsonlite)


download.file("https://CommunityMaps.wi.gov/crash/public/crashesKML.do?filetype=json&startyear=2022&injsvr=K&injsvr=A&county=dane", "crashes.json")
df <- st_read("crashes.json")

# set up time intervals
d <- today()

last_week <- interval(start = floor_date(d, unit = "week")-8, end = floor_date(d, unit = "week")-1)



crashes <- df %>% 
  mutate(date = mdy(date),
         totfatl = as.numeric(totfatl),
         totinj = as.numeric(totinj)) %>% 
  st_drop_geometry()

# to access the various flags in the data, we need to parse the json once more
# and then add that to the original crashes data frame
crashesJSON <- fromJSON("crashes.json")
crashes <- crashes %>% 
  add_column(crashesJSON$features$properties) %>% 
  filter(muniname == "MADISON")

crashes_wk <- crashes %>% 
  filter(date %within% last_week)

#weekly numbers
tot_crashes_wk <- crashes_wk %>% nrow()
tot_fat_wk <- crashes_wk %>% 
  summarise(sum(totfatl)) %>% 
  pull()
tot_inj_wk <- crashes_wk %>% 
  summarise(sum(totinj)) %>% 
  pull()

# annual numbers
tot_crashes_yr <- crashes %>% nrow()
tot_fat_yr <- crashes %>% 
  summarise(sum(totfatl)) %>% 
  pull()
tot_inj_yr <- crashes %>% 
  summarise(sum(totinj)) %>% 
  pull()

tweet_1 <- paste0("Last week in Madison, there were ", 
                tot_crashes_wk, 
                " crashes that resulted in ",
                tot_fat_wk,
                " fatalities and ",
                tot_inj_wk,
                " serious injuries. Since the beginning of the year ",
                tot_fat_yr,
                " people have been killed and ",
                tot_inj_yr,
                " people have been seriously injured in traffic. #VisionZero #StopTrafficViolence")


tweet_2 <- paste0("Of those killed and injured last week, ",
                  tot_inj_ped_wk,
                  " were pedestrians and ",
                  tot_inj_bik_wk,
                  " were riding a bike. The crashes happened here.")




