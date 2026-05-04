
clear all
set more off


*==============================================================================
* SPLC HATE GROUP DATA: 2000-2021 LONGITUDINAL CLEANING

cd "C:\Users\ranya\OneDrive - Alma Mater Studiorum Università di Bologna\Desktop\UNIBO\PFE\US\robustness\splc hate"

* 2. Start the processing loop
foreach y of numlist 2000/2021 {
    
    * Import the raw CSV for each year
    import delimited "splc_hate_data_`y'.csv", clear varnames(1)
    
    * Ensure the search is case-insensitive
    gen id_low = lower(ideology_name)

    * --- 3. INDIVIDUAL IDEOLOGY COUNTS---
    gen splc_num_anti_immigra     = strpos(id_low, "anti-immigrant") > 0
    gen splc_num_anti_lgbt        = strpos(id_low, "anti-lgbtq") > 0
    gen splc_num_anti_muslim      = strpos(id_low, "anti-muslim") > 0
    gen splc_num_blacknationalist = (strpos(id_low, "black separatist") > 0 | strpos(id_low, "black nationalist") > 0
    gen splc_num_christian        = strpos(id_low, "christian identity") > 0
    gen splc_num_general          = strpos(id_low, "general hate") > 0
    gen splc_num_hatemusic        = strpos(id_low, "hate music") > 0
    gen splc_num_holocaustdenial  = strpos(id_low, "holocaust denial") > 0
    gen splc_num_kkk              = strpos(id_low, "ku klux klan") > 0
    gen splc_num_neoconfederate   = strpos(id_low, "neo-confederate") > 0
    gen splc_num_neonazi          = strpos(id_low, "neo-nazi") > 0
    gen splc_num_neovolk          = strpos(id_low, "neo-volkisch") > 0 |  strpos(id_low, "Neo-VÃ¶lkisch") > 0
    gen splc_num_skinhead         = strpos(id_low, "racist skinhead") > 0
    gen splc_num_catholic         = strpos(id_low, "traditionalist catholic") > 0
    gen splc_num_white_nat        = strpos(id_low, "white nationalist") > 0

    * --- 4. BROAD CATEGORIZATION (Super-Categories) ---
    * White Supremacy
    gen cat_white_supremacy = (splc_num_white_nat | splc_num_kkk | splc_num_neonazi | ///
                               splc_num_neoconfederate | splc_num_skinhead | ///
                               splc_num_neovolk | splc_num_hatemusic)
    
    * Anti-Identity
    gen cat_anti_identity   = (splc_num_anti_immigra | splc_num_anti_lgbt | ///
                               splc_num_anti_muslim | splc_num_holocaustdenial)

    * Religious Extremism
    gen cat_religious       = (splc_num_christian | splc_num_catholic)

    * Black Nationalist/Separatist
    gen cat_black_nat       = (splc_num_blacknationalist)

    * General Hate
    gen cat_general         = (splc_num_general)
    
    * --- 5. COLLAPSE TO STATE LEVEL ---
    * This sums the rows to create the counts for the map
    collapse (sum) splc_num_* cat_*, by(state_name)
    
    * Add year variable and save temporary Stata file
    gen year = `y'
    save "data/temp/splc/temp_`y'.dta", replace
}

* --- 6. APPEND ALL YEARS INTO ONE MASTER PANEL ---
use "data/temp/splc/temp_2000.dta", clear
foreach y of numlist 2001/2021 {
    append using "temp_`y'.dta"
}

* --- 7. FINAL PANEL FORMATTING ---
sort state_name city_name year

* Label the broad categories for clarity
label variable cat_white_supremacy "Total White Supremacist Chapters"
label variable cat_anti_identity   "Total Anti-Minority Chapters"
label variable cat_religious       "Total Religious Extremist Chapters"
label variable cat_black_nat       "Total Black Nationalist Chapters"
label variable cat_general         "Total General Hate Chapters"

* Save the final master file
save "SPLC_Master_Panel_2000_2021.dta", replace

* 8. Clean up temporary files
foreach y of numlist 2000/2021 {
    erase "temp_`y'.dta"
}

* Check your results
tab year
sum splc_num_*