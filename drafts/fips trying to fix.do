************************************************
* Importing and Merging Intercensal DBs
************************************************

import excel "data/raw/population/co-est2020int-pop.xlsx", cellrange(A6:M3148) clear 
keep A B C D E F G H I J K L M

rename A geo
rename C pop2010
rename D pop2011
rename E pop2012
rename F pop2013
rename G pop2014
rename H pop2015
rename I pop2016
rename J pop2017
rename K pop2018
rename L pop2019
rename M pop2020_april

* 1. Basic cleaning
drop if geo == "United States"
split geo, parse(",")
rename geo1 county_name
rename geo2 state_name

* 2. FORCE UPPERCASE IMMEDIATELY (Crucial for matching and subinstr)
replace county_name = upper(trim(county_name))
replace state_name  = upper(trim(state_name))

* 3. Clean suffixes while in UPPERCASE
replace county_name = substr(county_name, 2, .) if substr(county_name,1,1) == "."
foreach suffix in " COUNTY" " PARISH" " BOROUGH" " CENSUS AREA" " MUNICIPALITY" " CITY AND" {
    replace county_name = subinstr(county_name, "`suffix'", "", .)
}

* 4. Saint Format Fix (Matching Master's "SAINT" instead of "ST")
replace county_name = subinstr(county_name, "ST. ", "SAINT ", .)
replace county_name = subinstr(county_name, "ST ", "SAINT ", .)
replace county_name = "DONA ANA" if county_name == "DOñA ANA"
replace county_name = "LA SALLE" if county_name == "LASALLE"
replace county_name = "SHANNON" if county_name == "OGLALA LAKOTA"

* 5. McCrary Constant Boundary Mapping (Alaska Splits)
* We rename them to the 2000-era names so they can be summed together
replace county_name = "VALDEZ-CORDOVA" if inlist(county_name, "CHUGACH", "COPPER RIVER")
replace county_name = "WRANGELL-PETERSBURG" if inlist(county_name, "PETERSBURG", "WRANGELL")
replace county_name = "SKAGWAY-HOONAH-ANGOON" if inlist(county_name, "SKAGWAY", "HOONAH-ANGOON")
replace county_name = "PRINCE OF WALES-OUTER KETCHIKAN" if county_name == "PRINCE OF WALES-HYDER"	
replace county_name = "WADE HAMPTON" if county_name == "KUSILVAK"

* 6. Add FIPS (Using state name to be safe)

drop _merge


* 7. Hard-code the Historic FIPS for the McCrary counties
replace fips = 2261 if county_name == "VALDEZ-CORDOVA"
replace fips = 2280 if county_name == "WRANGELL-PETERSBURG"
replace fips = 2232 if county_name == "SKAGWAY-HOONAH-ANGOON"
replace fips = 2201 if county_name == "PRINCE OF WALES-OUTER KETCHIKAN"
replace fips = 2270 if county_name == "WADE HAMPTON"
replace fips = 2020 if county_name == "ANCHORAGE" & state_name == "ALASKA"

* 8. THE SQUASH (Collapse)
* This is the vital step: it sums the population of split counties into one row
collapse (sum) pop*, by(fips state_name county_name state_abbrev state_fips)

* 9. Final Formatting
gen fips_str = string(fips, "%05.0f")
drop fips
rename fips_str fips

drop if missing(pop2010)
drop if fips == "" | fips == "."

order fips county_name state_abbrev state_fips
save "data/intermediate/pop2010-2020_clean.dta", replace

* 10. Verification
duplicates report fips