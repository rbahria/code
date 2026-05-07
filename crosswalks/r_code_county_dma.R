#----------------------------------------------------------------

# Need to :
#           -->   add the dma numeric code to dmas 
#           --> since this is from 2016 maybe the county boundaries are very
#different from the adjusted boundaries from 2000 I did on stata

#-----------------------------------------------------------------


library(readr)
library(dplyr)
library(tidyr)
library(stringr)

setwd("C:/Users/ranya/OneDrive - Alma Mater Studiorum Università di Bologna/Desktop/UNIBO/PFE/US/Work")

txt <- read_file("data/crosswalks/dma/nielsen_2016")  


dma_raw <- tibble(line = str_split(txt, "\\r?\\n")[[1]]) %>% #cut whenever there 
  #is a new line
  filter(str_detect(line, "--")) %>%
  separate(
    line,
    into = c("dma", "county_names"),
    sep = "\\s*--\\s*",
    extra = "merge",
    fill = "right"
  ) %>%
  mutate(
    dma = str_trim(dma),
    county_names = str_remove(county_names, "\\.$"), #removing the last .
    county_names = str_squish(county_names)
  )

head(dma_raw)

write_csv(dma_raw, "data/raw/dma/dma_counties_2016_raw.csv")