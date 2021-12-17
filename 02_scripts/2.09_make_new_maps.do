* make new maps
*! version 1.0 by Hemanshu Kumar on 28 January 2021


************************************************************************************************************************
* map of areas under Schedule 5 and 6
************************************************************************************************************************

	use "../03_processed/lang_workfile", clear

	duplicates drop region6113, force
	drop if is_state
	
	keep region6113 regionname6113 scheduledarea6113 tribalarea6113
	
	gen protected_status = 0
	
	replace protected_status = 1 if scheduledarea6113 != 0
	replace protected_status = 2 if tribalarea6113 != 0
	
	label define PROTECTED_STATUS 0 "Not protected" 1 "Schedule 5" 2 "Schedule 6"
	label values protected_status PROTECTED_STATUS
	
	keep region6113 protected_status
	
	tempfile protected
	save `protected'
	
	
	use "../03_processed/indregionsbasemap6113", clear
	rename census_201 region6113
	rename census_2_1 regionname6113

	merge m:1 region6113 using `protected', assert(master match)

	replace protected_status = .a if _merge == 1
	label define PROTECTED_STATUS .a "No STs", add

	drop _merge


	#delimit ;
	spmap protected_status using "../03_processed/indregionscoord6113" ,
	/*	caption(`"Protected Areas"', pos(12))*/
		id(id)
		osize(vthin ...) ndsize(vthin ...)
		fcolor(Greens)
		clmethod(unique)
		clnumber(3)
		ndlabel("N.A.")
		legstyle(2)
		legend(pos(7) ring(0))
		legorder(hilo)
		note("Consistent regions, Census 1961 - DISE 2013-14", pos(7))
		name(st_protected, replace)
		;
	#delimit cr  
	
	graph export "../04_results/02_figures/st_protected_6113.pdf", replace name(st_protected)
	
