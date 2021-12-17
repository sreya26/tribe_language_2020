local censusfolder "../01_data/census_1961_st_language_tables"

local states /* an ap as br dn gj hp ke kt lm mh mn mp ng or pn rj tn tr */ wb /* */

foreach st of local states {
	
	import excel using "`censusfolder'/`st'61langst01.xlsx", firstrow clear
	
	foreach var of varlist subsidiary_speakers_total_? {
		destring `var', ignore("N") replace
	}
	
	foreach var of varlist sl_* {
		destring `var', ignore("xXnil") replace
	}
	
	foreach x in m f {
		replace subsidiary_speakers_total_`x' = 0 if missing(subsidiary_speakers_total_`x')
		egen subsidiary_total_`x' = rowtotal(sl_*_`x')
		gen subsidiary_error_`x' = subsidiary_total_`x' - subsidiary_speakers_total_`x'
	}
	count if subsidiary_error_m !=0 | subsidiary_error_f !=0
}
