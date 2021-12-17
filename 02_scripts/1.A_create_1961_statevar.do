* this program takes a state code variable (can be from census 2001, 2011 or DISE 2013-14) and creates a state variable for census 1961

capture program drop create_1961_statevar
program define create_1961_statevar
	syntax varname(numeric) , GENerate(name)
	
	confirm new var `generate'
	
	gen `generate' = ""
	replace `generate' = "Andhra Pradesh" if `varlist' == 28
	replace `generate' = "North East Frontier Agency" if `varlist' == 12
	replace `generate' = "Assam" if inlist(`varlist',15,17,18)
	replace `generate' = "Bihar" if inlist(`varlist',10,20)
	replace `generate' = "Goa, Daman and Diu" if inlist(`varlist',25,30)
	replace `generate' = "Gujarat" if `varlist' == 24
	replace `generate' = "Himachal Pradesh" if `varlist' == 2
	replace `generate' = "Jammu & Kashmir" if `varlist' == 1
	replace `generate' = "Mysore" if `varlist' == 29
	replace `generate' = "Kerala" if `varlist' == 32
	replace `generate' = "Madhya Pradesh" if inlist(`varlist',22,23)
	replace `generate' = "Maharashtra" if `varlist' == 27
	replace `generate' = "Manipur" if `varlist' == 14
	replace `generate' = "Nagaland" if `varlist' == 13
	replace `generate' = "Orissa" if `varlist' == 21
	replace `generate' = "Punjab" if inlist(`varlist',3,4,6)
	replace `generate' = "Rajasthan" if `varlist' == 8
	replace `generate' = "Sikkim" if `varlist' == 11
	replace `generate' = "Madras" if `varlist' == 33
	replace `generate' = "Tripura" if `varlist' == 16
	replace `generate' = "Uttar Pradesh" if inlist(`varlist',5,9)
	replace `generate' = "West Bengal" if `varlist' == 19
	replace `generate' = "Andaman & Nicobar Islands" if `varlist' == 35
	replace `generate' = "Dadra and Nagar Haveli" if `varlist' == 26
	replace `generate' = "Delhi" if `varlist' == 7
	replace `generate' = "Laccadive, Minicoy and Amindivi Islands" if `varlist' == 31
	replace `generate' = "Pondicherry" if `varlist' == 34
end
