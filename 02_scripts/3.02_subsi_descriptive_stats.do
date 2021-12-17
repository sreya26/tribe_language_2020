
*********************************************************************************************************
* issue with this data: state-level observations are not the sum of corresponding district-level observations
* e.g. because that specific tribe was not listed in a specific component district in 1961
* * e.g. the Mina total for Rajasthan is not equal to the sum of Mina populations of Rajasthan districts
* * this is because no Minas were listed in Ajmer district in 1961, 
* * and so the 2011 Mina observation does not merge with anything in 1961, and thus drops out
* upshot: construct state totals by summing over district observations, rather than using state observations
********************************************************************************************************



********************************************************************************************************
* 1. a tribe-level table of the largest 20 tribes in the country, with columns for
* -- population fraction of STs in India
* -- largest mother tongue in the country
* -- largest state
* -- average linguistic distance (across the country)
* -- % with dominant language as mother tongue
* -- % with dominant language as subsidiary language
* -- educational attainment levels in 2011 
********************************************************************************************************

	********************************************************************************************************
	* 1.1 Identify the largest tribes in the country [as per 2011 populations]
	********************************************************************************************************
	
	use "../03_processed/lang_workfile", clear	
	drop if is_state | castegroup_1961_2011_code == 500
	
	collapse (sum) total_p_2011, by(castegroup_1961_2011_code)
	gsort -total_p_2011
	
	sum total_p_2011
	local total_st_pop_2011 = r(sum)
	
	drop if castegroup_1961_2011_code == 990
	
	keep in 1/20
	
	rename total_p_2011 india_tribe_pop
	gen india_tribe_perc = india_tribe_pop / `total_st_pop_2011' * 100
	format india_tribe_perc %5.2f
	format india_tribe_pop %11.0fc
	
	compress
	
	tempfile bigtribes
	save `bigtribes'
	
	********************************************************************************************************
	* 1.2 obtain largest mother tongue for each large tribe
	********************************************************************************************************

	use "../03_processed/census_1961_mothertongue_for_analysis_distance", clear
	
	merge m:1 castegroup_1961_2011_code using `bigtribes', keep(match) nogen
	
	drop if is_state | mothertongue == "all mother tongues"

	rename language mothertongue_std
	
	replace mothertongue = language_ethnologue if !missing(language_ethnologue)
	replace mothertongue = mothertongue + " [unmatched]" if missing(language_ethnologue)
	
	egen total_speakers = rowtotal(total_speakers_m total_speakers_f)
	
	collapse (sum) total_speakers, by(castegroup_1961_2011_code mothertongue mothertongue_iso india_tribe_pop)
	
	bysort castegroup_1961_2011_code (total_speakers): keep if _n == _N
	gsort -india_tribe_pop -total_speakers
	
	compress
	rename mothertongue l1
	rename mothertongue_iso l1_iso
	rename total_speakers l1_speakers
	format l1_speakers %11.0fc
	
	gen l1_speakers_perc = l1_speakers/india_tribe_pop * 100
	format l1_speakers_perc %5.2f
	
	tempfile l1
	save `l1'
	
	********************************************************************************************************
	* 1.2 obtain largest state for each large tribe
	********************************************************************************************************
	
	use "../03_processed/census_1961_mothertongue_for_analysis_distance", clear
	
	merge m:1 castegroup_1961_2011_code using `bigtribes', keep(match) nogen
	
	drop if is_state
	keep if mothertongue == "all mother tongues"
	
	egen total_speakers = rowtotal(total_speakers_m total_speakers_f)

	collapse (sum) total_speakers (max) india_tribe_pop, by(state_1961 castegroup_1961_2011_code)

	bysort castegroup_1961_2011_code (total_speakers): keep if _n == _N
	
	rename total_speakers s1_pop
	rename state_1961 s1
	format s1_pop %11.0fc
	
	gen s1_perc = s1_pop / india_tribe_pop * 100
	format s1_perc %5.2f
	
	gsort -india_tribe_pop
	order castegroup_1961_2011_code
	
	compress
	
	tempfile s1
	save `s1'
	
	********************************************************************************************************
	* 1.3 obtain average linguistic distance for each large tribe
	********************************************************************************************************
	
	use "../03_processed/census_1961_mothertongue_for_analysis_distance", clear
	
	merge m:1 castegroup_1961_2011_code using `bigtribes', keep(match) nogen
	
	drop if is_state | mothertongue == "all mother tongues"
	
	egen total_speakers = rowtotal(total_speakers_m total_speakers_f)

	collapse (mean) lang_distance_f8_dominant [w=total_speakers] , by(castegroup_1961_2011_code)
	
	rename lang_distance_f8_dominant linguistic_distance
	format linguistic_distance %4.2f
	
	compress
	
	tempfile dist
	save `dist'

	
	********************************************************************************************************
	* 1.4 obtain subsidiary speakers of dominant language
	********************************************************************************************************
	
	use "../03_processed/census_1961_mothertongue_for_analysis_distance", clear
	
	merge m:1 castegroup_1961_2011_code using `bigtribes', keep(match) nogen

	drop if is_state
	
	keep if mothertongue == "all mother tongues"
	
	egen total_speakers = rowtotal(total_speakers_m total_speakers_f)
	egen subsi_speakers_of_dom_lang = rowtotal(subsi_speakers_of_dom_lang_m subsi_speakers_of_dom_lang_f)
	
	collapse (sum) subsi_speakers_of_dom_lang, by(castegroup_1961_2011_code)
	format subsi_speakers_of_dom_lang %11.0fc	
	
	tempfile subsi
	save `subsi'

	
	********************************************************************************************************
	* 1.5 obtain tribal population with dominant language as mother tongue 
	********************************************************************************************************
	
	use "../03_processed/census_1961_mothertongue_for_analysis_distance", clear

	merge m:1 castegroup_1961_2011_code using `bigtribes', keep(match) nogen
	
	drop if is_state 
	
	egen total_speakers = rowtotal(total_speakers_m total_speakers_f)
	
	keep if mothertongue_iso == dominant_language_iso
	
	collapse (sum) total_speakers, by(castegroup_1961_2011_code)
		
	rename total_speakers mt_speakers_of_dominant_language
	format mt_speakers_of_dominant_language %11.0fc
	
	tempfile mt
	save `mt'
		
	
	********************************************************************************************************
	* 1.6 obtain educational attainment in 2011 for each large tribe
	********************************************************************************************************

	use "../03_processed/lang_workfile", clear	
	drop if is_state

	merge m:1 castegroup_1961_2011_code using `bigtribes', keep(match) nogen
	
	collapse (sum) total_p_2011 literate_p_2011 primaryplus_p_2011 middleplus_p_2011 matricplus_p_2011 graduate_p_2011 age*_p_2011, by(castegroup_1961_2011_code)
	
	local edlevels 		literacy 	primaryplus 	middleplus 	matricplus 	graduate
	local excludeages 	0to6		0to8			0to11		0to14		0to19
	local numlevels: list sizeof edlevels

	forval i=1/`numlevels' {
		local level: word `i' of `edlevels'
		local exage: word `i' of `excludeages'
		
		if "`level'" == "literacy" local var literate
			else local var `level'
			
		gen `level'_perc_2011 = `var'_p_2011 / (total_p_2011 - age`exage'_p_2011) * 100
		format %5.2f `level'_perc_2011
	}
	
	keep castegroup_1961_2011_code *_perc_2011
	
	tempfile outcomes
	save `outcomes'
	
	********************************************************************************************************
	* 1.7 put everything together
	********************************************************************************************************
	
	use `bigtribes', clear
	
	merge 1:1 castegroup_1961_2011_code using `l1', assert(match) nogen
	merge 1:1 castegroup_1961_2011_code using `s1', assert(match) nogen
	merge 1:1 castegroup_1961_2011_code using `dist', assert(match) nogen
	merge 1:1 castegroup_1961_2011_code using `subsi', assert(match) nogen
	merge 1:1 castegroup_1961_2011_code using `mt', assert(master match) 
	merge 1:1 castegroup_1961_2011_code using `outcomes', assert(match) nogen

	replace mt_speakers_of_dominant_language = 0 if _merge == 1
	drop _merge
	
	gen subsi_speakers_dom_lang_perc = subsi_speakers_of_dom_lang/india_tribe_pop * 100
	gen mt_speakers_dom_lang_perc = mt_speakers_of_dominant_language/india_tribe_pop * 100
	format %5.2f subsi_speakers_dom_lang_perc mt_speakers_dom_lang_perc
	
	gsort -india_tribe_pop
	
	#delimit ;
	listtab castegroup_1961_2011_code india_tribe_perc l1 s1 linguistic_distance mt_speakers_dom_lang_perc subsi_speakers_dom_lang_perc
			literacy_perc_2011 primaryplus_perc_2011 middleplus_perc_2011 matricplus_perc_2011 graduate_perc_2011
		using "../04_results/01_tables/3_new_summary_table_2.tex", replace
		rstyle(tabular)
		head(
		`"\toprule"'
		`"& & & & & \multicolumn{2}{c}{\% that speaks} \\"'
		`"& & & & & \multicolumn{2}{c}{dominant language as} & \multicolumn{5}{c}{Educational attainment in 2011, (\%) } \\"' 
		`"\cmidrule(lr){6-7} \cmidrule(lr){8-12}"'
		`"		& \% of 	& Largest 			& Largest		& Linguistic & Mother 	& Subsidiary \\"'
		`"Tribe	& India ST 	& Mother Tongue 	& 1961 State 	& Distance 	 & Tongue	& Language & Literacy & Primary & Middle & Secondary & Graduate\\"'
		`"\midrule"')
		foot(`"\bottomrule"')
		;
	#delimit cr

********************************************************************************************************
* 2. a state-level table with columns for
* -- tribal population as % of state population
* -- dominant language
* -- average linguistic distance amongst tribes in the state
* -- % of tribal population with dominant language as mother tongue
* -- % of tribal population with dominant language as subsidiary language
* -- secondary school attainment for SCs, STs, and non-SC/STs
* [also: add a row for India]
********************************************************************************************************

	********************************************************************************************************
	* 2.1 obtain tribal population as a percentage of overall population in 2011
	********************************************************************************************************
	
	use "../03_processed/lang_workfile", clear	

	drop if is_state
	keep if castegroup_1961_2011_code == 500
	
	collapse (sum) total_p_2011 overallpop_2011, by(state_1961)

	preserve
		collapse (sum) total_p_2011 overallpop_2011
		gen state_1961 = "India"
		tempfile india
		save `india'
	restore
	
	append using `india'
	
	gen tribal_pop_perc = total_p_2011 / overallpop_2011 * 100
	format tribal_pop_perc %5.2f
		
	compress
	
	keep state_1961 tribal_pop_perc
	
	tempfile overall_pop
	save `overall_pop'


	********************************************************************************************************
	* 2.2 obtain average linguistic distance for tribes in each state
	********************************************************************************************************
	
	use "../03_processed/census_1961_mothertongue_for_analysis_distance", clear
	
	drop if is_state | mothertongue == "all mother tongues" | castegroup_1961_2011_code == 500
	
	egen total_speakers = rowtotal(total_speakers_m total_speakers_f)

	preserve
		collapse (mean) lang_distance_f8_dominant [w=total_speakers]
		gen state_1961 = "India"
		tempfile india
		save `india'
	restore
	
	collapse (mean) lang_distance_f8_dominant [w=total_speakers] , by(state_1961)
	
	append using `india'
	
	rename lang_distance_f8_dominant linguistic_distance
	format linguistic_distance %4.2f
	
	compress
	
	tempfile dist
	save `dist'

	
	********************************************************************************************************
	* 2.3 obtain state tribal population in 1961, and subsidiary speakers of dominant language
	********************************************************************************************************
	
	use "../03_processed/census_1961_mothertongue_for_analysis_distance", clear
	
	drop if is_state | mothertongue == "all mother tongues"
	
	keep if castegroup_1961_2011_code == 500
	
	egen total_speakers = rowtotal(total_speakers_m total_speakers_f)
	egen subsi_speakers_of_dom_lang = rowtotal(subsi_speakers_of_dom_lang_m subsi_speakers_of_dom_lang_f)
	
	collapse (sum) total_speakers subsi_speakers_of_dom_lang, by(state_1961)

	preserve
		collapse (sum) total_speakers subsi_speakers_of_dom_lang
		gen state_1961 = "India"
		tempfile india
		save `india'
	restore
	
	append using `india'
	
	rename total_speakers state_tribal_pop_61
	
	tempfile pops
	save `pops'

	
	********************************************************************************************************
	* 2.4 obtain tribal population with dominant language as mother tongue 
	********************************************************************************************************
	
	use "../03_processed/census_1961_mothertongue_for_analysis_distance", clear

	drop if is_state | castegroup_1961_2011_code == 500
	
	egen total_speakers = rowtotal(total_speakers_m total_speakers_f)
	
	keep if mothertongue_iso == dominant_language_iso
	
	collapse (sum) total_speakers, by(state_1961)
	
	preserve
		collapse (sum) total_speakers
		gen state_1961 = "India"
		tempfile india
		save `india'
	restore
	
	append using `india'
	
	rename total_speakers mt_speakers_of_dominant_language

	tempfile mt
	save `mt'
	
	********************************************************************************************************
	* 2.5 obtain secondary school attainment for Non-SC/STs, SCs and STs 
	********************************************************************************************************
	
	use "../03_processed/census2011_agg_edu_data", clear

	drop if caste_group == "All":CASTE_GROUPS
	keep if tru == "Total":TRU
	drop tru
	
	* create 1961 states [reference: Table 1 of Kumar & Somanathan (2016), "Creating long panels using census data, 1961-2011"]
	gen state_1961 = state
	replace state_1961 = "Assam" if inlist(state,"Meghalaya","Mizoram")
	replace state_1961 = "Bihar" if state == "Jharkhand"
	replace state_1961 = "Goa, Daman and Diu" if inlist(state,"Goa","Daman & Diu")
	replace state_1961 = "Madhya Pradesh" if state == "Chhattisgarh"
	replace state_1961 = "Punjab" if inlist(state,"Punjab","Haryana","Chandigarh") // iffy, but works in our context
	replace state_1961 = "Uttar Pradesh" if state == "Uttarakhand"
	replace state_1961 = "Madras" if state == "Tamil Nadu"
	replace state_1961 = "Mysore" if state == "Karnataka"
	replace state_1961 = "Orissa" if state == "Odisha"
	replace state_1961 = "Laccadive, Minicoy and Amindivi Islands" if state == "Lakshadweep"
	replace state_1961 = "Dadra and Nagar Haveli" if state == "Dadra & Nagar Haveli"
	replace state_1961 = "Delhi" if state == "NCT of Delhi"
	replace state_1961 = "North East Frontier Agency" if state == "Arunachal Pradesh"
	replace state_1961 = "Pondicherry" if state == "Puducherry"
	
	drop if inlist(state_1961,"Goa, Daman and Diu","Punjab","Delhi","North East Frontier Agency","Jammu & Kashmir","Pondicherry","Sikkim","Uttar Pradesh")

	collapse (sum) total_p - age0to19_f, by(state_1961 caste_group)
	
	* create secondary school attainment variables
	foreach x in p m f {
		egen matricplus_`x' = rowtotal(matric_`x' intermediate_`x' nontechdiploma_`x' techdiploma_`x' graduate_`x')
		gen matricplus_perc_`x' = matricplus_`x'/(total_`x' - age0to14_`x') * 100
		format matricplus_perc_`x' %5.2f
	}

	* reshape and keep the data we want
	decode caste_group, gen(group)
	drop caste_group
	replace group = lower(group)
	replace group = "nonscst" if group == "non sc/st"
	
	keep state_1961 group matricplus_perc_p
	rename matricplus_perc_p matricplus_
	reshape wide matricplus_, i(state_1961) j(group) string
	
	tempfile outcomes
	save `outcomes'
	
	********************************************************************************************************
	* 2.6 put the table together 
	********************************************************************************************************
	
	use "../03_processed/census_1961_mothertongue_for_analysis_distance", clear
	
	duplicates drop state_1961, force
	
	keep state_1961 dominant_language
	expand 2 in l
	replace state_1961 = "India" in l
	replace dominant_language = "Hindi" in l

	merge 1:1 state_1961 using `overall_pop', assert(match) nogen
	merge 1:1 state_1961 using `dist', assert(match) nogen 
	merge 1:1 state_1961 using `pops', assert(match) nogen
	merge 1:1 state_1961 using `mt', assert(master match)
	merge 1:1 state_1961 using `outcomes', assert(match) nogen
	
	replace mt_speakers_of_dominant_language = 0 if _merge == 1
	drop _merge
	
	gen mt_speakers_dom_lang_perc = mt_speakers_of_dominant_language/state_tribal_pop_61 * 100
	gen subsi_speakers_dom_lang_perc = subsi_speakers_of_dom_lang/state_tribal_pop_61 * 100
	
	format %5.2f mt_speakers_dom_lang_perc subsi_speakers_dom_lang_perc
	
	keep state_1961 tribal_pop_perc dominant_language linguistic_distance mt_speakers_dom_lang_perc subsi_speakers_dom_lang_perc matricplus_*
	
	gen x = 0
	replace x = 1 if state_1961 == "India"
	sort x state_1961
	drop x
	
	replace state_1961 = "\midrule " + state_1961 if state_1961 == "India"
	replace state_1961 = subinstr(state_1961, " & ", " \& ", .)

	#delimit ;
	listtab state_1961 tribal_pop_perc dominant_language linguistic_distance 
			mt_speakers_dom_lang_perc subsi_speakers_dom_lang_perc
			matricplus_sc matricplus_st matricplus_nonscst
		using "../04_results/01_tables/3_new_summary_table_1.tex", replace
		rstyle(tabular)
		head(
		`"\toprule"'
		`"& & & & \multicolumn{2}{c}{\% of tribal population} & \multicolumn{3}{c}{Secondary school}\\"'
		`"					& 		& 			& Linguistic & \multicolumn{2}{c}{that speaks} & \multicolumn{3}{c}{attainment in} \\"'
		`"					& 		& 			& Distance 	& \multicolumn{2}{c}{dominant language as} & \multicolumn{3}{c}{2011 (\%)}\\"'
		`"													\cmidrule(lr){5-6} 								\cmidrule(lr){7-9}"'
		`"					& 		& Dominant 	& among 	& Mother 	& Subsidiary &		&		& Non-\\"'
		`"Census 1961 State & ST \%	& Language	& STs		& Tongue	& Language 	 & SC	& ST 	& SC/ST \\"'
		`"\midrule"')
		foot(`"\bottomrule"')
		;
	#delimit cr
	

********************************************************************************************************
* 3. a state-level table with top four tribes, and for each tribe, columns for
* -- population as % of state ST population
* -- average linguistic distance in the state
* -- % with dominant language as mother tongue
* -- % with dominant language as subsidiary language
* -- secondary school attainment
********************************************************************************************************


	********************************************************************************************************
	* 3.1 find four largest tribes in each state (as per 2011 figures)
	********************************************************************************************************
	
	use "../03_processed/lang_workfile", clear	

	drop if is_state | castegroup_1961_2011_code == 500

	drop total_p_1961
	rename total_speakers total_p_1961
	
	format total_p_1961 %11.0fc
	
	collapse (sum) total_p_2011 overallpop_2011 total_p_1961, by(state_1961 castegroup_1961_2011_code)
	
	egen state_st_pop_2011 = total(total_p_2011), by(state_1961)
	
	drop if castegroup_1961_2011_code == 990
	
	bysort state_1961 (total_p_2011): keep if _n >_N-4
	
	gen pop_st_perc = total_p_2011 / state_st_pop_2011 * 100
	format pop_st_perc %5.2f
		
	compress
	
	gsort state_1961 -pop_st_perc
	by state_1961: gen state_rank = _n
	keep state_1961 castegroup_1961_2011_code pop_st_perc state_rank total_p_1961
	
	tempfile bigtribes
	save `bigtribes'

	
	********************************************************************************************************
	* 3.2 for each tribe, compute average linguistic distance in the state
	********************************************************************************************************

	use "../03_processed/census_1961_mothertongue_for_analysis_distance", clear
	
	merge m:1 state_1961 castegroup_1961_2011_code using `bigtribes', keep(match) nogen keepusing(state_1961 castegroup_1961_2011_code)
	
	drop if is_state | mothertongue == "all mother tongues"
	
	egen total_speakers = rowtotal(total_speakers_m total_speakers_f)

	collapse (mean) lang_distance_f8_dominant [w=total_speakers] , by(state_1961 castegroup_1961_2011_code)
	
	rename lang_distance_f8_dominant linguistic_distance
	format linguistic_distance %4.2f
	
	compress
	
	tempfile dist
	save `dist'
	
	********************************************************************************************************
	* 3.3 obtain subsidiary speakers of dominant language
	********************************************************************************************************
	
	use "../03_processed/census_1961_mothertongue_for_analysis_distance", clear
	
	merge m:1 state_1961 castegroup_1961_2011_code using `bigtribes', keep(match) nogen

	drop if is_state
	
	keep if mothertongue == "all mother tongues"
	
	egen total_speakers = rowtotal(total_speakers_m total_speakers_f)
	egen subsi_speakers_of_dom_lang = rowtotal(subsi_speakers_of_dom_lang_m subsi_speakers_of_dom_lang_f)
	
	collapse (sum) subsi_speakers_of_dom_lang, by(state_1961 castegroup_1961_2011_code)
	format subsi_speakers_of_dom_lang %11.0fc	
	
	tempfile subsi
	save `subsi'

	
	********************************************************************************************************
	* 3.4 obtain population with dominant language as mother tongue 
	********************************************************************************************************
	
	use "../03_processed/census_1961_mothertongue_for_analysis_distance", clear

	merge m:1 state_1961 castegroup_1961_2011_code using `bigtribes', keep(match) nogen
	
	drop if is_state 
	
	egen total_speakers = rowtotal(total_speakers_m total_speakers_f)
	
	keep if mothertongue_iso == dominant_language_iso
	
	collapse (sum) total_speakers, by(state_1961 castegroup_1961_2011_code)
		
	rename total_speakers mt_speakers_of_dominant_language
	format mt_speakers_of_dominant_language %11.0fc
	
	tempfile mt
	save `mt'

	********************************************************************************************************
	* 3.5 obtain secondary school attainment in 2011 for each large tribe
	********************************************************************************************************

	use "../03_processed/lang_workfile", clear	
	drop if is_state

	merge m:1 state_1961 castegroup_1961_2011_code using `bigtribes', keep(match) nogen
	
	collapse (sum) total_p_2011 literate_p_2011 primaryplus_p_2011 middleplus_p_2011 matricplus_p_2011 graduate_p_2011 age*_p_2011, by(state_1961 castegroup_1961_2011_code)
	
	local edlevels 		literacy 	primaryplus 	middleplus 	matricplus 	graduate
	local excludeages 	0to6		0to8			0to11		0to14		0to19
	local numlevels: list sizeof edlevels

	forval i=1/`numlevels' {
		local level: word `i' of `edlevels'
		local exage: word `i' of `excludeages'
		
		if "`level'" == "literacy" local var literate
			else local var `level'
			
		gen `level'_perc_2011 = `var'_p_2011 / (total_p_2011 - age`exage'_p_2011) * 100
		format %5.2f `level'_perc_2011
	}
	
	keep state_1961 castegroup_1961_2011_code matricplus_perc_2011
	
	tempfile outcomes
	save `outcomes'


	********************************************************************************************************
	* 3.6 put the table together
	********************************************************************************************************
	
	use `bigtribes', clear
	
	merge 1:1 state_1961 castegroup_1961_2011_code using `dist', assert(match) nogen
	merge 1:1 state_1961 castegroup_1961_2011_code using `subsi', assert(match) nogen
	merge 1:1 state_1961 castegroup_1961_2011_code using `mt', assert(master match) 
	merge 1:1 state_1961 castegroup_1961_2011_code using `outcomes', assert(match) nogen

	replace mt_speakers_of_dominant_language = 0 if _merge == 1
	drop _merge
	
	gen subsi_speakers_dom_lang_perc = subsi_speakers_of_dom_lang/total_p_1961 * 100
	gen mt_speakers_dom_lang_perc = mt_speakers_of_dominant_language/total_p_1961 * 100

	format %3.0f pop_st_perc subsi_speakers_dom_lang_perc mt_speakers_dom_lang_perc matricplus_perc_2011
	
	drop total_p_1961 subsi_speakers_of_dom_lang mt_speakers_of_dominant_language

	order state_1961 castegroup_1961_2011_code pop_st_perc linguistic_distance mt_speakers_dom_lang_perc subsi_speakers_dom_lang_perc matricplus_perc_2011
	
	reshape wide castegroup_1961_2011_code pop_st_perc linguistic_distance mt_speakers_dom_lang_perc subsi_speakers_dom_lang_perc matricplus_perc_2011 , i(state_1961) j(state_rank)

	* drop small states ( < 5 million in census 2011) and those with a small ST population ( < 1% of state population)
	drop if inlist(state_1961,"Andaman & Nicobar Islands","Dadra and Nagar Haveli","Laccadive, Minicoy and Amindivi Islands","Kerala","Madras","Manipur","Nagaland","Tripura")
	drop *4
	
	#delimit ;
	listtab 
		using "../04_results/01_tables/3_new_summary_table_3.tex", replace
		rstyle(tabular)
		head(
		`"\toprule"'
		`"& & & & \multicolumn{2}{c}{\% that speaks}		 & & & & & \multicolumn{2}{c}{\% that speaks} 		& & & & & \multicolumn{2}{c}{\% that speaks} & \\"'
		`"& & & & \multicolumn{2}{c}{dominant language as}   & & & & & \multicolumn{2}{c}{dominant language as} & & & & & \multicolumn{2}{c}{dominant language as} & \\"' 
		`"\cmidrule(lr){5-6} \cmidrule(lr){11-12} \cmidrule(lr){17-18} "'
		`"				& Largest   & \% of 	& Linguistic 	& Mother 	& Subsi. & Secondary     & 2nd Largest   & \% of 	& Linguistic 	& Mother 	& Subsi. & Secondary     & 3rd Largest   & \% of 	& Linguistic 	& Mother 	& Subsi. & Secondary     \\"'
		`"1961 State	& Tribe 	& ST 	& Distance 		& Tongue	& Lang.  & school (\%)	& Tribe 	& ST 	& Distance 		& Tongue	& Lang.  & school (\%) & Tribe 	& ST 	& Distance 		& Tongue	& Lang.  & school (\%) \\"'
		`"\midrule"')
		foot(`"\bottomrule"')
		;
	#delimit cr































