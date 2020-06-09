library(tidyr)
library(dplyr)
library(wesanderson)
library(ggplot2)
#I've downloaded a list of 311 (City Services) calls from the City of Winnipeg's open data site
calls311 <- read_csv("~/Downloads/311_Service_Request.csv")
#Few issues. One: there are spaces in variable names; Two: the coordinates are jumbled.
# Additionally, I personally find it annoying when variable names are not in lowercase
names(calls311) <- tolower(names(calls311))
names(calls311) <- gsub(' ', '_', names(calls311))
# Now that the variable names are cleaned up, onto cleaning up the coordinate data
# A quicker way to do this is to just use a nested gsub command
calls311$location_1 <- gsub('\\)','',gsub('\\(','',calls311$location_1))
calls311<- calls311 %>%
separate(location_1, c('latitude','longitude'), ', ')
calls311$date <- as.POSIXct(calls311$date, tz = "America/Winnipeg", "%m/%d/%Y %I:%M:%S %p")
# Cool, now we can just see which neighbourhoods called 311 the most
most_calls <- calls311 %>%
group_by(neighbourhood) %>%
tally() %>%
top_n(5)
ggplot(most_calls, aes(neighbourhood, n)) + geom_col(fill = "deepskyblue4") + labs( x = "Neighbourhood", y = "Number of Calls to 311", title = "Calls to 311 by Neighbourhood, 2018 - 2019")
#Okay, so William Whyte has by far the most amount of calls to 311. Let's see what's the deal there.
will_whyte <- calls311[calls311$neighbourhood=="William Whyte",]
will_whyte_most <- will_whyte %>%
group_by(service_request) %>%
tally() %>%
top_n(5)
wwplot <- ggplot(will_whyte_most, aes(service_request, n)) + geom_col( fill = "#0072B2") + labs( x = "Type of Complaint", y = "Number of Calls to 311", title = "William Whyte 311 Calls, 2018 - 2019")
wwplot + theme(axis.text.x = element_text(face = "bold", color = "#993333", size = 8, angle = 20, hjust = 1))
