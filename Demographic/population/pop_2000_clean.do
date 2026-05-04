clear all 
set more off

global PATH "C:\Users\ranya\OneDrive - Alma Mater Studiorum Università di Bologna\Desktop\UNIBO\PFE\US\Work"

cd "${PATH}"





****************************************************

* Importing files files from US Census

*****************************************************

import delimited "https://www2.census.gov/programs-surveys/popest/datasets/2010-2020/counties/totals/co-est2020-alldata.csv", clear

save "data/raw/population/us_census2020.dta", replace




********************************************************

*				cleaning 1990-2000

********************************************************

use "data/raw/population/us_census2000.dta", clear 

rename pop_total* pop*
rename FIPS fips
rename FIPS_county_code county_fips


save "data/intermediate/pop1990_2000.dta", replace



*check for the alska counties

* Shanon/ Oglala lakota SD
list state_code county_fips if state_code==46 // 113 not present

*Alaska
list if state_code==2

* final check
duplicates report fips


********************************************************



*******************************************************

*				cleaning 2000-2010 

*******************************************************

import delimited "data/raw/population/co-est2000int-tot.csv", varnames(1)clear

keep if sumlev==50  //counties only

drop estimatesbase2000 census2010pop region sumlev division 

*renaming vars
rename popestimate* pop*
rename  stname state_name 
rename ctyname county_name
rename state state_fips
rename county county_fips


gen fips= string(state_fips, "%02.0f") + string(county_fips, "%03.0f")

order fips county_name county_fips state_name state_fips



*check for the alska counties
list state_name county_name fips if state_name == "Alaska" & ///
(strpos(county_name, "Chugach") | strpos(county_name, "Copper") | ///
 strpos(county_name, "Kusilvak") | strpos(county_name, "Wade Hampton"))

* check for the 2010 "Parent" names and their historical FIPS
list state_name county_name fips if state_name == "Alaska" & ///
(fips == "02261" | fips == "02280" | fips == "02232")


*************************
* Restoring to Historical
*************************

*dropping Broomfield NEED TO CHECK THIS AGAIN
drop if state_fips == 8 & county_fips == 14

/*Bedford old code
replace county_fips= 019 if county_fips == 515 & state_fips == 51
replace fips = "51019 " if fips == "51515" | county_name == "BEDFORD CITY" */

*Bedford
replace fips = "51019" if fips == "51515"
replace county_name = "Bedford" if fips == "51019"

* Alaska splits → map to historical units
replace fips = "02261" if inlist(fips, "02063", "02066")   // Chugach + Copper River
replace fips = "02280" if inlist(fips, "02195", "02275")   // Petersburg + Wrangell
replace fips = "02232" if inlist(fips, "02230", "02105")   // Skagway + Hoonah-Angoon
replace fips = "02201" if fips == "02198"                  // Prince of Wales-Hyder

*county and state fips fix
drop county_fips state_fips // to replace them with new correct ones
gen county_fips = real(substr(fips, 3, 3)) 
gen state_fips  = real(substr(fips, 1, 2))


collapse (sum) pop2000-pop2010 (first) county_name county_fips state_name state_fips, by(fips )
order fips county_name county_fips state_name state_fips
 
 
 
*redundant in merge
drop  pop2010 
 
save "data/intermediate/pop2000-2010.dta", replace



**********************************************************

*				cleaning 2010-2020

*********************************************************


use "data/raw/population/us_census2020.dta", clear

 keep if sumlev==50 

 keep state county stname ctyname popestimate2010 ///
 popestimate2011 popestimate2012 popestimate2013 popestimate2014 ///
 popestimate2015 popestimate2016 popestimate2017 popestimate2018 ///
 popestimate2019 popestimate2020 
 
*renaming vars
rename popestimate* pop*
rename  stname state_name 
rename ctyname county_name
rename state state_fips
rename county county_fips


gen fips= string(state_fips, "%02.0f") + string(county_fips, "%03.0f")
order fips


*check for the alska counties
list state_name county_name fips if state_name == "Alaska" & ///
(strpos(county_name, "Chugach") | strpos(county_name, "Copper") | ///
 strpos(county_name, "Kusilvak") | strpos(county_name, "Wade Hampton"))
 
 /* 				
	state_~e		county_name	fips	
					
73.	Alaska	Chugach	Census Area	02063	
74.	Alaska	Copper River	Census Area	02066	
84.	Alaska	Kusilvak	Census Area	02158	
					
*/ 
 
 
* check for the 2010 "Parent" names and their historical FIPS
list state_name county_name fips if state_name == "Alaska" & ///
(fips == "02261" | fips == "02280" | fips == "02232")
 
 //--> doesnt exist

 
**********************
* Boundary Adjustment
*********************

//I will folow Chaflin & Mcrary's suggestion for " Constant boundary rule" and use their historical county boundaries to maintain consistency


*dropping Broomfield NEED TO CHECK THIS AGAIN
drop if state_fips == 8 & county_fips == 14


* Alaska Valdez- Cordova

replace fips = "02261" if ///
strpos(county_name, "Chugach") | strpos(county_name, "Copper")

replace fips = "02280" if ///
strpos(county_name, "Petersburg") | strpos(county_name, "Wrangell")

replace fips = "02232" if ///
strpos(county_name, "Skagway") | strpos(county_name, "Hoonah")

replace fips = "02201" if strpos(county_name, "Prince of Wales")

replace fips = "02270" if strpos(county_name, "Kusilvak") 

/*
replace fips = "02261" if ///
inlist(county_name, "Chugach", "Copper River") | /// 
inlist(fips, "02063", "02066")

replace fips = "02280" if inlist(county_name, "Petersburg", "Wrangell")
replace fips = "02232" if inlist(county_name, "Skagway", "Hoonah-Angoon")
replace fips = "02201" if county_name == "Prince of Wales-Hyder"
replace fips = "02270" if county_name == "Kusilvak" */

*renaming counties
replace county_name = "Valdez-Cordova" if fips == "02261"
replace county_name = "Wrangell-Petersburg" if fips == "02280"

* Shannon / Oglala Lakota 
//replace county_name = "Shannon" if strpos(county_name, "Oglala Lakota")
replace fips = "46113" if fips == "46102"
replace county_name = "Shannon" if fips == "46113"

*// to replace them with new correct ones
drop county_fips state_fips 
gen county_fips = real(substr(fips, 3, 3)) 
gen state_fips  = real(substr(fips, 1, 2))

collapse (sum) pop2010-pop2020 (first) county_name state_name ,  by(fips)

save "data/intermediate/pop2010_2020.dta", replace



* check
use "data/intermediate/pop2010_2020.dta", clear
count if fips == ""
duplicates report fips

duplicates tag fips, gen(dup) //ceate a flag
list fips county_name state_name if dup > 0


duplicates report fips
duplicates list fips