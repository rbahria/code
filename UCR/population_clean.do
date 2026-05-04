
clear all 
set more off

cd "C:\Users\ranya\Downloads\US\hate_crimes_dta_1991_2024"
use "ucr_hate_crimes_1991_2024", clear

/* Note so I don't lose my mind:
This bit of code is 

*checking quartely flags to distinguish btw Z and O --> every year has a participating_year (0 or 1)

*phase 2:
*phase 3: --> using fillin creating missing years
*phase 4: --> Birth year: identifying first year an agency reported and deleting years before it

issue: sometimes has no Z or I but still exists -->check what to do with this

In the first part for pop I use  mean because I need the "average size" of a police department in that county
In the second part I will use sum because it
*/



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
* 2. FIRST COLLAPSE: INCIDENTS -> AGENCY-YEARS
*******************************************************
collapse (sum) incidents = marker_incident ///
         (max) participating_year quarters_active population ///
         (first) fips_state_county_code, by(ori year)
		 
*-> only rows for years where the agency existed in FBI record		 
		 
		 
*******************************************************
* 3. FILLING THE GAPS
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
* 4. BIRTH YEAR LOGIC: FIXING ADMINISTRATIVE BIAS
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



* Diagnostic check
preserve
    duplicates report ori // Total agencies ever seen
    keep if !missing(birth_year)
    duplicates report ori // Agencies that reported at least once
restore

*******************************************************
* 5. FINAL COLLAPSE: AGENCY -> COUNTY-YEAR
*******************************************************
collapse (sum)  county_incidents = incidents ///
         (mean) county_population = population ///
         (mean) county_participation_years = participating_year ///
         (mean) avg_missing_rate = missing_rate_agency, ///
         by(fips_state_county_code year)

* Final ID Formatting
gen county_id = string(fips_state_county_code, "%05.0f")

export delimited using "data/r/birthyear_grey.csv", replace

****************************************************************


**********************************************************************
*									Plots
***********************************************************************
 
preserve

    * Collapse everything into a single national total per year
    collapse (sum) national_total = county_incidents, by(year)

    * Option A: Standard Bar Chart (Good for showing individual years)
    graph bar national_total, over(year, label(angle(45) labsize(small))) ///
        title("Total Weighted Hate Crimes per Year", size(medium)) ///
        ytitle("Number of Incidents") ///
        bar(1, color(navy)) 
		
restore

* Option B: Twoway Bar (Often cleaner for long timelines like 1991-2024)
		* Collapse everything into a single national total per year
    collapse (sum) national_total = county_incidents, by(year)
    twoway bar national_total year, ///
        title("Annual Hate Crime Frequency (1991-2024)") ///
        xtitle("Year") ytitle("Total Weighted Incidents") ///
        xlabel(1991(2)2024, angle(45)) ///
        color(ebblue%80) ///
        lcolor(black) lwidth(vthin)
		* Save the graph
    graph export "output/graph/HC_light_timeline_bar.png", replace
	


*  NATIONAL AGGREGATION & PLOT

preserve
    * Collapse the county data to yearly totals
    collapse (sum) annual_incidents = county_incidents, by(year)

  twoway (line annual_incidents year, sort lcolor(cranberry) lwidth(medium)), ///
        title("Total Reported Hate Crime Incidents (1991-2024)", size(medium)) ///
        subtitle("Aggregated from County-Level Data", size(small)) ///
        ytitle("Number of Incidents") xtitle("Year") ///
        xlabel(1991(5)2024) ///
        ylabel(4000(2000)12000) ///
        graphregion(fcolor(white)) ///  <- Makes background white
        xline(1991(5)2024, lcolor(gs14) lpattern(dash) lwidth(vthin)) /// <- Manual Vertical Grid
        yline(4000(2000)12000, lcolor(gs14) lpattern(dash) lwidth(vthin))   


    graph export "output/graph/HC_year_latest.png", as(png) replace

restore



* Alternative for part 1

*******************************************************
* 1. PRE-COLLAPSE: WEIGHTING & ZERO-REPORT LOGIC
*******************************************************


* --- NEW MÜLLER WEIGHTING SECTION ---
gen hate_crime_unit = 1 
replace hate_crime_unit = 0 if missing(incident_number) | incident_number == "NA"

* Calculate the Weight: how many times does this unique_id appear?
bysort unique_id: gen num_counties_split = _N 
gen weight = 1 / num_counties_split

* Create the Weighted Incident
gen weighted_marker = hate_crime_unit * weight

* THE SWAP: Use 'weighted_marker' as your 'marker_incident'
* This ensures the rest of your script (fillin, birth_year) works without changes.
rename marker_incident raw_count_old // optional: keeps a backup of your old logic
rename weighted_marker marker_incident
* ------------------------------------






** NOW FOR POPULATION TESTS






*-----------------------------------------------------------------------------------------------------------------------------------------*


clear all 
set more off

cd "C:\Users\ranya\Downloads\US\hate_crimes_dta_1991_2024"
use "ucr_hate_crimes_1991_2024", clear

/* Note so I don't lose my mind:
This bit of code is 

*checking quartely flags to distinguish btw Z and O --> every year has a participating_year (0 or 1)

*phase 2:
*phase 3: --> using fillin creating missing years
*phase 4: --> Birth year: identifying first year an agency reported and deleting years before it

issue: sometimes has no Z or I but still exists -->check what to do with this

In the first part for pop I use  mean because I need the "average size" of a police department in that county
In the second part I will use sum because it
*/



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
* 2. FIRST COLLAPSE: INCIDENTS -> AGENCY-YEARS
*******************************************************
collapse (sum) incidents = marker_incident ///
         (max) participating_year quarters_active population ///
         (first) fips_state_county_code, by(ori year)
		 
*-> only rows for years where the agency existed in FBI record		 
		 
		 
*******************************************************
* 3. THE TRUTH ENGINE: FILLING THE GAPS
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
* 4. BIRTH YEAR LOGIC: FIXING ADMINISTRATIVE BIAS
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

*******************************************************
* 5. FINAL COLLAPSE: AGENCY -> COUNTY-YEAR
*******************************************************
collapse (sum)  county_incidents = incidents ///
                county_population = population /// 
         (mean) county_participation_years = participating_year ///
         (mean) avg_missing_rate = missing_rate_agency, ///
         by(fips_state_county_code year)

* 1. Create the Rate per 100k using your existing variable names
gen hate_crime_rate = (county_incidents / county_population) * 100000

* 2. The safety check you asked about (using your exact variables)
replace hate_crime_rate = 0 if county_population == 0 | missing(hate_crime_rate)

* 3. Final ID Formatting for your map
gen county_id = string(fips_state_county_code, "%05.0f")

export delimited using "data/r/pop_grey.csv", replace

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