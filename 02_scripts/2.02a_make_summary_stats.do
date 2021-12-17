project , uses("../03_processed/lang_workfile.dta")
project , uses("../03_processed/census_1961_mothertongue_for_analysis_distance.dta")

************************************************************************************************************************
* Summary statistics on tribes and mother tongues
************************************************************************************************************************

	local tabstat_opts stat(count min max median mean sd) save
	
	use "../03_processed/lang_workfile", clear
	drop if is_state

	keep if castegroup_1961_2011_code == 500

	gen st_frac = total_p_2011 / overallpop_2011 

	tabstat total_p_2011 st_frac, `tabstat_opts' // ST population fraction per region
	tabstatmat A
	mat sumstats = A'

		
	use "../03_processed/lang_workfile", clear
	drop if inlist(castegroup_1961_2011_code,500) // also 990?
	drop if is_state
	egen double india_p_2011 = total(total_p_2011), by(castegroup_1961_2011_code)

	egen num_regions = count(region6113), by(castegroup_1961_2011_code)
	egen num_tribes = count(castegroup_1961_2011_code) , by(region6113)

	preserve
		duplicates drop castegroup_1961_2011_code, force
		keep  castegroup_1961_2011_code india_p_2011 num_regions
		gsort -india_p_2011
		tabstat num_regions, `tabstat_opts' // number of regions per tribe
		tabstatmat A
		mat sumstats = sumstats \ A'
	restore

	duplicates drop region6113, force
	tabstat num_tribes, `tabstat_opts' // number of tribes per region
	tabstatmat A
	mat sumstats = sumstats \ A'

	use "../03_processed/census_1961_mothertongue_for_analysis_distance", clear
	drop if is_state
	drop if inlist(castegroup_1961_2011_code,500) // also 990?
	drop if mothertongue == "all mother tongues"

	encode mothertongue, gen(mothertongue_num)

	preserve
		duplicates drop region6113 mothertongue_num, force
		egen languages_by_region = count(mothertongue_num) , by(region6113)
		duplicates drop region6113, force

		tabstat languages_by_region, `tabstat_opts' // number of languages per region
		tabstatmat A
		mat sumstats = sumstats \ A'
	restore

	duplicates drop castegroup_1961_2011_code mothertongue, force
	egen languages_by_tribe = count(mothertongue_num) , by(castegroup_1961_2011_code)
	duplicates drop castegroup_1961_2011_code, force

	tabstat languages_by_tribe, `tabstat_opts' // number of languages per tribe
	tabstatmat A
	mat sumstats = sumstats \ A'
	
	use "../03_processed/lang_workfile", clear
	drop if inlist(castegroup_1961_2011_code,500) // also 990?
	drop if is_state

	tabstat literacy_rate_2011 primaryplus_rate_2011 middleplus_rate_2011 matricplus_rate_2011 graduate_rate_2011 literacy_rate_1961 /// 
		wt_lang_dist_f8_modal wt_lang_dist_tj_modal wt_lang_dist_as_modal, `tabstat_opts'
	tabstatmat A
	mat sumstats = sumstats \ A'
	
	use "../03_processed/lang_workfile", clear
	drop if inlist(castegroup_1961_2011_code,500)
	drop if is_state
	tabstat christian_frac_tribe_1961 christian_frac_st_1961 christian_frac_all_1961, `tabstat_opts' // Christian popn percentages
	tabstatmat A
	mat sumstats = sumstats \ A'

	tempfile sumstats
	xsvmat sumstats, rowname(variables) names(col) saving(`sumstats')

	use `sumstats', clear
	rename *, lower
	
	format min max p50 %11.0fc
	format %10.2fc mean sd

	tempvar obnum f8_ob f8_ob_temp edu_ob edu_ob_temp
	set obs `=_N+2'
	replace variables = "weighted_lang" in l
	replace variables = "edu" in -2
	gen `obnum' = _n
	gen `f8_ob_temp' = _n if variables == "wt_lang_dist_f8_modal"
	egen `f8_ob' = max(`f8_ob_temp')
	gen `edu_ob_temp' = _n if variables == "literacy_rate_2011"
	egen `edu_ob' = max(`edu_ob_temp')
	replace `obnum' = `f8_ob' - 0.5 in l
	replace `obnum' = `edu_ob' - 0.5 in -2
	sort `obnum'
  
	gen varlabel = "ST population per district (2011)" if variables == "total_p_2011"
	replace varlabel = "ST fraction per district (2011)" if variables == "st_frac"
	replace varlabel = "No. of districts per tribe" if variables == "num_regions"
	replace varlabel = "No. of tribes per district" if variables == "num_tribes"
	replace varlabel = "No. of mother tongues per district" if variables == "languages_by_region"
	replace varlabel = "No. of mother tongues per tribe" if variables == "languages_by_tribe"
	replace varlabel = "Educational attainment (population fractions):" if variables == "edu"
	replace varlabel = "-- Literate, 2011" if variables == "literacy_rate_2011"
	replace varlabel = "-- Primary school, 2011" if variables == "primaryplus_rate_2011"
	replace varlabel = "-- Middle school, 2011" if variables == "middleplus_rate_2011"
	replace varlabel = "-- Secondary school, 2011" if variables == "matricplus_rate_2011"
	replace varlabel = "-- Graduation, 2011" if variables == "graduate_rate_2011"
	replace varlabel = "-- Literate, 1961" if variables == "literacy_rate_1961"
	replace varlabel = "Christian Frac of tribe group (1961)" if variables == "christian_frac_tribe_1961"
	replace varlabel = "Christian Frac of all STs (1961)" if variables == "christian_frac_st_1961"
	replace varlabel = "Christian Frac of overall popn (1961)" if variables == "christian_frac_all_1961"
	replace varlabel = "\multicolumn{5}{l}{Language distance from modal medium of instruction in district:}" if variables == "weighted_lang"
	replace varlabel = "-- using \$d^{CB}\$" if variables == "wt_lang_dist_f8_modal"
	replace varlabel = "-- using \$d^{NT}\$"  if variables == "wt_lang_dist_tj_modal"
	replace varlabel = "-- using \$d^{LS}\$"  if variables == "wt_lang_dist_as_modal"

	format varlabel %-32s
	order varlabel min max p50 mean sd

	tostring min max p50 mean sd, gen(min_str max_str p50_str mean_str sd_str) usedisplayformat force
	replace min_str = string(round(min,0.001)) if variables == "st_frac" | strpos(variables,"_rate_") | strpos(variables,"_frac_")
	replace max_str = string(round(max,0.001))  if variables == "st_frac" | strpos(variables,"_rate_")| strpos(variables,"_frac_")
	replace max_str = string(round(max,0.1))  if strpos(variables, "wt_lang_dist_")
	replace p50_str = string(round(p50,0.001))  if variables == "st_frac" | strpos(variables,"_rate_") | strpos(variables,"_frac_")
	replace p50_str = string(round(p50,0.1))  if strpos(variables, "wt_lang_dist_")
	replace mean_str = string(round(mean),"%13.0gc")  if variables == "total_p_2011"
	replace mean_str = string(round(mean,0.001))  if variables == "st_frac" | strpos(variables,"_rate_") | strpos(variables,"_frac_")
	replace sd_str = string(round(sd),"%13.0gc")  if variables == "total_p_2011"
	replace sd_str = string(round(sd,0.001))  if variables == "st_frac" | strpos(variables,"_rate_") | strpos(variables,"_frac_")

	replace min_str = "\phantom{\" if variables == "weighted_lang"
	replace max_str = "\"  if variables == "weighted_lang"
	replace p50_str = "\"  if variables == "weighted_lang"
	replace mean_str = "\"  if variables == "weighted_lang"
	replace sd_str = "}"  if variables == "weighted_lang"

	replace min_str = "" if variables == "edu"
	replace max_str = ""  if variables == "edu"
	replace p50_str = ""  if variables == "edu"
	replace mean_str = ""  if variables == "edu"
	replace sd_str = ""  if variables == "edu"
	
	#delimit ;
	listtab varlabel min_str max_str p50_str mean_str sd_str 
		using "../04_results/01_tables/9_tribelang_summary_stats_1.tex", replace
		rstyle(tabular)
		head(
		`"\toprule"' 
		`" & Min & Max & Median & Mean & Std Dev\\"'
		`"\midrule"')
		foot(`"\bottomrule"')
		;
	#delimit cr

	project , creates("../04_results/01_tables/9_tribelang_summary_stats_1.tex")
