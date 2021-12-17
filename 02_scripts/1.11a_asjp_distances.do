* read in ASJP distances

import excel using "../01_data/asjp_data/tribelang_asjp_matrix.xlsx", clear cellrange("A3") firstrow
mkmat adi-yim, matrix(asjp) rownames(iso)
mata: st_replacematrix("asjp", makesymmetric(st_matrix("asjp")))
drop adi-yim

svmat asjp, names(col)

foreach var of varlist adi-yim {
	replace `var' = round(`var',0.01)
}
		
save "../08_temp/asjp_distances", replace

