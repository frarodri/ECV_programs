clear all
set more off 
   
* Write here the main folder, where the folders rawdata, output, intermediate 
* and programs are located:
*global rootdir "C:\Users\franj\Documents\GitHub\ECV\working"
global rootdir  "C:\Users\lidic\OneDrive\Escritorio\Cruces&Rodríguez\Encuesta de Condiciones de Vida\ECV\working"
global rawdata "$rootdir\rawdata"
global output "$rootdir\output"
global intermediate "$rootdir\intermediate"
global programs "$rootdir\programs"
 
cd "$rawdata"

import delimited es18r, delimiter(",") clear

rename (rb010 rb020 rb030 rb040 rb060 rb060_f rb062 rb062_f rb063 rb063_f ///
rb064 rb064_f rb100 rb100_f rb070 rb070_f rb080 rb080_f rb090 rb090_f rb110 ///
rb110_f) ///
(year country pid hhid perwt_base perwt_base_f perwt_2y perwt_2y_f perwt_3y ///
perwt_3y_f perwt_4y perwt_4y_f samper samper_f birthmo birthmo_f birthyr ///
birthyr_f sex sex_f sith sith_f)

rb200 rb200_f rb210 rb210_f rb220 rb220_f rb230 rb230_f ///
rb240 rb240_f rl010 rl010_f rl020 rl020_f rl030 rl030_f rl040 rl040_f ///
rl050 rl050_f rl060 rl060_f rl070 rl070_f) 

(year country pid hhid perwt_base perwt_base_f perwt_2y perwt_2y_f perwt_3y ///
perwt_3y_f perwt_4y perwt_4y_f samper samper_f birthmo birthmo_f birthyr ///
birthyr_f sex sex_f sith sith_f  

sith sith_f ///
act_last act_last_f fid fid_f mid mid_f sid sid_f cc1 cc1_f cc2 cc2_f ///
cce cce_f cceo cceo_f ccb ccb_f ccin ccin_f cweight cweight_f)
