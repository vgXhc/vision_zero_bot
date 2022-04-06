# vision_zero_bot
A Twitter bot to automatically send out Vision-Zero-related tweets for Madison, using R and GitHub actions.

The instructions [here](https://www.rostrum.blog/2020/09/21/londonmapbot/) were very helpful in figuring this out. 

For more details, see my [blog post](https://haraldkliems.netlify.app/posts/a-vision-zero-twitter-bot-for-madison/) about the bot.

## Current status
The bot is in production status, tweeting a summary tweet once a week on Wednesdays. As of March 2022, it also tweets a monthly summary tweet, comparing the current month to the years 2017-2022.

## Data
The bot uses data from [Community Maps](https://transportal.cee.wisc.edu/partners/community-maps/crash/search/BasicSearch.do) to gather information about traffic crashes in Madison.

> Community Maps provides a statewide map of all police reported motor vehicle crashes in Wisconsin from 2010 to the current year. Fatal crashes are included from 2001. Crashes occurring on or after January 1, 2017 are mapped using geo-coded locations from the Wisconsin DT4000 police crash report. Prior year crashes have been geo-coded from the crash report location descriptions. Crashes that have not been geo-coded are not displayed on the map. Community Maps is maintained by the Wisconsin Traffic Operations and Safety (TOPS) Laboratory for research purposes and as a service to the Wisconsin Department of Transportation Bureau of Transportation Safety. See Community Maps for more information: https://CommunityMaps.wi.gov/.

## Basic functionality
Once a week, triggered by a cron job via Github actions, injury and fatality data is pulled from Community Maps. The bot posts a summary of the injuries and fatalities in the preceding week, as well as a running total of the calendar year and tweets that out. The tweet also includes an image with the same data and a second tweet with a disclaimer that data may not include all crashes.

Once a month, using the same data and mechanism, a tweet with monthly stats including a faceted bar graph as an image is sent.

## Potential future features
- [x] include a graph or infographic with the information
  - [ ] Could also be a map
- [ ] tweet other Vision Zero related messages?
- [ ] automatically retweet tweets located in Madison and tagged #VisionZero?

If you have suggestions for a feature, create an [issue in the repository](https://github.com/vgXhc/vision_zero_bot/issues)!
