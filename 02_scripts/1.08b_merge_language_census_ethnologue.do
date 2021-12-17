project , uses("../08_temp/census1961_st_mothertongue.dta")
project , uses("../08_temp/ethnologue_tree.dta")
project , original("../01_data/ethnologue_data/unmerged_languages_inprogress_2021_09.xlsx") 

********************************************************************************************************************************
* This do-file merges "census1961mothertongue.dta" and "ethnologue_tree.dta"
*! version 1.0 created on 12 July 2020 by Hemanshu Kumar; 
* the first version to be compatible with Robert Picard's -project- command
* also updated to Ethnologue edition 23
********************************************************************************************************************************

use "../08_temp/census1961_st_mothertongue", clear

keep state mothertongue 
gen language = mothertongue

replace language = lower(language)
replace language = subinstr(language,"-"," ",.)
replace language = subinstr(language,"/"," ",.)
replace language = subinstr(language,"*"," ",.)
replace language = subinstr(language,","," ",.)

replace language = trim(itrim(language))

duplicates drop language, force

drop if language=="total" 
drop if language=="all scheduled tribes" 
drop if language=="all mother tongues" 

tempfile census_languages
save `census_languages'

// Merge dataset with the Ethnologue tree

use "../08_temp/ethnologue_tree", clear
gen language_ethnologue = language

replace language = lower(language)

replace language = subinstr(language,"-"," ",.)
replace language = subinstr(language,"/"," ",.)
replace language = subinstr(language,"*"," ",.)
replace language = subinstr(language,","," ",.)

replace language = trim(itrim(language))

duplicates drop language, force

tempfile ethnologue_tree_standardized
save `ethnologue_tree_standardized', replace

merge 1:1 language using `census_languages'

keep language iso state language_ethnologue mothertongue _merge


preserve
	keep if _merge == 3
	drop _merge
	drop state mothertongue
	clonevar census_language = language
	tempfile auto_merged
	save `auto_merged'
restore
*/

* we now create auto_merged_languages.xlsx and unmerged_languages.xlsx
* these are to be used to manually match those ethnologue and census languages that we were not not able to automatically do in the merge above
* the manually edited version of unmerged_languages.xlsx should be renamed to unmerged_languages_inprogress.xlsx (to prevent being overwritten by the code here)

export excel language state language_ethnologue mothertongue using "../08_temp/auto_merged_languages.xlsx" if _merge == 3, replace firstrow(variables)
export excel language language_ethnologue using "../08_temp/unmerged_languages.xlsx" if _merge == 1, sheet("Ethnologue") sheetreplace
export excel language state mothertongue using "../08_temp/unmerged_languages.xlsx" if _merge == 2, sheet("Census") sheetreplace

********************************************************************************************************************************
* now we take the manually merged languages and automatically merged languages to form a consolidated list
********************************************************************************************************************************

import excel using "../01_data/ethnologue_data/unmerged_languages_inprogress_2021_09.xlsx", sheet("Census") firstrow clear
keep if ethnologue_match~=""
keep language ethnologue_match iso

rename language census_language
rename ethnologue_match language

merge m:1 iso using `ethnologue_tree_standardized', keepusing(language_ethnologue) assert(2 3)

keep if _merge == 3
drop _merge

append using `auto_merged'

rename language match_language
rename census_language language

duplicates drop language language_ethnologue, force

save "../08_temp/matched_language_list", replace

project , creates("../08_temp/auto_merged_languages.xlsx")
project , creates("../08_temp/unmerged_languages.xlsx")
project , creates("../08_temp/matched_language_list.dta")

********************************************************************************************************************************************************
* the code below is for use during the manual merging process, and should generally be kept commented out
* unless the manual merge is being re-done, fixed, etc.
* this code is dated 2017, and has not been tested with the -project- changes and ethnologue edition update made in 2020

* district-specific language and tribe matching

/*
use "../03_processed/census1961mothertongue", clear

keep state district mothertongue
gen language = mothertongue

replace language = lower(language)
replace language = subinstr(language,"-"," ",.)
replace language = subinstr(language,"/"," ",.)
replace language = subinstr(language,"*"," ",.)
replace language = subinstr(language,","," ",.)
replace language = trim(itrim(language))

drop if language=="total" 
drop if language=="all scheduled tribes" 
drop if language=="all mother tongues" 

duplicates drop state district language, force

sort language state district
order language state district

save "../03_processed/census_languages_with_districts", replace

********************************************************************************************************

* another version: keeping total pop figures

use "../03_processed/census1961mothertongue", clear

egen totalp = rowtotal(total_speakers*)

keep mothertongue totalp

gen language = mothertongue

replace language = lower(language)
replace language = subinstr(language,"-"," ",.)
replace language = subinstr(language,"/"," ",.)
replace language = subinstr(language,"*"," ",.)
replace language = subinstr(language,","," ",.)
replace language = trim(itrim(language))

drop if language=="total" 
drop if language=="all scheduled tribes" 
drop if language=="all mother tongues" 

collapse (sum) totalp, by(language)

gsort -totalp

tempfile pops
save `pops'

use "../03_processed/ethnologue_tree", clear
gen language_ethnologue = language

replace language = lower(language)

replace language = subinstr(language,"-"," ",.)
replace language = subinstr(language,"/"," ",.)
replace language = subinstr(language,"*"," ",.)
replace language = subinstr(language,","," ",.)

replace language = trim(itrim(language))

duplicates drop language, force


merge 1:1 language using "../03_processed/census_languages"

keep language state language_ethnologue mothertongue _merge

keep if _merge == 2
drop _merge

merge m:1 language using `pops'
keep if _merge == 3
drop _merge

gsort -totalp
export excel language totalp using "../03_processed/unmerged_language_pops.xlsx", replace firstrow(variable) 

*/
