

 
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
* 				cleaning  Facility
******************************************************************


* Clear existing data
clear

/*Import using the dictionary
infile using "${helper}/facility.dct", using("${data}/cdbs_files/facility.dat") delimiter("|") clear*/

import delimited "${data}/cdbs_files/facility.dat", delimiter("|") clear

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
	CA: Class A TV category of low-power TV stations that have similar protections to full-power stations ??

*/

*Keep only TV-related stations
keep if inlist(fac_service, "TV", "DT", "TV" "LD", "TX", "CA")

*back up file
save "${temp}/cbds/facility.dta", replace

*only necessary vars
keep facility_id fac_callsign comm_city comm_state 


******************************************************************
* 				cleaning  application 
******************************************************************










