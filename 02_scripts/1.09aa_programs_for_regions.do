********************************************************************************************************************************************
* this code defines two small programs used to make and name regions
********************************************************************************************************************************************

	capture program drop makeregions
	program define makeregions
		syntax , PARENTvar(varname numeric) CHILDvar(varname numeric) GENerate(name)

		confirm new var `generate'
		
		local is_different 1
		tempvar regions_by_parent
		egen `regions_by_parent' = group(`parentvar')
	
		while `is_different'>0 {
			capture drop `regions_by_child'
			tempvar regions_by_child
			egen `regions_by_child' = min(`regions_by_parent'), by(`childvar')
			tempvar regions_by_parent
			egen `regions_by_parent' = min(`regions_by_child'), by(`parentvar')
			cap assert `regions_by_parent' == `regions_by_child'
			local is_different = _rc
		}
	
		gen `generate' =  `regions_by_child'
	end

****************************************************************************************************
	
	capture program drop nameregions
	program define nameregions
		syntax varname , PARentvar(varname string) CHILDvar(varname string) GENerate(name)
		
		confirm new var `generate'

		tempvar sortorder
		gen `sortorder' = _n
		
		sort `varlist' `parentvar' `childvar'
		gen `generate' = ""

		replace `generate' = `parentvar' in 1
		local totalobs = _N

		forvalues i = 2/`totalobs' {
			if `varlist' ~= `varlist'[_n-1] in `i' {
				replace `generate'= `parentvar' in `i'
			}
			else {
				if `parentvar' == `parentvar'[_n-1] in `i' {
					replace `generate' = `generate'[_n-1] in `i'
				}
				else {
					replace `generate' = `generate'[_n-1] + ", " + `parentvar' in `i'
				}
			}
		}
    
		by `varlist': replace `generate' = `generate'[_N]
		
		sort `sortorder'
	end
****************************************************************************************************



	capture program drop listdistricts
	program define listdistricts
		syntax varname , DISTSTRvar(varname string) GENerate(name)
		
		confirm new var `generate'

		tempvar sortorder
		gen `sortorder' = _n
		
		sort `varlist' `distvar'
		gen `generate' = ""
		
		local distlist = `diststrvar'[1]
		local distlist: list uniq distlist
		local distlist: list sort distlist

		replace `generate' = "`distlist'" in 1
		local totalobs = _N

		forvalues i = 2/`totalobs' {			
			if `varlist' != `varlist'[_n-1] in `i' {
				local distlist = `diststrvar'[`i']
				local distlist: list uniq distlist
				local distlist: list sort distlist
			}
				else {
					local newdist = `diststrvar'[`i']
					local olddistlist = `generate'[`=`i'-1']
					local distlist: list olddistlist | newdist
					local distlist: list uniq distlist
					local distlist: list sort distlist
				}
			
			replace `generate' = "`distlist'" in `i'
		}
    
		bysort `varlist' (`distvar'): replace `generate' = `generate'[_N]
		
		sort `sortorder'
	end
****************************************************************************************************
