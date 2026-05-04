clear all 
set more off

global PATH "C:\Users\ranya\OneDrive - Alma Mater Studiorum Università di Bologna\Desktop\UNIBO\PFE\US\Work"

sysdir

cd "${PATH}"

ssc install statastates
ssc install countyfips




************************************************

*    Importing and Merging Intercensal DBs

************************************************

import excel "data/raw/population/co-est2020int-pop.xlsx", cellrange(A6:M3148) clear //2000-2020
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

* cleaning & creating county and state names for fips xwalk later
drop if geo == "United States"
split geo, parse(",")
rename geo1 county_name
rename geo2 state_name

*cleaning county names
replace county_name = trim(county_name)
replace state_name  = trim(state_name)

replace county_name = substr(county_name, 2, .) if substr(county_name,1,1) == "."
replace county_name = subinstr(county_name, " County", "", .)
replace county_name = subinstr(county_name, " Parish", "", .)
replace county_name = subinstr(county_name, " Borough", "", .)
replace county_name = subinstr(county_name, " Census Area", "", .)





/*saint format fix
replace county_name = subinstr(county_name, "ST. ", "St. ", .)
replace county_name = subinstr(county_name, "ST. ", "SAINT ", .)
replace county_name = subinstr(county_name, "ST ", "SAINT ", .) */


* Ste → Sainte
replace county_name = subinstr(county_name, "STE. ", "Ste ", .)

/*ndardize Saint properly
replace county_name = upper(county_name)
replace county_name = subinstr(county_name, "ST. ", "St ", .)
replace county_name = subinstr(county_name, "ST ", "St ", .)
replace county_name = subinstr(county_name, "SAINT ", "St ", .)
replace county_name = itrim(county_name) //clean spacing
*/

*1. Fix STE first (French counties — protect them)
replace county_name = subinstr(county_name, "STE. ", "Ste ", .)

* 2. Fix ST. → St
replace county_name = subinstr(county_name, "ST. ", "St ", .)

* 3. Fix ST (no dot) → St
replace county_name = subinstr(county_name, "ST ", "St ", .)

* 4. Fix SAINT → St
replace county_name = subinstr(county_name, "SAINT ", "St ", .)

* 5. Clean spacing
replace county_name = itrim(county_name)



*accents
replace county_name = "Dona Ana" if county_name == "DOñA ANA" //correct

* Alaska suffixes
replace county_name = subinstr(county_name, " MUNICIPALITY", "", .)
replace county_name = subinstr(county_name, " CITY AND", "", .)

/* special Louisiana case
replace county_name = "La Salle" if county_name == "LASALLE"
*  Illinois LaSalle
replace county_name = "La Salle" if county_name == "LA SALLE" & state_name=="ILLINOIS" */

*la salle fix
replace county_name = "LaSalle" if county_name == "LA SALLE" & state_name=="ILLINOIS"
replace county_name = "La Salle" if county_name == "LASALLE" & state_name=="LOUISIANA"


*old name
replace county_name = "Shannon" if county_name == "OGLALA LAKOTA"



*adding fips
statastates, name(state_name) 
drop _merge
countyfips, name(county_name) statefips(state_fips)

list county_name state_name if _merge == 1


*Anchorage in Alaska
replace fips = 02020 if county_name == "ANCHORAGE" & state_name == "ALASKA"
replace county_fips = 20 if county_name == "ANCHORAGE" & state_name == "ALASKA"
drop if county_name == "ANCHORAGE" & missing(pop2010)


/* Cannot merge 8 counties because their boundaries have changed 
so I will folow Chaflin & Mcrary's suggestion for " Constant boundary 
Rule" and use their historical county boundaries to maintain consistency

+----------------------------------+
county_name   state~me	
	
536.                CHUGACH     ALASKA	
670.           COPPER RIVER     ALASKA	
1343.          HOONAH-ANGOON     ALASKA	
1600.               KUSILVAK     ALASKA	
2323.             PETERSBURG     ALASKA	
	
2430.  PRINCE OF WALES-HYDER     ALASKA	
2728.                SKAGWAY     ALASKA	
3261.               WRANGELL     ALASKA	
*/

* Valdez-Cordova Split (into Chugach and Copper River)
replace county_name = "Valdez-Cordova" if inlist(county_name, "CHUGACH", "COPPER RIVER")

* Wrangell-Petersburg Split (into Petersburg and Wrangell)
replace county_name = "Wrangell-Petersburg" if inlist(county_name, "PETERSBURG", "WRANGELL")

* Skagway-Hoonah-Angoon Split (into Skagway and Hoonah-Angoon)
replace county_name = "Skagway-Hoonah-Angoon" if inlist(county_name, "SKAGWAY", "HOONAH-ANGOON")

* Prince of Wales-Outer Ketchikan Split (into Prince of Wales-Hyder)
replace county_name = "Prince of Wales-Outer Ketchikan" if county_name == "PRINCE OF WALES-HYDER"	

* Wade Hampton was renamed Kusilvak in 2015. 
* To keep the Fixed Effect consistent, I will use the historical name.
replace county_name = "Wade Hampton" if county_name == "KUSILVAK"


replace fips = 02261 if county_name == "Valdez-Cordova" //need to look at these again
replace fips = 02280 if county_name == "Wrangell-Petersburg"
replace fips = 02232 if county_name == "Skagway-Hoonah-Angoon"
replace fips = 02201 if county_name == "Prince of Wales-Outer Ketchikan"
replace fips = 02270 if county_name == "Wade Hampton"



*fips & string
drop _merge
countyfips, name(county_name) statefips(state_fips)

gen fips_str = string(fips, "%05.0f")
drop fips
rename fips_str fips


*final cleaning
browse if _merge == 1
drop _merge county_code state_code B geo 
drop if missing(pop2010) //* removing the empties

gen fips_str = string(fips, "%05.0f")
drop fips
rename fips_str fips

order fips  county_name county_fips state_abbrev state_fips 



save "data/intermediate/pop2010-2020.dta", replace


*tests
use "data/intermediate/pop2010-2020.dta", clear

browse if _merge == 1
list county_name state_name fips if _merge == 1
duplicates report
duplicates list fips
list county_name state_name if missing(fips)
list county_name state_name if fips == ""

duplicates tag fips, gen(dup)
list fips county_name state_name if dup > 0






/*
gen state = ""

replace state= "AL" if STNAME== "Alabama"
replace state= "AK" if STNAME== "Alaska"
replace state= "AZ" if STNAME== "Arizona"
replace state= "AR" if STNAME== "Arkansas"
replace state= "CA" if STNAME== "California"
replace state= "CO" if STNAME== "Colorado"
replace state= "CT" if STNAME== "Connecticut"
replace state= "DE" if STNAME== "Delaware"
replace state= "DC" if STNAME== "District of Columbia"
replace state= "FL" if STNAME== "Florida"
replace state= "GA" if STNAME== "Georgia"
replace state= "HI" if STNAME== "Hawaii"
replace state= "ID" if STNAME== "Idaho"
replace state= "IL" if STNAME== "Illinois"
replace state= "IN" if STNAME== "Indiana"
replace state= "IA" if STNAME== "Iowa"
replace state= "KS" if STNAME== "Kansas"
replace state= "KY" if STNAME== "Kentucky"
replace state= "LA" if STNAME== "Louisiana"
replace state= "ME" if STNAME== "Maine"
replace state= "MD" if STNAME== "Maryland"
replace state= "MA" if STNAME== "Massachusetts"
replace state= "MI" if STNAME== "Michigan"
replace state= "MN" if STNAME== "Minnesota"
replace state= "MS" if STNAME== "Mississippi"
replace state= "MO" if STNAME== "Missouri"
replace state= "MT" if STNAME== "Montana"
replace state= "NE" if STNAME== "Nebraska"
replace state= "NV" if STNAME== "Nevada"
replace state= "NH" if STNAME== "New Hampshire"
replace state= "NJ" if STNAME== "New Jersey"
replace state= "NM" if STNAME== "New Mexico"
replace state= "NY" if STNAME== "New York"
replace state= "NC" if STNAME== "North Carolina"
replace state= "ND" if STNAME== "North Dakota"
replace state= "OH" if STNAME== "Ohio"
replace state= "OK" if STNAME== "Oklahoma"
replace state= "OR" if STNAME== "Oregon"
replace state= "PA" if STNAME== "Pennsylvania"
replace state= "RI" if STNAME== "Rhode Island"
replace state= "SC" if STNAME== "South Carolina"
replace state= "SD" if STNAME== "South Dakota"
replace state= "TN" if STNAME== "Tennessee"
replace state= "TX" if STNAME== "Texas"
replace state= "UT" if STNAME== "Utah"
replace state= "VT" if STNAME== "Vermont"
replace state= "VA" if STNAME== "Virginia"
replace state= "WA" if STNAME== "Washington"
replace state= "WV" if STNAME== "West Virginia"
replace state= "WI" if STNAME== "Wisconsin"
replace state= "WY" if STNAME== "Wyoming"
replace state= "AS" if STNAME== "American Samoa"
replace state= "GU" if STNAME== "Guam"
replace state= "PR" if STNAME== "Puerto Rico"
replace state= "MP" if STNAME== "Northern Mariana Islands"
replace state= "UM" if STNAME== "Minor Outlying Islands"
replace state= "VI" if STNAME== "Virgin Islands"
*/













