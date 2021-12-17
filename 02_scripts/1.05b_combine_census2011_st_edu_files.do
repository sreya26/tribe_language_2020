*************************************************************************************************************************
* this file combines and retains the relevant parts of the census 2011 education files (i.e. education levels + age groups)
*
*! version 1.0 created by Hemanshu Kumar on 7 July 2020
*************************************************************************************************************************

project , uses("../08_temp/census2011_st_age_dist_data.dta")
project , uses("../08_temp/census2011_st_edu_dist_data.dta")
project , uses("../08_temp/census2011_st_edu_state_data.dta")

*************************************************************************************************************************
* 1. keep just the age information from the district-level age-educational enrolment data (Table ST-9 Appendix)
* and IMPUTE the age-groups we need
* the relevant age groups we need are:
* (i) 0-6 years [literacy] ; (ii) 0-8 years [primary] ; (iii) 0-11 years [middle] 
* (iv) 0-14 years [secondary]; (v) 0-17 years [intermediate] ; (vi) 0-19 years [graduate] 
*************************************************************************************************************************

use "../08_temp/census2011_st_age_dist_data", clear

foreach x in p m f {
	tempvar age0to5_`x' age6to14_`x' age15to19_`x'
	gen `age0to5_`x'' = total_`x' if age_group == "0-5"
	gen `age6to14_`x'' = total_`x' if age_group == "6-14"
	gen `age15to19_`x'' = total_`x' if age_group == "15-19"
	
	egen age0to5_`x' = max(`age0to5_`x''), by(state_code district_code caste_code tru)
	egen age6to14_`x' = max(`age6to14_`x''), by(state_code district_code caste_code tru)
	egen age15to19_`x' = max(`age15to19_`x''), by(state_code district_code caste_code tru)	

	* imputations!!
	gen age0to6_`x' = age0to5_`x' + round(age6to14_`x'/9)
	gen age0to8_`x' = age0to5_`x' + round(age6to14_`x'/3)
	gen age0to11_`x' = age0to5_`x' + round(age6to14_`x'*2/3)
	gen age0to14_`x' = age0to5_`x' + age6to14_`x'
	gen age0to17_`x' = age0to14_`x' + round(age15to19_`x'*3/5)
	gen age0to19_`x' = age0to14_`x' + age15to19_`x'
	
	drop `age0to5_`x'' `age6to14_`x'' `age15to19_`x'' age0to5_`x' age6to14_`x' age15to19_`x'
}

drop if age_group != "All ages"
drop age_group
drop total_? attending_p-other_f

tempfile dist_age
save `dist_age'

*************************************************************************************************************************
* 2. merge the district-level age information with the district-level educational attainment data (Table ST-8 Appendix)
*************************************************************************************************************************

use "../08_temp/census2011_st_edu_dist_data", clear
drop if district_code == 0

merge 1:1 state_code district_code caste_code tru using `dist_age', keepusing(age*) assert(1 3) nogen

tempfile dist_data
save `dist_data'


*************************************************************************************************************************
* 3. retain the relevant part of the state-level educational attainment data (Table ST-8)
* again, the relevant age groups we need are:
* (i) 0-6 years [literacy] ; (ii) 0-8 years [primary] ; (iii) 0-11 years [middle] 
* (iv) 0-14 years [secondary]; (v) 0-17 years [intermediate] ; (vi) 0-19 years [graduate] 
*************************************************************************************************************************

use "../08_temp/census2011_st_edu_state_data", clear

drop if !inlist(age_group,"Total","0-6","7","8","9","10","11","12","13") & !inlist(age_group,"14","15","16","17","18","19")

gen upper_age = age_group if !inlist(age_group,"Total","0-6")
replace upper_age = "6" if age_group == "0-6"

destring upper_age, replace

local upper_ages 6 8 11 14 17 19

foreach x in p m f {
	foreach y of local upper_ages {
		tempvar age0to`y'_`x'
		egen `age0to`y'_`x'' = sum(total_`x') if inrange(upper_age,6,`y'), by(state_code caste_code tru)
		egen age0to`y'_`x' = max(`age0to`y'_`x'') , by(state_code caste_code tru)
		drop `age0to`y'_`x''
	}	
}

format %16.0fc age0*
drop upper_age

drop if age_group != "Total"
drop age_group

gen district_code = 0
gen district = ""

order district_code, after(state_code)
order district , after(state)

*************************************************************************************************************************
* 4. append state and district data  
*************************************************************************************************************************

append using `dist_data'

label define TRU 1 "Total" 2 "Rural" 3 "Urban"
tempvar tru
encode tru , gen(`tru') label(TRU)

sort state_code district_code caste_code `tru'

rename caste_name caste

compress

save "../08_temp/census2011_st_edu_data", replace


*************************************************************************************************************************
* 5. create a small dataset of state-level populations of all tribes  
*************************************************************************************************************************

use "../08_temp/census2011_st_edu_data", clear

keep if district_code == 0
drop if caste_code == 500
keep if tru == "Total"

keep state_code state caste_code caste total_p

save "../08_temp/st_2011_state_pops", replace



project , creates("../08_temp/census2011_st_edu_data.dta")
project , creates("../08_temp/st_2011_state_pops.dta")
