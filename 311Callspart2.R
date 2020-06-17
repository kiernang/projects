#Building a full neighbourhood characteristic dataset
#Starting with income which was pre-cleaned sort of
income_neighbourhoods <- read_excel("~/Downloads/2011 Income by Neighbourhood.xlsx")
names(income_neighbourhoods) <- tolower(names(income_neighbourhoods))
names(income_neighbourhoods) <- gsub(" ", "_", names(income_neighbourhoods))
income_neighbourhoods <- subset(income_neighbourhoods, select = -c(`one_parent_-_female...20`, `one_parent_-_male...21`))
income_neighbourhoods <- subset(income_neighbourhoods, select = -c(`one_parent_-_female...9`, `one_parent_-_male...10`))
income_neighbourhoods <- subset(income_neighbourhoods, select = -c(`one_parent_-_female...20`, `one_parent_-_male...21`))
income_neighbourhoods <- subset(income_neighbourhoods, select = -c(`one_parent_-_male...21`))
#Moving onto housing
house_qualities <- read_excel("~/Downloads/2011 Dwelling Condition by Neighbourhood.xls",
na = "-")
names(house_qualities) <- tolower(names(house_qualities))
names(house_qualities) <- gsub(" ", "_", names(house_qualities))
#Onto Rental data
housing_costs <- read_excel("~/Downloads/2011 Dwelling Costs by Neighbourhood.xls")
names(housing_costs)<- tolower(gsub(" ", "_", names(housing_costs)))
names(housing_costs) <- gsub(",","",names(housing_costs))
housing_costs <- housing_costs[-c(194,195),]
#Onto Population
neighbourhood_pop <- read_excel("~/Downloads/2011 Population by Neighbourhood.xls",
na = "-", skip = 22)
names(neighbourhood_pop)<- tolower(gsub(c(" ","-"),"_", names(neighbourhood_pop)))
names(neighbourhood_pop)<- tolower(gsub("-","_", names(neighbourhood_pop)))
neighbourhood_pop <- subset(neighbourhood_pop, select = -c(`#`))

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



