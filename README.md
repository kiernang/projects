# Intro
I've been finding it difficult to communicate the severity of the recent spike in COVID-19 infections in Manitoba (where I live) to people that are not from Manitoba. The majority of my colleagues live in Ontario, with one in Vancouver, my girlfriend lives in Germany, and my best friend lives in Norway. I also find it cumbersome to calculate the rate of infection per 100,000. Bartley Kives of CBC Manitoba has been tweeting what the equivalent number of infections would be if Manitoba had the same size of population as Ontario recently, which I found far more intuitive. I used publicly available to data, updated daily, to calculate what the equivalent number of daily cases would be in Manitoba if the population was equal to a given region.
# Data
I use publicly available data from John Hopkins University. I group American data at the state level to calculate the daily increase per given state. The data is updated everyday at 11:59 pm UTC. You can find the data [here.](https://github.com/CSSEGISandData/COVID-19)

# Methodology
Fairly straightforward methodology. To calculate the scaled number of cases in Manitoba, I multiply the number of cases in Manitoba per given day by the ratio between the population of the selected region and Manitoba. I.e. Cases_Daily* (Pop_notMB/Pop_MB)

# Other Considerations
I am not a dashboard developer, so this may be a little janky. I didn't really want to figure out how to cache the data so the dashboard takes a little while to load as the script is actually executing in place.  ¯\_(ツ)_/¯.

