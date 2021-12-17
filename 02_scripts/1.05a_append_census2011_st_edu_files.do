*************************************************************************************************************************
* this file appends the original census 2011 education files for individual Scheduled Tribes at the state and district level
* i.e. from Tables ST-8, ST-8 Appendix, ST-9 Appendix
* we need ST-9 Appendix for district-level age data (ST-8 has this for the state level already)
* in turn, the age data is needed to be able to compute literacy rates etc.
*
*! version 1.0 created by Hemanshu Kumar on 7 July 2020
*************************************************************************************************************************


local edu_state_folder "../01_data/census_2011_st_edu_data/st_08/"
local edu_dist_folder "../01_data/census_2011_st_edu_data/st_08a/"
local age_dist_folder "../01_data/census_2011_st_edu_data/st_09a/"

local edu_state_files: dir "`edu_state_folder'" files "ST-??-00-008-2011-ddw.XLS"  
local edu_dist_files: dir "`edu_dist_folder'" files "ST-??-00-08A-DDW-2011.XLS"
local age_dist_files: dir "`age_dist_folder'" files "ST-??-00-09A-DDW-2011.XLS"

local file_types edu_state edu_dist age_dist

foreach ft of local file_types {
	foreach file of local `ft'_files {
		project , original("``ft'_folder'/`file'")		
	}
}


*************************************************************************************************************************
* 1. append the state level education files
*************************************************************************************************************************

tempfile edu_state
save `edu_state' , emptyok replace

foreach file of local edu_state_files {
	import excel using "`edu_state_folder'/`file'", clear cellrange(A8)
	destring B D H-Z A?, replace
	keep if A == "ST0008"
	drop A
	
	tempfile table
	save `table', replace
	
	use `edu_state', clear
	dis as error "Appending data from file `file' ... "
	append using `table'
	
	save`edu_state', replace
	}

rename B state_code
rename C state
rename D caste_code
rename E caste_name
rename F tru
rename G age_group
rename H total_p
rename I total_m
rename J total_f
rename K illiterate_p
rename L illiterate_m
rename M illiterate_f
rename N literate_p
rename O literate_m
rename P literate_f
rename Q litnoed_p
rename R litnoed_m
rename S litnoed_f
rename T belowprimary_p
rename U belowprimary_m
rename V belowprimary_f
rename W primary_p
rename X primary_m
rename Y primary_f
rename Z middle_p
rename AA middle_m
rename AB middle_f
rename AC matric_p
rename AD matric_m
rename AE matric_f
rename AF intermediate_p
rename AG intermediate_m
rename AH intermediate_f
rename AI nontechdiploma_p
rename AJ nontechdiploma_m
rename AK nontechdiploma_f
rename AL techdiploma_p
rename AM techdiploma_m
rename AN techdiploma_f
rename AO graduate_p
rename AP graduate_m
rename AQ graduate_f
 
replace state = subinstr(state,"STATE - ","",1)
replace state = subinstr(state,"UNION TERRITORY - ","",1)
replace state = regexr(state,"[0-9]+$","")
replace state = trim(state)

compress

save "../08_temp/census2011_st_edu_state_data", replace


*************************************************************************************************************************
* 2. append the district level education files
*************************************************************************************************************************

clear
tempfile edu_dist
save `edu_dist' , emptyok replace

foreach file of local edu_dist_files {
	import excel using "`edu_dist_folder'/`file'", clear cellrange(A8)
	destring B C E H-Z A?, replace
	keep if A == "ST008A"
	drop A
	
	tempfile table
	save `table', replace
	
	use `edu_dist', clear
	dis as error "Appending data from file `file' ... "
	append using `table'
	
	save`edu_dist', replace
	}

rename B state_code
rename C district_code_instate
rename D area_name
rename E caste_code
rename F caste_name
rename G tru
rename H total_p
rename I total_m
rename J total_f
rename K illiterate_p
rename L illiterate_m
rename M illiterate_f
rename N literate_p
rename O literate_m
rename P literate_f
rename Q litnoed_p
rename R litnoed_m
rename S litnoed_f
rename T belowprimary_p
rename U belowprimary_m
rename V belowprimary_f
rename W primary_p
rename X primary_m
rename Y primary_f
rename Z middle_p
rename AA middle_m
rename AB middle_f
rename AC matric_p
rename AD matric_m
rename AE matric_f
rename AF intermediate_p
rename AG intermediate_m
rename AH intermediate_f
rename AI nontechdiploma_p
rename AJ nontechdiploma_m
rename AK nontechdiploma_f
rename AL techdiploma_p
rename AM techdiploma_m
rename AN techdiploma_f
rename AO graduate_p
rename AP graduate_m
rename AQ graduate_f
 
replace area_name = subinstr(area_name,"STATE - ","",1)
replace area_name = subinstr(area_name,"UNION TERRITORY - ","",1)
replace area_name = subinstr(area_name,"District - ","",1)

tempvar code
gen `code' = regexs(0) if regexm(area_name,"[0-9]+$")
replace area_name = subinstr(area_name,`code',"",1)
gen district_code = real(`code') if district_code_instate != 0
replace district_code = 0 if district_code_instate == 0
order district_code , after(district_code_instate)

drop district_code_instate `code'

replace area_name = trim(area_name)

gen state = area_name if district_code == 0
replace state = state[_n-1] if missing(state)

replace area_name = "" if district_code == 0
rename area_name district
order state , before(district)

compress

save "../08_temp/census2011_st_edu_dist_data", replace


*************************************************************************************************************************
* 3. append the district level age & current education files
*************************************************************************************************************************

clear
tempfile age_dist
save `age_dist' , emptyok replace

foreach file of local age_dist_files {
	import excel using "`age_dist_folder'/`file'", clear cellrange(A6)
	destring B D F J-Z A?, replace
	keep if A == "ST009A"
	drop A
	
	tempfile table
	save `table', replace
	
	use `age_dist', clear
	dis as error "Appending data from file `file' ... "
	append using `table'
	
	save`age_dist', replace
	}

rename B state_code
rename C state
rename D district_code_instate
rename E district
rename F caste_code
rename G caste_name
rename H tru
rename I age_group
rename J total_p
rename K total_m
rename L total_f
rename M attending_p
rename N attending_m
rename O attending_f
rename P school_p
rename Q school_m
rename R school_f_m
rename S college_p
rename T college_m
rename U college_f
rename V vocational_p
rename W vocational_m
rename X vocational_f
rename Y special_p
rename Z special_m
rename AA special_f
rename AB litcenter_p
rename AC litcenter_m
rename AD litcenter_f
rename AE other_p
rename AF other_m
rename AG other_f
 
replace state = subinstr(state,"STATE - ","",1)
replace state = subinstr(state,"UNION TERRITORY - ","",1)
replace state = regexr(state,"[0-9]+$","")
replace state = trim(state)

replace district = subinstr(district,"District - ","",1)

tempvar code
gen `code' = regexs(0) if regexm(district,"[0-9]+$")
replace district = subinstr(district,`code',"",1)
gen district_code = real(`code') if district_code_instate != 0
replace district_code = 0 if district_code_instate == 0
order district_code , after(district_code_instate)
drop district_code_instate `code'

replace district = trim(district)

compress

save "../08_temp/census2011_st_age_dist_data", replace


 
project , creates("../08_temp/census2011_st_edu_state_data.dta") 
project , creates("../08_temp/census2011_st_edu_dist_data.dta")
project , creates("../08_temp/census2011_st_age_dist_data.dta")
 
 
 
 
 
 
 
 
 
