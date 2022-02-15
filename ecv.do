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
*global rootdir  "C:\Users\lidic\OneDrive\Escritorio\Cruces&Rodríguez\Encuesta de Condiciones de Vida\ECV\working"
global rawdata "$rootdir\rawdata"
global output "$rootdir\output"
global intermediate "$rootdir\intermediate"
global programs "$rootdir\ECV_programs"

cd "$rootdir"

* Choose here which years you want to have in the final dataset: 
local years "04 05 06 07 08"
local tofrom "04_08"
local base "04"

**************************************************
* Merge the cross-section datasets for each year *
**************************************************

foreach t of local years {

	* Merge the household basic data file (fichero d) and the household data 
	* file (fichero h)
	cd "$rawdata"
	import delimited esudb`t'h, delimiter(",") clear

	rename (hb010 hb020 hb030) (db010 db020 db030)
	cd "$intermediate"
	save ecv_h.dta, replace

	cd "$rawdata"
	import delimited esudb`t'd, delimiter(",") clear

	cd "$intermediate"
	merge 1:1 db010 db020 db030 using ecv_h.dta, generate(_mergedh)

	save ecv_dh.dta, replace
	erase ecv_h.dta

	* Merge the person basic data file (fichero r) and the person data file 
	* (fichero p)
	cd "$rawdata"
	import delimited esudb`t'p, delimiter(",") clear
	rename (pb010 pb020 pb030) (rb010 rb020 rb030)

	cd "$intermediate"
	save ecv_p.dta, replace

	cd "$rawdata"
	import delimited esudb`t'r, delimiter(",") clear

	cd "$intermediate"
	merge 1:1 rb010 rb020 rb030 using ecv_p.dta, generate(_mergerp)

	save ecv_rp.dta, replace
	erase ecv_p.dta

	* Note: there are some observations that are only in the master data 
	* (fichero r) that correspond to people 16 years old and younger. 

	* Retrieve the household's identifier from the person's identifier
	tostring rb030, generate(id)
	generate pernum=substr(id,-2,.)
	destring pernum, replace
	generate id_reverse=strreverse(id) 
	generate db030_reverse=substr(id_reverse,3,.)
	generate db030=strreverse(db030_reverse)
	destring db030, replace
	drop id id_reverse db030_reverse

	label var pernum "Person's number within household"

	* Merge with household data
	rename (rb010 rb020) (db010 db020)

	cd "$intermediate"
	merge m:1 db010 db020 db030 using ecv_dh.dta, generate(_mergedhrp)
	
	destring _all, replace

	save ecv_`t'.dta, replace
	erase ecv_dh.dta
	erase ecv_rp.dta	
	
}

********************
* Append all years *
********************

foreach t of local years {

	if "`t'"==word("`years'", 1) {
		use ecv_`t', clear
	}
	
	else {
		append using ecv_`t'	
	}	
}

cd "$output"

label data "ECV for `years'"
save ecv_`tofrom', replace 

*************************
* Renaming and labeling *
*************************

* Basic person data (fichero p) *
*********************************

* Basic information and childcare *
* Rename variables
rename db010 year
rename db020 country
rename rb030 pid
rename rb050 perwt_cs
rename rb050_f perwt_cs_f
rename rb070 birthmo
rename rb070_f birthmo_f
rename rb080 birthyr 
rename rb080_f birthyr_f
rename rb090 sex
rename rb090_f sex_f
rename rb200 sith
rename rb200_f sith_f
rename rb210 act_lastwk
rename rb210_f act_lastwk_f
rename rb220 fid
rename rb220_f fid_f
rename rb230 mid
rename rb230_f mid_f
rename rb240 sid
rename rb240_f sid_f
rename rl010 cc_presch
rename rl010_f cc_presch_f
rename rl020 cc_sch
rename rl020_f cc_sch_f
rename rl030 cc_xsch
rename rl030_f cc_xsch_f
rename rl040 cc_other
rename rl040_f cc_other_f
rename rl050 cc_pro
rename rl050_f cc_pro_f
rename rl060 cc_inf 
rename rl060_f cc_inf_f
rename rl070 ccweight
rename rl070_f ccweight_f 

* Label variables
label var year "Year"
label var country "Country"
label var pid "Person identifier" 
label var perwt_cs "Cross-sectional person weight"
label var perwt_cs_f "Cross-sectional person weight flag"
label var birthmo "Birth month"
label var birthmo_f "Birth month flag"
label var birthyr "Birth year"
label var birthyr_f "Birth year flag"
label var sex "Sex"
label var sex_f "Sex flag"
label var sith "Situation at home"
label var sith_f "Situation at home flag"
label var act_lastwk "Activity last week"
label var act_lastwk_f "Activity last week flag"
label var fid "Father's identifier"
label var fid_f "Father's identifier flag "
label var mid "Mother's identifier "
label var mid_f "Mother's identifier flag "
label var sid "Spouse/partner's identifier"
label var sid_f "Spouse/partner's identifier flag"
label var cc_presch "Childcare hours per week at preschool/kindergarten"
label var cc_presch_f ///
"Childcare hours per week at preschool/kindergarten flag"
label var cc_sch "Childcare hours per week at school (primary or secondary)"
label var cc_sch_f ///
"Childcare hours per week at school (primary or secondary) flag"
label var cc_xsch "Childcare hours per week outside school hours"
label var cc_xsch "Childcare hours per week outside school hours flag"
label var cc_other "Childcare hours per week in other childcare centers"
label var cc_other_f "Childcare hours per week in other childcare centers flag"
label var cc_pro "Childcare hours per week by paid professionals (babysitters)"
label var cc_pro_f ///
"Childcare hours per week by paid professionals (babysitters) flag"
label var cc_inf ///
"Childcare hours per week by unpaid adults (other than parents)"
label var cc_inf_f ///
"Childcare hours per week by unpaid adults (other than parents) flag"
label var ccweight "Cross-sectional childcare weight"
label var ccweight_f "Cross-sectional childcare weight flag"

* Label values
label define sex_lbl ///
1 "Male" ///
2 "Female" 
label values sex sex_lbl

label define sith_lbl ///
1 "Lives in the household" ///
2 "Temporarily out of the household"
label values sith sith_lbl

label define act_lastwk_lbl ///
1 "Working" ///
2 "Not working" ///
3 "Retired" ///
4 "Other" 
label values act_lastwk act_last_lbl

* Person data (fichero p) *
***************************

* Basic information *
* Check consistency of variables present in both r and p
* Birth month
count if birthmo!=pb130 & _mergerp==3
* Birth year
count if birthyr!=pb140 & _mergerp==3
* Sex
count if sex!=pb150 & _mergerp==3
* Father's identifier
count if fid!=pb160 & _mergerp==3
* Mother's identifier
count if mid!=pb170 & _mergerp==3
* Spouse's identifier
count if sid!=pb180 & _mergerp==3
* All correct!

* Remove duplicate variables
drop pb130-pb180_f

* Rename variables
rename (pb040 pb040_f pb100 pb100_f pb110 pb110_f pb120 pb120_f pb190 ///
pb190_f pb200 pb200_f pb210 pb210_f pb220a pb220a_f) ///
(pweight_16plus pweight_16plus_f intmonth intmonth_f intyear ///
intyear_f qmin qmin_f marst marst_f marstleg martsleg_f ///
cob cob_f nationality nationality_f) 

* Label variables
label var pweight_16plus "Cross-sectional person weight (16 and older)"
label var pweight_16plus_f ///
"Cross-sectional person weight (16 and older) flag"
label var intmonth "Interview month" 
label var intmonth_f "Interview month flag"
label var intyear "Interview year" 
label var intyear_f "Interview year flag"
label var qmin "Number of minutes questionnaire"
label var qmin_f "Number of minutes questionnaire flag"
label var marst "Marital status"
label var marst_f "Marital status flag"
label var marstleg "Legal status of union"
label var martsleg_f "Legal status of union flag"
label var cob "Country of birth"
label var cob_f "Country of birth flag" 
label var nationality "Nationality"
label var nationality_f "Nationaltiy flag"

* Label values
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

label define country_lbl ///
1 "Spain" ///
2 "Rest of EU" ///
3 "Non EU"

label values cob nationality country_lbl

* Education *
* Rename variables
rename (pe010 pe010_f pe020 pe020_f pe030 pe030_f pe040 pe040_f) (inschool ///
inschool_f inschool_level_raw inschool_level_raw_f yearedattain yearedattain_f ///
edattain_raw edattain_raw_f)

* Label variables
label var inschool "Currently in school"
label var inschool_f "Currently in school flag" 
label var inschool_level_raw "Level of current studies (raw)" 
label var inschool_level_raw_f "Level of current studies (raw) flag"
label var yearedattain "Year of attainment of highest education level" 
label var yearedattain_f "Year of attainment of highest education level flag"
label var edattain_raw "Educational attainment (raw)"
label var edattain_raw_f "Educational attainment (raw) flag"

* Label values
label define inschool_level_raw_lbl ///
0 "Less than primary" ///
1 "Primary" ///
2 "First cycle of secondary" ///
30 "Second cycle of secondary" ///
34 "Second cycle of secondary general orientation (people aged 16-34)" ///
35 "Second cycle of secondary professional orientation (people aged 16-34)" ///
40 "Non-college post-secondary" ///
45 "Non-college post-secondary professional orientation (people aged 16-34)" ///
50 "College"

label define edattain_raw_lbl ///
0 "Less than primary" ///
100 "Primary" ///
200 "First cycle of secondary" ///
300 "Second cycle of secondary" ///
344 "Second cycle of secondary general orientation (people aged 16-34)" ///
353 "Second cycle of secondary general orientation with no direct access to college (people aged 16-34)" ///
354 "Second cycle of secondary professional orientation with direct access to college (people aged 16-34)" ///
400 "Non-college post-secondary" ///
450 "Non-college post-secondary professional orientation (people aged 16-34)" ///
500 "College"

label values inschool_level_raw inschool_level_lbl
label values edattain_raw edattain_lbl

* Employment *

if "`base'"=="04" {

	* Rename
	rename pl030 activity_raw
	rename pl030_f activity_raw_f
	rename pl035 wrklastweek_sal
	rename pl035_f wrklastweek_sal_f
	rename pl035comp wrklastweek
	rename pl035comp_f wrklastweek_f
	rename pl015 everwrkd
	rename pl015_f everwrkd_f
	rename pl020 looking_4wk
	rename pl020_f looking_4wk_f
	rename pl025 available_2w
	rename pl025_f available_2w_f
	rename pl040 classwkr_raw
	rename pl040_f classwkr_raw_f
	rename pl050 occ_raw
	rename pl050_f occ_raw_f
	rename pl060 uhrswrk_raw
	rename pl060_f uhrswrk_raw_f
	rename pl070 months_ft
	rename pl070_f months_ft_f
	rename pl072 months_pt
	rename pl072_f months_pt_f
	rename pl080 months_ue
	rename pl080_f months_ue_f
	rename pl085 months_ret
	rename pl085_f months_ret_f
	rename pl087 months_study
	rename pl087_f months_study_f
	rename pl090 months_inactive
	rename pl090_f months_inactive_f
	rename pl100 uhrswrk2_raw
	rename pl100_f uhrswrk2_raw_f
	rename pl110a ind_raw
	rename pl110a_f ind_raw_f
	rename pl120 rless30h
	rename pl120_f rless30h_f
	rename pl130 firmsize_raw
	rename pl130_f firmsize_raw_f
	rename pl140 contype
	rename pl140_f contype_f
	rename pl150 mngr
	rename pl150_f mngr_f
	rename pl160 jobch
	rename pl160_f jobch_f
	rename pl170 jobchr
	rename pl170_f jobchr_f
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
	
	* Label	variables
	label var activity_raw "Self-declared employment status (raw)"
	label var activity_raw_f "Self-declared employment status (raw)-flag"
	label var wrklastweek_sal "Worked at least one hour last week for pay"
	label var wrklastweek_sal_f "Worked at least one hour last week for pay-flag"
	label var wrklastweek "Worked at least one hour last week"
	label var wrklastweek_f "Worked at least one hour last week-flag"
	label var everwrkd "Has ever worked"
	label var everwrkd_f "Has ever worked-flag"
	label var looking_4wk "Looked for work in the past 4 weeks"
	label var looking_4wk_f "Looked for work in the past 4 weeks-flag"
	label var available_2w "Is available to work within the next 2 weeks"
	label var available_2w_f "Is available to work within the next 2 weeks-flag"
	label var classwkr_raw "Class of worker (raw)"
	label var classwkr_raw_f "Class of worker (raw)-flag"
	label var occ_raw "Occupation (raw)"
	label var occ_raw_f "Occupation (raw)-flag"
	label var uhrswrk_raw "Usual hours worked per week (raw)"
	label var uhrswrk_raw_f "Usual hours worked per week (raw)-flag"
	label var months_ft "Months worked full time last year"
	label var months_ft_f "Months worked full time last year-flag"
	label var months_pt "Months worked part time last year"
	label var months_pt_f "Months worked part time last year-flag"
	label var months_ue "Months unemployed last year"
	label var months_ue_f "Months unemployed last year-flag"
	label var months_ret "Months retired last year"
	label var months_ret_f "Months retired last year-flag"
	label var months_study "Months studying last year"
	label var months_study_f "Months studying last year-flag"
	label var months_inactive "Months inactive last year"
	label var months_inactive_f "Months inactive last year-flag"
	label var uhrswrk2_raw "Usual hours worked per week in second, third, etc jobs (raw)"
	label var uhrswrk2_raw_f "Usual hours worked per week in second, third, etc jobs (raw)-flag"
	label var ind_raw "Industry of main job (raw)"
	label var ind_raw_f "Industry of main job (raw)-flag"
	label var rless30h "Reason for working less than 30 hours per week"
	label var rless30h_f "Reason for working less than 30 hours per week-flag"
	label var firmsize_raw "Number of employees in establishment (raw)"
	label var firmsize_raw_f "Number of employees in establishment (raw)-flag"
	label var contype "Type of contract"
	label var contype_f "Type of contract-flag"
	label var mngr "Manager role"
	label var mngr_f "Manager role-flag"
	label var jobch "Changed jobs in last 12 months"
	label var jobch_f "Changed jobs in last 12 months-flag"
	label var jobchr "Reason for job change in last 12 months"
	label var jobchr_f "Reason for job change in last 12 months-flag"
	label var actch "Most recent activity change"
	label var actch_f "Most recent activity change-flag"
	label var agewrk "Age started working regularly"
	label var agewrk_f "Age started working regularly-flag"
	label var experyrs "Years of work experience"
	label var experyrs "Years of work experience-flag"
	label var activity_m1 "Main activity January"
	label var activity_1_f "Main activity January-flag"
	label var activity_m2 "Main activity February"
	label var activity_2_f "Main activity February-flag"
	label var activity_m3 "Main activity March"
	label var activity_3_f "Main activity March-flag"
	label var activity_m4 "Main activity April"
	label var activity_4_f "Main activity April-flag"
	label var activity_m5 "Main activity May"
	label var activity_5_f "Main activity May-flag"
	label var activity_m6 "Main activity June"
	label var activity_6_f "Main activity June-flag"
	label var activity_m7 "Main activity July"
	label var activity_7_f "Main activity July-flag"
	label var activity_m8 "Main activity August"
	label var activity_8_f "Main activity August-flag"
	label var activity_m9 "Main activity September"
	label var activity_9_f "Main activity September-flag"
	label var activity_m10 "Main activity October"
	label var activity_10_f "Main activity October-flag"
	label var activity_m11 "Main activity November"
	label var activity_11_f "Main activity November-flag"
	label var activity_m12 "Main activity December"
	label var activity_12_f "Main activity December-flag"

	* Label values
	label define activity_raw_lbl ///
	1 "Full time worker" ///
	2 "Part time worker" ///
	3 "Unemployed" ///
	4 "Student" ///
	5 "Retired or closed business" ///
	6 "Permanently disabled for work" ///
	7 "Military service" ///
	8 "Homemaker" ///
	9 "Other type of inactivity"
	label values activity_raw activity_raw_lbl
	
	label define yesno ///
	1 "Yes" ///
	2 "No"
	 
	label define classwkr_raw_lbl ///
	1 "Employer" ///
	2 "Self-employed without employees" ///
	3 "Employee" ///
	4 "Family help" 
	
	label define contype_lbl ///
	1 "Open-ended" ///
	2 "Fixed-term" 
	
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
	
}
else {	

	* Rename
	rename (pl031 pl031_f pl015 pl015_f pl020 pl020_f pl025 pl025_f pl040 ///
	pl040_f pl051 pl051_f pl060 pl060_f pl073 pl073_f pl074 pl074_f pl075 ///
	pl075_f pl076 pl076_f pl080 pl080_f pl085 pl085_f pl086 pl086_f pl087 ///
	pl087_f pl089 pl089_f pl090 pl090_f pl100 pl100_f pl111a pl111a_f pl120 ///
	pl120_f pl130 pl130_f pl140 pl140_f pl150 pl150_f pl160 pl160_f pl170 ///
	pl170_f pl180 pl180_f pl190 pl190_f pl200 pl200_f pl211a pl211a_f pl211b ///
	pl211b_f pl211c pl211c_f pl211d pl211d_f pl211e pl211e_f pl211f pl211f_f ///
	pl211g pl211g_f pl211h pl211h_f pl211i pl211i_f pl211j pl211j_f pl211k ///
	pl211k_f pl211l pl211l_f) ///
	(empstatraw empstatraw_f everworked everworked_f worksearch4wp ///
	worksearch4wp_f workavail2w workavail2w_f empsit empsit_f occup occup_f ///
	wrkhrs_wk wrkhrs_wk_f months_ftsal months_ftsal_f months_ptsal ///
	months_ptsal_f months_ftse months_ftse_f months_ptse months_ptse_f ///
	months_ue months_ue_f months_ret months_ret_f months_dis months_dis_f ///
	months_study months_study_f months_hwrk months_hwrk_f months_other ///
	months_other_f wrkhrsother_wk wrkhrsother_wk_f ind ind_f rless30h rless30h_f ///
	nemp nemp_f conttype conttype_f superv superv_f jobch12m jobch12m_f jobchr ///
	jobchr_f empstatrawch empstatrawch_f agestartwrk agestartwrk_f yearswrk ///
	yearswrk_f empstatraw_jan empstatraw_jan_f empstatraw_feb empstatraw_feb_f ///
	empstatraw_mar empstatraw_mar_f empstatraw_apr empstatraw_apr_f ///
	empstatraw_may empstatraw_may_f empstatraw_jun empstatraw_jun_f ///
	empstatraw_jul empstatraw_jul_f empstatraw_aug empstatraw_aug_f ///
	empstatraw_sep empstatraw_sep_f empstatraw_oct empstatraw_oct_f ///
	empstatraw_nov empstatraw_nov_f empstatraw_dec empstatraw_dec_f)
	
	* Label variables
	label var empstatraw "Employment status (raw)" 
	label var empstatraw_f "Employment status (raw) flag" 
	label var everworked "Has ever worked" 
	label var everworked_f "Has ever worked flag"
	label var worksearch4wp "Has searched for work in previous 4 weeks"
	label var worksearch4wp_f "Has searched for work in previous 4 weeks flag"
	label var workavail2w "Is available to work in next 2 weeks"
	label var workavail2w_f "Is available to work in next 2 weeks"
	label var empsit "Employment situation"
	label var empsit_f "Employment situation flag"
	label var occup "Current or last occupation"
	label var occup_f "Current or last occupation flag"
	label var wrkhrs_wk "Hours worked per week (main job)"
	label var wrkhrs_wk_f "Hours worked per week (main job) flag" 
	label var months_ftsal "Number of months full-time salaried worker last year"
	label var months_ftsal_f ///
	"Number of months full-time salaried worker last year flag"
	label var months_ptsal "Number of months part-time salaried worker last year"
	label var months_ptsal_f ///
	"Number of months part-time salaried worker last year flag"
	label var months_ftse "Number of months full-time self employed last year"
	label var months_ftse_f ///
	"Number of months full-time self employed last year flag"
	label var months_ptse "Number of months part-time self employed last year"
	label var months_ptse_f ///
	"Number of months part-time self employed last year flag"
	label var months_ue "Number of months unemployed last year" 
	label var months_ue_f "Number of months unemployed last year flag"
	label var months_ret "Number of months retired last year"
	label var months_ret_f "Number of months retired last year flag"
	label var months_dis "Number of months disabled last year" 
	label var months_dis_f "Number of months disabled last year flag"
	label var months_study "Number of months student last year" 
	label var months_study_f "Number of months disabled last year flag"
	label var months_hwrk "Number of months housework, child care etc. last year"
	label var months_hwrk_f ///
	"Number of months housework, child care etc. last year flag"
	label var months_other "Number of months inactive for other reasons last year"
	label var months_other_f ///
	"Number of months inactive for other reasons last year flag"
	label var wrkhrsother_wk "Hours worked per week (other jobs)"
	label var wrkhrsother_wk_f "Hours worked per week (other jobs) flag" 
	label var ind "Industry of current or last job"
	label var ind_f "Industry of current or last job flag"
	label var rless30h "Reason for working less than 30 hours"
	label var rless30h_f "Reason for working less than 30 hours flag"
	label var nemp "Number of employees in work establishment"
	label var nemp_f "Number of employees in work establishment flag"
	label var conttype "Type of contract"
	label var conttype_f "Type of contract flag"
	label var superv "Supervising job"
	label var superv_f "Supervising job flag"
	label var jobch12m "Has changed job in last 12 months"
	label var jobch12m_f "Has changed job in last 12 months flag"
	label var jobchr "Reason for job change"
	label var jobchr_f "Reason for job change flag"
	label var empstatrawch "Most recent employment status change"
	label var empstatrawch_f "Most recent employment status change flag"
	label var agestartwrk "Age start regular work"
	label var agestartwrk_f "Age start regular work flag"
	label var yearswrk "Years of paid work"
	label var yearswrk_f "Years of paid work flag"
	label var empstatraw_jan "Employment status in January" 
	label var empstatraw_jan_f "Employment status in January flag"
	label var empstatraw_feb "Employment status in February"
	label var empstatraw_feb_f "Employment status in February flag"
	label var empstatraw_mar "Employment status in March"
	label var empstatraw_mar_f "Employment status in March flag"
	label var empstatraw_apr "Employment status in April"
	label var empstatraw_apr_f "Employment status in April flag"
	label var empstatraw_may "Employment status in May "
	label var empstatraw_may_f "Employment status in May flag"
	label var empstatraw_jun "Employment status in June"
	label var empstatraw_jun_f "Employment status in June flag"
	label var empstatraw_jul "Employment status in July"
	label var empstatraw_jul_f "Employment status in July flag"
	label var empstatraw_aug "Employment status in August"
	label var empstatraw_aug_f "Employment status in August flag"
	label var empstatraw_sep "Employment status in September"
	label var empstatraw_sep_f "Employment status in September flag"
	label var empstatraw_oct "Employment status in October"
	label var empstatraw_oct_f "Employment status in October flag"
	label var empstatraw_nov "Employment status in November"
	label var empstatraw_nov_f "Employment status in November flag"
	label var empstatraw_dec "Employment status in December"
	label var empstatraw_dec_f "Employment status in December flag"

	* Label values
	label define empstatraw_lbl ///
	1 "Full-time salaried worker" ///
	2 "Part-time salaried worker" ///
	3 "Full-time self employed" ///
	4 "Part-time self-employed" ///
	5 "Unemployed" ///
	6 "Student or in training" ///
	7 "Retired" ///
	8 "Permanently disabled" ///
	9 "Military service" ///
	10 "Homemaker" ///
	11 "Inactive for other reasons"

	label define yesno ///
	1 "Yes" ///
	2 "No"

	label define empsit_lbl ///
	1 "Employer" ///
	2 "Self-employed with no employees" ///
	3 "Salaried worker" ///
	4 "Family helper"

	replace ind="" if ind==" "
	encode ind, gen(ind_num)

	label define ind_lbl ///
	1 "Agriculture, livestock, forestry and fishing" ///
	2 "Extractive industries" ///
	3 "Manufacturing" ///
	4 "Power and gas" ///
	5 "Water supply and sanitation" ///
	6 "Construction" ///
	7 "Retail, motor vehicle repair" ///
	8 "Transportation and storage" ///
	9 "Hospitality" ///
	10 "Information and communications" ///
	11 "Finance and insurance" ///
	12 "Real state" ///
	13 "Professional, scientific and technical activities" ///
	14 "Administrative and auxiliary services" ///
	15 "Public administration, social security and defense" ///
	16 "Education" ///
	17 "Health and social services" ///
	18 "Arts and recreation" ///
	19 "Other services" ///
	20 "Domestic work" ///
	21 "Foreign organizations, unknown"

	label define rless30h_lbl ///
	1 "Studying or training" ///
	2 "Own sickness or disability" ///
	3 "Want more hours but can't get them" ///
	4 "Don't want to work more hours" ///
	5 "Sum of hours in all jobs is full time" ///
	6 "Doing housework, childcare or caring of other people" ///
	7 "Other reasons"

	label define conttype_lbl ///
	1 "Fixed-term contract" ///
	2 "Open-ended contract"

	label define jobchr_lbl ///
	1 "Better job" ///
	2 "End of fixed-term contract" ///
	3 "Forced by business reasons" ///
	4 "Sale or closing of own or family business" ///
	5 "Childcare or caring of other people" ///
	6 "Marriage-relocation of partner" ///
	7 "Other reasons"

	label define empstatrawch_lbl ///
	1 "Employment to unemployment" ///
	2 "Employment to retirement" ///
	3 "Employment to other type of inactivity" ///
	4 "Unemployment to employment" ///
	5 "Unemployment to retirement" ///
	6 "Unemployment to other type of inactivity" ///
	7 "Retirement to employment" ///
	8 "Retirement to unemployment" ///
	9 "Retirement to other type of inactivity" ///
	10 "Other type of inactivity to employment" ///
	11 "Other type of inactivity to unemployment" ///
	12 "Other type of inactivity to retirement" 

	label values empstatraw empstatraw_jan empstatraw_feb empstatraw_mar empstatraw_apr ///
	empstatraw_may empstatraw_jun empstatraw_jul empstatraw_aug empstatraw_sep empstatraw_oct empstatraw_nov ///
	empstatraw_dec empstatraw_lbl
	label values everworked worksearch4wp workavail2w superv jobch12m yesno
	label values empsit empsit_lbl
	label values ind_num ind_lbl
	label values rless30h rless30h_lbl
	label values conttype conttype_lbl
	label values jobchr jobchr_lbl
	label values empstatrawch empstatrawch_lbl
	
	* Health *

	* Income *

	label var py010n "Net Monetary income" 
	label var py010n_f "Net Monetary income flag"
	label var py020n "Net Not monetary income" 
	label var py020n_f "Net Not monetary income flag"
	label var py035n "Net Contribution to private pension" 
	label var py035n_f "Net Contribution to private pension flag"
	label var py080n "Net Income from private pensions" 
	label var py080n_f "Net Income from private pensions flag"
	label var py100n "Net Income from public pensions" 
	label var py100n_f "Net Income from public pensions flag"
	label var py110n "Net Income from survivor pensions" 
	label var py110n_f "Net Income from survivor pensions flag"

	rename (py010n py010n_f py020n py020n_f py035n py035n_f py080n py080n_f py100n ///
	py100n_f py110n py110n_f) ///
	(ninc_mon ninc_mon_f ninc_nmon ninc_nmon_f nc_pen nc_pen_f ///
	ninc_pri_pen ninc_pri_pen_f ninc_pub_pen ninc_pub_pen_f ninc_surv_pen ///
	ninc_surv_pen_f)

	 *Gross
	label var py010g "Gross Monetary income" 
	label var py010g_f "Gross Monetary income flag"
	label var py020g "Gross Not monetary income" 
	label var py020g_f "Gross Not monetary income flag"
	label var py035g "Gross Contribution to private pension" 
	label var py035g_f "Gross Contribution to private pension flag"
	label var py080g "Gross Income from private pensions" 
	label var py080g_f "Gross Income from private pensions flag"
	label var py100g "Gross Income from public pensions" 
	label var py100g_f "Gross Income from public pensions flag"
	label var py110g "Gross Income from survivor pensions" 
	label var py110g_f "Gross Income from survivor pensions flag"

	rename (py010g py010g_f py020g py020g_f py035g py035g_f py080g py080g_f ///
	py100g py100g_f py110g py110g_f ) ///
	(ginc_mon ginc_mon_f ginc_nmon ginc_nmon_f ///
	 gc_pen gc_pen_f ginc_pri_pen ginc_pri_pen_f ///
	 ginc_pub_pen ginc_pub_pen_f ginc_surv_pen ginc_surv_pen_f)

	label var py030g "Gross Contribution to SS by employer" 
	label var py030g_f "Gross Contribution to SS by employer flag"

	rename (py030g py030g_f) ///
	(gc_ss_emp gc_ss_emp_f)

	* Basic household data (fichero d) * 
	************************************

	* Basic information *
	* Rename variables
	rename (db030 db040 db040_f db060 db060_f db090 db090_f db100 ///
	db100_f) (hhid region_ca region_ca_f psu psu_f hhweight_cs ///
	hhweight_cs_f urb urb_f)

	* Label variables
	label var hhid "Household identifier" 
	label var region_ca "Region (comunidad autónoma)"
	label var region_ca_f "Region flag"
	label var psu "Primary sampling unit"
	label var psu_f "Primary sampling unit flag"
	label var hhweight_cs "Cross-sectional household weight"
	label var hhweight_cs_f "Cross-sectional household weight flag"
	label var urb "Urbanization"
	label var urb_f "Urbanization flag"

	* Label values
	replace region_ca = subinstr(region_ca,"ES","",.)
	destring region_ca, replace

	label define region_ca_lbl ///
	11 "Galicia" ///
	12 "Asturias" ///
	13 "Cantabria" ///
	21 "País Vasco" /// 
	22 "Navarra" ///
	23 "La Rioja" ///
	24 "Aragón" ///
	30 "Madrid" ///
	41 "Castilla y León" ///
	42 "Castilla-La Mancha" ///
	43 "Extremadura" ///
	51 "Cataluña" ///
	52 "Valencia" ///
	53 "Baleares" ///
	61 "Andalucía" ///
	62 "Murcia" ///
	63 "Ceuta" ///
	64 "Melilla" ///
	70 "Canarias" 

	label values region_ca region_ca_lbl

	label define urb_lbl ///
	1 "Very populated area" ///
	2 "Intermediate area" ///
	3 "Sparsely populated area"

	label values urb urb_lbl

	* Household data (fichero h) * 
	************************************

	* Income *
	* Total
	label var hy020 "Total disposable income last year" 
	label var hy020_f "Total disposable income last year flag" 

	tostring hy020_f, generate(hy)
	generate hy020_f1=substr(hy,1,1)
	destring hy020_f1, replace
	label define hy020_f1 0 "No data" ///
	1 "Net" ///
	2 "Gross" ///
	3 "Net and gross" ///
	4 "Unknown" 

	generate hy020_f2=substr(hy,2,1)
	destring hy020_f2, replace

	generate hy020_f3=substr(hy,-3,.)
	destring hy020_f3, replace

	label var hy022 "Disposable income before pensions last year" 
	label var hy022_f "Disposable income before pensions last year flag" 
	label var hy023 "Disposable income with pensions last year" 
	label var hy023_f "Disposable income with pensions last year flag" 

	rename (hy020 hy020_f hy022 hy022_f hy023 hy023_f ) ///
	(inc_disp_t inc_disp_t_f inc_disp_b inc_disp_b_f ///
	inc_disp inc_disp_f )

	* Net variables
	label var hy050n "Net Subsidy due to family or children last year" 
	label var hy050n_f "Net Subsidy due to family or children last year flag" 
	label var hy081n "Net Subsidy due to an alimony last year" 
	label var hy081n_f "Net Subsidy due to an alimony last year flag" 
	label var hy110n "Net Disposable income for children (less than 16)" 
	label var hy110n_f "Net Disposable income for children (less than 16) flag" 
	label var hy131n "Net Payment due to an alimony last year" 
	label var hy131n_f "Net Payment due to an alimony last year flag" 

	rename (hy050n hy050n_f hy081n hy081n_f hy110n hy110n_f hy131n hy131n_f) ///
	(nsub_c nsub_c_f nsub_ali nsub_ali_f ninc_disp_c ninc_disp_c_f ///
	npay_ali npay_ali_f )

	* Gross variables
	label var hy010 "Gross income last year" 
	label var hy010_f "Gross income last year flag"
	label var hy050g "Gross Subsidy due to family or children last year" 
	label var hy050g_f "Gross Subsidy due to family or children last year flag" 
	label var hy081g "Gross Subsidy due to an alimony last year" 
	label var hy081g_f "Gross Subsidy due to an alimony last year flag" 
	label var hy110g "Gross Disposable income for children (less than 16)" 
	label var hy110g_f "Gross Disposable income for children (less than 16) flag" 
	label var hy131g "Gross Payment due to an alimony last year" 
	label var hy131g_f "Gross Payment due to an alimony last year flag" 
	label var hy140g "Labor tax and contributions to the SS" 
	label var hy140g_f "Labor tax and contributions to the SS flag" 

	rename (hy010 hy010_f hy050g hy050g_f hy081g hy081g_f ///
	hy110g hy110g_f hy131g hy131g_f hy140g hy140g_f) ///
	(inc_gross inc_gross_f gsub_c gsub_c_f gsub_ali ///
	gsub_ali_f ginc_disp_c ginc_disp_c_f gpay_ali gpay_ali_f ///
	cont_ss cont_ss_f)

	* Social exclusion *

	* Housing *

	* Additional questions economic situation *

	* Complementary variables *
	label var hx040 "Number of members in the household" 
	label var hx060 "Household type" 
	label var hx240 "Consumption units, OECD scale" 

	rename (hx040 hx060 hx240) ///
	(num_hh type_hh ud_cons)

	label define type_hh ///
	1 "Unipersonal male <30" ///
	2 "Unipersonal male 30-64" ///
	3 "Unipersonal male >65" ///
	4 "Unipersonal female <30" ///
	5 "Unipersonal female 30-64" ///
	6 "Unipersonal female >65" ///
	7 "2 adults w/out dep. children & 1>65" ///
	8 "2 adults w/out dep. children & 2>65" ///
	9 "Other hh w/out dep. children" ///
	10 "1 adult + >= 1 dep.children" ///
	11 "2 adults w. 1 dep. children" ///
	12 "2 adults w. 2 dep.children" ///
	13 "2 adults w. +=3 dep.children" ///
	14 "Other hh w. dep. children" ///

	* Material deprivation *
	
}

* Save the dataset
cd "$output"
save ecv_`tofrom', replace
