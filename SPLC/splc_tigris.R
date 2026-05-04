# =========================
# SPLC 2000 -> county FIPS
#cleaning splc raw file
# =========================


#install.packages(c("tidyverse", "tidygeocoder", "tigris", "sf"))

library(tidyverse)
library(tidygeocoder)
library(tigris)
library(sf)

options(tigris_use_cache = TRUE)


setwd("C:/Users/ranya/OneDrive - Alma Mater Studiorum Università di Bologna/Desktop/UNIBO/PFE/US/robustness/splc hate")
df <- read_csv("splc_hate_data_2000.csv", col_types = cols(ein = col_character()))

# Clean basic strings
df <- df %>%
  mutate(
    city_name = str_squish(city_name),
    state_name = str_squish(state_name)
  )

#  Geocode city/state rows
df_geocoded <- df %>%
  geocode(city = city_name, state = state_name, method = "osm")

#  Separate successful and failed geocodes
df_ok <- df_geocoded %>%
  filter(!is.na(lat) & !is.na(long))

df_fail <- df_geocoded %>%
  filter(is.na(lat) | is.na(long)) %>%
  mutate(
    type = case_when(
      is.na(city_name) ~ "missing",
      city_name %in% c("undefined", "Unknown", "") ~ "missing",
      str_detect(city_name, "County") ~ "county",
      str_detect(city_name, "/") ~ "multiple",
      str_detect(city_name, regex("north|south|east|west|central", ignore_case = TRUE)) ~ "region",
      TRUE ~ "city"
    )
  )

View(df_fail)

# Build county and state references from TIGER
us_counties <- counties(cb = TRUE, year = 2000)
us_states   <- states(cb = TRUE, year = 2000)

county_ref <- us_counties %>%
  st_drop_geometry() %>%
  mutate(
    county_fips = paste0(STATEFP, COUNTYFP)
  ) %>%
  transmute(
    state_fips = STATEFP,
    county_name = NAME,
    county_fips
  )

states_ref <- us_states %>%
  st_drop_geometry() %>%
  mutate(
    state_fips = sprintf("%02d", as.integer(STATE))
  ) %>%
  transmute(
    state_name = NAME,
    state_fips
  )

# County rows: direct string matching to county reference
df_county <- df_fail %>%
  filter(type == "county") %>%
  mutate(
    state_name = str_squish(state_name),
    county_name = str_remove(city_name, " County$"),
    county_name = case_when(
      county_name == "Emore" ~ "Elmore",
      TRUE ~ county_name
    )
  )

df_county_final <- df_county %>%
  left_join(states_ref, by = "state_name") %>%
  left_join(county_ref, by = c("state_fips", "county_name")) %>%
  mutate(source_match = "county_string")

#  Successful city geocodes: spatial join to counties
# transform points to sf
df_points <- df_ok %>%
  st_as_sf(coords = c("long", "lat"), crs = 4326, remove = FALSE)

# match CRS
df_points <- st_transform(df_points, st_crs(us_counties))

# spatial join
df_points_joined <- st_join(
  df_points,
  us_counties %>% select(NAME, STATEFP, COUNTYFP),
  join = st_within,
  left = TRUE
) %>%
  mutate(
    county_fips = paste0(STATEFP, COUNTYFP),
    county_name = NAME,
    source_match = "city_geocode"
  )

df_city_final <- df_points_joined %>%
  st_drop_geometry()

#  Remaining failed rows that still need manual review
df_unresolved <- df_fail %>%
  filter(type %in% c("city", "multiple", "region", "missing")) %>%
  mutate(source_match = "manual_review")

#  Combine clean county-level outputs
splc_county_ready <- bind_rows(
  df_city_final %>%
    mutate(final_status = if_else(is.na(county_fips), "unmatched", "matched")),
  
  df_county_final %>%
    mutate(final_status = if_else(is.na(county_fips), "unmatched", "matched"))
)

#  Save outputs
write_csv(splc_county_ready, "splc_2000_county_ready.csv")
write_csv(df_unresolved, "splc_2000_manual_review.csv")

# optional .RDS saves
saveRDS(splc_county_ready, "splc_2000_county_ready.rds")
saveRDS(df_unresolved, "splc_2000_manual_review.rds")

#  Diagnostics
cat("\n=== MATCH SUMMARY ===\n")
splc_county_ready %>%
  count(source_match, final_status) %>%
  print(n = Inf)

cat("\n=== UNRESOLVED TYPES ===\n")
df_unresolved %>%
  count(type) %>%
  print(n = Inf)

cat("\n=== COUNTY ROWS STILL UNMATCHED ===\n")
df_county_final %>%
  filter(is.na(county_fips)) %>%
  select(city_name, state_name, county_name, state_fips) %>%
  print(n = Inf)

cat("\n=== CITY POINTS STILL UNMATCHED AFTER SPATIAL JOIN ===\n")
df_city_final %>%
  filter(is.na(county_fips)) %>%
  select(city_name, state_name, lat, long) %>%
  print(n = Inf)




#------------------------Fix the faulty ones

df_unresolved <- df_fail %>%
  filter(type %in% c("city", "multiple", "region", "missing"))

#inspect the unesolved
df_unresolved %>%
  select(city_name, state_name, type) %>%
  arrange(type, state_name) %>%
  print(n = Inf)

df_multiple_county <- df_unresolved %>%
  filter(city_name == "Wise/Denton counties")


# fix cities

df_unresolved_fixed <- df_unresolved %>%
  filter(type !="multiple") %>%
  mutate(
    city_clean = case_when(
      
      # --- Alabama
      city_name == "Atalla" ~ "Attalla",
      
      # --- Arizona
      city_name == "Tuscon" ~ "Tucson",
      
      # --- California
      city_name == "Monroula" ~ "Monrovia",
      
      # --- Florida
      city_name == "Tampa Bay" ~ "Tampa",
      
      # --- Illinois
      city_name == "Prospects Heights" ~ "Prospect Heights",
      
      # --- Massachusetts
      city_name == "Cape Cod" ~ "Barnstable",
      
      # --- Mississippi
      city_name == "Byrum" ~ "Byram",
      
      # --- Missouri
      city_name == "Clarkston" ~ "Clarkson Valley",
      
      # --- Montana
      city_name == "Moxon" ~ "Maxon",
      city_name == "Big Fork" ~ "Bigfork",
      
      # --- New Jersey
      city_name == "New Brunswich" ~ "New Brunswick",
      
      # --- New York
      city_name == "Warwich" ~ "Warwick",
      city_name == "Binhamton" ~ "Binghamton",
      
      # --- North Carolina
      city_name == "Millspring" ~ "Mill Spring",
      city_name == "Culluwhee" ~ "Cullowhee",
      city_name == "Elon College" ~ "Elon",
      
      # --- Ohio
      city_name == "Ameilia" ~ "Amelia",
      city_name == "Richmondale" ~ "Richmond Dale",
      
      # --- South Carolina (NOT real cities → pick anchors)
      city_name == "lowcountry chapter" ~ "Charleston",
      city_name == "upcountry chapter" ~ "Greenville",
      
      # --- Tennessee
      city_name == "Pulaska" ~ "Pulaski",
      
      # --- Texas
      city_name == "Waxahatchie" ~ "Waxahachie",
      city_name == "LaMarque" ~ "La Marque",
      
      # --- Virginia
      city_name == "Bayse" ~ "Basye",
      
      # --- Louisiana
      city_name == "West Wego" ~ "Westwego",
      
      # --- Minnesota
      city_name == "North Baport" ~ "Bayport",
      
      # --- REGIONS
      city_name == "northern Mississippi" ~ "Oxford",
      city_name == "eastern North Carolina" ~ "Greenville",
      
      
      # --- fallback
      TRUE ~ city_name
    )
  )

#multiple counties

df_multiple <- df_unresolved %>%
  filter(type == "multiple")

# Willard/Sandusky -> Huron County + Sandusky County, Ohio
willard_sandusky_base <- df_multiple %>%
  filter(city_name == "Willard/Sandusky") %>%
  slice(1)

willard_sandusky_fix <- bind_rows(
  willard_sandusky_base,
  willard_sandusky_base
) %>%
  mutate(
    county_fips = c("39077", "39143"),   # Huron County, OH ; Sandusky County, OH
    source_match = "manual_fix_split",
    final_status = "matched"
  )

# Wise/Denton counties -> Wise County + Denton County, Texas
wise_denton_base <- df_multiple %>%
  filter(city_name == "Wise/Denton counties") %>%
  slice(1)

wise_denton_fix <- bind_rows(
  wise_denton_base,
  wise_denton_base
) %>%
  mutate(
    county_fips = c("48497", "48121"),   # Wise County, TX ; Denton County, TX
    source_match = "manual_fix_split",
    final_status = "matched"
  )

df_multiple_fixed <- bind_rows(
  willard_sandusky_fix,
  wise_denton_fix
)




#regeocode
df_regeo <- df_unresolved_fixed %>%
  filter(type != "missing") %>%
  geocode(city = city_clean, state = state_name, method = "osm")

#check


names(df_regeo)
df_regeo <- df_regeo %>%
  rename(
    lat = `lat...11`,
    long = `long...12`
  )


df_regeo %>%
  summarise(
    total = n(),
    success = sum(!is.na(lat)),
    failed = sum(is.na(lat))
  )


#assigning fips
df_regeo_sf <- df_regeo %>%
  filter(!is.na(lat), !is.na(long)) %>%
  st_as_sf(coords = c("long", "lat"), crs = 4326)

df_regeo_sf <- st_transform(df_regeo_sf, st_crs(us_counties))

df_regeo_joined <- st_join(
  df_regeo_sf,
  us_counties %>% select(STATEFP, COUNTYFP),
  
  join = st_within,
  left = TRUE
) %>%
  mutate(
    county_fips = paste0(STATEFP, COUNTYFP),
    source_match = "manual_fix"
  ) %>%
  st_drop_geometry()

#aappend
splc_final <- bind_rows(
  splc_county_ready,
  df_regeo_joined %>% mutate(final_status = "matched"),
  df_multiple_fixed
)

splc_final %>%
  summarise(
    total = n(),
    matched = sum(!is.na(county_fips)),
    unmatched = sum(is.na(county_fips))
  )

#view and save
View(splc_final)

splc_final <- splc_final %>% #fips string
  mutate(
    county_fips = str_pad(as.character(county_fips), width = 5, pad = "0")
  )

write_csv(splc_final, "C:/Users/ranya/OneDrive - Alma Mater Studiorum Università di Bologna/Desktop/UNIBO/PFE/US/Work/data/raw/SPLC/splc_hate_data_2000_saved.csv")
