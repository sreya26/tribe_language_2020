*************************************************************************************************************************
* this file takes the census1961 mothertongue data and codes its districts
* districts are coded as per census60.csv
*************************************************************************************************************************

project , original("../01_data/census_boundaries_data/District Boundary Changes 1961-2011.xlsx")
project , uses("../08_temp/census1961_st_mothertongue.dta")


import excel using "../01_data/census_boundaries_data/District Boundary Changes 1961-2011.xlsx", sheet("census1961") firstrow case(lower) clear



rename *1961 *_1961

tempfile census61
save `census61'

************************************************************************************************************************
* 2. fix states and districts in 1961 ST language data, and give them codes 
************************************************************************************************************************

use "../08_temp/census1961_st_mothertongue", clear

drop if strpos(district," Division")>0


rename state state_1961
rename district district_1961

* there is no point keeping those areas of Andamans, Laccadives, Tripura and Manipur that are not "districts" in our district-boundaries data
drop if district_1961 ~= "Andaman & Nicobar Islands" & state_1961 == "Andaman & Nicobar Islands"
drop if district_1961 ~= "Tripura" & state_1961 == "Tripura"
drop if inlist(district_1961,"Mao","Sadar Hills") & state_1961 == "Manipur"
drop if district_1961 ~= "Laccadive, Minicoy and Amindivi Islands" & state_1961 == "Laccadive, Minicoy and Amindivi Islands"

* for A&N,Tripura, Dadra Nagar Haveli and Laccadives we need to create a new "district" [same as the state]
expand 2 if inlist(state_1961,"Andaman & Nicobar Islands","Tripura","Laccadive, Minicoy and Amindivi Islands","Dadra and Nagar Haveli"), gen(dist_obs)
replace district_1961 = district_1961 + " District" if dist_obs
replace dcode = dcode + 1 if dist_obs
drop dist_obs  

* for Laccadives we need to create another set of observations with "all scheduled tribes" as the tribe
expand 2 if state_1961 == "Laccadive, Minicoy and Amindivi Islands", gen(lacca_obs)
replace tribe = "all scheduled tribes" if lacca_obs
replace tribe_code = 196132500 if lacca_obs
drop lacca_obs

merge m:1 state_1961 district_1961 using `census61', assert(match using) keep(match)


* in some states, there were no STs delimited in 1961: Delhi, J&K, Pondicherry, Sikkim, UP
* in Punjab, no STs were delimited outside of the hilly parts that later went to HP
* in Goa, no info was collected on SCs and STs in 1961
* we have found no SC/ST volume for NEFA [Arunachal Pradesh] in 1961

drop if _merge~=3
assert dcode == dcode_1961
drop _merge dcode is_not_division sort_code

order dcode_1961 state_1961 district_1961 area_1961 pop_1961
compress

save "../08_temp/census1961_st_mothertongue_distcoded", replace

project , creates("../08_temp/census1961_st_mothertongue_distcoded.dta")
 
