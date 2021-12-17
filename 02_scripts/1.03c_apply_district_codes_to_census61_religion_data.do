

local parentfile_1961_2011 "../01_data/census_boundaries_data/District Boundary Changes 1961-2011.xlsx"

project , original("`parentfile_1961_2011'")
project , uses("../08_temp/census1961_st_religion_data.dta")
project , uses("../08_temp/census1961_agg_religion_data_distcoded.dta")

************************************************************************************************************************
* 1. import list of 1961 states and districts with codes 
************************************************************************************************************************

	import excel using "`parentfile_1961_2011'", sheet("census1961") firstrow case(lower) clear	
	rename *1961 *_1961
	
	tempfile census_1961
	save `census_1961'

************************************************************************************************************************
* 2. fix states and districts in 1961 ST education data, and give them location codes 
************************************************************************************************************************
	
	use "../08_temp/census1961_st_religion_data.dta", clear
  

	replace district = subinstr(district,"Sub Division","Sub-Division",1) if state == "Tripura"
	
	rename state state_1961
	rename district district_1961
	
	drop if strpos(district_1961," Division")>0
	
	replace district_1961 = "Imphal East" if district_1961 == "Imphal Town part of Imphal East"
	replace district_1961 = "Imphal West" if district_1961 == "Imphal Town part of Imphal West"
	

	* there is no point keeping those areas of Andamans, Lakshadweep, Tripura and Manipur that are not "districts" in our district-boundaries data
	drop if district_1961~= "Andaman & Nicobar Islands" & state_1961 == "Andaman & Nicobar Islands"
	drop if district_1961~= "Tripura" & state_1961 == "Tripura"
	drop if inlist(district_1961,"Imphal Town") & state_1961 == "Manipur"
	drop if inlist(district_1961,"Mao","Sadar Hills") & state_1961 == "Manipur"
	drop if district_1961 ~= "Laccadive, Minicoy and Amindivi Islands" & state_1961 == "Laccadive, Minicoy and Amindivi Islands"
	

	* for A&N, Tripura, Dadra & Nagar Haveli, Lakshadweep we need to create a new "district" [same as the state]
	expand 2 if inlist(state_1961,"Andaman & Nicobar Islands", "Tripura", "Dadra and Nagar Haveli", "Laccadive, Minicoy and Amindivi Islands"), gen(dist_obs)
	replace district_1961 = district_1961 + " District" if dist_obs
	replace dcode = dcode + 1 if dist_obs	
	drop dist_obs  
	
	* religion files had a dcode variable originally, checking its validity
	
	merge m:1 state_1961 district_1961 using `census_1961', assert(match using)

	assert inlist(state_1961,"Delhi","Goa, Daman and Diu", "Jammu & Kashmir", "North East Frontier Agency", ///
					"Pondicherry", "Punjab", "Sikkim", "Uttar Pradesh") | ///
					inlist(district_1961,"Akola","Bhandara","Buldhana","Nagpur","Wardha","Damoh","Sagar") ///
					if _merge == 2 
					
	* these were areas where either STs were not delimited in 1961, or the full census was not conducted, or no STs were present in 1961
	
	keep if _merge == 3
	
	assert dcode == dcode_1961 if state_1961 != "Manipur"
	drop  _merge dcode is_not_division sort_order
		
	order dcode_1961 division_code sub_division_code island_code state_1961 district_1961 area_1961 pop_1961 tribe_code tribe area
	drop if area == "total" //MP irrelevant

	compress

	save "../08_temp/census1961_st_religion_distcoded", replace
	
************************************************************************************************************************
* 3. merging in the agg religion data 
************************************************************************************************************************
	
	use "../08_temp/census1961_st_religion_distcoded", clear
	
	** generating urban observations for districts with 0 urban popn to facilitate merge with agg data 
	
	expand 2 if inlist(dcode_1961,601109,601322,601337,601415,601418,602000,602700,602701), gen(dist_obs) //these district have no urban obs as populations are zero 
	replace area = "urban" if dist_obs	
	
	foreach var of varlist total_p-indefinite_belief_f {
		replace `var' = 0 if dist_obs
	}
	
	drop dist_obs
	
	merge m:1 dcode_1961 area using "../08_temp/census1961_agg_religion_data_distcoded.dta", assert(match)
		
	
	drop _merge
	
	save "../08_temp/census1961_st_agg_religion_distcoded", replace


	
	project , creates("../08_temp/census1961_st_religion_distcoded.dta")
	project , creates("../08_temp/census1961_st_agg_religion_distcoded.dta")
	
