# ---------------------------------------------------------------
# Set up
# ---------------------------------------------------------------

library(readr)
library(dplyr)
library(haven)

PATH <- "C:/Users/ranya/OneDrive - Alma Mater Studiorum Università di Bologna/Desktop/UNIBO/PFE/US/Work"

data   <- file.path(PATH, "data/raw")
clean  <- file.path(PATH, "data/clean")
temp   <- file.path(PATH, "data/temp")
helper <- file.path(PATH, "code/helper")

setwd(PATH)

# ---------------------------------------------------------------
# Import ownership_structure.dat
# ---------------------------------------------------------------

ownership_structure <- read_delim(
  file = file.path(data, "cdbs_files/ownership_structure.dat"),
  delim = "|",
  col_names = FALSE,
  col_types = cols(.default = col_character()),
  quote = "",
  locale = locale(encoding = "ISO-8859-1")
)

ownership_structure <- ownership_structure %>%
  select(1:16) %>%
  rename(
    ownership_structure_id = X1,
    application_id         = X2,
    name_address           = X3,
    gender_flg             = X4,
    ethnicity_flg          = X5,
    race_flg               = X6,
    citizenship            = X7,
    positional_int         = X8,
    votes_perc             = X9,
    equity_perc            = X10,
    active_ind             = X11,
    office_held            = X12,
    interest_perc          = X13,
    occupation             = X14,
    appointed_by           = X15,
    existing_interests     = X16
  ) %>%
  mutate(
    ownership_structure_id = as.integer(ownership_structure_id),
    application_id         = as.integer(application_id),
    votes_perc             = as.numeric(votes_perc),
    equity_perc            = as.numeric(equity_perc),
    interest_perc          = as.numeric(interest_perc)
  )

# Save clean Stata file
write_dta(
  ownership_structure,
  file.path(clean, "ownership_structure_clean.dta")
)