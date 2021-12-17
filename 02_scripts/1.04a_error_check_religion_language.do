
project, uses("../08_temp/census1961_st_religion_data.dta")
project, uses("../08_temp/census1961_st_mothertongue.dta")
project, uses("../08_temp/census1961_st_mothertongue_distcoded.dta")
	
	
	*************************************************************************************************************************
	* ERROR CHECKS FOR RELIGION DATA 
	*************************************************************************************************************************
	
	*************************************************************************************************************************
	* for religion data: 
	* 1. to check gender wise row totals 
	* 2. to check whether districts within a division sum up to the figures stated for the division 
	*************************************************************************************************************************
	
	use "../08_temp/census1961_st_religion_data.dta", clear
	
	*************************************************************************************************************************
	** gender-wise row totals 
	*************************************************************************************************************************
	
	local gender f m 
	
	foreach x of local gender {
		ds *_`x'
		local vars `r(varlist)'
		local exclude total_`x'
		local vars: list vars - exclude
		egen double tot_`x' = rowtotal(`vars')
		assert tot_`x' == total_`x'
	}
	
	*************************************************************************************************************************
	** ensuring that total_m + total_f = total_p
	*************************************************************************************************************************
	
	egen tot_p = rowtotal(total_m total_f)
	assert total_p == tot_p
	
	*************************************************************************************************************************	
	** check for districts within a division
	*************************************************************************************************************************
	
	keep if division_code > 0 & !missing(division_code)
	
	gen byte weight_div = 1 if strpos(district,"Division")>0
	replace weight_div = -1 if missing(weight_div)
	
	foreach var of varlist *_m *_f {
		egen `var'_error = total(`var'*weight_div), by (state division_code tribe area)
		assert `var'_error == 0
	}
	
	
	*************************************************************************************************************************
	* ERROR CHECKS FOR LANGUAGE DATA
	*************************************************************************************************************************

	*************************************************************************************************************************
	* gender-wise totals for sl speakers (districts and divisions)
	*************************************************************************************************************************
	
	use	"../08_temp/census1961_st_mothertongue.dta",clear
	
	foreach x in m f {
		replace subsidiary_speakers_total_`x' = 0 if missing(subsidiary_speakers_total_`x')
		egen subsidiary_total_`x' = rowtotal(sl_*_`x')
		gen subsidiary_error_`x' = subsidiary_total_`x' - subsidiary_speakers_total_`x'
	}
	
	tempfile mothertongue_data
	save `mothertongue_data'
	
	assert subsidiary_error_m == 0 
	assert subsidiary_error_f ==0 
	
	
	*************************************************************************************************************************
	* check to see whether districts within a division sum up to the division obs
	*************************************************************************************************************************
	
	
	keep if division_code > 0 & !missing(division_code) | sub_division_code > 0 & !missing(sub_division_code)
	
	rename sl_ceylonesesimelusinghalese_m sl_ceylonese_m //renaming some sl languages to generate valid error names othw strings are too long
	rename sl_ceylonesesimelusinghalese_f sl_ceylonese_f
	
	rename sl_nagpuri_eastern_magahi_m sl_nagpuri_m
	rename sl_nagpuri_eastern_magahi_f sl_nagpuri_f
	
	gen byte weight_div = 1 if strpos(district,"Division")>0 & state != "Tripura"
	replace weight_div = -1 if strpos(district,"Division") == 0 & !inlist(state,"Tripura","Manipur") //Manipur and Tripur have no divisions 
	
	egen error_division_m = total(total_speakers_m*weight_div), by (state division_code tribe mothertongue)
	egen error_division_f = total(total_speakers_f*weight_div), by (state division_code tribe mothertongue)
	
	egen error_division_sub_m = total(subsidiary_speakers_total_m*weight_div), by (state division_code tribe mothertongue)
	egen error_division_sub_f = total(subsidiary_speakers_total_f*weight_div), by (state division_code tribe mothertongue)

	assert error_division_m == 0 
	assert error_division_f == 0 
	assert error_division_sub_m == 0 
	assert error_division_sub_f == 0 
	
	*************************************************************************************************************************
	** Checks for sub-divisions
	** For Manipur: Mao and Sadar Hills figures should sum to those stated for Mao & Sadar Hills
	** Tripura only has sub-divisions, these figures should sum to those stated for State level obs
	*************************************************************************************************************************
	
	gen byte weight_sub = 1 if district == "Mao & Sadar Hills" | district == "Tripura"
	replace weight_sub = -1 if district == "Mao" | district == "Sadar Hills" | strpos(tribe,"Sub-Division")>0  
	
	
	egen error_sub_m = total(total_speakers_m*weight_sub), by (state sub_division_code tribe mothertongue)
	egen error_sub_f = total(total_speakers_f*weight_sub), by (state sub_division_code tribe mothertongue)
	
	egen error_subdiv_sub_m = total(subsidiary_speakers_total_m*weight_sub), by (state sub_division_code tribe mothertongue)
	egen error_subdiv_sub_f = total(subsidiary_speakers_total_f*weight_sub), by (state sub_division_code tribe mothertongue)
	
	assert error_sub_m == 0
	assert error_sub_f == 0
	
	assert error_subdiv_sub_m == 0
	assert error_subdiv_sub_m == 0
	
	foreach var of varlist sl_* {
		egen `var'_sub = total(`var'*weight_sub) , by(state sub_division_code tribe mothertongue)
		assert `var'_sub == 0
		
	}
	
	drop *_sub
	
	*************************************************************************************************************************
	** additional check for whether all sl speakers in a division is the sum of its constituent district figures
	*************************************************************************************************************************
	
	drop if state == "Manipur" | state == "Tripura" // dropping manipur and tripura since they only have sub-divisions
	

	foreach var of varlist sl_* {
		egen `var'_error = total(`var'*weight_div) , by(state division_code tribe mothertongue)
		assert `var'_error == 0
	}

	
	**********************************************************************************************************************************************
	* Some states give us total mother tongue information in the tables, checking if sum of individual mother tongues for each tribe sums to this
	**********************************************************************************************************************************************
	
	use `mothertongue_data' , clear 
	
	gen byte weight = 1 if mothertongue == "total" | mothertongue == "all mother tongues"
	replace weight = -1 if missing(weight)
	
	
	egen error_m = total(total_speakers_m*weight) , by(state district tribe)
	egen error_f = total(total_speakers_f*weight) , by(state district tribe)
	
	keep if inlist(state, "West Bengal", "Tripura","Rajasthan", "Maharashtra","Himachal Pradesh")
	
	drop if tribe != "all scheduled tribes" & inlist(state,"Tripura","Rajasthan")
	
	keep state district tribe mothertongue total_speakers_m total_speakers_f error_m error_f
	drop if strpos(tribe,"aggregate")>0
	
	drop if tribe == "all scheduled tribes" & state == "West Bengal" //useless for us since we don't have language-wise information for "all scheduled tribes"
	drop if tribe == "all scheduled tribes" & state == "Himachal Pradesh" //useless for us since we don't have language-wise information for "all scheduled tribes"
	
	assert error_m == 0
	assert error_f == 0
	
	
	*************************************************************************************************************************
	* checks to ensure that gender-wise total popn figures match across religion and mother-tongue data
	*************************************************************************************************************************
	use `mothertongue_data', clear
	
	foreach var of varlist total_speakers_m-total_speakers_f {
		replace `var' = 0 if missing(`var')
	}
	
	drop if strpos(tribe,"aggregate")>0 
	replace district = subinstr(district,"Island","Islands",1) if state == "Andaman & Nicobar Islands" & district != "Andaman & Nicobar Islands"
	replace district = "Bilas Division" if district == "Bilaspur Division" & state == "Madhya Pradesh"

	
	drop if mothertongue == "total" | mothertongue == "all mother tongues" //to account for double counting
	drop if total_speakers_m == 0 & total_speakers_f == 0
	
	
	collapse (sum) total_speakers_m total_speakers_f, by(state district tribe)
	rename total_speakers_? total_speakers?_lang
	
		
	tempfile mothertongue
	save `mothertongue'
	
	*************************************************************************************************************************
	* preparing religion data 
	*************************************************************************************************************************
	
	use "../08_temp/census1961_st_religion_data.dta", clear
	drop if strpos(tribe,"aggregate") > 0 
	
	drop if district == "Imphal Town" //this is redundant we already have Manipur urban obs
	
	replace district = strrtrim(district)
	drop if area == "total" //mp has urban rural and total area
	
	replace district = "Imphal West" if district == "Imphal Town part of Imphal West"
	replace district = "Imphal East" if district == "Imphal Town part of Imphal East"
	replace district = proper(district) if state == "Laccadive, Minicoy and Amindivi Islands" & state != district 
	drop if tribe == "all scheduled tribes"  & state == "Laccadive, Minicoy and Amindivi Islands"
	
	collapse (sum) total_m total_f, by(state district tribe)
	
	keep state district tribe total_m total_f
	
	merge 1:1 state district tribe using `mothertongue', assert(match master)
	
	**unmatched are all scheduled tribes obs only from religion data since we do not have this reported consistently in the mother tongue data
	
	assert tribe == "all scheduled tribes" if _merge == 1
	keep if _merge == 3
	
	drop if tribe == "all scheduled tribes" & state == "Gujarat" //Gujarat does not consistently report numbers for all scheduled tribes, missing for when only one tribe is listed for the mothertongue
	
	
	assert total_m == total_speakersm_lang
	assert total_f == total_speakersf_lang

	*************************************************************************************************************************
	* checks for district totals summing to the state level figures
	*************************************************************************************************************************
	
	use "../08_temp/census1961_st_mothertongue_distcoded.dta", clear

	gen is_state = mod(dcode_1961,100) 
	
	drop if strpos(tribe,"aggregate")>0
	drop if tribe == "all scheduled tribes" & state_1961 == "Manipur" //manipur all scheduled tribe total mother tongue data only at state level 
		

	*** district totals of total speakers summing up to the state level
	
	gen byte weight = 1 if is_state == 0
	replace weight = -1 if missing(weight)

	egen error_totalm = total(total_speakers_m*weight) , by(state_1961 tribe)
	egen error_totalf = total(total_speakers_f*weight) , by(state_1961 tribe)

	assert error_totalm == 0  
	assert error_totalf == 0
	
	*************************************************************************************************************************
	* checks for whether subsidiary tot_popn sums to state 
	*************************************************************************************************************************
	
	egen error_total_subsidiary_m = total(subsidiary_speakers_total_m*weight) , by(state_1961 tribe)
	egen error_total_subsidiary_f = total(subsidiary_speakers_total_f*weight) , by(state_1961 tribe)
	
	assert error_total_subsidiary_m == 0 if state_1961 != "Orissa" // Orissa has missing obs for speakers of sl languages who constitute less than 1% of population
	assert error_total_subsidiary_f == 0 if state_1961 != "Orissa"
	
	
	drop if state_1961 == "Orissa" //not retaining Orissa for checks for each sl language 
	
	rename sl_ceylonesesimelusinghalese_m sl_ceylonese_m //renaming some sl languages to generate valid error names
	rename sl_ceylonesesimelusinghalese_f sl_ceylonese_f
	
	rename sl_nagpuri_eastern_magahi_m sl_nagpuri_m
	rename sl_nagpuri_eastern_magahi_f sl_nagpuri_f

	foreach var of varlist sl_* {
		egen `var'_error = total(`var'*weight) , by(state_1961 tribe)
		assert `var'_error == 0
	}
	
	

	

	

	
	
	
	
		
	
	
	
	
	
	