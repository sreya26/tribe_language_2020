

******************************************************************************************************************************************
* this file identifies tribal (ST) groups across India using a [mostly] automated method
* the work is first done for Census 2011, and then the same groups are used for Census 1961
* dated: July 2020 
******************************************************************************************************************************************
project, original ("../01_data/scheduled tribes list/census 1961 scheduled tribe list.xlsx") 
project , uses("../08_temp/st_2011_state_pops.dta")
project , uses("../08_temp/census1961_st_religion_distcoded.dta")

******************************************************************************************************************************************
* 1. define a program to clean up the tribe names
******************************************************************************************************************************************
capture program drop clean_tribe
program define clean_tribe
	syntax varname(string) , GENerate(name)
	
	confirm new var `generate'
	
	gen `generate' = `varlist'	
	replace `generate' = trim(itrim(lower(`generate')))
	
	*********************************************************************************************************************
	* 1.1 things to remove:
	*********************************************************************************************************************
	
	local roman i ii iii iv v vi vii viii ix x xi xii xiii xiv xv xvi xvii xviii xix xx ///
				xxi xxii xxiii xxiv xxv xxvi xxvii xxviii xxix xxx xxxi xxxii xxxiii xxxiv xxxv xxxvi xxxvii
	foreach numeral of local roman {
		local str = "(`numeral')"
		replace `generate' = subinstr(`generate',"`str'",",",.)
		}
	
	replace `generate' = subinstr(`generate',"; ,",",",.)
	replace `generate' = subinstr(`generate',"*","",.)
	replace `generate' = subinstr(`generate',"/",",",.)
	replace `generate' = subinstr(`generate',", including the following sub-tribes:",", ",1)
	replace `generate' = subinstr(`generate'," including:",", ",1)
	replace `generate' = subinstr(`generate',"(including ",", ",1)
	replace `generate' = subinstr(`generate',"including ",", ",1)
	replace `generate' = subinstr(`generate'," etc."," ",.)	
	replace `generate' = subinstr(`generate'," in cachar","",1)
	replace `generate' = subinstr(`generate'," -","-",.)	
	replace `generate' = subinstr(`generate',"- ","-",.)
	
	*********************************************************************************************************************
	* 1.2 remove everything to the right of:
	*********************************************************************************************************************	
	tempvar excludepos
	gen `excludepos' = strpos(`generate',"excluding")
	replace `generate' = substr(`generate', 1, `excludepos'-2) if `excludepos' > 0
	replace `excludepos' = strpos(`generate',"(in ")
	replace `generate' = substr(`generate', 1, `excludepos'-1) if `excludepos' > 0
	replace `excludepos' = strpos(`generate',"[in ")
	replace `generate' = substr(`generate', 1, `excludepos'-1) if `excludepos' > 0
	replace `excludepos' = strpos(`generate',"(to be spelt")
	replace `generate' = substr(`generate', 1, `excludepos'-2) if `excludepos' > 0
	replace `excludepos' = strpos(`generate',"(tai speaking")
	replace `generate' = substr(`generate', 1, `excludepos'-2) if `excludepos' > 0
	replace `excludepos' = strpos(`generate', " minicoy")
	replace `generate' = substr(`generate', 1, `excludepos'-1) if `excludepos' > 0
	replace `excludepos' = strpos(`generate', " abor, aka, apatani, dafla, galong, khampti, khowa,mishmi, momba, naga tribes (any), sherdukpen, singpho")
	replace `generate' = substr(`generate', 1, `excludepos'-2) if `excludepos' > 0
	replace `excludepos' = strpos(`generate', " abor, aka, apatani, dafla, galong, khampti, khowa, mishmi, momba, naga tribes (any), sherdukpen and singpho")
	replace `generate' = substr(`generate', 1, `excludepos'-2) if `excludepos' > 0
	
	*********************************************************************************************************************
	* 1.3 remove parentheses
	*********************************************************************************************************************	
	
	replace `generate' = subinstr(`generate',"("," ",.)
	replace `generate' = subinstr(`generate',")"," ",.)

	*********************************************************************************************************************
	* 1.4 replace conjunctions etc with commas
	*********************************************************************************************************************		

	replace `generate' = subinstr(`generate', " and ", "," ,.)
	replace `generate' = subinstr(`generate', " or ", "," ,.)

	*********************************************************************************************************************
	* 1.5 sort out commas
	*********************************************************************************************************************		
	
	replace `generate' = trim(itrim(`generate'))
	replace `generate' = subinstr(`generate'," ,",",",.)
	replace `generate' = subinstr(`generate',", ,",", ",.)
	replace `generate' = subinstr(`generate',",,",", ",.)

	replace `generate' = trim(itrim(`generate'))
	replace `generate' = substr(`generate',2,.) if substr(`generate',1,1) == "," // should not start with comma
	replace `generate' = substr(`generate',1,length(`generate')-1) if substr(`generate',-1,1) == "," // should not end with comma	
end


******************************************************************************************************************************************
* 2. now we create a program that will do most of the work of creating tribe groups 
******************************************************************************************************************************************

capture program drop create_tribe_groups
program define create_tribe_groups
	syntax, CASTEvar(varname string) STATEvar(varname string) POPvar(varname numeric) GENGROUPvar(name) GENSYNonymvar(name)
	
	confirm new var `gengroupvar' `gensynonymvar'
	
	tempvar sort_order
	gen `sort_order' = _n
	
	tempvar tribe
	clonevar `tribe' = `castevar'

	split `tribe', p(, ; :) gen(_split_)
	ds _split_*
	local numsplits: word count `r(varlist)'

	tempvar first_name
	
	forvalues i=1/`numsplits' {
		replace _split_`i' = trim(itrim(_split_`i'))
		if `i'==1 gen `first_name' = _split_1
		replace _split_`i' = subinstr(_split_`i',"-","_",.)
		replace _split_`i' = trim(itrim(_split_`i'))
		replace _split_`i' = subinstr(_split_`i'," ","_",.)
		replace _split_`i' = trim(itrim(_split_`i'))
	}
		
	tempvar tribewords
	egen `tribewords' = concat(_split_*), punct(" ") // each synonym is space-separated; synonyms are "words", i.e. have no spaces within them
	drop _split_*

	* SYNONYMS: these don't get automatically picked up by the program (mainly due to spelling differences) and are manually put in

	local group1 any_mizo_lushai_tribe any_mizo_lushai_tribes mizo_lushai_tribes_any lushai //
	local group2 any_naga_tribes naga_tribes_any naga kacha_naga poumai_naga //
	local group3 bhot jad
	local group4 boro boro_kacharis boro_borokachari
	local group5 dimasa_kachari kachari
	local group6 gadaba gadabas
	local group7 gond kotia_bentho_oriya kotia koya pardhan
	local group8 garo garoo
	local group9 jannsari jaunsari
	local group10 kochuvelan kochu_velan
	local group11 kol kol_dahait
	local group12 kolah_loharas kolah_kol_loharas
	local group13 kondareddis konda_reddis 
	local group14 mag magh
	local group15 mal_paharia mal_pahariya
	local group16 man man_tai_speaking
	local group17 muthuvan muthuwan
	local group18 naikda naikda_talavia
	local group19 paradhi pardhi
	local group20 parja paroja porja porja_parangiperja
	local group21 raba rabha
	local group22 santal santhal
	local group23 sahariya saharya
	local group24 sawar savar
	local group25 siddi siddi_nayaka
	local group26 singpho singhpho
	local group27 sugalis sugalis_lambadis
	local group28 synteng syntheng
	local group29 ulladan ulladan_hill_dwellers 
	local group30 vaiphui vaiphei
	local group31 mikir karbi // this equivalence established by the SC ST Orders Amendment Act, 2002 (see Assam change)
	local group32 goudu_goud goudu 
	local group33 kondhs_kodi kondhs 
	local group34 savaras_kapu_savaras savaras 
	local group35 malha_malasar maha_malasar //discrepancies in tribe name spellings across census volumes 
	local group36 sahte suhte //discrepancies in tribe name spellings across census volumes
	local group37 bhil bhils garasia // oraon added 
	local group38 koli koli_dhor koli_malhar  //added koli mahadev
	local group39 any_kuki_tribes kuki //added riang gangte vaiphei 
	local num_manual 39

	* add the manually specified synonyms to the synonyms for relevant tribes
	local N = _N	
	forval	i=1/`N'	{
		forval m = 1/`num_manual' {
			local all_synonyms = `tribewords'[`i']
			if "`:list all_synonyms & group`m''" != "" local all_synonyms: list all_synonyms | group`m'
			replace `tribewords' = "`all_synonyms'" in `i'
		}		
	}
	* logic:
	* sort observations alphabetically
	* start top-level cycle of observations from j = 1 to end	
		* initialize `group' to be the first synonym of `tribefull'[j]
		* initialize `synonyms' to be `tribefull'[j]
		* initialize `add_this' to `tribefull'[j]
		* while `add_this' ~= ""
			* set `add_this' = ""
			* cycle through all other observations i = j+1 to end 
				* check if there is any overlap between `synonyms' and `tribefull'[i]
					* if there is, set `synonyms' = `synonyms' | `tribefull'[i]; set `group' = `group'[j]; set `added_bit' = `tribefull'[i] - `synonyms'; set `add_this': `add_this' | `added_bit' 
					* else set `add_this' = ""
				* end cycle
			* end while loop
		* replace `synonyms' = local `synonyms' if `group' = `group'[j]
		* end top level cycle
	
	tempvar synonyms group group_num
	gen `synonyms' = ""
	gen `group' = ""
	gen `group_num' = .
	
	gsort -`popvar'
		
	local group_counter = 0
	
	forvalues j = 1/`N' {
		if `group'[`j'] ~= "" continue
		local ++group_counter
		
		local all_synonyms = `tribewords'[`j']
		local tribe_group: word 1 of `all_synonyms'
		
		replace `group' = "`tribe_group'" in `j'
		replace `group_num' = `group_counter' in `j'
				
		* first we collect all synonyms of this group, till there are no new ones
		
		local found_something 1 // initialize this as non-zero to enable while loop to begin
		local obs_for_this_tribe // initialize to nothing
		
		while `found_something' ~= 0 { // we want to loop over all observations until we go through a full loop without finding any synonyms
			local found_something 0 // not found anything yet for this loop
			forvalues i = `=`j'+1'/`N'{ 
				if `group'[`i'] ~= "" continue // skip observations that are already in a group
				local this_tribe = `tribewords'[`i']
				local x: list all_synonyms & this_tribe // synonyms in both this observation and the current tribe
				if "`x'" ~= "" {   // i.e. if the observation belongs to the current tribe
					local obs_for_this_tribe: list obs_for_this_tribe | i
					local added_bit: list this_tribe - all_synonyms
					if "`added_bit'" ~= "" {
						local found_something 1
						local all_synonyms: list all_synonyms | this_tribe // add the synonyms from this tribe to the full list
					}
				}
			}
		}
		
		replace `synonyms' = "`all_synonyms'" in `j'
				
		foreach i of local obs_for_this_tribe {
			replace `group' = `group'[`j'] in `i'
			replace `group_num' = `group_counter' in `i'
			replace `synonyms' = "`all_synonyms'" in `i'
		}
	}
	
	gen `gensynonymvar' = `synonyms'
	tempvar neg_pop
	gen `neg_pop' = -`popvar'
	bysort `group_num' (`neg_pop'): gen `gengroupvar' = proper(`first_name'[1])

	sort `sort_order'
end

******************************************************************************************************************************************
* 3. this part prepares the 1961 scheduled tribes list in order to append with 2011 data 
* it adds total population figures for each tribe 
******************************************************************************************************************************************

import excel "../01_data/scheduled tribes list/census 1961 scheduled tribe list.xlsx", sheet("Sheet1") firstrow clear

replace tribe = strtrim(tribe)
replace tribe = lower(tribe)
tempfile tribelist
save `tribelist'


use "../08_temp/census1961_st_religion_distcoded.dta", clear
keep dcode_1961 state_1961 tribe_code tribe area total_p
replace tribe = strtrim(tribe)
keep if mod(dcode_1961,100) == 0
collapse (sum) total_p , by (dcode_1961 state_1961 tribe)
drop if strpos(tribe,"aggregate")>0
rename state_1961 state 
merge 1:1 state tribe using `tribelist'

clonevar caste = tribe
clonevar caste_updated = caste 
drop tribe 

tempfile 1961_tribe
save `1961_tribe'

******************************************************************************************************************************************
* 3. this part prepares the 2011 scheduled tribes list in order to append with 1961 
******************************************************************************************************************************************

use "../08_temp/st_2011_state_pops", clear

clonevar caste_updated = caste


replace caste_updated = "Any Kuki Tribes, including:  (I) Biate Or Biete (Ii) Changsan (Iii) Chongloi (Iv) Doungel (V) Gamalhou (Vi) Gangte (Vii) Guite (Viii) Hanneng (Ix) Haokip Or Haupit (X) Haolai (Xi) Hengna (Xii) Hongsungh (Xiii) Hrangkhwal Or Rangkhol (Xiv) Jongbe (Xv) Khawchung (Xvi) Khawathlang Or Khothalong (Xvii) Khelma (Xviii) Kholhou (Xix) Kipgen (Xx) Kuki (Xxi) Lengthang (Xxii) Lhangum (Xxiii) Lhoujem (Xxiv) Lhouvun (Xxv) Lupheng (Xxvi) Mangjel (Xxvii) Misao (Xxviii) Riang (Xxix) Sairhem (Xxx) Selnam (Xxxi) Singson (Xxxii) Sitlhou (Xxxiii) Sukte (Xxxiv) Thado (Xxxv) Thangngeu (Xxxvi) Uibuh (Xxxvii) Vaiphei" if caste_updated == "Any Kuki Tribes, including:" & state == "MIZORAM"

replace caste_updated = "Kuki, including the following sub-tribes: i) Balte (ii) Belalhut (iii) Chhalya (iv) Fun (v) Hajango (vi) Jangtei (vii) Khareng (viii) Khephong (ix) Kuntei (x) Laifang (xi) Lentei (xii) Mizel (xiii) Namte (xiv) Paitu, Paite (xv) Rangchan (xvi) Rangkhole (xvii) Thangluya" if caste_updated == "Kuki,   including the following sub-tribes:" & state == "TRIPURA"

replace caste_updated = "Any Kuki Tribes, including:  (I) Biate Or Biete (Ii) Changsan (Iii) Chongloi (Iv) Doungel (V) Gamalhou (Vi) Gangte (Vii) Guite (Viii) Hanneng (Ix) Haokip Or Haupit (X) Haolai (Xi) Hengna (Xii) Hongsungh (Xiii) Hrangkhwal Or Rangkhol (Xiv) Jongbe (Xv) Khawchung (Xvi) Khawathlang Or Khothalong (Xvii) Khelma (Xviii) Kholhou (Xix) Kipgen (Xx) Kuki (Xxi) Lengthang (Xxii) Lhangum (Xxiii) Lhoujem (Xxiv) Lhouvun (Xxv) Lupheng (Xxvi) Mangjel (Xxvii) Misao (Xxviii) Riang (Xxix) Sairhem (Xxx) Selnam (Xxxi) Singson (Xxxii) Sitlhou (Xxxiii) Sukte (Xxxiv) Thado (Xxxv) Thangngeu (Xxxvi) Uibuh (Xxxvii) Vaiphei" if caste_updated == "Any Kuki Tribes,  including:" & state == "MEGHALAYA"

replace caste_updated = "Any Kuki Tribes, including:  (I) Biate Or Biete (Ii) Changsan (Iii) Chongloi (Iv) Doungel (V) Gamalhou (Vi) Gangte (Vii) Guite (Viii) Hanneng (Ix) Haokip Or Haupit (X) Haolai (Xi) Hengna (Xii) Hongsungh (Xiii) Hrangkhwal Or Rangkhol (Xiv) Jongbe (Xv) Khawchung (Xvi) Khawathlang Or Khothalong (Xvii) Khelma (Xviii) Kholhou (Xix) Kipgen (Xx) Kuki (Xxi) Lengthang (Xxii) Lhangum (Xxiii) Lhoujem (Xxiv) Lhouvun (Xxv) Lupheng (Xxvi) Mangjel (Xxvii) Misao (Xxviii) Riang (Xxix) Sairhem (Xxx) Selnam (Xxxi) Singson (Xxxii) Sitlhou (Xxxiii) Sukte (Xxxiv) Thado (Xxxv) Thangngeu (Xxxvi) Uibuh (Xxxvii) Vaiphei" if caste_updated == "Any Kuki Tribes,  including:**" & state == "ASSAM"

replace caste_updated = "Andamanese,   Chariar,   Chari,   Tabo,   Bo,   Yere, Kede,   Bea,   Balawa,   Bojigiyab,   Juwai" if caste_updated == "Andamanese,   Chariar,   Chari,   Kora,   Tabo,   Bo,   Yere, Kede,   Bea,   Balawa,   Bojigiyab,   Juwai,   Kol" 

******************************************************************************************************************************************
* 3.1 fix the Naga sub-tribes in Nagaland, since these do not appear in the 1961 mother tongue tables
******************************************************************************************************************************************


replace caste_updated = subinstr(caste_updated,"(ST)","",.)
replace caste_updated = trim(caste_updated)
levelsof caste_updated if caste_code > 1000, local(nagas) clean
local naga Naga
local nagas: list nagas - naga
replace caste_updated = "Naga, " + subinstr("`nagas'"," ",", ",.) if caste_code == 505 & state == "NAGALAND"
drop if caste_code > 1000
gen year = 2011

******************************************************************************************************************************************
* 3 Appending 1961 and 2011 data 
******************************************************************************************************************************************

append using `1961_tribe'
replace state = proper(state)
replace total_p = 0 if missing(total_p)


******************************************************************************************************************************************
* 3.2 clean the tribe name variable and create tribe groups using the program defined above
******************************************************************************************************************************************

replace caste_updated = "generic tribes" if inlist(caste_updated,"scheduled tribes not known","unclassified")
replace caste_updated = "any mizo (lushai) tribes" ///
		if inlist(caste_updated,"any mizo (lushai)tribes","any mizo(lushai) tribes","any mizo(lushai)tribes")


drop if caste_updated == "all scheduled tribes"
replace caste_updated = proper(caste_updated)

gen excludepos = strpos(caste_updated,"Excluding")
replace caste_updated = substr(caste_updated,1,excludepos-1) if excludepos > 0
drop excludepos

replace caste_updated = "Gamit, Gamta, Gavit, Mavchi, Padvi" if strpos(caste_updated,"Gamit")>0
* the above conforms with post-1976 definition of Gamit in Gujarat (drop a couple synonyms), and breaks the link between Bhils and Oraons

replace caste_updated = "Andamanese Including Chariar Or Chari, Tabo Or Bo, Yere, Kede, Bea, Balawa, Bojigiyab, Juwai" if caste_updated == "Andamanese Including Chariar Or Chari, Kora, Tabo Or Bo, Yere, Kede, Bea, Balawa, Bojigiyab, Juwai And Kol"

qui clean_tribe caste_updated , gen(caste_clean)

******************************************************************************************************************************************
* 4. the following bit of code uses the program (defined above) create_tribe_groups to create tribal groups from 1961 data
* specifically, it uses the mothertongue data for STs from Census 1961 to do this
* this creates the file st_groups_with_states that has state, tribe and castegroup
******************************************************************************************************************************************

qui create_tribe_groups, castevar(caste_clean) statevar(state) popvar(total_p) gengroup(castegroup_1961_2011) gensynonym(tribe_synonyms_1961_2011)

replace castegroup_1961_2011 = "Any Kuki Tribes" if castegroup_1961_2011 == "Riang"

drop caste_clean
label define CASTE_GROUPS_1961_2011 0 "All Scheduled Castes" 490 "Generic Castes" 500 "All Scheduled Tribes" 990 "Generic Tribes"
encode castegroup_1961_2011, generate(castegroup_1961_2011_code) label(CASTE_GROUPS_1961_2011)


save "../08_temp/st_groups_with_states" , replace 
export excel "../03_processed/census scheduled tribe list with states and tribe groups.xlsx", firstrow(variables) nolabel replace


******************************************************************************************************************************************
* 5 Status check for tribe groups across 1961 and 2011 
******************************************************************************************************************************************

sort castegroup_1961_2011


by castegroup_1961_2011: egen exception_1961 = max(year)
distinct castegroup_1961_2011 if exception_1961 == 1961

noi levelsof castegroup_1961_2011 if exception_1961 == 1961

/* 
* 9 tribe groups of 1961 are left unmerged:
"All Tribes Of N.E.F.A."' `"All Tribes Of North-East Frontier Agency"' `"Dafla"' `"Keer"' `"Korama"' `"Nat"' `"Pulayan"' `"Vaghri"' "Vishavan"
*/


by castegroup_1961_2011: egen exception_2011 = min(year)
distinct castegroup_1961_2011 if exception_2011 == 2011

noi levelsof castegroup_1961_2011 if exception_2011 == 2011


/* 124 tribe groups are found only in 2011 

"Adi"' `"Adi Bori"' `"Adi Gallong"' `"Adi Minyong"' `"Adi Padam"' `"Adi Pasi"' `"Adiramo"' `"Ashing"' ` "Bagi"' `"Bakarwal"' `"Balti"' `"Bangni"' `"Bhotia"' `"Bogum"' `"Bokar"' `"Bomdo"' `"Bori"' `"Bot"' `"Brokpa"' `"Buksa"' `"But Monpa"' `"Changpa"' `"Cholanaickan"' `"Dalbing"' `"Darok Tangsa"' `"Degaru"' `"Dirang Monpa"' `"Domba"' `"Dubla Halpati"' `"Garra"' `"Gawda"' `"Haisa Tangsa"' `"Havi Tangsa"' `"Hill Miri"' `"Hotang Tangsa"' `"Hrusso"' `"Jannsari"' `"Jugli"' `"Kaman"' `"Karimpalan"' `"Karka"' `"Kemsing Tangsa"' `"Khamba"' `"Khamiyang"' `"Kharam"' `"Koch"' `"Komkar"' `"Korang Tangsa"' `"Laju"' `"Langkai Tangsa"' `"Libo"' `"Lichi Tangsa"' `"Liju Nocte"' `"Limboo"' `"Limbu Subba"' `"Lish Monpa"' `"Longchang Tangsa"' `"Longin Tangsa"' `"Longphi Tangsa"' `"Longri Tangsa"' `"Longsang Tangsa"' `"Lowang Tangsa"' `"Mala Panickar"' `"Mala Vettuvan"' `"Mavilan"' `"Meyor"' `"Miji"' `"Millang"' `"Miniyong"' `"Moglum Tangsa"' `"Mon"' `"Monpa"' `"Morang Tangsa"' `"Mossang Tangsa"' `"Muktum"' `"Nakkala"' `"NamsangTangsa"' `"Ngimong Tangsa"' `"Nishang"' `"Nissi"' `"Nocte"' `"Nonong"' `"Nyishi"' `"Padam"' `"Pailibo"' `"Panchen Monpa"' `"Pangi"' `"Parahiya"' `"Pasi"' `"Patari"' `"Phong Tangsa"' `"Ponthai Nocte"' `"Purigpa"' `"Raji"' `"Ramo"' `"Rangai Tangsa"' `"Rongrang Tangsa"' `"Sanke Tangsa"' `"Simong"' `"Sippi"' `"Siram"' `"Sulung"' `"Sulung Bangni"' `"Tagin"' `"Tagin Bangni"' `"Taisen Tangsa"' `"Tamang"' `"Tangam"' `"Tangsa"' `"Taram"' `"Tarao"' `"Tawang Monpa"' `"Ten Kurumban"' `"Thachanadan"' `"Thai Khampi"' `"Tharu"' `"Tikhak Tangsa"' `"Tutcha Nocte"' `"Velip"' `"Vetta Kuruman"' `"Wancho"' `"Yobin"' `"Yongkuk Tangsa"' `"Yougli Tangsa"'

*/

/* 

Discussion on unmerged tribes:

1961 Unmerged Tribes
--------------------

These 5 tribes have been checked, and will remain unmatched for the following reasons:

1. Keer is a tribe scheduled in parts of Madhya Pradesh. They have zero returns in 2011.
2. Korama are a community in Karnataka that were shifted from the ST list to the SC list in 1976
3. Nat are a small community in Madhya Pradesh in 1961, but only figure as SCs in that state 2011, not STs
4. Pulayan were a large tribe in Malabar district of Kerala, but were included as SC in other parts of Kerala in 1976, this was rationalized and Pulayan were removed from ST list of Kerala and scheduled as an SC all over the state. They also had a small presence in Tamil Nadu, and there too they were earlier in both SC and ST lists (for different parts of the state) and in 1976 moved to SC list only
5. Vaghri are a small tribe delimited only in the Kutch region of Gujarat, and have nil returns in 2011
6. Vishavan is a tribe only in Kerala and has nil returns in 1961, remains unmatched since it was deleted from the list of S.Ts in 1981 in Kerala due to having no population in 1971 census (Source: PRIMARY CENSUS ABSTRACT FOR SCHEDULED CASTES AND SCHEDULED TRIBES, Series 10 Kerala 1981)
7. all tribes of n.e.f.a : removed from Assam and Nagaland in 1971
8. all tribes of north east frontier agency : removed from Assam and Nagaland in 1971
9. Dafla(In Nagaland and Assam): This tribe was listed as ST in Assam by the Constitution (Scheduled Tribes) Order, 1950, After the creation of Arunachal Pradesh as a State, "Dafla" was mentioned in the list of ST in Arunachal Pradesh by the North-Eastern Areas (Reorganisation) Act, 1971.
The Constitution (Nagaland) Scheduled Tribes Order, 1970 (Annex 3.V) specified only five tribes in namely- (i) Naga, (ii) Kuki, (iii) Kachari, (iv) Mikir, and (v) Garo.

2011 Unmerged Tribes
--------------------

These 124 tribes have been checked, and will remain unmatched for the following reasons:

1-9. 	9 are tribes scheduled in Jammu & Kashmir where scheduling had not yet happened in 1961 
		[Bakarwal; Balti; Bot; Brokpa; Changpa; Garra; Mon; Purigpa; Sippi]
10-13. 	4 are tribes scheduled in Uttarakhand, where scheduling had not happened in 1961 
		[Bhotia, Buksa, Jannsari, Raji] 
14-21.	8 are tribes newly scheduled in Kerala in 2002 [Cholanaickan; Karimpalan; Mala Panickar; Mala Vettuvan; Mavilan; Ten Kurumban; Thachanadan; Vetta Kuruman;]
22.		Nakkala was newly scheduled in Andhra Pradesh in 2002
23-24.	2 are tribes newly scheduled in Manipur in 2002 [Kharam; Tarao]
25-26.	2 are tribes newly scheduled in West Bengal in 2002 [Limbu Subba; Tamang]
27-28.	2 are tribes newly scheduled in Goa in 2002 [Gawda; Velip]
29-30.	2 are tribes newly scheduled in Uttar Pradesh in 2002 [Parahiya; Patari]
31.		2 tribes were newly scheduled in Sikkim in 2002 [Limboo; Tamang] (Tamang already counted as new in WB above)
32.		Domba was newly scheduled in Himachal Pradesh in 2002
35. 	Dubla Halpati are scheduled in Goa, and in Daman & Diu, for which no SC/ST data was collected in the census of 1961
39.		Koch are STs of Meghalaya  that are not listed in Assam for 1961
42-134. The remaining 91 tribes are scheduled in Arunachal Pradesh only, for which we have been unable to obtain Census 1961 data
		[Adi; Adi Bori; Adi Gallong; Adi Minyong; Adi Padam; Adi Pasi; Adiramo; Ashing; Bagi; Bangni; Bogum; Bokar; Bomdo; Bori; But Monpa; Dalbing; Darok Tangsa; Degaru; Dirang Monpa; Haisa Tangsa; Havi Tangsa; Hill Miri; Hotang Tangsa; Hrusso; Jugli; Kaman; Karka; Kemsing Tangsa; Khamba; Khamiyang; Komkar; Korang Tangsa; Laju; Langkai Tangsa; Libo; Lichi Tangsa; Liju Nocte; Lish Monpa; Longchang Tangsa; Longin Tangsa; Longphi Tangsa; Longri Tangsa; Longsang Tangsa; Lowang Tangsa; Meyor; Miji; Millang; Miniyong; Moglum Tangsa; Monpa; Morang Tangsa; Mossang Tangsa; Muktum; Namsang Tangsa; Ngimong Tangsa; Nishang; Nissi; Nocte; Nonong; Nyishi; Padam; Pailibo; Panchen Monpa; Pangi;  Pasi; Phong Tangsa; Ponthai Nocte; Ramo; Rangai Tangsa; Rongrang Tangsa; Sanke Tangsa; Sherdukpen; Simong; Siram; Sulung; Sulung Bangni; Tagin; Tagin Bangni; Taisen Tangsa; Tangam; Tangsa; Taram; Tawang Monpa; Thai Khampi; Tharu; Tikhak Tangsa; Tutcha Nocte; Wancho; Yobin; Yongkuk Tangsa; Yougli Tangsa]
*/

******************************************************************************************************************************************
* 6 Creating dataset retaining only tribe groups and tribe group codes 
******************************************************************************************************************************************

use "../08_temp/st_groups_with_states" , clear

collapse (sum) total_p, by(castegroup_1961_2011 castegroup_1961_2011_code state state_code caste_updated caste caste_code year)
keep castegroup_1961_2011 castegroup_1961_2011_code state state_code caste_updated caste caste_code year 

noi distinct castegroup_1961_2011 castegroup_1961_2011_code

save "../08_temp/st_groups_merged_1961_2011", replace


project, creates("../08_temp/st_groups_with_states.dta")
project, creates("../03_processed/census scheduled tribe list with states and tribe groups.xlsx")
project, creates("../08_temp/st_groups_merged_1961_2011.dta")










