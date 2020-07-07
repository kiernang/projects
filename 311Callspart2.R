library(tidyr)
library(dplyr)
library(wesanderson)
library(ggplot2)
library(ggpubr)
library(readr)
library(ggpattern)
library(readxl)
library(shiny)
library(rgdal)
library(leaflet)
library(stargazer)
#Building a full neighbourhood characteristic dataset
#Starting with income which was pre-cleaned sort of
income_neighbourhoods <- read_excel("~/Downloads/2011 Income by Neighbourhood.xlsx")
names(income_neighbourhoods) <- tolower(names(income_neighbourhoods))
names(income_neighbourhoods) <- gsub(" ", "_", names(income_neighbourhoods))
income_neighbourhoods$neighbourhood <- gsub(" - ", "-", income_neighbourhoods$neighbourhood)
income_neighbourhoods <- subset(income_neighbourhoods, select = -c(`one_parent_-_female...20`, `one_parent_-_male...21`))
income_neighbourhoods <- subset(income_neighbourhoods, select = -c(`one_parent_-_female...9`, `one_parent_-_male...10`))
#Moving onto housing
house_qualities <- read_excel("~/Downloads/2011 Dwelling Condition by Neighbourhood.xls",
na = "-")
names(house_qualities) <- tolower(names(house_qualities))
names(house_qualities) <- gsub(" ", "_", names(house_qualities))
house_qualities$neighbourhood <- gsub(" - ", "-", house_qualities$neighbourhood)
#Onto Rental data
housing_costs <- read_excel("~/Downloads/2011 Dwelling Costs by Neighbourhood.xls")
names(housing_costs)<- tolower(gsub(" ", "_", names(housing_costs)))
names(housing_costs) <- gsub(",","",names(housing_costs))
housing_costs <- housing_costs[-c(194,195),]
housing_costs$neighbourhood <- gsub(" - ", "-", housing_costs$neighbourhood)
#Onto Population
neighbourhood_pop <- read_excel("~/Downloads/2011 Population by Neighbourhood.xls",
na = "-", skip = 22)
names(neighbourhood_pop)<- tolower(gsub(c(" ","-"),"_", names(neighbourhood_pop)))
names(neighbourhood_pop)<- tolower(gsub("-","_", names(neighbourhood_pop)))
neighbourhood_pop <- subset(neighbourhood_pop, select = -c(`#`))
neighbourhood_pop$neighbourhood <- gsub(" - ", "-", income_neighbourhoods$neighbourhood)

#Onto 60 +
pop_60 <- read_excel("~/Downloads/2011 Population Age 60 and Over by Neighbourhood.xlsx",
col_types = c("skip", "text", "numeric",
"numeric", "numeric", "numeric",
"skip", "numeric", "skip", "numeric",
"skip", "numeric", "skip", "numeric",
"skip", "numeric", "skip", "skip"),
na = "-", skip = 23)
names(pop_60)<-tolower(gsub(" ","_", names(pop_60)))
pop_60 <- subset(pop_60, select = -c(percent_of_total_population________60_and_over))
pop_60$neighbourhood <- gsub(" - ", "-", pop_60$neighbourhood)
#Prepping objects for merging
income_premerge <- subset(income_neighbourhoods, select  = c(neighbourhood, average_income,median_income,low_inc_1864))
pop_60_premerge<- subset(pop_60, select = c(neighbourhood, total_population, population_age_60_and_over))
names(housing_costs) <-gsub("-","_",names(housing_costs))
names(housing_costs) <-gsub("\n","",names(housing_costs))
housing_costs_premerge <- subset(housing_costs, select = c(neighbourhood, percent_of_occupied_private_dwellings_that_are_rented, average_gross_rent, tenant_occupied_non_farm_non_reserve_dwellings, average_value_of_dwelling, average_owner_major_payments, owner_occupied_non_farm_non_reserve_dwellings))
neighbourhood_pop_premerge <- subset(neighbourhood_pop, select = c(1,2,4,5))
house_qualities_premerge <- subset(house_qualities, select = c(1,2,3,4,5,10))

#Merging datasets
merged_neighbourhood <- right_join(income_premerge,pop_60_premerge)
merged_neighbourhood <- right_join(merged_neighbourhood,housing_costs_premerge)
merged_neighbourhood <- right_join(merged_neighbourhood,house_qualities_premerge)
merged_neighbourhood <- rename(merged_neighbourhood, rental_rate = percent_of_occupied_private_dwellings_that_are_rented)
merged_neighbourhood <- merged_neighbourhood %>%
mutate(low_income_rate = (low_inc_1864/total_population), avg_payment = ((rental_rate*average_gross_rent) + (1-rental_rate)*average_owner_major_payments), deprec_rate = dwellings_requiring_major_repairs/total_occupied_private_dwellings, old_house_stock = before_1960/total_occupied_private_dwellings, new_house_stock = y2006_2011/total_occupied_private_dwellings)
# Adding in our other dataset..
calls311 <-read_csv("~/Downloads/311_Service_Request201819.csv")
names(calls311) <- tolower(names(calls311))
names(calls311) <- gsub(' ', '_', names(calls311))
calls311$location_1 <- gsub('\\)','',gsub('\\(','',calls311$location_1))
calls311<- calls311 %>%
  separate(location_1, c('latitude','longitude'), ', ')
calls311$date <- as.POSIXct(calls311$date, tz = "America/Winnipeg", "%m/%d/%Y %I:%M:%S %p")
calls_by_day <-  calls311 %>% count(day_of_year = as.Date(date))
day_plot <-ggplot(calls_by_day,aes(day_of_year,n))+geom_line(colour = "darkorchid4")+labs(title = "Daily 311 Calls", subtitle = "2018 - 2019", x = "Day of Year", y = "Number of Calls") + theme(plot.margin = unit(c(.5,4,.5,.5), "cm"))
calls_premerge_true <- calls311 %>% group_by(neighbourhood) %>%
tally()
calls_premerge_true$neighbourhood[calls_premerge_true$neighbourhood == 'Logan-C.p.r.'] <- "Logan-C.P.R."
merged_neighbourhood <-right_join(merged_neighbourhood, calls_premerge_true)
merged_neighbourhood <- rename(merged_neighbourhood, calls = n)
#Wealthiest Neighbourhoods
wealthiest <- merged_neighbourhood %>%
top_n(n = 6, wt = median_income)
#Poorest Neighbourhoods
poorest <- merged_neighbourhood %>%
top_n(n = -6, wt = median_income) %>%
arrange(desc(median_income))
# setting the quintiles
merged_neighbourhood <- merged_neighbourhood %>%
mutate(income_quintile = ntile(median_income,5))

# I also have housing price data, assessed value data, and tree counts.
tree_inventory <- read_csv("~/Downloads/Tree_Inventory.csv")
names(tree_inventory) <- tolower(names(tree_inventory))
names(tree_inventory) <- gsub(' ', '_', names(tree_inventory))
tree_inventory <- tree_inventory %>% group_by(neighbourhood) %>% tally()
tree_inventory$neighbourhood[tree_inventory$neighbourhood == "St. John'S"] <- "St. John's"
tree_inventory$neighbourhood[tree_inventory$neighbourhood == "St. John'S Park"] <- "St. John's Park"
tree_inventory$neighbourhood[tree_inventory$neighbourhood == "Omand'S Creek Industrial"] <- "Omand's Creek Industrial"
merged_neighbourhood <-full_join(merged_neighbourhood, tree_inventory)
merged_neighbourhood <- rename(merged_neighbourhood, tree_count = n)
analysis_set <- merged_neighbourhood[!is.na(merged_neighbourhood$income_quintile),]
### T test efunction
multi.tests <- function(fun = t.test, df, vars, group.var, ...) {
  sapply(simplify = FALSE,                                    # sapply(simplify=T) better, elements named
         vars,                                                # loop on vector of outcome variable names
         function(var) {
           formula <- as.formula(paste(var, "~", group.var))# create a formula with outcome and grouping var.
           fun(data = df, formula, ...)                     # perform test with a given fun, default t.test
         }
  )
}
test_set <- filter(merged_neighbourhood, (income_quintile == 1 | income_quintile == 5))
test_set$group <- ifelse(test_set$income_quintile == 1, "Poor", "Rich")

tests<- multi.tests(fun = t.test, df = test_set,
vars = c("total_population", "population_age_60_and_over", "rental_rate", "old_house_stock", "calls", "tree_count"),
group.var =  "group"
)
tab <- map_df(tests, tidy)
names(tab) <- c("Difference", "Low Income Mean", "High Income Mean", "T-score", "P Value", "Degrees of Freedom", "Lower Estimate", "Upper Estimate", "Method", "Alternative")
tab <- as.data.frame(tab)
rownames(tab) <- c("Total Population", "Population age 60+", "Rental Rate", "Old House Stock", "Calls", "Tree Count")
tab<- tab[,1:8]
tab$`P Value` <- round(tab$`P Value`, 5)
tab[,1:3] <- round(tab[,1:3], 2)
tab[,4] <- round(tab[,4], 4)
tab[,6:8] <- round(tab[,6:8], 4)
non_log_model <- lm(calls ~ median_income + total_population + population_age_60_and_over + rental_rate + old_house_stock + tree_count + deprec_rate, data = merged_neighbourhood)
log_model <- lm(log1p(calls) ~ log1p(median_income) + log1p(total_population) + log1p(population_age_60_and_over) + rental_rate + old_house_stock + log1p(tree_count) + deprec_rate, data = merged_neighbourhood)
