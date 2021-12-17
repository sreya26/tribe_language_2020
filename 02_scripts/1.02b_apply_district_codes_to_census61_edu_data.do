************************************************************************************************************************
* this file takes the ST education data for individual tribe levels from Census 1961
* and gives them district and caste [group] codes 
************************************************************************************************************************

local parentfile_1961_2011 "../01_data/census_boundaries_data/District Boundary Changes 1961-2011.xlsx"

project , original("`parentfile_1961_2011'")
project , uses("../08_temp/census1961_st_edu_data.dta")


************************************************************************************************************************
* 1. import list of 1961 states and districts with codes 
************************************************************************************************************************

	import excel using "`parentfile_1961_2011'", sheet("census1961") firstrow case(lower) clear	
	rename *1961 *_1961
	
	tempfile census_1961
	save `census_1961'
	
************************************************************************************************************************
* 2. fix states and districts in 1961 ST education data, and give them codes 
************************************************************************************************************************
	
	use "../08_temp/census1961_st_edu_data.dta", clear

	replace district = "Manipur" if district == "Imphal Town" // fixing urban tables of Manipur
	replace district = "Imphal East" if district == "Imphal Town Part Of Imphal East"
	replace district = "Imphal West" if district == "Imphal Town Part Of Imphal West"


	replace district = subinstr(district,"Sub Division","Sub-Division",1) if state == "Tripura"

	rename state state_1961
	rename district district_1961

	drop if strpos(district_1961," Division")>0

	* there is no point keeping those areas of Andamans, Lakshadweep, Tripura and Manipur that are not "districts" in our district-boundaries data
	drop if district_1961~= "Andaman & Nicobar Islands" & state_1961 == "Andaman & Nicobar Islands"
	drop if district_1961~= "Tripura" & state_1961 == "Tripura"
	drop if inlist(district_1961,"Mao","Sadar Hills") & state_1961 == "Manipur"
	drop if island ~= "all" & state_1961 == "Laccadive, Minicoy and Amindivi Islands"
	drop island

	* for A&N, Tripura, Dadra & Nagar Haveli, Lakshadweep we need to create a new "district" [same as the state]
	expand 2 if inlist(state_1961,"Andaman & Nicobar Islands", "Tripura", "Dadra and Nagar Haveli", "Laccadive, Minicoy and Amindivi Islands"), gen(dist_obs)
	replace district_1961 = district_1961 + " District" if dist_obs
	replace dcode = dcode + 1 if dist_obs
	drop dist_obs  

	replace district_1961 = subinstr(district_1961,"Lakshadweep","Laccadive, Minicoy and Amindivi Islands",1)
	expand 2 if strpos(state_1961,"Laccadive"), gen(lacca_obs)
	replace tribe = "all scheduled tribes" if lacca_obs
	replace tribe_code = 196132500 if lacca_obs
	drop lacca_obs
	
	merge m:1 state_1961 district_1961 using `census_1961', assert(match using)

	assert inlist(state_1961,"Delhi","Goa, Daman and Diu", "Jammu & Kashmir", "North East Frontier Agency", ///
					"Pondicherry", "Punjab", "Sikkim", "Uttar Pradesh") | ///
					inlist(district_1961,"Akola","Bhandara","Buldhana","Nagpur","Wardha","Damoh","Sagar") ///
					if _merge == 2 
	
	* these were areas where either STs were not delimited in 1961, or the full census was not conducted, or no STs were present in 1961	
	keep if _merge == 3
	assert dcode == dcode_1961
	drop _merge dcode is_not_division sort_order
		
	order dcode_1961 division_code sub_division_code island_code state_1961 district_1961 area_1961 pop_1961 tribe_code tribe area
		
	label var area_1961 "Area (rural + urban)"
	label var pop_1961 "Total Population (rural + urban)"
	
	compress

	save "../08_temp/census1961_st_edu_distcoded", replace

project , creates("../08_temp/census1961_st_edu_distcoded.dta")
