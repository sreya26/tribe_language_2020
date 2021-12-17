*************************************************************************************************************************
* this file appends the original census 2011 education files for total Scheduled Tribes and Overall Population at the state and district level
* i.e. from Tables 08,SC-08
* these files contain both education level data and age data 
*! version 1.0 created by Sreya Majumder on 10 November 2021
*************************************************************************************************************************
	
local edu_dist_folder_all "../01_data/census_2011_st_edu_data/overall_08"
local edu_dist_folder_sc "../01_data/census_2011_st_edu_data/sc_08"
	
local edu_dist_files_all: dir "`edu_dist_folder_all'" files "DDW-????C-08.xlsx"
local edu_dist_files_sc: dir "`edu_dist_folder_sc'" files "DDW-????C-08SC.xlsx"
	
local file_types edu_dist_all edu_dist_sc
	
foreach ft of local file_types {
	foreach file of local `ft'_files {
		project , original("``ft'_folder'/`file'")		
	}
}

*************************************************************************************************************************
* 1. append the district level education files for overall population
*************************************************************************************************************************

	clear
	tempfile edu_dist_all
	save `edu_dist_all' , emptyok replace

	foreach file of local edu_dist_files_all {
		import excel using "`edu_dist_folder_all'/`file'", clear cellrange(A8)
		destring B C E H-Z A?, replace
		keep if A == "C2308"
		drop A
		
		tempfile table
		save `table', replace
		
		use `edu_dist_all', clear
		dis as error "Appending data from file `file' ... "
		append using `table'
		
		save`edu_dist_all', replace
		}

	rename B state_code
	rename C district_code
	rename D area_name
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
	 
	replace area_name = subinstr(area_name,"State - ","",1)
	replace area_name = subinstr(area_name,"UNION TERRITORY - ","",1)
	replace area_name = subinstr(area_name,"District - ","",1)


	replace area_name = trim(area_name)

	gen state = area_name if district_code == 0
	replace state = state[_n-1] if missing(state)

	replace area_name = "" if district_code == 0
	rename area_name district
	order state , before(district)
	drop AT
	duplicates drop //note: this folder also contains the 00 INDIA file hence we have duplicates of the state level obs

	

*************************************************************************************************************************
* 2. keep just the age information from the district-level age-educational enrolment data
* the relevant age groups we need are:
* (i) 0-14 years [secondary]
*************************************************************************************************************************

	drop if district_code == 0 
	
	drop if !inlist(age_group,"All ages","0-6","7","8","9","10","11","12","13") & !inlist(age_group,"14","15","16","17","18","19")

	gen upper_age = age_group if !inlist(age_group,"All ages","0-6")
	replace upper_age = "6" if age_group == "0-6"

	destring upper_age, replace

	local upper_ages 6 8 11 14 17 19

	foreach x in p m f {
		foreach y of local upper_ages {
			tempvar age0to`y'_`x'
			egen `age0to`y'_`x'' = sum(total_`x') if inrange(upper_age,6,`y'), by(district_code tru)
			egen age0to`y'_`x' = max(`age0to`y'_`x'') , by(district_code tru)
			drop `age0to`y'_`x''
		}	
	}

	format %16.0fc total_p - unclassified_f age0*
	drop upper_age

	drop if age_group != "All ages"
	drop age_group
	
	sort state_code district_code tru
	
	label define TRU 1 "Total" 2 "Rural" 3 "Urban"
	tempvar tru
	encode tru , gen(`tru') label(TRU)


	
	compress
	save "../08_temp/census2011_overall_edu_data", replace
	
	
*************************************************************************************************************************
* 3. append the district level education files for sc population
*************************************************************************************************************************

	clear
	tempfile edu_dist_sc
	save `edu_dist_sc' , emptyok replace

	foreach file of local edu_dist_files_sc {
		import excel using "`edu_dist_folder_sc'/`file'", clear cellrange(A8)
		destring B C E H-Z A?, replace
		keep if A == "C2508SC"
		drop A
		
		tempfile table
		save `table', replace
		
		use `edu_dist_sc', clear
		dis as error "Appending data from file `file' ... "
		append using `table'
		
		save`edu_dist_sc', replace
		}

	rename B state_code
	rename C district_code
	rename D area_name
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
	 
	replace area_name = subinstr(area_name,"State - ","",1)
	replace area_name = subinstr(area_name,"UNION TERRITORY - ","",1)
	replace area_name = subinstr(area_name,"District - ","",1)


	replace area_name = trim(area_name)

	gen state = area_name if district_code == 0
	replace state = state[_n-1] if missing(state)

	replace area_name = "" if district_code == 0
	rename area_name district
	order state , before(district)
	drop AT
	duplicates drop //note: this folder also contains the 00 INDIA file hence we have duplicates of the state level obs

	
	
*************************************************************************************************************************
* 4. keep just the age information from the district-level age-educational enrolment data
* the relevant age groups we need are:
* (i) 0-14 years [secondary]
*************************************************************************************************************************

	drop if district_code == 0 
	
	drop if !inlist(age_group,"All ages","0-6","7","8","9","10","11","12","13") & !inlist(age_group,"14","15","16","17","18","19")

	gen upper_age = age_group if !inlist(age_group,"All ages","0-6")
	replace upper_age = "6" if age_group == "0-6"

	destring upper_age, replace

	local upper_ages 6 8 11 14 17 19

	foreach x in p m f {
		foreach y of local upper_ages {
			tempvar age0to`y'_`x'
			egen `age0to`y'_`x'' = sum(total_`x') if inrange(upper_age,6,`y'), by(district_code tru)
			egen age0to`y'_`x' = max(`age0to`y'_`x'') , by(district_code tru)
			drop `age0to`y'_`x''
		}	
	}

	format %16.0fc total_p - unclassified_f age0*
	drop upper_age

	drop if age_group != "All ages"
	drop age_group
	
	sort state_code district_code tru
	
	label define TRU 1 "Total" 2 "Rural" 3 "Urban"
	tempvar tru
	encode tru , gen(`tru') label(TRU)

	
	compress
	save "../08_temp/census2011_sc_edu_data", replace
	
	


project , creates("../08_temp/census2011_overall_edu_data.dta")	
project , creates("../08_temp/census2011_sc_edu_data.dta")	
	
	
	


