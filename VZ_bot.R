library(dplyr)
library(tibble)
library(rtoot)
library(sf)
library(lubridate)
library(jsonlite)
library(magick)
library(tmap)

# read token from Github Actions environment
token <- structure(
  list(
    bearer = Sys.getenv("RTOOT_DEFAULT_TOKEN"),
    type = "user",
    instance = "urbanists.social"
  ),
  class = "rtoot_bearer"
)

# read in city limits
city_limits <- st_read("data/City_Limit/City_Limit.shp") |> st_make_valid()

# download current year crash data
this_year = year(Sys.Date())
dl_path = paste0("https://CommunityMaps.wi.gov/crash/public/crashesKML.do?filetype=json&startyear=",
                 this_year,
                 "&injsvr=K&injsvr=A&county=dane")
download.file(dl_path, "crashes.json")
df <- st_read("crashes.json")

# set up time intervals
d <- today()

last_week <- interval(start = floor_date(d, unit = "week")-8, end = floor_date(d, unit = "week")-1)

# formatted date for output in tweet
last_week_formatted <- paste0(format(last_week@start, "%m/%d"),
                         "-",
                         format(floor_date(d, unit = "week")-1, "%m/%d"))


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

disclaimer <- "* There can be delays in crash reporting, and weekly numbers are preliminary. Data: CommunityMaps/WI Traffic Operations and Safety Laboratory. https://communitymaps.wi.gov/"
# create tweet body
toot_1 <- paste0("Last week in #MadisonWI (",
                  last_week_formatted,
                  "), there were ",
                tot_fat_wk,
                " traffic fatalities and ",
                tot_inj_wk,
                " serious injuries.* Since the beginning of the year, traffic violence has killed ",
                tot_fat_yr,
                " people and seriously injured ",
                tot_inj_yr,
                " people in our city. #VisionZero #StopTrafficViolence\n\n",
                disclaimer)


# create crash map
map_data <- df |> 
  filter(muniname == "MADISON") |> 
  mutate(severity = case_match(injsvr,
                                   "A" ~ "Serious injury",
                                   "K" ~ "Fatal"))

tmap_options(check.and.fix = TRUE)
background <- tm_shape(city_limits) +
  tm_polygons(alpha = .7) +
  tm_shape(map_data) +
  tm_dots(col = "red", title = "Crash severity", size = .1) +
  tm_layout(frame = FALSE) 

tmap_save(background, filename = "background_map.png", width = 1200, height = 675)


# create image to go with tweet. Recommended size: 1200px X 675px

background <- image_read("background_map.png")

background <- background |> image_colorize(opacity = 60, "lightgrey") 

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

toot_1_img <- image_annotate(background,
               image_text,
               size = 60,
               font = "sans",
               weight = 700,
               gravity = "center",
               color = "black")

image_write(toot_1_img,
            path = "toot_1_img.png")

# # Download the image to a temporary location
# temp_file <- tempfile()
# download.file("https://haraldkliems.netlify.app/posts/do-crashes-have-a-history/img/montreal_map.png", temp_file)


# post a media file with alt text
post_toot(toot_1,
          media = "toot_1_img.png",
          alt_text = paste0("A map of the Madison city limits and red dots for all serious and fatal crash locations for the year. Overlaid text: ", image_text), 
          visibility = "public",
          language = "EN",
          token = token
          )



