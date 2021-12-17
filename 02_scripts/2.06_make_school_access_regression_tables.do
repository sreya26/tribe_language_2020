
project , uses("../03_processed/lang_workfile.dta")

*********************************************************************************************************************
* this do-file makes the school access regression tables for the tribelanguage paper
*********************************************************************************************************************

	use "../03_processed/lang_workfile.dta", clear

	drop if inlist(castegroup_1961_2011_code,500) | is_state // also exclude General Castes (990)?

	label var literacy_rate_1961 "Literacy 1961"

	local dist_types f8 // tj as
	local match_to dominant // dominant modal enrol_st schools_all enrol_all
	local areas all protected unprotected // scheduled tribal 
	
	foreach area of local areas {
		if "`area'" == "all" local ifcond
			else if "`area'" == "scheduled" local ifcond "if scheduledarea6113 ~= 0"
				else if "`area'" == "tribal" local ifcond "if tribalarea6113 ~= 0"
					else if "`area'" == "protected" local ifcond "if scheduledarea6113 ~= 0 | tribalarea6113 ~= 0"
						else if "`area'" == "unprotected" local ifcond "if scheduledarea6113 == 0 & tribalarea6113 == 0"
						
		foreach dtype of local dist_types {
			foreach type of local match_to {
				egen lang_dist_normalized = std(wt_lang_dist_`dtype'_`type') `ifcond'
				label var lang_dist_normalized "Distance"
				gen lang_dist_norm_sq = lang_dist_normalized^2
				label var lang_dist_norm_sq "Distance\$^2\$"
				local basic_x lang_dist_normalized lang_dist_norm_sq i.castegroup_1961_2011_code i.region6113
				label var wt_lang_dist_`dtype'_`type' "Language Distance"

				eststo POP_PER_SCHOOL, title("Population per School"): qui regress pop_2011_per_school `basic_x' literacy_rate_1961 `ifcond', robust

				#delimit ;
				esttab POP_PER_SCHOOL
					using "../04_results/01_tables/6_schoolreg_`type'_`dtype'_`area'.tex", replace
					booktabs
					nobase nonumbers mtitles label b(3) se star(* 0.10 ** 0.05 *** 0.01) stats(N, fmt(%18.0gc) labels(`"Observations"') layout({@}))
					drop(*castegroup_1961_2011_code* *region6113*)
					nonotes
					addnotes("Heteroskedasticity-robust standard errors in parentheses." "\sym{*} \(p<0.10\), \sym{**} \(p<0.05\), \sym{***} \(p<0.01\)")
				;
			#delimit cr

				drop lang_dist_normalized 
				cap drop lang_dist_norm_sq
				}
			}
	}

	project , creates("../04_results/01_tables/6_schoolreg_dominant_f8_all.tex")
	project , creates("../04_results/01_tables/6_schoolreg_dominant_f8_protected.tex")
	project , creates("../04_results/01_tables/6_schoolreg_dominant_f8_unprotected.tex")
