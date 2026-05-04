
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


**** COLLAPSE FROM INCIDENTS TO AGENCY-YEARS
* We use (sum) on unique_id to get the number of events.
* We use (max) on participation to know if they were active at all that year.
collapse (sum) incidents = marker_incident ///
         (max) participating_year quarters_active ///
         (first) fips_state_county_code, by(ori year)


fillin ori year
*Carry the FIPS code to the newly created 'fillin' rows
bysort ori (fips_state_county_code): replace fips_state_county_code = fips_state_county_code[1] if missing(fips_state_county_code)


* If Stata filled it in (_fillin == 1), incidents should be 0 not missing.
replace incidents = 0 if _fillin == 1
replace participating_year = 0 if missing(participating_year)
		 
* Identify if the year was "Missed" (No paperwork sent to FBI)
gen missed_year = 0
replace missed_year = 1 if _fillin == 1 & (participating_year == 0 | participating_year == .)
replace missed_year = 1 if _fillin == 0 & participating_year == 0	 
		 

		 ****** Clusters of silence
* . CALCULATE RELIABILITY METRICS (For  Heatmap)
* Total years missed by each agency (ORI)
bysort ori: egen total_missed_by_ori = total(missed_year)
* . Squash the data to the Agency level first (One row per ORI)
collapse (mean) total_missed_by_ori (first) fips_state_county_code, by(ori)
* This calculates the "Reliability Score" for the whole county
collapse (mean) avg_years_missed = total_missed_by_ori, by(fips_state_county_code)



 * Collapse to the County Level (Mean years missed per county)
collapse (mean) avg_years_missed, by(fips_state_county_code)

* Export for R
export delimited using "data/r/missed_ori.csv", replace



* Average years missed by all agencies in the County (FIPS)
bysort fips_state_county_code: egen avg_years_missed = mean(total_missed_by_ori)		 
export delimited using "data/r/missed_county.csv", replace	 
		 

*  Collapse to the County Level (Mean years missed per county)
collapse (mean) avg_years_missed, by(fips_state_county_code)

* Export to a CSV that R can read easily
export delimited using "hate_crime_map_data.csv", replace


* 1. Collapse to the County Level (Mean years missed per county)
collapse (mean) avg_years_missed, by(fips_state_county_code)

* 2. Export to a CSV that R can read easily
export delimited using "hate_crime_map_data.csv", replace
		
		
		**** OLD

**********ensuring every agency has a placeholder for every year so you can see where data is missing.

* Use the population and ori variables from your file to create a list of all known agencies
keep ori year population fips_state_code fips_county_code
duplicates drop ori year, force //the incident file might have multiple rows --> WRONG lose OBS
 //a single agency in a single year (for example, if an agency reported multiple hate crimes



* expand this to include every year for every agency (1990-2023)
/* If _fillin == 0: The agency was "Active." They had an incident.
If _fillin == 1: The agency was "Silent." */
fillin ori year


***** identify Participation Vs Zero reporting

* If the row came from the 'fillin' command, it means no crime was recorded 
gen incident_occurred = (_fillin == 0) // TF Incident reported
gen participated = (population != .) // TF agency active or not
gen years_missed = (participated == 0) //It marks a 1 for every year the agency was totally absent from the record.


* total years missed for each specific agency (ORI)
bysort ori: egen total_missed_agency = total(years_missed)

* Collapse to the County Level
collapse (mean) avg_years_missed = total_missed_agency (sum) total_county_pop = population, by(fips_state_code fips_county_code)


* We use (count) to tally up how many unique IDs exist for that agency-year
collapse (count) incidents = unique_id ///
         (max) participating_year quarters_active ///
         (first) fips_state_county_code, by(ori year)




/*
ith your data structured this way, you can now create the visualizations Herbert recommends:

Heatmap of Silence: Map avg_years_missed. High values (darker colors) indicate counties where the media's influence on hate crimes is impossible to measure because the police aren't participating.

Population Coverage Map: Calculate (total_county_pop / census_county_pop). This shows you where your "Hate Crime Count" is actually a reliable sample of the population. */




* (Since your current file is incident-level, we collapse to agency-year)
collapse (max) participating_year quarters_active (sum) total_incidents = total_num_incidents, by(ori year fips_state_county_code)

* Now, create the missing years for every agency
fillin ori year


