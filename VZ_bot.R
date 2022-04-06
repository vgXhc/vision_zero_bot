library(tidyverse)
library(rtweet)
library(sf)
library(lubridate)
library(jsonlite)
library(magick)
library(toOrdinal)


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



# create tweet body
tweet_1 <- paste0("Last week in Madison (",
                  last_week_formatted,
                  "), there were ",
                tot_fat_wk,
                " traffic fatalities and ",
                tot_inj_wk,
                " serious injuries. Since the beginning of the year, traffic violence has killed ",
                tot_fat_yr,
                " people and seriously injured ",
                tot_inj_yr,
                " people in our city. #VisionZero #StopTrafficViolence")

disclaimer_tweet <- "Note that there can be delays in crash reporting and weekly numbers are preliminary. Data: CommunityMaps/WI Traffic Operations and Safety Laboratory. https://communitymaps.wi.gov/"


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

# # Download the image to a temporary location
# temp_file <- tempfile()
# download.file("https://haraldkliems.netlify.app/posts/do-crashes-have-a-history/img/montreal_map.png", temp_file)

post_tweet(status = tweet_1,
           media = "tweet_1_img.png")

# prepare disclaimer tweet
## lookup status_id
my_timeline <- get_timeline(rtweet:::home_user())

## ID for reply
reply_id <- my_timeline$status_id[1]

## post reply
post_tweet(status = disclaimer_tweet,
           in_reply_to_status_id = reply_id)


