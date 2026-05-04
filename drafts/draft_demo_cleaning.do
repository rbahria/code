//draft from cleaning demographic US CENSU



/******************* 2010-2020 ****************



*Race and Gender variables
gen pop_white = wa_male + wa_female

* Age categories
gen age_cat = ""
replace age_cat = "0-14"   if inrange(agegrp, 1, 3) // 0 is totals
replace age_cat = "15-24"  if inrange(agegrp, 4, 5)
replace age_cat = "25-39"  if inrange(agegrp, 6, 8)
replace age_cat = "40plus" if agegrp >= 9 & agegrp <= 18

//the empty age_cat contains the data for the totals

* total county-year pop
// idea: for each group defined by fips and year do
bysort fips year: egen pop_total_check = max(tot_pop) if agegrp == 0
bysort fips year: egen pop_total = max(pop_total_check)
drop pop_total_check

* age-groups populations for
bysort fips year age_cat: egen pop_age = total(tot_pop) if agegrp != 0
gen sh_age_0_14   = pop_age / pop_total if age_cat == "0-14"
gen sh_age_15_24  = pop_age / pop_total if age_cat == "15-24"
gen sh_age_25_39  = pop_age / pop_total if age_cat == "25-39"
gen sh_age_40plus = pop_age / pop_total if age_cat == "40plus"



/*collapse (sum) pop_age = tot_pop ///
         (max) pop_total = tot_pop pop_white tot_male tot_female ///
         (firstnm) state_name county_name, ///
         by(fips year age_cat state_fips county_fips) */

* gender totals from agegrp == 0 rows
bysort fips year: egen pop_male_check   = max(tot_male) if agegrp == 0
bysort fips year: egen pop_female_check = max(tot_female) if agegrp == 0

bysort fips year: egen pop_male   = max(pop_male_check)
bysort fips year: egen pop_female = max(pop_female_check)

drop pop_male_check pop_female_check		 
		 
gen sh_male   = pop_male / pop_total
gen sh_female = pop_female / pop_total

* race: white / nonwhite
bysort fips year: egen pop_white_check = max(wa_male + wa_female) if agegrp == 0
bysort fips year: egen pop_white = max(pop_white_check)

drop pop_white_check

gen pop_nonwhite = pop_total - pop_white

gen sh_white    = pop_white / pop_total
gen sh_nonwhite = pop_nonwhite / pop_total

* one row per county-year
collapse (max) pop_total sh_age_0_14 sh_age_15_24 sh_age_25_39 sh_age_40plus ///
               sh_male sh_female sh_white sh_nonwhite, ///
    by(fips year state_fips county_fips state_name county_name)	
	
	
	
	

	
	
	
	

keep fips state_fips county_fips year state_name county_name pop_total ///
     sh_white sh_nonwhite sh_male sh_female age_cat sh_age
	*/