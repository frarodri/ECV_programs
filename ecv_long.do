/* 
This code merges the different data files of the Spanish Encuesta de 
Condiciones de Vida (ECV) for each year, appends them and renames and labels 
the variables following as closely as possible IPUMS naming conventions.
 
You should create 4 folders called rawdata, output, intermediate and 
ECV_programs. Download the data from INE's website and unzip as is in rawdata. 
Place this code in ECV_programs. The final dataset will be stored in output. 
Change the folder structure of this code at your own risk!  
Authors: Lidia Cruces, F. Javier Rodríguez-Román 
*/

clear all
set more off

* Write here the main folder, where the folders rawdata, output, intermediate 
* and programs are located:
global rootdir "G:\My Drive\ECV\working"
global rawdata "$rootdir\rawdata"
global output "$rootdir\output"
global intermediate "$rootdir\intermediate"
global programs "$rootdir\ECV_programs"

cd "$rootdir"

* Write here the final years for the longitudinal files you want to have in the 
* final dataset: 
local years "07 08 09"

********************************
* Merge the longitudinal files *
********************************

foreach t of local years {

	* Merge the household basic data file (fichero d) and the household data 
	* file (fichero h)
	cd "$rawdata"
	import delimited es`t'h, delimiter(",") clear

	rename (hb010 hb020 hb030) (db010 db020 db030)
	cd "$intermediate"
	save ecv_h.dta, replace

	cd "$rawdata"
	import delimited es`t'd, delimiter(",") clear

	cd "$intermediate"
	merge 1:1 db010 db020 db030 using ecv_h.dta, generate(_mergedh)

	save ecv_dh.dta, replace
	erase ecv_h.dta
	
	* Merge the person basic data file (fichero r) and the adult detailed data 
	* file (fichero p)
	cd "$rawdata"
	import delimited es`t'p, delimiter(",") clear
	rename (pb010 pb020 pb030) (rb010 rb020 rb030)

	cd "$intermediate"
	save ecv_p.dta, replace

	cd "$rawdata"
	import delimited es`t'r, delimiter(",") clear
	duplicates drop rb010 rb020 rb030, force

	cd "$intermediate"
	merge 1:1 rb010 rb020 rb030 using ecv_p.dta, generate(_mergerp)

	save ecv_rp.dta, replace
	erase ecv_p.dta
	
	* Merge with household data
	
	rename (rb010 rb020 rb040) (db010 db020 db030) 
	
	merge m:1 db010 db020 db030 using ecv_dh.dta, generate(_mergedhrp)
	
	* Drop observations that are not matched
	drop if _mergedhrp!=3
	
	destring _all, replace

	save ecv_long_`t'.dta, replace
	erase ecv_dh.dta
	erase ecv_rp.dta	
	
}

********************
* Append all years *
********************

foreach t of local years {

	if "`t'"==word("`years'", 1) {
		use ecv_long_`t', clear
	}
	
	else {
		append using ecv_long_`t'
	}	
}
	
*************************
* Renaming and labeling *
*************************

* Fichero r: person basic data *
********************************

* Basic information
rename db010 year
rename db020 country
rename rb030 id_long
rename db030 id_hh
rename rb060 perwt_basic
rename rb060_f perwt_basic_f
rename rb062 perwt_long2
rename rb062_f perwt_long2_f
rename rb063 perwt_long3
rename rb063_f perwt_long3_f
rename rb064 perwt_long4
rename rb064_f perwt_long4_f
rename rb100 insample
rename rb100_f insample_f
rename rb070 birthmo
rename rb070_f birthmo_f
rename rb080 birthyr
rename rb080_f birthyr_f
rename rb090 sex
rename rb090_f sex_f
rename rb110 hhsit
rename rb110_f hhsit_f
rename rb120 newloc
rename rb120_f newloc_f
rename rb140 dismo
rename rb140_f dismo_f
rename rb150 disyr
rename rb150_f disyr_f
rename rb160 monthsinhh
rename rb160_f monthsinhh_f
rename rb170 activityper
rename rb170_f activityper_f
rename rb180 arrivemo
rename rb180_f arrivemo_f
rename rb190 arriveyr
rename rb190_f arriveyr_f 
rename rb200 inhh
rename rb200_f inhh_f
rename rb210 activitylastwk_raw
rename rb210_f activitylastwk_raw_f
rename rb220 poploc
rename rb220_f poploc_f
rename rb230 momloc
rename rb230_f momloc_f
rename rb240 sploc
rename rb240_f sploc_f

label var year "Year"
label var country "Country"
label var id_long "Longitudinal identifier"
label var id_hh "Household identifier"
label var perwt_basic "Basic person weight"
label var perwt_basic_f "Basic person weight flag"
label var perwt_long2 "Longitudinal weight 2 years"
label var perwt_long2_f "Longitudinal weight 2 years flag"
label var perwt_long3 "Longitudinal weight 3 years"
label var perwt_long3_f "Longitudinal weight 3 years flag"
label var perwt_long4 "Longitudinal weight 4 years"
label var perwt_long4_f "Longitudinal weight 4 years flag"
label var insample "Sample or co-resident person"
label var insample_f "Sample or co-resident person flag"
label var birthmo "Birth month"
label var birthmo_f "Birth month flag"
label var birthyr "Birth year"
label var birthyr_f "Birth year flag"
label var sex "Sex"
label var sex_f "Sex flag"
label var hhsit "Situation in household"
label var hhsit_f "Situation in household flag"
label var newloc "New location"
label var newloc_f "New location flag" 
label var dismo "Month of relocation or death"
label var dismo_f "Month of relocation or death flag"
label var disyr "Year of relocation or death"
label var disyr_f "Year of relocation or death flag"
label var monthsinhh "Number of months in household"
label var monthsinhh_f "Number of months in household flag"
label var activityper "Main activity during reference period"
label var activityper_f "Main activity during reference period flag"
label var arrivemo "Month of arrival to household"
label var arrivemo_f "Month of arrival to household flag"
label var arriveyr "Year of arrival to household"
label var arriveyr_f "Year of arrival to household flag"
label var inhh "Living in household"
label var inhh_f "Living in household flag"
label var activitylastwk_raw "Activity last week"
label var activitylastwk_raw_f "Activity last week flag"
label var poploc "Father's identifier"
label var poploc_f "Father's identifier flag"
label var momloc "Mother's identifier"
label var momloc_f "Mother's identifier flag"
label var sploc "Spouse's identifier"
label var sploc_f "Spouse's identifier flag"

label define sex_lbl ///
1 "Male" ///
2 "Female" 
label values sex sex_lbl

label define inhh_lbl ///
1 "Lives in the household" ///
2 "Temporarily out of the household"
label values inhh inhh_lbl

label define activitylastwk_lbl ///
1 "Working" ///
2 "Not working" ///
3 "Retired" ///
4 "Other" 
label values activityper activitylastwk_raw activitylastwk_lbl

* Fichero p: person detailed data *
***********************************

* Basic information
rename pb050 perwt_16plus
rename pb050_f perwt_16plus_f
rename pb100 intmo
rename pb100_f intmo_f
rename pb120 intmin
rename pb120_f intmin_f
rename pb130 birthmo_16plus
rename pb130_f birthmo_16plus_f
rename pb140 birthyr_16plus
rename pb140_f birthyr_16plus_f
rename pb150 sex_16plus
rename pb150_f sex_16plus_f
rename pb160 poploc_16plus
rename pb160_f poploc_16plus_f
rename pb170 momloc_16plus
rename pb170_f momloc_16plus_f
rename pb180 sploc_16plus
rename pb180_f sploc_16plus_f
rename pb190 marst
rename pb190_f marst_f
rename pb200 marstleg
rename pb200_f marstleg_f

label var marst "Marital status"
label var marst_f "Marital status flag"
label var marstleg "Legal status of marital union"
label var marstleg_f "Legal status of marital union flag"

label define marst_lbl ///
1 "Single" ///
2 "Married" ///
3 "Separated" ///
4 "Widow/widower" ///
5 "Divorced"
label values marst marst_lbl

label define marstleg_lbl ///
1 "Legal basis" ///
2 "No legal basis" ///
3 "Not in union"
label values marstleg marstleg_lbl

* Education
rename pe040 educ
rename pe040_f educ_f

label var educ "Educational attainment"
label var educ_f "Educational attainment flag"

label define educ_lbl ///
1 "Primary" ///
2 "First stage secondary" ///
3 "Second stage secondary" ///
4 "Post-secondary non college" ///
5 "College"
label values educ educ_lbl

* Employment
rename pl030 activity_raw
rename pl030_f activity_raw_f
rename pl020 looking_4wk
rename pl020_f looking_4wk_f
rename pl025 available_2wk
rename pl025_f available_2wk_f
rename pl040 classwkr_raw
rename pl040_f classwkr_raw_f
rename pl050 occ_raw
rename pl050_f occ_raw_f
rename pl060 uhrswrk_raw
rename pl060_f uhrswrk_raw_f
rename pl140 contype
rename pl140_f contype_f
rename pl160 jobch
rename pl160_f jobch_f
rename pl170 jobchreason
rename pl170_f jobchreason_f
rename pl180 actch
rename pl180_f actch_f
rename pl190 agewrk 
rename pl190_f agewrk_f
rename pl200 experyrs
rename pl200_f experyrs_f
rename pl210a activity_m1
rename pl210a_f activity_1_f
rename pl210b activity_m2
rename pl210b_f activity_2_f
rename pl210c activity_m3
rename pl210c_f activity_3_f
rename pl210d activity_m4
rename pl210d_f activity_4_f
rename pl210e activity_m5
rename pl210e_f activity_5_f
rename pl210f activity_m6
rename pl210f_f activity_6_f
rename pl210g activity_m7
rename pl210g_f activity_7_f
rename pl210h activity_m8
rename pl210h_f activity_8_f
rename pl210i activity_m9
rename pl210i_f activity_9_f
rename pl210j activity_m10
rename pl210j_f activity_10_f
rename pl210k activity_m11
rename pl210k_f activity_11_f
rename pl210l activity_m12
rename pl210l_f activity_12_f

label var activity_raw "Self-reported activity"
label var activity_raw_f "Self-reported activity flag"
label var looking_4wk "Looked for work in the past 4 weeks"
label var looking_4wk_f "Looked for work in the past 4 weeks flag"
label var available_2wk "Is available to work within next 2 weeks"
label var available_2wk_f "Is available to work within next 2 weeks flag"
label var classwkr_raw "Class of worker"
label var classwkr_raw_f "Class of worker flag"
label var occ_raw "Current or last occupation"
label var occ_raw_f "Current or last occupation flag"
label var uhrswrk_raw "Usual hours worked per week"
label var uhrswrk_raw_f "Usual hours worked per week flag"
label var contype "Type of contract"
label var contype_f "Type of contract flag"
label var jobch "Changed jobs in last 12 months"
label var jobch_f "Changed jobs in last 12 months flag"
label var jobchreason "Reason for job change"
label var jobchreason_f "Reason for job change flag"
label var actch "Most recent activity change"
label var actch_f "Most recent activity change flag"
label var agewrk "Age started working regularly"
label var agewrk_f "Age started working regularly flag"
label var experyrs "Years worked"
label var experyrs_f "Years worked flag"
label var activity_m1 "Main activity January"
label var activity_1_f "Main activity January flag"
label var activity_m2 "Main activity February"
label var activity_2_f "Main activity February flag"
label var activity_m3 "Main activity March"
label var activity_3_f "Main activity March flag"
label var activity_m4 "Main activity April"
label var activity_4_f "Main activity April flag"
label var activity_m5 "Main activity May"
label var activity_5_f "Main activity May flag"
label var activity_m6 "Main activity June"
label var activity_6_f "Main activity June flag"
label var activity_m7 "Main activity July"
label var activity_7_f "Main activity July flag"
label var activity_m8 "Main activity August"
label var activity_8_f "Main activity August flag"
label var activity_m9 "Main activity September"
label var activity_9_f "Main activity September flag"
label var activity_m10 "Main activity October"
label var activity_10_f "Main activity October flag"
label var activity_m11 "Main activity November"
label var activity_11_f "Main activity November flag"
label var activity_m12 "Main activity December"
label var activity_12_f "Main activity December flag"

label define activity_raw_lbl ///
1 "Full time worker" ///
2 "Part time worker" ///
3 "Unemployed" ///
4 "Student" ///
5 "Retired or closed business" ///
6 "Permanently disabled for work" ///
7 "Military service" ///
8 "Homemaker" ///
9 "Other"
label values activity_raw activity_raw_lbl
 
label define classwkr_raw_lbl ///
1 "Employer" ///
2 "Self-employed without employees" ///
3 "Employee" ///
4 "Family help" 
label values classwkr_raw classwkr_raw_lbl

label define contype_lbl ///
1 "Open-ended" ///
2 "Fixed-term" 
label values contype contype_lbl

label define activity_months_lbl ///
1 "Full-time employee" ///
2 "Part-time employee" ///
3 "Full-time self-employed" ///
4 "Part-time self-employed" ///
5 "Unemployed" ///
6 "Retired" ///
7 "Student" ///
8 "Other type of inactivity" ///
9 "Military service"
label values activity_m* activity_months_lbl

* Health

* Income

* Fichero d: household basic data *
***********************************

rename db040 region_ca
rename db040_f region_ca_f
rename db060 psu
rename db060_f psu_f
rename db075 rotgroup
rename db075_f rotgroup_f
rename db090 hhwt
rename db090_f hhwt_f
rename db100 urbdenlvl
rename db100_f urbdenlvl_f

* Fichero h: household detailed data *
**************************************

**********************
* Generate variables *
**********************

* Age
gen age=year-birthyr
label var age "Age"

* Yearly labour force participation

* First we recode the monthly main activity variables into labor force 
* participation variables ft, pt, ue and olf, which contain the the number of 
* months that the person spent working full time, part time, unemployed and out 
* of the labor force, respectively. 

* Full time employment
recode activity_m* (1 3 = 1) (nonmi = 0), pre(ft_)
rename ft_activity_m* ft_m*
egen ftmonths=rowtotal(ft_*)
label var ftmonths "Months spent working full time last year"
drop ft_m1-ft_m12

* Part time employment
recode activity_m* (2 4 = 1) (nonmi = 0), pre(pt_)
rename pt_activity_m* pt_m*
egen ptmonths=rowtotal(pt_*)
label var ptmonths "Months spent working part time last year"
drop pt_m1-pt_m12

* Unemployment
recode activity_m* (5 = 1) (nonmi = 0), pre(ue_)
rename ue_activity_m* ue_m*
egen uemonths=rowtotal(ue_*)
label var uemonths "Months spent unemployed last year"
drop ue_m1-ue_m12

* Out of labor force
recode activity_m* (6/9 = 1) (nonmi = 0), pre(olf_)
rename olf_activity_m* olf_m*
egen olfmonths=rowtotal(olf_*)
label var olfmonths "Months spent out of labour force last year"
drop olf_m1-olf_m12

* Unique person-year identifiers
egen pid = concat(year id_long), format(%15.0g) 
egen sid = concat(year sploc) if !missing(sploc), format(%15.0g) 
egen fid = concat(year poploc) if !missing(poploc), format(%15.0g) 
egen mid = concat(year momloc) if !missing(momloc), format(%15.0g) 

destring pid-mid, replace

bysort id_long year: egen longwt_2=max(perwt_long2)
bysort id_long year: egen longwt_3=max(perwt_long3)
bysort id_long year: egen longwt_4=max(perwt_long4)

bysort id_long year: egen longwt_2_f=max(perwt_long2_f)
bysort id_long year: egen longwt_3_f=max(perwt_long3_f)
bysort id_long year: egen longwt_4_f=max(perwt_long4_f)

cd "$intermediate"
local years "04-07, 05-08 and 06-09"
label data "Longitudinal ECV for `years'"
save ecv_long, replace 
















 
























