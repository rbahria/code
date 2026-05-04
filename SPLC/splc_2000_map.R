# =========================
# SPLC mapping
# =========================

library(tidyverse)
library(tigris)
library(sf)
library(ggplot2)

options(tigris_use_cache = TRUE)

# working directory
setwd("C:/Users/ranya/OneDrive - Alma Mater Studiorum Università di Bologna/Desktop/UNIBO/PFE/US/Work")
splc <- read_csv("data/raw/splc/splc_hate_data_2000_saved.csv")


# quick check
glimpse(splc)

splc %>%
  summarise(
    total = n(),
    unique_counties = n_distinct(county_fips),
    missing_fips = sum(is.na(county_fips))
  )

#collapse to county
splc_county_counts <- splc %>%
  filter(!is.na(county_fips)) %>%
  count(county_fips, name = "splc_count")

#loading county polygons
us_counties <- counties(cb = TRUE, year = 2000) %>%
  mutate(
    county_fips = paste0(STATEFP, COUNTYFP)
  )


# keep contiguous US only
us_counties_mainland <- us_counties %>%
  filter(!STATEFP %in% c("02", "15", "72"))

# join counts
splc_county_map <- us_counties_mainland %>%
  left_join(splc_county_counts, by = "county_fips") %>%
  mutate(
    splc_count = replace_na(splc_count, 0)
  )

#------county centroids + bubble size

color1 <- "#008C8C"   # deep teal
color2 <- "#82AAA0"   # sage green
color3 <- "#BE963C"   # deep gold
color4 <- "#DCC8A0"   # sandy beige
color5 <- "#A06464"   # muted rose

# centroids for bubbles
splc_centroids <- splc_county_map %>%
  filter(splc_count > 0) %>%
  st_point_on_surface()

# plot
ggplot() +
  geom_sf(data = us_counties_mainland, fill = "#e9e1d2", color = "white", linewidth = 0.15) +
  geom_sf(
    data = splc_centroids,
    aes(size = splc_count),
    color = "#008C8C",
    alpha = 0.85
  ) +
  geom_sf_text(
    data = splc_centroids %>% filter(splc_count >= 4),
    aes(label = splc_count),
    color = "white",
    size = 2.2,
    fontface = "bold"
  ) +
  scale_size_area(max_size = 10, name = "Hate groups") +
  coord_sf(xlim = c(-125, -66), ylim = c(24, 50), expand = FALSE) +
  labs(
    title = "Hate groups by county",
    subtitle = "United States, 2000"
  ) +
  theme_void() +
  theme(
    legend.position = "none",
    plot.title = element_text(size = 16, hjust = 0.5),
    plot.subtitle = element_text(size = 11,hjust = 0.5)
  )


##########################  2016 ###################################


splc_2016 <- read_csv("data/raw/splc/splc-hate-groups-2016_county.csv")

names(splc_2016)

splc_2016 <- splc_2016 %>%
  select(-`state_code...28`) %>%
  rename(state_code = `state_code...27`) %>%
  mutate(
    state_code = str_pad(as.character(state_code), 2, pad = "0"),
    FIPS_county_code = str_pad(as.character(FIPS_county_code), 3, pad = "0"),
    county_fips = paste0(state_code, FIPS_county_code)
  )


splc_2016_county_counts <- splc_2016 %>%
  filter(!is.na(county_fips)) %>%
  count(county_fips, name = "splc_count")

us_counties <- counties(cb = TRUE, year = 2016) %>%
  filter(!STATEFP %in% c("02", "15", "72")) %>%
  mutate(county_fips = paste0(STATEFP, COUNTYFP))

splc_2016_map <- us_counties %>%
  left_join(splc_2016_county_counts, by = "county_fips") %>%
  mutate(splc_count = replace_na(splc_count, 0))

splc_2016_centroids <- splc_2016_map %>%
  filter(splc_count > 0) %>%
  st_point_on_surface()

#centroid might be a wrong
ggplot() +
  geom_sf(data = us_counties, fill = "#e7dfd2", color = "white", linewidth = 0.2) +
  geom_sf(
    data = splc_2016_centroids,
    aes(size = splc_count),
    color = "#A06464",
    alpha = 0.85
  ) +
  geom_sf_text(
    data = splc_2016_centroids %>% filter(splc_count >= 4),
    aes(label = splc_count),
    color = "white",
    size = 2.2,
    fontface = "bold"
  ) +
  scale_size_area(max_size = 10, name = NULL) +
  coord_sf(xlim = c(-125, -66), ylim = c(24, 50), expand = FALSE) +
  labs(title = "Hate groups by county",
       subtitle = "United States, 2016") +
  theme_void() +
  theme(
    legend.position = "none",
    plot.title = element_text(size = 16,hjust = 0.5),
    plot.subtitle = element_text(size = 11,hjust = 0.5)
  )


#-------- fixing the centroid but the bubble too big
us_counties_proj <- us_counties %>%
  st_transform(5070)

splc_2016_centroids <- us_counties_proj %>%
  left_join(splc_2016_county_counts, by = "county_fips") %>%
  mutate(splc_count = replace_na(splc_count, 0)) %>%
  filter(splc_count > 0) %>%
  st_point_on_surface() %>%
  st_transform(4326)


ggplot() +
  geom_sf(data = us_counties, fill = "#e7dfd2", color = "white", linewidth = 0.2) +
  geom_sf(
    data = splc_2016_centroids,
    aes(size = splc_count),
    color = "darkblue",
    alpha = 0.85
  ) +
  geom_sf_text(
    data = splc_2016_centroids %>% filter(splc_count >= 3),
    aes(label = splc_count),
    color = "white",
    size = 2.2,
    fontface = "bold"
  ) +
  scale_size_area(max_size = 10, name = NULL) +
  coord_sf(xlim = c(-125, -66), ylim = c(24, 50), expand = FALSE) +
  labs(title = "Hate groups by county",
       subtitle = "United States, 2016") +
  theme_void() +
  theme(
    legend.position = "none",
    plot.title = element_text(size = 16),
    plot.subtitle = element_text(size = 11)
  )
