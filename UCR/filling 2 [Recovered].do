
clear all 
set more off

cd "C:\Users\ranya\Downloads\US\hate_crimes_dta_1991_2024"
use "ucr_hate_crimes_1991_2024", clear


************************
* Variables*
*************************


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






**********************************
* Muller test
**********************************
duplicates report incident_number
duplicates  report unique_id


gen hate_crime_unit = 1 // a dummy for an actual incident 
replace hate_crime_unit = 0 if missing(incident_number) | incident_number == "NA" //IDENTIFY ZERO-REPORTS

bysort unique_id: gen num_counties_split = _N //If a unique_id appears twice (split between counties)
gen weight = 1 / num_counties_split

gen weighted_incidents = hate_crime_unit * weight //weight incidents


****** AGGREGATE TO agency-YEAR


collapse (sum) incidents = weighted_incidents ///
         (max) participating_year quarters_active ///
         (first) fips_state_county_code, by(ori year)
		 
*6. FINAL AGGREGATION TO COUNTY LEVEL
* Since some ORIs are in the same county, we sum again by FIPS
collapse (sum) total_incidents = incidents ///
         (max) participating_year quarters_active, by(fips_state_county_code year) 
		 
		 
		 
preserve

    * Collapse everything into a single national total per year
    collapse (sum) national_total = total_incidents, by(year)

    * Option A: Standard Bar Chart (Good for showing individual years)
    graph bar national_total, over(year, label(angle(45) labsize(small))) ///
        title("Total Weighted Hate Crimes per Year", size(medium)) ///
        ytitle("Number of Incidents") ///
        bar(1, color(navy)) 		 
		 
	* Save the graph
    graph export "output/graph/HC_timeline_bar.png", replace
	
	

	* Option B: Twoway Bar (Often cleaner for long timelines like 1991-2024)
		* Collapse everything into a single national total per year
    collapse (sum) national_total = total_incidents, by(year)
    twoway bar national_total year, ///
        title("Annual Hate Crime Frequency (1991-2024)") ///
        xtitle("Year") ytitle("Total Weighted Incidents") ///
        xlabel(1991(2)2024, angle(45)) ///
        color(ebblue%80) ///
        lcolor(black) lwidth(vthin)
		* Save the graph
    graph export "output/graph/HC_light_timeline_bar.png", replace
	
	
	
	
	
	






*********************************Filling 2 ccode**********************


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
		 
		 
		 
		 
*******************************************************
* 3. THE TRUTH ENGINE: FILLING THE GAPS
*******************************************************
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

* D. YOUR SPECIFIC TREATMENT FOR "MISSED YEAR"
gen missed_year = 0
replace missed_year = 1 if _fillin == 1 & (participating_year == 0 | participating_year == .)
replace missed_year = 1 if _fillin == 0 & participating_year == 0


*******************************************************
* 4. BIRTH YEAR LOGIC: FIXING ADMINISTRATIVE BIAS
*******************************************************

* Find the first year the agency actually appeared (not a fillin)
bysort ori: egen birth_year = min(year) if _fillin == 0
bysort ori (birth_year): replace birth_year = birth_year[1] // so that the brith year is not jsut an empty cell but the actual min 

* Drop years before the agency entered the FBI system
drop if year < birth_year

* Calculate agency-level metrics
gen years_active_so_far= (year - birth_year) + 1
// age of agency at each given pt in time

*  Numerator: Running total of misses up to this point in time
bysort ori (year): gen missed_so_far = sum(missed_year)

*  The Correct Rate:
gen missing_rate_agency = (missed_so_far / years_active_so_far) * 100

export delimited using "data/r/agency_activity.csv", replace



We use (mean) for the rates because if a county has 2 agencies,
* and one is 100% silent and one is 0% silent, the county is 50% silent.

collapse (sum)  county_incidents = incidents ///
         (mean) county_population = population ///
         (mean) county_participation_rate = participating_year ///
         (mean) avg_missing_rate = missing_rate_agency, ///
         by(fips_state_county_code year)

* 6. CUMULATIVE METRIC (Optional snapshot of raw volume)
* This shows the total count of missed years the county has accumulated
bysort fips_state_county_code (year): gen years_missed_so_far = sum(1 - county_participation_rate)

* 7. FINAL ID FORMATTING FOR R
* Ensuring the FIPS stays as a 5-digit string (e.g., "01001")
gen county_id = string(fips_state_county_code, "%05.0f")

export delimited using "data/r/missed_rate_ori.csv", replace
















/* old  agency year issue

*******************************************************
* 5. FINAL COLLAPSE: AGENCY-YEAR -> COUNTY-YEAR
*******************************************************
collapse (sum)  county_incidents = incidents ///
         (mean) county_population = population ///
         (mean) county_participation_rate = participating_year ///
         (mean) avg_missing_rate = missing_rate_agency, ///
         by(fips_state_county_code year)

* Cumulative metric for the evolution map
bysort fips_state_county_code (year): gen years_missed_so_far = sum(1 - county_participation_rate)

* Final ID Formatting
gen county_id = string(fips_state_county_code, "%05.0f")

export delimited using "data/r/missed_rate_ori.csv", replace

*/











****************************************************
**** COLLAPSE FROM INCIDENTS TO AGENCY-YEARS
* We use (sum) on unique_id to get the number of events.
* We use (max) on participation to know if they were active at all that year.
collapse (sum) incidents = marker_incident ///
         (max) participating_year quarters_active population ///
         (first) fips_state_county_code, by(ori year)


fillin ori year

* 1. Anchor every 'filled-in' row to its physical County
bysort ori (fips_state_county_code): replace fips_state_county_code = fips_state_county_code[1] if missing(fips_state_county_code)
replace participating_year = 0 if missing(participating_year)


* 2. Handle missing values for the new 'fillin' rows
replace incidents = 0 if missing(incidents)
sort ori year
bysort ori: replace population = population[_n-1] if missing(population) & _n > 1
//Take the FIPS code from the first row that has one (the [1]) and copy it into all the blank rows . If I don't do this then when averaging pop it will consider it as if that county has 0 population
replace participating_year = 0 if missing(participating_year)


***** Finding Birth year of each agency*****
bysort ori: egen birth_year = min(year) if _fillin == 0
bysort ori (birth_year): replace birth_year = birth_year[1]
* Drop the years before an agency actually existed in the system
* This removes the 'fake' zeros from 1991 for an agency that started in 2005.
drop if year < birth_year
*. Calculate the 'Years Since Entry' (The Denominator)
gen years_active_in_system = (year - birth_year) + 1
* 4. Calculate the Missingness RATE (%)
* Instead of just summing 1s, we look at the proportion.
bysort ori: egen total_missed_by_agency = total(missed_year)
gen missing_rate_agency = (total_missed_by_agency / years_active_in_system) * 100


* 3. SQUASH TO THE COUNTY-YEAR LEVEL
* This keeps 'year' and summarizes all agencies within that county for that specific year
collapse (sum) county_incidents = incidents ///
         (mean) county_population = population ///
         (mean) county_participation_years = participating_year, ///
         by(fips_state_county_code year)

* 4. Calculate the "Data Desert" metric (Running Total)
* This calculates how many years *up to that point* the county has missed
bysort fips_state_county_code (year): gen years_missed_so_far = sum(1 - county_participation_years)

* 5. Format FIPS for R
gen county_id = string(fips_state_county_code, "%05.0f")

* 6. Export the Full Panel
export delimited using "data/r/missed_ori.csv", replace






*****DELETED

/*bysort ori: egen total_missed_by_agency = total(missed_year)
  It sums up every time missed_year was equal to $1$ for that specific ori (agency ID). egen puts final sum into every single row for that agency
gen missing_rate_agency = (total_missed_by_agency / years_active_in_system) * 100
*/

