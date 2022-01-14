*********************************************************************************************************************************************		 
* Tilburg University Department of Cognitive Science and Artificial Intelligence
* MSc in Data Science and Society
* Thesis
* 
* Date: September 2021
* Author: Hazal Colak
*********************************************************************************************************************************************
*********************************************************************************************************************************
clear
clear matrix
set more off

***********************************************************************************************************************************
*SETTING FOLDER PATHS
***********************************************************************************************************************************		

global data "C:\Users\hazal\Desktop\Personal\Tilburg MSc\Thesis\Data\2.Codes&Analysis"
global data1 "$data\1.Original\stata"
global codes "$data\3.Codes"
global logfiles  "$data\4.Tables and Analysis"
 
**********************************************************************************************************************************


*******************************HH MODULE INDIVIDUAL LEVEL DATASETS 2016**********************************************************

*--------------------------------HH MODULE 	A------------------------------------
***HH Module B contains information about hh roster including gender, education
**level and age groups.

use "$data1\hh_mod_b_16.dta",clear

gen year=0 

***Adding HH Module A to HH Module B
merge m:1 y3_hhid using "$data1\hh_mod_a_filt_16.dta", generate (_merge_hha_2016)
drop if _merge_hha_2016==2 //HH Module A only contains information about hh identification.
//For this reason, I started with HH Module B and added identifier info from Module A.


***Regenerating the gender variable
gen gender=0 if hh_b03==1
replace gender=1 if hh_b03==2
label var gender "Gender of HH members"
label define gender_val 0 "Male" 1 "Female"
label values gender gender_val

***Gender of HH Head
gen _hh_head_gen=gender if hh_b04==1
bysort y3_hhid:egen hh_head_gender=max(_hh_head_gen)
label define hh_head_gender_val 0 "Male" 1 "Female"
label values hh_head_gender hh_head_gender_val

***Mother presence in HH
gen mother_presence=1 if hh_b19a==1
replace mother_presence=0 if hh_b19a!=1
label define mother_presence_val 0 "No" 1 "Yes"
label values mother_presence mother_presence_val

***Father presence in HH
gen father_presence=1 if hh_b16a==1
replace father_presence=0 if hh_b16a!=1
label define father_presence_val 0 "No" 1 "Yes"
label values father_presence father_presence_val

//order id_code gender hh_b06_3a hh_b04 hh_b16a hh_b16b hh_b18 hh_b19a hh_b19b hh_b21, after(y3_hhid)

save "$data\2.Processed\2016_hh_individual.dta", replace

*--------------------------------HH MODULE C------------------------------------
***HH Module C contains information about education of all HH members

merge 1:1 PID using "$data1\hh_mod_c_16.dta", generate (_merge_hhc_2016)
drop if _merge_hhc_2016==2

save "$data\2.Processed\2016_hh_individual.dta", replace

*--------------------------------HH MODULE D------------------------------------
***HH Module D contains information about health situation of all HH members

***Merging HH Modules D
merge 1:1 PID using "$data1\hh_mod_d_16.dta", generate (_merge_hhd_2016)
drop if _merge_hhd_2016==2

save "$data\2.Processed\2016_hh_individual.dta", replace

*--------------------------------HH MODULE E------------------------------------
***HH Module E contains information about time use and labour of all HH members

***Merging HH Modules E
merge 1:1 PID using "$data1\hh_mod_e_16.dta", generate (_merge_hhe_2016)
drop if _merge_hhe_2016==2

save "$data\2.Processed\2016_hh_individual.dta", replace

*--------------------------------HH MODULE F------------------------------------
***HH Module F contains information about housing in general for each HH

***Merging HH Modules F
merge m:1 y3_hhid using "$data1\hh_mod_f_16.dta", generate (_merge_hhf_2016)
drop if _merge_hhf_2016==2

save "$data\2.Processed\2016_hh_individual.dta", replace

*---------------------------MID-STEP DATA PROCESSING----------------------------
***Using the merged version so far to generate variables related to hh which will then be
//used while merging the following modules
use "$data\2.Processed\2016_hh_individual.dta", clear

**Total number of individuals from all age groups living in the household
gen ind=1
bys y3_hhid: egen total_hh_member = sum(ind)
label var total_hh_member "Number of individuals living in the household"

**There have been two visits paid to HHs to complete the survey. And each hh members were
//asked their ages in both visits. For this reason, there are two variables (hh_b05a and 
//hh_b06_3a) related to the ages of individuals. hh_b06_3a is the latest one that will be
//mainly used for this analysis. However, there are 327 people (out of 12266) whose age is
//not known. I filled in these meesing values from the first visit (if it exists).

gen age=hh_b06_3a
replace age=(hh_b05a) if hh_b06_3a==. //Now, there is no missing value for age.#

**Total number of adults living in HH
gen adult = (age>=18) if age!=.
label var adult "Adults over 18"
bys y3_hhid: egen total_adult = sum(adult)
label var total_adult "Total number of adults in HH over 18"

**Total number of children living in HH
gen p0_17 = (age>=0 & age<=17) if age!=.
label var p0_17 "Children under 18"
bys y3_hhid: egen total0_17 = sum(p0_17)
label var total0_17 "Total number of children in HH between 0 and 17"

**Child age groups
gen gr_total0_17=1 if total0_17>=1 & total0_17<=2
replace gr_total0_17=2 if total0_17>=3 & total0_17<=4
replace gr_total0_17=3 if total0_17>=5 & total0_17!=.

label var gr_total0_17 "Number of children under 14 in the household"
label define child_groups 1 "1-2" 2 "3-4" 3 "5 or more"
label values gr_total0_17 child_groups
 
***Total number of elderly living in the HH
/*Government of Malawi adopted the National Policy for Older Persons in 2016. The policy defines an older person as a person
who is of age 60 years or above.
Source: https://www.un.org/development/desa/ageing/wp-content/uploads/sites/24/2019/04/MISA-Survey-Report.pdf*/

gen elderly= 0
replace elderly= 1 if age >60
bysort y3_hhid: egen num_elderly = sum(elderly)


*** Adult equalized scale (according to the modified OECD equivalence scale)
* Here I create the adult equalized scale for each household according to the modified OECD equivalence scale
*Sources: Eurostat Glossary - http://ec.europa.eu/eurostat/statistics-explained/index.php/Glossary:Equivalised_disposable_income
* OECD note: http://www.oecd.org/eco/growth/OECD-Note-EquivalenceScales.pdf 

g aes1= 1 if total_adult==1 & total_hh_member==1
replace aes1=1+(total_adult-1)*0.5+total0_17*0.3 if total_hh_member>1 
label var aes1 "Adult equivalence scale - OECD new"

**Adult equalized scale (according to the old OECD equivalence scale)

g aes2= 1 if total_adult==1 & total_hh_member==1
replace aes2=1+(total_adult-1)*0.7+total0_17*0.5 if total_hh_member>1 
label var aes2 "Adult equivalence scale - OECD old"

***

save "$data\2.Processed\2016_hh_individual.dta", replace

*--------------------------------HH MODULE G1-----------------------------------
//HH Module G1 is about food consumption of HH over past one week

***Processing the HH Module G before merging since the dataset has a long format
use "$data1\hh_mod_g1_16.dta",clear

**Bringing the information about the number of individuals and adult equalized scale in the
*household to the Module G. This information is particularly important for this
*food consumption and expenditure module (Module G) to calculate per person food expenditure.
*I also brought variables related to the period and date of the survey that was carried out.
*This information will be used below to calculate inflated food consumption for HHs.

preserve
use "$data\2.Processed\2016_hh_individual.dta", clear
keep y3_hhid panelweight_2016 total_hh_member aes1 aes2 interviewdate_v1 interviewdate_v2
duplicates drop y3_hhid panelweight_2016, force
tempfile hh_member_number  
save "`hh_member_number'", replace
restore

merge m:1 y3_hhid using "`hh_member_number'"
drop if _merge==2
tab _merge
drop _merge

**If a food item is not consumed in HH, it was coded as "." in the data that is
*treated as a missing value and causing a problem for the analysis. For this reason,
*food consumption and expenditure values "." were converted into 0 meaning not being
*consumed in HH.
recode hh_g03a .=0
recode hh_g05 .=0

**Generating main food gategories to label sub-category food items
gen cereals=1 if hh_g02>=101 & hh_g02<=117
replace cereals=0 if cereals!=1 & hh_g02!=.
label var cereals "Cereals, Grains and Cereal Products Consumed in HH"

gen roots=1 if hh_g02>=201 & hh_g02<=209
replace roots=0 if roots!=1 & hh_g02!=.
label var roots "Roots, Tubers, and Plantains Consumed in HH"

gen nuts=1 if (hh_g02>=301 & hh_g02<=313)
replace nuts=0 if nuts!=1 & hh_g02!=.
label var nuts "Nuts and Pulses Consumed in HH"

gen veggie=1 if hh_g02>=401 & hh_g02<=414
replace veggie=0 if veggie!=1 & hh_g02!=.
label var veggie "Vegetables Consumed in HH"

gen meat=1 if hh_g02>=501 & hh_g02<=515
replace meat=0 if meat!=1 & hh_g02!=.
label var meat "Meat, Fish and Animal products Consumed in HH"

gen fruit=1 if hh_g02>=601 & hh_g02<=610
replace fruit=0 if fruit!=1 & hh_g02!=.
label var fruit "Fruits Consumed in HH"

gen cooked=1 if hh_g02>=820 & hh_g02<=837
replace cooked=0 if cooked!=1 & hh_g02!=.
label var cooked "Cooked Foods from Vendors Consumed in HH"

gen milk=1 if hh_g02>=701 & hh_g02<=709
replace milk=0 if milk!=1 & hh_g02!=.
label var milk "Milk and Milk Products Consumed in HH"

gen sugar=1 if hh_g02>=801 & hh_g02<=804
replace sugar=0 if sugar!=1 & hh_g02!=.
label var sugar "Sugar, Fats, and Oil Consumed in HH"

gen beverage=1 if hh_g02>=901 & hh_g02<=916
replace beverage=0 if beverage!=1 & hh_g02!=.
label var beverage "Beverages Consumed in HH"

gen spice=1 if hh_g02>=810 & hh_g02<=818
replace spice=0 if spice!=1 & hh_g02!=.
label var spice "Spices & Miscellaneous Consumed in HH"

***Expenditure on each food categories
**Cereals
bys y3_hhid: egen exp_cereals = sum(hh_g05) if cereals==1
label var exp_cereals "Weekly expenditure on cereals in HH"

**Roots
bys y3_hhid: egen exp_roots = sum(hh_g05) if roots==1
label var exp_roots "Weekly expenditure on roots in HH"

**Nuts
bys y3_hhid: egen exp_nuts = sum(hh_g05) if nuts==1
label var exp_nuts "Weekly expenditure on nuts in HH"

**Veggie
bys y3_hhid: egen exp_veggie = sum(hh_g05) if veggie==1
label var exp_veggie "Weekly expenditure on veggie in HH"

**Meat
bys y3_hhid: egen exp_meat = sum(hh_g05) if meat==1
label var exp_meat "Weekly expenditure on meat in HH"

**Fruit
bys y3_hhid: egen exp_fruit = sum(hh_g05) if fruit==1
label var exp_fruit "Weekly expenditure on fruit in HH"

**Cooked
bys y3_hhid: egen exp_cooked = sum(hh_g05) if cooked==1
label var exp_cooked "Weekly expenditure on cooked in HH"

**Milk
bys y3_hhid: egen exp_milk = sum(hh_g05) if milk==1
label var exp_milk "Weekly expenditure on milk in HH"

**Sugar
bys y3_hhid: egen exp_sugar = sum(hh_g05) if sugar==1
label var exp_sugar "Weekly expenditure on sugar in HH"

**Beverage
bys y3_hhid: egen exp_beverage = sum(hh_g05) if beverage==1
label var exp_beverage "Weekly expenditure on beverage in HH"

**Spice
bys y3_hhid: egen exp_spice = sum(hh_g05) if spice==1
label var exp_spice "Weekly expenditure on spice in HH"

**Total expenditure on all food items
bys y3_hhid: egen total_exp_food = sum(hh_g05) if hh_g05!=.
label var total_exp_food "Total weekly expenditure on food in HH"

***Interview dates and visiting groups
**It is important to note that -since the questionnaire is long-the households
*were visited two times. The whole sample is splitted into A and B. HHs in group A
*were asked the HH questionnaire Module G when they were visited for the first time.
*HHs in group A were asked those questions when they visited for the second time.
*For this reason, below, I generate a new date variable from qx_type and interviewdate_v1
*and interviewdate_v2 variables.

/*gen _int_date_hhmod=interviewdate_v1 if qx_type==1
replace _int_date_hhmod=interviewdate_v2 if qx_type==2
replace _int_date_hhmod=interviewdate_v1 if _int_date_hhmod=="##N/A##" //a small number
//of hhs were visited once
label var _int_date_hhmod "The date when HHs were asked the household questionnaire"*/

*Since these dates are in yyyy-mm-dd format, I only kept the year and month information

gen interviewDate2=interviewDate
replace interviewDate2=interviewdate_v1 if interviewDate=="##N/A##"

gen int_date_hhmod = substr( interviewDate2, 1,7 ) //Now, we have the information of
//when exactly (year and month) HHs told how much money they spent on food. This info
//is important given that each month food prices can change. In order to compare
//HH expenditure with each other, I inflated the expenditures to the latest interview
//date using consumer price index.

*--------------------Malawi Monthly Consumer Price Index------------------------

***Malawi monthly consumer price index data were acquired from the IMF database,
//and converted into the stata file
*Source: https://data.imf.org/?sk=4FFB52B2-3653-409A-B471-D47B46D904B5&sId=1485878855236

merge m:1 int_date_hhmod using "$data1\additional\Malawi_CPI_IMF_April2016_April2017.dta", generate (_merge_cpi_2016)
drop if _merge_cpi_2016==2

gen malawi_cpi_Apr2017=90.3225806451613

gen inflator=malawi_cpi_Apr2017/cpi

*Inflacting total expenditure on food to April 2017-the latest time for carrying out the survey in the field.
gen aes1_total_exp_food=(total_exp_food*inflator)/aes1
label var aes1_total_exp_food "Adult equalized (aes1) inflated total expenditure on food"

gen aes2_total_exp_food=(total_exp_food*inflator)/aes2
label var aes2_total_exp_food "Adult equalized (aes2) inflated total expenditure on food"

gen pc_total_exp_food=(total_exp_food*inflator)/total_hh_member
label var pc_total_exp_food "Per capita inflated total expenditure on food"


local variables exp_*
foreach var of varlist `variables' {
gen aes1_`var'=(`var'*inflator)/aes1
gen aes2_`var'=(`var'*inflator)/aes2
gen pc_`var'=(`var'*inflator)/total_hh_member
} 

local variables aes1_exp_*
foreach var of varlist `variables' {
bys y3_hhid: egen `var'2=max(`var')
} 

local variables aes2_exp_*
foreach var of varlist `variables' {
bys y3_hhid: egen `var'2=max(`var')
} 

local variables pc_exp_*
foreach var of varlist `variables' {
bys y3_hhid: egen `var'2=max(`var')
} 



keep y3_hhid aes1_total_exp_food aes2_total_exp_food pc_total_exp_food ///
aes1_exp_cereals2 aes2_exp_cereals2 pc_exp_cereals2 aes1_exp_roots2 ///
aes2_exp_roots2 pc_exp_roots2 aes1_exp_nuts2 aes2_exp_nuts2 pc_exp_nuts2 aes1_exp_veggie2 ///
aes2_exp_veggie2 pc_exp_veggie2 aes1_exp_meat2 aes2_exp_meat2 pc_exp_meat2 ///
aes1_exp_fruit2 aes2_exp_fruit2 pc_exp_fruit2 aes1_exp_cooked2 aes2_exp_cooked2 ///
pc_exp_cooked2 aes1_exp_milk2 aes2_exp_milk2 pc_exp_milk2 aes1_exp_sugar2 ///
aes2_exp_sugar2 pc_exp_sugar2 aes1_exp_beverage2 aes2_exp_beverage2 ///
pc_exp_beverage2 aes1_exp_spice2 aes2_exp_spice2 pc_exp_spice2

duplicates drop y3_hhid aes1_total_exp_food aes2_total_exp_food pc_total_exp_food ///
aes1_exp_cereals2 aes2_exp_cereals2 pc_exp_cereals2 aes1_exp_roots2 ///
aes2_exp_roots2 pc_exp_roots2 aes1_exp_nuts2 aes2_exp_nuts2 pc_exp_nuts2 aes1_exp_veggie2 ///
aes2_exp_veggie2 pc_exp_veggie2 aes1_exp_meat2 aes2_exp_meat2 pc_exp_meat2 ///
aes1_exp_fruit2 aes2_exp_fruit2 pc_exp_fruit2 aes1_exp_cooked2 aes2_exp_cooked2 ///
pc_exp_cooked2 aes1_exp_milk2 aes2_exp_milk2 pc_exp_milk2 aes1_exp_sugar2 ///
aes2_exp_sugar2 pc_exp_sugar2 aes1_exp_beverage2 aes2_exp_beverage2 ///
pc_exp_beverage2 aes1_exp_spice2 aes2_exp_spice2 pc_exp_spice2, force

save "$data\2.Processed\hh_mod_g1_16_processed.dta", replace


***Merging the processed HH Module G1

use "$data\2.Processed\2016_hh_individual.dta", clear

merge m:1 y3_hhid using "$data\2.Processed\hh_mod_g1_16_processed.dta", generate (_merge_hhg1_2016)
drop if _merge_hhg1_2016==2

save "$data\2.Processed\2016_hh_individual.dta", replace

*--------------------------------HH MODULE G2-----------------------------------
//HH Module G2 is about the number of days each food is consumed by HHs
*
merge m:1 y3_hhid using "$data1\hh_mod_g2_16.dta", generate (_merge_hhg2_2016)
drop if _merge_hhg2_2016==2

***Food Consumption Score
**Since there are lots of food consumption variables, I generated an aggregated food consumption
*score for each HH based on the score established by WFP.
*Source:https://inddex.nutrition.tufts.edu/data4diets/indicator/food-consumption-score-fcs

gen staples = cond(missing(hh_g08a, hh_g08b), max(hh_g08a, hh_g08b), (hh_g08a + hh_g08b) / 2) 

gen w_staples=2
gen w_pulses=3
gen w_vegetables=1
gen w_fruit=1
gen w_meat_fish=4
gen w_milk=4
gen w_sugar = 0.5
gen w_oil = 0.5

gen food_consumption_score= w_staples*staples+w_pulses*hh_g08c+hh_g08d+hh_g08f ///
+w_meat_fish*hh_g08e+w_milk*hh_g08g+w_sugar*hh_g08i+w_oil*hh_g08h

gen food_score_ctg=0 if food_consumption_score<=21
replace food_score_ctg=1 if food_consumption_score>21 & food_consumption_score<=35
replace food_score_ctg=2 if food_consumption_score>35 & food_consumption_score!=.
label var food_score_ctg "Food consumption score categories"
label define food_score_ctg_val 0"Poor food consumption" 1"Borderline food consumption" 2"Acceptable food consumption"
label val food_score_ctg food_score_ctg_val


*--------------------------------HH MODULE H-----------------------------------
//HH Module H is about food security
merge m:1 y3_hhid using "$data1\hh_mod_h_16.dta", generate (_merge_hhh_2016)
drop if _merge_hhh_2016==2

***In the literature, reduced coping index is frequently used to understand the coping
**mechanisms households adjust to deal food insecurity. This reduced coping strategy index
*was built below in line with the literature.
*Source1:https://documents.wfp.org/stellent/groups/public/documents/manual_guide_proced/wfp211058.pdf
*Source2:https://www.fantaproject.org/sites/default/files/resources/HFCIS-report-Dec2015.pdf

*These are the weights specified in the literature to give importance on coping
*strategies.
gen w_less_expensive=1
gen w_borrow_food=2
gen w_portion_food=1
gen w_food_child=3
gen w_reduce_meals=1

*Constructing an aggregated reduced consumption coping score
gen r_csi=w_less_expensive*hh_h02a+w_portion_food*hh_h02b+w_reduce_meals*hh_h02c ///
+ w_food_child*hh_h02d + w_borrow_food*hh_h02e

*Depending on the level of an aggregated score, thresholds are set to determine
*sub-categories. These thresholds were assigned in line with the literature mentioned above.
gen rcsi_food_secure=1 if r_csi>=0 & r_csi<=4
replace rcsi_food_secure=0 if r_csi>4 & r_csi!=.

gen rcsi_mod_insecure=1 if r_csi>=5 & r_csi<=10
replace rcsi_mod_insecure=0 if (r_csi<5 | r_csi>10) & r_csi!=.

gen rcsi_sev_insecure=1 if r_csi>=11 & r_csi!=.
replace rcsi_sev_insecure=0 if r_csi<11 & r_csi!=.

save "$data\2.Processed\2016_hh_individual.dta", replace

*--------------------------------HH MODULE I.1-----------------------------------
*One week recall expenditures on non-food items
use "$data1\hh_mod_i1_16.dta", clear

preserve
use "$data\2.Processed\2016_hh_individual.dta", clear
keep y3_hhid panelweight_2016 total_hh_member aes1 aes2 interviewdate_v1 interviewdate_v2
duplicates drop y3_hhid panelweight_2016, force
tempfile hh_member_number  
save "`hh_member_number'", replace
restore

merge m:1 y3_hhid using "`hh_member_number'", generate(_merge_hh_member)
drop if _merge_hh_member==2

//In the data missing values mean not spending money on certain non-food items.
//For this reason, missing values were converted to 0, as these missing values
//may cause a problem while transfering the data to Python.
recode hh_i03 .=0


**Total expenditure on non-food items (one-week recall)
bys y3_hhid: egen nonfood_exp_weekly = sum(hh_i03)
**Assuming that this expenditure occurs every week for each HH to get the monthly
*expenditure to inflate the expenditure level based on monthly CPI and interview
*months reported.
gen nonfood_exp_monthly_i1 = nonfood_exp_weekly*4

***Interview dates and visiting groups
**It is important to note that -since the questionnaire is long-the households
*were visited two times. The whole sample is splitted into A and B. HHs in group A
*were asked the HH questionnaire Module I when they were visited for the first time.
*HHs in group A were asked those questions when they visited for the second time.
*For this reason, below, I generate a new date variable from qx_type and interviewdate_v1
*and interviewdate_v2 variables.

gen _int_date_hhmod=interviewdate_v1 if qx_type==1
replace _int_date_hhmod=interviewdate_v2 if qx_type==2
replace _int_date_hhmod=interviewdate_v2 if _int_date_hhmod==""
replace  _int_date_hhmod=interviewdate_v1 if _int_date_hhmod=="##N/A##" //a small number
//of hhs were visited once
label var _int_date_hhmod "The date when HHs were asked the household questionnaire"

*Since these dates are in yyyy-mm-dd format, I only kept the year and month information
gen int_date_hhmod = substr( _int_date_hhmod, 1,7 ) 

*--------------------Malawi Monthly Consumer Price Index------------------------

***Malawi monthly consumer price index data were acquired from the IMF database,
//and converted into the stata file
*Source: https://data.imf.org/?sk=4FFB52B2-3653-409A-B471-D47B46D904B5&sId=1485878855236

merge m:1 int_date_hhmod using "$data1\additional\Malawi_CPI_IMF_April2016_April2017.dta", generate (_merge_cpi_2016)
drop if _merge_cpi_2016==2

gen malawi_cpi_Apr2017=90.3225806451613

gen inflator=malawi_cpi_Apr2017/cpi

gen aes1_total_exp_non_food_i1=(nonfood_exp_monthly_i1*inflator)/aes1
label var aes1_total_exp_non_food_i1 "AES1 inflated total expenditure on non-food(I1)"

gen aes2_total_exp_non_food_i1 =(nonfood_exp_monthly_i1*inflator)/aes2
label var aes2_total_exp_non_food_i1  "AES1 inflated total expenditure on non-food(I1)"

gen pc_total_exp_non_food_i1 =(nonfood_exp_monthly_i1*inflator)/total_hh_member
label var pc_total_exp_non_food_i1 "Per capita inflated total expenditure on non-food(I1)"

drop qx_type interview_status hh_i01 hh_i02 hh_i03 panelweight_2016 interviewdate_v1 ///
interviewdate_v2 total_hh_member aes1 aes2 _merge_hh_member _int_date_hhmod ///
int_date_hhmod cpi _merge_cpi_2016 malawi_cpi_Apr2017 inflator

duplicates drop y3_hhid nonfood_exp_weekly nonfood_exp_monthly_i1 aes1_total_exp_non_food_i1 aes2_total_exp_non_food_i1 pc_total_exp_non_food_i1, force

save "$data\2.Processed\hh_mod_i1_16_processed.dta", replace

use "$data\2.Processed\2016_hh_individual.dta", clear

merge m:1 y3_hhid using "$data\2.Processed\hh_mod_i1_16_processed.dta", generate (_merge_hhi1_2016)
drop if _merge_hhi1_2016==2

save "$data\2.Processed\2016_hh_individual.dta", replace

*--------------------------------HH MODULE I.2-----------------------------------
//This HH module I2 is about one month recall expenditures on non-food items
use "$data1\hh_mod_i2_16.dta", clear

bys y3_hhid: egen nonfood_exp_monthly_i2 = sum(hh_i06)

preserve
use "$data\2.Processed\2016_hh_individual.dta", clear
keep y3_hhid panelweight_2016 total_hh_member aes1 aes2 interviewdate_v1 interviewdate_v2
duplicates drop y3_hhid panelweight_2016, force
tempfile hh_member_number  
save "`hh_member_number'", replace
restore

merge m:1 y3_hhid using "`hh_member_number'", generate(_merge_hh_member)
drop if _merge_hh_member==2


recode hh_i06 .=0

gen _int_date_hhmod=interviewdate_v1 if qx_type==1
replace _int_date_hhmod=interviewdate_v2 if qx_type==2
replace _int_date_hhmod=interviewdate_v2 if _int_date_hhmod=="" //a small number
//of hhs were visited once
replace  _int_date_hhmod=interviewdate_v1 if _int_date_hhmod=="##N/A##" //a small number
//of hhs were visited once
label var _int_date_hhmod "The date when HHs were asked the household questionnaire"

*Since these dates are in yyyy-mm-dd format, I only kept the year and month information
gen int_date_hhmod = substr( _int_date_hhmod, 1,7 ) 

*--------------------Malawi Monthly Consumer Price Index------------------------

***Malawi monthly consumer price index data were acquired from the IMF database,
//and converted into the stata file
*Source: https://data.imf.org/?sk=4FFB52B2-3653-409A-B471-D47B46D904B5&sId=1485878855236

merge m:1 int_date_hhmod using "$data1\additional\Malawi_CPI_IMF_April2016_April2017.dta", generate (_merge_cpi_2016)
drop if _merge_cpi_2016==2

gen malawi_cpi_Apr2017=90.3225806451613

gen inflator=malawi_cpi_Apr2017/cpi

gen aes1_total_exp_non_food_i2=(nonfood_exp_monthly_i2*inflator)/aes1
label var aes1_total_exp_non_food_i2 "AES1 inflated total expenditure on non-food(I2)"

gen aes2_total_exp_non_food_i2 =(nonfood_exp_monthly_i2*inflator)/aes2
label var aes2_total_exp_non_food_i2  "AES1 inflated total expenditure on non-food(I2)"

gen pc_total_exp_non_food_i2 =(nonfood_exp_monthly_i2*inflator)/total_hh_member
label var pc_total_exp_non_food_i2 "Per capita inflated total expenditure on non-food(I2)"


drop qx_type interview_status hh_i04 hh_i05 hh_i06 nonfood_exp_monthly_i2 panelweight_2016 interviewdate_v1 ///
interviewdate_v2 total_hh_member aes1 aes2 _merge_hh_member _int_date_hhmod ///
int_date_hhmod cpi _merge_cpi_2016 malawi_cpi_Apr2017 inflator

duplicates drop y3_hhid aes1_total_exp_non_food_i2 aes2_total_exp_non_food_i2 pc_total_exp_non_food_i2, force

save "$data\2.Processed\hh_mod_i2_16_processed.dta", replace

use "$data\2.Processed\2016_hh_individual.dta", clear

merge m:1 y3_hhid using "$data\2.Processed\hh_mod_i2_16_processed.dta", generate (_merge_hhi2_2016)
drop if _merge_hhi2_2016==2

save "$data\2.Processed\2016_hh_individual.dta", replace

*--------------------------------HH MODULE J-----------------------------------
//This HH module H includes one month recall expenditures on non-food items
use "$data1\hh_mod_j_16.dta", clear

bys y3_hhid: egen nonfood_exp_3month_j = sum(hh_j03)

preserve
use "$data\2.Processed\2016_hh_individual.dta", clear
keep y3_hhid panelweight_2016 total_hh_member aes1 aes2 interviewdate_v1 interviewdate_v2
duplicates drop y3_hhid panelweight_2016, force
tempfile hh_member_number  
save "`hh_member_number'", replace
restore

merge m:1 y3_hhid using "`hh_member_number'", generate(_merge_hh_member)
drop if _merge_hh_member==2


recode hh_j03 .=0

gen _int_date_hhmod=interviewdate_v1 if qx_type==1
replace _int_date_hhmod=interviewdate_v2 if qx_type==2
replace _int_date_hhmod=interviewdate_v2 if _int_date_hhmod=="" //a small number
//of hhs were visited once
replace  _int_date_hhmod=interviewdate_v1 if _int_date_hhmod=="##N/A##" //a small number
//of hhs were visited once
label var _int_date_hhmod "The date when HHs were asked the household questionnaire"

*Since these dates are in yyyy-mm-dd format, I only kept the year and month information
gen int_date_hhmod = substr( _int_date_hhmod, 1,7 ) 

gen nonfood_exp_monthly_j= nonfood_exp_3month_j / 3

*--------------------Malawi Monthly Consumer Price Index------------------------

***Malawi monthly consumer price index data were acquired from the IMF database,
//and converted into the stata file
*Source: https://data.imf.org/?sk=4FFB52B2-3653-409A-B471-D47B46D904B5&sId=1485878855236

merge m:1 int_date_hhmod using "$data1\additional\Malawi_CPI_IMF_April2016_April2017.dta", generate (_merge_cpi_2016)
drop if _merge_cpi_2016==2

gen malawi_cpi_Apr2017=90.3225806451613

gen inflator=malawi_cpi_Apr2017/cpi

gen aes1_total_exp_non_food_j=(nonfood_exp_monthly_j*inflator)/aes1
label var aes1_total_exp_non_food_j "AES1 inflated total expenditure on non-food(J)"

gen aes2_total_exp_non_food_j =(nonfood_exp_monthly_j*inflator)/aes2
label var aes2_total_exp_non_food_j  "AES2 inflated total expenditure on non-food(J)"

gen pc_total_exp_non_food_j =(nonfood_exp_monthly_j*inflator)/total_hh_member
label var pc_total_exp_non_food_j "Per capita inflated total expenditure on non-food(J)"

drop qx_type interview_status hh_j01 hh_j02 hh_j03 hh_j_check panelweight_2016 ///
interviewdate_v1 interviewdate_v2 total_hh_member aes1 aes2 _merge_hh_member ///
_int_date_hhmod int_date_hhmod cpi _merge_cpi_2016 malawi_cpi_Apr2017 inflator

duplicates drop y3_hhid nonfood_exp_3month_j nonfood_exp_monthly_j ///
 aes1_total_exp_non_food_j aes2_total_exp_non_food_j pc_total_exp_non_food_j, force

save "$data\2.Processed\hh_mod_j_16_processed.dta", replace

use "$data\2.Processed\2016_hh_individual.dta", clear
 
merge m:1 y3_hhid using "$data\2.Processed\hh_mod_j_16_processed.dta", generate (_merge_hhj_2016)
drop if _merge_hhj_2016==2

save "$data\2.Processed\2016_hh_individual.dta", replace

*--------------------------------HH MODULE K-----------------------------------
//This module involves informaton about mon-food expenditures over past 12 months
use "$data1\hh_mod_k1_16.dta", clear

bys y3_hhid: egen nonfood_exp_12month_k = sum(hh_k03)

preserve
use "$data\2.Processed\2016_hh_individual.dta", clear
keep y3_hhid panelweight_2016 total_hh_member aes1 aes2 interviewdate_v1 interviewdate_v2
duplicates drop y3_hhid panelweight_2016, force
tempfile hh_member_number  
save "`hh_member_number'", replace
restore

merge m:1 y3_hhid using "`hh_member_number'", generate(_merge_hh_member)
drop if _merge_hh_member==2

recode hh_k03 .=0

gen nonfood_exp_monthly_k=nonfood_exp_12month_k/12

gen _int_date_hhmod=interviewdate_v1 if qx_type==1
replace _int_date_hhmod=interviewdate_v2 if qx_type==2
replace _int_date_hhmod=interviewdate_v2 if _int_date_hhmod=="" //a small number
//of hhs were visited once
replace  _int_date_hhmod=interviewdate_v1 if _int_date_hhmod=="##N/A##" //a small number
//of hhs were visited once
label var _int_date_hhmod "The date when HHs were asked the household questionnaire"

*Since these dates are in yyyy-mm-dd format, I only kept the year and month information
gen int_date_hhmod = substr( _int_date_hhmod, 1,7 ) 

*--------------------Malawi Monthly Consumer Price Index------------------------

***Malawi monthly consumer price index data were acquired from the IMF database,
//and converted into the stata file
*Source: https://data.imf.org/?sk=4FFB52B2-3653-409A-B471-D47B46D904B5&sId=1485878855236

merge m:1 int_date_hhmod using "$data1\additional\Malawi_CPI_IMF_April2016_April2017.dta", generate (_merge_cpi_2016)
drop if _merge_cpi_2016==2

gen malawi_cpi_Apr2017=90.3225806451613

gen inflator=malawi_cpi_Apr2017/cpi

gen aes1_total_exp_non_food_k=(nonfood_exp_monthly_k*inflator)/aes1
label var aes1_total_exp_non_food_k "AES1 inflated total expenditure on non-food(K)"

gen aes2_total_exp_non_food_k =(nonfood_exp_monthly_k*inflator)/aes2
label var aes2_total_exp_non_food_k  "AES2 inflated total expenditure on non-food(K)"

gen pc_total_exp_non_food_k =(nonfood_exp_monthly_k*inflator)/total_hh_member
label var pc_total_exp_non_food_k "Per capita inflated total expenditure on non-food(K)"

drop qx_type interview_status hh_k01 hh_k02 hh_k03 panelweight_2016 ///
interviewdate_v1 interviewdate_v2 total_hh_member aes1 aes2 _merge_hh_member ///
nonfood_exp_monthly_k _int_date_hhmod int_date_hhmod cpi _merge_cpi_2016 ///
malawi_cpi_Apr2017 inflator

duplicates drop y3_hhid nonfood_exp_12month_k aes1_total_exp_non_food_k ///
aes2_total_exp_non_food_k pc_total_exp_non_food_k, force


save "$data\2.Processed\hh_mod_k_16_processed.dta", replace

use "$data\2.Processed\2016_hh_individual.dta", clear
 
merge m:1 y3_hhid using "$data\2.Processed\hh_mod_k_16_processed.dta", generate (_merge_hhk_2016)
drop if _merge_hhk_2016==2

save "$data\2.Processed\2016_hh_individual.dta", replace

*--------------------------------HH MODULE L-----------------------------------
//This module involve information about durable goods (i.e. HH assets)
use "$data1\hh_mod_l_16.dta", clear

*Total market values of assets owned by HHs
bys y3_hhid: egen asset_sale_value = sum(hh_l05)

*In the later stage of the analysis, principal components of assets will be generated
*along with wealth quintiles. For this reason, dummy variables of each HH asset was created below.
preserve
generate item_name=hh_l02 if hh_l02!=.
drop qx_type interview_status hh_l02 hh_l03 hh_l04 hh_l05 hh_l06 hh_l07 hh_l05 hh_l06 hh_l07 asset_sale_value
reshape wide hh_l01, i(y3_hhid) j(item_name) 
tempfile asset_item  
save "`asset_item'", replace
restore

merge m:1 y3_hhid using "`asset_item'", generate(_merge_asset_item)
drop if _merge_asset_item==2

drop qx_type interview_status hh_l01 hh_l02 hh_l03 hh_l04 hh_l05 hh_l06 hh_l07 _merge_asset_item

duplicates drop y3_hhid asset_sale_value hh_l01501 hh_l01502 hh_l01503 hh_l01504 ///
hh_l01505 hh_l01506 hh_l01507 hh_l01508 hh_l01509 hh_l01510 hh_l01511 hh_l01512 ///
hh_l01513 hh_l01514 hh_l01515 hh_l01516 hh_l01517 hh_l01518 hh_l01519 hh_l01520 ///
hh_l01521 hh_l01522 hh_l01523 hh_l01524 hh_l01525 hh_l01526 hh_l01527 hh_l01528 ///
hh_l01529 hh_l01530 hh_l01531 hh_l01532 hh_l015081, force

local variables hh_l01501 hh_l01502 hh_l01503 hh_l01504 ///
hh_l01505 hh_l01506 hh_l01507 hh_l01508 hh_l01509 hh_l01510 hh_l01511 hh_l01512 ///
hh_l01513 hh_l01514 hh_l01515 hh_l01516 hh_l01517 hh_l01518 hh_l01519 hh_l01520 ///
hh_l01521 hh_l01522 hh_l01523 hh_l01524 hh_l01525 hh_l01526 hh_l01527 hh_l01528 ///
hh_l01529 hh_l01530 hh_l01531 hh_l01532 hh_l015081
foreach var of varlist `variables' { 
recode `var' 2=0
}	


save "$data\2.Processed\hh_mod_l_16_processed.dta", replace

use "$data\2.Processed\2016_hh_individual.dta", clear
 
merge m:1 y3_hhid using "$data\2.Processed\hh_mod_l_16_processed.dta", generate (_merge_hhl_2016)
drop if _merge_hhl_2016==2

save "$data\2.Processed\2016_hh_individual.dta", replace

*--------------------------------HH MODULE N1-----------------------------------
//This module HH N1 involves the main information about household enterprises.
merge m:1 y3_hhid using "$data1\hh_mod_n1_16.dta", generate (_merge_hhn1_2016)
drop if _merge_hhn1_2016==2

save "$data\2.Processed\2016_hh_individual.dta", replace

*--------------------------------HH MODULE P------------------------------------
//This module is about other income sources of HHs
use "$data1\hh_mod_p_16.dta", clear

***Total income from transfers and gifts (12 months)
egen other_income_p03=rowtotal(hh_p03a hh_p03b hh_p03c)

***HH total income from transfers and gifts
bys y3_hhid: egen other_income_p03_12month = sum(other_income_p03)

***HH total income from other income sources excluding transfers and gifts
bys y3_hhid: egen other_income_p02_12month = sum(hh_p02)

***HH total income from all other income sources
egen other_income_12month=rowtotal(other_income_p03_12month other_income_p02_12month)

***HH monthly total income from all other income sources
gen other_income_monthly=other_income_12month/12

drop qx_type interview_status hh_p0a hh_p01 hh_p01_oth hh_p02 hh_p03a hh_p03b ///
hh_p03c hh_p03_1 hh_p03_2 hh_p03_2oth hh_p03_3 hh_p04a hh_p04b ///
other_income_p03 other_income_p03_12month other_income_p02_12month other_income_12month

duplicates drop other_income_monthly y3_hhid, force

save "$data\2.Processed\hh_mod_p_16_processed.dta", replace

use "$data\2.Processed\2016_hh_individual.dta", clear
 
merge m:1 y3_hhid using "$data\2.Processed\hh_mod_p_16_processed.dta", generate (_merge_hhp_2016)
drop if _merge_hhp_2016==2

save "$data\2.Processed\2016_hh_individual.dta", replace

*--------------------------------HH MODULE R-----------------------------------
***This module involves social safety nets
use "$data\2.Processed\2016_hh_individual.dta", clear

***Total cash and in-kind assistance received in the last 12 months
preserve
use "$data1\hh_mod_r_16.dta", clear
bys y3_hhid: egen cash_assistance_12month = sum(hh_r02a)
bys y3_hhid: egen inkind_assistance_12month = sum(hh_r02b)
keep y3_hhid cash_assistance_12month inkind_assistance_12month
duplicates drop y3_hhid cash_assistance_12month inkind_assistance_12month, force
tempfile assistance_amount
save "`assistance_amount'", replace
restore

merge m:1 y3_hhid using "`assistance_amount'", generate (_merge_asst)
drop if _merge_asst==2

***HH members benefiting from the school feeding programme in Malawi
preserve
use "$data1\hh_mod_r_16.dta", clear
drop if hh_r0a!=105
keep y3_hhid hh_r04a hh_r04b hh_r04c hh_r04d hh_r04e
drop if hh_r04a==. & hh_r04b==. & hh_r04c==. & hh_r04d==. & hh_r04e==.
reshape long hh_r04, i(y3_hhid) j(hh_mmb a b c d e)
duplicates drop y3_hhid hh_r04, force
rename hh_r04 food_feed_hhline
reshape wide food_feed_hhline, i(y3_hhid) j(hh_mmb) string
tempfile food_feed_hh_line
save "`food_feed_hh_line'", replace
restore

merge m:1 y3_hhid using "`food_feed_hh_line'", generate (_merge_food_feed)
drop if _merge_food_feed==2

gen school_feed=1 if id_code==food_feed_hhlinea | id_code==food_feed_hhlineb | ///
id_code==food_feed_hhlinec | id_code==food_feed_hhlined | id_code==food_feed_hhlinee

save "$data\2.Processed\2016_hh_individual.dta", replace

*--------------------------------HH MODULE T-----------------------------------
//This module involves information about the subjective assessment of well-being
merge m:1 y3_hhid using "$data1\hh_mod_t_16.dta", generate (_merge_hht_2016)
drop if _merge_hht_2016==2

save "$data\2.Processed\2016_hh_individual.dta", replace

*--------------------------------HH MODULE U-----------------------------------
//This module involves shocks and coping strategies
use "$data\2.Processed\2016_hh_individual.dta", clear

***We are holding shocks that only affected households most severely and merging
**them with the individual level data.
preserve
use "$data1\hh_mod_u_16.dta", clear
keep if hh_u02==1
duplicates drop hh_u02 y3_hhid, force
drop hh_u04b hh_u04c hh_u02 hh_u01 qx_type interview_status
rename hh_u0a hh_u0a_most_severe
tempfile shocks
save "`shocks'", replace
restore

merge m:1 y3_hhid using "`shocks'", generate(_merge_shocks)
drop if _merge_shocks==2

save "$data\2.Processed\2016_hh_individual.dta", replace


*-----------------------------COMMUNITY QUESTIONNAIRES-------------------------*

*-----------------------COMM MODULE CC-----------------------------------------*
//This community module CC involves basic information about communities
use "$data1\com_cc_16.dta", clear
///There is one enumerator mistake regarding ea_id-one community is repeating two
///times in the row. For this reason, I dropped this one duplication from the data.
duplicates drop ea_id, force

***Three religions, lanugages and marriage typres in the communities were asked.
**Here, I am extracting the most frequently observed religion, language and marriage
*type in the community based on the number of households reported in the survey.
egen max_religion_hh=rowmax(com_cc04b com_cc04d com_cc04f)
egen max_language=rowmax(com_cc05b com_cc05d com_cc05f)
egen max_marriage=rowmax(com_cc07b com_cc07d com_cc07f)

rename com_cc04a religion1
rename com_cc04c religion2
rename com_cc04e religion3

rename com_cc05a language1
rename com_cc05c language2
rename com_cc05e language3

rename com_cc07a marriage1
rename com_cc07c marriage2
rename com_cc07e marriage3


rename com_cc04b number_hh_religion1
rename com_cc04d number_hh_religion2
rename com_cc04f number_hh_religion3

rename com_cc05b number_hh_language1
rename com_cc05d number_hh_language2
rename com_cc05f number_hh_language3

rename com_cc07b number_hh_marriage1
rename com_cc07d number_hh_marriage2
rename com_cc07f number_hh_marriage3

***Reshape the data format from wide to long
reshape long religion language marriage, i(ea_id) j(number)

gen match_religion=1 if number_hh_religion1==max_religion_hh
replace match_religion=2 if number_hh_religion2==max_religion_hh
replace match_religion=3 if number_hh_religion3==max_religion_hh

gen match_language=1 if number_hh_language1==max_language
replace match_language=2 if number_hh_language2==max_language
replace match_language=3 if number_hh_language3==max_language

gen match_marriage=1 if number_hh_marriage1==max_marriage
replace match_marriage=2 if number_hh_marriage2==max_marriage
replace match_marriage=3 if number_hh_marriage3==max_marriage

gen _freq_religion=.
replace _freq_religion=religion if number==match_religion

gen _freq_language=.
replace _freq_language=language if number==match_language

gen _freq_marriage=.
replace _freq_marriage=marriage if number==match_marriage

bysort ea_id: egen freq_religion=max(_freq_religion)
label define freq_religion_val 1 "Traditional" 2 "Islam" 3 "Christian" 4 "Other religion" 5 "None"
label val freq_religion freq_religion_val
bysort ea_id: egen freq_language=max(_freq_language)
bysort ea_id: egen freq_marriage=max(_freq_marriage)
label define freq_marriage_val 1 "Matrilineal and neolocal" 2 "Matrilineal and matrilocal" 3 "Matrilineal and patrilocal" 4 "Patrilineal and neolocal" 5 "Patrilineal and patrilocal"
label val freq_marriage freq_marriage_val



keep ea_id com_cc01 com_cc02 com_cc03 freq_religion freq_language ///
freq_marriage com_cc06 com_cc08 com_cc09 com_cc10 com_cc11 com_cc12 com_cc13 com_cc14

duplicates drop ea_id com_cc01 com_cc02 com_cc03 freq_religion freq_language ///
freq_marriage com_cc06 com_cc08 com_cc09 com_cc10 com_cc11 com_cc12 com_cc13 com_cc14, force

save "$data\2.Processed\com_mod_cc_16_processed.dta", replace

use "$data\2.Processed\2016_hh_individual.dta", clear

merge m:1 ea_id using "$data\2.Processed\com_mod_cc_16_processed.dta", generate (_merge_com_cc_2016)
drop if _merge_com_cc_2016==2

save "$data\2.Processed\2016_hh_individual.dta", replace

*-----------------------COMM MODULE CD-----------------------------------------*
//This module is about access to basic services in the communities.
use "$data1\com_cd_16.dta", clear

***Distances to different services such as banks, postal offices and schools
**are expressed in miles, KMs and meters in the communities. For this reason, each
*distance variable was converted into meters. If there is that service in the communities
*then distance to that service is taken as 0. If there is no that service in the communities,
*then distance is given in the data. These distances are converted in meters below.

*the nearest asphalt road
gen com_cd02a_meter=.
replace com_cd02a_meter=com_cd02a*1000 if com_cd02b==2
replace com_cd02a_meter=com_cd02a*1609.344 if com_cd02b==3
replace com_cd02a_meter=com_cd02a if com_cd02b==1

*the nearest bus stage
gen com_cd07a_meter=.
replace com_cd07a_meter=0 if com_cd06==1 | com_cd07a==0
replace com_cd07a_meter=com_cd07a*1000 if com_cd07b==2
replace com_cd07a_meter=com_cd07a*1609.344 if com_cd07b==3
replace com_cd07a_meter=com_cd07a if com_cd07b==1

/*
gen com_cd08a_minute=.
replace com_cd08a_minute=com_cd08a if com_cd08b==1 | com_cd08a==0
replace com_cd08a_minute=com_cd08a*60 if com_cd08b==2
replace com_cd08a_minute=com_cd08a*60*24 if com_cd08b==3
*/

*the nearest district basma
gen com_cd10a_meter=.
replace com_cd10a_meter=0 if com_cd09==1 | com_cd10a==0
replace com_cd10a_meter=com_cd10a*1000 if com_cd10b==2
replace com_cd10a_meter=com_cd10a*1609.344 if com_cd10b==3

*the nearest major urban center
gen com_cd13a_meter=.
replace com_cd13a_meter=0 if com_cd12==1 | com_cd13a==0
replace com_cd13a_meter=com_cd13a*1000 if com_cd13b==2
replace com_cd13a_meter=com_cd13a*1609.344 if com_cd13b==3

*distance to the nearest daily market
gen com_cd16_meter=.
replace com_cd16_meter=0 if com_cd15==1 | com_cd16==0
replace com_cd16_meter=com_cd16*1000 if com_cd16b==2
replace com_cd16_meter=com_cd16*1609.344 if com_cd16b==3
replace com_cd16_meter=com_cd16 if com_cd16b==1

*distance to the nearest weekly market
gen com_cd18a_meter=.
replace com_cd18a_meter=0 if com_cd17==1 | com_cd18a==0
replace com_cd18a_meter=com_cd18a*1000 if com_cd18b==2
replace com_cd18a_meter=com_cd18a*1609.344 if com_cd18b==3
replace com_cd18a_meter=com_cd18a if com_cd18b==1

*distance to the permanent ADMARC market
gen com_cd20a_meter=.
replace com_cd20a_meter=0 if com_cd19==1 | com_cd20a==0
replace com_cd20a_meter=com_cd20a*1000 if com_cd20b==2
replace com_cd20a_meter=com_cd20a*1609.344 if com_cd20b==3
replace com_cd20a_meter=com_cd20a if com_cd20b==1

*distance to the nearest post office
gen com_cd22a_meter=.
replace com_cd22a_meter=0 if com_cd21==1 | com_cd22a==0
replace com_cd22a_meter=com_cd22a*1000 if com_cd22b==2
replace com_cd22a_meter=com_cd22a*1609.344 if com_cd22b==3
replace com_cd22a_meter=com_cd22a if com_cd22b==1

*distance to the nearest place where one can make a phone call
gen com_cd24a_meter=.
replace com_cd24a_meter=0 if com_cd23==1 | com_cd24a==0
replace com_cd24a_meter=com_cd24a*1000 if com_cd24b==2
replace com_cd24a_meter=com_cd24a*1609.344 if com_cd24b==3
replace com_cd24a_meter=com_cd24a if com_cd24b==1

*distance to the nearest government primary school
gen com_cd27a_meter=.
replace com_cd27a_meter=0 if com_cd27b==0
replace com_cd27a_meter=com_cd27a if com_cd27b==1
replace com_cd27a_meter=com_cd27a*1000 if com_cd27b==2

*distance to the nearest government secondary school
gen com_cd36a_meter=.
replace com_cd36a_meter=com_cd36a if com_cd36b==1
replace com_cd36a_meter=com_cd36a*1000 if com_cd36b==2
replace com_cd36a_meter=com_cd36a*1609.344 if com_cd36b==3

*distance to the nearest community day secondary school
gen com_cd40a_meter=.
replace com_cd40a_meter=0 if com_cd40b==0
replace com_cd40a_meter=com_cd40a if com_cd40b==1
replace com_cd40a_meter=com_cd40a*1000 if com_cd40b==2

*distance to the nearest pharmacy
gen com_cd49a_meter=.
replace com_cd49a_meter=0 if com_cd48==1 | com_cd49a==0
replace com_cd49a_meter=com_cd49a*1000 if com_cd49b==2
replace com_cd49a_meter=com_cd49a*1609.344 if com_cd49b==3
replace com_cd49a_meter=com_cd49a if com_cd49b==1

*distance to the nearest health clinic (Chipatala)
gen com_cd51a_meter=.
replace com_cd51a_meter=0 if com_cd50==1 | com_cd51a==0
replace com_cd51a_meter=com_cd51a*1000 if com_cd51b==2
replace com_cd51a_meter=com_cd51a*1609.344 if com_cd51b==3
replace com_cd51a_meter=com_cd51a if com_cd51b==1

*distance to the nearest commercial bank
gen com_cd67a_meter=.
replace com_cd67a_meter=0 if com_cd66==1 | com_cd67a==0
replace com_cd67a_meter=com_cd67a*1000 if com_cd67b==2
replace com_cd67a_meter=com_cd67a*1609.344 if com_cd67b==3
replace com_cd67a_meter=com_cd67a if com_cd67b==1

*distance to the nearest micro finance institution
gen com_cd69a_meter=.
replace com_cd69a_meter=0 if com_cd68==1 | com_cd69a==0
replace com_cd69a_meter=com_cd69a*1000 if com_cd69b==2
replace com_cd69a_meter=com_cd69a*1609.344 if com_cd69b==3
replace com_cd69a_meter=com_cd69a if com_cd69b==1

duplicates drop ea_id, force


save "$data\2.Processed\com_mod_cd_16_processed.dta", replace

use "$data\2.Processed\2016_hh_individual.dta", clear

merge m:1 ea_id using "$data\2.Processed\com_mod_cd_16_processed.dta", generate (_merge_com_cd_2016)
drop if _merge_com_cd_2016==2

save "$data\2.Processed\2016_hh_individual.dta", replace


*-----------------------COMM MODULE CE-----------------------------------------*
//This module is about economic activities in communities
use "$data\2.Processed\2016_hh_individual.dta", clear

preserve 
use "$data1\com_ce_16.dta", clear
duplicates drop ea_id, force
tempfile com_ce
save "`com_ce'", replace
restore

merge m:1 ea_id using "`com_ce'", generate(_merge_com_ce)
drop if _merge_com_ce==2

save "$data\2.Processed\2016_hh_individual.dta", replace

*-----------------------COMM MODULE CG-----------------------------------------*
///This module involves main changes experienced in communities such as droughts, 
//massive job lay-offs etc.

preserve
use "$data1\com_cg_16.dta", clear
keep ea_id com_cg35c //Keeping info only about the shock type for the analysis
drop if com_cg35c==.
duplicates drop ea_id com_cg35c, force
gen com_shocks= com_cg35c //Generate numerical variable for data shape transformation
reshape wide com_shocks, i(ea_id) j(com_cg35c) //reshape the data from long to wide
recode com_shocks2 2=1 //recode the variables to binaries
recode com_shocks3 3=1
recode com_shocks4 4=1
recode com_shocks5 5=1
recode com_shocks6 6=1
recode com_shocks6 7=1
recode com_shocks8 8=1
recode com_shocks9 9=1
recode com_shocks10 10=1
recode com_shocks12 12=1
recode com_shocks19 19=1
recode com_shocks20 20=1
tempfile shocks
save "`shocks'", replace
restore

merge m:1 ea_id using "`shocks'", generate(_merge_comm_cg_16)
drop if _merge_comm_cg_16==2


save "$data\2.Processed\com_mod_cg_16_processed.dta", replace


*------AGRICULTURE MODULE E. TIME USE & LABOR-------------------------------*
///This module is a very detailed module about agriculture. Here, I am calculating
//total hours spent on agriculture for respective HH member for rainy season
//as well as the type of labour (land preparatipon or weeding/fertilising). This variable
//is important to understand if a child in HH working in agriculture.

use "$data1\ag_mod_d_16.dta", clear

***Total hours spent in rainy season for land preparation
local x=1
while `x' < = 13  {
gen _rainy_labor_hours1_landprep_`x'=ag_d42d`x'
gen _rainy_labor_hours2_landprep_`x'=ag_d42d`x'*ag_d42c`x' if (ag_d42c`x'!=. | ag_d42c`x'!=0)
gen rainy_labor_hours_landprep`x'=_rainy_labor_hours2_landprep_`x'*ag_d42b`x' if (ag_d42b`x'!=. | ag_d42b`x'!=0)
local x = `x'+1
}

***Total hours spent in rainy season for weeding
local x=1
while `x' < = 13  {
gen _rainy_labor_hours1_weed_`x'=ag_d43d`x'
gen _rainy_labor_hours2_weed_`x'=ag_d43d`x'*ag_d43c`x' if (ag_d43c`x'!=. | ag_d43c`x'!=0)
gen rainy_labor_hours_weed`x'=_rainy_labor_hours2_weed_`x'*ag_d43b`x' if (ag_d43b`x'!=. | ag_d43b`x'!=0)
local x = `x'+1
}

***Total hours spent in rainy season for harvesting
local x=1
while `x' < = 13  {
gen _rainy_labor_hours1_harvest_`x'=ag_d44d`x'
gen _rainy_labor_hours2_harvest_`x'=ag_d44d`x'*ag_d44c`x' if (ag_d44c`x'!=. | ag_d44c`x'!=0)
gen rainy_labor_hours_harvest`x'=_rainy_labor_hours2_harvest_`x'*ag_d44b`x' if (ag_d44b`x'!=. | ag_d44b`x'!=0)
local x = `x'+1
}


***Keep only necessary variables to calculate the total hours HH members spent on agriculture activities
keep y3_hhid gardenid rainy_labor_hours_landprep1 rainy_labor_hours_landprep2 rainy_labor_hours_landprep3 ///
rainy_labor_hours_landprep4 rainy_labor_hours_landprep5 rainy_labor_hours_landprep6 rainy_labor_hours_landprep7 ///
rainy_labor_hours_landprep8 rainy_labor_hours_landprep9 rainy_labor_hours_landprep10 rainy_labor_hours_landprep11 ///
rainy_labor_hours_landprep12 rainy_labor_hours_landprep13 rainy_labor_hours_weed1 rainy_labor_hours_weed2 ///
rainy_labor_hours_weed3 rainy_labor_hours_weed4 rainy_labor_hours_weed5 rainy_labor_hours_weed6 ///
rainy_labor_hours_weed7 rainy_labor_hours_weed8 rainy_labor_hours_weed9 rainy_labor_hours_weed10 ///
rainy_labor_hours_weed11 rainy_labor_hours_weed12 rainy_labor_hours_weed13 rainy_labor_hours_harvest1 ///
rainy_labor_hours_harvest2 rainy_labor_hours_harvest3 rainy_labor_hours_harvest4 rainy_labor_hours_harvest5 ///
rainy_labor_hours_harvest6 rainy_labor_hours_harvest7 rainy_labor_hours_harvest8 rainy_labor_hours_harvest9 ///
rainy_labor_hours_harvest10 rainy_labor_hours_harvest11 rainy_labor_hours_harvest12 rainy_labor_hours_harvest13 ///
ag_d42a1 ag_d42a2 ag_d42a3 ag_d42a4 ag_d42a5 ag_d42a6 ag_d42a7 ag_d42a8 ag_d42a9 ag_d42a10 ag_d42a11 ag_d42a12 ag_d42a13 ///
ag_d43a1 ag_d43a2 ag_d43a3 ag_d43a4 ag_d43a5 ag_d43a6 ag_d43a7 ag_d43a8 ag_d43a9 ag_d43a10 ag_d43a11 ag_d43a12 ag_d43a13 ///
ag_d44a1 ag_d44a2 ag_d44a3 ag_d44a4 ag_d44a5 ag_d44a6 ag_d44a7 ag_d44a8 ag_d44a9 ag_d44a10 ag_d44a11 ag_d44a12 ag_d44a13

duplicates drop y3_hhid gardenid, force

save "$data\2.Processed\ag_mod_d_16_processed.dta", replace


use "$data\2.Processed\2016_hh_individual.dta", clear

preserve
use "$data\2.Processed\ag_mod_d_16_processed.dta", clear
reshape long ag_d42a rainy_labor_hours_landprep, i(y3_hhid gardenid) j(number1)
keep y3_hhid gardenid ag_d42a rainy_labor_hours_landprep
bysort  y3_hhid ag_d42a: egen total_rainy_labor_landprep=sum(rainy_labor_hours_landprep)
drop gardenid rainy_labor_hours_landprep
duplicates drop y3_hhid ag_d42a total_rainy_labor_landprep, force
drop if ag_d42a==. | total_rainy_labor_landprep==.
rename ag_d42a id_code
tempfile landprep_42  
save "`landprep_42'", replace
restore

merge 1:1 y3_hhid id_code using "`landprep_42'", generate (_merge_landprep_42)
drop if _merge_landprep_42==2


preserve
use "$data\2.Processed\ag_mod_d_16_processed.dta", clear
reshape long ag_d43a rainy_labor_hours_weed, i(y3_hhid gardenid) j(number2)
keep y3_hhid gardenid ag_d43a rainy_labor_hours_weed
bysort  y3_hhid ag_d43a: egen total_rainy_labor_weed=sum(rainy_labor_hours_weed)
drop gardenid rainy_labor_hours_weed
duplicates drop y3_hhid ag_d43a total_rainy_labor_weed, force
drop if ag_d43a==. | total_rainy_labor_weed==.
rename ag_d43a id_code
tempfile weed_43  
save "`weed_43'", replace
restore

merge 1:1 y3_hhid id_code using "`weed_43'", generate (_merge_weed_43)
drop if _merge_weed_43==2


preserve
use "$data\2.Processed\ag_mod_d_16_processed.dta", clear
reshape long ag_d44a rainy_labor_hours_harvest, i(y3_hhid gardenid) j(number3)
keep y3_hhid gardenid ag_d44a rainy_labor_hours_harvest
bysort  y3_hhid ag_d44a: egen total_rainy_labor_harvest=sum(rainy_labor_hours_harvest)
drop gardenid rainy_labor_hours_harvest
duplicates drop y3_hhid ag_d44a total_rainy_labor_harvest, force
drop if ag_d44a==. | total_rainy_labor_harvest==.
rename ag_d44a id_code
tempfile harvest_44 
save "`harvest_44'", replace
restore

merge 1:1 y3_hhid id_code using "`harvest_44'", generate (_merge_harvest_44)
drop if _merge_harvest_44==2


save "$data\2.Processed\2016_hh_individual.dta", replace


*--------------------------------2019 HH MODULE C-------------------------------

use "$data\2.Processed\2016_hh_individual.dta", replace

preserve
use "$data1\hh_mod_c_19.dta", clear
keep PID y4_hhid hh_c06 hh_c08 hh_c09 hh_c11 hh_c12 hh_c13 hh_c14 hh_c14_oth hh_c15 hh_c20 hh_c21
rename * *_19
rename PID_19 PID
rename y4_hhid_19 y4_hhid
tempfile hh_mod_c_19_processed  
save "`hh_mod_c_19_processed'", replace
restore

merge 1:1 PID using "`hh_mod_c_19_processed'", generate (_merge_hhc_2019)

/*


    Result                           # of obs.
    -----------------------------------------
    not matched                         5,883
        from master                     1,750  (_merge_hhc_2019==1)
        from using                      4,133  (_merge_hhc_2019==2)

    matched                            10,516  (_merge_hhc_2019==3)
    -----------------------------------------

. count if hh_c11==1 & hh_c12>=1 & hh_c12<=8
  3,481

. count if _merge_hhc_2019==1 & hh_c12>=1 & hh_c12<=8
  408

 
*/

drop if _merge_hhc_2019==2
drop if _merge_hhc_2019==1

save "$data\2.Processed\2016_hh_individual.dta", replace


*********************************************************************************************

*------------------Mother & Father Information----------------------------------

use "$data\2.Processed\2016_hh_individual.dta", clear

***Father's variables
**There is a variable about mother's and father's HH id number for each child in HH,
*we can match mother's and father's information with children. However, we need to 
*generate a temporary father data to extract his ID info and match with his children.
preserve 
gen father = 1
drop hh_b16b
rename id_code hh_b16b
keep y3_hhid hh_b16b hh_b23 hh_c05a hh_c05b hh_c06 hh_c08 hh_c09 hh_d33 hh_e06_8a 
rename * *_father
rename y3_hhid_father y3_hhid
rename hh_b16b_father hh_b16b
duplicates drop y3_hhid hh_b16b, force
tempfile father
save "`father'", replace
restore

merge m:1 y3_hhid hh_b16b using "`father'", generate (_merge_father)
drop if _merge_father==2
drop _merge_father

//order id_code gender hh_b16b hh_b04 age hh_b23_father hh_c05a_father ///
//hh_c05b_father hh_c06_father hh_c09_father hh_d33_father hh_e06_8a_father, after(y3_hhid)

***Mother's variables
preserve 
gen mother = 1
drop hh_b19b
rename id_code hh_b19b
keep y3_hhid hh_b19b hh_b23 hh_b24 hh_c05a hh_c05b hh_c06 hh_c08 hh_c09 hh_d33 hh_e06_8a 
rename * *_mother
rename y3_hhid_mother y3_hhid
rename hh_b19b_mother hh_b19b
duplicates drop y3_hhid hh_b19b, force
tempfile mother
save "`mother'", replace
restore

merge m:1 y3_hhid hh_b19b using "`mother'", generate (_merge_mother)
drop if _merge_mother==2
drop _merge_mother

//order id_code gender hh_b16b hh_b04 age hh_b19b hh_b23_mother hh_c05a_mother ///
//hh_c05b_mother hh_c06_mother hh_c09_mother hh_d33_mother hh_e06_8a_mother , after(y3_hhid)


*Create an `oldest_female` variable in HH
//new variable for analysis 2
bys y3_hhid:egen x_age_female=max(age) if gender==1
gen oldest_female_hh1=1 if age==x_age_female & age!=. & age > 17
gen oldest_female_hh_id1=id_code if oldest_female_hh1==1 & age!=. & age > 17
bys y3_hhid: egen oldest_female_hh_id=min(oldest_female_hh_id1) if age!=. & age > 17
gen oldest_female_hh=.
replace oldest_female_hh=1 if oldest_female_hh1==1 & oldest_female_hh_id==oldest_female_hh_id1 & age!=. & age > 17

*Create an `oldest male` variable in HH
//new variable for analysis 2
bys y3_hhid:egen x_age_male=max(age) if gender==0
gen oldest_male_hh1=1 if age==x_age_male & age!=. & age > 17
gen oldest_male_hh_id1=id_code if oldest_male_hh1==1 & age!=. & age > 17
bys y3_hhid: egen oldest_male_hh_id=min(oldest_male_hh_id1) if age!=. & age > 17
gen oldest_male_hh=.
replace oldest_male_hh=1 if oldest_male_hh1==1 & oldest_male_hh_id==oldest_male_hh_id1 & age!=. & age > 17


*Create variables for oldest males and females in HH
//religion
bys y3_hhid: egen oldest_female_religion=min(hh_b23*oldest_female_hh)
label var oldest_female_religion "Religion of the oldest female in HH"

bys y3_hhid: egen oldest_male_religion=min(hh_b23*oldest_male_hh)
label var oldest_male_religion "Religion of the oldest male in HH"

//order gender age oldest_female_hh hh_b23 oldest_female_religion, after(y3_hhid)

//Read and write Chichewa
bys y3_hhid: egen oldest_female_lang1=min(hh_c05a*oldest_female_hh)
label var oldest_female_lang1 "Language ability (Chichewa) of the oldest female in HH"

bys y3_hhid: egen oldest_male_lang1=min(hh_c05a*oldest_male_hh)
label var oldest_male_lang1 "Language ability (Chichewa) of the oldest male in HH"

//Read and write English
bys y3_hhid: egen oldest_female_lang2=min(hh_c05b*oldest_female_hh)
label var oldest_female_lang2 "Language level (English) of the oldest female in HH"

bys y3_hhid: egen oldest_male_lang2=min(hh_c05b*oldest_male_hh)
label var oldest_male_lang2 "Language level (English) of the oldest male in HH"

//Ever attended school
bys y3_hhid: egen oldest_female_attend=min(hh_c06*oldest_female_hh)
label var oldest_female_attend "Ever school attendance of the oldest female in HH"

bys y3_hhid: egen oldest_male_attend=min(hh_c06*oldest_male_hh)
label var oldest_male_attend "Ever school attendance of the oldest male in HH"

//Education level
bys y3_hhid: egen oldest_female_edu=min(hh_c09*oldest_female_hh)
label var oldest_female_edu "Highest education level of the oldest female in HH"

bys y3_hhid: egen oldest_male_edu=min(hh_c09*oldest_male_hh)
label var oldest_male_edu "Highest education level of the oldest male in HH"

//Chronic illness
bys y3_hhid: egen oldest_female_ill=min(hh_d33*oldest_female_hh)
label var oldest_female_ill "Chronic illness of the oldest female in HH"

bys y3_hhid: egen oldest_male_ill=min(hh_d33*oldest_male_hh)
label var oldest_male_ill "Chronic illness of the oldest male in HH"

//Economic activity
bys y3_hhid: egen oldest_female_job=min(hh_e06_8a*oldest_female_hh)
label var oldest_female_job "Economic activity of the oldest female in HH in the last 12 months"

bys y3_hhid: egen oldest_male_job=min(hh_e06_8a*oldest_male_hh)
label var oldest_male_job "Economic activity of the oldest male in HH in the last 12 months"

//Marital status
bys y3_hhid: egen oldest_female_marital=min(hh_b24*oldest_female_hh)
label var oldest_female_marital "Marital status of the oldest female in HH in the last 12 months"

//Mother's variables (and if a child does not have a mother - oldest female's variables included)
//Education level
gen mother_educ=.
replace mother_educ=hh_b21 if (hh_b19b!=. | hh_b19b!=97 | hh_b19b!=98 | hh_b19b!=99)
replace mother_educ=oldest_female_edu if (hh_b19b==. | hh_b19b==97 | hh_b19b==98 | hh_b19b==99)
replace mother_educ=hh_b21 if mother_educ==.
label var mother_educ "Highest education level of a mother including the oldest female in HH if a child does not have a mother in HH"
label define mother_educ_gr 1"NONE" 2"PSLC" 3"JCE" 4"MSCE" 5"NON-UNIV DIPLOMA" 6"UNIVER DIPLOMA, DEGREE" 7"POST-GRAD DEGREE"
label val mother_educ mother_educ_gr


//Father's variables (and if a child does not have a father - oldest male's variables included)
//Religion
//Education level
gen father_educ=.
replace father_educ=hh_b18 if (hh_b16b!=. | hh_b16b!=97 | hh_b16b!=98 | hh_b16b!=99)
replace father_educ=oldest_male_edu if (hh_b16b==. | hh_b16b==97 | hh_b16b==98 | hh_b16b==99)
replace father_educ=hh_b18 if father_educ==.
label var father_educ "Highest education level of a father including the oldest male in HH if a child does not have a father in HH"
label define father_educ_gr 1"NONE" 2"PSLC" 3"JCE" 4"MSCE" 5"NON-UNIV DIPLOMA" 6"UNIVER DIPLOMA, DEGREE" 7"POST-GRAD DEGREE"
label val father_educ father_educ_gr

//Economic activity
gen _hh_head_job=hh_e06_8a if hh_b04==1
bysort y3_hhid:egen hh_head_job=max(_hh_head_job)

gen father_job=.
replace father_job=hh_e06_8a_father if (hh_b16b!=. | hh_b16b!=97 | hh_b16b!=98 | hh_b16b!=99)
replace father_job=hh_head_job if (hh_b16b==. | hh_b16b==97 | hh_b16b==98 | hh_b16b==99)
replace father_job=6 if father_job==.
label var father_job "Economic activity of a father including the oldest male in HH if a child does not have a father in HH"
label define father_job_val 1 "WAGE EMPLOYMENT EXCLUDING GANYU" 2 "HOUSEHOLD BUSINESS (NONAG)" 3 "UNPAID HOUSEHOLD LABOR(AGRIC)" 4 "UNPAID APPRENTICESHIP" 5 "GANYU" 6 "UNEMPLOYED"
label val father_job father_job_val

save "$data\2.Processed\2016_hh_individual.dta", replace

use "$data\2.Processed\2016_hh_individual.dta", clear

***Additional data processing where necessary.
**Convert the hours for traveling to school to minutes
gen school_travel_min=hh_c19a if hh_c19b==1
replace school_travel_min=hh_c19a*60 if hh_c19b==2

***Total non-food expenditure (inflated and AES1-based)
egen total_aes1_nonfood_exp_inf=rowtotal(aes1_total_exp_non_food_i1 ///
aes1_total_exp_non_food_i2 aes1_total_exp_non_food_j aes1_total_exp_non_food_k)

***Total non-food and food expenditure
egen total_aes1_exp_inf=rowtotal(aes1_total_exp_food total_aes1_nonfood_exp_inf)

***Principal components of asset ownership

pca hh_l01501 hh_l01502 hh_l01503 hh_l01504 hh_l01505 hh_l01506 hh_l01507 ///
hh_l01508 hh_l01509 hh_l01510 hh_l01511 hh_l01512 hh_l01513 hh_l01514 ///
hh_l01515 hh_l01516 hh_l01517 hh_l01518 hh_l01519 hh_l01520 hh_l01521 ///
hh_l01522 hh_l01523 hh_l01524 hh_l01525 hh_l01526 hh_l01527 hh_l01528 ///
hh_l01529 hh_l01530 hh_l01531 hh_l01532 hh_l015081, components(1)
	
predict assetindex
	
xtile asset_q =assetindex [aw=panelweight_2016], nq(5)
tab asset_q, g (asset_q)

label var asset_q1 "Asset quintile 1 (Poorest)"
label var asset_q2 "Asset quintile 2"
label var asset_q3 "Asset quintile 3"
label var asset_q4 "Asset quintile 4"
label var asset_q5 "Asset quintile 5 (Richest)"

***AES Scaled Monthly Cash Assistance and In-Kind Assistance Calculations
gen monthly_cash_assist=cash_assistance_12month/12
gen monthly_inkind_assist=inkind_assistance_12month/12

gen aes1_monthly_cash_assist=(monthly_cash_assist)/aes1
label var aes1_monthly_cash_assist "AES1 total monthly cash assistance"

gen aes1_monthly_inkind_assist=(monthly_inkind_assist)/aes1
label var aes1_monthly_inkind_assist "AES1 total monthly inkind assistance"

egen total_assist_invalue=rowtotal(aes1_monthly_cash_assist aes1_monthly_inkind_assist)

***Recode the school feed variable
gen school_feed_beneficiary=1 if school_feed==1
replace school_feed_beneficiary=0 if school_feed_beneficiary!=1
label define school_feed_beneficiary_val 0 "No" 1 "Yes"
label val school_feed_beneficiary school_feed_beneficiary_val

***Generate a sibjective well-being assessment in comparison with neighbours and friend
gen wellbeing_better_neighbors=1 if hh_t05>hh_t06 & (hh_t05!=. & hh_t06!=.)
replace wellbeing_better_neighbors=0 if hh_t05<=hh_t06 & (hh_t05!=. & hh_t06!=.)
label define wellbeing_better_neighbors_val 0 "No" 1 "Yes"
label val wellbeing_better_neighbors wellbeing_better_neighbors_val

gen wellbeing_better_friends=1 if hh_t05>hh_t07 & (hh_t05!=. & hh_t07!=.)
replace wellbeing_better_friends=0 if hh_t05<=hh_t07 & (hh_t05!=. & hh_t07!=.)
label define wellbeing_better_friends_val 0 "No" 1 "Yes"
label val wellbeing_better_friends wellbeing_better_friends_val


save "$data\2.Processed\2016_hh_individual.dta", replace


use "$data\2.Processed\2016_hh_individual.dta", clear

**Calculate the number of phone per adult in HH
gen phone_per_adult=hh_f34/total_adult if total_adult!=0
replace phone_per_adult=hh_f34 if total_adult==0

*Recoding well-being question based on the well-being leather. Originially it was coded as continuous variable but in the questionnaire,
//it is an ordinal-categorical variable. For this reason, here I am recoding the variables
gen cat_hh_t05="1-poor" if hh_t05==1
replace cat_hh_t05="2" if hh_t05==2
replace cat_hh_t05="3" if hh_t05==3
replace cat_hh_t05="4" if hh_t05==4
replace cat_hh_t05="5" if hh_t05==5
replace cat_hh_t05="6-rich" if hh_t05==6

gen asset_q2_recoded="Yes" if asset_q2==1
replace asset_q2_recoded="No" if asset_q2==0

gen asset_q3_recoded="Yes" if asset_q3==1
replace asset_q3_recoded="No" if asset_q3==0

gen asset_q4_recoded="Yes" if asset_q4==1
replace asset_q4_recoded="No" if asset_q4==0

gen asset_q5_recoded="Yes" if asset_q5==1
replace asset_q5_recoded="No" if asset_q5==0

/*
**Calculating the number of teachers in primary schools in communitys per population in each community
gen teacher_primary_pp=com_cd28/com_cc02

**Calculating the number of students studying in primary schools in communitys per population in each community
gen student_primary_pp=com_cd29/com_cc02*/

***Generate the dropout variable
gen dropout=1 if hh_c11==1 & hh_c12>=1 & hh_c12<=8 & (hh_c11_19==2 & hh_c13_19==2) & (hh_c15>=2015 & hh_c15_19!=.)
replace dropout=0 if hh_c11==1 & hh_c12>=1 & hh_c12<=8 & (hh_c13_19==1 | hh_c11_19==1)
label var dropout "Child in primary school in 2016 dropped out of school in the 2019 round"
label define dropout_gr 1 "Yes" 0 "No"
label values dropout dropout_gr
 
keep if dropout!=.

keep y3_hhid PID dropout ea_id panelweight_2016 gender hh_c12 hh_head_gender hh_c05a hh_c05b ///
hh_c17 school_travel_min hh_c22j hh_d13 hh_d33 ///
hh_e05 hh_e06 hh_e06_1a hh_e06_1b hh_e06_1c hh_e06_2 hh_e06_3 hh_e06_4 hh_e06_5 hh_e06_6 ///
hh_f01 hh_f08 hh_f09 hh_f11 hh_f12 hh_f19 phone_per_adult hh_f36 hh_f41 hh_f44 hh_f48 ///
total0_17 num_elderly total_aes1_exp_inf food_consumption_score r_csi ///
asset_q2_recoded asset_q3_recoded asset_q4_recoded asset_q5_recoded hh_n01 hh_n02 hh_n03 hh_n04 hh_n05 hh_n06 hh_n07 hh_n08 ///
total_assist_invalue school_feed_beneficiary hh_t02 hh_t03 hh_t04 cat_hh_t05 wellbeing_better_neighbors wellbeing_better_friends ///
hh_t08 hh_u0a_most_severe mother_presence father_presence ///
com_cc02 freq_religion freq_marriage com_cc08 com_cc09 com_cc14 ///
com_cd01 com_cd16_meter com_cd18a_meter com_cd20a_meter com_cd22a_meter com_cd24a_meter com_cd25 com_cd26 com_cd27a_meter ///
com_cd28 com_cd29 com_cd30 com_cd32 com_cd35 com_cd49a_meter com_cd51a_meter com_cd55 com_cd67a_meter com_cd69a_meter ///
com_ce01a com_ce02 com_ce06 com_ce08_1 com_ce09 ///
mother_educ father_educ father_job

keep if com_cc02!=.

gen road_type=1 if (com_cd01==1 | com_cd01==2)
replace road_type=0 if (com_cd01==3 | com_cd01==4)
label var road_type "Road type in the community"
label define road_type_val 1 "Asphalt/graded graveled" 0 "Dirt road/dirt track"
label val road_type road_type_val

gen drink_water_type=1 if (hh_f36==1 | hh_f36==2 | hh_f36==3)
replace drink_water_type=2 if (hh_f36==4 | hh_f36==5 | hh_f36==6 | hh_f36==7)
replace drink_water_type=3 if hh_f36==8
replace drink_water_type=4 if hh_f36>=9 & hh_f36!=.
label var drink_water_type "Drinking water type in HH"
label define drink_water_type_val 1 "Pipe" 2 "Well" 3 "Borehole" 4 "Other"
label val drink_water_type drink_water_type_val

gen freq_marriage_type2=1 if freq_marriage==1 | freq_marriage==2 | freq_marriage==3
replace freq_marriage_type2=2 if freq_marriage==4 | freq_marriage==5
label var freq_marriage_type2 "Frequent marriage type in the community"
label define freq_marriage_type2_val 1 "Matrilineal" 2 "Patrilineal"
label val freq_marriage_type2 freq_marriage_type2_val

gen father_educ_type2=1 if father_educ==1
replace father_educ_type2=2 if father_educ==2 | father_educ==3
replace father_educ_type2=3 if father_educ==4
replace father_educ_type2=4 if father_educ>=5 & father_educ!=.
label var father_educ_type2 "Father's education level"
label define edu_val 1 "None" 2 "PSLC/JCE" 3 "MSCE" 4 "NonUni/Uni Diploma"
label val father_educ_type2 edu_val

gen mother_educ_type2=1 if mother_educ==1
replace mother_educ_type2=2 if mother_educ==2 | mother_educ==3
replace mother_educ_type2=3 if mother_educ==4
replace mother_educ_type2=4 if mother_educ>=5 & mother_educ!=.
label var mother_educ_type2 "Mother's education level"
label val mother_educ_type2 edu_val

gen hh_t08_type2=1 if hh_t08==1 | hh_t08==2
replace hh_t08_type2=2 if hh_t08==3
replace hh_t08_type2=3 if hh_t08==4 | hh_t08==5
label var hh_t08_type2 "Wellbeing assessment:current income"
label define hh_t08_type2_val 1 "Allow to save" 2 "Only just meet expenses" 3 "Not sufficient"
label val hh_t08_type2 hh_t08_type2_val

drop com_cd01 hh_f36 freq_marriage father_educ mother_educ hh_t08



save "$data\2.Processed\2016_hh_child_sample.dta", replace





