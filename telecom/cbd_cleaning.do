

 
 
/*
	app_tracking : Application X was a Sale on date Y
	app_party: Party_id
	ownership_group: Station A belongs to Group

	
	to look into the translator stations TX 
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
global helper "${PATH}/code/helper"

cd "${PATH}"





******************************************************************
* 	cleaning  Facility: What stations are they?
******************************************************************
* 

* Clear existing data
clear

import delimited "${data}/cdbs_files/facility.dat", delimiter("|") clear

*renaming
rename v1  comm_city
rename v2  comm_state
rename v3  eeo_rpt_ind
rename v4  fac_address1
rename v5  fac_address2
rename v6  fac_callsign
rename v7  fac_channel
rename v8  fac_city
rename v9  fac_country
rename v10 fac_frequency
rename v11 fac_service
rename v12 fac_state
rename v13 fac_status_date
rename v14 fac_type
rename v15 facility_id
rename v16 lic_expiration_date
rename v17 fac_status
rename v18 fac_zip1
rename v19 fac_zip2
rename v20 station_type
rename v21 assoc_facility_id
rename v22 callsign_eff_date
rename v23 tsid_ntsc
rename v24 tsid_dtv
rename v25 digital_status
rename v26 sat_tv
rename v30 last_change_date

/*
 possibly v27 Network Affilication
		 v28 Market Name/DMA 
		 */

drop in 1/3
drop  v31 v32


*labels
label variable comm_city           "City of community served"
label variable comm_state          "State of community served"
label variable eeo_rpt_ind         "EEO report indicator (5+ employees)"
label variable fac_address1        "Facility address 1"
label variable fac_address2        "Facility address 2"
label variable fac_callsign        "Station callsign"
label variable fac_channel         "Channel number"
label variable fac_city            "city where fac loccated/Mailing city"
label variable fac_country         "Country"
label variable fac_frequency        "Assigned frequency"
label variable fac_service         "Service type (TV, DT, FM, etc.)"
label variable fac_state           "Mailing state"
label variable fac_status_date     "Date status took effect"
label variable fac_status          "last status of fac application processing"
label variable fac_type            "Facility type"
label variable facility_id         "Unique Facility ID (Primary Key)"
label variable lic_expiration_date "License expiration date"
label variable fac_zip1            "Zipcode (first 5)"
label variable fac_zip2            "Zipcode (last 4)"
label variable station_type        "Main or auxiliary station"
label variable assoc_facility_id   "Associated ID (for rebroadcasts)"
*label variable frn                 "FCC Registration Number"
label variable callsign_eff_date   "Date callsign became effective"
label variable tsid_ntsc           "Analog Transport Stream ID"
label variable tsid_dtv            "Digital Transport Stream ID"
label variable digital_status      "Digital (D) or Hybrid (H)"
label variable sat_tv              "Satellite TV designation"
label variable last_change_date    "Date record last updated"


/*
 fac_service is the license type of each facility
	DT: Digital TV
	TV: Analog TV
	LD: Lower Power Digital (Smaller TV stations with limited range)
	TX: repeater stattions 
	AM/FM radio
	FX: Radio Repeaters
	CA: Class A TV category of low-power TV stations that have similar
	protections to full-power stations ??

*/
* keep if inlist(fac_service, "TV", "DT", "TV" "LD", "TX", "CA")

*back up file
save "${temp}/cbds/facility_backup.dta", replace

*Keep only TV-related stations
keep if inlist(fac_service, "TV", "DT", "LD", "CA")

*Keep only commercial stations
keep if inlist(fac_type, "CDT", "CT")

*only US
keep if fac_country == "US"

*only Main stations
tab station_type
keep if station_type == "M"

drop eeo_rpt_ind fac_channel fac_frequency fac_country fac_address2 lic_expiration_date fac_zip2 station_type assoc_facility_id tsid_ntsc tsid_dtv sat_tv v27 v28 v29

destring facility_id , replace


save "${temp}/cbds/facility.dta", replace



******************************************************************
* 		cleaning  application : intent
******************************************************************

//only if a request( filing request) was filed, would need app_tracking.dta to determine if  FCC said yes

import delimited "${data}/cdbs_files/application.dat", delimiter("|") rowrange(4) clear

drop v27 v28

rename v1  app_arn
rename v2  app_service
rename v3  application_id
rename v4  facility_id
rename v5  file_prefix
rename v6  comm_city
rename v7  comm_state
rename v8  fac_frequency
rename v9  station_channel
rename v10 fac_callsign
rename v11 general_app_service
rename v12 app_type
rename v13 paper_filed_ind
rename v14 dtv_type
rename v26 last_change_date

/*
possible:
		v15 frn
		v20 network_affiliation
		v22 county_name		
*/

label variable app_arn "Filing date + processing order (ARN)"
label variable app_service "Service addressed by application (e.g., TV, DT)"
label variable application_id "System-generated unique ID for the filing"
label variable facility_id "Unique ID for the station"
label variable file_prefix "Combination of app type and facility type codes"
label variable fac_frequency "Frequency assigned to the station"
label variable station_channel "Station channel number"
label variable fac_callsign "Station call sign"
label variable general_app_service "Service type (AM, FM, TV, or DT) from form"
label variable app_type "Type of application (e.g., AL=Assignment, TC=Transfer)"
label variable paper_filed_ind "Indicator for paper-filed forms"
label variable dtv_type "DTV transition status (Pre/Post/Both)"
label variable last_change_date "Date the application was last updated"

/*
	*facility id link to facility_dta
	* app_type only AL (Assignment of License) and TC ( Transfer of Control) --> sales
	* application_id link to party.Dta
	
	* app_arn
*/


save "${temp}/cbds/application_backup.dta", replace


*Filter for Acquisition-related types
keep if inlist(app_type, "AL", "TC", "BAL", "BTC")

*filter for TV only
keep if inlist(app_service, "DT", "TV", "CA")


drop file_prefix  v25 v24 v23 v17 v15 v18 v19 v20
drop fac_frequency station_channel  paper_filed_ind 
drop v21 
drop general_app_service
drop dtv_type

destring facility_id, replace
destring application_id, replace 

save "${temp}/cbds/application.dta", replace


******************************************************************
* 		cleaning  app_tracking : approval
******************************************************************


clear
import delimited "${data}/cdbs_files/app_tracking.dat", delimiter("|") ///
stringcols(_all) varnames(nonames) clear


keep v1-v11

rename v1  application_id
rename v2  app_status_date
rename v3  cutoff_date
rename v4  cutoff_type
rename v5  cp_exp_date
rename v6  app_status
rename v7  dtv_checklist
rename v8  amendment_stamped_date
rename v9  accepted_date
rename v10 tolling_code
rename v11 last_change_date

* Convert dates
rename app_status_date app_status_str
gen app_status_date = date(app_status_str, "MDY")
drop app_status_str
format app_status_date %tdnn/dd/CCYY
gen year_status= year(app_status_date)

* Keep only Granted applications 
keep if inlist(app_status, "GRANT", "GRNT")

keep application_id app_status app_status_date year
destring application_id, replace

save "${temp}/cbds/app_tracking.dta", replace


******************************************************************
* 		cleaning  app_party to link application_id to party_id
******************************************************************

clear
import delimited "${data}/cdbs_files/app_party.dat", delimiter("|") ///
 stringcols(_all) varnames(nonames) clear

keep v1-v11
rename v1 application_id
rename v2 party_id
rename v3 party_type
rename v4 cert_title
rename v5 cert_date
rename v6 other_fcc_id
rename v7 party_notify_ind
rename v8 party_relationship
rename v9 sig_present_ind
rename v10 sig_name
rename v11 last_change_date



/*
 party_type |   
------------+-----------------------------------
      AECRT 	
      AOCRT |  
      APCRT |    
      APPLI | applicant
      ASTRE |  Assignee/Transferee --> buyer
      ASTRO |     ssignor/Transferor --> Seller 
      CNREP |   Lawyer
      CNTSE |     
      CNTSO |    
      CRTEN |    
      NCCRT |     
      OWNEN |    
      RSPON |     
	  */

keep application_id party_id party_type 
destring application_id, replace
destring party_id
save "${temp}/cbds/app_party.dta", replace


*merge to app_tracking
use "${temp}/cbds/app_party.dta", clear

merge m:m application_id using "${temp}/cbds/app_tracking.dta"

keep if _merge == 3
drop _merge
destring application_id party_id, replace

save "${temp}/cbds/app_tracking_party_merged.dta", replace


******************************************************************
* 		cleaning  party
******************************************************************


clear
import delimited "${data}/cdbs_files/party.dat", delimiter("|") ///
stringcols(_all) varnames(nonames) clear

keep v1-v16

rename v1 party_id
rename v2 party_address1
rename v3 party_address2
rename v4 party_citizenship
rename v5 party_city
rename v6 party_company
rename v7 party_country
rename v8 party_email
rename v9 party_fax
rename v10 party_legal_name
rename v11 party_name
rename v12 party_phone
rename v13 party_state
rename v14 party_zip1
rename v15 party_zip2
rename v16 last_change_date

destring party_id, replace
drop if missing(party_id)

drop if missing(trim(party_name))


*sinclair group
gen conglomerate = 0
replace  conglomerate = 1 if strpos(party_name, "SINCLAIR") > 0
tab party_name if conglomerate == 1

*Nextar
replace conglomerate = 2 if strpos(party_name, "NEXSTAR") > 0
tab party_name if conglomerate == 2

*Gray
replace conglomerate = 3 if strpos(party_name, "GRAY TELE") > 0

tab party_name if conglomerate == 3

drop party_phone party_email party_citizenship 

save "${temp}/cbds/party.dta", replace


******************************************************************
* 		cleaning  ownership_group 
******************************************************************

clear
import delimited "${data}/cdbs_files/ownership_group.dat", delimiter("|") ///
 stringcols(_all) varnames(nonames) clear

keep v1-v12

rename v1 ownership_group_id
rename v2 application_id
rename v3 fac_callsign
rename v4 facility_id
rename v5 fac_service
rename v6 comm_city
rename v7 comm_state
rename v8 fac_service_o
rename v9 app_arn
rename v10 file_prefix
rename v11 order_number
rename v12 last_update_date

destring ownership_group_id application_id facility_id, replace
drop order_number file_prefix


save "${temp}/cbds/ownership_group.dta", replace





