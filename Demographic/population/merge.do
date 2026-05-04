clear all 
set more off

global PATH "C:\Users\ranya\OneDrive - Alma Mater Studiorum Università di Bologna\Desktop\UNIBO\PFE\US\Work"

cd "${PATH}"

**************************************************


* 1.First decade
use "data/intermediate/pop1990_2000.dta", clear

* 2. the second decade
* (1:1 merge because each county only appears once in each wide file)
merge 1:1 fips using "data/intermediate/pop2000-2010.dta"
browse if _merge == 2
drop _merge
* 3.the third decade
merge 1:1 fips using "data/intermediate/pop2010_2020.dta"
browse if _merge == 2

drop _merge
order fips state_name county_name county_fips state_fips

save "data/intermediate/population_totals.dta" , replace

// drop these since not included in UCR hate ccrimes the Virgin Islands, Puerto Rico, the Northern Mariana Islands, American Samoa, and Guam