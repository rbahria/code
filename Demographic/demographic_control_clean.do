/*------------------------------------------------
	In this file I am cleaning Demographic data :
	
	--> Race, sex, age from US census MISSING 2021
---------------------------------------------------
*/


 
 
 
****************************************************************

* 				Set up

****************************************************************

clear all
set more off


global PATH "C:\Users\ranya\OneDrive - Alma Mater Studiorum Università di Bologna\Desktop\UNIBO\PFE\US\Work"
global data "${PATH}/data/raw"
global clean "${PATH}/data/clean"
global temp "${PATH}/data/temp"

cd "${PATH}"



******************************************************************

* 				cleaning US census Demographics

******************************************************************



********************************************
* 1. 1990- 2000s US census Populations
********************************************

clear 
*loop over files

forvalues i = 90/99 {
	
	infix year 1-2 str fips 3-10 str age_raw 11-13 str race_sex 14 str 	ethnic 16 pop 17-30 ///
    using "${data}/demographic_US_census/stch-icen19`i'.txt"
	
	gen year_full = 1900 + year
	drop year
	rename year_full year
	
	foreach v in fips age_raw race_sex ethnic {
        replace `v' = trim(`v') //cleaning
		}

	*age groups
	gen age_cat = ""
    replace age_cat = "0-14"  if inlist(age_raw, "0", "1", "2", "3")
    replace age_cat = "15-24" if inlist(age_raw, "4", "5")
    replace age_cat = "25-39" if inlist(age_raw, "6", "7", "8")
    replace age_cat = "40plus" if real(age_raw) >= 9 & real(age_raw) != .
	
	* race and gender
//1=White M, 2=White F, 3=Black M, 4=Black F, 5=Ind M, 6=Ind F, 7=Asian M, 8=Asian F
	gen gender = ""
    replace gender = "male"   if inlist(race_sex, "1", "3", "5", "7")
    replace gender = "female" if inlist(race_sex, "2", "4", "6", "8")
	
	gen race_grp = "nonwhite"
    replace race_grp = "white" if inlist(race_sex, "1", "2")
	
	collapse (sum) pop, by(year fips age_cat gender race_grp)
	
	save "${temp}/demo/demo_temp_`i'.dta", replace
    clear
	
	}
	
	
* appending
use "${temp}/demo/demo_temp_90.dta", clear
	forvalues i = 91/99 {
    append using "${temp}/demo/demo_temp_`i'.dta"
}


* 1.a) 1990- 2000s shares

*total county population
bysort fips year: egen pop_total = total(pop)

*age-group pop shares
bysort fips year age_cat: egen pop_age = total(pop)

gen sh_age_0_14   = pop_age / pop_total if age_cat == "0-14"
gen sh_age_15_24  = pop_age / pop_total if age_cat == "15-24"
gen sh_age_25_39  = pop_age / pop_total if age_cat == "25-39"
gen sh_age_40plus = pop_age / pop_total if age_cat == "40plus"

*gender shares
bysort fips year gender: egen pop_gender = total(pop)

gen sh_female = pop_gender / pop_total if gender == "female"
gen sh_male   = pop_gender / pop_total if gender == "male"
	
*race shares	
bysort fips year race_grp: egen pop_race = total(pop)

gen sh_white    = pop_race / pop_total if race_grp == "white"
gen sh_nonwhite = pop_race / pop_total if race_grp == "nonwhite"

*one row per county-year
collapse (max) pop_total sh_age_0_14 sh_age_15_24 sh_age_25_39 sh_age_40plus ///
               sh_female sh_male sh_white sh_nonwhite, ///
    by(fips year)

	
*1.b) fixing fips and boundaries
gen state_fips  = real(substr(fips, 1, 2))
gen county_fips = real(substr(fips, 3, 3))

* Oglala Lakota County, SD
replace county_fips = 102 if county_fips == 113 & state_fips == 46

* Alaska Census Areas
replace county_fips = 198 if county_fips == 201 & state_fips == 2
replace county_fips = 105 if county_fips == 232 & state_fips == 2
replace county_fips = 158 if county_fips == 270 & state_fips == 2
replace county_fips = 195 if county_fips == 280 & state_fips == 2

* Virginia fixes
replace county_fips = 19 if county_fips == 515 & state_fips == 51
replace county_fips = 5  if county_fips == 560 & state_fips == 51

*county-year level
collapse (sum) pop_total ///
         (mean) sh_age_0_14 sh_age_15_24 sh_age_25_39 sh_age_40plus ///
                sh_female sh_male sh_white sh_nonwhite [aw=pop_total], ///
         by(state_fips county_fips year)

* fixing fips after boundary change
gen fips = string(state_fips, "%02.0f") + string(county_fips, "%03.0f")
order fips state_fips county_fips year pop_total

isid fips year


save "${clean}/demo/demo_us_1990_2000.dta", replace


*checks
	duplicates report fips year
	* missing values
	misstable summarize fips state_fips county_fips year pop_total ///
    sh_age_0_14 sh_age_15_24 sh_age_25_39 sh_age_40plus ///
    sh_female sh_male sh_white sh_nonwhite
	
	assert pop_total > 0
	foreach v in sh_age_0_14 sh_age_15_24 sh_age_25_39 sh_age_40plus ///
             sh_female sh_male sh_white sh_nonwhite {
    assert inrange(`v', 0, 1) if !missing(`v')
	}
	*Check shares sum to 1
	gen check_age = sh_age_0_14 + sh_age_15_24 + sh_age_25_39 + sh_age_40plus
	gen check_gender = sh_female + sh_male
	gen check_race = sh_white + sh_nonwhite

   drop check_race check_gender check_age



********************************************
* 2. 2000- 2010s US census Populations
********************************************


* 2.a )age/sex file

import delimited "${data}/demographic_US_census/co-est00int-agesex-5yr.csv", clear
	
keep if sumlev==50  //counties only

drop estimatesbase2000 census2010pop sumlev


*renaming vars
rename popestimate* pop*
rename  stname state_name 
rename ctyname county_name
rename state state_fips
rename county county_fips


gen fips= string(state_fips, "%02.0f") + string(county_fips, "%03.0f")
order fips county_name county_fips state_name state_fips

*reshaping
reshape long pop, i(fips sex agegrp) j(year)

*age groups
gen age_cat = ""
replace age_cat = "0-14"   if inrange(agegrp, 1, 3)
replace age_cat = "15-24"  if inrange(agegrp, 4, 5)
replace age_cat = "25-39"  if inrange(agegrp, 6, 8)
replace age_cat = "40plus" if agegrp >= 9 & agegrp <= 18

*age shares
bysort fips year: egen pop_total = max(cond(sex==0 & agegrp==0, pop, .)) //look for row where they're totals and copy that nb into every
//row for that county and year

bysort fips year age_cat: egen pop_age = total(pop) if sex == 0

gen sh_age_0_14   = pop_age / pop_total if age_cat == "0-14"
gen sh_age_15_24  = pop_age / pop_total if age_cat == "15-24"
gen sh_age_25_39  = pop_age / pop_total if age_cat == "25-39"
gen sh_age_40plus = pop_age / pop_total if age_cat == "40plus"

* gender shares
bysort fips year sex: egen pop_gender = total(pop) if agegrp == 0
gen sh_male   = pop_gender / pop_total if sex == 1
gen sh_female = pop_gender / pop_total if sex == 2

*collapse
collapse (max) pop_total sh_age_* sh_male sh_female, ///
    by(fips year state_fips county_fips state_name county_name)
	

save "${temp}/demo/demo_us_2000_2010_sexage.dta", replace



* 2.b ) Age race charactheristics
import delimited "${data}/demographic_US_census/co-est00int-sexracehisp.csv", clear

keep if sumlev == 50
drop estimatesbase2000 census2010pop sumlev

rename state state_fips
rename county county_fips
rename popestimate* pop*
rename  stname state_name 
rename ctyname county_name

gen fips = string(state_fips, "%02.0f") + string(county_fips, "%03.0f")

reshape long pop, i(fips sex race origin) j(year)

keep if origin == 0 // origin= 0 total whther they are hispanic or not
drop origin

*Race Shares 
// sex== 0 means total men and women 
bysort fips year: egen pop_total = max(cond(sex==0 & race==0, pop, .))
bysort fips year: egen pop_white = max(cond(sex==0 & race==1, pop, .))

gen sh_white = pop_white / pop_total
gen sh_nonwhite = 1 - sh_white


collapse (max) sh_white sh_nonwhite, ///
    by(fips year state_fips county_fips state_name county_name)
	
save "${temp}/demo/demo_us_2000_2010_race.dta", replace


*2.c) Merging the two files

use "${temp}/demo/demo_us_2000_2010_sexage.dta", clear
merge 1:1 fips year using "${temp}/demo/demo_us_2000_2010_race.dta"

tab _merge
drop if _merge == 2
drop _merge

* 2.d) Boundary Fix

*Broomfield
drop if state_fips == 8 & county_fips == 14

* South Dakota
replace county_fips = 113 if county_fips == 102 & state_fips == 46
// Oglala Lakota back to Shannon

* Virginia
replace fips = "51019" if fips == "51515"
replace county_fips = 19 if fips == "51019"
replace county_name = "Bedford" if fips == "51019"

* Alaska 
replace fips = "02261" if inlist(fips, "02063", "02066")   // Chugach + Copper River
replace fips = "02280" if inlist(fips, "02195", "02275")   // Petersburg + Wrangell
replace fips = "02232" if inlist(fips, "02230", "02105")   // Skagway + Hoonah-Angoon
replace fips = "02201" if fips == "02198"                  // Prince of Wales-Hyder
replace fips = "02270" if fips == "02158"                  // Kusilvak back to Wade Hampton

collapse (sum) pop_total (firstnm) state_name county_name (mean) sh_age_* sh_male sh_female sh_white sh_nonwhite [aw=pop_total], by(fips year)
		 
* the names for these merged units
replace county_name = "Skagway-Yakutat-Angoon" if fips == "02232"
replace county_name = "Wrangell-Petersburg" if fips == "02280"
replace county_name = "Valdez-Cordova" if fips == "02261"
replace county_name = "Bedford" if fips == "51019"
replace county_name = "Prince of Wales-Outer Ketchikan" if fips == "02201"
replace county_name = "Wade Hampton" if fips == "02270"
replace county_name = "Shannon" if fips == "46113"

gen state_fips  = real(substr(fips, 1, 2))
gen county_fips = real(substr(fips, 3, 3))

		 order state_fips county_fips fips year state_name county_name pop_total sh_white sh_nonwhite
sort fips year

*check
duplicates report fips year
duplicates list fips year

save "${clean}/demo/demo_us_2000_2010.dta", replace


********************************************
* 3. 2010- 2020s US census Populations
********************************************


import delimited "${data}/demographic_US_census/cc-est2020int-alldata.csv", clear

keep if year >= 4 & year <= 13 //drop 2010 since in previous files

replace year = 2007 + year

gen fips = string(state, "%02.0f") + string(county, "%03.0f")

rename  stname state_name 
rename ctyname county_name
rename state state_fips
rename county county_fips

order fips year state_fips county_fips state_name county_name

*3.a)  Total, gender, race from agegrp == 0
preserve

    keep if agegrp == 0

    gen pop_total = tot_pop

    gen pop_male   = tot_male
    gen pop_female = tot_female

    * white alone
    gen pop_white = wa_male + wa_female
    gen pop_nonwhite = pop_total - pop_white

    keep fips year state_fips county_fips state_name county_name ///
         pop_total pop_male pop_female pop_white pop_nonwhite

    tempfile totals
    save `totals'

restore


* 3.b) Age-group populations

keep if agegrp != 0

gen age_cat = ""
replace age_cat = "0_14"   if inrange(agegrp, 1, 3)
replace age_cat = "15_24"  if inrange(agegrp, 4, 5)
replace age_cat = "25_39"  if inrange(agegrp, 6, 8)
replace age_cat = "40plus" if inrange(agegrp, 9, 18)

drop if age_cat == ""

*sum population within age groups
collapse (sum) tot_pop, ///
    by(fips year state_fips county_fips state_name county_name age_cat)
	
reshape wide tot_pop, ///
    i(fips year state_fips county_fips state_name county_name) ///
    j(age_cat) string

rename tot_pop0_14    pop_age_0_14
rename tot_pop15_24   pop_age_15_24
rename tot_pop25_39   pop_age_25_39
rename tot_pop40plus  pop_age_40plus

* 3.c) creating shares
merge 1:1 fips year using `totals'

gen sh_age_0_14   = pop_age_0_14   / pop_total
gen sh_age_15_24  = pop_age_15_24  / pop_total
gen sh_age_25_39  = pop_age_25_39  / pop_total
gen sh_age_40plus = pop_age_40plus / pop_total

gen sh_male   = pop_male   / pop_total
gen sh_female = pop_female / pop_total

gen sh_white    = pop_white    / pop_total
gen sh_nonwhite = pop_nonwhite / pop_total


keep fips year state_fips county_fips state_name county_name pop_total ///
     sh_age_0_14 sh_age_15_24 sh_age_25_39 sh_age_40plus ///
     sh_male sh_female sh_white sh_nonwhite

order fips year state_fips county_fips state_name county_name pop_total


save "${temp}/demo/demo_us_2011_2020.dta", replace



* 3.d) boundary adjustement

use "${temp}/demo/demo_us_2011_2020.dta", clear

* Broomfield, CO
drop if state_fips == 8 & county_fips == 14

*Alaska
replace fips = "02261" if strpos(county_name, "Chugach") | strpos(county_name, "Copper")
replace fips = "02280" if strpos(county_name, "Petersburg") | strpos(county_name, "Wrangell")
replace fips = "02232" if strpos(county_name, "Skagway") | strpos(county_name, "Hoonah")
replace fips = "02201" if strpos(county_name, "Prince of Wales")
replace fips = "02270" if strpos(county_name, "Kusilvak")

replace county_name = "Valdez-Cordova" if fips == "02261"
replace county_name = "Wrangell-Petersburg" if fips == "02280"
replace county_name = "Skagway-Hoonah-Angoon" if fips == "02232"
replace county_name = "Prince of Wales-Outer Ketchikan" if fips == "02201"
replace county_name = "Wade Hampton" if fips == "02270"


* Shannon / Oglala Lakota
replace fips = "46113" if fips == "46102"
replace county_name = "Shannon" if fips == "46113"


* collapse after harmonization
collapse (sum) pop_total ///
         (mean) sh_age_0_14 sh_age_15_24 sh_age_25_39 sh_age_40plus ///
		 (firstnm) state_name county_name ///
                sh_male sh_female sh_white sh_nonwhite [aw=pop_total], /// 
         by (fips year)
		 
* rebuild numeric FIPS variables
gen state_fips  = real(substr(fips, 1, 2))
gen county_fips = real(substr(fips, 3, 3))

	
duplicates list fips year

 order state_fips county_fips fips year state_name county_name pop_total sh_white sh_nonwhite

save "${clean}/demo/demo_us_2011_2020.dta", replace

*check
tab county_name if strpos(county_name, "Wrang"), missing

