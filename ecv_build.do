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

* Write here the name of the main dataset:
global mainds "ecv_04_08"

*****************************************************
* Add spouse's data to each person/year observation *
*****************************************************

* Open the main dataset
cd "$output"
use "$mainds" ,clear

* Remove all person/year observations with no spouse data 
drop if missing(sid)

* Keep only variables we want
keep sid year activity_m1 activity_m2 activity_m3 activity_m4 ///
activity_m5 activity_m6 activity_m7 activity_m8 activity_m9 ///
activity_m10 activity_m11 activity_m12 months_ft months_pt ///
months_ue months_inactive birthyr 

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
use "$mainds", clear

* Merge spouse's dataset into main dataset 
cd "$intermediate"
merge 1:1 year pid using ecv_spouse.dta, generate(_mergespouse)

save ecv_spouse, replace

*******************************************************
* Add children's data to each person/year observation *
*******************************************************

* Open the main dataset
cd "$output"
use "$mainds" ,clear

* Remove all person/year observations with no mother's data 
drop if missing(mid)

* Drop everyone older than 18? No
*drop if year-birthyr>18

* Create a variable (child) that tells us the birth order. 1= first child, 
* 2=second child, and another variable (children) with the number of children
* currently living with the mother
*tostring(year mid), gen(year_str mid_str)

*gen id_year = mid_str+year_str
*destring(id_year), replace
*drop mid_str year_str

*sort id_year birthyr
*by id_year, sort: gen child = _n
*bysort id_year: gen children = _N

gen negbirthyr=-birthyr
sort mid year negbirthyr
by mid year: gen child=_n
drop negbirthyr

sum child
local maxchild=`r(max)'

* One by one, create a file with the data for each child.
forvalues i=1(1)`maxchild'{

	preserve 
	keep if child==`i'

	keep year pid mid cc_presch cc_sch cc_xsch cc_other cc_pro ///
	cc_inf ccweight birthyr
	
	* This variable will help count the number of children per woman later
	gen child=1

	* We create the variable for child's age so that is years old at the 
	* beginning of the year, because that's how eligibility for school is 
	* determined in Spain
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

forvalues i=1(1)`maxchild'{

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

* Children and motherhood *
***************************

* Generate variable total number of children 
egen nchild=rowtotal(child_*)
label var nchild "Number of own children living in the house"

* Generate dummy variable for mothers 
gen mom=nchild>0 if sex==2
label var mom "Is a mom"

label define mom_lbl ///
0 "Childless" ///
1 "Mother"
label values mom mom_lbl

* Generate a variable with total number of births (as oposed to children, in 
* order to account for multiple births) 
gen births=nchild

* Substract 1 from births for every time an age is repeated among children
local maxbirthscheck=`maxchild'-1
forvalues i=1(1)`maxbirthscheck'{

	local j=`i'+1
	replace births=births-1 if age_`i'==age_`j' & !missing(age_`i')
	
}

label var births "Total number of births"

* Generate age of youngest and eldest child
egen age_yng=rowmin(age_*)
egen age_eld=rowmax(age_*)

label var age_yng "Age of youngest child"
label var age_eld "Age of eldest child"

* Generate age of first birth
gen age_fbirth=age-age_eld
label var age_fbirth "Age at first birth" 

* Generate labor force participation variables *
************************************************

* We first create a current lfp variable
recode activity_raw (1 = 3) (2 = 2) (3 = 1) (4/9=0), gen(lfp_current)
label var lfp_current "Current labor force status"

label define lfp_lbl ///
3 "Full time work" ///
2 "Part time work" ///
1 "Unemployed" ///
0 "Out of the labor force" 

label values lfp_current lfp_lbl

* Now we create LFP variables for the year. 

* First we count total months in labor force
gen months_lf=months_ft+months_pt+months_ue
* We then compute the number of months the person actually worked
gen months_wrk=months_ft+months_pt
* Compute full time equivalent months, where a full time month is 1, part-time 
* month 0.5 and unemployment is zero
gen months_fte=months_ft+0.5*months_pt
* Compute average full time equivalent work during the year when in the labour 
* force
gen avg_fte=months_fte/months_lf

* Generate lfp for the year
* First we assign to in labor force those who had worked for more than 6 months
* during the year, or whose average hours multiplied by their months in the 
*labor force are enough to bump them to part-time
gen inlf_yr=1 if months_lf>5 | ///
(!missing(avg_fte) & avg_fte*months_wrk>3)
replace inlf_yr=0 if missing(inlf_yr)

* Then we create the lfp variable for the year
* We first create a variable that recodes the average hours for people 
* considered to be in the labor force, to 0 when unemployed (person reported
* being in the labor force but didn't work enough hours to reach part time), 1
* for part time and 2 for full time
egen lfp_yr=cut(avg_fte), at(0,0.25,0.75,1.25) icodes
* Add 1 to match lfp_current
replace lfp_yr=lfp_yr+1
* Add people olf with a zero
replace lfp_yr=0 if missing(lfp_yr)

label var lfp_yr "Yearly labor force status"
label values lfp_yr lfp_lbl

* Generate childcare variables *
********************************

* Youngest child is the first one
gen cc_presch_yng=0 if mom==1 & age_1<=12
gen cc_sch_yng=0 if mom==1 & age_1<=12  
gen cc_xsch_yng=0 if mom==1 & age_1<=12
gen cc_other_yng=0 if mom==1 & age_1<=12
gen cc_pro_yng=0 if mom==1 & age_1<=12 
gen cc_inf_yng=0 if mom==1 & age_1<=12

replace cc_presch_yng=cc_presch_1 if !missing(cc_presch_1)
replace cc_sch_yng=cc_sch_1 if !missing(cc_sch_1)
replace cc_xsch_yng=cc_xsch_1 if !missing(cc_xsch_1)
replace cc_other_yng=cc_other_1 if !missing(cc_other_1)
replace cc_pro_yng=cc_pro_1 if !missing(cc_pro_1)
replace cc_inf_yng=cc_inf_1 if !missing(cc_inf_1)

label var cc_presch_yng "Weekly hours at pre-school for youngest child"
label var cc_sch_yng "Weekly hours at school for youngest child"
label var cc_xsch_yng "Weekly hours at after school activities for youngest child"
label var cc_other_yng "Weekly hours under other childcare for youngest child"
label var cc_pro_yng "Weekly hours under professional childcare for youngest child"
label var cc_inf_yng "Weekly hours under informal childcare for youngest child"

gen cc_paid_yng=cc_presch_yng+cc_xsch_yng+cc_other_yng+cc_pro_yng if age_yng<=2
replace cc_paid_yng=cc_xsch_yng+cc_other_yng+cc_pro_yng if age_yng>2 & age_yng
gen cc_unpaid_yng=cc_sch_yng+cc_inf_yng if age_yng<=2
replace cc_unpaid_yng=cc_presch_yng+cc_sch_yng+cc_inf_yng if age_yng>2

label var cc_paid_yng "Weekly hours under paid childcare for youngest child"
label var cc_unpaid_yng "Weekly hours under unpaid childcare for youngest child" 

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

keep if sex==2 & age>=25 & births<=3 & nchild<=3

keep year perwt_cs pweight_16plus age marst mom nchild age_yng age_eld ///
age_fbirth lfp_current lfp_yr months_ft months_pt months_ue cc_presch_yng ///
cc_sch_yng cc_xsch_yng cc_other_yng cc_pro_yng cc_inf_yng cc_paid_yng ///
cc_unpaid_yng perwt_cs

cd "$output"
save "${mainds}_women.dta", replace

* Moments for calibration *
***************************

* LFP for mothers *

gen age_yng_preyrg=age_yng-1
label var age_yng_preyrg "Age of youngest child previous year (grouped)"
recode age_yng_preyrg (-1 = .) (0 = 0) (3/5 = 3) (6/11 = 4) (12/99 = 5)
label define age_yng_g_lbl ///
0 "<1 year old" ///
1 "1 year old" ///
2 "2 years old" ///
3 "3-6 years old (pre-school)" ///
4 "6-12 years old (elementary)" ///
5 "12+ years old"
label values age_yng_preyrg age_yng_g_lbl

tab lfp_yr, generate(lfp)
rename lfp1 olf_yr
rename lfp2 ue_yr
rename lfp3 pt_yr
rename lfp4 ft_yr

preserve

collapse olf_yr ue_yr pt_yr ft_yr [iweight=perwt_cs] if age_yng_preyrg<5, ///
by(year age_yng_preyrg)

collapse olf_yr ue_yr pt_yr ft_yr, by(age_yng_preyrg)

label var olf_yr "Out of labour force"
label var ue_yr "Unemployed"
label var pt_yr "Part time work"
label var ft_yr "Full time work"

* Export
cd "$output"
export excel using "${mainds}_moments.xlsx", sheet("lfp_moms") sheetreplace ///
firstrow(varl) 

* Graph 
replace olf_yr=olf_yr*100
replace ue_yr=ue_yr*100
replace pt_yr=pt_yr*100
replace ft_yr=ft_yr*100

twoway ///
(line ft_yr age_yng_preyrg) ///
(line pt_yr age_yng_preyrg) ///
(line olf_yr age_yng_preyrg) ///
(line ue_yr age_yng_preyrg), ///
scheme(sj) graphr(c(white)) ///
xtitle("Age of youngest child") ytitle("%") ///
xlabel(0 "<1" 1 "1" 2 "2" 3 "3-6" 4 "6-12") ///
yscale(range(0 64)) ///
ylabel(0 20 40 60) ///
legend(order(1 2 3 4) label(1 "Full time") label(2 "Part time") ///
label(3 "Out of the labour force") label(4 "Unemployed") ///
cols(1) region(c(white))) ///
name(lfp_age_yng)

restore

* LFP childless women *

recode age (26/30 = 1) (31/35 = 2) (36/40 =3) (41/45 =4) (nonmissing = .), ///
generate(age_groups_single)
label var age_groups_single "Age groups"
label define age_groups_single_lbl ///
1 "25-30" ///
2 "30-35" ///
3 "35-40" ///
4 "40-45" 
label values age_groups_single age_groups_single_lbl

preserve

collapse olf_yr ue_yr pt_yr ft_yr [iweight=perwt_cs] if mom==0, ///
by(year age_groups_single)

collapse olf_yr ue_yr pt_yr ft_yr, by(age_groups_single)

label var olf_yr "Out of labour force"
label var ue_yr "Unemployed"
label var pt_yr "Part time work"
label var ft_yr "Full time work"

drop if missing(age_groups_single)

* Export
cd "$output"
export excel using "${mainds}_moments.xlsx", sheet("lfp_childless") ///
sheetreplace firstrow(varl) 

* Graph
replace olf_yr=olf_yr*100
replace ue_yr=ue_yr*100
replace pt_yr=pt_yr*100
replace ft_yr=ft_yr*100

twoway ///
(line ft_yr age_groups_single) ///
(line pt_yr age_groups_single) /// 
(line olf_yr age_groups_single) ///
(line ue_yr age_groups_single), ///
scheme(sj) graphr(c(white)) ///
xtitle("Age") ytitle("%") ///
xlabel(1 2 3 4, valuelabel) ///
legend(order(1 2 3 4) label(1 "Full time") label(2 "Part time") ///
label(3 "Out of the labour force") label(4 "Unemployed") cols(1) ///
region(c(white))) ///
name(lfp_age_childless)

restore 

* Childcare use by age of child and current labor participation status of the 
* mother *

recode age_yng (3/5 = 3) (6/11 = 4) (12/99 = 5), generate(age_yng_g)
label var age_yng_g "Age of youngest child (grouped)"
label values age_yng_g age_yng_g_lbl

preserve

collapse cc_presch_yng cc_sch_yng cc_xsch_yng cc_other_yng cc_pro_yng ///
cc_inf_yng if age_yng_g<5 [iweight=perwt_cs], by(year age_yng_g lfp_current)

collapse cc_presch_yng cc_sch_yng cc_xsch_yng cc_other_yng cc_pro_yng ///
cc_inf_yng if age_yng_g<5, by(age_yng_g lfp_current)

drop if missing(lfp_current)

egen cc_total=rowtotal(cc_*)
gen cc_paid=cc_presch_yng*(age_yng_g<=2)+cc_xsch_yng+cc_other_yng+cc_pro_yng
gen cc_unpaid=cc_presch_yng*(age_yng_g>2)+cc_sch_yng+cc_inf_yng

label var cc_presch_yng "Pre-school"
label var cc_sch_yng "School" 
label var cc_xsch_yng "Extra-school" 
label var cc_other_yng "Other childcare center" 
label var cc_pro_yng "Paid at home"
label var cc_inf_yng "Informal"
label var cc_paid "Paid"
label var cc_unpaid "Unpaid"
label var cc_total "Total"

* Export
cd "$output"
export excel using "${mainds}_moments.xlsx", sheet("childcare") ///
sheetreplace firstrow(varl) 

* Graphs
twoway ///
area cc_paid age_yng_g || rarea cc_paid cc_total age_yng_g, ///
by(lfp_current) ///
scheme(sj) graphr(c(white)) ///
xtitle("Age of youngest child") ytitle("Hours per week") ///
xlabel(0 "<1" 1 "1" 2 "2" 3 "3-6" 4 "6-12") ///
legend(order(1 2) label(1 "Paid") label(2 "Unpaid")) ///
name(childcare_paid_unpaid)

twoway ///
(line cc_presch_yng age_yng_g) ///
(line cc_sch_yng age_yng_g) ///
(line cc_inf_yng age_yng_g) ///
(line cc_total age_yng_g) , ///
by (lfp_current) ///
scheme(sj) graphr(c(white)) ///
xtitle("Age of youngest child") ytitle("Hour per week") ///
xlabel(0 1 2 3 4, valuelabel) ///
legend(order(1 2 3 4) label(1 "Pre-school") label(2 "School") ///
label(3 "Informal") label(4 "Total") cols(1) region(c(white))) ///
name(childcare)

restore


* Graphs and tables *
*********************

* Childcare use *
*****************

* THIS DOESNT MAKE ANY SENSE BECAUSE LFP IS MEASURED FOR -LAST YEAR-
* By age and average lfp through the year
preserve

collapse cc_presch_yng cc_sch_yng cc_xsch_yng cc_other_yng cc_pro_yng ///
cc_inf_yng cc_paid_yng cc_unpaid_yng if age_yng<=12 [iweight=perwt_cs], ///
by(year lfp_yr age_yng)

collapse cc_presch_yng cc_sch_yng cc_xsch_yng cc_other_yng cc_pro_yng ///
cc_inf_yng cc_paid_yng cc_unpaid_yng, by(lfp_yr age_yng)

twoway ///
(line cc_presch_yng age_yng if lfp==0 & age_yng<=5) ///
(line cc_presch_yng age_yng if lfp==2 & age_yng<=5) ///
(line cc_presch_yng age_yng if lfp==3 & age_yng<=5), ///
xline(3, lcolor(red)) ///
scheme(sj) graphr(c(white)) ///
xtitle("Age of youngest child") ytitle("Hours per week") ///
legend(order(1 2 3) label(1 "Out of labor force") label(2 "Part-time work") ///
label(3 "Full-time work") cols(1) region(c(white))) ///
name(presch_lfp)

twoway ///
(line cc_inf_yng age_yng if lfp==0 & age_yng<=5) ///
(line cc_inf_yng age_yng if lfp==2 & age_yng<=5) ///
(line cc_inf_yng age_yng if lfp==3 & age_yng<=5), ///
xline(3, lcolor(red)) ///
scheme(sj) graphr(c(white)) ///
xtitle("Age of youngest child") ytitle("Hours per week") ///
legend(order(1 2 3) label(1 "Out of labor force") label(2 "Part-time work") ///
label(3 "Full-time work") cols(1) region(c(white))) ///
name(inf_lfp)

twoway ///
(line cc_paid_yng age_yng if lfp==0 & age_yng<=5) ///
(line cc_paid_yng age_yng if lfp==2 & age_yng<=5) ///
(line cc_paid_yng age_yng if lfp==3 & age_yng<=5), ///
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
(line cc_presch_yng age_yng if lfp==2 & age_yng<=5) ///
(line cc_presch_yng age_yng if lfp==3 & age_yng<=5), ///
xline(3, lcolor(red)) ///
scheme(sj) graphr(c(white)) ///
xtitle("Age of youngest child") ytitle("Hours per week") ///
legend(order(1 2 3) label(1 "Out of labor force") label(2 "Part-time work") ///
label(3 "Full-time work") cols(1) region(c(white))) ///
name(presch_lfp_current)

twoway ///
(line cc_inf_yng age_yng if lfp==0 & age_yng<=5) ///
(line cc_inf_yng age_yng if lfp==2 & age_yng<=5) ///
(line cc_inf_yng age_yng if lfp==3 & age_yng<=5), ///
xline(3, lcolor(red)) ///
scheme(sj) graphr(c(white)) ///
xtitle("Age of youngest child") ytitle("Hours per week") ///
legend(order(1 2 3) label(1 "Out of labor force") label(2 "Part-time work") ///
label(3 "Full-time work") cols(1) region(c(white))) ///
name(inf_lfp_current)

twoway ///
(line cc_paid_yng age_yng if lfp==0 & age_yng<=5) ///
(line cc_paid_yng age_yng if lfp==2 & age_yng<=5) ///
(line cc_paid_yng age_yng if lfp==3 & age_yng<=5), ///
xline(3, lcolor(red)) ///
scheme(sj) graphr(c(white)) ///
xtitle("Age of youngest child") ytitle("Hours per week") ///
legend(order(1 2 3) label(1 "Out of labor force") label(2 "Part-time work") ///
label(3 "Full-time work") cols(1) region(c(white))) ///
name(ccpaid_lfp_current)

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

tab lfp_yr, generate(lfp)

collapse lfp1-lfp4 if age>=25 & age<=65 [iweight=perwt_cs], by(year age mom)

collapse lfp1-lfp4, by(age mom)

* Childless women
twoway ///
(line lfp1 age if mom==0) ///
(line lfp3 age if mom==0) ///
(line lfp4 age if mom==0), ///
scheme(sj) graphr(c(white)) ///
xtitle("Age") ytitle("Fraction of women") ///
legend(order(1 2 3) label(1 "Out of labor force") label(2 "Part-time work") ///
label(3 "Full-time work") cols(1) region(c(white))) ///
name(lfp_age_childless)

* Moms
twoway ///
(line lfp1 age if mom==1) ///
(line lfp3 age if mom==1) ///
(line lfp4 age if mom==1), ///
scheme(sj) graphr(c(white)) ///
xtitle("Age") ytitle("Fraction of women") ///
legend(order(1 2 3) label(1 "Out of labor force") label(2 "Part-time work") ///
label(3 "Full-time work") cols(1) region(c(white))) ///
name(lfp_age_mom)

* Gap

reshape wide lfp*, i(age) j(mom)

gen ptgap=(lfp30-lfp31)*100
gen ftgap=(lfp40-lfp41)*100
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

*************************
* Moments for the model *
*************************

* Participation rates by age of youngest child

preserve

tab lfp_yr, generate(lfp)
gen age_yng_lfp=age_yng-1

collapse lfp1-lfp4 [iweight=perwt_cs], by(year age_yng_lfp)

collapse lfp1-lfp4, by(age_yng_lfp)

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
(line lfp1 age_yng_lfp if age_yng_lfp>=0 & age_yng_lfp<=12) ///
(line lfp2 age_yng_lfp if age_yng_lfp>=0 & age_yng_lfp<=12) ///
(line lfp3 age_yng_lfp if age_yng_lfp>=0 & age_yng_lfp<=12) ///
(line lfp4 age_yng_lfp if age_yng_lfp>=0 & age_yng_lfp<=12), ///
scheme(sj) graphr(c(white)) ///
xtitle("Age of youngest child") ytitle("%") ///
xlabel(1 2 3 4 5 6, valuelabel) ///
legend(order(1 2 3 4) label(1 "Out of labor force") label(2 "Unemployed") ///
label(3 "Part time") label(4 "Full time") cols(1) region(c(white))) ///
name(lfp_age_yng)

twoway ///
line total_lfp age_yng_lfp if age_yng_lfp<=12, ///
scheme(sj) graphr(c(white)) ///
xtitle("Age of youngest child") ytitle("%") ///
xlabel(1 2 3 4 5 6, valuelabel) 

export excel using Model_moments.xlsx, sheet("lfp_moms") sheetreplace ///
firstrow(varl) 

restore

* Participation rates for childless women

tab lfp_yr, generate(lfp)

collapse lfp1-lfp4 if mom==0 [iweight=perwt_cs], by(year age)

collapse lfp1-lfp4, by(age)

gen total_lfp=lfp3+lfp4
gen pt_ft=lfp3/lfp4

label var lfp1 "Out of labor force"
label var lfp2 "Part time"
label var lfp3 "Full time"
label var total_lfp "Labor force participation"
label var pt_ft "Part time to full time ratio"

export excel using Model_moments.xlsx, sheet("lfp_childless") sheetreplace ///
firstrow(varl) 


restore



