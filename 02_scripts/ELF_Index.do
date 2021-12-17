
*************************************************************************************************************************************  
	** Small Program to compute ELF index 
	** Logic: since we have multiple datasets this program accounts for wide/long form 
	** varlist contains the popn fractions of the various groups
	** we generate sq values of those fractions and sum them over a region/state
	** subtract this from 1 to get ELF 
*************************************************************************************************************************************
	

	capture program drop ELF
	program define ELF
		syntax varlist, GENerate(name) [Type(string)] [BYvars(varlist)]
		confirm new variable `generate'
		
		if "`type'" != "long" {
			foreach var of varlist `varlist' {
			gen `var'_sq = `var'^2
			}
		egen total = rowtotal(*_sq)
		assert total <= 1
		gen `generate' = 1 - total
		drop *_sq total
		}
		if "`type'" == "long" {
			foreach var of varlist `varlist' {
			gen `var'_sq = `var'^2
			egen total_`var' = total(`var'_sq), by(`byvars')
			assert total_`var' <= 1 
			gen `generate' = 1 - total_`var'
			drop `var'_sq total_`var'
		}
		}
	end
	
*************************************************************************************************************************************  
	** Region ELF values
*************************************************************************************************************************************
	
	
	 use "../03_processed/lang_workfile.dta", clear
	 drop if castegroup_1961_2011_code == 500 

	 egen total_st_popn_2011 = total(total_p_2011), by(region6113 regionname6113)
	 gen tribe_popn_2011 = total_p_2011/total_st_popn_2011

	 
	 ELF tribe_popn_2011, gen(st_index_2011) type(long) by(region6113 regionname6113)
	 keep regionname6113 st_index_2011
	 duplicates drop 
	 tempfile st_index
	 save `st_index'
	 
	 use "../03_processed/census_1961_mothertongue_for_analysis_distance.dta", clear
	 drop if mothertongue == "all mother tongues"
	 drop if castegroup_1961_2011_code == 500 
	 
	 
	 egen total_speakers_p = rowtotal(total_speakers_m total_speakers_f)
	 egen total_st_popn_1961 = total(total_speakers_p), by(region6113 regionname6113)
	 egen lang_popn_1961 = total(total_speakers_p), by(mothertongue region6113 regionname6113)
	 gen language_popn_1961 = lang_popn_1961/total_st_popn_1961 
	 keep region6113 regionname6113 mothertongue lang_popn_1961 language_popn_1961
	 duplicates drop
	 
	 ELF language_popn_1961, gen(lang_index_1961) type(long) by(region6113 regionname6113)
	 keep regionname6113 lang_index_1961
	 duplicates drop 
	 tempfile lang_index_1961
	 save `lang_index_1961'
	 
	 
	 import excel "../04_results/03_excel_tables/region_table.xls", sheet("Sheet1") firstrow clear

	foreach var of varlist popn_share_st_totpopn popn_share_sc popn_share_nonscst agg_* {
		replace `var' = `var'/100
}
	 
	 
	ELF popn_share_st_totpopn popn_share_sc popn_share_nonscst, gen(group_index_2011)
	ELF agg_*, gen(religion_index_1961)
	
	 
	merge m:1 regionname6113 using `st_index' , keep(match) nogen
	merge m:1 regionname6113 using `lang_index_1961', keep(match) nogen
	 
	gsort -national_tribe_perc -region_tribe_perc  
	format *_index_* %5.2f

	 
	foreach var of varlist popn_share_st_totpopn popn_share_sc popn_share_nonscst agg_* {
		replace `var' = `var'*100
}
	export excel using "../04_results/03_excel_tables/region_table_ELF.xls", firstrow(variables) replace


*************************************************************************************************************************************  
	** State ELF values
*************************************************************************************************************************************

	 
	 
	use "../03_processed/lang_workfile.dta", clear
	drop if castegroup_1961_2011_code == 500 

	gen state_2011 = state_1961
	replace state_2011 = "Jharkhand" if state_1961 == "Bihar" & inlist(regionname6113,"Santal Parganas","Palamau","Dhanbad, Hazaribagh","Ranchi","Singhbhum")
	replace state_2011 = "Chhattisgarh" if state_1961 == "Madhya Pradesh" & inlist(regionname6113,"Surguja","Bilaspur, Durg","Raigarh","Raipur","Bastar")
	replace state_2011 = "Meghalaya" if state_1961 == "Assam"  & inlist(regionname6113,"Garo Hills","United Khasi And Jaintia Hills")
	replace state_2011 = "Mizoram" if state_1961 == "Assam" & inlist(regionname6113,"Mizo Hills")
	replace state_2011 = "Tamil Nadu" if state_1961 == "Madras"
	replace state_2011 = "Karnataka" if state_1961 == "Mysore"
	replace state_2011 = "Odisha" if state_1961 == "Orissa"
	replace state_2011 = "Dadra & Nagar Haveli" if state_1961 == "Dadra and Nagar Haveli"
	replace state_2011 = "Lakshadweep" if state_1961 == "Laccadive, Minicoy and Amindivi Islands"

	
	egen total_st_popn_2011 = total(total_p_2011), by(state_2011)
	gen tribe_popn_2011 = total_p_2011/total_st_popn_2011

	 
	ELF tribe_popn_2011, gen(st_index_2011) type(long) by(state_2011)
	keep state_2011 st_index_2011
	duplicates drop 
	tempfile st_index_state
	save `st_index_state'
	
	
	
	 use "../03_processed/census_1961_mothertongue_for_analysis_distance.dta", clear
	 drop if mothertongue == "all mother tongues"
	 drop if castegroup_1961_2011_code == 500 
	 
	 gen state_2011 = state_1961
	replace state_2011 = "Jharkhand" if state_1961 == "Bihar" & inlist(regionname6113,"Santal Parganas","Palamau","Dhanbad, Hazaribagh","Ranchi","Singhbhum")
	replace state_2011 = "Chhattisgarh" if state_1961 == "Madhya Pradesh" & inlist(regionname6113,"Surguja","Bilaspur, Durg","Raigarh","Raipur","Bastar")
	replace state_2011 = "Meghalaya" if state_1961 == "Assam"  & inlist(regionname6113,"Garo Hills","United Khasi And Jaintia Hills")
	replace state_2011 = "Mizoram" if state_1961 == "Assam" & inlist(regionname6113,"Mizo Hills")
	replace state_2011 = "Tamil Nadu" if state_1961 == "Madras"
	replace state_2011 = "Karnataka" if state_1961 == "Mysore"
	replace state_2011 = "Odisha" if state_1961 == "Orissa"
	replace state_2011 = "Dadra & Nagar Haveli" if state_1961 == "Dadra and Nagar Haveli"
	replace state_2011 = "Lakshadweep" if state_1961 == "Laccadive, Minicoy and Amindivi Islands"

	 
	 
	 egen total_speakers_p = rowtotal(total_speakers_m total_speakers_f)
	 egen total_st_popn_1961 = total(total_speakers_p), by(state_2011)
	 egen lang_popn_1961 = total(total_speakers_p), by(mothertongue state_2011)
	 gen language_popn_1961 = lang_popn_1961/total_st_popn_1961 
	 keep state_2011 mothertongue lang_popn_1961 language_popn_1961 total_st_popn_1961
	 duplicates drop
	 
	 ELF language_popn_1961, gen(lang_index_1961) type(long) by(state_2011)
	 keep state_2011 lang_index_1961
	 duplicates drop 
	 tempfile lang_index_1961_state
	 save `lang_index_1961_state'
	 
	
	 import excel "../04_results/03_excel_tables/state_table.xls", sheet("Sheet1") firstrow clear

	foreach var of varlist popn_share_st_totpopn popn_share_sc popn_share_nonscst popn_share_Buddhist popn_share_Christian popn_share_Hindu popn_share_Jain popn_share_Muslim popn_share_Other popn_share_Sikh {
		replace `var' = `var'/100
}
	 
	 
	ELF popn_share_st_totpopn popn_share_sc popn_share_nonscst, gen(group_index_2011)
	ELF popn_share_Buddhist popn_share_Christian popn_share_Hindu popn_share_Jain popn_share_Muslim popn_share_Other popn_share_Sikh, gen(religion_index_2011)
	
	 
	merge m:1 state_2011 using `st_index_state' , keep(match) nogen
	merge m:1 state_2011 using `lang_index_1961_state', keep(match) nogen
	 
	gsort -national_tribe_perc -state_tribe_perc  
	format *_index_* %5.2f

	 
	foreach var of varlist popn_share_st_totpopn popn_share_sc popn_share_nonscst popn_share_Buddhist popn_share_Christian popn_share_Hindu popn_share_Jain popn_share_Muslim popn_share_Other popn_share_Sikh {
		replace `var' = `var'*100
}
	export excel using "../04_results/03_excel_tables/state_table_ELF.xls", firstrow(variables) replace

	
	
	
	
	 
