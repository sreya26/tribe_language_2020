project , uses("../08_temp/st_groups_merged_1961_2011.dta")
project , uses("../08_temp/census1961_st_mothertongue_distcoded.dta")

******************************************************************************************************************************************
* 1. the file st_groups_with_state_1961.dta retained the state and castegroup_1961
* we now add in the castegroup_2011 variables into it
* and then finally we put in the tribe group codes into the census1961mothertongue_distcoded file
******************************************************************************************************************************************

use "../08_temp/st_groups_merged_1961_2011", clear

rename state state_1961
rename caste tribe 
keep if year == 1961 
replace tribe = lower(tribe)

replace state_1961 = "Dadra and Nagar Haveli" if state_1961 == "Dadra And Nagar Haveli"
replace state_1961 = "Laccadive, Minicoy and Amindivi Islands" if state_1961 == "Laccadive, Minicoy And Amindivi Islands"

merge 1:m state_1961 tribe using "../08_temp/census1961_st_mothertongue_distcoded"


drop if strpos(tribe,"aggregate")>0 | inlist(tribe,"keer","korama","nat, navdigar, sapera and kubutar","pulayan","vaghri","vishavan","all tribes of n.e.f.a.","all tribes of north-east frontier agency","dafla")

replace tribe = "all scheduled tribes" if tribe == "total" | strpos(tribe,"all ")>0 & !inlist(state_1961,"Assam","Nagaland")
replace castegroup_1961_2011_code = 500 if tribe == "all scheduled tribes"
replace castegroup_1961_2011 = tribe if tribe == "all scheduled tribes"
*replace castegroup_2011 = tribe if tribe == "all scheduled tribes"



assert ~missing(castegroup_1961_2011_code)
assert castegroup_1961_2011_code == 500 if _merge == 2
drop _merge

compress

******************************************************************************************************************************************
* 2. some areas have no "all scheduled tribes" entry. we fix this now.
******************************************************************************************************************************************

preserve 
	egen tribemin = min(castegroup_1961_2011_code), by(state_1961 dcode_1961)
	keep if tribemin~=500
	assert ~inlist(mothertongue,"all","total","all mother tongues")

	collapse (sum) total_speakers_m total_speakers_f subsidiary_speakers_total_m subsidiary_speakers_total_f sl_*, ///
					by(state_1961 district_1961 dcode_1961 area_1961 pop_1961)
	gen castegroup_2011_code = 500
	gen mothertongue = "all mother tongues"
	gen tribe = "all scheduled tribes"
	gen castegroup_1961_2011 = "all scheduled tribes"
	*gen castegroup_2011 = "all scheduled tribes" 

	tempfile missing_alltribes
	save `missing_alltribes'
restore

append using `missing_alltribes' 

******************************************************************************************************************************************
* 3. some areas have no "all mother tongues" entry [currently, just Laccadives]. we fix this now.
******************************************************************************************************************************************

preserve
	egen mothertongue_all = max(inlist(mothertongue,"total","all mother tongues")) , by(state_1961 dcode_1961)
	keep if mothertongue_all == 0
	collapse (sum) total_speakers_m total_speakers_f subsidiary_speakers_total_m subsidiary_speakers_total_f sl_*, ///
					by(state_1961 district_1961 dcode_1961 area_1961 pop_1961 castegroup_1961_2011_code tribe castegroup_1961_2011)
	gen mothertongue = "all mother tongues"
	tempfile missing_alltongue
	save `missing_alltongue'
restore

append using `missing_alltongue'

sort state_1961 dcode_1961 castegroup_1961_2011_code mothertongue

order state_1961 district_1961 castegroup_1961_2011_code mothertongue total_speakers*

	
drop if missing(dcode_1961) //drops all the tribes which had no population and therefore did not feature in tables

compress

save "../08_temp/census_1961_mothertongue_data_with_dist_tribe_codes", replace

project, creates("../08_temp/census_1961_mothertongue_data_with_dist_tribe_codes.dta")
