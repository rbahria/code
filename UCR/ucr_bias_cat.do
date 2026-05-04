/*--------------------------------------------------------

NOTES SO I DON'T GO CRAZY

1. Argument here: Not all crimes are equal
--> intensity , will use var_vic as a weight 
--> if an attack has 4 victims it is counted as 4 not 1 --> Terror effect


2. creating 4 distinct channels for hate_crime_incident_present
			* Violent physical threat
			* Sexual bodily integrity
			* Property
			* other
--> MULTIDIMENSIONAL: will check all possible offenses by looping through them
and flag any master indicator as 1 if bias_motivation_offense*=1

3. Targets: Indiv vs Institutional ( synagogues/mosques/businesses)
--> use _indiv and _inst to categorize the type of victim.

4. if 10 people jump one person, this counted as 1 incident but multiplying the nb of
offenders, we can create a metric for "offender activity" --> Emboldened to act in groups
--> Are crimes more mob-like or lone-wolf attakcs due to biased media
------------------------------------------------------------- */








 
*********************************************
* Set up
*********************************************

clear all
set more off


global PATH "C:\Users\ranya\OneDrive - Alma Mater Studiorum Università di Bologna\Desktop\UNIBO\PFE\US\Work"
global data "${PATH}/data/raw"

cd "${PATH}"


use "${data}/ucr_hate/ucr_hate_crimes_1991_2024.dta", clear



tab bias_motivation_offense_1
tab bias_motivation_offense_1 if strpos(lower(bias_motivation_offense_1), "anti-")

************************************************
* cleaning
***********************************************

* destringing victim types
foreach type in individual business government society unknown financial religious other {
    forval n = 1/10 {
      
        capture destring vic_type_`type'_offense_`n', replace
    }
}




gen check_muslim_arab = 0

forval i = 1/10 {

    replace check_muslim_arab = 1 if strpos(lower(bias_motivation_offense_`i'), "anti-islamic") > 0 | ///
                                     strpos(lower(bias_motivation_offense_`i'), "anti-arab") > 0
}

* 2. See the raw numbers by year
tab year check_muslim_arab if check_muslim_arab == 1
 
*********************************************
*Creating bias indicatos
*********************************************

gen anti_black = 0
gen anti_white = 0
gen anti_jewish = 0
gen anti_muslim = 0
gen anti_hispanic = 0
gen anti_lgbtq = 0
gen anti_asian = 0
gen general_bias = 0

forval i = 1/10 {
    replace anti_black = 1 if bias_motivation_offense_`i' == "anti-black"
    replace anti_white = 1 if bias_motivation_offense_`i' == "anti-white"
    replace anti_jewish = 1 if bias_motivation_offense_`i' == "anti-jewish"
 replace anti_muslim = 1 if (strpos(bias_motivation_offense_`i', "anti-islamic") > 0 | ///
  strpos(bias_motivation_offense_`i', "anti-arab") > 0)
    replace anti_hispanic = 1 if bias_motivation_offense_`i' == "anti-hispanic or latino"
    replace anti_asian = 1 if inlist(bias_motivation_offense_`i', "anti-asian", "anti-native hawaiian...")
    replace anti_lgbtq = 1 if inlist(bias_motivation_offense_`i', "anti-gay (male)", "anti-lesbian (female)", "anti-bisexual", "anti-transgender")
	}
	
	//doing it outside the loop to not mess up sorting
	replace general_bias = 1 if hate_crime_incident_present == "one or more hate crime incidents present" & ///
                            anti_black == 0 & anti_white == 0 & ///
                            anti_jewish == 0 & anti_muslim == 0 & ///
                            anti_hispanic == 0 & anti_lgbtq == 0 & ///
                            anti_asian == 0
	

*************************************************
* Intensity
*************************************************

local biases anti_black anti_white anti_jewish anti_muslim anti_hispanic anti_lgbtq anti_asian general_bias


foreach var in `biases' {
    
     * Intensity Victims and Offenders
    gen `var'_vic      = `var' * total_num_of_individual_victims
    gen `var'_off      = `var' * total_offenders
	
	 *  Offense Type Classification
    gen `var'_violent  = 0
    gen `var'_sexual   = 0
    gen `var'_property = 0
    gen `var'_other    = 0
	
	*Offense victim type
    gen `var'_indiv    = 0
    gen `var'_inst     = 0

    forval n = 1/10 {
        
        * VIOLENT (Physical Harm & Threats)
        replace `var'_violent = 1 if `var'==1 & ///
            (strpos(ucr_offense_code_`n', "assault") > 0 | ///
             strpos(ucr_offense_code_`n', "murder") > 0 | ///
             strpos(ucr_offense_code_`n', "manslaughter") > 0 | ///
             strpos(ucr_offense_code_`n', "weapon") > 0 | ///
             strpos(ucr_offense_code_`n', "kidnapping") > 0 | ///
             strpos(ucr_offense_code_`n', "extortion") > 0)

        * SEXUAL (Sex Crimes & Human Rights)
        replace `var'_sexual = 1 if `var'==1 & ///
            (strpos(ucr_offense_code_`n', "sex offenses") > 0 | ///
             strpos(ucr_offense_code_`n', "prostitution") > 0 | ///
             strpos(ucr_offense_code_`n', "trafficking") > 0 | ///
             strpos(ucr_offense_code_`n', "pornography") > 0)
 
        * PROPERTY (Theft, Vandalism, Financial)
        replace `var'_property = 1 if `var'==1 & ///
            (strpos(ucr_offense_code_`n', "destruction") > 0 | ///
             strpos(ucr_offense_code_`n', "vandalism") > 0 | ///
             strpos(ucr_offense_code_`n', "arson") > 0 | ///
             strpos(ucr_offense_code_`n', "robbery") > 0 | ///
             strpos(ucr_offense_code_`n', "burglary") > 0 | ///
             strpos(ucr_offense_code_`n', "theft") > 0 | ///
             strpos(ucr_offense_code_`n', "fraud") > 0 | ///
             strpos(ucr_offense_code_`n', "stolen property") > 0 | ///
             strpos(ucr_offense_code_`n', "counterfeiting") > 0 | ///
             strpos(ucr_offense_code_`n', "bribery") > 0 | ///
             strpos(ucr_offense_code_`n', "gambling") > 0)

        * TARGET TYPE (Individual vs Institutional)
        replace `var'_indiv = 1 if `var'==1 & vic_type_individual_offense_`n' == 1
        replace `var'_inst  = 1 if `var'==1 & (vic_type_business_offense_`n'==1 | vic_type_religious_offense_`n'==1 | vic_type_government_offense_`n'==1)
    }

    * other
    replace `var'_other = 1 if `var'==1 & `var'_violent==0 & `var'_sexual==0 & `var'_property==0

    * weighted victim counts 
    gen `var'_viol_vic = `var'_violent  * total_num_of_individual_victims
    gen `var'_sex_vic  = `var'_sexual   * total_num_of_individual_victims
    gen `var'_prop_vic = `var'_property * total_num_of_individual_victims
    gen `var'_oth_vic  = `var'_other    * total_num_of_individual_victims
}

save  "data/temp/ucr/ucr_cat_temp.dta", replace






********************************
* Plots
*********************************

use "data/temp/ucr/ucr_cat_temp.dta", clear

**** Incidence
local teal  "0 140 140"   // Muslim/Arab
local rose  "160 100 100" // Hispanic
local gold  "190 150 60"  // Black
local sage  "130 170 160" // Jewish
local beige "220 200 160" // LGBTQ

graph bar (sum) anti_muslim anti_hispanic anti_black ///
                anti_jewish anti_lgbtq anti_asian ///
                anti_white general_bias, ///
    over(year, label(angle(45) labsize(vsmall))) ///
    stack ///
    title("Total Number of Hate Crime Incidents", size(medium)) ///
    subtitle("Frequency of Targeted Attacks (1991-2024)", size(small)) ///
    ytitle("Number of Incidents ") ///
    legend(order(1 "Muslim/Arab" 2 "Hispanic" 3 "Black" 4 "Jewish" ///
                 5 "LGBTQ" 6 "Asian" 7 "White" 8 "General Bias") ///
           size(vsmall) rows(2) position(6) region(lcolor(none))) ///
    bar(1, color("`teal'")) ///
    bar(2, color("`rose'")) ///
    bar(3, color("`gold'")) ///
    bar(4, color("`sage'")) ///
    bar(5, color("`beige'")) ///
    bar(6, color(gs10)) ///
    bar(7, color(gs13)) ///
    bar(8, color(black)) ///
    graphregion(color(white))
save "data/temp/ucr/incidence_cat.dta", replace

****intesity
preserve

*  sum all the binary flags and intensity weights

	collapse (sum) anti_black_vic anti_white_vic anti_jewish_vic anti_muslim_vic ///
				   anti_hispanic_vic anti_lgbtq_vic anti_asian_vic general_bias_vic, by(year)

	label data "Yearly Hate Crime Intensity"
	save "data/temp/ucr/county_year_cat.dta", replace



*only three cat
twoway (line anti_muslim_vic year, lcolor(navy) lwidth(medium)) ///
       (line anti_hispanic_vic year, lcolor(maroon) lwidth(medium)) ///
       (line anti_black_vic year, lcolor(gs8) lwidth(medium)), ///
       xlabel(1991(5)2024) ///  // Labels every 5 years to keep it clean
       title("Evolution of Targeted Hate Crimes (1991-2024)") ///
       ytitle("Total Victims") ///
       legend(order(1 "Anti-Muslim" 2 "Anti-Hispanic" 3 "Anti-Black"))
	
	
	
* Good plot but arab/muslim makes no sense
		local teal  "0 140 140"   // Muslim/Arab
		local rose  "160 100 100" // Hispanic
		local gold  "190 150 60"  // Black
		local sage  "130 170 160" // Jewish
		local beige "220 200 160" // LGBTQ


twoway (line anti_muslim_vic year, lcolor("`teal'") lwidth(medthick)) ///     
       (line anti_hispanic_vic year, lcolor("`rose'") lwidth(medthick)) ///   
       (line anti_black_vic year, lcolor("`gold'") lwidth(medium)) ///        
       (line anti_jewish_vic year, lcolor("`sage'") lwidth(medium)) ///       
       (line anti_lgbtq_vic year, lcolor("`beige'") lwidth(medium)) ///      
       (line anti_asian_vic year, lcolor(gs10) lpattern(dash)) ///            
       (line anti_white_vic year, lcolor(gs13) lpattern(dot)) ///             
       (line general_bias_vic year, lcolor(black) lpattern(shortdash)), ///   
       xlabel(1991(5)2024, labsize(small) grid) ///
       ylabel(, labsize(small) angle(0) grid format(%9.0fc)) ///
       title("Hate Crime Intensity by Bias Motivation", size(medium)) ///
       ytitle("Total Victims") xtitle("Year") ///
       legend(order(1 "Muslim/Arab" 2 "Hispanic" 3 "Black" 4 "Jewish" ///
                    5 "LGBTQ" 6 "Asian" 7 "White" 8 "General Bias") ///
              size(vsmall) rows(2) position(6) region(lcolor(none))) ///
       graphregion(color(white))
	graph export "output/graphs/ucr/cat_lines.png", replace
	

	

* Stacked bar plot
	local teal  "0 140 140"   // Muslim/Arab
	local rose  "160 100 100" // Hispanic
	local gold  "190 150 60"  // Black
	local sage  "130 170 160" // Jewish
	local beige "220 200 160" // LGBTQ	
	
graph bar (sum) anti_muslim_vic anti_hispanic_vic anti_black_vic ///
					anti_jewish_vic anti_lgbtq_vic anti_asian_vic ///
					anti_white_vic general_bias_vic, ///
		over(year, label(angle(45) labsize(vsmall))) ///
		stack ///
		title("Total Victim Intensity by Year", size(medium)) ///
		ytitle("Total Number of Victims") ///
		legend(order(1 "Muslim/Arab" 2 "Hispanic" 3 "Black" 4 "Jewish" ///
					 5 "LGBTQ" 6 "Asian" 7 "White" 8 "General Bias") ///
			   size(vsmall) rows(2) position(6) region(lcolor(none))) ///
		bar(1, color("`teal'")) ///
		bar(2, color("`rose'")) ///
		bar(3, color("`gold'")) ///
		bar(4, color("`sage'")) ///
		bar(5, color("`beige'")) ///
		bar(6, color(gs10)) ///
		bar(7, color(gs13)) ///
		bar(8, color(black)) ///
		graphregion(color(white))
		graph export "output/graphs/ucr/cat_stacked.png", replace
	
	
	
	
	
	
restore




