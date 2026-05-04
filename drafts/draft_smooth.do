clear all 
set more off

global PATH "C:\Users\ranya\OneDrive - Alma Mater Studiorum Università di Bologna\Desktop\UNIBO\PFE\US\Work"

cd "${PATH}"

****************************************************************


* 1. Set the panel (assuming 'fips' is your county ID)
destring fips, gen(fips_n)
xtset fips_n year

* 2. The Smoothing Loop (The "Watchmen" Way)
gen ucr_pop_smoothed = .
levelsof fips_n, local(counties)

foreach c in `counties' {
    * Fits a local curve to the UCR population for each county
    * bwidth(2) means it looks at a 2-year window to decide the "smoothness"
    cap lpoly ucr_population year if fips_n == `c', degree(0) bwidth(2) at(year) gen(temp_p) nograph
    cap replace ucr_pop_smoothed = temp_p if fips_n == `c'
    cap drop temp_p
}

* 3. Calculate your Hate Crime Rate using the SMOOTHED version
gen hc_rate = (hate_crimes / ucr_pop_smoothed) * 100000