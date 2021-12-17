******************************************************************************************************************************************
* this file brings back the statecode and castecode variables into the tribe groups list from 2011
* it then adds the district codes from 2011
* this is used to merge the data with tribe-level education outcomes from Census 2011
* the data is then collapsed to the level of a tribal group in a district
* finally, we collapse our data to Census 1961 regions (regions with consistent boundaries between 1961 and 2013).
******************************************************************************************************************************************

project , uses("../08_temp/st_groups_merged_1961_2011.dta")
project , uses("../08_temp/census2011_st_edu_data.dta")
project , original("../01_data/census_2011_pca_data/DDW_PCA0000_2011_Indiastatedist.xlsx")
project , uses("../03_processed/regions6113_with_dists_2011.dta")

project , original("1.A_create_1961_statevar.do")

run "1.A_create_1961_statevar.do"

******************************************************************************************************
* 1. Merge back tribe group codes created in step #3 of the overall process
******************************************************************************************************

	use "../08_temp/st_groups_merged_1961_2011", clear
	keep if year == 2011
	
	keep state_code caste_code castegroup_1961_2011_code castegroup_1961_2011

	tempfile codes
	save `codes'

	use "../08_temp/census2011_st_edu_data", clear
	gen double dcode_2011 = 201100000 + state_code*1000 + district_code
	format dcode_2011 %9.0f
	order dcode_2011, after(district_code)
	
	merge m:1 state_code caste_code using `codes', assert(master match)
	
	assert caste_code == 500 | caste_code > 505000 if _merge == 1 // All STs or the individual Naga tribes in Nagaland
	drop _merge

	replace castegroup_1961_2011_code = caste_code if caste_code == 500
	replace castegroup_1961_2011 = "All Scheduled Tribes" if caste_code == 500
	
	sort state_code district_code caste_code tru
	
	tempfile temp
	save `temp'
	

******************************************************************************************************
* 2. Import overall population numbers from the Census 2011 PCA
******************************************************************************************************

	import excel using "../01_data/census_2011_pca_data/DDW_PCA0000_2011_Indiastatedist.xlsx", firstrow case(lower) clear

	keep state district level name tru tot_p
	drop if level == "India"

	destring state district, replace

	rename state state_code
	rename district district_code
	rename tot_p overallpop_2011

	sort state_code district_code tru
	
	tempfile censuspops
	save `censuspops'

	use `temp', clear
	merge m:1 state_code district_code tru using `censuspops', assert(match using) keep(match) keepusing(overallpop_2011) nogen
	* there are a bunch of areas where STs are not delimited; those will be in the using dataset and can be discarded
	
	drop if caste_code > 505000 // drop individual Naga tribes in Nagaland

	order dcode_2011 caste_code castegroup_1961_2011_code
	sort dcode_2011 caste_code castegroup_1961_2011_code tru

******************************************************************************************************
* 4. Collapse to caste group and consistent region level
******************************************************************************************************
	
	collapse (sum) total_p-age0to19_f (max) overallpop_2011, by(dcode_2011 state district castegroup_1961_2011_code tru) // collapse to caste groups
	
	merge m:1 dcode_2011 using "../03_processed/regions6113_with_dists_2011", keepusing(region6113 regionname6113) assert(match using)
	
	gen stcode_2011 = floor(dcode_2011/1000) - 201100

	create_1961_statevar stcode_2011 , gen(state_1961)
	order state_1961
		
	assert inlist(state_1961,"Delhi","Punjab","Pondicherry") if _merge == 2
	* _merge == 2 for Punjab, Delhi and Pondicherry, areas where there are no STs [not a problem]
	keep if _merge == 3
	drop _merge

	replace state_1961 = "Himachal Pradesh" if state_1961 == "Punjab"
	
	replace overallpop_2011 = 0 if ~(tru == "Total" & castegroup_1961_2011_code == 500) // to enable proper summing over dcode's in the following collapse

	drop if inlist(stcode_2011,5,9) // drop uttar pradesh and uttarakhand
	replace regionname6113 = "Himachal Pradesh" if strpos(regionname6113,"Himachal")
	 
	collapse (sum) total_p-age0to19_f overallpop_2011, by(state_1961 region6113 regionname6113 castegroup_1961_2011_code tru)
	
	tempvar overallpop
	egen double `overallpop' = max(overallpop_2011), by(state_1961 region6113 regionname6113) 
	replace overallpop_2011 = `overallpop'

******************************************************************************************************
* 5. Save dataset
******************************************************************************************************
	
	sort state_1961 region6113 castegroup_1961_2011_code tru
	order state_1961 regionname6113 castegroup_1961_2011_code tru

	rename (total_p-age0to19_f) =_2011
	compress
	
	save "../08_temp/census_2011_st_education_in_1961_regions", replace

	
project , creates("../08_temp/census_2011_st_education_in_1961_regions.dta")
