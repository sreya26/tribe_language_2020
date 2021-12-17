local census_agg_61_religion_folder "../01_data/census_1961_agg_religion_tables"
local st_religion_agg_61_files: dir "`census_agg_61_religion_folder'" files "??61c7religion.xlsx"  

foreach file of local st_religion_agg_61_files {
	project , original("`census_agg_61_religion_folder'/`file'")		
} 

******************************************************************************************************
* 1. import and append the original excel data files
******************************************************************************************************

	save "../08_temp/census1961_agg_religion_data", emptyok replace

	local states an ap as br dn gj hp ke kt mh mp mn lm ng or pn rj tn tr wb

	foreach st of local states {
		capture confirm file "`census_agg_61_religion_folder'/`st'61c7religion.xlsx"
		if _rc {
			dis as error "Could not locate the religion file for state `st'."
			continue
			}
		import excel using "`census_agg_61_religion_folder'/`st'61c7religion.xlsx", firstrow case(lower) clear
		
		append using "../08_temp/census1961_agg_religion_data"
		save "../08_temp/census1961_agg_religion_data", replace
		}
		



******************************************************************************************************
* 2. miscellaneous clean-ups
******************************************************************************************************
	use "../08_temp/census1961_agg_religion_data", clear 
	rename other_religions_and_persuasions_ other_persuasions_m //due to invalid stata variable name error and to maintain consistency with st religion data 
	rename v other_persuasions_f
	
	** in rajasthan other religions and persuasions f is called u, fixing this
	
	replace other_persuasions_f = u if state == "Rajasthan"
	drop x u s t 
	rename code dcode_1961
	keep if !missing(dcode_1961) //retaining only districts 
	
	** for A&N, Tripura, Dadra & Nagar Haveli, Lakshadweep we need to create a new "district" [same as the state]
	expand 2 if inlist(dcode_1961,602700,602400,602900,603200), gen(dist_obs)
	replace dcode_1961 = dcode_1961 + 1 if dist_obs	
	drop dist_obs
	
	order dcode_1961 state union_territory islands division district total_rural_urban
	drop if total_rural_urban == "total"
	drop division sub_division
	
	foreach var of varlist total_p *_m *_f {
		replace `var' = 0 if missing(`var')
		rename `var' agg_`var'
	}
	
	* these were areas where either STs were not delimited in 1961, or the full census was not conducted, or no STs were present in 1961
	drop if inlist(state,"Delhi","Goa, Daman and Diu", "Jammu & Kashmir", "North East Frontier Agency", ///
					"Pondicherry", "Sikkim", "Uttar Pradesh") | ///
					inlist(district,"Akola","Bhandara","Buldhana","Nagpur","Wardha","Damoh","Sagar") ///
					
	drop if state == "Punjab" & !inlist(district,"total","Lahaul and Spiti")
		
	drop if agg_total_p == 0
	
	rename total_rural_urban area
	keep dcode_1961 state district area agg_*
	
	
	save "../08_temp/census1961_agg_religion_data_distcoded" , replace
	
project , creates("../08_temp/census1961_agg_religion_data.dta")
project , creates("../08_temp/census1961_agg_religion_data_distcoded.dta")	
	
	
	