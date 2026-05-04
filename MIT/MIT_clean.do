/*------------------------------------------------
	In this file I am cleaning MIT Election Data
---------------------------------------------------
*/

 
 
*********************************************
* Set up
*********************************************

clear all
set more off


global PATH "C:\Users\ranya\OneDrive - Alma Mater Studiorum Università di Bologna\Desktop\UNIBO\PFE\US\Work"
global data "${PATH}/data/raw"
global clean "${PATH}/data/clean"

cd "${PATH}"



*********************************************
* cleaning
*********************************************

clear 
import delimited "${data}/MIT_county/countypres_2000-2024.csv", bindquote(strict) varnames(1) encoding(utf8)

ds 

//bindquote(strict) ignore quotes and commas in names treated as a part of string

tab party
replace party = lower(party)
keep if party == "democrat" | party == "republican" //other parties still
//counted in total votes

rename county_fips fips
rename candidatevotes candidate_votes
rename state_po state_abv

drop if fips == "NA"
drop if party == "NA"
drop version office mode candidate

* collapsing before reshaping because as of 2020 MIT includes the mode column to identify voting location/procedure

destring candidate_votes, replace

collapse (sum) candidate_votes (mean) totalvotes ///
         (firstnm) state county_name state_abv, ///
         by(fips year party)

reshape wide candidate_votes, i(fips year) j(party) string
rename candidate_votes* candidate_votes_*

* vote shares
gen share_dem = 0
gen share_rep = 0

replace share_dem= candidate_votes_democrat/ totalvotes
replace share_rep = candidate_votes_republican/ totalvotes

drop candidate_votes_* totalvotes 


save "$clean/MIT_clean.dta", replace
