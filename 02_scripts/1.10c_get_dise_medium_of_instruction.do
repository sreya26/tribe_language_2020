
project , uses("../08_temp/dise_basic_general.dta")
project , uses("../08_temp/dise_states_districts.dta")
project , uses("../08_temp/regions6113_with_dists_dise.dta")
project , uses("../08_temp/school_enrollment.dta")

project , original("1.A_create_1961_statevar.do")

run "1.A_create_1961_statevar.do"

*********************************************************************************************************************
* 1. create the file dise_basic_general_with_regions, by
*	-- giving codes from consistent 1961-2013 regions and consistent 2011-2013 regions
*	-- keeping only states with ST populations
*   -- keeping only data from schools with primary grades
*********************************************************************************************************************

	use "../08_temp/dise_basic_general", clear

	gen stcode_dise = real(substr(school_code,1,2))
	gen distcode_dise = real(substr(school_code,3,2))
	gen dcode_dise = real(substr(school_code,1,4))
	rename distname district_dise
	drop state

	merge m:1 dcode_dise using "../08_temp/dise_states_districts", assert(match using) keepusing(state_dise)
	assert _merge == 2 if mod(dcode_dise,100) == 0 // state-level observations
	drop _merge
	
	order state_dise, after(stcode_dise)
	
	*********************************************************************************************************************
	* 1.1 give DISE 2013-14 data codes from consistent 1961-2013 regions
	*********************************************************************************************************************

	merge m:1 dcode_dise using "../08_temp/regions6113_with_dists_dise", ///
			assert(match) nogen keepusing(region6113 regionname6113)
	
	drop if mod(dcode_dise,100) == 0
			
			
	*********************************************************************************************************************
	* 1.2 drop states that do not have STs delimited in 2011, and keep only elementary schools
	*********************************************************************************************************************

	drop if inlist(state_dise,"Chandigarh","Haryana","NCT of Delhi","Puducherry","Punjab")

	keep if inlist(schcat,1,2,3,6) // keep only elementary schools, i.e. those with primary grades (and possibly other grades too)

	note: This dataset contains information only on elementary schools, and only in areas that had STs delimited in 2011.

	compress
	
	*********************************************************************************************************************
	* 1.3 create a state variable for 1961
	* we can do this since our regions for the areas in which STs were delimited, do not cross census 1961 state lines
	* this would not be true for the Punjab & Himachal Pradesh region in general
	* remember that we have also ignored the UP-Bihar transfers in the 1960s
	*********************************************************************************************************************
	
	qui create_1961_statevar stcode_dise , gen(state_1961)
	
	* the only areas that remain of Punjab are the ones that eventually went over to Himachal. Hence the following line.
	replace state_1961 = "Himachal Pradesh" if state_1961 == "Punjab"
	
	order state_1961 , after(state_dise)
	
	save "../03_processed/dise_basic_general_with_regions", replace


****************************************************************************************************************************
* 2. Create a dataset with the modal medium of instruction in each district/region (as well as at the state level)
****************************************************************************************************************************

	****************************************************************************************************************************
	* 2.1 State-level dataset
	****************************************************************************************************************************

	use "../03_processed/dise_basic_general_with_regions", clear
	egen modal_language = mode(medinstr1) , by(state_1961)
	assert ~missing(modal_language) // check to ensure there is always a [unique] mode (missing would occur if there are multiple modes)
	label values modal_language MEDINSTR1
	decode modal_language, gen(modal_language_string)
	egen num_schools = count(medinstr1), by(state_1961)

	duplicates drop state_1961, force

	keep state_1961 modal_language modal_language_string num_schools
	compress
	save "../08_temp/dise_modal_languages_state", replace

	****************************************************************************************************************************
	* 2.2 Region-level dataset
	****************************************************************************************************************************

	use "../03_processed/dise_basic_general_with_regions", clear

	egen modal_language = mode(medinstr1) , by(region6113) maxmode
	label values modal_language MEDINSTR1
	decode modal_language, gen(modal_language_string)

	egen num_schools = count(medinstr1), by(region6113)

	duplicates drop region6113, force
	keep state_1961 state_dise region6113 regionname6113 modal_language modal_language_string num_schools
	order state_1961 state_dise region6113 regionname6113 modal_language modal_language_string num_schools
	compress
	save "../08_temp/dise_modal_languages", replace


	
***********************************************************************************************************************************************************
* 3. Create a dataset with the full distribution of media of instruction in each region (as well as at the state level) 
***********************************************************************************************************************************************************


	************************************************************************************************************
	* 3.1 Method 1: Using overall number of schools for each medium of instruction [nothing specific to STs]
	************************************************************************************************************

	use "../03_processed/dise_basic_general_with_regions", clear

	egen num_schools = count(pincode), by(region6113) // could've picked any numeric variable to count
	egen num_schools_lang = count(pincode), by(region6113 medinstr1)

	duplicates drop region6113 medinstr1, force

	keep state_1961 region6113 regionname6113 num_schools medinstr1 num_schools_lang
	sort state_1961 region6113 regionname6113 num_schools medinstr1 num_schools_lang
	order state_1961 region6113 regionname6113 num_schools medinstr1 num_schools_lang

	noi count if missing(medinstr1) // should be just two observations, with num_schools_lang = 1 each [so two schools in all]
	drop if missing(medinstr1)
	reshape wide num_schools_lang, i(state_1961 region6113 regionname6113 num_schools) j(medinstr1)
	 
	* create state-levels obs
	preserve
		collapse (sum) num_schools num_schools_lang*, by(state_1961)
		gen is_state = 1
		tempfile state_level
		save `state_level'
	restore

	gen is_state = 0
	append using `state_level'

	gsort state_1961 -is_state region6113 regionname6113 num_schools 

	local dise_lang_code	     1       2        3      4      5        6       7        8        9        10     11     12         13             14      15     16    17    18    19     20    21     22    23   24   25     26       27     28     29   30  31  32  33  34  39  98    99                          
	local dise_lang_string " Assamese Bengali Gujarati Hindi Kannada Kashmiri Konkani Malayalam Manipuri Marathi Nepali Oriya      Punjabi       Sanskrit Sindhi Tamil Telugu Urdu English Bodo Mising Dogri Khasi Garo Mizo  Bhutia   Lepcha Limboo French NA  NA  NA  NA  NA  NA  NA  Others "
	local ethnologue_lang  " Assamese Bengali Gujarati Hindi Kannada Kashmiri Konkani Malayalam  Meitei  Marathi Nepali Odia "Punjabi, Eastern" Sanskrit Sindhi Tamil Telugu Urdu English Boro Mising Dogri Khasi Garo Mizo Sikkimese Lepcha Limbu    NA   NA  NA  NA  NA  NA  NA  NA    NA " 
	* note: above, we code French as NA rather than putting it in ethnologue_tree because it occurs only in a few schools in Pondicherry, which will in any case drop out of our dataset
	* note: codes 30-98 are not documented in the DISE codebooks. Follow this up if possible.

	foreach var of varlist num_schools_lang* {
		if regexm("`var'","[0-9]+$") local num = regexs(0) // the digits at the end of the var
		gen frac_schools_lang`num' = num_schools_lang`num' / num_schools
		local pos: list posof "`num'" in dise_lang_code
		local lang: word `pos' of `ethnologue_lang'"
		label var frac_schools_lang`num' "`lang'"
		}

	keep state_1961 region6113 regionname6113 frac_schools_lang* is_state
	recode frac_schools_lang* (. = 0)

	tempfile lang_distrib_by_schools
	save `lang_distrib_by_schools'


	*********************************************************************************************************
	* 3.2 Method 2: Using enrolments for each medium of instruction, both for overall population and for STs
	*********************************************************************************************************

	use "../03_processed/dise_basic_general_with_regions", clear
	keep region6113 regionname6113 state_1961 state_dise dcode_dise district_dise school_code medinstr1
	rename school_code schcd

	merge 1:1 schcd using "../08_temp/school_enrollment"

	drop if _merge == 2 
	drop _merge
	drop enroll_primary* enroll_secondary* filename

	egen double tot_enroll_region = total(enroll_tot), by(region6113)
	egen double tot_enroll_lang = total(enroll_tot), by(region6113 medinstr1)

	egen double tot_st_enroll_region = total(enroll_tot_st), by(region6113)
	egen double tot_st_enroll_lang = total(enroll_tot_st), by(region6113 medinstr1)

	duplicates drop region6113 medinstr1, force

	keep state_1961 region6113 regionname6113 *_enroll_region medinstr1 *_enroll_lang
	sort state_1961 region6113 regionname6113 *_enroll_region medinstr1 *_enroll_lang
	order state_1961 region6113 regionname6113 *_enroll_region medinstr1 *_enroll_lang

	noi count if missing(medinstr1) // 2 obs
	drop if missing(medinstr1)
	reshape wide tot_enroll_lang tot_st_enroll_lang, i(state_1961 region6113 regionname6113 tot_enroll_region tot_st_enroll_region) j(medinstr1)
	 
	* create state-levels obs
	preserve
		collapse (sum) tot_enroll_region tot_enroll_lang* tot_st_enroll_region tot_st_enroll_lang*, by(state_1961)
		gen is_state = 1
		tempfile state_level
		save `state_level'
	restore

	gen is_state = 0
	append using `state_level'

	gsort state_1961 -is_state region6113 regionname6113 tot_enroll_region tot_st_enroll_region
	
	#delimit ;
	local dise_lang_code	     1       2        3      4      5        6       7        8        9        10     
								11     12         13             14      15     16    17    18    19     20    21     
								22    23   24   25     26       27     28     29   30  31  32  33  34  39  98    99        ;                  
	local dise_lang_string " Assamese Bengali Gujarati Hindi Kannada Kashmiri Konkani Malayalam Manipuri Marathi 
							Nepali Oriya      Punjabi       Sanskrit Sindhi Tamil Telugu Urdu English Bodo Mising 
							Dogri Khasi Garo Mizo  Bhutia   Lepcha Limboo French NA  NA  NA  NA  NA  NA  NA  Others " ;
	local ethnologue_lang  " Assamese Bengali Gujarati Hindi Kannada Kashmiri Konkani Malayalam  Meitei  Marathi 
							Nepali Odia "Punjabi, Eastern" Sanskrit Sindhi Tamil Telugu Urdu English Boro Mising 
							Dogri Khasi Garo Mizo Sikkimese Lepcha Limbu    NA   NA  NA  NA  NA  NA  NA  NA    NA " ;
	#delimit cr
	* note: above, we code French as NA rather than putting it in ethnologue_tree because it occurs only in a few schools in Pondicherry, which will in any case drop out of our dataset
	* note: codes 30-98 are not documented in the DISE codebooks. Follow this up if possible.

	foreach var of varlist tot_enroll_lang* {
		if regexm("`var'","[0-9]+$") local num = regexs(0) // the digits at the end of the var
		gen frac_enroll_lang`num' = tot_enroll_lang`num' / tot_enroll_region
		gen frac_st_enroll_lang`num' = tot_st_enroll_lang`num'/ tot_st_enroll_region
		local pos: list posof "`num'" in dise_lang_code
		local lang: word `pos' of `ethnologue_lang'"
		label var frac_enroll_lang`num' "`lang'"
		label var frac_st_enroll_lang`num' "`lang'"
		}

	keep state_1961 region6113 regionname6113 frac_enroll_lang* frac_st_enroll_lang* is_state
	recode frac_enroll_lang* (. = 0)
	recode frac_st_enroll_lang* (. = 0)

	merge 1:1 state_1961 region6113 using `lang_distrib_by_schools', assert(match) nogen
	* note that we need state_1961 in the merge above, because for state-level obs, region6113 is missing in both datasets, and thus is not unique by itself
	save "../08_temp/dise_lang_distribution", replace
	

project , creates("../03_processed/dise_basic_general_with_regions.dta")
project , creates("../08_temp/dise_modal_languages_state.dta")
project , creates("../08_temp/dise_modal_languages.dta")
project , creates("../08_temp/dise_lang_distribution.dta")
