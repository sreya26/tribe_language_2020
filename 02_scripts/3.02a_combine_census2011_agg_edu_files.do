*************************************************************************************************************************
* this file appends the original census 2011 education files for overall pop, SC and ST at the state level
* i.e. from Tables C-8, C-8 SC and C-8 ST
* it also imputes corresponding values for Non-SC/STs

*! version 1.0 created by Hemanshu Kumar on 1 February 2021
*************************************************************************************************************************

clear

local edu_folder "../01_data/census_2011_agg_edu_data"
local edu_files: dir "`edu_folder'" files "DDW-0000C-08*.xlsx"  


*************************************************************************************************************************
* 1. append the education files
*************************************************************************************************************************

	tempfile edu_aggs
	save `edu_aggs' , emptyok replace

	foreach file of local edu_files {
		import excel using "`edu_folder'/`file'", clear cellrange(A8)
		keep if inlist(A,"C2308","C2508SC","C2708ST")
		drop C
		gen caste_group = "All" if A == "C2308"
		replace caste_group = "SC" if A == "C2508SC"
		replace caste_group = "ST" if A == "C2708ST"
		drop A
		
		tempfile table
		save `table', replace
		
		use `edu_aggs', clear
		dis as error "Appending data from file `file' ... "
		append using `table'
		
		save`edu_aggs', replace
		}

	rename B state_code
	rename D state
	order caste_group, after(state)
	rename E tru
	rename F age_group
	rename G total_p
	rename H total_m
	rename I total_f
	rename J illiterate_p
	rename K illiterate_m
	rename L illiterate_f
	rename M literate_p
	rename N literate_m
	rename O literate_f
	rename P litnoed_p
	rename Q litnoed_m
	rename R litnoed_f
	rename S belowprimary_p
	rename T belowprimary_m
	rename U belowprimary_f
	rename V primary_p
	rename W primary_m
	rename X primary_f
	rename Y middle_p
	rename Z middle_m
	rename AA middle_f
	rename AB matric_p
	rename AC matric_m
	rename AD matric_f
	rename AE intermediate_p
	rename AF intermediate_m
	rename AG intermediate_f
	rename AH nontechdiploma_p
	rename AI nontechdiploma_m
	rename AJ nontechdiploma_f
	rename AK techdiploma_p
	rename AL techdiploma_m
	rename AM techdiploma_f
	rename AN graduate_p
	rename AO graduate_m
	rename AP graduate_f
	rename AQ unclassified_p
	rename AR unclassified_m
	rename AS unclassified_f

	capture drop AT
	 
	replace state = subinstr(state,"State - ","",1)
	replace state = regexr(state,"[0-9]+$","")
	replace state = trim(state)

	replace state = proper(state) if strpos(state,"DELHI") == 0
	replace state = "NCT of Delhi" if strpos(state,"DELHI")
	compress

*************************************************************************************************************************
* 2. create equivalent values for Non-SC/STs
*************************************************************************************************************************

	preserve
		foreach var of varlist total_p - unclassified_f {
			replace `var' = -`var' if inlist(caste_group,"SC","ST")
		}
				
		collapse (sum) total_p - unclassified_f , by(state_code state tru age_group)
		gen caste_group = "Non SC/ST"
		tempfile nonscst
		save `nonscst'
	restore
	
	append using `nonscst'
	
*************************************************************************************************************************
* 3. retain the relevant part of the state-level educational attainment data
* the relevant age groups we need are:
* (i) 0-6 years [literacy] ; (ii) 0-8 years [primary] ; (iii) 0-11 years [middle] 
* (iv) 0-14 years [secondary]; (v) 0-17 years [intermediate] ; (vi) 0-19 years [graduate] 
*************************************************************************************************************************

	drop if !inlist(age_group,"All ages","0-6","7","8","9","10","11","12","13") & !inlist(age_group,"14","15","16","17","18","19")

	gen upper_age = age_group if !inlist(age_group,"All ages","0-6")
	replace upper_age = "6" if age_group == "0-6"

	destring upper_age, replace

	local upper_ages 6 8 11 14 17 19

	foreach x in p m f {
		foreach y of local upper_ages {
			tempvar age0to`y'_`x'
			egen `age0to`y'_`x'' = sum(total_`x') if inrange(upper_age,6,`y'), by(state_code caste_group tru)
			egen age0to`y'_`x' = max(`age0to`y'_`x'') , by(state_code caste_group tru)
			drop `age0to`y'_`x''
		}	
	}

	format %16.0fc total_p - unclassified_f age0*
	drop upper_age

	drop if age_group != "All ages"
	drop age_group
	
	sort state_code caste_group tru
	
	label define TRU 1 "Total" 2 "Rural" 3 "Urban"
	tempvar tru
	encode tru , gen(`tru') label(TRU)

	label define CASTE_GROUPS 1 "All" 2 "Non SC/ST" 3 "SC" 4 "ST"
	tempvar caste_group
	encode caste_group, gen(`caste_group') label(CASTE_GROUPS)
	
	drop caste_group tru
	clonevar caste_group = `caste_group'
	clonevar tru = `tru'
	order caste_group tru, after(state)
	
	sort state_code caste_group tru

	compress

	drop `caste_group' `tru'
	
	save "../03_processed/census2011_agg_edu_data", replace
