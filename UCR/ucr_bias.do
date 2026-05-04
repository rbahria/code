clear all
set more off


global PATH "C:\Users\ranya\OneDrive - Alma Mater Studiorum Università di Bologna\Desktop\UNIBO\PFE\US\Work"
global data "${PATH}/data/raw"

cd "${PATH}"


use "${data}/ucr_hate/ucr_hate_crimes_1991_2024.dta", clear



tab bias_motivation_offense_1

*  

***********************************************
*Creating bias indicatos
*********************************************

gen anti_black = 0
gen anti_white = 0
gen anti_jewish = 0
gen anti_muslim = 0
gen anti_hispanic = 0
gen anti_lgbtq = 0
gen anti_asian = 0

* Loop through the first 3 bias slots (standard for most UCR analysis)
forval i = 1/10 {
    replace anti_black = 1 if bias_motivation_offense_`i' == "anti-black"
    replace anti_white = 1 if bias_motivation_offense_`i' == "anti-white"
    replace anti_jewish = 1 if bias_motivation_offense_`i' == "anti-jewish"
    replace anti_muslim = 1 if bias_motivation_offense_`i' == "anti-islamic (muslim)"
    replace anti_hispanic = 1 if bias_motivation_offense_`i' == "anti-hispanic or latino"
    replace anti_asian = 1 if inlist(bias_motivation_offense_`i', "anti-asian", "anti-native hawaiian...")
    replace anti_lgbtq = 1 if inlist(bias_motivation_offense_`i', "anti-gay (male)", "anti-lesbian (female)", "anti-bisexual", "anti-transgender")
}


*************************************************
* Intensity
**********************************************


*the list of biases we just created
local biases anti_black anti_white anti_jewish anti_muslim anti_hispanic anti_lgbtq anti_asian

foreach var in `biases' {
    
    * Intensity Victims and Offenders
    gen `var'_vic = `var' * total_num_of_individual_victims
    gen `var'_off = `var' * total_offenders

    * 2. Offense Type Classification (Check across the wide offense columns)
    gen `var'_violent  = 0
    gen `var'_sexual   = 0
    gen `var'_property = 0
    gen `var'_other    = 0
	* Kaplan-style Target Types
    gen `var'_indiv    = 0
    gen `var'_inst     = 0
	
	
	
	forval n = 1/10 {
       
	   local biases anti_black anti_white anti_jewish anti_muslim anti_hispanic anti_lgbtq anti_asian general_bias

foreach var in `biases' {
    
    forval n = 1/10 {
        
        * 1. VIOLENT (Physical Harm & Threats)
        * Assault, Murder, Manslaughter, Weapons, Kidnapping, Extortion
        replace `var'_violent = 1 if `var'==1 & ///
            (strpos(ucr_offense_code_`n', "assault") > 0 | ///
             strpos(ucr_offense_code_`n', "murder") > 0 | ///
             strpos(ucr_offense_code_`n', "manslaughter") > 0 | ///
             strpos(ucr_offense_code_`n', "weapon") > 0 | ///
             strpos(ucr_offense_code_`n', "kidnapping") > 0 | ///
             strpos(ucr_offense_code_`n', "extortion") > 0)

        * 2. SEXUAL (Sex Crimes & Trafficking)
        replace `var'_sexual = 1 if `var'==1 & ///
            (strpos(ucr_offense_code_`n', "sex offenses") > 0 | ///
             strpos(ucr_offense_code_`n', "prostitution") > 0 | ///
             strpos(ucr_offense_code_`n', "trafficking") > 0 | ///
             strpos(ucr_offense_code_`n', "pornography") > 0)

        * 3. PROPERTY (Economic & Vandalism)
        * Destruction/Vandalism, Arson, Robbery, Burglary, Larceny, Theft, Fraud, Embezzlement, etc.
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

        * 4. OTHER (Everything else, including Drugs and Undocumented)
        replace `var'_other = 1 if `var'==1 & `var'_violent==0 & `var'_sexual==0 & `var'_property==0 & ucr_offense_code_`n' != ""
    }

    * Create weighted victim counts (Müller logic)
    gen `var'_viol_vic = `var'_violent * total_num_of_individual_victims
    gen `var'_sex_vic  = `var'_sexual  * total_num_of_individual_victims
    gen `var'_prop_vic = `var'_property * total_num_of_individual_victims
    gen `var'_oth_vic  = `var'_other    * total_num_of_individual_victims
}
	   
	   
	   
	   
	   
	   
	   
	   
	   
	   
	   
	   
	   
	   
	   
	   
	   
	   
	   
	   
	   
	   
	   /*
	   
	   * 1. VIOLENCE (Aggravated, Simple, Intimidation, Murder, Kidnapping, Sex Offenses, Human Trafficking)
        replace `var'_violent = 1 if `var'==1 & ///
            (strpos(ucr_offense_code_`n', "assault") > 0 | ///
             strpos(ucr_offense_code_`n', "murder") > 0 | ///
             strpos(ucr_offense_code_`n', "sex offenses") > 0 | ///
             strpos(ucr_offense_code_`n', "kidnapping") > 0 | ///
             strpos(ucr_offense_code_`n', "trafficking") > 0)
	
	* 2. PROPERTY (Vandalism, Arson, Robbery, Burglary, Larceny, Motor Vehicle Theft)
        replace `var'_property = 1 if `var'==1 & ///
            (strpos(ucr_offense_code_`n', "vandalism") > 0 | ///
             strpos(ucr_offense_code_`n', "arson") > 0 | ///
             strpos(ucr_offense_code_`n', "robbery") > 0 | ///
             strpos(ucr_offense_code_`n', "burglary") > 0 | ///
             strpos(ucr_offense_code_`n', "theft") > 0 | ///
             strpos(ucr_offense_code_`n', "stolen property") > 0)
}
		* 3. OTHER (Drugs, Fraud, Weapon Violations, Gambling, etc.)
        replace `var'_other = 1 if `var'==1 & `var'_violent==0 & `var'_property==0 & ucr_offense_code_`n' != ""

        * 4. TARGETS (Using Kaplan's built-in dummies)
        replace `var'_indiv = 1 if `var'==1 & vic_type_individual_offense_`n' == 1
        replace `var'_inst  = 1 if `var'==1 & (vic_type_business_offense_`n'==1 | vic_type_religious_offense_`n'==1 | vic_type_government_offense_`n'==1)
    }
	

	  * Step 3: Weighted Intensity Indicators (The Müller Weights)
    gen `var'_viol_vic = `var'_violent * total_num_of_individual_victims
    gen `var'_prop_vic = `var'_property * total_num_of_individual_victims
    gen `var'_other_vic = `var'_other * total_num_of_individual_victims
}
	  
	  
	 tabstat anti_black_viol_vic anti_black_prop_vic anti_jewish_viol_vic anti_jewish_prop_vic, statistics(sum) 
	  
	  
	  
	  

   /* 3. Müller-style Interaction (Victims of Violent vs Property)
    gen `var'_viol_vic = `var'_violent * total_num_of_individual_victims
    gen `var'_prop_vic = `var'_property * total_num_of_individual_victims
} */
























replace bias_motivation_offense_1 = "anti-asian" if strpos(bias_motivation_offense_1, "anti-asian") > 0
replace bias_motivation_offense_1 = "anti-native hawaiian" if strpos(bias_motivation_offense_1, "native hawaiian") > 0
replace bias_motivation_offense_1 = "anti-lgbtq" if strpos(bias_motivation_offense_1, "gay, bisexual, or trans") > 0

gen ucr_victim_cat = ""











/*
* Anti-Black
replace ucr_victim_cat = "Anti-Black" if bias_motivation_offense_1 == "anti-black"

* Anti-Hispanic
replace ucr_victim_cat = "Anti-Hispanic" if bias_motivation_offense_1 == "anti-hispanic or latino"

* Anti-Asian
replace ucr_victim_cat = "Anti-Asian" if inlist(bias_motivation_offense_1, "anti-asian", "anti-native hawaiian")

* Anti-LGBTQ
replace ucr_victim_cat = "Anti-LGBTQ" if inlist(bias_motivation_offense_1, ///
    "anti-gay (male)", "anti-lesbian (female)", "anti-bisexual", ///
    "anti-transgender", "anti-gender non-conforming", "anti-lgbtq")

* Anti-Muslim
replace ucr_victim_cat = "Anti-Muslim" if bias_motivation_offense_1 == "anti-islamic (muslim)"

* Anti-Semitic
replace ucr_victim_cat = "Anti-Semitic" if bias_motivation_offense_1 == "anti-jewish"

* Anti-White
replace ucr_victim_cat = "Anti-White" if bias_motivation_offense_1 == "anti-white"

* General (Disability, Other Religions, etc.)
replace ucr_victim_cat = "General" if ucr_victim_cat == ""

* 3. Check your work
tab ucr_victim_cat */
