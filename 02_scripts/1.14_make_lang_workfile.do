*********************************************************************************************************************
* this do-file puts together the dataset for the tribelanguage paper
*********************************************************************************************************************

project , uses("../08_temp/census_2011_st_education_in_1961_regions.dta")
project , uses("../03_processed/census_1961_mothertongue_for_analysis_distance.dta")
project , uses("../08_temp/census1961_st_edu_religion_with_dist_tribe_codes.dta")
project , uses("../08_temp/scheduled_and_tribal_regions.dta")

*********************************************************************************************************************
* various methods of calculating distance between two given languages: 
* (a) TJ: counting the number of nodes that we need to traverse to get from one language to the other (see the Tarun Jain (2017) Common Tongue paper)
* (b) F: The Fearon (2003) measure, using m = 15 and alpha = 0.5
* (c) F8: The Fearon (2003) measure, using m = 8 and alpha = 0.5  
* (d) AP: 1 - Proximity as defined in Adsera & Pytlikova (2015)
* (e) DOW: The Fearon (2003) measure, using m = 8 and alpha = 0.05; see Desmet, Ortuno-Ortin and Weber (2009)
* (f) AS: the LDND measure of Bakker et al (2009) using ASJP database 
* (g) L : Laitin (2000)'s r measure given in his footnote 7

local dist_types tj as ap l f f8 dow
*********************************************************************************************************************


*********************************************************************************************************************
* 1. prepare the education outcomes data for census 2011 
*********************************************************************************************************************

	use "../08_temp/census_2011_st_education_in_1961_regions", clear

	capture drop __*
	
	distinct region6113 castegroup_1961_2011_code tru, joint
	assert r(ndistinct) == r(N) // each observation is uniquely defined by region - castegroup - area
		
	keep if tru == "Total"
	drop tru

	egen matricplus_p_2011 = rowtotal(matric_p_2011 intermediate_p_2011 nontechdiploma_p_2011 techdiploma_p_2011 graduate_p_2011)
	egen middleplus_p_2011 = rowtotal(middle_p_2011 matricplus_p_2011)
	egen primaryplus_p_2011 = rowtotal(primary_p_2011 middleplus_p_2011)

	local edlevels 		literacy primary primaryplus middle middleplus matric matricplus graduate
	local excludeages 	0to6	0to8		0to8	0to11	0to11		0to14	0to14		0to19
	local numlevels: list sizeof edlevels

	forval i=1/`numlevels' {
		local level: word `i' of `edlevels'
		local exage: word `i' of `excludeages'
		
		if "`level'" == "literacy" local var literate
			else local var `level'
			
		gen gross_`level'_rate_2011 = `var'_p_2011/total_p_2011
		gen `level'_rate_2011 = `var'_p_2011 / (total_p_2011 - age`exage'_p_2011)
	}
	
	*********************************************************************************************************************
	* note: the (non-gross) rates for literacy, primary and middle at the district level are partly imputations 
	* because the age data for the relevant individual years is not available by individual tribes at the district level
	* (see the file 1.02b_combine_census2011_st_edu_files.do for details)
	* so it is not surprising we get a few pathological cases as below:
	*********************************************************************************************************************
	noi sum literacy_rate_2011 primary_rate_2011 matric_rate_2011
	noi count if !missing(literacy_rate_2011) & literacy_rate_2011>1 // 29
	noi count if !missing(primary_rate_2011) & primary_rate_2011>1	// 7
	noi count if !missing(middle_rate_2011) & middle_rate_2011>1 // 1	
	* because these variables are imputed, and these nonsensical results are all for small tribes, we just arbitrarily fix these pathological cases
	foreach var in literacy_rate_2011 primary_rate_2011 primaryplus_rate_2011 middle_rate_2011 middleplus_rate_2011 {
		replace `var' = 1 if !missing(`var') & `var' > 1
	}
	
	* let us drop states which we know do not exist in the 1961 ST language data
	drop if inlist(state_1961,"Goa, Daman and Diu","Jammu & Kashmir","North East Frontier Agency","Pondicherry","Sikkim","Uttar Pradesh")
		
	dis as err "The outcomes dataset has `:dis %5.0fc _N ' observations." // 6,502
	
	tempfile outcomes
	save `outcomes'

*********************************************************************************************************************
* 2. prepare the language distance information from census 1961 mother tongues combined with DISE 2013-14  
*********************************************************************************************************************
	
	use "../03_processed/census_1961_mothertongue_for_analysis_distance", clear

	distinct region6113 castegroup_1961_2011_code mothertongue, joint
	assert r(ndistinct) == r(N) // each observation is uniquely defined by region - castegroup - mothertongue
	
	drop if mothertongue == "all mother tongues"	
	sort region6113 castegroup_1961_2011_code mothertongue

	egen total_speakers = rowtotal(total_speakers*)
	egen subsidiary_speakers = rowtotal(subsidiary_speakers_total_?)
	egen subsi_speakers_of_dominant_lang = rowtotal(subsi_speakers_of_dom_lang_?)
	
	foreach dtype of local dist_types {
		foreach type in dominant modal schools_all enrol_all enrol_st {
			gen weight_`dtype'_`type' = 1 if ~missing(lang_distance_`dtype'_`type')
			replace weight_`dtype'_`type' = . if missing(lang_distance_`dtype'_`type')

			gen total_speakers_temp = total_speakers * weight_`dtype'_`type'
			egen all_languages_temp = total(total_speakers_temp), by(state_1961 region6113 castegroup_1961_2011_code) missing
			
			capture drop all_languages_`type'
			egen all_languages_`type' = max(all_languages_temp), by(state_1961 region6113 castegroup_1961_2011_code)
			drop total_speakers_temp all_languages_temp

			gen lang_frac_in_trb_`dtype'_`type' = (total_speakers / all_languages_`type' ) * weight_`dtype'_`type' // lang frac in tribe
			gen wt_lang_dist_`dtype'_`type' = lang_frac_in_trb_`dtype'_`type' * lang_distance_`dtype'_`type' //weighted

			}
		}
	
	* we collapse to the region - castegroup level (i.e. over the mothertongues spoken by each tribe in a region)
	
	collapse 	(min) num_schools ///
				(sum) wt_lang_dist_* total_speakers subsidiary_speakers subsi_speakers_of_dominant_lang, ///
					by(state_1961 regionname6113 region6113 castegroup_1961_2011_code is_state)


	local lang_61_obs = _N
	
	dis as err "The linguistic distance dataset has `:dis %5.0fc `lang_61_obs' ' observations." // 3,013
					
	tempfile distances
	save `distances'

*********************************************************************************************************************
* 3. prep the census 1961 data on education, and merge it with the census 1961 linguistic data  
*********************************************************************************************************************
	
	use "../08_temp/census1961_st_edu_religion_with_dist_tribe_codes", clear
	rename total_m totalm
	rename total_f totalf
	drop total_p

	foreach stub in total illiterate literatenoed primary matric {
		rename `stub'? `stub'_?
	}
		
	egen total_p = rowtotal(total_m total_f)
	egen illiterate_p = rowtotal(illiterate_m illiterate_f)
	gen literate_p = total_p - illiterate_p
	egen literatenoed_p = rowtotal(literatenoed_m literatenoed_f)
	egen primary_p = rowtotal(primary_m primary_f)
	egen matric_p = rowtotal(matric_m matric_f)
	gen matricplus_p = matric_p
	egen primaryplus_p = rowtotal(primary_p matricplus_p)
	
	collapse (sum) *_m *_f *_p, by(region6113 regionname6113 castegroup_1961_2011_code)
	
	assert _N == `lang_61_obs' // sanity check: the 1961 education data should have exactly the same number of observations as the 1961 language data
	
	rename (total_m - primaryplus_p) =_1961

	gen gross_literacy_rate_1961 = literate_p_1961/total_p_1961
	gen gross_primary_rate_1961 = primary_p_1961/total_p_1961
	gen gross_primaryplus_rate_1961 = primaryplus_p_1961/total_p_1961
	gen gross_matric_rate_1961 = matric_p_1961/total_p_1961
	gen gross_matricplus_rate_1961 = gross_matric_rate_1961
	
	
	** Generating variable for % of all STs in the region that are christian 
	egen christian_p = rowtotal(christian_m_1961 christian_f_1961)
	
	gen christian_perc_tribe = christian_p/total_p_1961 * 100
	
	gen weight = 0 if castegroup_1961_2011_code == 500
	replace weight = 1 if castegroup_1961_2011_code != 500

	egen region_total_pop = total(total_p_1961*weight), by (region6113)
	egen region_total_christ = total(christian_p*weight), by (region6113)
	gen christian_perc_region = region_total_christ/region_total_pop * 100
	
	
	drop christian_p region_total_pop region_total_christ
	
	label var christian_perc_tribe "(%) of tribe group in region that is Christian"
	label var christian_perc_region "(%) of all tribe group in region that are Christian"
	
	
	
	*********************************************************************************************************************
	* to get the net rates, we need age data, which is not available for STs separately in 1961
	* so we use the following scaling factors, from the full population
	*** (source: C-III Part A, "Age, Sex and Education in all areas" and C-IV "Single year age returns", Census 1961)
	*** (both tables from Part II-C(i) Social and Cultural Tables of the India volume)
	*********************************************************************************************************************

	local totalpop_1961 438936918 
	local pop_frac_0to6_1961 = (66102638 + 7879090 + 7365057 + 7180513 + 6803988)/`totalpop_1961'   // 0to4 + 5m + 5f + 6m + 6f
	local pop_frac_0to9_1961 = (66102638 + 64673959)/`totalpop_1961' //0to4 + 5to9
	local pop_frac_0to8_1961 = (66102638 + round(4*64673959/5,0))/`totalpop_1961' // 0to4 + 80% of 5to9
	local pop_frac_0to14_1961 = (66102638 + 64673959 + 49306185)/`totalpop_1961' //0to4 + 5to9 + 10to14
	
	gen literacy_rate_1961 = gross_literacy_rate_1961 * (1-`pop_frac_0to6_1961')^-1
	gen primaryplus_rate_1961 = gross_primaryplus_rate_1961 * (1-`pop_frac_0to8_1961')^-1
	gen matricplus_rate_1961 = gross_matricplus_rate_1961 * (1-`pop_frac_0to14_1961')^-1
	
	noi sum literacy_rate_1961
	count if !missing(literacy_rate_1961) & literacy_rate_1961 > 1 // 92
	* again, as with the 2011 data, the 1961 literacy rate is sometimes above 1 for small tribes because of the imputation.
	* and again, we arbitrarily fix this
	replace literacy_rate_1961 = 1 if !missing(literacy_rate_1961) & literacy_rate_1961 > 1
	
	noi sum primaryplus_rate_1961
	count if !missing(primaryplus_rate_1961) & primaryplus_rate_1961 > 1 //
	replace primaryplus_rate_1961 = 1 if !missing(primaryplus_rate_1961) & primaryplus_rate_1961 > 1
	
	noi sum matricplus_rate_1961
	count if !missing(matricplus_rate_1961) & matricplus_rate_1961 > 1 //
	replace matricplus_rate_1961 = 1 if !missing(matricplus_rate_1961) & matricplus_rate_1961 > 1
	
	
	merge 1:1 region6113 castegroup_1961_2011_code using `distances', assert(match) nogen

	tempfile data_1961
	save `data_1961'

*********************************************************************************************************************
* 4. merge the outcomes data with the linguistic distance data  
*********************************************************************************************************************

	use `outcomes', clear

	merge 1:1 region6113 castegroup_1961_2011_code using `data_1961'
	
	*********************************************************************************************************************
	* note: there was a massive increase in areas with STs between 1961 and 2011, because of 
	* (i) delimitation changes in 1976; 
	* (ii) states in which STs were delimited only later (e.g. Jammu & Kashmir, Uttar Pradesh, etc). 
	* In addition, there is lack of tribe-specific language data in Arunachal Pradesh in 1961. 
	* So we will have a massive number of observations in the 'master' dataset that do not merge. 
	* There are also some small tribes that that were present in 1961 but are not found in census 2011.
	* So there will be a small number of observations in the `using' dataset that do not merge.
	* All this is to be expected. We will trust the code to have done the merge correctly, and retain only the merged observations.
	*********************************************************************************************************************
	
	keep if _merge == 3  // 2,915 observations
	drop _merge
	
	gen pop_2011_per_school = total_p_2011/num_schools
	 
	merge m:1 region6113 using "../08_temp/scheduled_and_tribal_regions", ///
		keepusing(scheduledarea6113 tribalarea6113) assert(match using) keep(match) nogen

	save "../03_processed/lang_workfile", replace
	
project , creates("../03_processed/lang_workfile.dta")
