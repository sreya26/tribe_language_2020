project , uses("../03_processed/regions6113_with_dists_2011.dta")

*********************************************************************************************************
* this bit of code creates a CSV file that links census 2011 districts to 1961-2013 consistent regions
* this is used to create a region-level shapefile using QGIS 
*********************************************************************************************************

use "../03_processed/regions6113_with_dists_2011", clear

drop if mod(dcode_2011,1000) == 0 // drop state-level observations
drop dists_2011_in_region6113


export delimited using "../03_processed/census_2011_dists_regions_6113.csv", replace

project , creates("../03_processed/census_2011_dists_regions_6113.csv")
