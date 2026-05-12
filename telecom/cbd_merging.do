



clear all
set more off


global PATH "C:\Users\ranya\OneDrive - Alma Mater Studiorum Università di Bologna\Desktop\UNIBO\PFE\US\Work"
global data "${PATH}/data/raw"
global clean "${PATH}/data/clean"
global temp "${PATH}/data/temp"
global helper "${PATH}/code/helper"

cd "${PATH}"



*****************************************************************
* Merging
******************************************************************

*application cleaning
use "${temp}/cbds/application.dta", clear

keep app_arn application_id comm_city comm_state fac_callsign app_type last_change_date

drop if missing(application_id)
drop if missing(fac_callsign)

save "${temp}/cbds/application_2.dta", replace

***********
*mERGING

* merge Application to get the Facility IDs
use "${temp}/cbds/app_tracking_party_merged.dta", clear
merge m:1 application_id using "${temp}/cbds/application.dta", keep(match) nogenerate

*merge to facility
merge m:1 facility_id using "${temp}/cbds/facility.dta", keep(match) nogenerate
save"${temp}/cbds/intermediate_merge.dta", replace


* attach the Conglomerate names/flags
use "${temp}/cbds/intermediate_merge.dta", clear
destring party_id, replace force
merge m:1 party_id using "${temp}/cbds/party.dta", keep(match) nogenerate



gen buyer_conglom = conglomerate if is_buyer == 1
label values buyer_conglom cong_lbl

* Drop extra parties to have one row per acquisition event
keep if is_buyer == 1

save "${temp}/final_analysis_sample.dta", replace why m to 1 for facility

