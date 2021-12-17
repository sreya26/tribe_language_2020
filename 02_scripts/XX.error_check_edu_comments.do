	
	
******************************************************************************************************
	* various error checks
	* Note: The religion dataset has been checked for gender-wise totals for religions summing to the corresponding number in the total_? column
	* Check was done during data cleaning, assertions confirming the validity of this check included in st_religion do file
******************************************************************************************************

******************************************************************************************************
	* Errors Resolved (11th & 12th August)
******************************************************************************************************
	
	******************************************************************************************************
	* totalm != total_m // 13 obs (Manipur all scheduled tribes obs removed)
	******************************************************************************************************
	
	* Saharsa (urban) - Santal tribe - (savar tribe values assigned incorrectly to santal)  (R)
	* Saharsa (urban) - Savar tribe - (santal tribe values assigned incorrectly to savar) (R)
	* Shahdol district (rural) - (biar or biyar tribe values assigned) (R)
	* Shahdol district (rural) - (bhumiya including bharia and paliha tribe values assigned) (R)
	* Manipur Imphal Town (urban) - Hmar - (education table incorrect total m sums to 54) (R)
	* Manupur Imphal East (rural) - tangkhul tribe - (error in education data, total m sums to 54 not 154) (R)
	* Sundargarh district (urban) - munda, munda-lohara or munda-mahalis - error in census education tables total m sums to 5817 (R)
	* Mayurbhanj district (rural) - Bhuiya or Bhuya -  error in census education tables total m sums to 14899 (R)
	* Birbhum district (rural) - unclassified - error in census education tables total m sums to 2886 (R)
	* Puruliya district (urban) - tribe lohara or lohra in census tables has been incorrectly named as lodha, kheria or kharia (R)
	
	** Gujarat: Baroda Division : dhodia and dubla, including talavia or halpati values interchanged (UNRESOLVED)
	** Maharashtra: Nagpur Division (rural) : tribe called "nagesir" in religion data and nagesia or nagasia in edu data (R)
	
	******************************************************************************************************
	* totalf != total_f // 9 obs (Manipur all scheduled tribes obs removed)
	******************************************************************************************************
	
	* 2 observation pertaining to Shahdol (R)
	* 2 obs pertaining to naming discrepancies for lohara or lohra tribe (R)
	* Imphal west (urban) - angami tribe - error in census education tables - total f sums to 7 (R)
	* Balgaum (rural) - all scheduled tribes - error in census tables for education - total f sums to 23351 (R)
	* Punjab State (rural) - all scheduled tribes - total f is 7168 in census edu tables (R)
	* Lahaul and Spiti (rural) - all scheduled tribes - total f is 7168 in census edu tables (R)
	
	** Gujarat: Baroda Division : dhodia and dubla, including talavia or halpati values interchanged (UNRESOLVED)
	** Maharashtra: Nagpur Division (rural) : tribe called "nagesir" in religion data and nagesia or nagasia in edu data (R)
	
	******************************************************************************************************
	* (illiteratem + literatenoedm + primarym + matricm) != totalm // 32 observations (Manipur all scheduled tribes obs removed)
	******************************************************************************************************
	
	* Himachal Pradesh
	* Mahasu (urban) - all scheduled tribes - no obs in tables
	* Mahasu (urban) - jad, lamba, khampa and bhot or bodh - census table error primary_m = 1 (R)
	
	* Karnataka
	* Bangalore (rural) - soligaru - error in census tables - entries across all education levels missing (R)
	* North Kanara (rural) - all scheduled tribes - error in census tables - entry missing for literate_noed m and other obs displaced to the right (R)
	
	* Madhya Pradesh
	* Sidhi (rural) - all scheduled tribes - error in census tables - matric m changed from 14 to 4 (R)
	
	* Manipur RURAL 
	
	* Manipur (rural) - kabui - error in census table - primary m changed to 760 from 160 (R)
	* Manipur (rural) - maring - error in census tables - literatenoed m changed to 3149 (R)
	* Manipur (rural) - paite - error in census tables  - literatenoed m changed to 4054 (R)
	
	* Imphal east (rural) - hmar -  error in census table - matric m changed to 1 (R)
	* Imphal east (rural) - paite - error in census tables - literatenoed changed to 1 (R)
	* Imphal east (rural) - tangkhul - error in census table - change total m to 54  (R)
	
	* Mao and Sadar Hills (rural) - chiru - literatenoed m change to 49 (R)
	* Jiribam (rural) - simte - change literate_noed m to 1, literate_noed f to 6, next two columns to zero, matric m to 1 (R)
	* Churachandpur (rural) - chiru - error in census tables - literate_noed m changed from 18 to 17 (R)
	
	* Manipur URBAN 
	
	* Manipur (urban) - Hmar - error in census tables - total m changed to 54 (R)
	* Manipur (urban) - koireng - primary m 1 changed to 0, primary f changed to 1 (R)
	* Manipur (urban) - simte - error in census tables - matric m changed to 1 (R)
	* Manipur (urban) - thadou - diplomat m changed to 2 , imphal town part of imphal east illiterate f changed to 15 (R)
	* Manipur (urban) - vaiphui - error in census tables - diplomat m changed to 2 (R)
	* Manipur (urban) - zou - error in census tables - diplomat m changed to 1 (R)
	
	
	* Sundargarh (urban) - munda, munda-lohara or munda-mahalis - total m changed to 5817 (R)
	* Mayurbhanj (rural) - bhuiya or bhuya - total m changed to 14899 (R)
	
	* Nilgiri (rural) - unclassified - matric m changed to zero (R)
	* Tripura (rural) - khasia - primary m changed to 4 (R)
	* Tripura district (rural) - khasia - primary m changed to 4 (R)
	* Birbhum (rural) - unclassified - changed total m to 2886 (R)
	
	******************************************************************************************************
	* (illiteratef + literatenoedf + primaryf + matricf) != totalf // 22 obs (Manipur all scheduled tribes obs removed)
	******************************************************************************************************
	
	* Gujatarat (rural) - pardhi, including advichincher and phanse pardhi - illiterate f changed to 161 , literate f changed to 3 (R)
	* Mysore (rural) - naikda or nayaka including cholivala nayaka, kapadia nayaka, mota nayaka and nana nayaka - literate no ed f changed to 651 (R)
	* Bangalore (rural) - soligaru (R)
	* Balgaum (rural) - all scheduled tribes - error in census tables for education - individual components appear to sum to 23351 (R)
	* North Kanara (rural) - all scheduled tribes (R) 
	* Manipur (rural) - kabui // error in census table // primary f change to 112 (R)
	* Manipur (urban) - koireng (R)
	* Manipur (rural) - kom // error in census tables // illiterate f changed to 2200 (R)
	* Manipur (urban) - kom // error in census tables // literatenoed f changed to 6 (R)
	* Imphal West (urban) - anal // error in census table// primary f changed to 2 (R)
	* Imphal west (urban) - angami (R)
	* Imphal east (urban) - thadaou (R)
	* Bishenpur (rural) - gangte // error in census table // illiterate f changed to 3 (R)
	* Bishenpur (rural) - all scheduled tribes (R)
	* Jiribam (rural) - simte (R)
	* Balasore (rural) - bathudi // changed to 3562 illiterate f (R)
	* Punjab State (rural) - all scheduled tribes // total f is 7168 in census edu tables (R)
	* Lahaul and Spiti (rural) - all scheduled tribes // total f is 7168 in census edu tables (R)
	
	
	******************************************************************************************************
	** genderwise totals do not add up for these divisions //12 obs
	******************************************************************************************************
	
	/*
	tot m
	gujarat baroda division (rural) - unclassified - interchange matric m and f (R)
	manipur sadar hills (rural) - maram - error in census table - total m changed to 278 (R)
	manipur sadar hills (rural) - tangkhul - error in census table matric m changed to 2 (R)
	belonia sub division (rural) - all - literate m and primary m changed to 1395 and 255 (R)
	sadar sub division (rural) - santal - literate m changed to 18 (R)
	udaipur sub division (rural) - riang - total m changed to 1176(R)
	
	tot f
	chotanagpur division (urban) - santal - matric f changed to 1 (R)
	baroda division (rural) - unclassified - interchange matric m and f (R)
	bilaspur division - all scheduled tribes - error in census tables - matric f changed to 29 (R)
	bilaspur division (rural) - bhaina - error in census table - illiterate f changed to 9017 (R)
	jabalpur division (urban) - bhunjia - total f changed to 2 (R)
	*/
	
	******************************************************************************************************
	** individual tribe components do not sum to all scheduled tribes
	******************************************************************************************************
	
	** Balgaum (R)
	** Baroda Division (R)
	** Belonia Sub Division (R)
	** Bilaspur Division (R)
	** Bombay Division // gond aggregate and pardhi aggregate changed to gond group a and pardhi group a (R)
	** Chotanagpur division (R)
	** Jabalpur Division (R)
	** Poona Division // gond aggregate and pardhi aggregate changed to gond group a and pardhi group a (R)
	** Sadar Sub Division (R)
	** Udaipur Sub division  (R)
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
