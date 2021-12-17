******************************************************************************************************************************************
* this file jumps through a few hoops to prepare the census 1961 mothertongue data for including in the main workfile for the tribelanguage paper
*! version 1.0 created by Hemanshu Kumar on 20 July 2020
*! version 1.1 created by Hemanshu Kumar on 25 January 2021 adds in some work on subsidiary languages
******************************************************************************************************************************************
project , original("1.11a_asjp_distances.do")
project , original("1.11b_counting_nodes.do")

project , original("../01_data/asjp_data/tribelang_asjp_matrix.xlsx") // this is called by asjp_distances
project , uses("../08_temp/ethnologue_tree.dta") // this is called by counting_nodes

project , original("../01_data/ethnologue_data/20201023 census 1961 subsidiary languages in ethnologue.xlsx")

project , uses("../08_temp/census_1961_mothertongue_data_with_dist_tribe_codes.dta")
project , uses("../08_temp/regions6113_with_dists_1961.dta")
project , uses("../08_temp/matched_language_list.dta")
project , uses("../08_temp/dise_lang_distribution.dta")
project , uses("../08_temp/dise_modal_languages.dta")
project , uses("../08_temp/dise_modal_languages_state.dta")

run "1.11a_asjp_distances.do"
run "1.11b_counting_nodes.do"

******************************************************************************************************************************************
* various methods of calculating distance between two given languages: 
* (a) TJ: counting the number of nodes that we need to traverse to get from one language to the other (see the Tarun Jain (2017) Common Tongue paper)
* (b) F: The Fearon (2003) measure, using m = 15 and alpha = 0.5
* (c) F8: The Fearon (2003) measure, using m = 8 and alpha = 0.5  
* (d) AP: 1 - Proximity as defined in Adsera & Pytlikova (2015)
* (e) DOW: The Fearon (2003) measure, using m = 8 and alpha = 0.05; see Desmet, Ortuno-Ortin and Weber (2009)
* (f) AS: the LDND measure of Bakker et al (2009) using ASJP database 
* (g) L : Laitin (2000)'s r measure given in his footnote 7

local dist_types tj as ap l f f8 dow
******************************************************************************************************************************************


******************************************************************************************************************************************
* 1. we add in totals by language and by tribe in each district in the dataset
******************************************************************************************************************************************

	use "../08_temp/census_1961_mothertongue_data_with_dist_tribe_codes", clear

	keep state_1961 dcode_1961 district_1961 castegroup_1961_2011_code mothertongue total_speakers* subsidiary_speakers_total_* sl_*

	* first we ensure each district-tribe-mothertongue combo is unique
	collapse (sum) total_speakers* subsidiary_speakers_total_* sl_*, by(state_1961 dcode_1961 district_1961 castegroup_1961_2011_code mothertongue)

	* we will add totals by tribe in each district, as well as totals by language in each district (and a total of totals will be computed too)
	* currently, these are very inconsistently available in the dataset

	drop if castegroup_1961_2011_code == 500
	drop if inlist(mothertongue,"all mother tongues","total","all scheduled tribes")

	tempfile extract
	save `extract'

	collapse (sum) total_speakers* subsidiary_speakers_total_* sl_*, by(state_1961 dcode_1961 district_1961 castegroup_1961_2011_code)
	gen mothertongue = "all mother tongues"
	tempfile all_tongues
	save `all_tongues'

	use `extract', clear
	append using `all_tongues'
	save `extract', replace

	collapse (sum) total_speakers* subsidiary_speakers_total_* sl_*, by(state_1961 dcode_1961 district_1961 mothertongue)
	gen castegroup_1961_2011_code = 500
	tempfile all_tribes
	save `all_tribes'

	use `extract', clear
	append using `all_tribes'

	sort state_1961 dcode_1961 castegroup_1961_2011_code mothertongue

	clonevar language = mothertongue

	replace language = lower(language)
	replace language = subinstr(language,"-"," ",.)
	replace language = subinstr(language,"/"," ",.)
	replace language = subinstr(language,"*"," ",.)
	replace language = subinstr(language,","," ",.)

	replace language = trim(itrim(language))

	replace state_1961 = "Himachal Pradesh" if state_1961 == "Punjab"

	
	* now we aggregate this data to the 1961-2013 consistent regions

	merge m:1 dcode_1961 using "../08_temp/regions6113_with_dists_1961", ///
				keepusing(region6113 regionname6113) assert(match using) keep(match) nogen
				* there will be regions from areas where STs are not delimited which will not merge and occur only in the using dataset; we ignore those
	
	gen is_state = (mod(dcode_1961,100) == 0)
		
	collapse (sum) total_speakers_* subsidiary_speakers_total_* sl_*, by(state_1961 region6113 regionname6113 castegroup_1961_2011_code mothertongue language is_state)

	tempfile language_initial
	save `language_initial'
	
******************************************************************************************************************************************
* 2. give the subsidiary language variables a characteristic that notes their ISO code
******************************************************************************************************************************************

	**********************************************************************************************************
	* 2.1 export the list of subsidiary languages
	**********************************************************************************************************

	use `language_initial', clear

	descsave sl_*, list(,) norestore

	keep name varlab
	sort varlab

	gen subsi_language = trim(itrim(varlab))
	replace subsi_language = substr(subsi_language,10,.) // gets rid of the "(sum) sl_" at the start
	replace subsi_language = substr(subsi_language,1,length(subsi_language)-2) // gets rid of the "_m" or "_f" at the end

	drop if substr(name,-2,.) == "_f" // since language names will be duplicated across _m and _f variables
	drop varlab
	
	distinct subsi_language
	assert r(ndistinct) == r(N) // no further duplicates

	export excel using "../08_temp/census_1961_subsidiary_languages.xlsx", firstrow(variables) replace
	
	**********************************************************************************************************
	* 2.2 read in ISO codes for subsidiary languages
	* note: the above excel file is manually edited to match with ethnologue codes, and obtain the excel file below
	**********************************************************************************************************

	import excel using "../01_data/ethnologue_data/20210125 census 1961 subsidiary languages in ethnologue.xlsx", clear firstrow
	keep subsi_language ethnologue_language iso

	distinct subsi_language
	assert r(ndistinct) == _N // all subsidiary languages should be unique
	
	levelsof subsi_language , local(subsi_languages)
	
	forval i=1/`=_N' {
		local sl_`=subsi_language[`i']' `" "`=ethnologue_language[`i']'" `=iso[`i']' "' // macros to store the ethnologue language and iso for each subsidiary language
	} 
		
	**********************************************************************************************************
	* 2.3 create characteristics to store ethnologue language and ISO code for the subsidiary language variables
	**********************************************************************************************************
	
	use `language_initial', clear
	foreach lang of local subsi_languages {
		char sl_`lang'_m[ethnologue] "`:word 1 of `sl_`lang'''"
		char sl_`lang'_f[ethnologue] "`:word 1 of `sl_`lang'''"
		char sl_`lang'_m[iso] "`:word 2 of `sl_`lang'''"
		char sl_`lang'_f[iso] "`:word 2 of `sl_`lang'''"		
	}

	tempfile language
	save `language'
	
******************************************************************************************************************************************
* 3. add in the language distance variable
******************************************************************************************************************************************

	**********************************************************************************************************
	* 3.1 create the dominant_language variable manually
	**********************************************************************************************************

	use `language', clear
	merge m:1 language using "../08_temp/matched_language_list", keepusing(language_ethnologue iso) assert(master match)
	
	rename iso mothertongue_iso
	
	count if _merge == 1 & language~="all mother tongues"
	dis as error "Please look into " r(N) " observations where languages did not merge; probably because of incomplete ethnologue-census language matching"

	preserve
		*diagnostics diagnostics!
		pause on
		pause
		collapse (sum) total_speakers_? if is_state & _merge == 1 & language!="all mother tongues", by(language)
		egen total_speakers = rowtotal(total_speakers_?)
		gsort -total_speakers
		dis as err "Here are the top 10 languages that do not merge:"
		noi li language total_speakers in 1/10
		sum total_speakers
		local sum = r(sum)
		dis as err "The total speakers for the languages that do not merge are: `:dis %6.0fc `sum''"
	restore
		
	drop _merge 

	* information on state official languages is available in Report of the Commissioner for Linguistic Minorities (2016)
	* some states have multiple official languages; we pick the most popular one (as per Census 2011 Table C-16)
	* A&N Islands: Hindi* and English
	* Dadra & Nagar Haveli: Gujarati* and Hindi
	* Tripura: Bengali*, English, Kokborok

	* also the component parts of Assam 1961 have different official languages:
	* Assam 2011: Assamese
	* Meghalaya: English [United Khasi & Jaintia Hills; Garo Hills]
	* Mizoram: Mizo*, English, Hindi [Mizo Hills]

	gen dominant_language = "Hindi" if inlist(state_1961,"Himachal Pradesh","Bihar","Madhya Pradesh","Rajasthan","Punjab","Andaman & Nicobar Islands") 
		// Punjab too, since this is basically Himachal
	replace dominant_language = "Telugu" if state_1961 == "Andhra Pradesh"
	replace dominant_language = "Assamese" if state_1961 == "Assam"
	replace dominant_language = "Gujarati" if inlist(state_1961,"Gujarat","Dadra and Nagar Haveli")
	replace dominant_language = "Malayalam" if inlist(state_1961,"Kerala","Laccadive, Minicoy and Amindivi Islands")
	replace dominant_language = "Tamil" if state_1961 == "Madras"
	replace dominant_language = "Marathi" if state_1961 == "Maharashtra"
	replace dominant_language = "Bengali" if inlist(state_1961,"Tripura","West Bengal")
	replace dominant_language = "Meitei" if state_1961 == "Manipur"
	replace dominant_language = "Kannada" if state_1961 == "Mysore"
	replace dominant_language = "English" if state_1961 == "Nagaland" | strpos(regionname6113,"United Khasi") | strpos(regionname6113,"Garo Hills") 
	replace dominant_language = "Odia" if state_1961 == "Orissa" 
	replace dominant_language = "Mizo" if regionname6113 == "Mizo Hills"

	**********************************************************************************************************
	* 3.2 count the number of speakers of dominant language as subsidiary language
	**********************************************************************************************************
	
	* first we find the ISO code for the dominant language
	
	preserve
		use "../08_temp/matched_language_list", clear
		duplicates drop language_ethnologue, force
		keep language_ethnologue iso
		rename language_ethnologue dominant_language
		rename iso dominant_language_iso
		
		tempfile ethnologue_languages
		save `ethnologue_languages'
	restore
	
	merge m:1 dominant_language using `ethnologue_languages', assert(2 3) keep(3) nogen
	
	* now we iterate over the dominant languages and sum the relevant subsidiary language variables
	
	levelsof dominant_language_iso, local(iso_codes)
	
	foreach x in m f {
		gen subsi_speakers_of_dom_lang_`x' = .
	
		foreach dominant_iso of local iso_codes {
			local subsi_vars
			foreach var of varlist sl_*_`x' {
				local subsi_iso: char `var'[iso]
				if "`subsi_iso'" == "`dominant_iso'" local subsi_vars `subsi_vars' `var'
			}
			tempvar subsi_speakers_`x'
			egen `subsi_speakers_`x'' = rowtotal(`subsi_vars') if dominant_language_iso == "`dominant_iso'"
			replace subsi_speakers_of_dom_lang_`x' = `subsi_speakers_`x''  if dominant_language_iso == "`dominant_iso'"
		}
	}
	
	******************************************************************************************************************************************
	* 3.3 to make the code efficient, we create a file with all unique combos of dominant_language and language_ethnologue (i.e. the mother tongue)
	* 		and we run the counting_nodes program on that file with unique combos (rather than the full file)
	******************************************************************************************************************************************
	
	
	merge m:1 region6113 using "../08_temp/dise_modal_languages", keepusing(modal_language modal_language_string num_schools)
	assert is_state if _merge == 1
	drop if _merge == 2
	drop _merge

	preserve
		keep if is_state
		drop modal_language* num_schools
		merge m:1 state_1961 using "../08_temp/dise_modal_languages_state", ///
			keepusing(modal_language modal_language_string num_schools) keep(match) nogen
		tempfile state_obs
		save `state_obs'
	restore

	drop if is_state
	append using `state_obs'

	replace modal_language_string = "Punjabi, Eastern" if modal_language_string == "Punjabi"
	replace modal_language_string = "Odia" if modal_language_string == "Oriya"
	
	tempfile before_distance
	save `before_distance', replace

	keep language_ethnologue dominant_language modal_language_string
	duplicates drop language_ethnologue dominant_language modal_language_string, force

	tempvar dise_language
	clonevar `dise_language' = modal_language_string
	replace `dise_language' = "" if modal_language_string == "Others" 
	 
	local N = _N


	foreach dtype of local dist_types {
		gen lang_distance_`dtype'_dominant = .
		gen lang_distance_`dtype'_modal = .
		}
		
	forval i=1/`N' {
		if language_ethnologue[`i'] == "" continue
		local lang1 = language_ethnologue[`i']
		local lang2 = dominant_language[`i']
		local lang3 = `dise_language'[`i']
		node_distance , lang1("`lang1'") lang2("`lang2'")
		foreach dtype of local dist_types {
			local dist_`dtype' = r(dist_`dtype')
			replace lang_distance_`dtype'_dominant = `dist_`dtype'' in `i'
			}
		if "`lang3'"~="" {
			node_distance , lang1("`lang1'") lang2("`lang3'")
			foreach dtype of local dist_types {
				local dist_`dtype' = r(dist_`dtype')
				replace lang_distance_`dtype'_modal = `dist_`dtype'' in `i'
				}
			}	
		}

	drop `dise_language' 

	tempfile distances
	save `distances'

	******************************************************************************************************************************************
	* 3.4 merge the language distances back into the main dataset
	******************************************************************************************************************************************
	
	use `before_distance', clear
	merge m:1 language_ethnologue dominant_language modal_language_string using `distances', assert(match) nogen

	drop modal_language_string

	gsort state_1961 -is_state regionname6113 castegroup_1961_2011_code mothertongue

	order state_1961 regionname6113 castegroup_1961_2011_code mothertongue

	tempfile before_all_distance
	save `before_all_distance'

******************************************************************************************************************************************
* 4. calculating the weighted distance over all media of instruction, in each district/region
******************************************************************************************************************************************

	use `before_all_distance', clear
	duplicates drop language_ethnologue, force
	keep language_ethnologue

	preserve
		use "../08_temp/dise_lang_distribution", clear
		foreach var of varlist frac_schools_* {
			local lang: var label `var'
			local dise_languages `" `dise_languages' "`lang'" "'
			}
	restore
	
	local N = _N
	#delimit ;
	local dise_lang_code	     1       2        3      4      5        6       7        8        9        10 
								11     12       13      		14      15     16    17    18    19     20    21     22    23 
								24   25     26       29   30  32  33  34  39  98    99 ;                         
	local dise_lang_string " Assamese Bengali Gujarati Hindi Kannada Kashmiri Konkani Malayalam Manipuri Marathi
								Nepali Oriya Punjabi 			Sanskrit Sindhi Tamil Telugu Urdu English Bodo Mising Dogri Khasi
								Garo Mizo  Bhutia  French NA  NA  NA  NA  NA  NA  Others " ;
	local ethnologue_lang  " Assamese Bengali Gujarati Hindi Kannada Kashmiri Konkani Malayalam  Meitei  Marathi
								Nepali Odia "Punjabi, Eastern" Sanskrit Sindhi Tamil Telugu Urdu English Boro Mising Dogri Khasi
								Garo Mizo Sikkimese NA   NA  NA  NA  NA  NA  NA    NA " ;
	#delimit cr
	* the local dise_lang_string is only for our reference is and is not used anywhere
	
	
	foreach lang of local dise_languages {
		if "`lang'" == "NA" continue
		local pos: list posof "`lang'" in ethnologue_lang
		local code: word `pos' of `dise_lang_code'
		foreach dtype of local dist_types {
			gen lang_distance_`dtype'_`code' = .
			}
		forval i = 1/`N' {
			if language_ethnologue[`i'] == "" continue
			local lang1 = language_ethnologue[`i']
			node_distance , lang1("`lang1'") lang2("`lang'")
			foreach dtype of local dist_types {
				local dist_`dtype' = r(dist_`dtype')
				replace lang_distance_`dtype'_`code' = `dist_`dtype'' in `i'
				}
			}
		}
		
	tempfile all_distances
	save `all_distances'

******************************************************************************************************************************************
* 5. merge the weighted distance over all media of instruction, back into the main dataset
******************************************************************************************************************************************

	use "../08_temp/dise_lang_distribution", clear

	preserve
		keep if is_state
		drop is_state
		tempfile state_level
		save `state_level'
	restore
	
	keep if ~is_state
	drop is_state
	tempfile dist_level
	save `dist_level'

	use `before_all_distance', clear
	keep if is_state
	merge m:1 state_1961 using `state_level', keepusing(frac*) assert(match using) keep(match) nogen
	tempfile state_level_merged
	save `state_level_merged'

	use `before_all_distance', clear
	keep if ~is_state
	merge m:1 state_1961 region6113 using `dist_level', keepusing(frac*) assert(match using) keep(match) nogen

	append using `state_level_merged'
	gsort state_1961 -is_state regionname6113 castegroup_1961_2011_code mothertongue

	merge m:1 language_ethnologue using `all_distances', assert(match) nogen

	order frac_enroll_lang* frac_st_enroll_lang* frac_schools_lang*, after(lang_distance_dow_modal)

	egen total_enroll_frac = rowtotal(frac_enroll_lang1 - frac_enroll_lang26) , missing // all other languages are NA
	egen total_st_enroll_frac = rowtotal(frac_st_enroll_lang1 - frac_st_enroll_lang26) , missing // -ditto- 
	egen total_schools_frac = rowtotal(frac_schools_lang1 - frac_schools_lang26) , missing // -ditto-


	foreach dtype of local dist_types {
		foreach var of varlist lang_distance_`dtype'_? lang_distance_`dtype'_?? {
			if regexm("`var'","[0-9]+$") local num = regexs(0) // the digits at the end of the var
			gen frac_enroll_dist_`dtype'_`num' = frac_enroll_lang`num' * lang_distance_`dtype'_`num' / total_enroll_frac
			gen frac_st_enroll_dist_`dtype'_`num' = frac_st_enroll_lang`num' * lang_distance_`dtype'_`num' / total_st_enroll_frac
			gen frac_schools_dist_`dtype'_`num' = frac_schools_lang`num' * lang_distance_`dtype'_`num' / total_schools_frac
			}

		egen lang_distance_`dtype'_enrol_all = rowtotal(frac_enroll_dist_`dtype'_*) , missing
		egen lang_distance_`dtype'_enrol_st = rowtotal(frac_st_enroll_dist_`dtype'_*) , missing
		egen lang_distance_`dtype'_schools_all = rowtotal(frac_schools_dist_`dtype'_*) , missing	
		drop lang_distance_`dtype'_? lang_distance_`dtype'_??
		}


	drop frac_* total_*_frac 

	gsort state_1961 -is_state regionname6113 castegroup_1961_2011_code mothertongue
	order state_1961 regionname6113 castegroup_1961_2011_code mothertongue

	foreach dtype of local dist_types {
		label var lang_distance_`dtype'_dominant "Distance to dominant state language"
		label var lang_distance_`dtype'_modal "Distance to modal district medium of instruction (in terms of number of schools for overall population)"
		label var lang_distance_`dtype'_schools_all "Weighted distance to all media of instruction in district (weights: fractions of schools)"
		label var lang_distance_`dtype'_enrol_all "Weighted distance to all media of instruction in district (weights: fractions of total enrolment)"
		label var lang_distance_`dtype'_enrol_st "Weighted distance to all media of instruction in district (weights: fractions of ST enrolment)"
		}
		
	compress
	capture drop __*
	save "../03_processed/census_1961_mothertongue_for_analysis_distance", replace


project , creates("../08_temp/census_1961_subsidiary_languages.xlsx")
project , creates("../08_temp/asjp_distances.dta") // this is created by the asjp_distances program
project , creates("../03_processed/census_1961_mothertongue_for_analysis_distance.dta")
