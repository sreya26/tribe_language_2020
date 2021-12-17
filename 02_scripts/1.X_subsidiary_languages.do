/*

use "../03_processed/census_1961_mothertongue_data_with_dist_tribe_codes", clear

descsave sl_*, list(,) norestore

keep name varlab
sort varlab

gen subsi_language = trim(itrim(varlab))
replace subsi_language = substr(subsi_language,4,.) // gets rid of the "sl_" at the start
replace subsi_language = substr(subsi_language,1,length(subsi_language)-2) // gets rid of the "_m" or "_f" at the end

drop if substr(name,-2,.) == "_f" // since language names will be duplicated across _m and _f variables

distinct subsi_language
assert r(ndistinct) == r(N) // no further duplicates

export excel using "../03_processed/census_1961_subsidiary_languages.xlsx", firstrow(variables) replace

*/

use "../03_processed/census_1961_mothertongue_for_analysis_distance", clear

replace language_ethnologue = "All Mother Tongues" if language == "all mother tongues"
replace language_ethnologue = language + " [unmatched]" if missing(language_ethnologue)

drop mothertongue language

rename language_ethnologue mothertongue_ethnologue

label define LANGUAGES 0 "All Mother Tongues"

encode mothertongue_ethnologue if strpos(mothertongue_ethnologue,"[unmatched]") == 0, gen(language_code1) label(LANGUAGES)
encode mothertongue_ethnologue if strpos(mothertongue_ethnologue,"[unmatched]") > 0, gen(language_code2) label(LANGUAGES)
gen mothertongue = language_code1
replace mothertongue = language_code2 if missing(mothertongue)
label values mothertongue LANGUAGES
drop language_code?
order mothertongue, after(is_state)

collapse (sum) total_speakers_? subsidiary_speakers_total_? sl_*_? (max) num_schools lang_distance_* , by(state_1961 regionname6113 castegroup_2011_code region6113 is_state mothertongue dominant_language modal_language)

compress

/*
rename subsidiary_speakers_total_? all_subsidiary_speakers_?

gen sl_none_m = total_speakers_m - all_subsidiary_speakers_m
gen sl_none_f = total_speakers_f - all_subsidiary_speakers_f

rename sl_*_m sl_m_*
rename sl_*_f sl_f_*
 
reshape long sl_m_ sl_f_, ///
			i(region6113 castegroup_2011_code mothertongue) ///
			j(sl_stub) string

rename sl_m_ subsidiary_speakers_m
rename sl_f_ subsidiary_speakers_f

drop if subsidiary_speakers_m == 0 & subsidiary_speakers_f == 0

save "../03_processed/subsidiary_speakers_reshaped", replace
*/

import excel using "../01_data/ethnologue_data/20201023 census 1961 subsidiary languages in ethnologue.xlsx", clear firstrow
replace name = substr(name,1,length(name)-2)
replace name = substr(name,4,.)
rename name sl_stub

tempfile subsi_languages
save `subsi_languages'

use "../03_processed/subsidiary_speakers_reshaped", clear

merge m:1 sl_stub using `subsi_languages', keepusing(iso) keep(1 3)
assert sl_stub == "none" if _merge == 1
drop _merge

merge m:1 iso using "../03_processed/ethnologue_tree", keepusing(language) keep (1 3) nogen

rename sl_stub subsidiary_language
rename language subsidiary_language_ethnologue
rename iso subsidiary_language_iso
order subsidiary_language subsidiary_language_ethnologue subsidiary_language_iso, after(mothertongue)

gsort state_1961 -is_state region6113 castegroup_2011_code mothertongue subsidiary_language
order state_1961 is_state region6113 regionname6113  

compress

save "../03_processed/census_1961_subsidiary_language_data_for_tables", replace

use "../03_processed/census_1961_subsidiary_language_data_for_tables", clear

keep if is_state

foreach var in total_speakers all_subsidiary_speakers subsidiary_speakers {
	egen `var'_t = rowtotal(`var'_f `var'_m)
	order `var'_t, after(`var'_m)
	drop `var'_f `var'_m
}

* figure out the two largest tribes in each state

drop if inlist(castegroup_2011_code,500,990) // remove "All Scheduled Tribes" and "Generic Tribes"
gsort state_1961 -is_state region6113 -total_speakers_t mothertongue subsidiary_language
br if mothertongue == 0
gsort state_1961 -is_state region6113 castegroup_2011_code -total_speakers_t mothertongue -subsidiary_speakers_t
br if !inlist(castegroup_2011_code,500,990) & mothertongue!=0

* figure out the 20 largest tribes in the country
use "../03_processed/census_1961_subsidiary_language_data_for_tables", clear
keep if is_state & mothertongue == 0

duplicates drop state_1961 castegroup_2011_code, force

collapse (sum) total_speakers_m total_speakers_f, by(castegroup_2011_code)
egen total_speakers_t = rowtotal(total_speakers_?)
gsort -total_speakers_t
generate india_tribe_frac = total_speakers_t/total_speakers_t[1]
keep in 1/21
rename total_speakers_t india_tribe_pop
keep castegroup_2011_code india_tribe_pop india_tribe_frac
tempfile bigtribes
save `bigtribes'

use "../03_processed/census_1961_subsidiary_language_data_for_tables", clear
merge m:1 castegroup_2011_code using `bigtribes', assert(1 3)
gen bigtribe = (_merge == 3)
drop _merge

keep if is_state & bigtribe & mothertongue == 0
drop is_state bigtribe region6113 regionname6113 mothertongue

egen total_speakers_t = rowtotal(total_speakers_m total_speakers_f)
gsort -india_tribe_pop -total_speakers_t
duplicates drop state_1961 castegroup_2011_code, force

use "../03_processed/census_1961_subsidiary_language_data_for_tables", clear
merge m:1 castegroup_2011_code using `bigtribes', assert(1 3)
gen bigtribe = (_merge == 3)
drop _merge

keep if is_state & bigtribe & mothertongue != 0 & castegroup_2011_code!=500
drop is_state bigtribe region6113 regionname6113

foreach var in total_speakers all_subsidiary_speakers subsidiary_speakers {
	egen `var'_t = rowtotal(`var'_f `var'_m)
	order `var'_t, after(`var'_m)
	drop `var'_f `var'_m
}

* duplicates drop state_1961 castegroup_2011_code, force
gsort castegroup_2011_code state_1961 -total_speakers_t -subsidiary_speakers_t

keep state_1961 castegroup_2011_code mothertongue subsidiary_language_ethnologue total_speakers_t subsidiary_speakers_t


/*
collapse 	(sum) subsidiary_speakers ///
			(max) total_speakers_m total_speakers_f area_1961 pop_1961 all_subsidiary_speakers, ///
				by(dcode_1961 castegroup_2011_code mothertongue tribe state_1961 district_1961 ethnologue_language iso)

drop ethnologue_language

rename subsidiary_speakers sl_

drop if missing(iso)

reshape wide sl_ , i(dcode_1961 castegroup_2011_code mothertongue tribe state_1961 district_1961) j(iso) string

compress
*/
