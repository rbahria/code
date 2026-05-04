/*---------------------------------------------------------------------
In this file I am looping over splc files to create chapter categories
----------------------------------------------------------------------
*/


clear all
set more off

cd "C:\Users\ranya\OneDrive - Alma Mater Studiorum Università di Bologna\Desktop\UNIBO\PFE\US\Work"





************************************************
* Looping over files
************************************************

foreach y of numlist 2000/2021 {
    
    import delimited "data/raw/splc hate/splc_hate_data_`y'.csv", clear varnames(1)
    gen id_low = lower(ideology_name)

    * ---  INDIVIDUAL IDEOLOGY COUNTS ---
    gen splc_anti_immigra     = (strpos(id_low, "anti-immigrant") > 0)
    gen splc_anti_lgbt        = (strpos(id_low, "anti-lgbtq") > 0)
    gen splc_anti_muslim      = (strpos(id_low, "anti-muslim") > 0)
    gen splc_blacknationalist = (strpos(id_low, "black separatist") > 0 | strpos(id_low, "black nationalist") > 0)
    gen splc_christian        = (strpos(id_low, "christian identity") > 0)
    gen splc_general          = (strpos(id_low, "general hate") > 0)
    gen splc_hatemusic        = (strpos(id_low, "hate music") > 0)
    gen splc_holocaustdenial  = (strpos(id_low, "holocaust denial") > 0)
    gen splc_kkk              = (strpos(id_low, "ku klux klan") > 0)
    gen splc_neoconfederate   = (strpos(id_low, "neo-confederate") > 0)
    gen splc_neonazi          = (strpos(id_low, "neo-nazi") > 0)
    gen splc_neovolk          = (strpos(id_low, "neo-volkisch") > 0 | strpos(id_low, "vã¶lkisch") > 0)  
    gen splc_skinhead         = (strpos(id_low, "racist skinhead") > 0)
    gen splc_catholic         = (strpos(id_low, "traditionalist catholic") > 0)
    gen splc_white_nat        = (strpos(id_low, "white nationalist") > 0)

    * --- BROAD CATEGORIZATION ---
    gen cat_white_supremacy = (splc_white_nat | splc_kkk | splc_neonazi | ///
                               splc_neoconfederate | splc_skinhead | ///
                               splc_neovolk | splc_hatemusic)
    
    gen cat_anti_identity   = (splc_anti_immigra | splc_anti_lgbt | ///
                               splc_anti_muslim | splc_holocaustdenial)

    gen cat_religious       = (splc_christian | splc_catholic)
    gen cat_black_nat       = (splc_blacknationalist)
    gen cat_general         = (splc_general)
    

	* State level 
    collapse (sum) splc_* cat_*, by(state_name)
    
    gen year = `y'
    
    * folders when they don't exist
    capture mkdir "data"
    capture mkdir "data/temp"
    capture mkdir "data/temp/splc"
    save "data/temp/splc/temp_`y'.dta", replace
}

* append
use "data/temp/splc/temp_2000.dta", clear
foreach y of numlist 2001/2021 {
    append using "data/temp/splc/temp_`y'.dta"
}

* panel formatting
sort state_name year

label variable cat_white_supremacy "Total White Supremacist Chapters"
label variable cat_anti_identity   "Total Anti-Minority Chapters"
label variable cat_religious       "Total Religious Extremist Chapters"
label variable cat_black_nat       "Total Black Nationalist Chapters"
label variable cat_general         "Total General Hate Chapters"

save "data/temp/splc/splc_master_categ_2000_2021.dta", replace

* clean up temporary files
foreach y of numlist 2000/2021 {
    erase "data/temp/splc/temp_`y'.dta"
}

tab year
sum splc_*

tabstat splc_*, by(year) statistics(sum)

duplicates report state_name year

**********************************************
*	bar plots
***********************************************
graph bar (sum) cat_white_supremacy cat_anti_identity cat_religious cat_black_nat cat_general, ///
    over(year, label(angle(45))) ///
    title("Total Hate Group Chapters in the U.S. (2000-2021)") ///
    ytitle("Number of Chapters") ///
    legend(label(1 "White Supremacy") label(2 "Anti-Identity") ///
           label(3 "Religious") label(4 "Black Nat") label(5 "General"))

* Bar plot more asthetic all years

local color1 "0 140 140"     // Deep Teal
local color2 "130 170 160"   // Sage Green
local color3 "190 150 60"    // Deep Gold
local color4 "220 200 160"   // Sandy Beige
local color5 "160 100 100"   // Muted Rose

graph bar (sum) cat_white_supremacy cat_anti_identity cat_religious cat_black_nat cat_general, ///
    over(year, label(angle(45) labsize(vsmall))) ///
    title("Total Hate Group Chapters in the U.S. (2000-2021)", size(medium)) ///
    ytitle("Number of Chapters", size(small)) ///
    bar(1, color("`color1'")) ///
    bar(2, color("`color2'")) ///
    bar(3, color("`color3'")) ///
    bar(4, color("`color4'")) ///
    bar(5, color("`color5'")) ///
    legend(cols(1) pos(3) size(2) symxsize(2) symysize(2) keygap(1) ///
           region(lcolor(white)) ///
           label(1 "White Supremacy") label(2 "Anti-Identity") ///
           label(3 "Religious") label(4 "Black Nationalist") label(5 "General Hate")) ///
    graphregion(color(white)) ///
    plotregion(lcolor(black))
	
	
	
	   
 * bar plot fixed legend all years
local color1 "0 140 140"     // Deep Teal
local color2 "130 170 160"   // Sage Green
local color3 "190 150 60"    // Deep Gold
local color4 "220 200 160"   // Sandy Beige
local color5 "160 100 100"   // Muted Rose

graph bar (sum) cat_white_supremacy cat_anti_identity cat_religious cat_black_nat cat_general, ///
    over(year, label(angle(45) labsize(vsmall))) ///
    title("Total Hate Group Chapters in the U.S. (2000-2021)", size(medium)) ///
    ytitle("Number of Chapters", size(small)) ///
    bar(1, color("`color1'")) ///
    bar(2, color("`color2'")) ///
    bar(3, color("`color3'")) ///
    bar(4, color("`color4'")) ///
    bar(5, color("`color5'")) ///
    legend(cols(1) ring(0) pos(1) size(2) symxsize(2) symysize(2) keygap(1) ///
           region(lcolor(black) fcolor(white) margin(small)) ///
           label(1 "White Supremacy") label(2 "Anti-Identity") ///
           label(3 "Religious") label(4 "Black Nationalist") label(5 "General Hate")) ///
    graphregion(color(white)) ///
    plotregion(lcolor(black))
	graph export "output/graphs/splc/chapters_bar_allyears.png", replace
	
	
* bar plot 5 years intervals
local color1 "0 140 140"     // Deep Teal
local color2 "130 170 160"   // Sage Green
local color3 "190 150 60"    // Deep Gold
local color4 "220 200 160"   // Sandy Beige
local color5 "160 100 100"   // Muted Rose

* Run the bar chart only for years 2000, 2005, 2010, 2015, 2020
graph bar (sum) cat_white_supremacy cat_anti_identity cat_religious cat_black_nat cat_general ///
    if inlist(year, 2000, 2005, 2010, 2015, 2020), ///
    over(year, label(labsize(small))) ///
    title("National Evolution of Hate Group Ideologies (5-Year Intervals)", size(medium)) ///
    ytitle("Number of Chapters", size(small)) ///
    bar(1, color("`color1'")) ///
    bar(2, color("`color2'")) ///
    bar(3, color("`color3'")) ///
    bar(4, color("`color4'")) ///
    bar(5, color("`color5'")) ///
    legend(cols(1) ring(0) pos(1) size(2) symxsize(2) symysize(2) keygap(1) ///
           region(lcolor(black) fcolor(white) margin(small)) ///
           label(1 "White Supremacy") label(2 "Anti-Identity") ///
           label(3 "Religious") label(4 "Black Nationalist") label(5 "General Hate")) ///
    graphregion(color(white)) ///
    plotregion(lcolor(black))	
		graph export "output/graphs/splc/chapters_bar_fiveyears.png", replace
	
	
***************************************
*stacked bar
***************************************
local color1 "0 140 140"     // Deep Teal
local color2 "130 170 160"   // Sage Green
local color3 "190 150 60"    // Deep Gold
local color4 "220 200 160"   // Sandy Beige
local color5 "160 100 100"   // Muted Rose

graph bar (sum) cat_white_supremacy cat_anti_identity cat_religious cat_black_nat cat_general, ///
    over(year, label(angle(45) labsize(vsmall))) ///
    stack ///
    title("National Evolution of Hate Group Ideologies", size(medium) margin(bottom)) ///
    ytitle("Total Number of Chapters", size(small)) ///
    bar(1, color("`color1'")) ///
    bar(2, color("`color2'")) ///
    bar(3, color("`color3'")) ///
    bar(4, color("`color4'")) ///
    bar(5, color("`color5'")) ///
    legend(cols(1) pos(3) size(2) symxsize(2) symysize(2) keygap(1) ///
           region(lcolor(white)) ///
           label(1 "White Supremacy") label(2 "Anti-Identity") ///
           label(3 "Religious") label(4 "Black Nationalist") label(5 "General Hate")) ///
    graphregion(color(white)) ///
    plotregion(lcolor(black))
	graph export "output/graphs/splc/chapters_stacked.png", replace
		   
	