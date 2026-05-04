install.packages("cdlTools")

library(tidyverse)
library(tidygeocoder) # For Lat/Long
library(cdlTools)     # For FIPS codes

setwd("C:/Users/ranya/OneDrive - Alma Mater Studiorum Università di Bologna/Desktop/UNIBO/PFE/US/robustness/splc hate")


df <- read_csv("splc_hate_data_2000.csv", col_types = cols(ein = col_character()))

# Clean up city/state names for better matching
df <- df %>%
  mutate(full_address = paste(city_name, state_name, "USA", sep = ", "))

# This creates the 'lat' and 'long' 
df_geocoded <- df %>%
  geocode(city = city_name, state = state_name, method = 'osm')

# Convert state/county names to the numerical FIPS codes
df_final <- df_geocoded %>%
  mutate(county_fips = fips(state_name, to = "FIPS"))


#inspecting the NAs

df_geocoded %>%
  filter(is.na(lat) | is.na(long)) %>%
  select(city_name, state_name)

#count them
df_geocoded %>%
  summarise(
    total = n(),
    failed = sum(is.na(lat) | is.na(long)),
    success = sum(!is.na(lat) & !is.na(long))
  )
# success and fail dataset
df_ok <- df_geocoded %>%
  filter(!is.na(lat) & !is.na(long))

df_fail <- df_geocoded %>%
  filter(is.na(lat) | is.na(long))

#inspecting the failed one
df_fail %>%
  count(state_name, city_name, sort = TRUE)

##################   Fixing             ####################
# some of the SPLC locations are defined at the regional or county level
#these obs were manually constructed to the closest identifiable city or county
#centroid

# classsifying obs
df_fail <- df_geocoded %>%
  filter(is.na(lat) | is.na(long)) %>%
  mutate(
    type = case_when(
      is.na(city_name) ~ "missing",
      city_name %in% c("undefined", "Unknown") ~ "missing",
      str_detect(city_name, "County") ~ "county",
      str_detect(city_name, "/") ~ "multiple",
      str_detect(city_name, regex("north|south|east|west|central", ignore_case = TRUE)) ~ "region",
      TRUE ~ "city"
    )
  )

df_fail %>% count(type)

#cleaning counties
df_county <- df_fail %>%
  filter(type == "county") %>%
  mutate(
    county_clean = str_remove(city_name, " County$")
  )

df_county %>% #inspect
  select(city_name, county_clean, state_name) %>%
  print(n = Inf)

#fixing typos
df_county <- df_county %>%
  mutate(
    county_clean = case_when(
      county_clean == "Emore" ~ "Elmore",
      TRUE ~ county_clean
    )
  )
#generating fips
df_county <- df_county %>%
  mutate(
    county_state = paste(county_clean, state_name, sep = ", "),
    county_fips = fips(county_state, to = "FIPS")
  )
df_county %>%
  select(county_state, county_fips) %>%
  print(n = Inf)



## trying to fix1 

# county rows you already created
df_county <- df_fail %>%
  filter(type == "county") %>%
  mutate(
    county_clean = str_remove(city_name, " County$"),
    county_clean = case_when(
      county_clean == "Emore" ~ "Elmore",
      TRUE ~ county_clean
    )
  )

# reference table from cdlTools
fips_ref <- cdlTools::census2010FIPS %>%
  as_tibble() %>%
  transmute(
    state_abbr = State,
    state_fips = sprintf("%02d", State.ANSI),
    county_fips_3 = sprintf("%03d", County.ANSI),
    county_name = County.Name,
    county_fips = paste0(state_fips, county_fips_3)
  )

# convert state names to abbreviations using cdlTools::fips
df_county2 <- df_county %>%
  mutate(
    state_abbr = cdlTools::fips(state_name, to = "Abbreviation")
  )

# merge on state abbreviation + county name
df_county_final <- df_county2 %>%
  left_join(
    fips_ref,
    by = c("state_abbr", "county_clean" = "county_name")
  )

df_county_final %>%
  select(city_name, county_clean, state_name, state_abbr, county_fips)

###### 2

# start from your county failures
df_county <- df_fail %>%
  filter(type == "county") %>%
  mutate(
    city_name = str_squish(city_name),
    state_name = str_squish(state_name),
    county_clean = str_remove(city_name, " County$"),
    county_clean = case_when(
      county_clean == "Emore" ~ "Elmore",
      TRUE ~ county_clean
    ),
    # use base R state lookup instead of cdlTools::fips()
    state_abbr = state.abb[match(state_name, state.name)]
  )

# build reference table from cdlTools dataset
fips_ref <- cdlTools::census2010FIPS %>%
  as_tibble() %>%
  mutate(
    State = str_squish(State),
    County.Name = str_squish(County.Name),
    state_fips = sprintf("%02d", State.ANSI),
    county_fips_3 = sprintf("%03d", County.ANSI),
    county_fips = paste0(state_fips, county_fips_3)
  )

# first inspect how county names are stored in the reference
fips_ref %>%
  filter(State %in% c("SC", "MS", "AL", "GA", "TX")) %>%
  select(State, County.Name) %>%
  print(n = 50)







############################

# clean cities 
df_city <- df %>%
  filter(type == "city") %>%
  mutate(
    city_name = case_when(
      city_name == "Warwich" ~ "Warwick",
      TRUE ~ city_name
    )
  ) %>%
  geocode(city = city_name, state = state_name, method = "osm")

#regions assigned manually

df_region <- df %>%
  filter(type == "region") %>%
  mutate(
    city_name = case_when(
      city_name == "Tampa Bay" ~ "Tampa",
      city_name == "eastern North Carolina" ~ "Greenville",
      city_name == "northern Mississippi" ~ "Oxford",
      TRUE ~ city_name
    )
  ) %>%
  geocode(city = city_name, state = state_name, method = "osm")


#split multiple cities
df_multi <- df %>%
  filter(type == "multiple") %>%
  mutate(city_name = word(city_name, 1, sep = "/")) %>%
  geocode(city = city_name, state = state_name, method = "osm")