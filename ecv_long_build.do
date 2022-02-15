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

********************************************************************
* Add spouse's and children's data to each person/year observation *
********************************************************************

cd "$intermediate"
use ecv_long, clear

* Spouse *
**********

* Remove all person/year observations with no spouse data 
*drop if missing(sid)

* Keep only variables we want
*keep sid year

* Children *
************

cd "$intermediate"
use ecv_long, clear

* Remove all person/year observations with no mother's data 
drop if missing(mid)

* Create a variable (child) that tells us the birth order. 1= first child, 
* 2=second children, and another variable (children) with the number of children
* currently living with the mother
sort mid age
by mid, sort: gen child = _n
bysort mid: gen children = _N

bysort mid: egen ageyng=min(age)
bysort mid: egen ageold=max(age)

* One by one, create a file with the data for each child
forvalues i=1(1)10{

preserve 
keep if child==`i'

keep year mid birthmo birthyr age children 

rename _all =_`i'
rename year_`i' year
rename mid_`i' pid

cd "$intermediate"
save ecv_long_child_`i', replace

restore

}

* Merge the children's variables into the main dataset
use ecv_long, clear 

forvalues i=1(1)10{

merge 1:1 year pid using ecv_long_child_`i'.dta
drop _merge

erase ecv_long_child_`i'.dta

}

*********************************

egen nchild=rowmax(children_*)
replace nchild=0 if missing(nchild)
label var nchild "Number of own children living in the house"

gen mom=(nchild>0) if sex==2
label var mom "Is a mom"

label define mom_lbl ///
0 "Childless" ///
1 "Mother"

label values mom mom_lbl

sort id_long year

by id_long: gen wave=_n
by id_long: gen waves=_N

*******

* LFP before and after childbirth

* Keep only women in the 18-65 age range
keep if sex==2 & age>=18 & age<=65

* Generate variables for the first and last year for which there is information
bysort id_long: egen firstyear=min(year)
by id_long: egen lastyear=max(year)

* Identify women that had a baby in 2004, 2005, 2006 and 2007 (before july) 
* respectively

gen b04=(birthyr_1==2004)
gen b05=(birthyr_1==2005)
gen b06=(birthyr_1==2006)
gen b07=(birthyr_1==2007)*(birthmo_1<=6)
bysort id_long: egen birth04=max(b04)
bysort id_long: egen birth05=max(b05)
bysort id_long: egen birth06=max(b06)
bysort id_long: egen birth07=max(b07)

* Identify women that were interviewed in 2004, 2005, 2006, 2007, 2008 and 2009
* respectively

gen int04=(year==2004)
gen int05=(year==2005)
gen int06=(year==2006)
gen int07=(year==2007)
gen int08=(year==2008)
gen int09=(year==2009)

bysort id_long: egen interviewed04=max(int04)
bysort id_long: egen interviewed05=max(int05)
bysort id_long: egen interviewed06=max(int06)
bysort id_long: egen interviewed07=max(int07)
bysort id_long: egen interviewed08=max(int08)
bysort id_long: egen interviewed09=max(int09)

drop int04-int09

* Identify usable births

gen ubirth=b04*interviewed04*interviewed05*interviewed06+/*
*/b05*interviewed05*interviewed06*interviewed07+/*
*/b06*interviewed06*interviewed07*interviewed08+/*
*/b07*interviewed07*interviewed08*interviewed09

* Identify year and month of the usable births
gen ubirth_yr=birthyr_1 if ubirth==1
gen ubirth_mo=birthmo_1 if ubirth==1

* Identify parity of the birth of interest
gen parity=nchild if ubirth_yr==year-1

* Identify usable observations
bysort id_long: egen uobs=total(ubirth)
replace uobs=1 if uobs>0

* Identify the number of usable births
gen usablebirths=birth04*interviewed04*interviewed05*interviewed06+/*
*/birth05*interviewed05*interviewed06*interviewed07+/*
*/birth06*interviewed06*interviewed07*interviewed08+/*
*/birth07*interviewed07*interviewed08*interviewed09

* Code below only works if there is only one birth of interest for each woman,
* for now we only keep the observation if that is the case
keep if usablebirths==1

* Identify the year, month and parity of the birth of interest
bysort id_long: egen byr=max(ubirth_yr)
bysort id_long: egen bmo=max(ubirth_mo)
bysort id_long: egen bpar=max(parity)

*bysort id_long: egen weight=max(perwt_long3)
*drop if missing(weight)

keep year id_long perwt_basic age byr bmo bpar activity_m1 activity_m2 ///
activity_m3 activity_m4 activity_m5 activity_m6 activity_m7 activity_m8 ///
activity_m9 activity_m10 activity_m11 activity_m12

reshape long activity_m, i(year id_long perwt_basic byr bmo bpar) j(month)

gen activity_pre12=activity_m if year==byr & month==bmo
gen activity_pre11=activity_m if (year==byr & month==bmo+1) | ///
(year==byr+1 & month==bmo-11)
gen activity_pre10=activity_m if (year==byr & month==bmo+2) | ///
(year==byr+1 & month==bmo-10)
gen activity_pre9=activity_m if (year==byr & month==bmo+3) | ///
(year==byr+1 & month==bmo-9)
gen activity_pre8=activity_m if (year==byr & month==bmo+4) | ///
(year==byr+1 & month==bmo-8)
gen activity_pre7=activity_m if (year==byr & month==bmo+5) | ///
(year==byr+1 & month==bmo-7)
gen activity_pre6=activity_m if (year==byr & month==bmo+6) | ///
(year==byr+1 & month==bmo-6)
gen activity_pre5=activity_m if (year==byr & month==bmo+7) | ///
(year==byr+1 & month==bmo-5)
gen activity_pre4=activity_m if (year==byr & month==bmo+8) | ///
(year==byr+1 & month==bmo-4)
gen activity_pre3=activity_m if (year==byr & month==bmo+9) | ///
(year==byr+1 & month==bmo-3)
gen activity_pre2=activity_m if (year==byr & month==bmo+10) | ///
(year==byr+1 & month==bmo-2)
gen activity_pre1=activity_m if (year==byr & month==bmo+11) | ///
(year==byr+1 & month==bmo-1)

gen activity_0=activity_m if year==byr+1 & month==bmo

gen activity_post1=activity_m if (year==byr+1 & month==bmo+1) | ///
(year==byr+2 & month==bmo-11)
gen activity_post2=activity_m if (year==byr+1 & month==bmo+2) | ///
(year==byr+2 & month==bmo-10)
gen activity_post3=activity_m if (year==byr+1 & month==bmo+3) | ///
(year==byr+2 & month==bmo-9)
gen activity_post4=activity_m if (year==byr+1 & month==bmo+4) | ///
(year==byr+2 & month==bmo-8)
gen activity_post5=activity_m if (year==byr+1 & month==bmo+5) | ///
(year==byr+2 & month==bmo-7)
gen activity_post6=activity_m if (year==byr+1 & month==bmo+6) | ///
(year==byr+2 & month==bmo-6)
gen activity_post7=activity_m if (year==byr+1 & month==bmo+7) | ///
(year==byr+2 & month==bmo-5)
gen activity_post8=activity_m if (year==byr+1 & month==bmo+8) | ///
(year==byr+2 & month==bmo-4)
gen activity_post9=activity_m if (year==byr+1 & month==bmo+9) | ///
(year==byr+2 & month==bmo-3)
gen activity_post10=activity_m if (year==byr+1 & month==bmo+10) | ///
(year==byr+2 & month==bmo-2)
gen activity_post11=activity_m if (year==byr+1 & month==bmo+11) | ///
(year==byr+2 & month==bmo-1)
gen activity_post12=activity_m if year==byr+2 & month==bmo 

forvalues i= 1(1)12 {

	bysort id_long: egen act_pre`i'=max(activity_pre`i')
	
}
	
by id_long: egen act_0=max(activity_0)
	
forvalues i= 1(1)12 {

	bysort id_long: egen act_post`i'=max(activity_post`i')

}

keep if year==byr & month==1

keep id_long perwt age byr bmo bpar act_pre12 act_pre11 act_pre10 act_pre9 act_pre8 ///
act_pre7 act_pre6 act_pre5 act_pre4 act_pre3 act_pre2 act_pre1 act_0 ///
act_post1 act_post2 act_post3 act_post4 act_post5 act_post6 act_post7 ///
act_post8 act_post9 act_post10 act_post11 act_post12

label values act_pre1- act_post12 activity_months_lbl

* Create year weight based on the number of observations
gen yr04=(byr==2004)
gen yr05=(byr==2005)
gen yr06=(byr==2006)
gen yr07=(byr==2007)

egen totyr04=total(yr04)
egen totyr05=total(yr05)
egen totyr06=total(yr06)
egen totyr07=total(yr07)

gen yrwt=yr04*totyr04/_N+yr05*totyr05/_N+yr06*totyr06/_N+yr07*totyr07/_N

drop yr04-totyr07

cd "$intermediate"
save ecv_long_lfpbirths, replace

****************

rename act_pre# lfp_pre_#
rename act_0 lfp_0
rename act_post# lfp_post_#

recode lfp_pre_* lfp_0 lfp_post_* (1 3 = 1) (2 4 = 2) (5 = 3) (6/9 = 4)

label define lfp_lbl ///
1 "Full-time work" ///
2 "Part-time work" ///
3 "Unemployed" ///
4 "Out of the labour force"

label values lfp_pre_* lfp_0 lfp_post_* lfp_lbl

* Create dummies for each LFP status

forvalues i=1(1)12 {

	tab lfp_pre_`i', generate(pre_`i'_)
	rename pre_`i'_1 ft_pre_`i'
	rename pre_`i'_2 pt_pre_`i'
	rename pre_`i'_3 ue_pre_`i'
	rename pre_`i'_4 olf_pre_`i'
	
	tab lfp_post_`i', generate(post_`i'_)
	rename post_`i'_1 ft_post_`i'
	rename post_`i'_2 pt_post_`i'
	rename post_`i'_3 ue_post_`i'
	rename post_`i'_4 olf_post_`i'
	
}
	
tab lfp_0, generate(lfp_0_)
rename lfp_0_1 ft_0
rename lfp_0_2 pt_0
rename lfp_0_3 ue_0
rename lfp_0_4 olf_0

* Compute yearly status
local birth_rel "pre post"

foreach s of local birth_rel {

	* Number of months spent under each labour force status
	egen ft_months_`s'=rowtotal(ft_`s'_*)
	egen pt_months_`s'=rowtotal(pt_`s'_*)
	egen ue_months_`s'=rowtotal(ue_`s'_*)
	egen olf_months_`s'=rowtotal(olf_`s'_*)

	* First we count total months in labor force
	gen inlf_months_`s'=ft_months_`s'+pt_months_`s'+ue_months_`s'
	* We then compute the number of months the person actually worked
	gen work_months_`s'=ft_months_`s'+pt_months_`s'
	* Compute full time equivalent months, where a full time month is 1, part-time 
	* month 0.5 and unemployment is zero
	gen fte_months_`s'=ft_months_`s'+0.5*pt_months_`s'
	* Compute average full time equivalent work during the year when in the labour 
	* force
	gen avg_fte_`s'=fte_months_`s'/inlf_months_`s'

	* Generate lfp for the year
	* First we assign to in labor force those who had worked for more than 6 months
	* during the year, or whose average full time equivalent work multiplied by 
	* their months in the labor force are enough to bump them to part-time
	gen inlf_`s'=1 if inlf_months_`s'>5 | ///
	(!missing(avg_fte_`s') & avg_fte_`s'*work_months_`s'>3)
	replace inlf_`s'=0 if missing(inlf_`s')

	* Then we create the lfp variable for the year
	* We first create a variable that recodes the average full time equivalent work 
	* for people considered to be in the labor force, to 0 when unemployed (person 
	* reported being in the labor force but didn't work enough hours to reach part 
	* time), 1 for part time and 2 for full time
	egen lfp_`s'=cut(avg_fte_`s'), at(0,0.25,0.75,1.25) icodes
	* Add 1 to match lfp_current
	replace lfp_`s'=lfp_`s'+1
	* Add people olf with a zero
	replace lfp_`s'=0 if missing(lfp_`s')
	
	* Create dummies for each status
	tab lfp_`s', generate(`s'_)
	rename `s'_1 olf_`s'
	rename `s'_2 ue_`s'
	rename `s'_3 pt_`s'
	rename `s'_4 ft_`s'
}

label var lfp_pre "Labor force status year pre-birth"
label var lfp_post "Labor force status year post-birth"

label define lfp_yr ///
3 "Full time work" ///
2 "Part time work" ///
1 "Unemployed" ///
0 "Out of the labor force" 

label values lfp_pre lfp_post lfp_yr

cd "$intermediate"
save ecv_lfpbirths_04_07, replace

* Obtain the averages 

* Monthly
preserve

collapse ft_pre_1-olf_0 yrwt [iweight=perwt_basic], by(byr bpar)
collapse ft_pre_1-olf_0 [iweight=yrwt], by(bpar) 

keep if bpar<=2

forvalues i=1(1)12 {
	
	local j = `i'+12
	local k = 13-`i'
	
	rename ft_pre_`i' ft_`k'
	rename ft_post_`i' ft_`j'
	
	rename pt_pre_`i' pt_`k'
	rename pt_post_`i' pt_`j'
	
	rename ue_pre_`i' ue_`k'
	rename ue_post_`i' ue_`j'
	
	rename olf_pre_`i' olf_`k'
	rename olf_post_`i' olf_`j'
}


reshape long ft_ pt_ ue_ olf_, i(bpar) j(months_birth) 	

replace months_birth=months_birth-13 if months_birth>=1 & months_birth<=12
replace months_birth=months_birth-12 if months_birth>=13

sort bpar months_birth

label var bpar "Birth parity"
label var months_birth "Months from birth"
label var ft_ "Full time"
label var pt_ "Part time"
label var ue_ "Unemployed"
label var olf_ "Out of labour force"

replace ft_=ft_*100 
replace pt_=pt_*100 
replace ue_=ue_*100
replace olf_=olf_*100

* Graphs
twoway ///
(line ft_ months_birth) ///
(line pt_ months_birth) ///
(line olf_ months_birth), ///
by (bpar) ///
ytitle("%") ///
xline(0, lcolor(red)) ///
xlabel(-12 -6 0 6 12) ///
scheme(sj) ///
graphr(c(white))

restore

* Yearly
preserve

collapse ft_pre pt_pre ue_pre olf_pre ft_post pt_post ue_post olf_post yrwt ///
[iweight=perwt_basic], by(byr bpar)

collapse ft_pre pt_pre ue_pre olf_pre ft_post pt_post ue_post olf_post ///
[iweight=yrwt], by(bpar)

label var bpar "Birth parity"
label var ft_pre "Full time pre birth"
label var pt_pre "Part time pre birth"
label var ue_pre "Unemployed time pre birth"
label var olf_pre "Out of labour force time pre birth"
label var ft_post "Full time post birth"
label var pt_post "Part time post birth"
label var ue_post "Unemployed time post birth"
label var olf_post "Out of labour force time post birth"

cd "$output"
export excel using Moments_data.xlsx, sheet("lfp_yr_birth") sheetreplace ///
firstrow(varl) 

restore


