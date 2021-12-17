*! Author: Hemanshu Kumar, hemanshu@econdse.org
*! version 2.1 17 Apr 2017
*! version 2.0 03 Aug 2016
*  version 1.0 22 Aug 2015

/*
  changelog: 
  version 2.1 includes the following changes
 + better handling of string variables: shortens the varable to its first 30 characters
  version 2 includes the following changes
+ uses the command labvalch3 in the labutil2 package
+ adds the options -tabmiss- and -cardinal-
*/

capture which labvalch3
if _rc == 111 ssc install labutil2

#delimit ;

* 
	only a single variable name is allowed to be passed
	specifying a file is compulsory
	-append- specifies that output must be appended to the specified file
	-replace- specified that the specified file must be over-written by the program output
	-question- optionally allows us to specify a survey question string associated with the variable
	-note- optionally allows us to specify a note or description
	-topn- optionally allows the user to specify how many of the most frequent values of a variable should be tabulated
	-tabmiss- optionally requests a tabulation of missing values, if any
	-cardinal- optionally requests calculation of mean and sd of the variable (also creates a stats table for any numeric var)

*; 

capture program drop latex_codebook ;
program define latex_codebook ;

version 14.0 ;

syntax varname using/ [if] [in] , 
	[APPEND] [REPLACE]
	[TABMISSing]
	[CARDinal]
	[Question(string)] 
	[NOTE(string)] 
	[TOPn(numlist >=1 <=40 min=1 max=1 integer)] 
	[SIZE(string)];

	
marksample touse, novarlist ;

* check that a tex file has been specified ;
if substr("`using'",-4,.) ~= ".tex" { ;
	dis as error "A LaTeX file must be specified in -using-. The file must have the extension \`.tex'." ;
	error 498 ; 
	} ;

* check that one out of append or replace has been specified ;
	
if "`append'" == "" & "`replace'" == "" {	;
	dis as error "Either of append or replace options is required"	;
	error 498 ;
	}	;
	
if "`replace'"~= "" local replace_append `" using `using', replace "' ;
	else local replace_append `" , appendto("`using'") "' ;

	
* if a note has been specified, prepend it with "Note: " ;
if "`note'"~= "" local note = "\textbf{Note:} " + "`note'" + "\\" ;
	
* if -topn- has not been specified, default to 10 values ;

if "`topn'" == "" local topn 10 ;

* if -size- has not been specified default to small ;
if "`size'" == "" local size "small" ;

* check that specified size is legal ;
local fontsizes Huge huge LARGE Large large normalsize small footnotesize scriptsize tiny ;
if `:list posof "`size'" in fontsizes' == 0	{ ;
	dis as error "Legal font sizes are: "
	_n "`fontsizes'" ;
	error 498 ;
	} ;
	
preserve ;

keep if `touse' ;
	
local var `varlist' ;

local var_disp: subinstr local var "_" "\_" , all ;
	
qui distinct `var' ;
local numlevels `r(ndistinct)' ;

local type: type `var' ;
local varlabel: var label `var' ;
if "`varlabel'" == "" local varlabel "No label" ;
local valuelabel: value label `var' ;
if "`valuelabel'" == "" local valuelabel "None" ;

local valuelabel_disp "`valuelabel'" ;

foreach char in _ # & { ;
	local varlabel: subinstr local varlabel "`char'" "\\`char'" , all ;
	local valuelabel_disp: subinstr local valuelabel_disp "`char'" "\\`char'" , all ;
} ;

foreach char in < > = { ;
	local varlabel: subinstr local varlabel "`char'" "$`char'$" , all ;
} ;

if "`valuelabel'" ~= "None" { ;
	foreach char in _ # & { ;
		labvalch3 `valuelabel' , subst("`char'" "\\`char'") ;
	} ;
} ;
	
qui count if missing(`var') ;
local miss: dis %8.0gc `r(N)' ;
qui count ;
local total: dis %8.0gc `r(N)' ;
	
	
if inrange(`numlevels',0,20) {	;
	contract `var', freq(count) percent(fraction) ;
	tostring fraction, usedisplayformat force replace ;
	replace fraction = fraction + "\%" ;
		
	format count %10.0fc ;
		
	if "`valuelabel'" ~= "None" { ;
		decode `var', gen(range_text) ;
		local labcol "l" ;
		local labhead " & {Label}" ;
		} ;
	
	if strpos("`type'","str") > 0 { ;
		replace `var' = substr(`var',1,30) ;
		foreach char in _ # & { ;
			replace `var' = subinstr(`var',"`char'","\\`char'",.) ;
			} ;
		} ;
		
	listtab
		`replace_append'
		rstyle(tabular)
		nolabel
		head(`"\\`size' \FloatBarrier"' `"\bigbreak"' `"\noindent\hrulefill \\"' `"\textbf{\texttt{`var_disp'}} \hfill \`\``varlabel'''\\"'
			`"Value label: \texttt{`valuelabel_disp'} \hfill Type: `type' \hfill Missing: `miss' /`total' \\"'
			`"\hrule "'
			`"\emph{`question'} \\"'
			`"`note'"'
			`"\begin{table}[!htbp]\centering"'
			`"\begin{tabular}{rrS`labcol'}"' `"\toprule"' 
			`"{Value} & {Count} & {Percentage} `labhead' \\"'
			`"\midrule"')
		foot(`"\bottomrule"'
			`"\end{tabular}"' 
			`"\end{table}"' `"\FloatBarrier"')
		;
	
	} ;
		
else { ;

	if "`valuelabel'" ~= "None" { ;
		qui label li `valuelabel' ;
		local minlabel = r(min)   ;
		} ;

	qui sum `var', detail ;
	
	if "`valuelabel'" ~= "None" & strpos("`type'","str") == 0 { ; 
				local min: dis %6.0fc `r(min)' ;
				local max: dis %6.0fc `r(max)' ;
				local median: dis %6.0fc `r(p50)' ;							
				} ;
				
	if (("`valuelabel'" == "None") | ("`valuelabel'" ~= "None" & "`minlabel'" == ".")) & strpos("`type'","str") == 0 { ;
				local min: dis %10.2fc `r(min)' ;
				local max: dis %10.2fc `r(max)' ;
				local mean: dis %10.2fc `r(mean)' ;
				local sd: dis %10.2fc `r(sd)' ;
				local median: dis %10.2fc `r(p50)' ;			
				} ;
			
	if strpos("`:format `var''","%t")>0 { ;
				local min: dis `:format `var'' `r(min)' ;
				local max: dis `:format `var'' `r(max)' ;
				local median: dis `:format `var'' `r(p50)' ;
				} ;
			
	contract `var', freq(count) percent(fraction) ;
	tostring fraction, usedisplayformat force replace ;
	replace fraction = fraction + "\%" ;
		
	format count %10.0fc ;
	
	gsort -count ;
	drop if missing(`var') ;
	keep in 1/`topn' ;

	if "`valuelabel'" ~= "None" decode `var', gen(range_text) ;
	
	if ("`valuelabel'" ~= "None" & "`minlabel'"~= "." ) | strpos("`:format `var''","%t")>0 { ;
		local cols "ccc" ;
		local heads "Min & Max & Median" ;
		local stats "`min' & `max' & `median'" ;
		} ;
	else { ;
		local cols "ccccc" ;
		local heads "Min & Max & Median & Mean & Std Dev" ;
		local stats "`min' & `max' & `median' & `mean' & `sd'" ;
		} ;
			
	if strpos("`type'","str") == 0 { ;
		local stats_table `" "\smallbreak" 
			"\begin{table}[!htbp]\centering" 
			"\begin{tabular}{`cols'}" 
			"\toprule" 
			"`heads' \\" 
			"\midrule" 
			"`stats' \\" 
			"\bottomrule" 
			"\end{tabular}" "\end{table}" "'
			;
		} ;
	else local stats_table "" ; 

	if "`valuelabel'" ~= "None" { ;
		local labcol "l" ;
		local labhead " & {Label}" ;
		} ;
	
	if strpos("`type'","str") > 0 { ;
		replace `var' = substr(`var',1,30) ;
		foreach char in _ # & { ;
			replace `var' = subinstr(`var',"`char'","\\`char'",.) ;
			} ;
		} ;
		
	listtab
		`replace_append'
		rstyle(tabular)
		nolabel
		head(`"\\`size' \FloatBarrier"' `"\bigbreak"' `"\noindent\hrulefill \\"' `"\textbf{\texttt{`var_disp'}} \hfill \`\``varlabel'''\\"'
			`"Value label: \texttt{`valuelabel_disp'} \hfill Type: `type' \hfill Missing: `miss' /`total' \\"'
			`"\hrule "'
			`"\emph{`question'} \\"'
			`"`note'"'
			`stats_table'					
			`"\medbreak Number of distinct values: `: dis %8.0gc `numlevels'' \\"'
			`"Distribution of the `topn' most common values:"' 
			`"\begin{table}[!htbp]\centering"'
			`"\begin{tabular}{rrS`labcol'}"' `"\toprule"' 
			`"{Value} & {Count} & {Percentage} `labhead'\\"'
			`"\midrule"')
		foot(`"\bottomrule"'
			`"\end{tabular}"' `"\end{table}"' `"\FloatBarrier"')
		;
		
	} ;	

restore ;

end ;

#delimit cr

