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



#check entries of each column

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

#-->If old-layout variables are populated,new-layout variables are never populated.



# entries with neither layout filled in
ownership_structure %>%
  filter(
    (is.na(office_held) | office_held == "") &
      (is.na(X33) | X33 == "")
  ) %>%
  select(1:20) %>%
  head(20)

# create a flag for neww/old table entries 



# Most common values in office_held

sort(table(ownership_structure$office_held),
     decreasing = TRUE)[1:30]

# Most common values in X33

sort(table(ownership_structure$X33),
     decreasing = TRUE)[1:30]


#positional int and x33

# First 30 non-empty positional_int values

ownership_structure %>%
  filter(!is.na(positional_int),
         positional_int != "",
         positional_int != "N/A") %>%
  distinct(positional_int) %>%
  slice(1:30)

# First 30 non-empty X33 values

ownership_structure %>%
  filter(!is.na(X33),
         X33 != "") %>%
  distinct(X33) %>%
  slice(1:30)

#figuring out the X flags

flag_cols <- paste0("X",22:32)

sapply(
  ownership_structure[flag_cols],
  function(x) sum(x == "X", na.rm = TRUE)
)

for(v in paste0("X",22:32)) {
  
  cat("\n\n",v,"\n")
  
  print(
    ownership_structure %>%
      filter(.data[[v]] == "X") %>%
      count(X33, sort = TRUE) %>%
      head(10)
  )
  
}


table(ownership_structure$X34, useNA="ifany")
ownership_structure %>%
  filter(!is.na(X33)) %>%
  count(X34, X33, sort=TRUE)

ownership_structure %>%
  count(X21, X34, sort = TRUE) #-> X34 not eprson/entity/


ownership_structure %>%
  filter(X34=="P") %>%
  count(X33, sort=TRUE) %>%
  print(n=30)

ownership_structure %>%
  filter(X34=="L") %>%
  count(X33, sort=TRUE) %>%
  print(n=30)

ownership_structure %>%
  filter(X34=="E") %>%
  count(X33, sort=TRUE) %>%
  print(n=30)


#checking empty equity / interest/vote
ownership_structure %>%
  summarise(
    votes_nonmissing    = sum(!is.na(votes_perc)),
    equity_nonmissing   = sum(!is.na(equity_perc)),
    interest_nonmissing = sum(!is.na(interest_perc))
  )


ownership_structure %>%
  mutate(
    new_schema = !is.na(X20)
  ) %>%
  group_by(new_schema) %>%
  summarise(
    n = n(),
    votes_nonmissing    = sum(!is.na(votes_perc)),
    equity_nonmissing   = sum(!is.na(equity_perc)),
    interest_nonmissing = sum(!is.na(interest_perc))
  )