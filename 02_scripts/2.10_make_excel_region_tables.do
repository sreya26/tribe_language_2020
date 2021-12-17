
project , uses("../03_processed/dise_basic_general_with_regions.dta")
project , uses("../03_processed/lang_workfile.dta")
project , uses("../03_processed/census_1961_mothertongue_for_analysis_distance.dta")
project , uses("../03_processed/regions6113_with_dists_2011.dta")
project , uses("../08_temp/census2011_st_edu_data.dta")
project , uses("../08_temp/census2011_sc_edu_data.dta")
project , uses("../08_temp/census2011_overall_edu_data.dta")


*************************************************************************************************************************************  
*Getting the top two mediums of instructions in regions using DISE data 
*************************************************************************************************************************************
	
		
	use "../03_processed/dise_basic_general_with_regions.dta" , clear
		
	gen num_schools = 1
	collapse (count) num_schools, by(region6113 medinstr1)
	egen total_num_schools = total(num_schools), by(region6113)
	gen medium_perc = num_schools/total_num_schools * 100
	egen medium_rank = rank(-num_schools), by(region6113)
	keep if inrange(medium_rank,1,2)


	keep region6113 medinstr1 medium_perc medium_rank
	reshape wide medinstr1 medium_perc, i(region6113) j(medium_rank)

	tempfile dise_data_reg
	save `dise_data_reg'
	
	
*************************************************************************************************************************************  
* Using the Lang workfile to get top 10 tribes in the country
* perc of the top 10 tribes in the regions, retaining only the top 5 regions where they occur
* finally merging with dise data which has info on medium of instruction 
*************************************************************************************************************************************

	 
	 use "../03_processed/lang_workfile.dta", clear
	 drop if is_state | castegroup_1961_2011_code == 500 
	 egen total_st_popn_2011 = total(total_p_2011)
	 egen total_tribe_popn_2011 = total(total_p_2011), by(castegroup_1961_2011_code)
	 
	drop if castegroup_1961_2011_code == 990

	preserve
			collapse (sum) total_p_2011, by(castegroup_1961_2011_code)
			gsort -total_p_2011

			gen big10 = 1 in 1/10
			replace big10 = 0 if missing(big10)

			keep castegroup_1961_2011_code big10
			tempfile big10
			save `big10'
	restore
		
	merge m:1 castegroup_1961_2011_code using `big10', nogen
	keep if big10 == 1
	gen region_tribe_perc = total_p_2011/total_tribe_popn_2011 * 100
	gen national_tribe_perc = total_tribe_popn_2011/total_st_popn_2011 * 100

	
	
	egen top_regions_2011 = rank(-region_tribe_perc), by(castegroup_1961_2011_code)
	keep if inrange(top_regions_2011,1,5)

	keep region6113 castegroup_1961_2011_code total_st_popn_2011 total_tribe_popn_2011 total_p_2011 national_tribe_perc ///
	region_tribe_perc top_regions_2011 gross_literacy_rate_2011 literacy_rate_2011 gross_matricplus_rate_2011 matricplus_rate_2011
	

	merge m:1 region6113 using `dise_data_reg' , keep(match) nogen


	tempfile region_dise
	save `region_dise'
	
	
********************************************************************************************************************************************************************************
* Using mothertongue data to identify the mothertongues which are
* (1) used as a medium of instruction in school 
* (2) the language most commonly spoken by that tribe in that region
********************************************************************************************************************************************************************************


	use "../03_processed/census_1961_mothertongue_for_analysis_distance.dta", clear

	drop if mothertongue == "all mother tongues" | castegroup_1961_2011_code == 500
	drop if is_state == 1

	egen total_speakers_p = rowtotal(total_speakers_m total_speakers_f)
	egen region_popn = total(total_speakers_p), by(castegroup_1961_2011_code region6113)
	
	gen state_2011 = state_1961
	replace state_2011 = "Jharkhand" if state_1961 == "Bihar" & inlist(regionname6113,"Santal Parganas","Palamau","Dhanbad, Hazaribagh","Ranchi","Singhbhum")
	replace state_2011 = "Chhattisgarh" if state_1961 == "Madhya Pradesh" & inlist(regionname6113,"Surguja","Bilaspur, Durg","Raigarh","Raipur","Bastar")
	replace state_2011 = "Meghalaya" if state_1961 == "Assam"  & inlist(regionname6113,"Garo Hills","United Khasi And Jaintia Hills")
	replace state_2011 = "Mizoram" if state_1961 == "Assam" & inlist(regionname6113,"Mizo Hills")


	keep state_2011 regionname6113 region6113 castegroup_1961_2011_code mothertongue total_speakers_p region_popn
	merge m:1 region6113 castegroup_1961_2011_code using `region_dise' , keep(match) nogen
	

	order state_2011 regionname6113 region6113 castegroup_1961_2011_code mothertongue medinstr11 medinstr12

	egen tag = tag(regionname6113 medinstr11)
	list state_2011 regionname6113 medinstr11 if tag == 1 , noobs table
	drop tag 
	
	/*
  +----------------------------------------------------------------+
  |     state_2011                       regionname6113   medin~11 |
  |----------------------------------------------------------------|
  |          Assam                           Garo Hills       Garo |
  |          Assam       United Khasi And Jaintia Hills      Khasi |
  |          Assam   United Mikir And North Cachar Hill    English |
  |          Assam                           Mizo Hills       Mizo |
  |      Jharkhand                      Santal Parganas      Hindi |
  |----------------------------------------------------------------|
  |      Jharkhand                  Dhanbad, Hazaribagh      Hindi |
  |      Jharkhand                               Ranchi      Hindi |
  |      Jharkhand                            Singhbhum      Hindi |
  |        Gujarat                          Panchmahals   Gujarati |
  | Madhya Pradesh                               Jhabua      Hindi |
  |----------------------------------------------------------------|
  | Madhya Pradesh                           West Nimar      Hindi |
  | Madhya Pradesh                               Mandla      Hindi |
  |   Chhattisgarh                              Surguja      Hindi |
  |   Chhattisgarh                       Bilaspur, Durg      Hindi |
  |   Chhattisgarh                              Raigarh      Hindi |
  |----------------------------------------------------------------|
  |   Chhattisgarh                               Raipur      Hindi |
  |   Chhattisgarh                               Bastar      Hindi |
  |    Maharashtra                                Thana    Marathi |
  |    Maharashtra                                Nasik    Marathi |
  |    Maharashtra                               Dhulia    Marathi |
  |----------------------------------------------------------------|
  |    Maharashtra                              Jalgaon    Marathi |
  |    Maharashtra                           Ahmadnagar    Marathi |
  |    Maharashtra                                Poona    Marathi |
  |    Maharashtra                               Chanda    Marathi |
  |        Manipur                    Mao & Sadar Hills    English |
  |----------------------------------------------------------------|
  |        Manipur                            Tamenlang     Others |
  |       Nagaland                   Kohima, Mokokchung    English |
  |       Nagaland                             Tuensang    English |
  |         Orissa                   Kalahandi, Koraput      Oriya |
  |         Orissa                             Bolangir      Oriya |
  |----------------------------------------------------------------|
  |         Orissa                      Baudh-Khondmals      Oriya |
  |         Orissa                               Ganjam      Oriya |
  |         Orissa                           Sundargarh      Oriya |
  |         Orissa                                 Puri      Oriya |
  |         Orissa                           Mayurbhanj      Oriya |
  |----------------------------------------------------------------|
  |      Rajasthan                                Alwar      Hindi |
  |      Rajasthan               Jaipur, Sawai Madhopur      Hindi |
  |      Rajasthan        Banswara, Chitorgarh, Udaipur      Hindi |
  |      Rajasthan                                Bundi      Hindi |
  |      Rajasthan                                 Kota      Hindi |
  |----------------------------------------------------------------|
  |    West Bengal                           Jalpaiguri    Bengali |
  |    West Bengal                            Midnapore    Bengali |
  +----------------------------------------------------------------+
*/
	
	gen reg_lang = 0 //constructing indicators to flag the mothertongues spoken as medium of instruction in the respective region 
	
	replace reg_lang = 1 if mothertongue == "bengali" & inlist(state_2011, "West Bengal")
	replace reg_lang = 1 if mothertongue == "hindi" & inlist(state_2011,"Rajasthan", "Madhya Pradesh", "Jharkhand", "Chhattisgarh")
	replace reg_lang = 1 if mothertongue == "gujarati" & inlist(state_2011, "Gujarat")
	replace reg_lang = 1 if mothertongue == "marathi" & state_2011 == "Maharashtra"
	replace reg_lang = 1 if mothertongue == "oriya" & state_2011 == "Orissa"
	replace reg_lang = 1 if mothertongue == "english" & state_2011 == "Nagaland"
	replace reg_lang = 1 if mothertongue == "garo" & inlist(regionname6113,"Garo Hills")
	replace reg_lang = 1 if mothertongue == "khasi" & inlist(regionname6113,"United Khasi And Jaintia Hills")
	replace reg_lang = 1 if mothertongue == "english" & inlist(regionname6113,"United Mikir And North Cachar Hill")
	replace reg_lang = 1 if mothertongue == "mizo" & inlist(regionname6113,"Mizo Hills")
	replace reg_lang = 1 if mothertongue == "english" & inlist(regionname6113,"Mao & Sadar Hills")
	
	
	egen tag = tag(regionname6113 medinstr12)
	list state_2011 regionname6113 medinstr12 if tag == 1 , noobs table
	drop tag 
	
	
	/*
 +----------------------------------------------------------------+
  |     state_2011                       regionname6113   medin~12 |
  |----------------------------------------------------------------|
  |      Meghalaya                           Garo Hills   Assamese |
  |      Meghalaya       United Khasi And Jaintia Hills    English |
  |          Assam   United Mikir And North Cachar Hill   Assamese |
  |        Mizoram                           Mizo Hills    English |
  |      Jharkhand                      Santal Parganas    English |
  |----------------------------------------------------------------|
  |      Jharkhand                  Dhanbad, Hazaribagh    English |
  |      Jharkhand                               Ranchi    English |
  |      Jharkhand                            Singhbhum    Bengali |
  |        Gujarat                          Panchmahals    English |
  | Madhya Pradesh                               Jhabua         98 |
  |----------------------------------------------------------------|
  | Madhya Pradesh                           West Nimar    English |
  | Madhya Pradesh                               Mandla    English |
  |   Chhattisgarh                              Surguja    English |
  |   Chhattisgarh                       Bilaspur, Durg    English |
  |   Chhattisgarh                              Raigarh    English |
  |----------------------------------------------------------------|
  |   Chhattisgarh                               Raipur    English |
  |   Chhattisgarh                               Bastar    English |
  |    Maharashtra                                Thana    English |
  |    Maharashtra                                Nasik    English |
  |    Maharashtra                               Dhulia    English |
  |----------------------------------------------------------------|
  |    Maharashtra                              Jalgaon       Urdu |
  |    Maharashtra                           Ahmadnagar    English |
  |    Maharashtra                                Poona    English |
  |    Maharashtra                               Chanda    English |
  |        Manipur                    Mao & Sadar Hills      Hindi |
  |----------------------------------------------------------------|
  |        Manipur                            Tamenlang    English |
  |         Orissa                   Kalahandi, Koraput    English |
  |         Orissa                             Bolangir    English |
  |         Orissa                      Baudh-Khondmals    English |
  |         Orissa                               Ganjam    English |
  |----------------------------------------------------------------|
  |         Orissa                           Sundargarh    English |
  |         Orissa                                 Puri    English |
  |         Orissa                           Mayurbhanj    English |
  |      Rajasthan                                Alwar    English |
  |      Rajasthan               Jaipur, Sawai Madhopur    English |
  |----------------------------------------------------------------|
  |      Rajasthan        Banswara, Chitorgarh, Udaipur    English |
  |      Rajasthan                                Bundi    English |
  |      Rajasthan                                 Kota    English |
  |    West Bengal                           Jalpaiguri      Hindi |
  |    West Bengal                            Midnapore    English |
  +----------------------------------------------------------------+

	*/
	
	gen reg_lang_2 = 0 //constructing indicators to flag the mothertongues spoken as medium of instruction in the respective region 
	replace reg_lang_2 = 1 if mothertongue == "assamese" &  regionname6113 == "Garo Hills"
	replace reg_lang_2 = 1 if mothertongue == "assamese" & regionname6113 == "United Mikir And North Cachar Hill"
	replace reg_lang_2 = 1 if mothertongue == "bengali" & regionname6113 == "Singhbhum"
	replace reg_lang_2 = 1 if mothertongue == "urdu" & regionname6113 == "Jalgaon"
	replace reg_lang_2 = 1 if mothertongue == "hindi" & regionname6113 == "Mao & Sadar Hills"
	replace reg_lang_2 = 1 if mothertongue == "hindi" & regionname6113 == "Jalpaiguri"
	replace reg_lang_2 = 1 if mothertongue == "english" & !inlist(regionname6113,"Garo Hills","United Mikir And North Cachar Hill","Singhbhum","Jalgaon","Mao & Sadar Hills","Jalpaiguri")
	

	gen lang_perc = total_speakers_p/region_popn * 100
	egen lang_rank = rank(-lang_perc), by(castegroup_1961_2011_code region6113) //rank the mothertongues spoken in the region acc to number of speakers 
	keep if reg_lang == 1 | reg_lang_2 == 1 | inrange(lang_rank,1,3) //we only retain those mothertongues which are either spoken as the medium of instructions or ranked 1-3 depending on total speakers
	
********************************************************************************************************************************************************************************
* Lang Order Logic
* first we display the major medium of instruction
* next we display the second major medium of instruction 
* next we display the most popular language spoken in the region 
* in the event that mediums of instruction are not spoken, we include other popular mothertongues, ranks are scaled by 10 so as to not interfere with preassigned order
*******************************************************************************************************************************************************************************

	
	gen lang_order = 1 if reg_lang == 1 
	replace lang_order = 2 if reg_lang_2 == 1 
	replace lang_order = 3 if lang_rank == 1 & !inlist(lang_order,1,2) 
	replace lang_order = lang_rank + 10 if !inlist(lang_order,1,2,3) 
	
	sort castegroup_1961_2011_code region6113
	keep lang_order state_2011 regionname6113 castegroup_1961_2011_code national_tribe_perc region_tribe_perc ///
	matricplus_rate_2011 literacy_rate_2011 medinstr11 medium_perc1 medinstr12 medium_perc2 mothertongue lang_perc 

	
	format national_tribe_perc region_tribe_perc matricplus_rate_2011 literacy_rate_2011 lang_perc medium_perc1 medium_perc2 %5.2f
	bysort castegroup_1961_2011_code regionname6113 (lang_order): gen i = _n

	drop lang_order
	reshape wide lang_perc mothertongue, i(state_2011 regionname6113 castegroup_1961_2011_code) j(i) 
	
	
	gen matricplus_rate_2011_perc = matricplus_rate_2011 * 100
	gen literacy_rate_2011_perc = literacy_rate_2011 * 100 
	drop matricplus_rate_2011 literacy_rate_2011 mothertongue4 lang_perc4
	format matricplus_rate_2011_perc literacy_rate_2011_perc %5.2f

	order state_2011 regionname6113 castegroup_1961_2011_code national_tribe_perc region_tribe_perc matricplus_rate_2011_perc literacy_rate_2011_perc medinstr11 medium_perc1 medinstr12 medium_perc2 
	gsort castegroup_1961_2011_code -region_tribe_perc
	
	
	save "../08_temp/census2011_regions_table.dta" , replace
	
*********************************************************************************************************************
** Now we add in additional information to these tables 
** (1) percentage of total sc popn as a fraction of overall popn and matricplus rate of scs
** (2) percentage of total non-sc/st popn as a fraction of overall popn and matricplus rate of non-sc/st
** (3) percentage of st's popn excluding the particular big 10 tribe as a fraction of overall popn in the specific region and their matric+ rate
** (4) percentage of all st popn as a fraction of overall popn and matricplus rate of sts
*********************************************************************************************************************	
		
*********************************************************************************************************************
** first we retain only the all scheduled tribes obs and tag them as such
*********************************************************************************************************************

	use "../08_temp/census2011_st_edu_data.dta" , clear
	drop if district_code == 0
	keep if caste_code == 500
	keep if tru == "Total"
	drop tru

	egen matricplus_p = rowtotal(matric_p intermediate_p nontechdiploma_p techdiploma_p graduate_p)

	foreach var of varlist total_p matricplus_p age0to14_p{
		rename `var' `var'_st
	}

	keep state_code district_code state district *_st
	tempfile edu_st
	save `edu_st'

*********************************************************************************************************************
** similarly tag the total sc popn obs
*********************************************************************************************************************

	use "../08_temp/census2011_sc_edu_data.dta" , clear
	drop __*
	keep if tru == "Total"
	drop tru

	egen matricplus_p = rowtotal(matric_p intermediate_p nontechdiploma_p techdiploma_p graduate_p)
	foreach var of varlist total_p matricplus_p age0to14_p{
		rename `var' `var'_sc
	}

	keep state_code district_code state district *_sc
	tempfile edu_sc
	save `edu_sc'

*********************************************************************************************************************
** similarly tag the total overall popn obs 
*********************************************************************************************************************

	use "../08_temp/census2011_overall_edu_data.dta" , clear
	drop __*
	keep if tru == "Total"
	drop tru

	egen matricplus_p = rowtotal(matric_p intermediate_p nontechdiploma_p techdiploma_p graduate_p)


	foreach var of varlist total_p matricplus_p age0to14_p {
		rename `var' `var'_all
	}

	** merge all of these into one dataset

	merge 1:1 state_code district_code using `edu_st', keep(match master) assert(1 3) nogen
	merge 1:1 state_code district_code using `edu_sc', keep(match master) assert(1 3) nogen

	keep state_code district_code state district *_st *_sc *_all

*********************************************************************************************************************
** calculations to get non st/sc popn figures 
*********************************************************************************************************************

	egen total_p_scst = rowtotal(total_p_sc total_p_st)
	egen matricplus_p_scst = rowtotal(matricplus_p_sc matricplus_p_st)
	egen age0to14_p_scst = rowtotal(age0to14_p_st age0to14_p_sc)

	** *_gen corresponds to non sc/st popn figures (essentially subtract sc+st popn numbers from overall figures)

	gen total_p_gen = total_p_all - total_p_scst
	gen matricplus_p_gen = matricplus_p_all - matricplus_p_scst
	gen age0to14_p_gen = age0to14_p_all - age0to14_p_scst

	** gen dcode_2011 variable to merge with consistent regions file 
	gen double dcode_2011 = 201100000 + state_code*1000 + district_code
	format dcode_2011 %9.0f
	order dcode_2011, after(district_code)
		
	merge 1:1 dcode_2011 using "../03_processed/regions6113_with_dists_2011.dta"
	keep if _merge == 3
	collapse (sum) *_all *_st *_sc *_scst *_gen, by(region6113 regionname6113)

	save "../08_temp/census2011_regions_edu_data.dta" , replace

*********************************************************************************************************************
*** to calculate matricplus rate for non-big10-tribes in the selected regions 
********************************************************************************************************************

	use "../03_processed/lang_workfile.dta", clear
	drop if is_state | castegroup_1961_2011_code == 500 
	
	
	
	local religion hindus muslims christians buddhists jains sikhs other_persuasions religion_not_stated other_religions
	
	foreach relg of local religion {
		egen agg_`relg'_p_1961 = rowtotal(agg_`relg'_m_1961 agg_`relg'_f_1961)
	}
	
	assert agg_other_religions_p_1961 == 0 if agg_other_persuasions_p_1961  > 0
	assert agg_other_persuasions_p_1961 == 0 if agg_other_religions_p_1961  > 0
	
	egen agg_other_beliefs_p_1961 = rowtotal(agg_other_religions_p_1961 agg_other_persuasions_p_1961)
	rename agg_religion_not_stated_p_1961 agg_not_stated_p_1961
	
	local religion hindus muslims christians buddhists jains sikhs other_beliefs not_stated 
	
	foreach relg of local religion {
		gen agg_`relg'_p_1961_perc = agg_`relg'_p_1961 / agg_total_p_1961 * 100 
	}
	
	

	keep region6113 castegroup_1961_2011_code total_p_2011 matricplus_p_2011 age0to14_p_2011 *_perc 
	merge m:1 region6113 using "../08_temp/census2011_regions_edu_data.dta"
	keep if _merge == 3
	drop _merge

	** creating the required variables 

	gen matricplus_rate_2011_sc =  matricplus_p_sc/ (total_p_sc - age0to14_p_sc) * 100 //matricplus rate for scs
	gen matricplus_rate_2011_nonscst = matricplus_p_gen/(total_p_gen - age0to14_p_gen) * 100 //matricplus rate for non-sc/st 
	gen matricplus_rate_2011_st = matricplus_p_st/(total_p_st - age0to14_p_st) * 100 

	gen popn_share_sc = total_p_sc/total_p_all * 100 // share of sc of overall popn in region 
	gen popn_share_st_totpopn = total_p_st/total_p_all * 100 // share of all st of total popn in region
	gen popn_share_tribe_totst = total_p_2011/total_p_st * 100 // perc of tribe as a fraction of all sts in the region 
	gen popn_share_tribe = total_p_2011/total_p_all * 100 
	gen popn_share_nonscst = total_p_gen/total_p_all * 100 


*********************************************************************************************************************
** consolidating with earlier region table
*********************************************************************************************************************

	merge 1:1 castegroup_1961_2011_code regionname6113 using "../08_temp/census2011_regions_table.dta"

	
	gen nontribe_matricplus_p = matricplus_p_st - matricplus_p_2011 //excluding matric+ numbers of those belonging to big10 tribe
	gen nontribe_age0to14_p = age0to14_p_st - age0to14_p_2011 //excluding age 0to14 popn numbers of those belonging to big10 tribe
	gen nontribe_total_p = total_p_st - total_p_2011
	
	
	gen popn_share_nontribe = nontribe_total_p/total_p_all * 100 
	gen matricplus_rate_2011_nontribe = nontribe_matricplus_p/(nontribe_total_p - nontribe_age0to14_p) * 100
	keep if _merge == 3

	keep state_2011 regionname6113 castegroup_1961_2011_code national_tribe_perc region_tribe_perc ///
	matricplus_rate_2011_perc literacy_rate_2011_perc medinstr11 medium_perc1 medinstr12 medium_perc2 ///
	mothertongue1 lang_perc1 mothertongue2 lang_perc2 mothertongue3 lang_perc3 ///
	matricplus_rate_2011_sc matricplus_rate_2011_nonscst popn_share_sc popn_share_st_totpopn ///
	popn_share_tribe_totst matricplus_rate_2011_nontribe popn_share_nontribe ///
	popn_share_tribe popn_share_nonscst matricplus_rate_2011_st *_perc 


	format matricplus_rate_2011_sc matricplus_rate_2011_nonscst popn_share_sc popn_share_st_totpopn ///
	popn_share_tribe_totst matricplus_rate_2011_nontribe popn_share_nontribe popn_share_tribe ///
	popn_share_nonscst matricplus_rate_2011_st *_perc %5.2f
	
	gsort -national_tribe_perc -region_tribe_perc  
	
	order castegroup_1961_2011_code regionname6113 state_2011 national_tribe_perc
	order popn_share_tribe_totst popn_share_tribe, after(region_tribe_perc)
	order popn_share_nontribe matricplus_rate_2011_nontribe popn_share_st_totpopn matricplus_rate_2011_st ///
	popn_share_sc matricplus_rate_2011_sc popn_share_nonscst matricplus_rate_2011_nonscst, after(literacy_rate_2011_perc)
	order agg_*, after (lang_perc3)
	
	
	export excel using "../04_results/03_excel_tables/region_table.xls", firstrow(variables) replace
	
	
project , creates("../08_temp/census2011_regions_table.dta")
project , creates("../08_temp/census2011_regions_edu_data.dta")
project , creates("../04_results/03_excel_tables/region_table.xls")
	
	
	