*********************************************************************************************************************
* this file creates a variable that denotes whether a (1961-2013) consistent region is
* a Scheduled Area (i.e. under the Fifth Schedule) or a Tribal Area (i.e. under the Sixth Schedule) as per the Constitution of India
*! version 1.0 created by Hemanshu Kumar on 22 July 2020 
* updated from 2017 version by adapting for Census 2011, and for use with Robert Picard's -project- command
*********************************************************************************************************************

project , original("../01_data/scheduled_tribal_areas/scheduled_and_tribal_districts_2011.xlsx")
project , uses("../03_processed/regions6113_with_dists_2011.dta")

import excel using "../01_data/scheduled_tribal_areas/scheduled_and_tribal_districts_2011.xlsx", clear firstrow case(lower)

replace scheduledarea = "0.5" if strpos(scheduledarea,"part")
replace tribalarea = "0.5" if strpos(tribalarea,"part")

destring scheduledarea, replace
destring tribalarea, replace

rename census2011statecode state_code_2011
rename census2011districtcode district_code_2011
rename name district_2011

gen double dcode_2011 = 201100000 + state_code_2011 * 1000 + district_code_2011
format %9.0f dcode_2011

drop state_code_2011 district_code_2011

replace scheduledarea = 0 if missing(scheduledarea)
replace tribalarea = 0 if missing(tribalarea)

rename (scheduledarea tribalarea) =_2011

tempfile areas
save `areas'

use "../03_processed/regions6113_with_dists_2011", clear
drop dists_2011_in_region6113

merge 1:1 dcode_2011 using `areas', assert(match) nogen keepusing(district_2011 scheduledarea_2011 tribalarea_2011)

foreach type in scheduled tribal {
	tempvar `type'area_1961_min `type'area_1961_max	
	egen ``type'area_1961_min' = min(`type'area_2011), by(region6113)
	egen ``type'area_1961_max' = max(`type'area_2011), by(region6113)
	gen `type'area_1961 = 1 if ``type'area_1961_min' == 1
	replace `type'area_1961 = 0 if ``type'area_1961_max' == 0
	replace `type'area_1961 = 0.5 if missing(`type'area_1961)
	}

duplicates drop region6113, force
keep *_1961 *6113

rename *_1961 *6113

label var scheduledarea6113 "Scheduled Area as per Fifth Schedule"
label var tribalarea6113 "Tribal Area as per Sixth Schedule"

save "../08_temp/scheduled_and_tribal_regions", replace

project , creates("../08_temp/scheduled_and_tribal_regions.dta")




