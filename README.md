# vision_zero_bot
A Twitter bot to automatically send out Vision-Zero-related tweets for Madison, using R and GitHub actions.

The instructions [here](https://www.rostrum.blog/2020/09/21/londonmapbot/) were very helpful in figuring this out.

## Current status
The bot is in production status, tweeting a summary tweet once a week on Wednesdays.

## Data
The bot uses data from [Community Maps](https://transportal.cee.wisc.edu/partners/community-maps/crash/search/BasicSearch.do) to gather information about traffic crashes in Madison.

## Basic functionality
Once a week, triggered by a cron job via Github actions, injury and fatality data is pulled from Community Maps. The bot posts a summary of the injuries and fatalities in the preceding week, as well as a running total of the calendar year and tweets that out. The tweet also includes an image with the same data.

## Potential future features
- [x] include a graph or infographic with the information
  - [ ] Could also be a map
- [ ] tweet other Vision Zero related messages?
- [ ] automatically retweet tweets located in Madison and tagged #VisionZero?
