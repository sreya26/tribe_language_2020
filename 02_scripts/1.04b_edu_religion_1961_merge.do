	
project, uses("../08_temp/census1961_st_edu_data.dta")
project, uses("../08_temp/census1961_st_edu_distcoded.dta")
project, uses("../08_temp/census1961_st_religion_data.dta")
project, uses("../08_temp/census1961_st_agg_religion_distcoded.dta")

	******************************************************************************************************
	* SECTION I : error checks of 1961 education data before attempting merge with religion file 
	******************************************************************************************************
	
	******************************************************************************************************
	* Gender wise totals 
	******************************************************************************************************
	
	use "../08_temp/census1961_st_edu_data.dta", clear
	
	local gender f m 
	
	
	foreach x of local gender {
		ds *`x'
		local vars `r(varlist)'
		local exclude total`x'
		local vars: list vars - exclude
		egen double tot`x' = rowtotal(`vars')
		assert tot`x' == total`x'
	}
	
	* checks out
	
	******************************************************************************************************
	* Changes in string name as applied in 1.10b 
	******************************************************************************************************

	

	replace district = "Manipur" if district == "Imphal Town" // fixing urban tables of Manipur
	replace district = "Imphal East" if district == "Imphal Town Part Of Imphal East"
	replace district = "Imphal West" if district == "Imphal Town Part Of Imphal West"

	replace district = subinstr(district,"Sub Division","Sub-Division",1) if state == "Tripura"

	drop if strpos(tribe,"aggregate")>0

	******************************************************************************************************
	* Checking whether sum of individual tribes sum to all scheduled tribes total 
	******************************************************************************************************

	tempfile master
	save `master'
	
	gen byte weight = 1 if strpos(tribe,"all scheduled tribes")>0
	replace weight = -1 if missing(weight)
	
	foreach var of varlist totalm-matricf  {
		egen `var'_error = total(`var'*weight), by (state district area)
		assert `var'_error == 0 if !inlist(state,"Himachal Pradesh", "Manipur", "Laccadive, Minicoy and Amindivi Islands" )
		// these states do not include all scheduled tribes obs 
	}
	
	*************************************************************************************************************************
	* check to see whether districts within a division sum up to the division obs
	*************************************************************************************************************************
	
	keep if division_code > 0 & !missing(division_code) | sub_division_code > 0 & !missing(sub_division_code)

	
	gen byte weight_div = 1 if strpos(district,"Division")>0
	replace weight_div = -1 if missing(weight_div)
	
	foreach var of varlist totalm-matricf {
		egen `var'_error_div = total(`var'*weight_div), by (state division_code tribe area)
		assert `var'_error_div == 0 if state != "Manipur" & state != "Tripura" //manipur and tripura only have sub divisions
	}
	
	
	*************************************************************************************************************************
	** only for manipur mao and sadar hills observations and tripura sub-divisions
	*************************************************************************************************************************
	
	keep if state == "Manipur" | state == "Tripura"
	
	gen byte weight_sub = 1 if district == "Mao & Sadar Hills" | district == "Tripura"
	replace weight_sub = -1 if district == "Mao" | district == "Sadar Hills" | strpos(tribe,"Sub-Division")>0  
	
	foreach var of varlist totalm-matricf {
		egen `var'_error_sub = total(`var'*weight_sub), by (state sub_division_code tribe area)
		assert `var'_error_sub == 0
	}
	
	* checks out

	******************************************************************************************************
	* Changes to edu dist code data as applied in 1.10b
	******************************************************************************************************

	use "../08_temp/census1961_st_edu_distcoded.dta", clear
	
	* some regions have no entry for "all scheduled tribes". we now fix this.
	preserve
		egen tribe_all = max(tribe == "all scheduled tribes"), by(dcode_1961 area)
		keep if tribe_all == 0
		assert strpos(tribe,"aggregate") == 0 
	
		collapse (sum) totalm-matricf, by(dcode_1961 state_1961 district_1961 area_1961 pop_1961 area)
		gen tribe = "all scheduled tribes"
		tempfile missing_tribe_all
		save `missing_tribe_all'
	restore

	append using `missing_tribe_all'
	drop if strpos(tribe,"aggregate")>0
	
	******************************************************************************************************
	* Checking whether district wise tribe totals sum up to their respective state values
	******************************************************************************************************
	
	gen is_state = mod(dcode_1961,100)
	replace is_state = -1 if is_state == 0
	replace is_state = 1 if is_state >0
	
	foreach var of varlist totalm-matricf {
		by state_1961 area tribe, sort: egen `var'_error = total(`var'*is_state) 
		assert `var'_error == 0
	}
	 
	* checks out

	******************************************************************************************************
	* Checking whether total m and f matches across edu and religion data 
	******************************************************************************************************
	
	******************************************************************************************************
	** preparing the education dataset 
	******************************************************************************************************
	
	use `master', clear 
	replace district = island if state == "Laccadive, Minicoy and Amindivi Islands" // the religion files retain the island names as the district names
	replace district = "Laccadive, Minicoy and Amindivi Islands" if island == "all" & state == "Laccadive, Minicoy and Amindivi Islands"
	drop island 
	
	
	** correcting discrepancies across string names for divisions 
	
	replace district = "Bilas Division" if district == "Bilaspur Division" & state == "Madhya Pradesh"
	replace district = "Chota Nagpur Division" if district == "Chotanagpur Division"
	replace district = "Dharmanagar Sub-Division" if district == "Dharamanagar Sub-Division"
	replace district = "Khowai Sub-Division" if district == "Keowai Sub-Division"
	replace district = subinstr(district,"Island","Islands",1) if state == "Andaman & Nicobar Islands" & district != "Andaman & Nicobar Islands"
	

	keep state district tribe area totalm totalf illiteratem illiteratef literatenoedm literatenoedf primarym primaryf matricm matricf
	
	tempfile edu
	save `edu'
	
	******************************************************************************************************
	** preparing the religion dataset
	******************************************************************************************************
	
	use "../08_temp/census1961_st_religion_data.dta", clear
	
	replace district = "Imphal East" if district == "Imphal Town part of Imphal East"
	replace district = "Imphal West" if district == "Imphal Town part of Imphal West"
	
	** We already retain Manipur Urban observations which correspond to those of Imphal Town, hence the latter is redundant
	drop if district == "Imphal Town"
	drop if state == "Laccadive, Minicoy and Amindivi Islands" & tribe == "all scheduled tribes" //this is only there in religion data 
		
	drop if area == "total" // retaining only rural and urban obs for MP
	
	drop if strpos(tribe,"aggregate")>0 // gets rid of the tribe groupings in Maharashtra
	
	
	******************************************************************************************************
	* SECTION II : MERGING EDUCATION AND RELIGION DATA 
	******************************************************************************************************
	
	******************************************************************************************************
	** Merging the edu and religion data 
	******************************************************************************************************
	
	merge 1:1 district tribe area using `edu'
	
	
	assert inlist(state,"Manipur","Himachal Pradesh", "Laccadive, Minicoy and Amindivi Islands") & ///
					inlist(tribe,"all scheduled tribes") ///
					if _merge == 1
					
	drop if _merge == 1
	
	assert total_m == totalm
	assert total_f == totalf
	
	
	******************************************************************************************************
	** Merging the distcoded edu and religion dataset 
	******************************************************************************************************
	
	use "../08_temp/census1961_st_edu_distcoded.dta", clear
	
	expand 2 if inlist(dcode_1961,601109,601322,601337,601415,601418,602000,602700,602701), gen(dist_obs) //these district have no urban obs as populations are zero 
	replace area = "urban" if dist_obs	
	
	foreach var of varlist totalm-matricf {
		replace `var' = 0 if dist_obs
	}
	
	drop dist_obs

	
	preserve
		egen tribe_all = max(tribe == "all scheduled tribes"), by(dcode_1961 area)
		keep if tribe_all == 0
		assert strpos(tribe,"aggregate") == 0 
		* none of the tribe aggregates are present in these areas, else we would have had to get rid of them before the collapse below
		collapse (sum) totalm-matricf, by(dcode_1961 state_1961 district_1961 area_1961 pop_1961 area)
		gen tribe = "all scheduled tribes"
		tempfile missing_tribe_all
		save `missing_tribe_all'
	restore
	

	append using `missing_tribe_all'
	
	rename totalm total_m
	rename totalf total_f 
	
	

	merge 1:1 dcode_1961 tribe area total_m total_f using "../08_temp/census1961_st_agg_religion_distcoded.dta", assert(match) 
	
	drop state district 
	replace tribe_code = 196109500 if state_1961 == "Himachal Pradesh" & tribe == "all scheduled tribes"
	replace tribe_code = 196115500 if state_1961 == "Manipur" & tribe == "all scheduled tribes"
	
	drop _merge 
	
	
	save "../08_temp/census_1961_edu_religion_merged", replace

project, creates("../08_temp/census_1961_edu_religion_merged.dta")
	
