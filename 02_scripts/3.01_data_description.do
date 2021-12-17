
*********************************************************************************************************
* issue with this data: state-level observations are not the sum of corresponding district-level observations
* e.g. because that specific tribe was not listed in a specific component district in 1961
* * e.g. the Mina total for Rajasthan is not equal to the sum of Mina populations of Rajasthan districts
* * this is because no Minas were listed in Ajmer district in 1961, 
* * and so the 2011 Mina observation does not merge with anything in 1961, and thus drops out
* upshot: construct state totals by summing over district observations, rather than using state observations
********************************************************************************************************

	use "../03_processed/lang_workfile", clear

	distinct castegroup_1961_2011_code_code if !inlist(castegroup_1961_2011_code_code,500,990)
	assert r(ndistinct) == 244 // we have 244 distinct tribes across the country
	
	distinct region6113 if !is_state
	assert r(ndistinct) == 211 // we have 211 consistent regions / "districts"

	keep if !is_state & !inlist(castegroup_1961_2011_code_code,500,990) // drop obs at state level, and obs for "All Scheduled Tribes" and "Generic Tribes"

	preserve
		collapse (sum) total_p_2011, by(castegroup_1961_2011_code_code)
		gsort -total_p_2011

		gen big10 = 1 in 1/10
		replace big10 = 0 if missing(big10)

		keep castegroup_1961_2011_code_code big10
		tempfile big10
		save `big10'
	restore
	
	merge m:1 castegroup_1961_2011_code_code using `big10', nogen
	keep if big10 == 1
	drop big10
	
	preserve
		bysort state_1961 castegroup_1961_2011_code_code: gen x_state = (_n == 1)
		gen x_region = 1
		
		collapse (sum) x_state x_region (sum) total_p_2011 , by(castegroup_1961_2011_code_code)
		
		rename x_state states
		rename x_region districts
		rename total_p_2011 population
		rename castegroup_1961_2011_code_code tribe
		format population %16.0fc
		
		gsort -population
		noi li tribe states districts population, clean

		/*	
				tribe   states  districts   population
		----------------------------------------------
		  1.     Bhil        7         83   16,625,036  
		  2.     Gond        9        113   14,584,496  
		  3.   Santal        4         40    6,570,382  
		  4.    Oraon        6         68    4,396,289  
		  5.     Mina        1         22    4,321,503  
		  6.    Munda        6         57    3,109,559  
		  7.     Naga        3         10    1,894,469  
		  8.    Khond        3         19    1,664,772  
		  9.      Kol        6         58    1,507,367  
		 10.    Khasi        1          4    1,430,402  
		*/
	restore
	
	keep state_1961 region6113 regionname6113 total_p_2011 castegroup_1961_2011_code_code literacy_rate_2011 primaryplus_rate_2011 matricplus_rate_2011 wt_lang_dist_f8_modal
	compress
	gsort region6113 -wt_lang_dist_f8_modal
	format total_p_2011 %16.0fc
	drop if total_p_2011 < 10000
	
