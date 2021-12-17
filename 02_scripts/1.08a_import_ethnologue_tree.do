******************************************************************************************************************************************
* this file imports languages from the excel file with the Ethnologue tree, in preparation for merging with census 1961 mothertongue data
*! version 1.0 created by Hemanshu Kumar on 11 July 2020
* this is the first version to comply with Robert Picard's -project- command
* it is also the first version to update the Ethnologue tree to edition 23 
* Eberhard, David M., Gary F. Simons, and Charles D. Fennig (eds.) 2020. Ethnologue: Languages of the World. ed. 23. Dallas, Texas: SIL International.
******************************************************************************************************************************************
local ethnologue_file "../01_data/ethnologue_data/20201023 Ethnologue Language Tree.xlsx"

project , original("`ethnologue_file'")

import excel using "`ethnologue_file'", firstrow clear case(lower) sheet("Dravidian")
tempfile Dravidian
save `Dravidian'

import excel using "`ethnologue_file'", firstrow clear case(lower) sheet("Indo-European")
drop if level1 == ""
tempfile IndoEuropean
save `IndoEuropean'

import excel using "`ethnologue_file'", firstrow clear case(lower) sheet("Kra-Dai")
drop if level1 == ""
tempfile KraDai
save `KraDai'

import excel using "`ethnologue_file'", firstrow clear case(lower) sheet("Sino-Tibetan")
drop if level1 == ""
tempfile SinoTibetan
save `SinoTibetan'

import excel using "`ethnologue_file'", firstrow clear case(lower) sheet("Austro-Asiatic")
drop if level1 == ""
tempfile AustroAsiatic
save `AustroAsiatic'

import excel using "`ethnologue_file'", firstrow clear case(lower) sheet("Andamanese")
drop if level1 == ""
tempfile Andamanese
save `Andamanese'

import excel using "`ethnologue_file'", firstrow clear case(lower) sheet("Afro-Asiatic")
drop if level1 == ""
tempfile AfroAsiatic
save `AfroAsiatic'

import excel using "`ethnologue_file'", firstrow clear case(lower) sheet("Japonic")
drop if level1 == ""
tempfile Japonic
save `Japonic'

import excel using "`ethnologue_file'", firstrow clear case(lower) sheet("Creole")
drop if level1 == ""
tempfile Creole
save `Creole'

import excel using "`ethnologue_file'", firstrow clear case(lower) sheet("Isolate")
drop if level1 == ""
tempfile Isolate
save `Isolate'

import excel using "`ethnologue_file'", firstrow clear case(lower) sheet("Unclassified")
drop if level1 == ""
tempfile Unclassified
save `Unclassified'


use `Dravidian', clear
append using `IndoEuropean'
append using `KraDai'
append using `SinoTibetan'
append using `AustroAsiatic'
append using `Andamanese'
append using `AfroAsiatic'
append using `Japonic'
append using `Creole'
append using `Isolate'
append using `Unclassified'

forval i=1/10 {
	replace level`i' = trim(itrim(level`i'))
	encode level`i', gen(numeric_level`i') label(LEVELS)
}

tempvar language
egen `language' = rowlast(numeric_level*)
label values `language' LEVELS
egen lang_depth = rownonmiss(numeric_level*)

decode `language', gen(language)

gen level0 = "All Languages"

drop numeric_* `language'

drop if language == "Marwari" & strpos(comments,"Pakistan")>0 // drops the Pakistani version of Marwari
drop if language == "Naga, Tangkhul" & strpos(comments,"Myanmar")>0 // drops the Burmese version of Tangkhul
drop comments

label var iso "ISO 639-3 Language Code"
///noi distinct language
order language iso lang_depth level0

save "../08_temp/ethnologue_tree", replace

project , creates("../08_temp/ethnologue_tree.dta")

