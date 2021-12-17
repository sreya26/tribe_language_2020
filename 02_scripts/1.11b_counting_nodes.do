********************************************************************************************************************************
* this do-file constructs the language distance between two languages using the ethnologue_tree.dta file
* using various methods:
* TJ: counting the number of nodes that we need to traverse to get from one language to the other (see the Tarun Jain (2017) Common Tongue paper)
* F: The Fearon (2003) measure, using m = 15 and alpha = 0.5
* F8: The Fearon (2003) measure, using m = 8 and alpha = 0.5 
* DOW: The Fearon (2003) measure, using m = 8 and alpha = 0.05; see Desmet, Ortuno-Ortin and Weber (2009)
* AP: 1 - Proximity as defined in Adsera & Pytlikova (2015)
* AS: the LDND measure of Bakker et al (2009) using ASJP database
* L : Laitin (2000)'s r measure given in his footnote 7
********************************************************************************************************************************


* this program requires a prior run of 6B.asjp_distances.do, to load the "asjp" matrix into memory

capture program drop node_distance
program define node_distance, rclass
	syntax , LANG1(string) LANG2(string)
	
	if "`lang1'" == "`lang2'" {
		return scalar dist_tj = 0
		return scalar dist_f = 0
		return scalar dist_f8 = 0
		return scalar dist_dow = 0
		return scalar dist_ap = 0
		return scalar dist_l = 0
		return scalar dist_as = 0
		
		preserve
		use "../08_temp/ethnologue_tree", clear
		tempvar obnum
		gen `obnum' = _n
		qui su `obnum' if language == "`lang1'", meanonly
		local lang_obs = r(min)
		return scalar nodes_common = lang_depth[`lang_obs']
		restore	
		exit
		}
	
	preserve
		use "../08_temp/ethnologue_tree", clear
		tempvar obnum
		gen `obnum' = _n
	
		su `obnum' if language == "`lang1'", meanonly
		local lang1_obs = r(min)
		su `obnum' if language == "`lang2'", meanonly
		local lang2_obs = r(min)
		
		local lang1_iso = iso[`lang1_obs']
		local lang2_iso = iso[`lang2_obs']
		
		* this loop starts at the top of the tree and stops at the first level where the two languages differ
		local i = 0
		while level`i'[`lang1_obs'] == level`i'[`lang2_obs'] {
			local ++i
			}
		
		local i = `i'-1 // this gives us the last common node
		
		local dist_up = lang_depth[`lang1_obs'] - `i' + 1 // +1 for self
		local dist_down = lang_depth[`lang2_obs'] - `i'
		
		local max_depth_dravidian = 7
		local max_depth_indo_european = 8
		local max_depth_sino_tibetian = 8
		local max_depth_austro_asiatic = 7
		local max_depth_andamanese = 4
		local max_depth_language_isolate = 2
		local max_depth_unclassified = 2
		
		local tree = lower(subinstr(level1[`lang1_obs'],"-","_",.))
		local tree = subinstr("`tree'"," ","_",.)
		local dist_f = 1-(`i'/15)^(0.5)
		local dist_f8 = 1-(`i'/8)^(0.5)
		* note: 15 comes from the maximum tree depth in Fearon (2003)'s database
		local dist_dow = 1-(`i'/8)^(0.05)
		local dist_l = 1-(`i'/8)
		* the below creates a distance measure taken from Adsera & Pytlikova (2015)
		if `i' == 0	local proximity_ap = 0
			else if `i' == 1 local proximity_ap = 0.1
				else if `i' == 2 local proximity_ap = 0.25
					else if `i' == 3 local proximity_ap = 0.45
						else if `i' > 3 local proximity_ap = 0.7
		local dist_ap = 1 - `proximity_ap'

	restore
	
	return scalar nodes_common = `i'
	return scalar dist_tj = `dist_up' + `dist_down'
	return scalar dist_f = `dist_f'
	return scalar dist_f8 = `dist_f8'	
	return scalar dist_dow = `dist_dow'
	return scalar dist_ap = `dist_ap'
	return scalar dist_l = `dist_l'
	return scalar dist_as = asjp[rownumb(asjp,"`lang1_iso'"),colnumb(asjp,"`lang2_iso'")]
	
	end

* local lang1 "Aer"
* local lang2 "Hindi"


* node_distance , lang1("`lang1'") lang2("`lang2'")
* dis as error "The distance between `lang1' and `lang2' is " r(distance) " nodes."




