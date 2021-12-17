
local statefiles: dir "../01_data/dise_data/2013-14 Enrolment and Repeaters Data" files "*.xlsx"
local distdirs: dir "../01_data/dise_data/2013-14 Enrolment and Repeaters Data" dir "??"
local distdirs: list clean distdirs

save "../08_temp/dise_enrollment", emptyok replace

foreach file of local statefiles {
	project , original("../01_data/dise_data/2013-14 Enrolment and Repeaters Data/`file'")
	import excel using "../01_data/dise_data/2013-14 Enrolment and Repeaters Data/`file'", firstrow case(lower) clear
	keep schcd ??_t? ??_tot?
	gen filename = "`file'"
	append using "../08_temp/dise_enrollment"
	noi dis as text "Appended `file'"
	save "../08_temp/dise_enrollment", replace	
}

foreach dis of local distdirs {
	local distfiles: dir "../01_data/dise_data/2013-14 Enrolment and Repeaters Data/`dis'" files "*.xlsx"
		foreach file of local distfiles {
			project , original(`"../01_data/dise_data/2013-14 Enrolment and Repeaters Data/`dis'/`file'"')
			import excel using `"../01_data/dise_data/2013-14 Enrolment and Repeaters Data/`dis'/`file'"', firstrow case(lower) clear
			keep schcd ??_t? ??_tot?
			gen filename = "`file'"
			append using "../08_temp/dise_enrollment"
			noi dis as text "Appended `file' of state `dis'"
			save "../08_temp/dise_enrollment", replace
			}
	}


use "../08_temp/dise_enrollment", clear
destring c*, replace
duplicates tag schcd, gen (tag)
drop if tag==1 & strpos(filename,"Janjgir")>0 //There is one school in Janjgir Champa district of CG which is not there in the school level file. We therefore keep just that school and drop all other schools which are there in the state file already.
drop tag

egen enroll_tot = rowtotal(c?_tot?)
egen enroll_primary_tot = rowtotal(c1_tot? c2_tot? c3_tot? c4_tot? c5_tot?)
egen enroll_secondary_tot = rowtotal(c6_tot? c7_tot? c8_tot?)

egen enroll_tot_st = rowtotal(c?_t?)
egen enroll_primary_st = rowtotal(c1_t? c2_t? c3_t? c4_t? c5_t?)
egen enroll_secondary_st = rowtotal(c6_t? c7_t? c8_t?)

drop c?_t? c?_tot?

compress

save "../08_temp/school_enrollment", replace

project , creates("../08_temp/dise_enrollment.dta")
project , creates("../08_temp/school_enrollment.dta")
