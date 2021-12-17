project , uses("../03_processed/dise_basic_general_with_regions.dta")
project , uses("../03_processed/lang_workfile.dta")
project , uses("../03_processed/census_1961_mothertongue_for_analysis_distance.dta")
project , uses("../08_temp/census2011_religion_edu_data.dta")
project , uses("../08_temp/census2011_agg_state_edu_data.dta")




*************************************************************************************************************************************  
*Getting the top two mediums of instructions in states using DISE data 
*************************************************************************************************************************************
		
	
	use "../03_processed/dise_basic_general_with_regions.dta" , clear
	
	gen state_2011 = state_1961 //to account for creation of new states and name changes post 1961
	replace state_2011 = "Jharkhand" if state_1961 == "Bihar" & inlist(regionname6113,"Santal Parganas","Palamau","Dhanbad, Hazaribagh","Ranchi","Singhbhum")
	replace state_2011 = "Chhattisgarh" if state_1961 == "Madhya Pradesh" & inlist(regionname6113,"Surguja","Bilaspur, Durg","Raigarh","Raipur","Bastar")
	replace state_2011 = "Meghalaya" if state_1961 == "Assam"  & inlist(regionname6113,"Garo Hills","United Khasi And Jaintia Hills")
	replace state_2011 = "Mizoram" if state_1961 == "Assam" & inlist(regionname6113,"Mizo Hills")
	replace state_2011 = "Tamil Nadu" if state_1961 == "Madras"
	replace state_2011 = "Karnataka" if state_1961 == "Mysore"
	replace state_2011 = "Odisha" if state_1961 == "Orissa"
	replace state_2011 = "Dadra & Nagar Haveli" if state_1961 == "Dadra and Nagar Haveli"
	replace state_2011 = "Lakshadweep" if state_1961 == "Laccadive, Minicoy and Amindivi Islands"

		
	gen num_schools = 1
	collapse (count) num_schools, by(state_2011 medinstr1) //gives us the count for number of schools for each medium of instruction in each state
	egen total_num_schools = total(num_schools), by(state_2011) //total number of schools in that state
	gen medium_perc = num_schools/total_num_schools * 100 //percentage of schools in that state with a particular medium of instruction
	egen medium_rank = rank(-num_schools), by(state_2011)
	keep if inrange(medium_rank,1,2)


	keep state_2011 medinstr1 medium_perc medium_rank
	reshape wide medinstr1 medium_perc, i(state_2011) j(medium_rank)

	tempfile dise_data
	save `dise_data'
	 
	 
*************************************************************************************************************************************  
* Using the Lang workfile to get top 10 tribes in the country
* perc of the top 10 tribes in the states, retaining only the top 5 states where they occur
* finally merging with dise data which has info on medium of instruction 
*************************************************************************************************************************************

	 
	 use "../03_processed/lang_workfile.dta", clear
	 drop if is_state | castegroup_1961_2011_code == 500 
	 egen total_st_popn_2011 = total(total_p_2011) //national st popn
	 egen total_tribe_popn_2011 = total(total_p_2011), by(castegroup_1961_2011_code) //national popn of each tribe 
	 
	 
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

	
	egen state_tribe_popn_2011 = total(total_p_2011), by(castegroup_1961_2011_code state_2011) //total popn of each tribe in each state 

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
	order state_2011, after(state_1961)
	gen state_tribe_perc = state_tribe_popn_2011/total_tribe_popn_2011 * 100 //variable capturing perc of tribe popn that occurs in each state 
	gen national_tribe_perc = total_tribe_popn_2011/total_st_popn_2011 * 100

	preserve 
		keep castegroup_1961_2011_code state_2011 state_tribe_perc
		duplicates drop 
		egen top_states_2011 = rank(-state_tribe_perc), by(castegroup_1961_2011_code) //identifying the top states where the top 10 tribes occur
		keep castegroup_1961_2011_code state_2011 top_states_2011
		tempfile topstates
		save `topstates'
	restore


	merge m:1 castegroup_1961_2011_code state_2011 using `topstates', nogen
	keep if inrange(top_states_2011,1,5)
	

	egen total_p_2011_state = total(total_p_2011), by(castegroup_1961_2011_code state_2011) //total popn of each tribe in each state
	egen matricplus_p_2011_state = total(matricplus_p_2011), by(castegroup_1961_2011_code state_2011) //total matricplus popn of each tribe in each state
	egen age0to14_p_2011_state = total(age0to14_p_2011), by(castegroup_1961_2011_code state_2011) //total popn of tribe aged 0-14 in each state
	egen literate_p_2011_state = total(literate_p_2011), by(castegroup_1961_2011_code state_2011) //total popn of tribe that is literate in each state
	egen age0to6_p_2011_state = total(age0to6_p_2011), by(castegroup_1961_2011_code state_2011) //total popn of tribe aged 0-6 in that state
	


	keep state_2011 castegroup_1961_2011_code total_st_popn_2011 total_tribe_popn_2011 national_tribe_perc state_tribe_popn_2011 state_tribe_perc top_states_2011 total_p_2011_state matricplus_p_2011_state age0to14_p_2011_state literate_p_2011_state age0to6_p_2011_state

	assert total_p_2011_state == state_tribe_popn_2011 // a small check
	duplicates drop	
		
	** constructing state level literacy and matricplus rates
	
	gen matricplus_rate_2011 =  matricplus_p_2011_state / (total_p_2011_state - age0to14_p_2011_state) * 100
	gen literacy_rate_2011 = literate_p_2011_state /(total_p_2011_state - age0to6_p_2011_state) * 100
	merge m:1 state_2011 using `dise_data' , keep(match) nogen 


	tempfile state_dise
	save `state_dise'
	
********************************************************************************************************************************************************************************* 
* Using mothertongue data to identify the mothertongues which are
* (1) used as a medium of instruction in school 
* (2) the language most commonly spoken by that tribe in that state
*********************************************************************************************************************************************************************************


	use "../03_processed/census_1961_mothertongue_for_analysis_distance.dta", clear

	drop if mothertongue == "all mother tongues" | castegroup_1961_2011_code == 500 
	drop if is_state == 1 


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


	collapse (sum) total_speakers_p, by(state_2011 castegroup_1961_2011_code mothertongue)
	egen state_popn = total(total_speakers_p), by(castegroup_1961_2011_code state_2011)

	merge m:1 state_2011 castegroup_1961_2011_code using `state_dise' , keep(match) nogen


	order state_2011 castegroup_1961_2011_code mothertongue medinstr11 medinstr12
	egen tag = tag(state_2011 medinstr11)
	list state_2011 medinstr11 if tag == 1 , noobs table //to identify the medium of instructions for each state
	drop tag 

	/*
  +-----------------------------------+
  |             state_2011   medin~11 |
  |-----------------------------------|
  |                  Assam   Assamese |
  |                  Bihar      Hindi |
  |           Chhattisgarh      Hindi |
  |   Dadra & Nagar Haveli   Gujarati |
  |                Gujarat   Gujarati |
  |-----------------------------------|
  |              Jharkhand      Hindi |
  |         Madhya Pradesh      Hindi |
  |            Maharashtra    Marathi |
  |                Manipur    English |
  |              Meghalaya      Khasi |
  |-----------------------------------|
  |                Mizoram       Mizo |
  |              Karnataka    Kannada |
  |               Nagaland    English |
  |                 Odisha      Oriya |
  |              Rajasthan      Hindi |
  |-----------------------------------|
  |                Tripura    Bengali |
  |            West Bengal    Bengali |
  +-----------------------------------+

	*/
	
	
	gen state_lang = 0
	replace state_lang = 1 if mothertongue == "bengali" & inlist(state_2011, "West Bengal", "Tripura")
	replace state_lang = 1 if mothertongue == "hindi" & inlist(state_2011,"Bihar", "Rajasthan", "Madhya Pradesh", "Jharkhand", "Chhattisgarh")
	replace state_lang = 1 if mothertongue == "gujarati" & inlist(state_2011, "Gujarat", "Dadra & Nagar Haveli")
	replace state_lang = 1 if mothertongue == "marathi" & state_2011 == "Maharashtra"
	replace state_lang = 1 if mothertongue == "oriya" & state_2011 == "Odisha"
	replace state_lang = 1 if mothertongue == "english" & state_2011 == "Nagaland"
	replace state_lang = 1 if mothertongue == "kannada" & state_2011 == "Karnataka"
	replace state_lang = 1 if mothertongue == "assamese" & state_2011 == "Assam"
	replace state_lang = 1 if mothertongue == "mizo" & state_2011 == "Mizoram"
	replace state_lang = 1 if mothertongue == "khasi" & state_2011 == "Meghalaya"
	replace state_lang = 1 if mothertongue == "english" & state_2011 == "Manipur"

	egen tag = tag(state_2011 medinstr12)
	list state_2011 medinstr12 if tag == 1 , noobs table //to identify the medium of instructions for each state
	drop tag 
	
	/*
  +-----------------------------------+
  |             state_2011   medin~12 |
  |-----------------------------------|
  |                  Assam    Bengali |
  |                  Bihar       Urdu |
  |           Chhattisgarh    English |
  |   Dadra & Nagar Haveli    Marathi |
  |                Gujarat    English |
  |-----------------------------------|
  |              Jharkhand    English |
  |         Madhya Pradesh    English |
  |            Maharashtra    English |
  |                Manipur     Others |
  |              Meghalaya       Garo |
  |-----------------------------------|
  |                Mizoram    English |
  |              Karnataka       Urdu |
  |                 Odisha    English |
  |              Rajasthan    English |
  |                Tripura    English |
  |-----------------------------------|
  |            West Bengal    English |
  +-----------------------------------+
	*/
	
	
	gen state_lang_2 = 0
	replace state_lang_2 = 1 if mothertongue == "english" & inlist(state_2011, "West Bengal","Tripura","Rajasthan","Odisha")
	replace state_lang_2 = 1 if mothertongue == "english" & inlist(state_2011,"Maharashtra","Madhya Pradesh","Jharkhand","Gujarat","Chhattisgarh","Mizoram")
	replace state_lang_2 = 1 if mothertongue == "bengali" & state_2011 == "Assam"
	replace state_lang_2 = 1 if mothertongue == "urdu" & state_2011 == "Bihar"
	replace state_lang_2 = 1 if mothertongue == "marathi" & state_2011 == "Dadra & Nagar Haveli"
	replace state_lang_2 = 1 if mothertongue == "urdu" & state_2011 == "Karnataka"
	replace state_lang_2 = 1 if mothertongue == "garo" & state_2011 == "Meghalaya"

	
	
	gen lang_perc = total_speakers_p/state_popn * 100
	egen lang_rank = rank(-lang_perc), by(castegroup_1961_2011_code state_2011) //we rank the mothertongues according to total speakers
	keep if state_lang == 1 | state_lang_2 == 1 | inrange(lang_rank,1,3) //we only retain those mothertongues which are either spoken as the medium of instructions or ranked 1-3 depending on total speakers
		
********************************************************************************************************************************************************************************
* Lang Order Logic
* first we display the major medium of instruction
* second we display the second major medium of instruction 
* next we display the most popular language spoken in the region 
* in the event that mediums of instruction are not spoken, we include other popular mothertongues, ranks for these are scaled by 10 so as to not interfere with preassigned order
********************************************************************************************************************************************************************************
	
    gen lang_order = 1 if state_lang == 1 
	replace lang_order = 2 if state_lang_2 == 1 
	replace lang_order = 3 if lang_rank == 1 & !inlist(lang_order,1,2) 
	replace lang_order = lang_rank + 10 if !inlist(lang_order,1,2,3) 


	sort castegroup_1961_2011_code state_2011
	keep lang_order state_2011 castegroup_1961_2011_code national_tribe_perc state_tribe_perc ///
	matricplus_rate_2011 literacy_rate_2011 medinstr11 medium_perc1 medinstr12 medium_perc2 mothertongue lang_perc 
	
	order state_2011 castegroup_1961_2011_code national_tribe_perc state_tribe_perc ///
	matricplus_rate_2011 literacy_rate_2011 medinstr11 medium_perc1 medinstr12 medium_perc2  mothertongue lang_perc
	
	format national_tribe_perc state_tribe_perc matricplus_rate_2011 literacy_rate_2011 medium_perc1 medium_perc2 lang_perc %5.2f
	bysort castegroup_1961_2011_code state_2011 (lang_order): gen i = _n

	drop lang_order
	reshape wide lang_perc mothertongue, i(state_2011 castegroup_1961_2011_code) j(i) 
	
	order state_2011 castegroup_1961_2011_code national_tribe_perc state_tribe_perc matricplus_rate_2011 literacy_rate_2011 medinstr11 medium_perc1 medinstr12 medium_perc2

	gsort castegroup_1961_2011_code -state_tribe_perc
	drop mothertongue4 lang_perc4
	
	save "../08_temp/census2011_state_table.dta" , replace

	
************************************************************************************************************************
* 3. Obtaining Information from 2011 Edu Religion Tables 
************************************************************************************************************************

	use "../08_temp/census2011_religion_edu_data", replace	

	
	keep state_code state religion total_p matricplus_p_2011_p age0to14_p
	replace religion = "All" if religion == "All religious communities"
	replace religion = "Other" if religion == "Other religions and persuasions"
	
	reshape wide *_p, i(state_code state) j(religion) string

	local religions Buddhist Christian Hindu Jain Muslim Other Sikh

	foreach relg of local religions {
		gen popn_share_`relg' = total_p`relg'/total_pAll * 100 
	}
	

	foreach relg of local religions {
		gen matricplus_rate_2011_`relg' = matricplus_p_2011_p`relg'/(total_p`relg' - age0to14_p`relg') * 100

	}

	
	foreach relg of local religions {
		order matricplus_rate_2011_`relg', after(popn_share_`relg')
	}
	
	rename state state_2011
	keep state_2011 popn_share_* matricplus_rate_*
	
	tempfile edu_religion
	save `edu_religion'
	
************************************************************************************************************************
* 4. Retaining relevant information from the lang workfile
************************************************************************************************************************

	
	use "../03_processed/lang_workfile.dta", clear
	drop if is_state | castegroup_1961_2011_code == 500 
	gen state = state_1961
	replace state = "Jharkhand" if state_1961 == "Bihar" & inlist(regionname6113,"Santal Parganas","Palamau","Dhanbad, Hazaribagh","Ranchi","Singhbhum")
	replace state = "Chhattisgarh" if state_1961 == "Madhya Pradesh" & inlist(regionname6113,"Surguja","Bilaspur, Durg","Raigarh","Raipur","Bastar")
	replace state = "Meghalaya" if state_1961 == "Assam"  & inlist(regionname6113,"Garo Hills","United Khasi And Jaintia Hills")
	replace state = "Mizoram" if state_1961 == "Assam" & inlist(regionname6113,"Mizo Hills")
	replace state = "Tamil Nadu" if state_1961 == "Madras"
	replace state = "Karnataka" if state_1961 == "Mysore"
	replace state = "Odisha" if state_1961 == "Orissa"
	replace state = "Dadra & Nagar Haveli" if state_1961 == "Dadra and Nagar Haveli"
	replace state = "Lakshadweep" if state_1961 == "Laccadive, Minicoy and Amindivi Islands"

	keep state castegroup_1961_2011_code total_p_2011 matricplus_p_2011 age0to14_p_2011
	collapse (sum) total_p_2011 matricplus_p_2011 age0to14_p_2011, by(state castegroup_1961_2011_code)
	
	merge m:1 state using "../08_temp/census2011_agg_state_edu_data" , assert(using match) keep(match) nogen
	
	/*
	states which do not match 
`"Arunachal Pradesh"' `"Chandigarh"' `"Daman & Diu"' `"Goa"' `"Haryana"' `"India"' `"Jammu & Kashmir"' `"NCT of Delhi"' `"Puducherry"' `"Punjab"' `"Sikkim"' `"Uttar Pradesh"' `"Uttarakhand"'
	*/


	local castes All Gen ST SC 
	foreach y of local castes {
		egen matricplus_p_2011_`y' = rowtotal(matric_p`y' intermediate_p`y' nontechdiploma_p`y' techdiploma_p`y' graduate_p`y')
	}
	

	gen matricplus_rate_2011_sc =  matricplus_p_2011_SC/ (total_pSC - age0to14_pSC) * 100 //matricplus rate for scs
	gen matricplus_rate_2011_nonscst = matricplus_p_2011_Gen/(total_pGen - age0to14_pGen) * 100 //matricplus rate for non-sc/st 
	gen matricplus_rate_2011_st = matricplus_p_2011_ST/(total_pST - age0to14_pST) * 100 

	gen popn_share_sc = total_pSC/total_pAll * 100 // share of sc of overall popn in region 
	gen popn_share_st_totpopn = total_pST/total_pAll * 100 // share of all st of total popn in region
	gen popn_share_nonscst = total_pGen/total_pAll * 100 

	
	gen popn_share_tribe_totst = total_p_2011/total_pST * 100 // perc of tribe as a fraction of all sts in the region 
	gen popn_share_tribe = total_p_2011/total_pAll * 100 
	
	rename state state_2011 

	merge 1:1 castegroup_1961_2011_code state_2011 using "../08_temp/census2011_state_table.dta", assert(master match) keep(match) nogen
	
	gen nontribe_matricplus_p = matricplus_p_2011_ST - matricplus_p_2011 //excluding matric+ numbers of those belonging to big10 tribe
	gen nontribe_age0to14_p = age0to14_pST - age0to14_p_2011 //excluding age 0to14 popn numbers of those belonging to big10 tribe
	gen nontribe_total_p = total_pST - total_p_2011
	
	gen popn_share_nontribe = nontribe_total_p/total_pAll * 100 
	gen matricplus_rate_2011_nontribe = nontribe_matricplus_p/(nontribe_total_p - nontribe_age0to14_p) * 100

	keep state_2011 castegroup_1961_2011_code national_tribe_perc state_tribe_perc ///
	matricplus_rate_2011 literacy_rate_2011 medinstr11 medium_perc1 medinstr12 medium_perc2 ///
	mothertongue1 lang_perc1 mothertongue2 lang_perc2 mothertongue3 lang_perc3 ///
	matricplus_rate_2011_* popn_share_* 

	
	order castegroup_1961_2011_code state_2011 national_tribe_perc state_tribe_perc popn_share_tribe_totst popn_share_tribe
	order popn_share_nontribe matricplus_rate_2011_nontribe popn_share_st_totpopn matricplus_rate_2011_st ///
	popn_share_sc matricplus_rate_2011_sc popn_share_nonscst matricplus_rate_2011_nonscst, after(literacy_rate_2011)
	
	merge m:1 state_2011 using `edu_religion' , assert(using match) keep(match) nogen 
	gsort -national_tribe_perc -state_tribe_perc  
	format popn_share_* matricplus_rate_2011_* %5.2f

	
	export excel using "../04_results/03_excel_tables/state_table.xls", firstrow(variables) replace

	
	
project, creates("../08_temp/census2011_state_table.dta")
project, creates("../04_results/03_excel_tables/state_table.xls")

	