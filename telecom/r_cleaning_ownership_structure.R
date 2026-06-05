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




#second try


# ---------------------------------------------------------------
# Import ownership_structure.dat (All columns kept)
# ---------------------------------------------------------------

ownership_structure <- read_delim(
  file = file.path(data, "cdbs_files/ownership_structure.dat"),
  delim = "|",
  col_names = FALSE,
  col_types = cols(.default = col_character()),
  quote = "",
  locale = locale(encoding = "ISO-8859-1")
)

# Define a vector for the first 16 column names
first_16_names <- c(
  "ownership_structure_id", "application_id", "name_address", 
  "gender_flg", "ethnicity_flg", "race_flg", "citizenship", 
  "positional_int", "votes_perc", "equity_perc", "active_ind", 
  "office_held", "interest_perc", "occupation", "appointed_by", 
  "existing_interests"
)

# Rename the first 16 positions, leaving remaining columns untouched (e.g., X17, X18...)
colnames(ownership_structure)[1:16] <- first_16_names

ownership_structure <- ownership_structure %>%
  mutate(
    ownership_structure_id = as.integer(ownership_structure_id),
    application_id         = as.integer(application_id),
    votes_perc             = as.numeric(votes_perc),
    equity_perc            = as.numeric(equity_perc),
    interest_perc          = as.numeric(interest_perc)
  )

# Save clean Stata file (will now contain all columns)
write_dta(
  ownership_structure,
  file.path(clean, "ownership_structure_clean.dta")
)




#----------------------- 17 names trying to fix the rest of the columns



# 1. Redefine your paths (Crucial step)
PATH  <- "C:/Users/ranya/OneDrive - Alma Mater Studiorum Università di Bologna/Desktop/UNIBO/PFE/US/Work"
data  <- file.path(PATH, "data/raw")
clean <- file.path(PATH, "data/clean")

# 2. Run the updated import code (keeps all columns, renames first 17)
ownership_structure <- read_delim(
  file = file.path(data, "cdbs_files/ownership_structure.dat"),
  delim = "|",
  col_names = FALSE,
  col_types = cols(.default = col_character()),
  quote = "",
  locale = locale(encoding = "ISO-8859-1")
)

# 3. Rename first 16 columns without dropping the rest
first_17_names <- c(
  "ownership_structure_id", "application_id", "name_address", 
  "gender_flg", "ethnicity_flg", "race_flg", "citizenship", 
  "positional_int", "votes_perc", "equity_perc", "active_ind", 
  "office_held", "interest_perc", "occupation", "appointed_by", 
  "existing_interests", "order_number"
)
colnames(ownership_structure)[1:17] <- first_17_names

# 4. Convert types
ownership_structure <- ownership_structure %>%
  mutate(
    ownership_structure_id = as.integer(ownership_structure_id),
    application_id         = as.integer(application_id),
    votes_perc             = as.numeric(votes_perc),
    equity_perc            = as.numeric(equity_perc),
    interest_perc          = as.numeric(interest_perc),
    order_number = as.integer(order_number)
  )

# 5. Save the complete dataset to Stata
write_dta(
  ownership_structure,
  file.path(clean, "ownership_structure_clean2.dta")
)



#identifying the new columns 


# Number of non-missing values in each column

col_summary <- data.frame(
  variable = names(ownership_structure),
  non_missing = sapply(ownership_structure,
                       function(x) sum(!is.na(x) & trimws(x) != "")),
  unique_values = sapply(ownership_structure,
                         function(x) length(unique(na.omit(x))))
)

col_summary


col_summary %>%
  filter(variable %in% paste0("X", 19:50))


for(v in paste0("X",19:50)) {
  
  cat("\n\n====================\n")
  cat(v,"\n")
  cat("====================\n")
  
  print(
    sort(table(ownership_structure[[v]]), decreasing=TRUE)[1:20]
  )
  
}



#check

table(ownership_structure$X33, useNA = "ifany")

# testing old /new table

ownership_structure %>%
  summarise(
    old_layout = sum(!is.na(office_held) & office_held != ""),
    new_layout = sum(!is.na(X40) & X40 != "")
  )

table(
  old = !is.na(ownership_structure$office_held) &
    ownership_structure$office_held != "",
  
  new = !is.na(ownership_structure$X40) &
    ownership_structure$X40 != ""
)

#If old-layout variables are populated,new-layout variables are never populated.

