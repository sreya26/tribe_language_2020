import excel "/Users/sreyamajumder/Dropbox/sreya_majumder/tribelanguage_2020 sreya/03_processed_sreya/census 1961-2011 scheduled tribe list with tribe groups.xlsx", sheet("Sheet1") firstrow clear
*(16 vars, 1,460 obs)

count if castegroup_1961_2011 != castegroup_appended
//111


use "/Users/sreyamajumder/Dropbox/sreya_majumder/tribelanguage_2020 sreya/08_temp/st_groups_with_states_1961_2011.dta", clear

drop castegroup_1961_2011 castegroup_1961_code
rename castegroup_appended castegroup_1961_2011
replace caste_updated = proper(caste_updated)

merge 1:1 state caste_code caste_updated castegroup_1961_2011 using "/Users/sreyamajumder/Dropbox/sreya_majumder/tribelanguage_2020 sreya/08_temp/st_groups_with_states_1961_2011_method3.dta", gen(_merged_groups) // all matched 



sort castegroup_1961_2011
by castegroup_1961_2011: egen exception_2011 = min(year)
distinct castegroup_1961_2011 if exception_2011 == 2011

by castegroup_1961_2011: egen exception_1961 = max(year)
distinct castegroup_1961_2011 if exception_1961 == 1961
