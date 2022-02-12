library(tidyverse)
library(rtweet)
library(sf)
library(lubridate)
library(jsonlite)
library(magick)

create_token(
  app = "vision_zero_bot",  # the name of the Twitter app
  consumer_key = Sys.getenv("TWITTER_CONSUMER_API_KEY"),
  consumer_secret = Sys.getenv("TWITTER_CONSUMER_API_SECRET"),
  access_token = Sys.getenv("TWITTER_ACCESS_TOKEN"),
  access_secret = Sys.getenv("TWITTER_ACCESS_TOKEN_SECRET")
)




download.file("https://CommunityMaps.wi.gov/crash/public/crashesKML.do?filetype=json&startyear=2022&injsvr=K&injsvr=A&county=dane", "crashes.json")
df <- st_read("crashes.json")

# set up time intervals
d <- today()

last_week <- interval(start = floor_date(d, unit = "week")-8, end = floor_date(d, unit = "week")-1)

# formatted date for output in tweet
last_week_formatted <- paste0(format(last_week@start, "%d/%m"),
                         "-",
                         format(floor_date(d, unit = "week")-1, "%d/%m"))


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


tweet_1 <- paste0("Last week in Madison (",
                  last_week_formatted,
                  "), there were ", 
                tot_fat_wk,
                " fatal and ",
                tot_inj_wk,
                " serious injury crashes. Since the beginning of the year, traffic violence has killed ",
                tot_fat_yr,
                " people and seriously injured ",
                tot_inj_yr,
                " people in our city. #VisionZero #StopTrafficViolence")


# tweet_2 <- paste0("Of those killed and injured last week, ",
#                   tot_inj_ped_wk,
#                   " were pedestrians and ",
#                   tot_inj_bik_wk,
#                   " were riding a bike. The crashes happened here.")

# create image to go with tweet. Recommended size: 1200px X 675px
background <- image_read("madison_1200.png")

image_text <- paste0("Vision Zero update ",
                     last_week_formatted,
                     "\n Fatalities: ",
                     tot_fat_wk,
                     "\n Serious injuries: ",
                     tot_inj_wk,
                     "\n Year-to-date fatalities: ",
                     tot_fat_yr,
                     "\n Year-to-date serious injuries:",
                     tot_inj_yr)
  
 

tweet_1_img <- image_annotate(background, 
               image_text, 
               size = 60, 
               font = "sans",
               weight = 700,
               gravity = "center", 
               color = "black")

image_write(tweet_1_img, 
            path = "tweet_1_img.png")

post_tweet(status = tweet_1, 
           media = "tweet_1_img.png")

