

clear all 
set more off

global PATH "C:\Users\ranya\OneDrive - Alma Mater Studiorum Università di Bologna\Desktop\UNIBO\PFE\US\Work"

cd "${PATH}"

use "data/raw/ucr_hate/ucr_hate_crimes_1991_2024.dta", clear

***********************************************************	
*			 Variables*
**************************************************************

*5-digit FIPS for mapping
destring fips_state_county_code, replace
format fips_state_county_code %05.0f // Force Stata to display the leading zero (using 5 digits)

drop if ori == ""


*** Quarter Z or I

* Create a numeric version of the activity flags
foreach q in first second third fourth {
    gen q`q'_participated = 0
    
    * Check for both possible "participation" strings
    replace q`q'_participated = 1 if state_`q'_quarter_activity == "incident report was submitted" | ///
                                     state_`q'_quarter_activity == "zero-report was submitted"
}

* Total quarters participated in a year (0 to 4)
gen quarters_active = qfirst_participated + qsecond_participated + qthird_participated + qfourth_participated

* Binary: Did they participate at all this year?
gen participating_year = (quarters_active > 0)


* the numeric marker based on incident_number
gen marker_incident = (incident_number != "")
******************************************************************


*******************************************************
* . FIRST COLLAPSE: INCIDENTS -> AGENCY-YEARS
*******************************************************
collapse (sum) incidents = marker_incident ///
         (max) participating_year quarters_active population ///
         (first) fips_state_county_code, by(ori year)
		 
*-> only rows for years where the agency existed in FBI record		 
		 
		 
*******************************************************
* . THE TRUTH ENGINE: FILLING THE GAPS
*******************************************************

* --> creating missing years
* Create rows for years an agency existed but didn't report
fillin ori year

* A. ANCHOR: Copy County ID to the newly created 'fillin' rows
bysort ori (fips_state_county_code): replace fips_state_county_code = fips_state_county_code[1] if missing(fips_state_county_code)

* B. POPULATION CARRY-FORWARD: Fill missing population blanks
sort ori year
bysort ori: replace population = population[_n-1] if missing(population) & _n > 1
gsort ori -year
bysort ori: replace population = population[_n-1] if missing(population) & _n > 1
sort ori year

* C. TREATMENT FOR INCIDENTS AND PARTICIPATION
replace incidents = 0 if _fillin == 1
replace participating_year = 0 if missing(participating_year)

* D. SPECIFIC TREATMENT FOR "MISSED YEAR"
gen missed_year = 0
replace missed_year = 1 if _fillin == 1 & (participating_year == 0 | participating_year == .)
replace missed_year = 1 if _fillin == 0 & participating_year == 0


*******************************************************
* . BIRTH YEAR LOGIC: FIXING ADMINISTRATIVE BIAS
*******************************************************


bysort ori: egen birth_year = min(year) if participating_year == 1 //first year it actually reports
bysort ori (birth_year): replace birth_year = birth_year[1]

* Drop years before their first actual report (This creates the "Grey" areas)
drop if year < birth_year
bysort ori (year): gen years_active_so_far = (year - birth_year) + 1
bysort ori (year): gen missed_so_far = sum(missed_year)


* Recalculate metrics using existing names
replace years_active_so_far = (year - birth_year) + 1
bysort ori (year): replace missed_so_far = sum(missed_year)
gen missing_rate_agency = (missed_so_far / years_active_so_far) * 100



//try

gen pop_smoothed = .
levelsof ori, local(all_oris)
foreach o in `all_oris' {
    cap drop temp_x temp_p
    quietly lpoly population year if ori == "`o'", ///
        degree(0) bwidth(2) at(year) gen(temp_x temp_p) nograph
    quietly replace pop_smoothed = temp_p if ori == "`o'"
    drop temp_x temp_p
}




/*test
gen pop_smoothed = .

levelsof ori, local(all_oris)

local i = 0
foreach o in `all_oris' {
    local ++i
    if `i' > 20 continue, break
    
    di "Running ORI `i': `o'"
    
    cap drop temp_x temp_p
    quietly count if ori == "`o'" & !missing(population, year)
    
    if r(N) >= 3 {
        cap noisily lpoly population year if ori == "`o'" & !missing(population, year), ///
            degree(1) bwidth(2) at(year) gen(temp_x temp_p) nograph
        
        if _rc == 0 {
            quietly replace pop_smoothed = temp_p if ori == "`o'"
        }
    }
    
    cap drop temp_x temp_p
}

*/

*******************************************************
* . SMOOTHING THE POPULATION
*******************************************************

* Smoothing at the Ori level

gen pop_smoothed = .
levelsof ori, local(all_oris)

foreach o in `all_oris' {
    * degree(0) = local constant (robust to spikes)
    * bwidth(2) = looks at a 2-year moving window
    cap lpoly population year if ori == "`o'", degree(0) bwidth(2) at(year) gen(temp_p) nograph
    cap replace pop_smoothed = temp_p if ori == "`o'"
    cap drop temp_p
}

* If lpoly fails for an agency with too few years, fall back to raw population
replace pop_smoothed = population if missing(pop_smoothed)


*********************************************
*  Visualizating the deviation between the two
***********************************************

* the raw difference
gen pop_diff = population - pop_smoothed

* the absolute percentage error (APE)
gen pop_ape = abs(pop_diff / pop_smoothed) * 100

label var pop_ape "Percentage difference: Raw vs. Smoothed Pop"

summarize pop_ape, detail

*******************************************************
* . FINAL COLLAPSE: AGENCY -> COUNTY-YEAR
*******************************************************
collapse (sum)  county_incidents = incidents ///
                county_population = population_smoothed /// 
         (mean) county_participation_years = participating_year ///
         (mean) avg_missing_rate = missing_rate_agency, ///
         by(fips_state_county_code year)

*  Rate per 100k 
gen hate_crime_rate = (county_incidents / county_population) * 100000

*safety check 
replace hate_crime_rate = 0 if county_population == 0 | missing(hate_crime_rate)

gen county_id = string(fips_state_county_code, "%05.0f")

export delimited using "data/r/pop_smooth_grey.csv", replace









/* Need to update this now 
*******************************************************
* 6. PLOT POPULATION COVERAGE (TREND LINE)
*******************************************************


preserve 

* Collapse the entire dataset by year to get national totals
collapse (sum) national_pop_covered = county_population, by(year)

* Create the line plot
twoway (line national_pop_covered year, lcolor(stone) lwidth(medium) lpattern(solid)) ///
       (scatter national_pop_covered year if inlist(year, 2013, 2014, 2017), ///
            mcolor(purple) msize(medium) mlabel(year) mlabpos(12)), ///
       title("Total Population Coverage Over Time") ///
       subtitle("Sum of Population from Reporting Agencies (1991-2024)") ///
       ytitle("Total Covered Population") ///
       xtitle("Year") ///
       xlabel(1991(3) 2024, grid) ///
       ylabel(, format(%12.0fc)) ///
       graphregion(color(white)) ///
       legend(off)

restore


*******************************************************
* 6. NATIONAL COVERAGE: AGENCIES AND POPULATION
*******************************************************
import delimited "data/r/pop_grey.csv", clear
preserve

*******************************************************
* 6. CORRECTED NATIONAL COVERAGE
*******************************************************
preserve

* Count how many unique FIPS codes exist for each year
collapse (sum) total_covered_pop = county_population ///
         (count) num_counties = fips_state_county_code, by(year)
**# Bookmark #1

* 1. Calculate Percentages (0 to 1.00) based on the observed maximums
* This ensures the lines scale like the image you shared (image_157882.png)
quietly sum total_covered_pop
gen perc_pop = total_covered_pop / r(max)

quietly sum num_counties
gen perc_agencies = num_counties / r(max)

* 2. Plotting to match your reference
twoway (line perc_pop year, lcolor(teal) lwidth(medium)) ///
       (line perc_agencies year, lcolor(black) lwidth(medium)), ///
       title("Percentage of Counties Reporting and Population Covered") ///
       ytitle("Percentage (0 to 1.00)") ///
       xtitle("Year") ///
       xlabel(1991(5) 2024) ///
       legend(label(1 "Population Covered") label(2 "Reporting Counties")) ///
       graphregion(color(white))

restore




preserve
import delimited "data/r/pop_grey.csv", clear
* 1. ONLY keep rows where the agency actually participated that year
* This removes the 'persistent' counties that aren't actually sending data
keep if participating_year == 1 

* 2. Now collapse
collapse (sum) total_covered_pop = county_population ///
         (count) active_counties = fips_state_county_code, by(year)

* 3. Calculate percentages relative to the total possible (approx 3142 counties)
gen perc_pop = total_covered_pop / r(max)
gen perc_agencies = active_counties / 3142  // Use the actual total number of US counties

* 4. Plot
twoway (line perc_pop year, lcolor(teal) lwidth(medium)) ///
       (line perc_agencies year, lcolor(black) lwidth(medium)), ///
       ytitle("Percentage of Active Reporting") xtitle("Year") ///
       legend(label(1 "Population Covered") label(2 "Active Counties")) ///
       graphregion(color(white))

restore

















/*
*******************************************************
* 4.5 WATCHMEN SMOOTHING: LOCAL POLYNOMIAL FILTER
*******************************************************
* We smooth at the ORI level to fix typos before they hit the county sum
gen pop_smoothed = .
levelsof ori, local(all_oris)

* Note: This may take a few minutes given the size of the UCR
foreach o in `all_oris' {
    * degree(0) = local constant (robust to spikes)
    * bwidth(2) = looks at a 2-year moving window
    cap lpoly population year if ori == "`o'", degree(0) bwidth(2) at(year) gen(temp_p) nograph
    cap replace pop_smoothed = temp_p if ori == "`o'"
    cap drop temp_p
}

* If lpoly fails for an agency with too few years, fall back to raw population
replace pop_smoothed = population if missing(pop_smoothed)