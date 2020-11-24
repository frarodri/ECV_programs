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

*1. Coges la base (ecv.dta) con todas las observaciones, quitas las que no tienen spouse (si la variable de spouse id es missing) y dejas solo las mujeres.

drop if missing(sid)
*keep if sex == 2

*2. Quitas todas las variables menos year y spouse id.

keep year sid 


*3. Cambias el nombre de spouse id por el nombre de la variable de id.

rename sid pid
*rename exp experience

*4. Haces un merge 1:1 con ecv.dta con las variables year y id y le dices que conserve sólo las observaciones que están en el master dataset.
merge 1:1 year pid using ecv.dta
keep if _merge==3

*5. Quitas todas las variables menos las que te interesa conservar.

keep sid year pid empstatjan empstatfeb empstatmar empstatapr empstatmay ///
empstatjun empstatjul empstataug empstatsep empstatoct empstatnov empstatdec ///
months_hwrk months_ptse months_ftse wrkhrs_wk ninc_mon ginc_mon birthyr 

*6. Le agregas al nombre de todas las variables el sufijo _spouse.
rename _all  =_spouse
renvars empstatjan empstatfeb empstatmar empstatapr empstatmay empstatjun empstatjul ///
 empstataug empstatsep empstatoct empstatnov empstatdec months_hwrk months_ptse months_ftse ///
 wrkhrs_wk ninc_mon ginc_mon birthyr , suffix(_spouse)

*7. Quitas la variable de id y le cambias el nombre a la variable de spouse id por id.
rename year_spouse year 

drop pid_spouse

rename sid_spouse pid 
*8. Guardas el archivo ( como ecv_spouse.dta?).
duplicates drop 
save ecv_spouse, replace

use ecv, clear 


*9. Abres ecv.dta y haces un merge 1:1 con ecv_spouse.dta con las variables id y year.


merge 1:1 year pid using ecv_spouse.dta

cd "$intermediate"
save ecv, replace


