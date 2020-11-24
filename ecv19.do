********************************************************************************
**********************Encuesta de Condiciones de Vida***************************
********************************************************************************

clear all
set more off

* Change the folder structure of this code at your own risk! 

global rootdir "C:\Users\franj\Documents\GitHub\ECV\working"
global rawdata "$rootdir\rawdata"
global output "$rootdir\output"
global intermediate "$rootdir\intermediate"
global programs "$rootdir\programs"

cd "$rootdir"

****************
*Merge datasets*
****************

* Merge the household basic data file (fichero d) and the household data file 
* (fichero h)
cd "$rawdata"
import delimited esudb19h, delimiter(",")

rename (hb010 hb020 hb030) (db010 db020 db030)
cd "$intermediate"
save ecvh.dta, replace

cd "$rawdata"
import delimited esudb19d, delimiter(",") clear

cd "$intermediate"
merge 1:1 db010 db020 db030 using ecvh.dta, generate(_mergedh)

save ecvdh.dta, replace
erase ecvh.dta

* Merge the person basic data file (fichero r) and the person data file (fichero 
* p)
cd "$rawdata"
import delimited esudb19p, delimiter(",") clear
rename (pb010 pb020 pb030) (rb010 rb020 rb030)

cd "$intermediate"
save ecvp.dta, replace

cd "$rawdata"
import delimited esudb19r, delimiter(",") clear

cd "$intermediate"
merge 1:1 rb010 rb020 rb030 using ecvp.dta, generate(_mergerp)

save ecvrp.dta, replace
erase ecvp.dta

* Note: there are 6476 observations that are only in the master data (fichero r)
* that correspond to people 16 years old and younger. 

* Retrieve the household's identifier from the person's identifier
tostring rb030, generate(id)
generate pid_hh=substr(id,-2,.)
destring pid_hh, replace
generate id_reverse=strreverse(id) 
generate db030_reverse=substr(id_reverse,3,.)
generate db030=strreverse(db030_reverse)
destring db030, replace
drop id id_reverse db030_reverse

* Merge with household data
rename (rb010 rb020) (db010 db020)

cd "$intermediate"
merge m:1 db010 db020 db030 using ecvdh.dta

save ecv.dta, replace
erase ecvdh.dta
erase ecvrp.dta

************
* Clean up *
************

* Individual basic variables
* Destring
destring rb070 rb210 rb220 rb230 rb240 rl010 rl020 rl030 rl040 rl050 rl060 ///
rl070, replace

* Rename
rename (db010 db020 rb030 rb050 rb050_f rb070 rb070_f rb080 rb080_f ///
rb090 rb090_f rb200 rb200_f rb210 rb210_f rb220 rb220_f rb230 rb230_f ///
rb240 rb240_f rl010 rl010_f rl020 rl020_f rl030 rl030_f rl040 rl040_f ///
rl050 rl050_f rl060 rl060_f rl070 rl070_f) (year country pid pweight_cs ///
pweight_cs_f bmonth bmonth_f byear byear_f sex sex_f sith sith_f ///
act_last act_last_f fid fid_f mid mid_f sid sid_f cc1 cc1_f cc2 cc2_f ///
cce cce_f cceo cceo_f ccb ccb_f ccin ccin_f cweight cweight_f)

*Label variables
label var year "Year"
label var country "Country"
label var pid "Person identifier" 
label var pweight_cs "Cross-sectional person weight"
label var pweight_cs_f "Cross-sectional person weight check"
label var bmonth "Birth month"
label var bmonth_f "Birth month check"
label var byear "Birth year"
label var byear_f "Birth year check"
label var sex "Sex"
label var sex_f "Sex check"
label var sith "Situation at home"
label var sith_f "Situation at home check"
label var act_last "Activity last week"
label var act_last_f "Activity last week check"
label var fid "Father's identifier"
label var fid_f "Father's identifier check "
label var mid "Mother's identifier "
label var mid_f "Mother's identifier check "
label var sid "Spouse/partner's identifier"
label var sid_f "Spouse/partner's identifier check"
label var cc1 "Hours per week of childcare in school (0-6)"
label var cc1_f "Hours per week of childcare in school (0-6) check"
label var cc2 "Hours per week of childcare in prim and sec school"
label var cc2_f "Hours per week of childcare in prim and sec school check"
label var cce "Hours per week of extra childcare"
label var cce_f "Hours per week of extra childcare check"
label var cceo "Hours per week of extra childcare other centers"
label var cceo_f "Hours per week of extra childcare other centers check"
label var ccb "Hours per week of babysitters childcare"
label var ccb_f "Hours per week of babysitters childcare check"
label var ccin "Hours per week of informal childcare"
label var ccin_f "Hours per week of informal childcare check"
label var cweight "Cross-sectional child weight"
label var cweight_f "Cross-sectional child weight check"

*Label values

label define sex_lbl ///
1 "Male" ///
2 "Female" 
label values sex sex_lbl

label define sith_lbl ///
1 "Lives in the household" ///
2 "Temporarily out of the household"
label values sith sith_lbl

label define act_last_lbl ///
1 "Working" ///
2 "Not working" ///
3 "Retired" ///
4 "Other" 
label values act_last act_last_lbl

* Household basic variables
rename (db030 db040 db040_f db060 db060_f db090 db090_f db100 ///
db100_f) (hhid region_ca region_ca_f psu psu_f hhweight_cs ///
hhweight_cs_f urb urb_f)

label var hhid "Household identifier" 
label var region_ca "Region (comunidad autónoma)"
label var region_ca_f "Region check"
label var psu "Primary sampling unit"
label var psu_f "Primary sampling unit check"
label var hhweight_cs "Cross-sectional household weight"
label var hhweight_cs_f "Cross-sectional household weight check"
label var urb "Urbanization"
label var urb_f "Urbanization check"

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

********************************
* Person variables (fichero p) *
********************************

* Basic information *
*********************

* Destring
destring pb*, replace
* Check consistency of variables present in both r and p

* Birth month
count if bmonth!=pb130 & _mergerp==3
* Birth year
count if byear!=pb140 & _mergerp==3
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

label var pweight_16plus "Cross-sectional person weight (16 and older)"
label var pweight_16plus_f ///
"Cross-sectional person weight (16 and older) check"
label var intmonth "Interview month" 
label var intmonth_f "Interview month check"
label var intyear "Interview year" 
label var intyear_f "Interview year check"
label var qmin "Number of minutes questionnaire"
label var qmin_f "Number of minutes questionnaire check"
label var marst "Marital status"
label var marst_f "Marital status check"
label var marstleg "Legal status of union"
label var martsleg_f "Legal status of union check"
label var cob "Country of birth"
label var cob_f "Country of birth check" 
label var nationality "Nationality"
label var nationality_f "Nationaltiy check"

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
*************

destring pe*, replace
rename (pe010 pe010_f pe020 pe020_f pe030 pe030_f pe040 pe040_f) (inschool ///
inschool_f inschool_level_raw inschool_level_raw_f yearedattain yearedattain_f ///
edattain_raw edattain_raw_f)

label var inschool "Currently in school"
label var inschool_f "Currently in school check" 
label var inschool_level_raw "Level of current studies (raw)" 
label var inschool_level_raw_f "Level of current studies (raw) check"
label var yearedattain "Year of attainment of highest education level" 
label var yearedattain_f "Year of attainment of highest education level check"
label var edattain_raw "Educational attainment (raw)"
label var edattain_raw_f "Educational attainment (raw) check"

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
**************
destring pl*, replace

rename (pl031 pl031_f pl015 pl015_f pl020 pl020_f pl025 pl025_f pl040 ///
pl040_f pl051 pl051_f pl060 pl060_f pl073 pl073_f pl074 pl074_f pl075 ///
pl075_f pl076 pl076_f pl080 pl080_f pl085 pl085_f pl086 pl086_f pl087 ///
pl087_f pl089 pl089_f pl090 pl090_f pl100 pl100_f pl111a pl111a_f pl120 ///
pl120_f pl130 pl130_f pl140 pl140_f pl150 pl150_f pl160 pl160_f pl170 ///
pl170_f pl180 pl180_f pl190 pl190_f pl200 pl200_f pl211a pl211a_f pl211b ///
pl211b_f pl211c pl211c_f pl211d pl211d_f pl211e pl211e_f pl211f pl211f_f ///
pl211g pl211g_f pl211h pl211h_f pl211i pl211i_f pl211j pl211j_f pl211k ///
pl211k_f pl211l pl211l_f) ///
(empstat_raw empstat_raw_f everworked everworked_f worksearch4wp ///
worksearch4wp_f workavail2w workavail2w_f empsit empsit_f occup occup_f ///
wrkhrs_wk wrkhrs_wk_f months_ftsal months_ftsal_f months_ptsal ///
months_ptsal_f months_ftse months_ftse_f months_ptse months_ptse_f ///
months_ue months_ue_f months_ret months_ret_f months_dis months_dis_f ///
months_study months_study_f months_hwrk months_hwrk_f months_other ///
months_other_f wrkhrsother_wk wrkhrsother_wk_f ind ind_f rless30h rless30h_f ///
nemp nemp_f conttype conttype_f superv superv_f jobch12m jobch12m_f jobchr ///
jobchr_f empstatch empstatch_f agestartwrk agestartwrk_f yearswrk yearswrk_f ///
empstatjan empstatjan_f empstatfeb empstatfeb_f empstatmar empstatmar_f ///
empstatapr empstatapr_f empstatmay empstatmay_f empstatjun empstatjun_f ///
empstatjul empstatjul_f empstataug empstataug_f empstatsep empstatsep_f ///
empstatoct empstatoct_f empstatnov empstatnov_f empstatdec empstatdec_f)

label var empstat_raw "Employment status (raw)" 
label var empstat_raw_f "Employment status (raw) check" 
label var everworked "Has ever worked" 
label var everworked_f "Has ever worked check"
label var worksearch4wp "Has searched for work in previous 4 weeks"
label var worksearch4wp_f "Has searched for work in previous 4 weeks check"
label var workavail2w "Is available to work in next 2 weeks"
label var workavail2w_f "Is available to work in next 2 weeks"
label var empsit "Employment situation"
label var empsit_f "Employment situation check"
label var occup "Current or last occupation"
label var occup_f "Current or last occupation check"
label var wrkhrs_wk "Hours worked per week (main job)"
label var wrkhrs_wk_f "Hours worked per week (main job) check" 
label var months_ftsal "Number of months full-time salaried worker last year"
label var months_ftsal_f "Number of months full-time salaried worker last year check"
label var months_ptsal "Number of months part-time salaried worker last year"
label var months_ptsal_f "Number of months part-time salaried worker last year check"
label var months_ftse "Number of months full-time self employed last year"
label var months_ftse_f "Number of months full-time self employed last year check"
label var months_ptse "Number of months part-time self employed last year"
label var months_ptse_f "Number of months part-time self employed last year check"
label var months_ue "Number of months unemployed last year" 
label var months_ue_f "Number of months unemployed last year check"
label var months_ret "Number of months retired last year"
label var months_ret_f "Number of months retired last year check"
label var months_dis "Number of months disabled last year" 
label var months_dis_f "Number of months disabled last year check"
label var months_study "Number of months student last year" 
label var months_study_f "Number of months disabled last year check"
label var months_hwrk "Number of months housework, child care etc. last year"
label var months_hwrk_f "Number of months housework, child care etc. last year check"
label var months_other "Number of months inactive for other reasons last year"
label var months_other_f "Number of months inactive for other reasons last year check"
label var wrkhrsother_wk "Hours worked per week (other jobs)"
label var wrkhrsother_wk_f "Hours worked per week (other jobs) check" 
label var ind "Industry of current or last job"
label var ind_f "Industry of current or last job check"
label var rless30h "Reason for working less than 30 hours"
label var rless30h_f "Reason for working less than 30 hours check"
label var nemp "Number of employees in work establishment"
label var nemp_f "Number of employees in work establishment check"
label var conttype "Type of contract"
label var conttype_f "Type of contract check"
label var superv "Supervising job"
label var superv_f "Supervising job check"
label var jobch12m "Has changed job in last 12 months"
label var jobch12m_f "Has changed job in last 12 months check"
label var jobchr "Reason for job change"
label var jobchr_f "Reason for job change check"
label var empstatch "Most recent employment status change"
label var empstatch_f "Most recent employment status change check"
label var agestartwrk "Age start regular work"
label var agestartwrk_f "Age start regular work check"
label var yearswrk "Years of paid work"
label var yearswrk_f "Years of paid work check"
label var empstatjan "Employment status in January" 
label var empstatjan_f "Employment status in January check"
label var empstatfeb "Employment status in February"
label var empstatfeb_f "Employment status in February check"
label var empstatmar "Employment status in March"
label var empstatmar_f "Employment status in March check"
label var empstatapr "Employment status in April"
label var empstatapr_f "Employment status in April check"
label var empstatmay "Employment status in May "
label var empstatmay_f "Employment status in May check"
label var empstatjun "Employment status in June"
label var empstatjun_f "Employment status in June check"
label var empstatjul "Employment status in July"
label var empstatjul_f "Employment status in July check"
label var empstataug "Employment status in August"
label var empstataug_f "Employment status in August check"
label var empstatsep "Employment status in September"
label var empstatsep_f "Employment status in September check"
label var empstatoct "Employment status in October"
label var empstatoct_f "Employment status in October check"
label var empstatnov "Employment status in November"
label var empstatnov_f "Employment status in November check"
label var empstatdec "Employment status in December"
label var empstatdec_f "Employment status in December check"

label define empstat_raw_lbl ///
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

label define empstatch_lbl ///
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

label values empstat_raw empstatjan empstatfeb empstatmar empstatapr ///
empstatmay empstatjun empstatjul empstataug empstatsep empstatoct empstatnov ///
empstatdec empstat_raw_lbl
label values everworked worksearch4wp workavail2w superv jobch12m yesno
label values empsit empsit_lbl
label values ind_num ind_lbl
label values rless30h rless30h_lbl
label values conttype conttype_lbl
label values jobchr jobchr_lbl
label values empstatch empstatch_lbl






