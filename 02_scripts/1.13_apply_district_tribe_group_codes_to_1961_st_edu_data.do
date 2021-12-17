************************************************************************************************************************
* this file takes the ST education data for individual tribe levels from Census 1961
* and gives them district and caste [group] codes 
************************************************************************************************************************

project , uses("../08_temp/census_1961_edu_religion_merged.dta")
project , uses("../08_temp/census_1961_mothertongue_data_with_dist_tribe_codes.dta")
project , uses("../08_temp/regions6113_with_dists_1961.dta")

************************************************************************************************************************
* 3. make the tribes the same as that in the mothertongue data [we do not give any codes here]
************************************************************************************************************************

	
	use "../08_temp/census_1961_edu_religion_merged.dta", clear

	drop if strpos(tribe,"aggregate")>0 // gets rid of the tribe groupings in Maharashtra

	drop if inlist(tribe,"keer","korama","nat, navdigar, sapera and kubutar","pulayan","vaghri", "all tribes of n.e.f.a.","all tribes of north-east frontier agency","dafla") 
	* these tribes groups could not be merged between 1961 and 2011 (detailed explanation in 1.03b_merge_1961_2011_tribe_groups.do)
	
	
	tempfile edu_data
	save `edu_data'

************************************************************************************************************************
* 4. give codes for individual tribes and tribe groups matched between census 1961 and census 2011  
************************************************************************************************************************
	
	use "../08_temp/census_1961_mothertongue_data_with_dist_tribe_codes", clear
	drop if missing(dcode_1961) //these are tribes with zero entries in 1961 and do not feature in the census tables, only in the scheduled tribe list 
	keep dcode_1961 tribe castegroup_1961_2011 castegroup_1961_2011_code

	duplicates drop dcode_1961 tribe, force

	merge 1:m dcode_1961 tribe using `edu_data', assert(master match)
	
	assert inlist(dcode_1961,601330,601331,601419,601420,601423,601424,601425) if _merge == 1 
	* these are seven districts of MH and MP where STs are not found (Akola, Bhandara, Buldhana, Nagpur, Wardha, Damoh, Sagar)
	
	drop if _merge == 1
	drop _merge
	
	replace castegroup_1961_2011_code = 500 if tribe == "all scheduled tribes"
	replace castegroup_1961_2011 = tribe if tribe == "all scheduled tribes"

	replace castegroup_1961_2011_code = 990 if strpos(tribe,"not known")>0 | tribe == "unclassified"
	*replace castegroup_2011 = "generic tribes" if strpos(tribe,"not known")>0 | tribe == "unclassified"
	replace castegroup_1961_2011 = "unclassified" if strpos(tribe,"not known")>0 | tribe == "unclassified"

************************************************************************************************************************
* 5. now to aggregate the data to consistent 1961-2013 regions
** note: we need to be careful while treating the agg_religions variables since they are unique to dcode_1961, and do not change with castegroups
************************************************************************************************************************

	replace state_1961 = "Himachal Pradesh" if state_1961 == "Punjab" // we'll only be using the part of Punjab that went to Himachal
	
	preserve 
		keep dcode_1961 area agg_* 
		duplicates drop 
		collapse (sum) agg_* , by(dcode_1961)
		tempfile aggregate_relg
		save `aggregate_relg'
	restore
	

	collapse (sum) total_m-indefinite_belief_f, by(dcode_1961 castegroup_1961_2011_code)
	merge m:1 dcode_1961 using `aggregate_relg' , assert(match) nogen 
	
	merge m:1 dcode_1961 using "../08_temp/regions6113_with_dists_1961", ///
			keepusing(region6113 regionname6113) assert(match using) keep(match) nogen
	* there will be many regions in which STs were not delimited and will thus not merge; we drop those
	
	preserve 
		keep dcode_1961 region6113 agg_* 
		duplicates drop 
		collapse (sum) agg_* , by(region6113)
		tempfile aggregate_region
		save `aggregate_region'
	restore
	

	collapse (sum) total_m-indefinite_belief_f, by(region6113 regionname6113 castegroup_1961_2011_code)
	merge m:1 region6113 using `aggregate_region'
	
	
	
	order regionname6113 region6113 castegroup_1961_2011_code

	save "../08_temp/census1961_st_edu_religion_with_dist_tribe_codes", replace

	
project , creates("../08_temp/census1961_st_edu_religion_with_dist_tribe_codes.dta")
