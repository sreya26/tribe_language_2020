************************************************************************************************************************************
* this file generates the dataset for the tribelanguage paper (Tarun Jain, Hemanshu Kumar, Rohini Somanathan) from scratch
*! version 1.0 created by Hemanshu Kumar, July 2020 : this is the first version to be compliant with the -project- command
*! version 2.0 created by Sreya Majumder, August 2021 : incorporates cleaned 1961 data 
* this is the first version to be compliant with the -project- command
************************************************************************************************************************************

************************************************************************************************************************************
* Step #1
* this portion puts together the mother tongue data files from Census 1961, and puts in the requisite district codes

project , do("1.01a_append_census61_language_files.do")
project , do("1.01b_apply_district_codes_to_census61_language_data.do")
************************************************************************************************************************************

************************************************************************************************************************************
* Step #2
* this portion puts together the edu data files from Census 1961, and puts in the requisite district codes

project , do("1.02a_append_census61_edu_files.do")
project , do("1.02b_apply_district_codes_to_census61_edu_data.do")


************************************************************************************************************************************
* Step #3
* this portion puts together the religion data files from Census 1961, and puts in the requisite district codes

project , do("1.03a_append_census61_religion_files.do")
project , do("1.03b_append_census61_ag_religion_files.do")
project , do("1.03c_apply_district_codes_to_census61_religion_data.do")


************************************************************************************************************************************
* Step #4
* this portion runs the error check do files on the religion, language and edu data 
* and merges together the religion and education data 

project , do("1.04a_error_check_religion_language.do")
project , do("1.04b_edu_religion_1961_merge.do")

************************************************************************************************************************************
* Step #5
* this portion appends the original census 2011 education files for individual Scheduled Tribes at the state and district level
* it then combines and retains the relevant parts of the census 2011 education files (i.e. education levels + age groups 
* it also appends the original census 2011 education files for all Scheduled Caste and Overall Popn at the state and district level 

project , do("1.05a_append_census2011_st_edu_files.do")
project , do("1.05b_combine_census2011_st_edu_files.do")
project , do("1.05c_append_combine_census2011_overall_sc_files.do")

************************************************************************************************************************************
* Step #6
* this portion generates tribe groups (across states) using Census 1961 and 2011 data, using a largely automated algorithm
* and creates a merge correspondence between the tribe groups in the two censuses

project , do("1.06_st_1961_2011_groups_automated.do")



************************************************************************************************************************************
* Step #7
* this portion takes the census1961mothertongue_distcoded.dta file created above, and
* applies tribe codes to it using the st_groups_with_states_1961.dta file created above
* this generates the file census_1961_mothertongue_data_with_dist_tribe_codes.dta

project , do("1.07_apply_tribe_codes_to_census1961_language_data.do")

************************************************************************************************************************************
* Step #8
* this portion matches the languages in the Census 1961 mother tongue tables with those in Ethnologue
* this will then be used to construct our measure of linguistic distance using the Ethnologue language tree.

project , do("1.08a_import_ethnologue_tree.do") // takes Ethnologue Language Tree.xlsx and creates ethnologue_tree.dta
project , do("1.08b_merge_language_census_ethnologue.do") // generates matched_language_list.dta [this do-file is also used for the manual merge process]


************************************************************************************************************************************
* Step #9
* create consistent regions between 1961 and 2013-14
 
project , do("1.09_make_regions.do")

************************************************************************************************************************************
* Step #10
* this portion imports the DISE data on medium of instruction, codes it appropriately, gives it codes for consistent 1961-2013 regions
* it extracts information on modal medium of instruction for each region and generates the file dise_modal_languages.dta
* it also extracts information of the distribution of media of instruction in each district by schools and by enrolment (the latter for for both overall pop and STs)
* and produces the file dise_lang_distribution.dta
 
project , do("1.10a_import_dise_basic_general_data.do")
project , do("1.10b_import_dise_enrolment_data.do")
project , do("1.10c_get_dise_medium_of_instruction.do")
************************************************************************************************************************************

************************************************************************************************************************************
* Step #11
* this portion creates linguistic distance variable(s) for the the Census 1961 language data
* the data on total speakers is aggregated to regions (districts/supra-district areas) with consistent boundaries between 1961-2013.
* it generates the file census_1961_mothertongue_for_analysis_distance.dta

project , do("1.11_apply_linguistic_distance_to_census1961_language_data.do")

************************************************************************************************************************************

************************************************************************************************************************************
* Step #12
* this portion takes the Census 2011 ST education data for individual tribes, attaches tribal group codes 
* the data is collapsed to regions with consistent boundaries between 1961-2013.

project , do("1.12a_prepare_census2011_st_edu_data.do")
project , do("1.12b_combine_census2011_agg_edu_religion_files.do")


************************************************************************************************************************************

************************************************************************************************************************************
* Step #13
* this portion applies tribe codes to the merged edu and religion data 
* and then codes it appropriately (this includes aggregating the data to consistent 1961-2013 regions)

project , do("1.13_apply_district_tribe_group_codes_to_1961_st_edu_data.do")

************************************************************************************************************************************

************************************************************************************************************************************
* Step #14
* puts everything together

project , do("1.14a_code_scheduled_tribal_areas.do")
project , do("1.14_make_lang_workfile.do")
************************************************************************************************************************************








