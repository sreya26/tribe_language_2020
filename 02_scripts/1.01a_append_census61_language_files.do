********************************************************************************************************************************
* this do-file constructs the mother tongue data from Census 1961 data 
********************************************************************************************************************************
project , original("../01_data/census_1961_st_language_tables/an61langst01.xlsx")
project , original("../01_data/census_1961_st_language_tables/ap61langst01.xlsx")
project , original("../01_data/census_1961_st_language_tables/as61langst01.xlsx")
project , original("../01_data/census_1961_st_language_tables/br61langst01.xlsx")
project , original("../01_data/census_1961_st_language_tables/dn61langst01.xlsx")
project , original("../01_data/census_1961_st_language_tables/gj61langst01.xlsx")
project , original("../01_data/census_1961_st_language_tables/hp61langst01.xlsx")
project , original("../01_data/census_1961_st_language_tables/ke61langst01.xlsx")
project , original("../01_data/census_1961_st_language_tables/kt61langst01.xlsx")
project , original("../01_data/census_1961_st_language_tables/lm61langst01.xlsx")
project , original("../01_data/census_1961_st_language_tables/mh61langst01.xlsx")
project , original("../01_data/census_1961_st_language_tables/mn61langst01.xlsx")
project , original("../01_data/census_1961_st_language_tables/mp61langst01.xlsx")
project , original("../01_data/census_1961_st_language_tables/ng61langst01.xlsx")
project , original("../01_data/census_1961_st_language_tables/or61langst01.xlsx")
project , original("../01_data/census_1961_st_language_tables/pn61langst01.xlsx")
project , original("../01_data/census_1961_st_language_tables/rj61langst01.xlsx")
project , original("../01_data/census_1961_st_language_tables/tn61langst01.xlsx")
project , original("../01_data/census_1961_st_language_tables/tr61langst01.xlsx")
project , original("../01_data/census_1961_st_language_tables/wb61langst01.xlsx")

 
save "../08_temp/census1961_st_mothertongue", emptyok replace

local states an ap as br dn gj hp ke kt lm mh mn mp ng or pn rj tn tr wb

foreach st of local states {
	import excel using "../01_data/census_1961_st_language_tables/`st'61langst01.xlsx", firstrow case(lower) clear
	foreach var of varlist subsidiary_speakers_* sl_* {
		capture replace `var' = "0" if `var' == "nil"
		}
	destring subsidiary_speakers_* sl_*, ignore("xXN") replace
	capture drop ?
	capture drop ??
	dis as err "Appending the parent file to the file for state `st'..."
	append using "../08_temp/census1961_st_mothertongue"
	save "../08_temp/census1961_st_mothertongue", replace
}

replace state = trim(state)
replace district = trim(district)
replace tribe = trim(tribe)

*replace district = subinstr(district," district","",1)

replace mothertongue= trim(itrim(mothertongue))

drop if state== "" & district == ""

**replace tribe = "all tribes" if strpos(state,"laccadive")>0

compress

save "../08_temp/census1961_st_mothertongue", replace

project , creates("../08_temp/census1961_st_mothertongue.dta")
