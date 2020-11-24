/*
 Authors: Lidia Cruces, F. Javier Rodríguez-Román 
*/
 
clear all 
set more off

* Write here the main folder, where the folders rawdata, output, intermediate 
* and programs are located:

global rootdir  "C:\Users\lidic\OneDrive\Escritorio\Cruces&Rodríguez\Encuesta de Condiciones de Vida\ECV\working"
*global rootdir "C:\Users\franj\Documents\GitHub\ECV\working"

global rawdata "$rootdir\rawdata"
global output "$rootdir\output"
global intermediate "$rootdir\intermediate"
global programs "$rootdir\programs"

cd "$rootdir"
cd "$output"

use "ecv.dta" ,clear

* I eliminate all the households in which there is no father and mother, like this the sample id= children id

drop if missing(fid)
drop if missing(mid)

* Create the variable children that tells us the birth order. 1= first children, 2=second children...

tostring(year mid), gen(year_str mid_str)

gen id_year = mid_str+year_str
destring(id_year), replace
drop mid_str year_str
by id_year , sort: gen children = _n

bysort id_year: gen num_children = _N
*This step is made because I need to include in ecv.dta the id for children 
rename pid ccid
gen cid=ccid
drop ccid
rename mid pid

*forvalues i=1(1)12{
forvalues i=1(1)3{

preserve 
keep if children==`i'
gen children_`i'_id= cid
renvars cc1 cc2 cce cceo ccb ccin birthyr, suffix(_`i')

keep year pid children_`i'_id  num_children cc1_`i' cc2_`i' cce_`i' cceo_`i' ccb_`i' ccin_`i' birthyr_`i'

save ecv_cid_`i', replace


use ecv, clear 
merge 1:1 year pid using ecv_cid_`i'.dta
drop _merge


save ecv_cid_`i', replace

restore
}



use ecv_cid_1, clear

*forval k = 2/12 {    
forval k = 2/3 { 
     merge 1:1 year pid using ecv_cid_`k', nogen
}

save ecv_children.dta, replace

*forval k = 1/12 {    
forval k = 1/3 { 
     erase ecv_cid_`k'.dta
}
