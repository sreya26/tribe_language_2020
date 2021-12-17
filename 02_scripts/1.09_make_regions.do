********************************************************************************************************************************************
* this file creates lists of pairs of child and parent states & districts for adjacent years, from 1961 through 2013 
*! version 2.0 created by Hemanshu Kumar on 28 October 2020 -- alters code to take advantage of recently published 2001-2011 census tables
*! version 1.0 created by Hemanshu Kumar on 19 July 2020
********************************************************************************************************************************************

local parentfile_2011_DISE "../01_data/census_boundaries_data/District Boundary Changes 2011-DISE 2013.xlsx"
local parentfile_1961_2011 "../01_data/census_boundaries_data/District Boundary Changes 1961-2011.xlsx"

project , original("`parentfile_2011_DISE'")
project , original("`parentfile_1961_2011'")
project , original("1.09aa_programs_for_regions.do")

local parentfile_2011_DISE "../01_data/census_boundaries_data/District Boundary Changes 2011-DISE 2013.xlsx"
local parentfile_1961_2011 "../01_data/census_boundaries_data/District Boundary Changes 1961-2011.xlsx"

****************************************************************************************************
* I. create lists of pairs of child and parent states & districts for adjacent years, from 1961 through 2013
****************************************************************************************************

	****************************************************************************************************
	* I.1 For census 1961-2011 
	* this adapts code from "1.make_adminchanges_datasets.do" (written for 1961-2001) 
	* in the relevant analysis folder of the EPW 2017 boundaries paper
	****************************************************************************************************

	
	****************************************************************************************************
	* IMPORTANT!!!!!!
	* We may ignore the 1961-71 inter-state transfers between UP and Bihar; or not.
	* 	these transfers involve Ballia district in UP [net recipient of 8,153 people]
	* 	and Shahabad [net loser of 10,536 people] and Saran [net recipient of 2,383 people] districts of Bihar
	local ignoreupbr 1
	* for the tribelanguage paper, we keep ignoreupbr = 1
	****************************************************************************************************

	****************************************************************************************************
	* IMPORTANT!!!!!!
	* We may generate the files by ignoring small population transfers
	local ignoresmall 1
	local laxity 0.05 // the threshold for ignoring; based on the proportion of population transfered
	* for the tribelanguage paper, we set ignoresmall to 1, and laxity to 0.05 (5%)
	local verbose 0
	* set to 1 if the transfers that are being ignored should be displayed, else to 0.
	****************************************************************************************************

	****************************************************************************************************
	* IMPORTANT!!!!!!!
	* For Census 1961, we can either treat Manipur as a single district, or work with "sub-divisions". 
	local manipur_61_district 0
	* for the tribelanguage paper, we set this to 0
	****************************************************************************************************

	****************************************************************************************************
	* Also see notes on boundary changes at the end of this do-file
	****************************************************************************************************

	****************************************************************************************************
	* A note on Mappings and Transfers
	* for each pair of census years, there is a "Mapping" observation for each district in the child year
	* (i.e. the number of observations in the mapping`x'to`y' sheet should be the same 
	* as the number of observations in the census`y' sheet
	* however, the "mapping" does not actually identify the parent in the case of newly created districts
	* those are covered in the "transfers`x'to`y' sheet
	****************************************************************************************************

	local censusyrs 1961 1971 1981 1991 2001 2011
	local oldcensusyrs 1961 1971 1981 1991 2001

	local numcensus: list sizeof local(censusyrs)
	local endyr: word `numcensus' of `censusyrs'
	local firstyr: word 1 of `censusyrs'

	* first to inspect the census data to check if it's fine

	capture program drop makenumeric
	program define makenumeric
		syntax varlist
		foreach var of varlist `varlist' {
				capture replace `var' = "" if `var' == "NA"
				capture destring `var', replace ignore(",")
		}
	end

	capture program drop renamevars
	program define renamevars
		syntax varlist
		foreach var of varlist `varlist' {
			local endbit = substr("`var'",-4,.)
			local stub = substr("`var'",1,length("`var'")-4)
			rename `var' `stub'_`endbit'
		}
	end
	
	foreach x of local censusyrs {

		if `x'==1961 & `manipur_61_district' == 1 {
			tempfile manipur
			import excel using "`parentfile_1961_2011'", sheet("Manipur1961to1971") cellrange(:E3) firstrow case(lower) clear
			renamevars _all
			save `manipur', replace
			import excel using "`parentfile_1961_2011'", sheet("census`x'") firstrow case(lower) clear 
			keep dcode`x' state`x' district`x' area`x' pop`x'
			renamevars _all
			drop if state_`x'=="Manipur"
			append using `manipur'
		}
		else {
			import excel using "`parentfile_1961_2011'", sheet("census`x'") firstrow case(lower) clear
			keep dcode`x' state`x' district`x' area`x' pop`x'
			renamevars _all
		}
		
		makenumeric dcode_`x'
		drop if dcode_`x' == .
		makenumeric area_`x' pop_`x'

		sum area_`x' pop_`x'
		gen spot = 0
		* to get rid of occasional state identifiers in district names for situations where two districts have the same name
		* also get rid of asterisks
		forvalues i = 1/8 {
			local abbrev: word `i' of  " BH" " CG" " HP" " KT" " MH" " MP" " UP" "*"
			replace spot = strpos(district_`x', "`abbrev'") if spot==0
			}
		replace spot = spot - 1 if spot>0
		replace district_`x'  = substr(district_`x',1,spot) if spot>0
		replace district_`x' = proper(trim(itrim(district_`x')))
		replace state_`x' = proper(trim(itrim(state_`x')))
		drop spot

		sort dcode_`x'
		keep dcode_`x' state_`x' district_`x' area_`x' pop_`x'
		
		assert ~missing(dcode_`x') & ~missing(pop_`x') & ~missing(state_`x') & ~missing(district_`x') // no missingness
		distinct dcode_`x'
		assert r(ndistinct) == r(N) // all dcodes are unique
		
		if `x' == 2011 count if mod(dcode_`x',1000) == 0
			else count if mod(dcode_`x',100) == 0
		
		local statecount_`x' = r(N)
		local distcount_`x' = _N - `statecount_`x''
		
		noi dis as text "In census `x', there are a total of `statecount_`x'' states/UTs and `distcount_`x'' districts."
		tempfile census_`x'
		save `census_`x'', replace
	}

	* now to check the Mappings


	foreach x of local oldcensusyrs {		
		local y = `x' + 10
				
		if `x'==1961 & `manipur_61_district' == 1 {
			import excel using "`parentfile_1961_2011'", sheet("Manipur1961to1971") cellrange(G1:M7) firstrow case(lower) clear
			rename loc`y' dcode`y'
			rename implicitpop implicitpop`x'
			rename district`y' district`y'namechanged
			drop district1971in1961
			tempfile manipur
			save `manipur', replace

			import excel using "`parentfile_1961_2011'", sheet("Mapping`x'to`y'") firstrow case(lower) clear
			keep dcode`y' state`y' district`y'namechanged area`y' dcode`x' implicitpop`x'
			destring implicitpop`x', replace ignore("NA")
			drop if state`y'=="Manipur"
			append using `manipur'
		}
		
		else {
			import excel using "`parentfile_1961_2011'", sheet("Mapping`x'to`y'") firstrow case(lower) clear
		}
		
		keep dcode`y' state`y' district`y'namechanged area`y' dcode`x' implicitpop`x'
		order dcode`y' state`y' district`y'namechanged area`y' dcode`x' implicitpop`x'

		renamevars dcode`y' state`y' area`y' dcode`x' implicitpop`x'

		makenumeric dcode_`y'
		label var implicitpop_`x' "Population in `x' adjusted to jurisdiction of `y'"
		sort dcode_`y'
		drop if missing(dcode_`y')
		makenumeric dcode_`x' area_`y' implicitpop_`x'
		
		count
		noi dis as text "Between census `x' and census `y', there are " r(N) " mappings defined."
		tempfile mapping`x'`y'
		save `mapping`x'`y'', replace
	}

	* now to check the Transfers


	foreach x of local oldcensusyrs {
		local y = `x' + 10
			   
		 if `x'== 1961 & `manipur_61_district' == 1 {
			import excel using "`parentfile_1961_2011'", sheet("Manipur1961to1971") cellrange(O1:T6) firstrow case(lower) clear
			tempfile manipur
			save `manipur', replace
			import excel using "`parentfile_1961_2011'", sheet("Transfers1961to1971") firstrow case(lower) clear
			destring transferfromloc`x', replace
			drop if transferfromloc`x'>=601501 & transferfromloc`x'<=601510
			destring populationtransferred, replace ignore("NA")
			append using `manipur'
		}
	   
		else {
			import excel using "`parentfile_1961_2011'", sheet("Transfers`x'to`y'") firstrow case(lower) clear
		}
		
		keep transfertodist`y' transfertoloc`y' transferfromdist`x' transferfromloc`x' areatransferred populationtransferred
		renamevars transfertodist`y' transfertoloc`y' transferfromdist`x' transferfromloc`x'
		
		if `x' == 1961 & `ignoreupbr' == 1 {
			drop if inlist(transferfromdist_1961,"Uttar Pradesh","Bihar","Shahabad","Ballia")
			note: This dataset ignores the transfers between UP and Bihar in the 1960s.
		}
				
		makenumeric transfertoloc_`y' 
		drop if missing(transfertoloc_`y')
		makenumeric transferfromloc_`x' areatransferred populationtransferred
		
		if `x' == 2001 { // taking care of multiple transfers between the same pairs of districts between 2001-2011
			tempvar dup
			duplicates tag transferfromloc_2001 transfertoloc_2011, gen(`dup')
			assert inlist(transferfromloc_2001,200317,200807,200825) if `dup' == 1 // Patiala to S.A.S. Nagar, Bharatpur to Alwar, and Rajsamand to Bhilwara
			drop `dup'
			collapse (sum) areatransferred populationtransferred, by(transfertodist_`y' transfertoloc_`y' transferfromdist_`x' transferfromloc_`x')
		}
		
		distinct transfertoloc_`y' transferfromloc_`x', joint
		assert r(N) == _N // no duplicates among transfers

		count
		noi dis as text "Between census `x' and census `y', there are " r(N) " transfers defined."
		
		rename transferfromloc_`x' dcode_`x'
		rename transfertoloc_`y' dcode_`y'
		
		gen ignore = 0
		if `ignoresmall' == 1 {
			merge m:1 dcode_`x' using `census_`x'', keepusing(pop_`x') assert(match using) keep(match) nogen
			tempvar parent_transfer_frac
			gen `parent_transfer_frac' = populationtransferred/pop_`x'
			
			merge m:1 dcode_`y' using `mapping`x'`y'', keepusing(implicitpop_`x') keep(match) nogen
			tempvar child_transfer_frac
			gen `child_transfer_frac' = populationtransferred/implicitpop_`x'
			
			count if `parent_transfer_frac' < `laxity'
			if r(N) > 0 & `verbose' {
				noi dis as err "Between census `x' and census `y', there are " r(N) " parent transfers that " _n "are smaller than `laxity' of the parent district population, and are being ignored:"
				noi li transferfromdist_`x' transfertodist_`y' populationtransferred `parent_transfer_frac' if `parent_transfer_frac' < `laxity'
			}
			
			count if `child_transfer_frac' < `laxity'
			if r(N) > 0 & `verbose' {
				noi dis as err "Between census `x' and census `y', there are " r(N) " child transfers that " _n "are smaller than `laxity' of the parent district population, and are being ignored:"
				noi li transferfromdist_`x' transfertodist_`y' populationtransferred `parent_transfer_frac' if `parent_transfer_frac' < `laxity'
			}
			
			replace ignore = 1 if (`parent_transfer_frac' < `laxity'  & `child_transfer_frac' < `laxity' ) /*& mod(dcode`x',100)~=0 */ // apply the laxity criterion only at the district level
			drop `parent_transfer_frac' pop_`x' `child_transfer_frac' 
		}
		
		rename transferfromdist_`x' district_`x'
		rename transfertodist_`y' district_`y'
		rename populationtransferred pop_`x'
		rename areatransferred area_`x'

		sort dcode_`y'	
		
		if `ignoresmall' 	== 1 	note: This dataset ignores small transfers that are less than `laxity' of the parent district population.
		if `ignoreupbr' 	== 1	note: This dataset ignores the transfers between UP and Bihar in the 1960s.
		
		tempfile transfers`x'`y'
		save `transfers`x'`y'', replace
	}

	* check for duplicates between Mapping and Transfers files for the same decade
	foreach x of local oldcensusyrs {
		local y = `x' + 10		
		use `mapping`x'`y'', clear
		append using `transfers`x'`y''
		distinct dcode_`x' dcode_`y', joint
		assert r(N) == r(ndistinct)
	}
		
	foreach x of local oldcensusyrs {
		local y = `x' + 10		
		use `census_`y'', clear
		merge 1:m dcode_`y' using `transfers`x'`y'', keepusing(dcode_`x' pop_`x' area_`x' ignore) keep(match) nogen
		gen byte weight = -1
		drop if ignore == 1
		drop ignore

		tempfile censustransfers
		save `censustransfers'
		
		use `census_`y'', clear
		merge 1:m dcode_`y' using `mapping`x'`y'', keepusing(dcode_`x') assert(match) nogen
		merge m:1 dcode_`x' using `census_`x'', keepusing(pop_`x' area_`x') keep(match) nogen 
		* note that the above line will drop the newly created districts (since the mapping file does not record their parent)
		* the transfers involving those newly created districts are recorded in the transfers`x'`y' file

		gen byte weight = 1
		
		append using `censustransfers'
		merge m:1 dcode_`y' using `mapping`x'`y'', keepusing(implicitpop_`x') keep(match) nogen
		
		* note that pop`x' (and area`x') for the transfers, will contain just the transfered population (and area) for that `x' `y' pair
		* but for mappings, it will contain the population (resp., area) of the parent district: this we now fix
		
		* now we need to subtract off all transferred areas and populations from the maps to obtain the net self-transfers

		gen double signedpop_`x' = weight*pop_`x'
		gen double signedarea_`x' = weight*area_`x'

		egen double nettransferpop_`x' = total(signedpop_`x'), by(dcode_`x')
		egen double nettransferarea_`x' = total(signedarea_`x'), by(dcode_`x')
		
		replace pop_`x' = nettransferpop_`x' if weight == 1 // i.e. do this only for "maps"
		replace area_`x' = nettransferarea_`x' if weight == 1

		rename pop_`x' poptransfer_`x'`y'
		rename area_`x' areatransfer_`x'`y'
		
		label var poptransfer_`x'`y' "Population Transferred from the `x' district to the `y' district"
		label var areatransfer_`x'`y' "Area Transferred from the `x' district to the `y' district"
		merge m:1 dcode_`x' using `census_`x'', keepusing(state_`x' district_`x' pop_`x' area_`x') keep(match) nogen

		if `y' == 2011 gen isstate_`y' = (mod(dcode_`y',1000)==0)
			else gen isstate_`y' = (mod(dcode_`y',100)==0)
		
		gen transferid_`x'`y' = string(dcode_`x') + string(dcode_`y')
		destring transferid_`x'`y', replace
		format transferid_`x'`y' %12.0f

		* we get rid of the zeros
		* note that this methodology implies the 100% population criterion,
		* i.e. boundary changes involving zero population transfers are ignored when defining unchanged or partitioned districts

		drop if poptransfer_`x'`y' == 0 

		* it should be the case that total of transfers to every child district equals its implicitpop
		* we now do this consistency check

		by dcode_`y', sort: egen double totalreceived = total(poptransfer_`x'`y')
		gen double diff = totalreceived - implicitpop_`x'
		count if diff~=0
		
		* everything is fine, except for Haryana in '81-'91 (and UP-BR in '61-'71 if we choose to ignore it)

		keep state_`y' dcode_`y' district_`y' isstate_`y' state_`x' dcode_`x' district_`x'	

		duplicates drop dcode_`x' dcode_`y', force
		
		noi dis as text "We have " _N " overall transfers between `x' and `y'."
				
		distinct dcode_`x'
		assert r(ndistinct) == `distcount_`x'' + `statecount_`x''

		distinct dcode_`y' if isstate_`y' == 0
		assert r(ndistinct) == `distcount_`y''
		distinct dcode_`y' if isstate_`y' == 1
		assert r(ndistinct) == `statecount_`y''
		
		tempfile parentage_`x'`y'
		save `parentage_`x'`y'', replace

	}
	
	****************************************************************************************************
	* I.2 For census 2011 - DISE 2013-14 
	****************************************************************************************************
	
	import excel using "`parentfile_2011_DISE'", sheet("parentage") cellrange("A3") clear
	
	rename A stcode_dise
	rename B distcode_dise
	rename C district_dise
	rename D status
	rename E stcode_2011_1
	rename F distcode_2011_1
	rename G district_2011_1
	rename H stcode_2011_2
	rename I distcode_2011_2
	rename J district_2011_2
	
	drop if missing(stcode_dise)
	
	destring stcode_dise distcode_dise, replace
		
	gen dcode_dise = stcode_dise*100 + distcode_dise
	order dcode_dise , after(distcode_dise)

	gen isstate_dise = (distcode_dise == 0)

	gen state_dise = proper(district_dise) if isstate_dise
	replace state_dise = subinstr(state_dise, " And ", " and ",.)
	replace state_dise = "NCT of Delhi" if state_dise == "Nct Of Delhi"	
	replace state_dise = state_dise[_n-1] if missing(state_dise)
	order state_dise, after(stcode_dise)
	
	count if isstate_dise == 0
	local distcount_dise = r(N)
	count if isstate_dise == 1
	local statecount_dise = r(N)
	
	noi dis as text "In DISE 2013-14, there are a total of `statecount_dise' states/UTs and `distcount_dise' districts."
	
	preserve
		keep stcode_dise state_dise distcode_dise dcode_dise district_dise
		order stcode_dise state_dise distcode_dise dcode_dise district_dise
		save "../08_temp/dise_states_districts", replace
	restore
	
	
	reshape long stcode_2011_ distcode_2011_ district_2011_ , i(stcode_dise state_dise distcode_dise dcode_dise district_dise status) j(num)
	
	rename *_ *
	drop num
	drop if missing(stcode_2011)

	gen double dcode_2011 = 201100000 + stcode_2011*1000 + distcode_2011
	format dcode_2011 %9.0f

	duplicates drop dcode_2011 dcode_dise, force
	
	noi dis as text "We have `=_N' overall transfers between census 2011 and DISE 2013-14."
	
	tempfile parentage_2011dise
	save `parentage_2011dise', replace
	
****************************************************************************************************
* II. Make regions with consistent boundaries between census 1961 and DISE 2013-14 
****************************************************************************************************
	run 1.09aa_programs_for_regions.do

	use `parentage_2011dise', clear
	
	qui makeregions , parent(dcode_2011) child(dcode_dise) gen(region1113)
	qui nameregions region1113, parent(district_2011) child(district_2011) gen(regionname1113)
			
	tempvar dcode_dise_str dcode_2011_str
	gen `dcode_dise_str' = string(dcode_dise)
	gen `dcode_2011_str' = string(dcode_2011,"%9.0f")
	qui listdistricts region1113 , diststrvar(`dcode_dise_str') gen(dists_dise_in_region1113)
	qui listdistricts region1113 , diststrvar(`dcode_2011_str') gen(dists_2011_in_region1113)
	
	foreach yyyy in 2011 2001 1991 1981 1971 {
		local yy = substr("`yyyy'",3,2)
		local xxxx = `yyyy' - 10
		local xx = substr("`xxxx'",3,2)

		duplicates drop dcode_`yyyy', force
		keep dcode_`yyyy' region`yy'13 regionname`yy'13 dists_dise_in_region`yy'13 dists_2011_in_region`yy'13 
		tempfile dcode_`yyyy'_with_regions`yy'13
		save `dcode_`yyyy'_with_regions`yy'13'

		use `parentage_`xxxx'`yyyy''
		merge m:1 dcode_`yyyy' using `dcode_`yyyy'_with_regions`yy'13', assert(match) nogen
	
		duplicates drop dcode_`xxxx' region`yy'13, force
	
		quietly {
			makeregions , parent(dcode_`xxxx') child(region`yy'13) gen(region`xx'13)
			nameregions region`xx'13, parent(district_`xxxx') child(regionname`yy'13) gen(regionname`xx'13)
			listdistricts region`xx'13 , diststrvar(dists_dise_in_region`yy'13) gen(dists_dise_in_region`xx'13)
			listdistricts region`xx'13 , diststrvar(dists_2011_in_region`yy'13) gen(dists_2011_in_region`xx'13)
		}
		if `xxxx' == 1961 {
			tempvar dcode_1961_str
			gen `dcode_1961_str' = string(dcode_1961,"%9.0f")
			qui listdistricts region`xx'13 , diststrvar(`dcode_1961_str') gen(dists_1961_in_region`xx'13)
		}
	}
	
	preserve
		keep dcode_1961 state_1961 district_1961 region6113 regionname6113
		duplicates drop dcode_1961, force
		save "../08_temp/regions6113_with_dists_1961", replace
	restore
	
	preserve
		duplicates drop region6113, force
		keep region6113 regionname6113 dists_2011_in_region6113		
		split dists_2011_in_region6113 , gen(dcode_2011)
		reshape long dcode_2011 , i(region6113 regionname6113) j(num)
		keep if !missing(dcode_2011)
		destring dcode_2011, replace
		drop num
		save "../03_processed/regions6113_with_dists_2011", replace
	restore

	preserve
		duplicates drop region6113, force
		keep region6113 regionname6113 dists_dise_in_region6113
		split dists_dise_in_region6113 , gen(dcode_dise)
		reshape long dcode_dise , i(region6113 regionname6113) j(num)
		keep if !missing(dcode_dise)
		destring dcode_dise, replace
		drop num
		save "../08_temp/regions6113_with_dists_dise", replace
	restore
	
project , creates("../08_temp/dise_states_districts.dta")	
project , creates("../08_temp/regions6113_with_dists_1961.dta")
project , creates("../03_processed/regions6113_with_dists_2011.dta")
project , creates("../08_temp/regions6113_with_dists_dise.dta")

/*
******************************************************************************************************
Some comments on Assam boundary changes between 1971-91 from 
Table A1 - Area, Houses, Population, pp. 17-19. Census of India 1991 Part II-A, General Population Tables
******************************************************************************************************
  Nowgong District (as Nagaon District):  
	In 1971 Census, it was spelled as Nowgong District, but later it was spelled as Nagaon District 
	vide Govt Notification No. GAG(B) 370/87/102 dt 29.9.89
  
  Mikir Hill District (As Karbi Anglong District): 
	Mikir Hill District as existed during 1971 Census, was renamed as Karbi Anglong District without any change
	in the boundary of district vide Govt Notification No. HAD 140/78/108 dt 31.5.82
  
  Formation of Dibrugarh District: 
	A new administrative district known as Dibrugarh district was constituted on 2nd October, 1971 
	vide Govt of Assam notification No. AAP 110/70/165 dt 22.9.71 by bifurcating the existing 
	Lakhimpur district. Dibrugarh district was formed with the entire area of existing 
	Dibrugarh sub-division of existing Lakhimpur district.

****************************************************************************************************
From Census of India, 1971, India - General Population Tables, p. 41
****************************************************************************************************
Sikkim became a state of the Indian union according to the constitution (36th) amendment act of 1975.


****************************************************************************************************
Difference between our district counts and those from the Census 2011 Administrative Atlas:

Mizoram: 
	In Census 1971 documents, Mizoram is not listed as a separate state. It figures as
	the Mizo district of Assam. The Census 2011 atlas however lists it as a separate state.

Sikkim: 
	The Atlas counts Sikkim as a single district in 1961 and 1971. This makes no sense.
	Either Sikkim should be excluded from the India total (this is what we do) because it was not
	formally part of India until 1975. Or if it is included, then it should have 4 districts
	in both 1961 and 1971 (verified from Census 1981 tables for Sikkim) [note: Census 1971 volumes
	for Sikkim are not available in the RTL at D'School]
****************************************************************************************************
*/
