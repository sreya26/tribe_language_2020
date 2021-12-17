************************************************************************************************************************
* this file puts together the DISE data for 2013-14 to use in the tribelanguage paper
* the main variable of interest from DISE is the medium of instruction in school
* that variable is found in the "General Data" files, but to identify the location of the school, 
* we also need the "Basic Data" files
************************************************************************************************************************

project , relies_on("../01_data/dise_data/RawDataDescription.pdf")
project , relies_on("../01_data/dise_data/UDCF_2013-14.pdf")
project , relies_on("../01_data/dise_data/UDISE_DCF_Description_2013-14.pdf")

local states AN AP AR AS BR CG CH DD DL DN GA GJ HP HR JH JK KE KT LK MG MH MN MP MZ NG OR PN PY RJ SK TN TR UA UP WB

foreach state of local states {
	project , original("../01_data/dise_data/2013-14 General Data/DISE_General_Data_`state'_2013-14.xlsx")
	project , original("../01_data/dise_data/2013-14 Basic Data/DISE_Basic_Data_`state'_2013-14.xlsx")
}

tempfile dise_general dise_basic

save `dise_general', emptyok
save `dise_basic', emptyok

foreach state of local states {
	import excel using "../01_data/dise_data/2013-14 General Data/DISE_General_Data_`state'_2013-14.xlsx", firstrow case(lower) clear
	gen state = "`state'"
	tempfile statefile
	save `statefile'
	use `dise_general', clear
	append using `statefile'
	save `dise_general', replace
	clear
	noi dis "Saved General data file for `state'..."
	}

use `dise_general', clear
destring _all, replace
save `dise_general', replace


foreach state of local states {
	import excel using "../01_data/dise_data/2013-14 Basic Data/DISE_Basic_Data_`state'_2013-14.xlsx", firstrow case(lower) clear
	gen state = "`state'"
	tempfile statefile
	save `statefile'
	use `dise_basic', clear
	append using `statefile'
	save `dise_basic', replace
	clear	
	noi dis "Saved Basic data file for `state'..."
	}

use `dise_basic', clear
destring _all, replace
rename school_code schcd
merge 1:1 schcd using `dise_general'

noi tab _merge // only 179 observations do not merge
keep if _merge == 3
drop _merge

rename schcd school_code
order state distname block_name cluster_name village_name pincode school_code school_name

capture label drop _all

#delimit ;
label define RURURB
	1 "Rural"
	2 "Urban"
	;

label var rururb "School is located in rural or urban area" ;

label values rururb RURURB ;

label define MEDINSTR1
	1 "Assamese"
	2 "Bengali"
	3 "Gujarati"
	4 "Hindi"
	5 "Kannada"
	6 "Kashmiri"
	7 "Konkani"
	8 "Malayalam"
	9 "Manipuri"
	10 "Marathi"
	11 "Nepali"
	12 "Oriya"
	13 "Punjabi"
	14 "Sanskrit"
	15 "Sindhi"
	16 "Tamil"
	17 "Telugu"
	18 "Urdu"
	19 "English"
	20 "Bodo"
	21 "Mising"
	22 "Dogri"
	23 "Khasi"
	24 "Garo"
	25 "Mizo"
	26 "Bhutia"
	27 "Lepcha"
	28 "Limboo"
	29 "French"
	99 "Others"
	;

label var medinstr1 "Medium of instruction" ;
label values medinstr1 MEDINSTR1 ;

label var disthq "Distance (in km) from primary to nearest govt / govt aided upper primary school" ;

label var distcrc "Distance (in km) from upper primary to nearest govt / govt aided secondary school" ;

label var estdyear "Year of establishment of school" ;

label define LOGICAL
	1 "Yes"
	2 "No"
	;

label var ppsec_yn "Pre-primary section (other than Anganwadi) attached to school" ;
label values ppsec_yn LOGICAL ;

label var schres_yn "Is the school residential?" ;
label values schres_yn LOGICAL ;

label define SCHMGT
	1 "Department of Education"
	2 "Tribal/Social Welfare Department"
	3 "Local body"
	4 "Pvt. Aided"
	5 "Pvt. Unaided"
	6 "Others"
	7 "Central Government"
	8 "Unrecognised"
	97 "Madarsa recognized (by Wakf board / Madarsa Board"
	98 "Madarsa unrecognized"
	;

label var schmgt "Managed by (school management)" ;
label values schmgt SCHMGT ;

label var lowclass "Lowest class in school" ;
label var highclass "Highest class in school" ;

label define SCHCAT
	1 "Primary only (1-5)"
	2 "Primary with Upper Primary (1-8)"
	3 "Primary with upper primary and secondary and higher secondary (1-12)"
	4 "Upper primary only (6-8)"
	5 "Upper primary with secondary and higher secondary (6-12)"
	6 "Primary with upper primary and secondary (1-10)"
	7 "Upper primary with secondary (6-10)"
	8 "Secondary only (9 & 10)"
	10 "Secondary with higher secondary (9-12)"
	11 "Higher secondary only / Junior college (11 & 12)"
	;

label var schcat "School category" ;
label values schcat SCHCAT ;

label var ppstudent "Total students: Pre-primary section (other than Anganwadi) attached to school" ;

label define SCHTYPE
	1 "Boys"
	2 "Girls"
	3 "Co-educational"
	;

label var schtype "Type of school" ;
label values schtype SCHTYPE ;

label var schshi_yn "Is the school a shift school?" ;
label values schshi_yn LOGICAL ;

label var workdays "Number of instructional days (previous academic year)" ;

label var noinspect "Number of academic inspections" ;

label define RESITYPE
	1 "Ashram (Government)"
	2 "Non-Ashram type (Government)"
	3 "Private"
	4 "Others"
	5 "Not Applicable"
	6 "Kasturba Gandhi Balika Vidyalaya (KGBV)"
	7 "Model School"
	;
	
label var resitype "Type of residential school" ;
label values resitype RESITYPE ;

label var ppteacher "Total teachers: Pre-primary section (other than Anganwadi) attached to school" ;
label var visitsbrc "Number of visits by Block level officer (last academic year)" ;
label var visitscrc "Number of visits by CRC coordinators (last academic year)" ;
label var conti_r "School development grant receipt (under SSA) : last completed financial year" ;
label var conti_e "School development grant expenditure (under SSA) : last completed financial year" ;
label var tlm_r "TLM/Teachers grant receipt (under SSA) : last completed financial year" ;
label var tlm_e "TLM/Teachers grant expenditure (under SSA) : last completed financial year" ;
label var funds_r "Funds from other sources receipts : last completed financial year" ;
label var funds_e "Funds from other sources expenditures : last completed financial year" ;

#delimit cr

compress

save "../08_temp/dise_basic_general", replace

project , creates("../08_temp/dise_basic_general.dta")
