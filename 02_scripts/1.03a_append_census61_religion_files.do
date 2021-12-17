

local census_61_religion_folder "../01_data/census_1961_st_religion_tables"
local st_religion_61_files: dir "`census_61_religion_folder'" files "??61sct4breligion.xlsx"  

foreach file of local st_religion_61_files {
	project , original("`census_61_religion_folder'/`file'")		
} 

  
******************************************************************************************************
* 1. import and append the original excel data files
******************************************************************************************************

	save "../08_temp/census1961_st_religion_data", emptyok replace

	local states an ap as br dn gj hp ke kt mh mp mn lm ng or pn rj tn tr wb

	foreach st of local states {
		capture confirm file "`census_61_religion_folder'/`st'61sct4breligion.xlsx"
		if _rc {
			dis as error "Could not locate the religion file for state `st'."
			continue
			}
		import excel using "`census_61_religion_folder'/`st'61sct4breligion.xlsx", firstrow case(lower) clear
		
		append using "../08_temp/census1961_st_religion_data"
		save "../08_temp/census1961_st_religion_data", replace
		}
   
******************************************************************************************************
* 2. miscellaneous clean-ups
******************************************************************************************************

	use "../08_temp/census1961_st_religion_data", clear 
	
	drop area_type tribe_components // we do not require this 
	
	
	foreach var in state district tribe scst area {
		replace `var' = trim(itrim(`var'))
		}
	
	assert scst == "st"
	drop scst
	
	
	foreach var of varlist total_m-indefinite_belief_f {
		replace `var' = 0 if missing(`var')
	}
	
	drop if total_m == 0 & total_f == 0
	
	** getting rid of some redundant variables 
	
	replace naga_m = naga_religion_m if state == "Nagaland" //naga_religion features only in Nagaland
	replace naga_f = naga_religion_f if state == "Nagaland" // naga_religion features only in Nagaland 
	drop naga_religion_*


	replace indefinite_belief_m = indefinite_beliefs_m if indefinite_beliefs_m > 0
	replace indefinite_belief_f = indefinite_beliefs_f if indefinite_beliefs_f > 0 
	drop indefinite_beliefs_* 


	sort dcode state district tribe area
	
	save "../08_temp/census1961_st_religion_data", replace
	
project , creates("../08_temp/census1961_st_religion_data.dta")

	
	
	
	