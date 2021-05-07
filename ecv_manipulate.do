clear all
set more off

* Write here the main folder, where the folders rawdata, output, intermediate 
* and programs are located:
 
*global rootdir  "C:\Users\lidic\OneDrive\Escritorio\Cruces&Rodríguez\Encuesta de Condiciones de Vida\ECV\working"
global rootdir "G:\My Drive\ECV\working"

global rawdata "$rootdir\rawdata"
global output "$rootdir\output"
global intermediate "$rootdir\intermediate"
global programs "$rootdir\ECV_programs"

cd "$rootdir"

*****************************************************
* Add spouse's data to each person/year observation *
*****************************************************

* Open the main dataset
cd "$output"
use "ecv.dta" ,clear

* Remove all person/year observations with no spouse data 
drop if missing(sid)

* Keep only variables we want
keep sid year empstatraw_jan empstatraw_feb empstatraw_mar empstatraw_apr ///
empstatraw_may empstatraw_jun empstatraw_jul empstatraw_aug empstatraw_sep ///
empstatraw_oct empstatraw_nov empstatraw_dec months_hwrk months_ptse ///
months_ftse wrkhrs_wk ninc_mon ginc_mon birthyr 

* Add suffix _spouse to all variables except year
rename _all  =_spouse
rename year_spouse year

* Rename spouse's spouse's id to person id
rename sid_spouse pid

duplicates drop year pid, force

* Save the spouse's dataset
cd "$intermediate"
save ecv_spouse, replace

* Go back to main dataset
cd "$output"
use ecv, clear

* Merge spouse's dataset into main dataset 
cd "$intermediate"
merge 1:1 year pid using ecv_spouse.dta, generate(_mergespouse)

save ecv_spouse, replace

*******************************************************
* Add children's data to each person/year observation *
*******************************************************

* Open the main dataset
cd "$output"
use "ecv.dta" ,clear

* Remove all person/year observations with no mother's data 
drop if missing(mid)

* Drop everyone older than 18? No
*drop if year-birthyr>18

* Create a variable (child) that tells us the birth order. 1= first child, 
* 2=second children, and another variable (children) with the number of children
* currently living with the mother
tostring(year mid), gen(year_str mid_str)

gen id_year = mid_str+year_str
destring(id_year), replace
drop mid_str year_str

sort id_year birthyr
by id_year, sort: gen child = _n
bysort id_year: gen children = _N

* One by one, create a file with the data for each child.
forvalues i=1(1)12{

preserve 
keep if child==`i'

keep year pid mid children cc_presch cc_sch cc_xsch cc_other cc_pro ///
cc_inf ccweight birthyr

* I generate the variable of child's age so that is years old at the beginning 
* of the year, because that's how eligibility for school is determined in Spain
gen child=1
gen age=year-birthyr-1
replace age=0 if age<0

rename _all =_`i'
rename year_`i' year
rename pid_`i' chid_`i'
rename mid_`i' pid 

cd "$intermediate"
save ecv_child_`i', replace

restore
}

use ecv_spouse, clear 

forvalues i=1(1)12{

merge 1:1 year pid using ecv_child_`i'.dta
drop _merge

erase ecv_child_`i'.dta

}

save ecv_spouse_children, replace
erase ecv_spouse.dta

***************************
* Obtaining key variables *
***************************

* Age * 
*******

* Generate age variable
gen age=year-birthyr
label var age "Age"

* Recode age variable to fit our 3-year periods
recode age ///
(0/29 = 0) ///
(30/32 = 1) ///
(33/35 = 2) ///
(36/38 = 3) ///
(39/41 = 4) ///
(42/44 = 5) ///
(45/47 = 6) ///
(48/50 = 7) ///
(51/53 = 8) ///
(54/56 = 9) ///
(57/59 = 10) ///
(60/63 = 11) ///
(63/66 = 12) ///
(nonmi = 13), generate(lifeper)

label var lifeper "Model equivalent life period"
label define lifeper_lbl ///
0 "29 and younger" ///
1 "30 to 33" ///
2 "33 to 36" ///
3 "36 to 39" ///
4 "39 to 42" ///
5 "42 to 45" ///
6 "45 to 48" ///
7 "48 to 51" ///
8 "51 to 54" ///
9 "54 to 57" ///
10 "57 to 60" ///
11 "60 to 63" ///
12 "63 to 66" ///
13 "67 and older"
label values lifeper lifeper_lbl

* Children and motherhood *
***************************

* Generate variable total number of children (I do this in two alternative ways
* that are equivalent)

forvalues i=1(1)12{

	replace child_`i'=0 if missing(child_`i')

}

egen nchild=rowmax(children_*)
replace nchild=0 if missing(nchild) & sex==2
egen nchild_alt=rowtotal(child_*)
label var nchild "Number of own children living in the house"

gen mom=(nchild>0) if sex==2
label var mom "Is a mom"

label define mom_lbl ///
0 "Childless" ///
1 "Mother"

label values mom mom_lbl

* Generate a variable with total number of births (as oposed to children, in 
* order to account for multiple births) 
gen births=nchild

* Substract 1 from births for every time an age is repeated among children
forvalues i=1(1)11{

	local j=`i'+1
	replace births=births-1 if age_`i'==age_`j' & !missing(age_`i')
	
}

label var births "Total number of births"

* Generate age of youngest and eldest child
egen age_yng=rowmin(age_*)
egen age_eld=rowmax(age_*)

label var age_yng "Age of youngest child"
label var age_eld "Age of eldest child"

recode age_yng ///
(0/2 = 1 "0 to 3") ///
(3/5 = 2 "3 to 6") ///
(6/8 = 3 "6 to 9") ///
(9/11 = 4 "9 to 12") ///
(12/14 = 5 "12 to 15") ///
(15/17 = 6 "15 to 18") ///
(nonm = .), ///
generate(lifeper_yng) label(lifper_yng_lbl)

label var lifeper_yng ///
"Model equivalent life period of youngest child  (up to 18 years old)"

* Generate age of first birth
gen age_fbirth=age-age_eld

label var age_fbirth "Age at first birth" 

* Generate labor force participation variable *
***********************************************

* First we recode the monthly employment status variables into labor force 
* participation variables ft, pt, ue and olf, which contain the the number of 
* months that the person spent working full time, part time, unemployed and out 
* of the labor force. We compare these variables to the results obtained from 
* variables months_ftsal months_ptsal months_ftse months_ptse months_ue 
* months_ret months_dis months_study months_hwrk and months_other

* Full time employment
recode empstatraw_* (1 3 = 1) (nonmi = 0), pre(ft_)
rename ft_empstatraw_* ft_*
drop ft_f ft_jan_f ft_feb_f ft_mar_f ft_apr_f ft_may_f ft_jun_f ft_jul_f ///
ft_aug_f ft_sep_f ft_oct_f ft_nov_f ft_dec_f ft_jan_spouse-ft_dec_spouse
egen ft=rowtotal(ft_*)
label var ft "Months spent working full time last year"

gen months_ft=months_ftsal+months_ftse
label var months_ft "Months spent working full time last year"

count if months_ft!=ft & !missing(months_ft) & !missing(ft) 

drop ft_jan-ft_dec

* Part time employment
recode empstatraw_* (2 4 = 1) (nonmi = 0), pre(pt_)
rename pt_empstatraw_* pt_*
drop pt_f pt_jan_f pt_feb_f pt_mar_f pt_apr_f pt_may_f pt_jun_f pt_jul_f ///
pt_aug_f pt_sep_f pt_oct_f pt_nov_f pt_dec_f pt_jan_spouse-pt_dec_spouse
egen pt=rowtotal(pt_*)
label var pt "Months spent working part time last year"

gen months_pt=months_ptsal+months_ptse
label var months_pt "Months spent working part time last year"

count if months_pt!=pt & !missing(months_pt) & !missing(pt)

drop pt_jan-pt_dec 

* Unemployment
recode empstatraw_* (5 = 1) (nonmi = 0), pre(ue_)
rename ue_empstatraw_* ue_*
drop ue_f ue_jan_f ue_feb_f ue_mar_f ue_apr_f ue_may_f ue_jun_f ue_jul_f ///
ue_aug_f ue_sep_f ue_oct_f ue_nov_f ue_dec_f ue_jan_spouse-ue_dec_spouse
egen ue=rowtotal(ue_*)
label var ue "Months spent in unemployment last year"

count if months_ue!=ue & !missing(months_ue) & !missing(ue) 

drop ue_jan-ue_dec

* Out of labor force
recode empstatraw_* (6/11 = 1) (nonmi = 0), pre(olf_)
rename olf_empstatraw_* olf_*
drop olf_f olf_jan_f olf_feb_f olf_mar_f olf_apr_f olf_may_f olf_jun_f ///
olf_jul_f olf_aug_f olf_sep_f olf_oct_f olf_nov_f olf_dec_f ///
olf_jan_spouse-olf_dec_spouse
egen olf=rowtotal(olf_*)
label var olf "Months spent working part time last year"

gen months_olf=months_ret+months_dis+months_study+months_hwrk+months_other
label var months_olf "Months spent working part time last year"

count if months_olf!=olf & !missing(months_olf) & !missing(olf)

drop olf_jan-olf_dec 

* No differences were found between the manually calculated variables and the 
* ones already present in the dataset.

* We first creat a current lfp variable
recode empstatraw (1 3 = 3) (2 4 = 2) (5 = 1) (6/11=0), gen(lfp_current)
label var lfp_current "Current labor force status"

label define lfp_lbl ///
3 "Full time work" ///
2 "Part time work" ///
1 "Unemployed" ///
0 "Out of the labor force" 

label values lfp_current lfp_lbl

* Now we create LFP variables for the year. 

* First we count total months in labor force
gen inlf_months=ft+pt+ue
* We then compute the number of months the person actually worked
gen work_months=ft+pt
* Compute total hours worked during the months in labor force, where a full time 
* month is 1, part-time month 0.5 and unemployment is zero
gen hours_inlf=ft+0.5*pt
* Compute average hours worked when in lf
gen avg_hours_inlf=hours_inlf/inlf_months

* Generate lfp for the year
* First we assign to in labor force those who had worked for more than 6 months
* during the year, or whose average hours multiplied by their months in the 
*labor force are enough to bump them to part-time
gen inlf_yr=1 if inlf_months>5 | ///
(!missing(avg_hours_inlf) & avg_hours_inlf*work_months>3)
replace inlf_yr=0 if missing(inlf_yr)

* Then we create the lfp variable for the year
* We first create a variable that recodes the average hours for people 
* considered to be in the labor force, to 0 when unemployed (person reported
* being in the labor force but didn't work enough hours to reach par time), 1
* for part time and 2 for full time
egen lfp_yr=cut(avg_hours_inlf), at(0,0.25,0.75,1.25) icodes
* Add 1 to match lfp_current
replace lfp_yr=lfp_yr+1
* Add people olf with a zero
replace lfp_yr=0 if missing(lfp_yr)

label var lfp_yr "Yearly labor force status"
label values lfp_yr lfp_lbl

* Generate childcare variables *
********************************

gen cc_presch_yng=0 if mom==1 & age_yng<=12
gen cc_sch_yng=0 if mom==1 & age_yng<=12  
gen cc_xsch_yng=0 if mom==1 & age_yng<=12
gen cc_other_yng=0 if mom==1 & age_yng<=12
gen cc_pro_yng=0 if mom==1 & age_yng<=12 
gen cc_inf_yng=0 if mom==1 & age_yng<=12

forvalues i=1(1)12{

	replace cc_presch_yng=cc_presch_`i' if age_`i'==age_yng & ///
	!missing(cc_presch_`i')
	replace cc_sch_yng=cc_sch_`i' if age_`i'==age_yng & !missing(cc_sch_`i')
	replace cc_xsch_yng=cc_xsch_`i' if age_`i'==age_yng & !missing(cc_xsch_`i')
	replace cc_other_yng=cc_other_`i' if age_`i'==age_yng ///
	& !missing(cc_other_`i')
	replace cc_pro_yng=cc_pro_`i' if age_`i'==age_yng & !missing(cc_pro_`i') 
	replace cc_inf_yng=cc_inf_`i' if age_`i'==age_yng & !missing(cc_inf_`i')
}

gen cc_paid_yng=cc_presch_yng+cc_xsch_yng+cc_other_yng+cc_pro_yng if age_yng<=2
replace cc_paid_yng=cc_xsch_yng+cc_other_yng+cc_pro_yng if age_yng>2 & age_yng
gen cc_unpaid_yng=cc_sch_yng+cc_inf_yng if age_yng<=2
replace cc_unpaid_yng=cc_presch_yng+cc_sch_yng+cc_inf_yng if age_yng>2

label var cc_paid_yng "Weekly hours of paid childcare for youngest child"
label var cc_unpaid_yng "Weekly hours of unpaid childcare for youngest child" 

*gen cc_mom=(24-8)*5-cc_paid-cc_unpaid
*gen wrk_hrs=(lfp==0)*0+(lfp==1)*20+(lfp==2)*40
*gen le_hrs_mom=(24-8)*5-cc_mom-wrk_hrs if mom==1 & age_yng<=12

* Income quintile *
*******************

* This computes a women's household income quintintile among women of the same 
* model cohort in the same year

local years "2011 2012 2013 2014 2015 2016 2017 2018 2019"

gen hhinc_5tile=1 if sex==2 & lifeper>=1 & lifeper<=12

forvalues p=1(1)12 {

	foreach t of local years {
	
		_pctile(inc_disp_t) if sex==2 & year==`t' & lifeper==`p' ///
		[iweight=perwt_cs], nquantiles(5)

		forvalues i=1(1)4{

			replace hhinc_5tile=hhinc_5tile+1 if year==`t' & lifeper==`p' & ///
			inc_disp_t>(r(r`i'))
	
		}
	}
}

label var hhinc_5tile "Year/cohort household income quintile"

save ecv_temp.dta, replace

* Keep only women and variables we need *
*****************************************

keep if sex==2 & age>=27 & births<=3 & nchild<=3

keep year age lifeper marst mom nchild age_yng lifeper_yng age_eld ///
age_fbirth lfp_current lfp_yr ue pt ft cc_presch_yng cc_sch_yng cc_xsch_yng ///
cc_other_yng cc_pro_yng cc_inf_yng cc_paid_yng cc_unpaid_yng hhinc_5tile ///
perwt_cs pweight_16plus

cd "$output"
save ecv_women.dta, replace

* Graphs and tables *
*********************

* Childcare use *
*****************

* By age and average lfp through the year
preserve

collapse cc_presch_yng cc_sch_yng cc_xsch_yng cc_other_yng cc_pro_yng ///
cc_inf_yng cc_paid_yng cc_unpaid_yng if age_yng<=12 [iweight=perwt_cs], ///
by(year lfp_yr age_yng)

collapse cc_presch_yng cc_sch_yng cc_xsch_yng cc_other_yng cc_pro_yng ///
cc_inf_yng cc_paid_yng cc_unpaid_yng, by(lfp_yr age_yng)

twoway ///
(line cc_presch_yng age_yng if lfp==0 & age_yng<=5) ///
(line cc_presch_yng age_yng if lfp==1 & age_yng<=5) ///
(line cc_presch_yng age_yng if lfp==2 & age_yng<=5), ///
xline(3, lcolor(red)) ///
scheme(sj) graphr(c(white)) ///
xtitle("Age of youngest child") ytitle("Hours per week") ///
legend(order(1 2 3) label(1 "Out of labor force") label(2 "Part-time work") ///
label(3 "Full-time work") cols(1) region(c(white))) ///
name(presch_lfp)

twoway ///
(line cc_inf_yng age_yng if lfp==0 & age_yng<=5) ///
(line cc_inf_yng age_yng if lfp==1 & age_yng<=5) ///
(line cc_inf_yng age_yng if lfp==2 & age_yng<=5), ///
xline(3, lcolor(red)) ///
scheme(sj) graphr(c(white)) ///
xtitle("Age of youngest child") ytitle("Hours per week") ///
legend(order(1 2 3) label(1 "Out of labor force") label(2 "Part-time work") ///
label(3 "Full-time work") cols(1) region(c(white))) ///
name(inf_lfp)

twoway ///
(line cc_paid_yng age_yng if lfp==0 & age_yng<=5) ///
(line cc_paid_yng age_yng if lfp==1 & age_yng<=5) ///
(line cc_paid_yng age_yng if lfp==2 & age_yng<=5), ///
xline(3, lcolor(red)) ///
scheme(sj) graphr(c(white)) ///
xtitle("Age of youngest child") ytitle("Hours per week") ///
legend(order(1 2 3) label(1 "Out of labor force") label(2 "Part-time work") ///
label(3 "Full-time work") cols(1) region(c(white))) ///
name(ccpaid_lfp)

restore 

* By age and current lfp 
preserve

collapse cc_presch_yng cc_sch_yng cc_xsch_yng cc_other_yng cc_pro_yng ///
cc_inf_yng cc_paid_yng cc_unpaid_yng if age_yng<=12 [iweight=perwt_cs], ///
by(year lfp_current age_yng)

collapse cc_presch_yng cc_sch_yng cc_xsch_yng cc_other_yng cc_pro_yng ///
cc_inf_yng cc_paid_yng cc_unpaid_yng, by(lfp_current age_yng)

twoway ///
(line cc_presch_yng age_yng if lfp==0 & age_yng<=5) ///
(line cc_presch_yng age_yng if lfp==1 & age_yng<=5) ///
(line cc_presch_yng age_yng if lfp==2 & age_yng<=5), ///
xline(3, lcolor(red)) ///
scheme(sj) graphr(c(white)) ///
xtitle("Age of youngest child") ytitle("Hours per week") ///
legend(order(1 2 3) label(1 "Out of labor force") label(2 "Part-time work") ///
label(3 "Full-time work") cols(1) region(c(white))) ///
name(presch_lfp_current)

twoway ///
(line cc_inf_yng age_yng if lfp==0 & age_yng<=5) ///
(line cc_inf_yng age_yng if lfp==1 & age_yng<=5) ///
(line cc_inf_yng age_yng if lfp==2 & age_yng<=5), ///
xline(3, lcolor(red)) ///
scheme(sj) graphr(c(white)) ///
xtitle("Age of youngest child") ytitle("Hours per week") ///
legend(order(1 2 3) label(1 "Out of labor force") label(2 "Part-time work") ///
label(3 "Full-time work") cols(1) region(c(white))) ///
name(inf_lfp_current)

twoway ///
(line cc_paid_yng age_yng if lfp==0 & age_yng<=5) ///
(line cc_paid_yng age_yng if lfp==1 & age_yng<=5) ///
(line cc_paid_yng age_yng if lfp==2 & age_yng<=5), ///
xline(3, lcolor(red)) ///
scheme(sj) graphr(c(white)) ///
xtitle("Age of youngest child") ytitle("Hours per week") ///
legend(order(1 2 3) label(1 "Out of labor force") label(2 "Part-time work") ///
label(3 "Full-time work") cols(1) region(c(white))) ///
name(ccpaid_lfp_current)

restore 

* By model life period and lfp through the year
preserve

collapse cc_presch_yng cc_sch_yng cc_xsch_yng cc_other_yng cc_pro_yng ///
cc_inf_yng cc_paid_yng cc_unpaid_yng if age_yng<=12 [iweight=perwt_cs], ///
by(year lfp_yr lifeper_yng)

collapse cc_presch_yng cc_sch_yng cc_xsch_yng cc_other_yng cc_pro_yng ///
cc_inf_yng cc_paid_yng cc_unpaid_yng, by(lfp_yr lifeper_yng)

graph bar cc_presch_yng if lfp_yr!=1 & lifeper_yng<=2, ///
over(lfp_yr, relabel(1 "Inactive" 2 "Part time" 3 "Full time" )) ///
over(lifeper_yng, relabel(1 "0 to 3 years old" 2 "3 to 6 years old")) ///
scheme(sj) graphr(c(white)) ytitle("Hours per week") ///
name(presch_lfp_lifeper_yng)

graph bar cc_inf_yng if lfp_yr!=1 & lifeper_yng<=2, ///
over(lfp_yr, relabel(1 "Inactive" 2 "Part time" 3 "Full time" )) ///
over(lifeper_yng, relabel(1 "0 to 3 years old" 2 "3 to 6 years old")) ///
scheme(sj) graphr(c(white)) ytitle("Hours per week") ///
name(inf_lfp_lifeper_yng)

graph bar cc_paid_yng if lfp_yr!=1 & lifeper_yng<=2, ///
over(lfp_yr, relabel(1 "Inactive" 2 "Part time" 3 "Full time" )) ///
over(lifeper_yng, relabel(1 "0 to 3 years old" 2 "3 to 6 years old")) ///
scheme(sj) graphr(c(white)) ytitle("Hours per week") ///
name(paid_lfp_lifeper_yng)

restore

* By model life period and current lfp
preserve

collapse cc_presch_yng cc_sch_yng cc_xsch_yng cc_other_yng cc_pro_yng ///
cc_inf_yng cc_paid_yng cc_unpaid_yng if age_yng<=12 [iweight=perwt_cs], ///
by(year lfp_current lifeper_yng)

collapse cc_presch_yng cc_sch_yng cc_xsch_yng cc_other_yng cc_pro_yng ///
cc_inf_yng cc_paid_yng cc_unpaid_yng, by(lfp_current lifeper_yng)

graph bar cc_presch_yng if lfp_current<=2 & lifeper_yng<=2, ///
over(lfp_current, relabel(1 "Inactive" 2 "Part time" 3 "Full time" )) ///
over(lifeper_yng, relabel(1 "0 to 3 years old" 2 "3 to 6 years old")) ///
scheme(sj) graphr(c(white)) ytitle("Hours per week") ///
name(presch_lfp_current_lifeper_yng)

graph bar cc_inf_yng if lfp_current<=2 & lifeper_yng<=2, ///
over(lfp_current, relabel(1 "Inactive" 2 "Part time" 3 "Full time" )) ///
over(lifeper_yng, relabel(1 "0 to 3 years old" 2 "3 to 6 years old")) ///
scheme(sj) graphr(c(white)) ytitle("Hours per week") ///
name(inf_lfp_current_lifeper_yng)

graph bar cc_paid_yng if lfp_current<=2 & lifeper_yng<=2, ///
over(lfp_current, relabel(1 "Inactive" 2 "Part time" 3 "Full time" )) ///
over(lifeper_yng, relabel(1 "0 to 3 years old" 2 "3 to 6 years old")) ///
scheme(sj) graphr(c(white)) ytitle("Hours per week") ///
name(paid_lfp_current_lifeper_yng)

restore

* Restrict to those that use positive amounts of pre-school
preserve

collapse cc_presch_yng cc_sch_yng cc_xsch_yng cc_other_yng cc_pro_yng ///
cc_inf_yng cc_paid_yng cc_unpaid_yng if age_yng<=12 & cc_presch_yng>0 ///
[iweight=perwt_cs], by(year lfp_current lifeper_yng)

collapse cc_presch_yng cc_sch_yng cc_xsch_yng cc_other_yng cc_pro_yng ///
cc_inf_yng cc_paid_yng cc_unpaid_yng, by(lfp_current lifeper_yng)

graph bar cc_presch_yng if lfp_current<=2 & lifeper_yng<=2, ///
over(lfp_current, relabel(1 "Inactive" 2 "Part time" 3 "Full time" )) ///
over(lifeper_yng, relabel(1 "0 to 3 years old" 2 "3 to 6 years old")) ///
scheme(sj) graphr(c(white)) ytitle("Hours per week") 

///
name(presch_lfp_current_lifeper_yng)

graph bar cc_inf_yng if lfp_current<=2 & lifeper_yng<=2, ///
over(lfp_current, relabel(1 "Inactive" 2 "Part time" 3 "Full time" )) ///
over(lifeper_yng, relabel(1 "0 to 3 years old" 2 "3 to 6 years old")) ///
scheme(sj) graphr(c(white)) ytitle("Hours per week") 

///
name(inf_lfp_current_lifeper_yng)

graph bar cc_paid_yng if lfp_current<=2 & lifeper_yng<=2, ///
over(lfp_current, relabel(1 "Inactive" 2 "Part time" 3 "Full time" )) ///
over(lifeper_yng, relabel(1 "0 to 3 years old" 2 "3 to 6 years old")) ///
scheme(sj) graphr(c(white)) ytitle("Hours per week") ///
name(paid_lfp_current_lifeper_yng)

restore

* Restrict to those that use positive amounts of informal childcare
preserve

collapse cc_presch_yng cc_sch_yng cc_xsch_yng cc_other_yng cc_pro_yng ///
cc_inf_yng cc_paid_yng cc_unpaid_yng if age_yng<=12 & cc_inf_yng>0 ///
[iweight=perwt_cs], by(year lfp_current lifeper_yng)

collapse cc_presch_yng cc_sch_yng cc_xsch_yng cc_other_yng cc_pro_yng ///
cc_inf_yng cc_paid_yng cc_unpaid_yng, by(lfp_current lifeper_yng)

graph bar cc_presch_yng if lfp_current<=2 & lifeper_yng<=2, ///
over(lfp_current, relabel(1 "Inactive" 2 "Part time" 3 "Full time" )) ///
over(lifeper_yng, relabel(1 "0 to 3 years old" 2 "3 to 6 years old")) ///
scheme(sj) graphr(c(white)) ytitle("Hours per week") 

///
name(presch_lfp_current_lifeper_yng)

graph bar cc_inf_yng if lfp_current<=2 & lifeper_yng<=2, ///
over(lfp_current, relabel(1 "Inactive" 2 "Part time" 3 "Full time" )) ///
over(lifeper_yng, relabel(1 "0 to 3 years old" 2 "3 to 6 years old")) ///
scheme(sj) graphr(c(white)) ytitle("Hours per week") 

///
name(inf_lfp_current_lifeper_yng)

graph bar cc_paid_yng if lfp_current<=2 & lifeper_yng<=2, ///
over(lfp_current, relabel(1 "Inactive" 2 "Part time" 3 "Full time" )) ///
over(lifeper_yng, relabel(1 "0 to 3 years old" 2 "3 to 6 years old")) ///
scheme(sj) graphr(c(white)) ytitle("Hours per week") ///
name(paid_lfp_current_lifeper_yng)

restore


* I want to check whether few households have access to informal childcare
* INSTALL ssc install asgen
preserve
generate access_cc_inf = 0  
replace access_cc_inf = 1 if cc_inf_yng >0
replace access_cc_inf = 0 if cc_inf_yng == .
* Access : IS THE WEIGHT THE CORRECT ONE?
bysort year : asgen avg_access_cc_inf=access_cc_inf, w(perwt_cs)
sum avg_access_cc_inf ,by year

*Use if they have access
keep if access_cc_inf == 1

collapse cc_inf_yng if age_yng<=12 [iweight=perwt_cs], ///
by(year lfp age_yng)

collapse cc_inf_yng, by(lfp age_yng)

twoway ///
(line cc_inf_yng age_yng if lfp==0 & age_yng<=5) ///
(line cc_inf_yng age_yng if lfp==1 & age_yng<=5) ///
(line cc_inf_yng age_yng if lfp==2 & age_yng<=5), ///
xline(3, lcolor(red)) ///
scheme(sj) graphr(c(white)) ///
xtitle("Age of youngest child") ytitle("Hours per week") ///
legend(order(1 2 3) label(1 "Out of labor force") label(2 "Part-time work") ///
label(3 "Full-time work") cols(1) region(c(white))) ///
name(inf_lfp_yes)

restore








preserve

collapse cc_paid_yng cc_unpaid_yng if lifeper_yng<=4 [iweight=perwt_cs], ///
by(year lfp lifeper_yng)

collapse cc_paid_yng cc_unpaid_yng, by(lfp lifeper_yng)

twoway ///
(line cc_paid lifeper_yng if lfp==0) ///
(line cc_paid lifeper_yng if lfp==1) ///
(line cc_paid lifeper_yng if lfp==2), ///
scheme(sj) graphr(c(white)) ///
xtitle("Age of youngest child") ytitle("Hours per week") ///
legend(order(1 2 3) label(1 "Out of labor force") label(2 "Part-time work") ///
label(3 "Full-time work") cols(1) region(c(white))) ///
xlabel(1 2 3 4, valuelabel) ///
name(cc_paid)

twoway ///
(line cc_unpaid lifeper_yng if lfp==0) ///
(line cc_unpaid lifeper_yng if lfp==1) ///
(line cc_unpaid lifeper_yng if lfp==2), ///
scheme(sj) graphr(c(white)) ///
xtitle("Age of youngest child") ytitle("Hours per week") ///
legend(order(1 2 3) label(1 "Out of labor force") label(2 "Part-time work") ///
label(3 "Full-time work") cols(1) region(c(white))) ///
xlabel(1 2 3 4, valuelabel) ///
name(cc_unpaid)

restore
*I THINK WE NEED A PRESERVE  HERE

preserve

* Labor force participation *

* By model life period
drop if lfp_yr==1
tab lfp_yr, generate(lfp_yr)

*rename lfp1 olf
*rename lfp2 pt
*rename lfp3 ft


collapse lfp_yr1-lfp_yr3 if lifeper<13 [iweight=perwt_cs], by(year lifeper mom)

collapse lfp_yr1-lfp_yr3, by(lifeper mom)

replace lfp_yr1=lfp_yr1*100
replace lfp_yr2=lfp_yr2*100
replace lfp_yr3=lfp_yr3*100

* Childless women
twoway ///
(line lfp_yr2 lifeper if mom==0) ///
(line lfp_yr3 lifeper if mom==0), ///
scheme(sj) graphr(c(white)) ///
xtitle("Age") ytitle("% of women") ///
legend(order(1 2) label(1 "Part-time") ///
label(2 "Full-time") rows(1) region(c(white))) ///
xlabel(1 "30 to 33" 3 "36 to 39" 5 "42 to 45" 7 "48 to 51" 9 "54 to 57" ///
11 "60 to 63") ///
name(lfp_childless)

* Moms
twoway ///
(line lfp_yr2 lifeper if mom==1) ///
(line lfp_yr3 lifeper if mom==1), ///
scheme(sj) graphr(c(white)) ///
xtitle("Age") ytitle("% of women") ///
legend(order(1 2) label(1 "Part-time") ///
label(2 "Full-time") rows(1) region(c(white))) ///
xlabel(1 "30 to 33" 3 "36 to 39" 5 "42 to 45" 7 "48 to 51" 9 "54 to 57" ///
11 "60 to 63") ///
name(lfp_mom)

* Gap

reshape wide lfp*, i(lifeper) j(mom)

gen ptgap=(lfp_yr21-lfp_yr20)
gen ftgap=(lfp_yr31-lfp_yr30)
gen gap=ptgap+ftgap

twoway ///
(line ptgap lifeper) ///
(line ftgap lifeper) ///
(line gap lifeper), ///
scheme(sj) graphr(c(white)) ///
xtitle("Age") ytitle("Percentage points") ///
legend(order(1 2 3) label(1 "Part-time gap") label(2 "Full-time gap") ///
label(3 "Participation gap") rows(1) region(c(white))) ///
xlabel(1 4 7 10, valuelabel) ///
name(lfp_gap)

restore

preserve
* By age

tab lfp, generate(lfp)

collapse lfp1-lfp3 if age>=30 & age<=65 [iweight=perwt_cs], by(year age mom)

collapse lfp1-lfp3, by(age mom)

* Childless women
twoway ///
(line lfp1 age if mom==0) ///
(line lfp2 age if mom==0) ///
(line lfp3 age if mom==0), ///
scheme(sj) graphr(c(white)) ///
xtitle("Age") ytitle("Fraction of women") ///
legend(order(1 2 3) label(1 "Out of labor force") label(2 "Part-time work") ///
label(3 "Full-time work") cols(1) region(c(white))) ///
name(lfp_age_childless)

* Moms
twoway ///
(line lfp1 age if mom==1) ///
(line lfp2 age if mom==1) ///
(line lfp3 age if mom==1), ///
scheme(sj) graphr(c(white)) ///
xtitle("Age") ytitle("Fraction of women") ///
legend(order(1 2 3) label(1 "Out of labor force") label(2 "Part-time work") ///
label(3 "Full-time work") cols(1) region(c(white))) ///
name(lfp_age_mom)

* Gap

reshape wide lfp*, i(age) j(mom)

gen ptgap=(lfp20-lfp21)*100
gen ftgap=(lfp30-lfp31)*100
gen gap=ptgap+ftgap

twoway ///
(line ptgap age) ///
(line ftgap age) ///
(line gap age), ///
scheme(sj) graphr(c(white)) ///
xtitle("Age") ytitle("%") ///
legend(order(1 2 3) label(1 "Part-time gap") label(2 "Full-time gap") ///
label(3 "Participation gap") cols(1) region(c(white))) ///
name(lfp_age_gap)


restore

************************
* Moments for the model*
************************

* Participation rates by age of youngest child

preserve

tab lfp_yr, generate(lfp)

collapse lfp1-lfp4 [iweight=perwt_cs], by(year lifeper_yng)

collapse lfp1-lfp4, by(lifeper_yng)

foreach x of varlist lfp1-lfp4 {
	replace `x'=`x'*100
} 

gen total_lfp=lfp2+lfp3+lfp4
gen pt_ft=lfp3/lfp4

label var lfp1 "Out of labor force"
label var lfp2 "Unemployed"
label var lfp2 "Part time"
label var lfp4 "Full time"
label var total_lfp "Labor force participation"
label var pt_ft "Part time to full time ratio"

twoway ///
(line lfp1 lifeper_yng) ///
(line lfp2 lifeper_yng) ///
(line lfp3 lifeper_yng) ///
(line lfp4 lifeper_yng), ///
scheme(sj) graphr(c(white)) ///
xtitle("Age of youngest child") ytitle("%") ///
xlabel(1 2 3 4 5 6, valuelabel) ///
legend(order(1 2 3 4) label(1 "Out of labor force") label(2 "Unemployed") ///
label(3 "Part time") label(4 "Full time") cols(1) region(c(white))) ///
name(lfp_lifeper_yng)

twoway ///
line total_lfp lifeper_yng, ///
scheme(sj) graphr(c(white)) ///
xtitle("Age of youngest child") ytitle("%") ///
xlabel(1 2 3 4 5 6, valuelabel) 

export excel using Model_moments.xlsx, sheet("lfp_moms") sheetreplace ///
firstrow(varl) 

restore

* Participation rates for childless women

tab lfp, generate(lfp)

collapse lfp1-lfp3 if mom==0 [iweight=perwt_cs], by(year lifeper)

collapse lfp1-lfp3, by(lifeper)

gen total_lfp=lfp2+lfp3
gen pt_ft=lfp2/lfp3

label var lfp1 "Out of labor force"
label var lfp2 "Part time"
label var lfp3 "Full time"
label var total_lfp "Labor force participation"
label var pt_ft "Part time to full time ratio"

export excel using Model_moments.xlsx, sheet("lfp_childless") sheetreplace ///
firstrow(varl) 


restore



