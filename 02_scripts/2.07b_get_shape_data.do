project , original("../01_data/shapefiles/census_1961_2013_consistent_regions.shp")
project , original("../01_data/shapefiles/census_1961_2013_consistent_regions.dbf")

project , original("../01_data/shapefiles/SDE_DATA_IN_F7DSTRBND_2011.shp") // this was used by QGIS
project , original("../01_data/shapefiles/SDE_DATA_IN_F7DSTRBND_2011.dbf") // this was used by QGIS
project , uses("../03_processed/census_2011_dists_regions_6113.csv") // this was used by QGIS

*********************************************************************************************************
* this do file gets shape data from the regions shapefile created using QGIS  
*********************************************************************************************************


	*********************************************************************************************************
	* Here is a description of the process in QGIS:
	* 1. We used census 2011 boundaries data obtained from MIT (via Aditya Paul), contained in the
	* 		files named SDE_DATA_IN_F7DSTRBND_2011.*
	* 2. These were opened in QGIS 3.14
	* 3. 	From the SDE_DATA_IN_F7DSTRBND_2011 layer -> Open Attribute Table -> Open Field Calculator , 
	* 		we created a new field, dcode_2011 by computing 201100000 + toreal(C_CODE11)/1000000000000
	* 4. 	Layer (top menu) -> Add Layer -> Add Delimited Text Layer... , to read in the csv file linking
	*			regions and 2011 district codes [remember to select "No geometry" in Geometry Definition in
	*			the dialog box]
	* 5.	From the SDE_DATA_IN_F7DSTRBND_2011 layer -> Properties... -> Joins -> "+" , we join the two layers
	*			SDE_DATA_IN_F7DSTRBND_2011 and the one with the region codes, using the field dcode_2011
	* 6.	Vector (top menu) -> Geoprocessing Tools -> Dissolve... to dissolve the new layer using the field region6113
	* 7.	Convert the new temporary layer into a permanent one, which will ask to create the new shapefiles
	*********************************************************************************************************

	shp2dta using "../01_data/shapefiles/census_1961_2013_consistent_regions.shp", database("../03_processed/indregionsbasemap6113") coordinates("../03_processed/indregionscoord6113") genid(id) gencentroids(mid) replace	

	project , creates("../03_processed/indregionsbasemap6113.dta")
	project , creates("../03_processed/indregionscoord6113.dta")
