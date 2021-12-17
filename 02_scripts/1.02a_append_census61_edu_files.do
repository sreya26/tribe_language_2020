 ************************************************************************************************************************
* this file appends the xlsx files that contain education levels for STs in Census 1961
* into a single dataset
************************************************************************************************************************

local census_61_edu_folder "../01_data/census_1961_st_education_tables"
local st_edu_61_files: dir "`census_61_edu_folder'" files "??stedu?61.xlsx"  

foreach file of local st_edu_61_files {
	project , original("`census_61_edu_folder'/`file'")		
} 

******************************************************************************************************
* 1. import and append the original excel data files
******************************************************************************************************

	save "../08_temp/census1961_st_edu_data", emptyok replace

	local states an ap as br dn gj hp ke kt mh mp mn lm ng or pn rj tn tr wb

	foreach st of local states {
		capture confirm file "`census_61_edu_folder'/`st'stedur61.xlsx"
		if _rc {
			dis as error "Could not locate the rural file for state `st'."
			continue
			}
		import excel using "`census_61_edu_folder'/`st'stedur61.xlsx", firstrow case(lower) clear
		destring totalm-matricf, replace
		replace area = "rural"
		append using "../08_temp/census1961_st_edu_data"
		save "../08_temp/census1961_st_edu_data", replace

		capture confirm file "`census_61_edu_folder'/`st'steduu61.xlsx"
		if _rc {
			dis as error "Could not locate the urban file for state `st'."
			continue
			}
		import excel using "`census_61_edu_folder'/`st'steduu61.xlsx", firstrow case(lower) clear
		destring totalm-degreetf, replace
		replace area = "urban"
		append using "../08_temp/census1961_st_edu_data"
		save "../08_temp/census1961_st_edu_data", replace
		}
  
******************************************************************************************************
* 2. make the matric variable comparable across rural and urban areas
******************************************************************************************************

	use "../08_temp/census1961_st_edu_data", clear

	foreach var in state district tribe scst area {
		replace `var' = trim(itrim(`var'))
		}

	egen matricplusm = rowtotal(matricm diplomantm diplomatm degreentm degreetm) if area == "urban"
	egen matricplusf = rowtotal(matricf diplomantf diplomatf degreentf degreetf) if area == "urban"

	replace matricm = matricplusm if area == "urban"
	replace matricf = matricplusf if area == "urban"

	drop diploma* degree* matricplus*

******************************************************************************************************
* 3. miscellaneous clean-ups
******************************************************************************************************
	
	
	assert scst == "st"
	drop scst

	foreach var of varlist totalm-matricf {
		replace `var' = 0 if missing(`var')
	}

	drop if totalm == 0 & totalf == 0

	sort state district tribe area
	
	compress
	
	save "../08_temp/census1961_st_edu_data", replace

project , creates("../08_temp/census1961_st_edu_data.dta")
