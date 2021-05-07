* Preliminaries
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

* Moments for model calibration

cd "$output"
use ecv_women.dta, clear

******************************
******************************
* LABOUR FORCE PARTICIPATION *
******************************
******************************

* Generate individual indicators for LFP status
tab lfp_yr, generate(lfp_yr)
tab lfp_current, generate(lfp_current)

******************************************
* LFP, women aged 28-34 with no children *
******************************************

* Yearly average LFP
preserve

collapse lfp_yr1-lfp_yr4 [iweight=perwt_cs] if ///
age>=28 & age<=34 & mom==0, by(year)

collapse lfp_yr1-lfp_yr4

label var lfp_yr1 "Out of labor force"
label var lfp_yr2 "Unemployed"
label var lfp_yr3 "Part time"
label var lfp_yr4 "Full time"

export excel using Data_moments.xlsx, sheet("LFP") cell(B3) sheetmodify ///
firstrow(varl) 

restore

* Current LFP
preserve

collapse lfp_current1-lfp_current4 [iweight=perwt_cs] if ///
age>=28 & age<=34 & mom==0, by(year)

collapse lfp_current1-lfp_current4

label var lfp_current1 "Out of labor force"
label var lfp_current2 "Unemployed"
label var lfp_current3 "Part time"
label var lfp_current4 "Full time"

export excel using Data_moments.xlsx, sheet("LFP") cell(B5) sheetmodify  

restore

******************************************
* LFP, women aged 31-37 with no children *
******************************************

* Yearly average LFP
preserve

collapse lfp_yr1-lfp_yr4 [iweight=perwt_cs] if ///
age>=31 & age<=37 & mom==0, by(year)

collapse lfp_yr1-lfp_yr4

label var lfp_yr1 "Out of labor force"
label var lfp_yr2 "Unemployed"
label var lfp_yr3 "Part time"
label var lfp_yr4 "Full time"

export excel using Data_moments.xlsx, sheet("LFP") cell(B8) sheetmodify ///
firstrow(varl) 

restore

* Current LFP
preserve

collapse lfp_current1-lfp_current4 [iweight=perwt_cs] if ///
age>=31 & age<=37 & mom==0, by(year)

collapse lfp_current1-lfp_current4

label var lfp_current1 "Out of labor force"
label var lfp_current2 "Unemployed"
label var lfp_current3 "Part time"
label var lfp_current4 "Full time"

export excel using Data_moments.xlsx, sheet("LFP") cell(B10) sheetmodify  

restore

******************************************
* LFP, women aged 31-37 with no children *
******************************************

* Yearly average LFP
preserve

collapse lfp_yr1-lfp_yr4 [iweight=perwt_cs] if ///
age>=34 & age<=40 & mom==0, by(year)

collapse lfp_yr1-lfp_yr4

label var lfp_yr1 "Out of labor force"
label var lfp_yr2 "Unemployed"
label var lfp_yr3 "Part time"
label var lfp_yr4 "Full time"

export excel using Data_moments.xlsx, sheet("LFP") cell(B13) sheetmodify ///
firstrow(varl) 

restore

* Current LFP
preserve

collapse lfp_current1-lfp_current4 [iweight=perwt_cs] if ///
age>=34 & age<=40 & mom==0, by(year)

collapse lfp_current1-lfp_current4

label var lfp_current1 "Out of labor force"
label var lfp_current2 "Unemployed"
label var lfp_current3 "Part time"
label var lfp_current4 "Full time"

export excel using Data_moments.xlsx, sheet("LFP") cell(B15) sheetmodify  

restore

******************************************************
* LFP, women aged 28-34 with a single child aged 0-3 *
******************************************************

* Yearly average LFP
preserve
 
collapse lfp_yr1-lfp_yr4 [iweight=perwt_cs] if ///
age>=28 & age<=34 & nchild==1 & lifeper_yng==1, by(year)

collapse lfp_yr1-lfp_yr4

label var lfp_yr1 "Out of labor force"
label var lfp_yr2 "Unemployed"
label var lfp_yr3 "Part time"
label var lfp_yr4 "Full time"

export excel using Data_moments.xlsx, sheet("LFP") cell(H3) sheetmodify ///
firstrow(varl) 

restore

* Current LFP
preserve

collapse lfp_current1-lfp_current4 [iweight=perwt_cs] if ///
age>=28 & age<=34 & nchild==1 & lifeper_yng==1, by(year)

collapse lfp_current1-lfp_current4

label var lfp_current1 "Out of labor force"
label var lfp_current2 "Unemployed"
label var lfp_current3 "Part time"
label var lfp_current4 "Full time"

export excel using Data_moments.xlsx, sheet("LFP") cell(H5) sheetmodify  

restore

******************************************************
* LFP, women aged 31-37 with a single child aged 3-6 *
******************************************************

* Yearly average LFP
preserve
 
collapse lfp_yr1-lfp_yr4 [iweight=perwt_cs] if ///
age>=31 & age<=37 & nchild==1 & lifeper_yng==2, by(year)

collapse lfp_yr1-lfp_yr4

label var lfp_yr1 "Out of labor force"
label var lfp_yr2 "Unemployed"
label var lfp_yr3 "Part time"
label var lfp_yr4 "Full time"

export excel using Data_moments.xlsx, sheet("LFP") cell(H8) sheetmodify ///
firstrow(varl) 

restore

* Current LFP
preserve

collapse lfp_current1-lfp_current4 [iweight=perwt_cs] if ///
age>=31 & age<=37 & nchild==1 & lifeper_yng==2, by(year)

collapse lfp_current1-lfp_current4

label var lfp_current1 "Out of labor force"
label var lfp_current2 "Unemployed"
label var lfp_current3 "Part time"
label var lfp_current4 "Full time"

export excel using Data_moments.xlsx, sheet("LFP") cell(H10) sheetmodify  

restore

******************************************************
* LFP, women aged 34-40 with a single child aged 6-9 *
******************************************************

* Yearly average LFP
preserve
 
collapse lfp_yr1-lfp_yr4 [iweight=perwt_cs] if ///
age>=34 & age<=40 & nchild==1 & lifeper_yng==3, by(year)

collapse lfp_yr1-lfp_yr4

label var lfp_yr1 "Out of labor force"
label var lfp_yr2 "Unemployed"
label var lfp_yr3 "Part time"
label var lfp_yr4 "Full time"

export excel using Data_moments.xlsx, sheet("LFP") cell(H13) sheetmodify ///
firstrow(varl) 

restore

* Current LFP
preserve

collapse lfp_current1-lfp_current4 [iweight=perwt_cs] if ///
age>=34 & age<=40 & nchild==1 & lifeper_yng==3, by(year)

collapse lfp_current1-lfp_current4

label var lfp_current1 "Out of labor force"
label var lfp_current2 "Unemployed"
label var lfp_current3 "Part time"
label var lfp_current4 "Full time"

export excel using Data_moments.xlsx, sheet("LFP") cell(H15) sheetmodify  

restore

**********************************************************************
* LFP, women aged 31-37 with two children, the youngest one aged 0-3 *
**********************************************************************

* Yearly average LFP
preserve
 
collapse lfp_yr1-lfp_yr4 [iweight=perwt_cs] if ///
age>=31 & age<=37 & nchild==2 & lifeper_yng==1, by(year)

collapse lfp_yr1-lfp_yr4

label var lfp_yr1 "Out of labor force"
label var lfp_yr2 "Unemployed"
label var lfp_yr3 "Part time"
label var lfp_yr4 "Full time"

export excel using Data_moments.xlsx, sheet("LFP") cell(N8) sheetmodify ///
firstrow(varl) 

restore

* Current LFP
preserve

collapse lfp_current1-lfp_current4 [iweight=perwt_cs] if ///
age>=31 & age<=37 & nchild==2 & lifeper_yng==1, by(year)

collapse lfp_current1-lfp_current4

label var lfp_current1 "Out of labor force"
label var lfp_current2 "Unemployed"
label var lfp_current3 "Part time"
label var lfp_current4 "Full time"

export excel using Data_moments.xlsx, sheet("LFP") cell(N10) sheetmodify  

restore

**********************************************************************
* LFP, women aged 34-40 with two children, the youngest one aged 3-6 *
**********************************************************************

* Yearly average LFP
preserve
 
collapse lfp_yr1-lfp_yr4 [iweight=perwt_cs] if ///
age>=34 & age<=40 & nchild==2 & lifeper_yng==2, by(year)

collapse lfp_yr1-lfp_yr4

label var lfp_yr1 "Out of labor force"
label var lfp_yr2 "Unemployed"
label var lfp_yr3 "Part time"
label var lfp_yr4 "Full time"

export excel using Data_moments.xlsx, sheet("LFP") cell(N13) sheetmodify ///
firstrow(varl) 

restore

* Current LFP
preserve

collapse lfp_current1-lfp_current4 [iweight=perwt_cs] if ///
age>=34 & age<=40 & nchild==2 & lifeper_yng==2, by(year)

collapse lfp_current1-lfp_current4

label var lfp_current1 "Out of labor force"
label var lfp_current2 "Unemployed"
label var lfp_current3 "Part time"
label var lfp_current4 "Full time"

export excel using Data_moments.xlsx, sheet("LFP") cell(N15) sheetmodify  

restore

************************************************************************
* LFP, women aged 34-40 with three children, the youngest one aged 0-3 *
************************************************************************

* Yearly average LFP
preserve
 
collapse lfp_yr1-lfp_yr4 [iweight=perwt_cs] if ///
age>=34 & age<=40 & nchild==3 & lifeper_yng==1, by(year)

collapse lfp_yr1-lfp_yr4

label var lfp_yr1 "Out of labor force"
label var lfp_yr2 "Unemployed"
label var lfp_yr3 "Part time"
label var lfp_yr4 "Full time"

export excel using Data_moments.xlsx, sheet("LFP") cell(T13) sheetmodify ///
firstrow(varl) 

restore

* Current LFP
preserve

collapse lfp_current1-lfp_current4 [iweight=perwt_cs] if ///
age>=34 & age<=40 & nchild==3 & lifeper_yng==1, by(year)

collapse lfp_current1-lfp_current4

label var lfp_current1 "Out of labor force"
label var lfp_current2 "Unemployed"
label var lfp_current3 "Part time"
label var lfp_current4 "Full time"

export excel using Data_moments.xlsx, sheet("LFP") cell(T15) sheetmodify  

restore

*******************************************************************************
* LFP by age of youngest child, women aged 28-34 with a single child aged 0-3 *
*******************************************************************************

* Yearly average LFP
preserve
 
collapse lfp_yr1-lfp_yr4 [iweight=perwt_cs] if ///
age>=28 & age<=34 & nchild==1 & lifeper_yng==1, by(year age_yng)

collapse lfp_yr1-lfp_yr4, by(age_yng)

label var lfp_yr1 "Out of labor force"
label var lfp_yr2 "Unemployed"
label var lfp_yr3 "Part time"
label var lfp_yr4 "Full time"

export excel using Data_moments.xlsx, sheet("LFP") cell(G19) sheetmodify ///
firstrow(varl) 

restore

* Current LFP
preserve

collapse lfp_current1-lfp_current4 [iweight=perwt_cs] if ///
age>=28 & age<=34 & nchild==1 & lifeper_yng==1, by(year age_yng)

collapse lfp_current1-lfp_current4, by(age_yng)

label var lfp_current1 "Out of labor force"
label var lfp_current2 "Unemployed"
label var lfp_current3 "Part time"
label var lfp_current4 "Full time"

export excel using Data_moments.xlsx, sheet("LFP") cell(G24) sheetmodify  

restore

*******************************************************************************
* LFP by age of youngest child, women aged 31-37 with two children, the youngest
* one aged 0-3 *
*******************************************************************************

* Yearly average LFP
preserve
 
collapse lfp_yr1-lfp_yr4 [iweight=perwt_cs] if ///
age>=31 & age<=37 & nchild==2 & lifeper_yng==1, by(year age_yng)

collapse lfp_yr1-lfp_yr4, by(age_yng)

label var lfp_yr1 "Out of labor force"
label var lfp_yr2 "Unemployed"
label var lfp_yr3 "Part time"
label var lfp_yr4 "Full time"

export excel using Data_moments.xlsx, sheet("LFP") cell(M19) sheetmodify ///
firstrow(varl) 

restore

* Current LFP
preserve

collapse lfp_current1-lfp_current4 [iweight=perwt_cs] if ///
age>=31 & age<=37 & nchild==2 & lifeper_yng==1, by(year age_yng)

collapse lfp_current1-lfp_current4, by(age_yng)

label var lfp_current1 "Out of labor force"
label var lfp_current2 "Unemployed"
label var lfp_current3 "Part time"
label var lfp_current4 "Full time"

export excel using Data_moments.xlsx, sheet("LFP") cell(M24) sheetmodify  

restore

**********************************************
* LFP mothers aged 30-39 with only one child *
**********************************************

* Yearly average LFP
preserve
 
collapse lfp_yr1-lfp_yr4 [iweight=perwt_cs] if ///
age>=30 & age<=39 & nchild==1 & lifeper_yng==1, by(year)

collapse lfp_yr1-lfp_yr4

label var lfp_yr1 "Out of labor force"
label var lfp_yr2 "Unemployed"
label var lfp_yr3 "Part time"
label var lfp_yr4 "Full time"

export excel using Data_moments.xlsx, sheet("LFP") cell(B29) sheetmodify ///
firstrow(varl) 

restore

* Current LFP
preserve

collapse lfp_current1-lfp_current4 [iweight=perwt_cs] if ///
age>=30 & age<=39 & nchild==1 & lifeper_yng==1, by(year)

collapse lfp_current1-lfp_current4

label var lfp_current1 "Out of labor force"
label var lfp_current2 "Unemployed"
label var lfp_current3 "Part time"
label var lfp_current4 "Full time"

export excel using Data_moments.xlsx, sheet("LFP") cell(B31) sheetmodify  

restore

**********************************
* LFP childless women aged 30-39 *
**********************************

* Yearly average LFP
preserve
 
collapse lfp_yr1-lfp_yr4 [iweight=perwt_cs] if ///
age>=30 & age<=39 & nchild==0, by(year)

collapse lfp_yr1-lfp_yr4

label var lfp_yr1 "Out of labor force"
label var lfp_yr2 "Unemployed"
label var lfp_yr3 "Part time"
label var lfp_yr4 "Full time"

export excel using Data_moments.xlsx, sheet("LFP") cell(B34) sheetmodify ///
firstrow(varl) 

restore

* Current LFP
preserve

collapse lfp_current1-lfp_current4 [iweight=perwt_cs] if ///
age>=30 & age<=39 & nchild==0, by(year)

collapse lfp_current1-lfp_current4

label var lfp_current1 "Out of labor force"
label var lfp_current2 "Unemployed"
label var lfp_current3 "Part time"
label var lfp_current4 "Full time"

export excel using Data_moments.xlsx, sheet("LFP") cell(B36) sheetmodify  

restore


*******************
*******************
* CHILDCARE USAGE *
*******************
*******************

* Generate usage variables
gen prssch_use_yng=(cc_presch_yng>10)
gen inf_use_yng=(cc_inf_yng>0)

*****************************************************************
* Preschool enrolment by mother's LFP status, children aged 0-3 *
*****************************************************************

* Yearly average LFP
preserve

collapse prssch_use_yng [iweight=perwt_cs] ///
if age>=28 & age<=40 & lifeper_yng==1, by(year lfp_yr)

collapse prssch_use_yng, by(lfp_yr)

export excel using Data_moments.xlsx, sheet("Childcare") cell(A4) sheetmodify 

restore

* Current LFP
preserve

collapse prssch_use_yng [iweight=perwt_cs] ///
if age>=28 & age<=40 & lifeper_yng==1, by(year lfp_current)

collapse prssch_use_yng, by(lfp_current)

drop if missing(lfp_current)

export excel prssch_use_yng using Data_moments.xlsx, ///
sheet("Childcare") cell(C4) sheetmodify 

restore

*******************************************************************************
* Average number of preschool hours by mother's LFP status, children aged 0-3 *
*******************************************************************************

* Yearly average LFP
preserve

collapse cc_presch_yng [iweight=perwt_cs] ///
if age>=28 & age<=40 & lifeper_yng==1, by(year lfp_yr)

collapse cc_presch_yng, by(lfp_yr)

export excel using Data_moments.xlsx, sheet("Childcare") cell(A11) sheetmodify 

restore

* Current LFP
preserve

collapse cc_presch_yng [iweight=perwt_cs] ///
if age>=28 & age<=40 & lifeper_yng==1, by(year lfp_current)

collapse cc_presch_yng, by(lfp_current)

drop if missing(lfp_current)

export excel cc_presch_yng using Data_moments.xlsx, ///
sheet("Childcare") cell(C11) sheetmodify 

restore

