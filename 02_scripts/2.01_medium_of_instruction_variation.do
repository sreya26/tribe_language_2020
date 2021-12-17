project , uses("../03_processed/dise_basic_general_with_regions.dta")
project , uses("../03_processed/census_1961_mothertongue_for_analysis_distance.dta")

project , relies_on("../01_data/census_2011_overall_language_tables/DDW-C16-STMT-MDDS-0000.XLSX")
************************************************************************************************************************
* Table on variation in medium of instruction
************************************************************************************************************************

capture program drop set_dominant_language
program define set_dominant_language

	capture confirm new var state_dise
	if _rc == 0 {
		gen state_dise = state_1961
		replace state_dise = "Lakshadweep" if strpos(state_1961,"Lacca")
		replace state_dise = "Chhattisgarh" if inlist(regionname6113,"Surguja","Bilaspur, Durg", "Raigarh", "Raipur", "Bastar")
		replace state_dise = "Jharkhand" if inlist(regionname6113,"Santal Parganas", "Palamau", "Dhanbad, Hazaribagh", "Ranchi", "Singhbhum")
		replace state_dise = "Meghalaya" if inlist(regionname6113,"Garo Hills","United Khasi And Jaintia Hills")
		replace state_dise = "Mizoram" if regionname6113 == "Mizo Hills"
		replace state_dise = "Karnataka" if state_1961 == "Mysore"
		replace state_dise = "Tamil Nadu" if state_1961 == "Madras"
		replace state_dise = "Odisha" if state_1961 == "Orissa"
	}
	
	gen dominant_language = 4 if inlist(state_dise,"Himachal Pradesh","Bihar","Madhya Pradesh","Rajasthan","Chhattisgarh","Jharkhand","Andaman & Nicobar Islands") // Hindi
	replace dominant_language = 17 if state_dise == "Andhra Pradesh" // Telugu
	replace dominant_language = 1 if state_dise == "Assam" // Assamese
	replace dominant_language = 3 if inlist(state_dise,"Gujarat","Dadra and Nagar Haveli") // Gujarati
	replace dominant_language = 8 if inlist(state_dise,"Kerala","Lakshadweep") // Malayalam
	replace dominant_language = 16 if state_dise == "Tamil Nadu" // Tamil
	replace dominant_language = 10 if state_dise == "Maharashtra" // Marathi
	replace dominant_language = 2 if inlist(state_dise,"Tripura","West Bengal") // Bengali
	replace dominant_language = 9 if state_dise == "Manipur" // Manipuri
	replace dominant_language = 5 if state_dise == "Karnataka" // Kannada
	replace dominant_language = 19 if inlist(state_dise,"Nagaland","Meghalaya") // English
	replace dominant_language = 12 if state_dise == "Odisha" // Oriya 
	replace dominant_language = 25 if state_dise == "Mizoram" // Mizo
end



	use "../03_processed/dise_basic_general_with_regions", clear

	keep state_dise region6113 regionname6113 medinstr1

	set_dominant_language
	
	label values dominant_language MEDINSTR1

	gen num_schools = 1

	collapse (count) num_schools, by(state_dise region6113 dominant_language medinstr1)

	egen all_schools = total(num_schools), by(state_dise region6113)
	gen perc = (num_schools/all_schools) * 100

	keep if medinstr1 == dominant_language | medinstr1 == "English":MEDINSTR1

	gen perc_english_temp = perc if medinstr1 == "English":MEDINSTR1
	gen perc_dominant_temp = perc if medinstr1 == dominant_language

	egen perc_dominant = max(perc_dominant_temp), by(state_dise region6113)
	egen perc_english = max(perc_english_temp), by(state_dise region6113)

	duplicates drop state_dise region6113, force

	drop *_temp medinstr1 perc num_schools
	drop if dominant_language == .
	* drop if inlist(state,"HR")
	gen perc_others = 100 - perc_dominant - perc_english
	replace perc_others = 100 - perc_dominant if dominant_language == "English":MEDINSTR1

	format %3.0f perc*

	rename perc_* *
	rename dominant_language dominant_lang
 
	collapse (mean) dominant_mean = dominant english_mean = english others_mean = others ///
		(min) dominant_min = dominant english_min = english others_min = others ///
		(max) dominant_max = dominant english_max = english others_max = others [aw = all_schools], ///
		by(state_dise dominant_lang)

	foreach var of varlist *_mean *_min *_max {
		replace `var' = -1 * `var' if `var' < 0
		}
		
	tempfile medinstr
	save `medinstr'

	* now we import information on fraction of STs who use the dominant language as mother tongue in 1961

	use "../03_processed/census_1961_mothertongue_for_analysis_distance", clear
	drop if language == "all mother tongues" | castegroup_1961_2011_code == 0 | is_state
	egen total_speakers = rowtotal(total_speakers_?)
	keep state_1961 region6113 regionname6113 castegroup_1961_2011_code language_ethnologue total_speakers dominant_language
	rename dominant_language dominant_language_str
	set_dominant_language
	egen total_st = sum(total_speakers), by(state_dise)
	tempvar total_dominant
	egen `total_dominant' = sum(total_speakers) if language_ethnologue == dominant_language_str, by(state_dise)
	egen total_dominant = max(`total_dominant'), by(state_dise)
	replace total_dominant = 0 if missing(total_dominant)	
	gen dominant_speaker_perc = total_dominant/total_st*100
	format dominant_speaker_perc %3.0f
	duplicates drop state_dise, force
	keep state_dise dominant_speaker_perc
	sort state_dise
	
	tempfile dominant_speakers
	save `dominant_speakers'
	
	use `medinstr', clear
	merge 1:1 state_dise using `dominant_speakers', assert(match) nogen


	replace state_dise = "Andaman and Nicobar Is." if state_dise == "Andaman & Nicobar Islands"
	#delimit ;
	listtab state_dise dominant_lang dominant_speaker_perc dominant_mean english_mean others_mean 
		using "../04_results/01_tables/1_medium_of_instruction_variation.tex", rstyle(tabular) replace
		head(`"\begin{threeparttable}[htbp]\centering \caption{Use of official state language by the Scheduled Tribes}\label{tab:medium_of_instruction_variation}"' 
		`"\begin{tabular}{llrrrr}\\"' `"\toprule"' 
		`"& \multicolumn{2}{c}{Use of official language by STs} & \multicolumn{3}{c}{Medium of Instruction} \\"'
		`" \cmidrule(lr){2-3} \cmidrule(lr){4-6}"'
		`"State/UT 			& Language 	& Mother Tongue	&	Dominant & English	& Others\\"'
		`"					& 			& \multicolumn{1}{c}{(\% of STs)} & \multicolumn{3}{c}{(\% of schools)} \\ "'
		`" \midrule "' )
		foot(`"\bottomrule"' `"\end{tabular}"' 
		`"\begin{tablenotes}[flushleft, online, normal, para]\scriptsize"'
		`"\emph{Source:} Medium of instruction from District Information System for Education (DISE), 2013-14. Mother tongue data from Census 1961. \\"'
		`"Notes: \\"'
/*		`"1. Dominant language refers to the state's official language, as reported in \citet{clm:2016a}."' */
		`"1. The states of Goa, Haryana, Punjab, Jammu \& Kashmir, Uttar Pradesh, Uttarakhand, as well as the NCT of Delhi, and the union territories of Chandigarh, Daman \& Diu, and Puducherry, are all excluded from the table since they did not have any tribes scheduled in 1961. The state of Arunachal Pradesh has been excluded because only a partial census was conducted in that region in 1961. \\"'
		`"2. In a few small states and union territories (Andaman and Nicobar Is., Dadra and Nagar Haveli, Mizoram and Tripura), there are multiple official languages, in which case we pick the one most widely spoken, as per Census 2011 data (Tables C-16). \\"'
		`"3. The mother tongue column uses Census 1961 data to compute the percentage of Scheduled Tribes who reported the dominant language as their mother tongue. \\"'
		`"\end{tablenotes}"' `"\end{threeparttable}"' )
		;
	#delimit cr

	
	project , creates("../04_results/01_tables/1_medium_of_instruction_variation.tex")
