/*------------------------------------------------
	In this file I am looping over splc files and counting hate groups
---------------------------------------------------
*/



clear all
set more off


* folder with the yearly SPLC files
global splc_dir "C:\Users\ranya\OneDrive - Alma Mater Studiorum Università di Bologna\Desktop\UNIBO\PFE\US\Work\data\raw\splc hate"
global out_dir "C:/Users/ranya/OneDrive - Alma Mater Studiorum Università di Bologna/Desktop/UNIBO/PFE/US/Work/output/graphs/splc"



tempfile results //temp dataset
tempname posth // temp posting handle


postfile `posth' year n_groups using `results', replace // results table filled in with handle posth


* Raw count of groups
forvalues y = 2000/2021 {
    
    capture confirm file "$splc_dir\splc_hate_data_`y'.csv"
    //check if file exists
    if _rc == 0 { // return code success (if file exists)
        import delimited "$splc_dir\splc_hate_data_`y'.csv", clear varnames(1) stringcols(_all)
        
        count //raw count
        local n = r(N)
        
        post `posth' (`y') (`n')
    }
    else {
        di as error "File for year `y' not found"
    }
}

postclose `posth'

use `results', clear
list, clean

save "$splc_dir\splc_group_counts_2000_2021.dta", replace
export delimited using "$splc_dir\group_counts_2000_2021.csv", replace


*************************************************
* unique groups
***********************************************
clear all
set more off

global splc_dir "C:\Users\ranya\OneDrive - Alma Mater Studiorum Università di Bologna\Desktop\UNIBO\PFE\US\Work\data\raw\splc hate"

tempfile results
tempname posth

postfile `posth' year n_groups using `results', replace

forvalues y = 2000/2021 {

    capture confirm file "$splc_dir\splc_hate_data_`y'.csv"

    if _rc == 0 {

        import delimited "$splc_dir\splc_hate_data_`y'.csv", ///
            clear varnames(1) stringcols(_all)

        *cleanup of var strings
        foreach v in name ideology_name state_name city_name ein statewide {
            replace `v' = trim(`v')
        }

        * mark first observation within each unique combination
        bysort name ideology_name state_name city_name ein statewide: ///
            gen tag_unique = (_n == 1)
//tag_unique = 1 for the first row of each unique combination and 0 for all duplicates after that
        count if tag_unique == 1
        local n_groups = r(N)

        post `posth' (`y') (`n_groups')
    }
    else {
        di as error "File for year `y' not found"
    }
}

postclose `posth'

use `results', clear
sort year
list, clean

*Plot 1
twoway line n_groups year, ///
    title("Hate group chapters by year") ///
    ytitle("Number of groups") ///
    xtitle("Year")

* Plot 2 
twoway line n_groups year, ///
lcolor("0 140 140") lwidth(medium) ///  <-- Direct RGB usage
    title("Evolution of Hate group chapters") ///
    subtitle(" US 2000–2021") ///
    ytitle("Number of chapters") ///
    xtitle("") ///
    xlabel(2000(2)2021, angle(45)) ///
    ylabel(, grid) ///
    graphregion(color(white))
	graph export "${out_dir}\splc_chapters_year.png", replace
	


