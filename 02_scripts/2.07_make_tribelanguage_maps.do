project , uses("../03_processed/census_1961_mothertongue_for_analysis_distance.dta")

*********************************************************************************************************
* this code creates a map for the language paper (Hemanshu Kumar, Tarun Jain, and Rohini Somanathan)
*! version 1.0 created by Hemanshu Kumar on 28 July 2020
* an earlier version of this code was used to create maps used for the Helsinki poster and
* also for the paper versions till 2018
* this version uses an underlying Census 2011 district map to create consistent regions
*********************************************************************************************************

	*********************************************************************************************************
	* 1. export a CSV file linking census 2011 districts to consistent regions, to help create a shapefile with QGIS 
	*********************************************************************************************************

	project, do("2.07a_export_regions.do")

	*********************************************************************************************************
	* 2. get shape databases from the newly created shapefile 
	*********************************************************************************************************

	project , do("2.07b_get_shape_data.do")
	
	*********************************************************************************************************
	* 3. compute the number of STs who speak the dominant language in every region (that is not a state)  
	*********************************************************************************************************
	
	use "../03_processed/census_1961_mothertongue_for_analysis_distance", clear

	keep if is_state == 0 & castegroup_1961_2011_code == 500

	keep if language == "all mother tongues" | lang_distance_f8_dominant == 0

	egen total_speakers_p = rowtotal(total_speakers_m total_speakers_f)

	tempvar region_st_pop

	gen `region_st_pop' = total_speakers_p if language == "all mother tongues"

	egen region_st_pop = max(`region_st_pop'), by(region6113)

	* there are regions where there are no speakers of the dominant language
	* to prevent these from dropping out, we need to create an observation with 0 speakers of the dominant language

	expand 2 if language == "all mother tongues", gen(dummy_lang)
	replace language = dominant_language if dummy_lang
	replace total_speakers_p = 0 if dummy_lang 

	drop if language == "all mother tongues"

	collapse (sum) total_speakers_p (max) region_st_pop, by(region6113 regionname6113 dominant_language)
	rename total_speakers_p dominant_speakers_p

	gen dominant_frac = dominant_speakers_p/region_st_pop
	format dominant_frac %3.2f

	tempfile st_lang_frac
	save `st_lang_frac'
	

	*********************************************************************************************************
	* 4. create a map  
	*********************************************************************************************************

	use "../03_processed/indregionsbasemap6113", clear
	rename census_201 region6113
	rename census_2_1 regionname6113

	merge m:1 region6113 using `st_lang_frac', keepusing(dominant_frac dominant_language) assert(master match)

	replace dominant_frac = .a if _merge == 1
	label define DOMINANT_FRAC .a "N.A."
	label values dominant_frac DOMINANT_FRAC

	drop _merge


	#delimit ;
	spmap dominant_frac using "../03_processed/indregionscoord6113" ,
	/*	caption(`"Fraction of Scheduled Tribes who speak the dominant language"', pos(12))*/
		id(id)
		osize(vthin ...) ndsize(vthin ...)
		fcolor(RdYlBu)
		clmethod(eqint)
		clnumber(10)
		ndlabel("N.A.")
		legstyle(2)
		legend(pos(7) ring(0))
		legorder(hilo)
		note("Consistent regions, Census 1961 - DISE 2013-14", pos(7))
		name(st_language, replace)
		;
	#delimit cr  

	graph export "../04_results/02_figures/st_language_6113.pdf", replace name(st_language)

	project , creates("../04_results/02_figures/st_language_6113.pdf")
	
/*	
*** map of ST distribution

use census_1961_mothertongue_for_analysis_distance, clear
keep if castegroup_2001_code == 0 & language == "all mother tongues" & ~is_state
drop if region6000 == 25 & dominant_language == "Punjabi, Eastern" // two observations for Chamba, Gurdaspur, Lahaul, Spiti area; retain the one which has Hindi as dominant language
egen st_pop = rowtotal(total_speakers_m total_speakers_f)
keep region6000 st_pop
tempfile st_pops
save `st_pops'
 
use all_regions_60_00, clear
merge m:1 dcode60 using census60, keepusing(pop60)
drop if mod(dcode00,100) == 0 // drop the state-level observations
duplicates drop dcode60, force
collapse (sum) pop60, by(region6000 regionname6000)

merge 1:1 region6000 using `st_pops'
replace st_pop = 0 if _merge == 1
drop _merge
gen st_frac = st_pop/pop60
format st_frac %3.2f
format st_pop %11.0fc

tempfile st_pop_frac
save `st_pop_frac'

use indregionsbasemap, clear
destring CODE01, replace
rename CODE01 dcode00
rename regions_tr region6000
rename regions__1 regionname6000
drop regions__?

merge m:1 region6000 using `st_pop_frac', keepusing(st_frac st_pop)

replace st_pop = .a if _merge == 1
replace st_frac = .a if _merge == 1

replace st_pop = .b if inlist(STATE,"ARUNACHAL","GOA","SIKKIM","JAMMU & KASHMIR")
replace st_frac = .b if inlist(STATE,"ARUNACHAL","GOA","SIKKIM","JAMMU & KASHMIR")

replace st_pop = .c if st_frac == 0
replace st_frac = .c if st_frac == 0

label define st_lab .a "No data" .b "No data" .c "no STs in 1961"
label values st_pop st_frac st_lab

assert inlist(_merge,1,3)
drop _merge

replace st_pop = st_pop/1000

#delimit ;
spmap st_pop using indregionscoord ,
/*	caption(`"Population of Scheduled Tribes, Census 1961"', pos(12))*/
	id(id)
	osize(vthin ...) ndsize(vthin ...)
	fcolor(Blues2)
	clmethod(custom)
	clbreaks(0(150)1350)
	ndlabel("No STs in 1961")
	legstyle(2)
	legtitle("In '000s:")
	legend(pos(7) ring(0))
	legorder(hilo)
	note("Consistent regions, Census 1961-2001", pos(7))
	name(st_pop, replace)
	;
#delimit cr

graph export st_pop.pdf, replace name(st_pop)
 
#delimit ;
spmap st_frac using indregionscoord ,
/*	caption(`"Fraction of Scheduled Tribes in the population"', pos(12))*/
	id(id)
	osize(vthin ...) ndsize(vthin ...)
	fcolor(Heat)
	clmethod(eqint)
	clnumber(10)
	ndlabel("No STs in 1961")
	legstyle(2)
	legend(pos(7) ring(0))
	legorder(hilo)
	note("Consistent regions, Census 1961-2001", pos(7))
	name(st_pop_frac, replace)
	;
#delimit cr

graph export st_pop_frac.pdf, replace name(st_pop_frac)

*****************
* medium of instruction vs dominant language

global tribelang_workdir "/Volumes/Data and Documents/Dropbox/Current Work/tribelanguage/tribelanguage shared/Work Data"

use "$tribelang_workdir/dise_basic_general_with_region6000", clear

	keep state60 region6000 regionname6000 medinstr1

	gen dominant_language = 4 if inlist(state60,"Himachal Pradesh","Bihar","Madhya Pradesh","Rajasthan","Uttar Pradesh","Delhi") // Hindi
	replace dominant_language = 13 if state60 == "Punjab" // Punjabi
	replace dominant_language = 17 if state60 == "Andhra Pradesh" // Telugu
	replace dominant_language = 1 if state60 == "Assam" // Assamese
	replace dominant_language = 3 if inlist(state60,"Gujarat","Dadra And Nagar Haveli") // Gujarati
	replace dominant_language = 8 if inlist(state60,"Kerala","Laccadive, Minicoy And Amindivi Islands") // Malayalam
	replace dominant_language = 16 if state60 == "Madras" // Tamil
	replace dominant_language = 10 if state60 == "Maharashtra" // Marathi
	replace dominant_language = 2 if inlist(state60,"Tripura","West Bengal","Andaman & Nicobar Islands") // Bengali
	replace dominant_language = 9 if state60 == "Manipur" // Manipuri
	replace dominant_language = 5 if state60 == "Mysore" // Kannada
	replace dominant_language = 19 if inlist(state60,"Nagaland","North East Frontier Agency") // English
	replace dominant_language = 12 if state60 == "Orissa" // Oriya 
	replace dominant_language = 6 if state60 == "Jammu & Kashmir" // Kashmiri
	replace dominant_language = 11 if state60 == "Sikkim" // Nepali
	replace dominant_language = 7 if state60 == "Goa, Daman And Diu" // Konkani
	label values dominant_language MEDINSTR1

	gen num_schools = 1

*	drop if state60 == "Punjab"
	
	collapse (count) num_schools, by(region6000  regionname6000 dominant_language medinstr1)

	egen all_schools = total(num_schools), by(region6000  regionname6000)
	gen frac = num_schools/all_schools

	keep if medinstr1 == dominant_language | medinstr1 == "English":MEDINSTR1

	gen frac_english_temp = frac if medinstr1 == "English":MEDINSTR1
	gen frac_dominant_temp = frac if medinstr1 == dominant_language

	egen frac_dominant = max(frac_dominant_temp), by(region6000 regionname6000)
	egen frac_english = max(frac_english_temp), by(region6000  regionname6000)

	replace frac_dominant = 0 if regionname6000 == "Mizo Hills" | dominant_language == 6
	
	duplicates drop region6000, force

	keep region6000 frac_dominant dominant_language
	format frac_dominant %3.2f
	
	tempfile school_lang
	save `school_lang'
	
	use indregionsbasemap, clear
	destring CODE01, replace
	rename CODE01 dcode00
	rename regions_tr region6000
	rename regions__1 regionname6000
	drop regions__?

	merge m:1 region6000 using `school_lang'

	#delimit ;
	spmap frac_dominant using indregionscoord ,
	/*	caption(`"Fraction of Schools where Teaching is in Dominant Language"', pos(12))*/
		id(id)
		osize(vthin ...) ndsize(vthin ...)
		fcolor(Blues2)
		clmethod(eqint)
		clnumber(10)
		ndlabel("No data")
		legstyle(2)
		legend(pos(7) ring(0))
		legorder(hilo)
		note("Consistent regions, Census 1961-2001", pos(7))
		name(school_language, replace)
		;
#delimit cr

graph export school_language.pdf, replace name(school_language)

	
