project , uses("../03_processed/lang_workfile.dta")

************************************************************************************************************************
* Table on correlation between different measures of linguistic distance
************************************************************************************************************************

	use "../03_processed/lang_workfile.dta", clear

	drop if is_state

	drop if inlist(castegroup_1961_2011_code,500) // also exclude General Castes (990)?

	estpost corr wt_lang_dist_f8_modal wt_lang_dist_tj_modal wt_lang_dist_as_modal, matrix
	#delimit ;
	esttab .
		using "../04_results/01_tables/3_distance_correlation.tex", replace
		booktabs alignment(l)
		not unstack compress 
		nonumbers star(* 0.10 ** 0.05 *** 0.01) 
		coeflabels(	wt_lang_dist_tj_modal "\$D^{NT}\$" 
					wt_lang_dist_f8_modal "\$D^{CB}\$" 
					wt_lang_dist_as_modal "\$D^{LS}\$")
		eqlabels("\$D^{CB}\$" "\$D^{NT}\$" "\$D^{LS}\$")
		stats(N, fmt(%18.0gc) labels(`"Observations"') layout({@}))
		nomtitles
		;
	#delimit cr
	
	project, creates("../04_results/01_tables/3_distance_correlation.tex")
