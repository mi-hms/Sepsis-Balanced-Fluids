/*************************************************************************
Project Name: Munroe - Fluid Analysis
Written by: Emily Walzl
Date: September 9th, 2026

BIG UPDATE FROM ORIGINAL PROJECT
NOW JUST FOCUSING ON BALANCED FLUID MEASURE, NO LONGER INCLUDING PORTION OF ANALYSIS RELATING TO 30 MLKG MEASURE
Aims:
Aim 1: Understand the association between receiving a majority balanced fluid overall (48 hours) and early resuscitation (6 hours) and clinical outcomes 
Aim 2: Evaluate the effect of receiving a majority balanced fluid and mortality across key subgroups based on septic shock, illness severity


Research Question:
This analysis plan builds on the balanced fluid analysis completed by Emily Walzl and team in 2025. This research plan focused the question to evaluate whether receiving a majority
balanced fluid during resuscitation is associated with mortality, both overall (48 hours) and in early resuscitation. 


Inputs:
1. Sepsis data cut (MOST RECENT DATACUT)


Primary analysis (overall resuscitation): All patients who receive at least 1L of fluid within 48 hours  

Secondary analysis (early resuscitation): All patients who receive at least 1L of fluid within 6 hours 

Subgroups: (based on a priori hypotheses and FISSH results) 
1.	Septic shock (on intravenous vasopressor within 2 hrs of presentation and first lactate >2 mmol/L, limit to lactate drawn within 6 hours) -> KEY subgroup
a.	Based on Sepsis-3 definition of septic shock: requiring vasopressors and lactate >2 
2.	Initiated on intravenous vasopressor within 2 hours of arrival  
3.	Hypotensive within 2 hours of (SBP <90, MAP <65, or on vasopressors)
4.	First lactate ≥4 mmol/L (with or without hypotension) limit to lactate drawn within 6 hours
5.	First lactate 2-4 mmol/L and no hypotension (intermediate lactate population), limit to lactate drawn within 6 hours
6.	AKI at presentation. Use initial creatinine and existing HMS measure for AKI present on presentation (use creatinine value used in mortality model)
7.	Age ≥65 years old  


Outcomes:
    Primary outcome: 30-day mortality (from date of presentation)

    Secondary outcomes:
    A.	In hospital mortality or hospice discharge (died in hospital or discharged to hospice)
    B.	Hospital length of stay
    C.	Ever renal replacement therapy (RRT): required RRT during admission

	
**************************************************************************/


/****************************************************************************************************/
/***************************************** Primary Analyses *****************************************/	
/****************************************************************************************************/
log using "[log file 1]"

/******************************** 48 Hours ********************************/
/* Primary Cohort */
import sas using "[filepath]\primarycohort_data_10plus.sas7bdat", clear
keep if other48 >= 1000

/* Create splines for cohort for models */
	mkspline spl_creatinine 5 = creatinine_high, pctile displayknots /* Creatinine Spline - 5 nodes */
	mkspline spl_lactate 5 = lactatemax_draw, pctile displayknots /* Lactate Spline - 5 nodes */
	mkspline spl_ratiomin 4 = ratio_min, pctile displayknots /* PaO2/FIO2 Spline - 4 nodes */
	mkspline spl_age 4 = age, pctile displayknots /* Age Spline - 4 nodes */
	mkspline spl_BMI 5 = BMI_calculated, pctile displayknots /* BMI Spline - 5 nodes */

 melogit mortality_30day ib0.balancemeasure48 c.spl_age? male postacutecare priorhosp KidneyDisease SevereLiverDisease CHF Metastatic mortality_predicted c.spl_BMI? c.spl_lactate? c.spl_creatinine? c.spl_creatinine?##KidneyDisease c.spl_ratiomin? ib2.max_temp ib2.max_HR ib1.max_RR mechvent_6hr alter_mental_status || hosp: , or

 /* Print Output to Excel File */
 putexcel set "[excel file name].xlsx", sheet(Prim48) modify
 putexcel A1=matrix(r(table)), names /* Output Model OR Table */
 
/* Calculate Marginal Probabilites (Risks) */
 margins balancemeasure48, post 
 putexcel A20=matrix(r(table)), names /* Output results to excel */
 
 /* Calculate Risk Differences */
 nlcom _b[1.balancemeasure48] - _b[0.balancemeasure48]

 putexcel G20=matrix(r(table)), names /* Output results to excel */


 	/* In-hospital Mortality - Categorical Version of Balanced Fluids */
	/* 20% intervals */
	melogit mortality_30day ib1.balance_48_cat c.spl_age? male postacutecare priorhosp KidneyDisease SevereLiverDisease CHF Metastatic mortality_predicted c.spl_BMI? c.spl_lactate? c.spl_creatinine? c.spl_creatinine?##KidneyDisease c.spl_ratiomin? ib2.max_temp ib2.max_HR ib1.max_RR mechvent_6hr alter_mental_status || hosp: , or

	/* Calculate Marginal Probabilites (Risks) */
	margins balance_48_cat, post 
	
	/* Calculate Risk Differences */
	nlcom _b[2.balance_48_cat] - _b[1.balance_48_cat]
	nlcom _b[3.balance_48_cat] - _b[1.balance_48_cat]
	nlcom _b[4.balance_48_cat] - _b[1.balance_48_cat]
	nlcom _b[5.balance_48_cat] - _b[1.balance_48_cat]

	/* 25% intervals - Update 09/14/2026 */
	melogit mortality_30day ib1.balance_48_cat_25 c.spl_age? male postacutecare priorhosp KidneyDisease SevereLiverDisease CHF Metastatic mortality_predicted c.spl_BMI? c.spl_lactate? c.spl_creatinine? c.spl_creatinine?##KidneyDisease c.spl_ratiomin? ib2.max_temp ib2.max_HR ib1.max_RR mechvent_6hr alter_mental_status || hosp: , or

	/* Calculate Marginal Probabilites (Risks) */
	margins balance_48_cat_25, post 
	
	/* Calculate Risk Differences */
	nlcom _b[2.balance_48_cat_25] - _b[1.balance_48_cat_25]
	nlcom _b[3.balance_48_cat_25] - _b[1.balance_48_cat_25]
	nlcom _b[4.balance_48_cat_25] - _b[1.balance_48_cat_25]
 
 
 /* Subgroup 1 - Septic Shock */
import sas using "[filepath]\subgroup1_data_10plus.sas7bdat", clear
keep if other48 >= 1000

/* Create splines for cohort for models */
	mkspline spl_creatinine 5 = creatinine_high, pctile displayknots /* Creatinine Spline - 5 nodes */
	mkspline spl_lactate 5 = lactatemax_draw, pctile displayknots /* Lactate Spline - 5 nodes */
	mkspline spl_ratiomin 4 = ratio_min, pctile displayknots /* PaO2/FIO2 Spline - 4 nodes */
	mkspline spl_age 4 = age, pctile displayknots /* Age Spline - 4 nodes */
	mkspline spl_BMI 5 = BMI_calculated, pctile displayknots /* BMI Spline - 5 nodes */

 melogit mortality_30day ib0.balancemeasure48 c.spl_age? male postacutecare priorhosp KidneyDisease SevereLiverDisease CHF Metastatic mortality_predicted c.spl_BMI? c.spl_lactate? c.spl_creatinine? c.spl_creatinine?##KidneyDisease c.spl_ratiomin? ib2.max_temp ib2.max_HR ib1.max_RR mechvent_6hr alter_mental_status || hosp: , or

 /* Print Output to Excel File */
 putexcel set "[excel file name].xlsx", sheet(Sub1_48) modify
 putexcel A1=matrix(r(table)), names /* Output Model OR Table */
 
/* Calculate Marginal Probabilites (Risks) */
 margins balancemeasure48, post 
 putexcel A20=matrix(r(table)), names /* Output results to excel */
 
 /* Calculate Risk Differences */
 nlcom _b[1.balancemeasure48] - _b[0.balancemeasure48]

 putexcel G20=matrix(r(table)), names /* Output results to excel */
 
 
  /* Subgroup 2 - Initiated on intravenous vasopressor within 2 hours of arrival */
import sas using "[filepath]\subgroup2_data_10plus.sas7bdat", clear
keep if other48 >= 1000

/* Create splines for cohort for models */
	mkspline spl_creatinine 5 = creatinine_high, pctile displayknots /* Creatinine Spline - 5 nodes */
	mkspline spl_lactate 5 = lactatemax_draw, pctile displayknots /* Lactate Spline - 5 nodes */
	mkspline spl_ratiomin 4 = ratio_min, pctile displayknots /* PaO2/FIO2 Spline - 4 nodes */
	mkspline spl_age 4 = age, pctile displayknots /* Age Spline - 4 nodes */
	mkspline spl_BMI 5 = BMI_calculated, pctile displayknots /* BMI Spline - 5 nodes */

 melogit mortality_30day ib0.balancemeasure48 c.spl_age? male postacutecare priorhosp KidneyDisease SevereLiverDisease CHF Metastatic mortality_predicted c.spl_BMI? c.spl_lactate? c.spl_creatinine? c.spl_creatinine?##KidneyDisease c.spl_ratiomin? ib2.max_temp ib2.max_HR ib1.max_RR mechvent_6hr alter_mental_status || hosp: , or

 /* Print Output to Excel File */
 putexcel set "[excel file name].xlsx", sheet(Sub2_48) modify
 putexcel A1=matrix(r(table)), names /* Output Model OR Table */
 
/* Calculate Marginal Probabilites (Risks) */
 margins balancemeasure48, post 
 putexcel A20=matrix(r(table)), names /* Output results to excel */
 
 /* Calculate Risk Differences */
 nlcom _b[1.balancemeasure48] - _b[0.balancemeasure48]

 putexcel G20=matrix(r(table)), names /* Output results to excel */
 
 
   /* Subgroup 3. Hypotensive within 2 hours of (SBP <90, MAP <65|| hosp: , or on vasopressors) */
import sas using "[filepath]\subgroup3_data_10plus.sas7bdat", clear
keep if other48 >= 1000

/* Create splines for cohort for models */
	mkspline spl_creatinine 5 = creatinine_high, pctile displayknots /* Creatinine Spline - 5 nodes */
	mkspline spl_lactate 5 = lactatemax_draw, pctile displayknots /* Lactate Spline - 5 nodes */
	mkspline spl_ratiomin 4 = ratio_min, pctile displayknots /* PaO2/FIO2 Spline - 4 nodes */
	mkspline spl_age 4 = age, pctile displayknots /* Age Spline - 4 nodes */
	mkspline spl_BMI 5 = BMI_calculated, pctile displayknots /* BMI Spline - 5 nodes */

 melogit mortality_30day ib0.balancemeasure48 c.spl_age? male postacutecare priorhosp KidneyDisease SevereLiverDisease CHF Metastatic mortality_predicted c.spl_BMI? c.spl_lactate? c.spl_creatinine? c.spl_creatinine?##KidneyDisease c.spl_ratiomin? ib2.max_temp ib2.max_HR ib1.max_RR mechvent_6hr alter_mental_status || hosp: , or

 /* Print Output to Excel File */
 putexcel set "[excel file name].xlsx", sheet(Sub3_48) modify
 putexcel A1=matrix(r(table)), names /* Output Model OR Table */
 
/* Calculate Marginal Probabilites (Risks) */
 margins balancemeasure48, post 
 putexcel A20=matrix(r(table)), names /* Output results to excel */
 
 /* Calculate Risk Differences */
 nlcom _b[1.balancemeasure48] - _b[0.balancemeasure48]

 putexcel G20=matrix(r(table)), names /* Output results to excel */


   /* Subgroup 4. First lactate ≥4 mmol/L (with or without hypotension); limit to lactate drawn within 6 hours - Answerd: DO WE WANT THIS ALSO WITHIN 3 HOURS? no 3 hour mark */
import sas using "[filepath]\subgroup4_data_10plus.sas7bdat", clear
keep if other48 >= 1000

/* Create splines for cohort for models */
	mkspline spl_creatinine 5 = creatinine_high, pctile displayknots /* Creatinine Spline - 5 nodes */
	mkspline spl_lactate 5 = lactatemax_draw, pctile displayknots /* Lactate Spline - 5 nodes */
	mkspline spl_ratiomin 4 = ratio_min, pctile displayknots /* PaO2/FIO2 Spline - 4 nodes */
	mkspline spl_age 4 = age, pctile displayknots /* Age Spline - 4 nodes */
	mkspline spl_BMI 5 = BMI_calculated, pctile displayknots /* BMI Spline - 5 nodes */

 melogit mortality_30day ib0.balancemeasure48 c.spl_age? male postacutecare priorhosp KidneyDisease SevereLiverDisease CHF Metastatic mortality_predicted c.spl_BMI? c.spl_lactate? c.spl_creatinine? c.spl_creatinine?##KidneyDisease c.spl_ratiomin? ib2.max_temp ib2.max_HR ib1.max_RR mechvent_6hr alter_mental_status || hosp: , or

 /* Print Output to Excel File */
 putexcel set "[excel file name].xlsx", sheet(Sub4_48) modify
 putexcel A1=matrix(r(table)), names /* Output Model OR Table */
 
/* Calculate Marginal Probabilites (Risks) */
 margins balancemeasure48, post 
 putexcel A20=matrix(r(table)), names /* Output results to excel */
 
 /* Calculate Risk Differences */
 nlcom _b[1.balancemeasure48] - _b[0.balancemeasure48]

 putexcel G20=matrix(r(table)), names /* Output results to excel */


   /* Subgroup 5. First lactate 2-4 mmol/L and no hypotension (intermediate lactate population), limit to lactate drawn within 6 hours */
import sas using "[filepath]\subgroup5_data_10plus.sas7bdat", clear
keep if other48 >= 1000

/* Create splines for cohort for models */
	mkspline spl_creatinine 5 = creatinine_high, pctile displayknots /* Creatinine Spline - 5 nodes */
	mkspline spl_lactate 5 = lactatemax_draw, pctile displayknots /* Lactate Spline - 5 nodes */
	mkspline spl_ratiomin 4 = ratio_min, pctile displayknots /* PaO2/FIO2 Spline - 4 nodes */
	mkspline spl_age 4 = age, pctile displayknots /* Age Spline - 4 nodes */
	mkspline spl_BMI 5 = BMI_calculated, pctile displayknots /* BMI Spline - 5 nodes */

 melogit mortality_30day ib0.balancemeasure48 c.spl_age? male postacutecare priorhosp KidneyDisease SevereLiverDisease CHF Metastatic mortality_predicted c.spl_BMI? c.spl_lactate? c.spl_creatinine? c.spl_creatinine?##KidneyDisease c.spl_ratiomin? ib2.max_temp ib2.max_HR ib1.max_RR mechvent_6hr alter_mental_status || hosp: , or

 /* Print Output to Excel File */
 putexcel set "[excel file name].xlsx", sheet(Sub5_48) modify
 putexcel A1=matrix(r(table)), names /* Output Model OR Table */
 
/* Calculate Marginal Probabilites (Risks) */
 margins balancemeasure48, post 
 putexcel A20=matrix(r(table)), names /* Output results to excel */
 
 /* Calculate Risk Differences */
 nlcom _b[1.balancemeasure48] - _b[0.balancemeasure48]

 putexcel G20=matrix(r(table)), names /* Output results to excel */

   /* Subgroup 6. AKI at presentation. Use initial creatinine and existing HMS measure for AKI present on presentation (use creatinine value used in mortality model) - Answerd: WHAT CREATEININE VALUES DO YOU WANT TO CONSIDER AKI? AND DO YOU ALSO WANT TO USE MODEERATRE TO SEVERE KIDNEY DISEASE? OR STAGE 5? Use the AKI definition from organ dysfunction calculator but with creatinine on day 1 only */
import sas using "[filepath]\subgroup6_data_10plus.sas7bdat", clear
keep if other48 >= 1000

/* Create splines for cohort for models */
	mkspline spl_creatinine 5 = creatinine_high, pctile displayknots /* Creatinine Spline - 5 nodes */
	mkspline spl_lactate 5 = lactatemax_draw, pctile displayknots /* Lactate Spline - 5 nodes */
	mkspline spl_ratiomin 4 = ratio_min, pctile displayknots /* PaO2/FIO2 Spline - 4 nodes */
	mkspline spl_age 4 = age, pctile displayknots /* Age Spline - 4 nodes */
	mkspline spl_BMI 5 = BMI_calculated, pctile displayknots /* BMI Spline - 5 nodes */

 melogit mortality_30day ib0.balancemeasure48 c.spl_age? male postacutecare priorhosp KidneyDisease SevereLiverDisease CHF Metastatic mortality_predicted c.spl_BMI? c.spl_lactate? c.spl_creatinine? c.spl_creatinine?##KidneyDisease c.spl_ratiomin? ib2.max_temp ib2.max_HR ib1.max_RR mechvent_6hr alter_mental_status || hosp: , or

 /* Print Output to Excel File */
 putexcel set "[excel file name].xlsx", sheet(Sub6_48) modify
 putexcel A1=matrix(r(table)), names /* Output Model OR Table */
 
/* Calculate Marginal Probabilites (Risks) */
 margins balancemeasure48, post 
 putexcel A20=matrix(r(table)), names /* Output results to excel */
 
 /* Calculate Risk Differences */
 nlcom _b[1.balancemeasure48] - _b[0.balancemeasure48]

 putexcel G20=matrix(r(table)), names /* Output results to excel */


   /* Subgroup 7. Age ≥65 years old */
import sas using "[filepath]\subgroup7_data_10plus.sas7bdat", clear
keep if other48 >= 1000

/* Create splines for cohort for models */
	mkspline spl_creatinine 5 = creatinine_high, pctile displayknots /* Creatinine Spline - 5 nodes */
	mkspline spl_lactate 5 = lactatemax_draw, pctile displayknots /* Lactate Spline - 5 nodes */
	mkspline spl_ratiomin 4 = ratio_min, pctile displayknots /* PaO2/FIO2 Spline - 4 nodes */
	mkspline spl_age 4 = age, pctile displayknots /* Age Spline - 4 nodes */
	mkspline spl_BMI 5 = BMI_calculated, pctile displayknots /* BMI Spline - 5 nodes */

 melogit mortality_30day ib0.balancemeasure48 c.spl_age? male postacutecare priorhosp KidneyDisease SevereLiverDisease CHF Metastatic mortality_predicted c.spl_BMI? c.spl_lactate? c.spl_creatinine? c.spl_creatinine?##KidneyDisease c.spl_ratiomin? ib2.max_temp ib2.max_HR ib1.max_RR mechvent_6hr alter_mental_status || hosp: , or

 /* Print Output to Excel File */
 putexcel set "[excel file name].xlsx", sheet(Sub7_48) modify
 putexcel A1=matrix(r(table)), names /* Output Model OR Table */
 
/* Calculate Marginal Probabilites (Risks) */
 margins balancemeasure48, post 
 putexcel A20=matrix(r(table)), names /* Output results to excel */
 
 /* Calculate Risk Differences */
 nlcom _b[1.balancemeasure48] - _b[0.balancemeasure48]

 putexcel G20=matrix(r(table)), names /* Output results to excel */





 /******************************** 6 Hours ********************************/
/* Primary Cohort */
import sas using "[filepath]\secondarycohort_data_10plus.sas7bdat", clear
keep if other6 >= 1000 /* Keep only hypoperfused without comorbidities cohort */

/* Create splines for cohort for models */
	mkspline spl_creatinine 5 = creatinine_high, pctile displayknots /* Creatinine Spline - 5 nodes */
	mkspline spl_lactate 5 = lactatemax_draw, pctile displayknots /* Lactate Spline - 5 nodes */
	mkspline spl_ratiomin 4 = ratio_min, pctile displayknots /* PaO2/FIO2 Spline - 4 nodes */
	mkspline spl_age 4 = age, pctile displayknots /* Age Spline - 4 nodes */
	mkspline spl_BMI 5 = BMI_calculated, pctile displayknots /* BMI Spline - 5 nodes */

 melogit mortality_30day ib0.balancemeasure6 c.spl_age? male postacutecare priorhosp KidneyDisease SevereLiverDisease CHF Metastatic mortality_predicted c.spl_BMI? c.spl_lactate? c.spl_creatinine? c.spl_creatinine?##KidneyDisease c.spl_ratiomin? ib2.max_temp ib2.max_HR ib1.max_RR alter_mental_status || hosp: , or

 /* Print Output to Excel File */
 putexcel set "[excel file name].xlsx", sheet(Prim6) modify
 putexcel A1=matrix(r(table)), names /* Output Model OR Table */
 
/* Calculate Marginal Probabilites (Risks) */
 margins balancemeasure6, post 
 putexcel A20=matrix(r(table)), names /* Output results to excel */
 
 /* Calculate Risk Differences */
 nlcom _b[1.balancemeasure6] - _b[0.balancemeasure6]

 putexcel G20=matrix(r(table)), names /* Output results to excel */
 
 
 /* Subgroup 1 - Septic Shock */
import sas using "[filepath]\subgroup1_data_10plus.sas7bdat", clear
keep if other6 >= 1000 /* Keep only hypoperfused without comorbidities cohort */

/* Create splines for cohort for models */
	mkspline spl_creatinine 5 = creatinine_high, pctile displayknots /* Creatinine Spline - 5 nodes */
	mkspline spl_lactate 5 = lactatemax_draw, pctile displayknots /* Lactate Spline - 5 nodes */
	mkspline spl_ratiomin 4 = ratio_min, pctile displayknots /* PaO2/FIO2 Spline - 4 nodes */
	mkspline spl_age 4 = age, pctile displayknots /* Age Spline - 4 nodes */
	mkspline spl_BMI 5 = BMI_calculated, pctile displayknots /* BMI Spline - 5 nodes */
 melogit mortality_30day ib0.balancemeasure6 c.spl_age? male postacutecare priorhosp KidneyDisease SevereLiverDisease CHF Metastatic mortality_predicted c.spl_BMI? c.spl_lactate? c.spl_creatinine? c.spl_creatinine?##KidneyDisease c.spl_ratiomin? ib2.max_temp ib2.max_HR ib1.max_RR alter_mental_status || hosp: , or

 /* Print Output to Excel File */
 putexcel set "[excel file name].xlsx", sheet(Sub1_6) modify
 putexcel A1=matrix(r(table)), names /* Output Model OR Table */
 
/* Calculate Marginal Probabilites (Risks) */
 margins balancemeasure6, post 
 putexcel A20=matrix(r(table)), names /* Output results to excel */
 
 /* Calculate Risk Differences */
 nlcom _b[1.balancemeasure6] - _b[0.balancemeasure6]

 putexcel G20=matrix(r(table)), names /* Output results to excel */
 
 
  /* Subgroup 2 - Initiated on intravenous vasopressor within 2 hours of arrival */
import sas using "[filepath]\subgroup2_data_10plus.sas7bdat", clear
keep if other6 >= 1000 /* Keep only hypoperfused without comorbidities cohort */

/* Create splines for cohort for models */
	mkspline spl_creatinine 5 = creatinine_high, pctile displayknots /* Creatinine Spline - 5 nodes */
	mkspline spl_lactate 5 = lactatemax_draw, pctile displayknots /* Lactate Spline - 5 nodes */
	mkspline spl_ratiomin 4 = ratio_min, pctile displayknots /* PaO2/FIO2 Spline - 4 nodes */
	mkspline spl_age 4 = age, pctile displayknots /* Age Spline - 4 nodes */
	mkspline spl_BMI 5 = BMI_calculated, pctile displayknots /* BMI Spline - 5 nodes */
 melogit mortality_30day ib0.balancemeasure6 c.spl_age? male postacutecare priorhosp KidneyDisease SevereLiverDisease CHF Metastatic mortality_predicted c.spl_BMI? c.spl_lactate? c.spl_creatinine? c.spl_creatinine?##KidneyDisease c.spl_ratiomin? ib2.max_temp ib2.max_HR ib1.max_RR alter_mental_status || hosp: , or

 /* Print Output to Excel File */
 putexcel set "[excel file name].xlsx", sheet(Sub2_6) modify
 putexcel A1=matrix(r(table)), names /* Output Model OR Table */
 
/* Calculate Marginal Probabilites (Risks) */
 margins balancemeasure6, post 
 putexcel A20=matrix(r(table)), names /* Output results to excel */
 
 /* Calculate Risk Differences */
 nlcom _b[1.balancemeasure6] - _b[0.balancemeasure6]

 putexcel G20=matrix(r(table)), names /* Output results to excel */
 
 
   /* Subgroup 3. Hypotensive within 2 hours of (SBP <90, MAP <65|| hosp: , or on vasopressors) */
import sas using "[filepath]\subgroup3_data_10plus.sas7bdat", clear
keep if other6 >= 1000 /* Keep only hypoperfused without comorbidities cohort */

/* Create splines for cohort for models */
	mkspline spl_creatinine 5 = creatinine_high, pctile displayknots /* Creatinine Spline - 5 nodes */
	mkspline spl_lactate 5 = lactatemax_draw, pctile displayknots /* Lactate Spline - 5 nodes */
	mkspline spl_ratiomin 4 = ratio_min, pctile displayknots /* PaO2/FIO2 Spline - 4 nodes */
	mkspline spl_age 4 = age, pctile displayknots /* Age Spline - 4 nodes */
	mkspline spl_BMI 5 = BMI_calculated, pctile displayknots /* BMI Spline - 5 nodes */

 melogit mortality_30day ib0.balancemeasure6 c.spl_age? male postacutecare priorhosp KidneyDisease SevereLiverDisease CHF Metastatic mortality_predicted c.spl_BMI? c.spl_lactate? c.spl_creatinine? c.spl_creatinine?##KidneyDisease c.spl_ratiomin? ib2.max_temp ib2.max_HR ib1.max_RR alter_mental_status || hosp: , or

 /* Print Output to Excel File */
 putexcel set "[excel file name].xlsx", sheet(Sub3_6) modify
 putexcel A1=matrix(r(table)), names /* Output Model OR Table */
 
/* Calculate Marginal Probabilites (Risks) */
 margins balancemeasure6, post 
 putexcel A20=matrix(r(table)), names /* Output results to excel */
 
 /* Calculate Risk Differences */
 nlcom _b[1.balancemeasure6] - _b[0.balancemeasure6]

 putexcel G20=matrix(r(table)), names /* Output results to excel */


   /* Subgroup 4. First lactate ≥4 mmol/L (with or without hypotension); limit to lactate drawn within 6 hours - Answerd: DO WE WANT THIS ALSO WITHIN 3 HOURS? no 3 hour mark */
import sas using "[filepath]\subgroup4_data_10plus.sas7bdat", clear
keep if other6 >= 1000 /* Keep only hypoperfused without comorbidities cohort */

/* Create splines for cohort for models */
	mkspline spl_creatinine 5 = creatinine_high, pctile displayknots /* Creatinine Spline - 5 nodes */
	mkspline spl_lactate 5 = lactatemax_draw, pctile displayknots /* Lactate Spline - 5 nodes */
	mkspline spl_ratiomin 4 = ratio_min, pctile displayknots /* PaO2/FIO2 Spline - 4 nodes */
	mkspline spl_age 4 = age, pctile displayknots /* Age Spline - 4 nodes */
	mkspline spl_BMI 5 = BMI_calculated, pctile displayknots /* BMI Spline - 5 nodes */

 melogit mortality_30day ib0.balancemeasure6 c.spl_age? male postacutecare priorhosp KidneyDisease SevereLiverDisease CHF Metastatic mortality_predicted c.spl_BMI? c.spl_lactate? c.spl_creatinine? c.spl_creatinine?##KidneyDisease c.spl_ratiomin? ib2.max_temp ib2.max_HR ib1.max_RR alter_mental_status || hosp: , or

 /* Print Output to Excel File */
 putexcel set "[excel file name].xlsx", sheet(Sub4_6) modify
 putexcel A1=matrix(r(table)), names /* Output Model OR Table */
 
/* Calculate Marginal Probabilites (Risks) */
 margins balancemeasure6, post 
 putexcel A20=matrix(r(table)), names /* Output results to excel */
 
 /* Calculate Risk Differences */
 nlcom _b[1.balancemeasure6] - _b[0.balancemeasure6]

 putexcel G20=matrix(r(table)), names /* Output results to excel */


   /* Subgroup 5. First lactate 2-4 mmol/L and no hypotension (intermediate lactate population), limit to lactate drawn within 6 hours */
import sas using "[filepath]\subgroup5_data_10plus.sas7bdat", clear
keep if other6 >= 1000 /* Keep only hypoperfused without comorbidities cohort */

/* Create splines for cohort for models */
	mkspline spl_creatinine 5 = creatinine_high, pctile displayknots /* Creatinine Spline - 5 nodes */
	mkspline spl_lactate 5 = lactatemax_draw, pctile displayknots /* Lactate Spline - 5 nodes */
	mkspline spl_ratiomin 4 = ratio_min, pctile displayknots /* PaO2/FIO2 Spline - 4 nodes */
	mkspline spl_age 4 = age, pctile displayknots /* Age Spline - 4 nodes */
	mkspline spl_BMI 5 = BMI_calculated, pctile displayknots /* BMI Spline - 5 nodes */

 melogit mortality_30day ib0.balancemeasure6 c.spl_age? male postacutecare priorhosp KidneyDisease SevereLiverDisease CHF Metastatic mortality_predicted c.spl_BMI? c.spl_lactate? c.spl_creatinine? c.spl_creatinine?##KidneyDisease c.spl_ratiomin? ib2.max_temp ib2.max_HR ib1.max_RR alter_mental_status || hosp: , or

 /* Print Output to Excel File */
 putexcel set "[excel file name].xlsx", sheet(Sub5_6) modify
 putexcel A1=matrix(r(table)), names /* Output Model OR Table */
 
/* Calculate Marginal Probabilites (Risks) */
 margins balancemeasure6, post 
 putexcel A20=matrix(r(table)), names /* Output results to excel */
 
 /* Calculate Risk Differences */
 nlcom _b[1.balancemeasure6] - _b[0.balancemeasure6]

 putexcel G20=matrix(r(table)), names /* Output results to excel */


   /* Subgroup 6. AKI at presentation. */
import sas using "[filepath]\subgroup6_data_10plus.sas7bdat", clear
keep if other6 >= 1000 /* Keep only hypoperfused without comorbidities cohort */

/* Create splines for cohort for models */
	mkspline spl_creatinine 5 = creatinine_high, pctile displayknots /* Creatinine Spline - 5 nodes */
	mkspline spl_lactate 5 = lactatemax_draw, pctile displayknots /* Lactate Spline - 5 nodes */
	mkspline spl_ratiomin 4 = ratio_min, pctile displayknots /* PaO2/FIO2 Spline - 4 nodes */
	mkspline spl_age 4 = age, pctile displayknots /* Age Spline - 4 nodes */
	mkspline spl_BMI 5 = BMI_calculated, pctile displayknots /* BMI Spline - 5 nodes */


 melogit mortality_30day ib0.balancemeasure6 c.spl_age? male postacutecare priorhosp KidneyDisease SevereLiverDisease CHF Metastatic mortality_predicted c.spl_BMI? c.spl_lactate? c.spl_creatinine? c.spl_creatinine?##KidneyDisease c.spl_ratiomin? ib2.max_temp ib2.max_HR ib1.max_RR alter_mental_status || hosp: , or

 /* Print Output to Excel File */
 putexcel set "[excel file name].xlsx", sheet(Sub6_6) modify
 putexcel A1=matrix(r(table)), names /* Output Model OR Table */
 
/* Calculate Marginal Probabilites (Risks) */
 margins balancemeasure6, post 
 putexcel A20=matrix(r(table)), names /* Output results to excel */
 
 /* Calculate Risk Differences */
 nlcom _b[1.balancemeasure6] - _b[0.balancemeasure6]

 putexcel G20=matrix(r(table)), names /* Output results to excel */


   /* Subgroup 7. Age ≥65 years old */
import sas using "[filepath]\subgroup7_data_10plus.sas7bdat", clear
keep if other6 >= 1000 /* Keep only hypoperfused without comorbidities cohort */

/* Create splines for cohort for models */
	mkspline spl_creatinine 5 = creatinine_high, pctile displayknots /* Creatinine Spline - 5 nodes */
	mkspline spl_lactate 5 = lactatemax_draw, pctile displayknots /* Lactate Spline - 5 nodes */
	mkspline spl_ratiomin 4 = ratio_min, pctile displayknots /* PaO2/FIO2 Spline - 4 nodes */
	mkspline spl_age 4 = age, pctile displayknots /* Age Spline - 4 nodes */
	mkspline spl_BMI 5 = BMI_calculated, pctile displayknots /* BMI Spline - 5 nodes */


 melogit mortality_30day ib0.balancemeasure6 c.spl_age? male postacutecare priorhosp KidneyDisease SevereLiverDisease CHF Metastatic mortality_predicted c.spl_BMI? c.spl_lactate? c.spl_creatinine? c.spl_creatinine?##KidneyDisease c.spl_ratiomin? ib2.max_temp ib2.max_HR ib1.max_RR alter_mental_status || hosp: , or

 /* Print Output to Excel File */
 putexcel set "[excel file name].xlsx", sheet(Sub7_6) modify
 putexcel A1=matrix(r(table)), names /* Output Model OR Table */
 
/* Calculate Marginal Probabilites (Risks) */
 margins balancemeasure6, post 
 putexcel A20=matrix(r(table)), names /* Output results to excel */
 
 /* Calculate Risk Differences */
 nlcom _b[1.balancemeasure6] - _b[0.balancemeasure6]

 putexcel G20=matrix(r(table)), names /* Output results to excel */

log close

/********************************************** Table 3 **********************************************/
log using "[log file 2]"
/******************************** 48 Hours ********************************/
/* Primary Cohort */
import sas using "[filepath]\primarycohort_data_10plus.sas7bdat", clear
keep if other48 >= 1000

/* Create splines for cohort for models */
	mkspline spl_creatinine 5 = creatinine_high, pctile displayknots /* Creatinine Spline - 5 nodes */
	mkspline spl_lactate 5 = lactatemax_draw, pctile displayknots /* Lactate Spline - 5 nodes */
	mkspline spl_ratiomin 4 = ratio_min, pctile displayknots /* PaO2/FIO2 Spline - 4 nodes */
	mkspline spl_age 4 = age, pctile displayknots /* Age Spline - 4 nodes */
	mkspline spl_BMI 5 = BMI_calculated, pctile displayknots /* BMI Spline - 5 nodes */


/* In-hospital Mortality */

 melogit mortality_hosp ib0.balancemeasure48 c.spl_age? male postacutecare priorhosp KidneyDisease SevereLiverDisease CHF Metastatic mortality_predicted c.spl_BMI? c.spl_lactate? c.spl_creatinine? c.spl_creatinine?##KidneyDisease c.spl_ratiomin? ib2.max_temp ib2.max_HR ib1.max_RR mechvent_6hr alter_mental_status || hosp: , or

 /* Print Output to Excel File */
 putexcel set "[excel file name].xlsx", sheet(HospMort48) modify
 putexcel A1=matrix(r(table)), names /* Output Model OR Table */
 
/* Calculate Marginal Probabilites (Risks) */
 margins balancemeasure48, post 
 putexcel A20=matrix(r(table)), names /* Output results to excel */
 
 /* Calculate Risk Differences */
 nlcom _b[1.balancemeasure48] - _b[0.balancemeasure48]

 putexcel G20=matrix(r(table)), names /* Output results to excel */



/* LOS */

 poisson length_stay ib0.balancemeasure48 c.spl_age? male postacutecare priorhosp KidneyDisease SevereLiverDisease CHF Metastatic mortality_predicted c.spl_BMI? c.spl_lactate? c.spl_creatinine? c.spl_creatinine?##KidneyDisease c.spl_ratiomin? ib2.max_temp ib2.max_HR ib1.max_RR mechvent_6hr alter_mental_status

 /* Print Output to Excel File */
 putexcel set "[excel file name].xlsx", sheet(LOS48) modify
 putexcel A1=matrix(r(table)), names /* Output Model OR Table */
 
/* Calculate Marginal Probabilites (Risks) */
 margins balancemeasure48, post 
 putexcel A20=matrix(r(table)), names /* Output results to excel */
 
 /* Calculate Risk Differences */
 nlcom _b[1.balancemeasure48] - _b[0.balancemeasure48]

 putexcel G20=matrix(r(table)), names /* Output results to excel */


 /* Every Required RRT */

 melogit EverRRT ib0.balancemeasure48 c.spl_age? male postacutecare priorhosp KidneyDisease SevereLiverDisease CHF Metastatic mortality_predicted c.spl_BMI? c.spl_lactate? c.spl_creatinine? c.spl_creatinine?##KidneyDisease c.spl_ratiomin? ib2.max_temp ib2.max_HR ib1.max_RR mechvent_6hr alter_mental_status || hosp: , or

 /* Print Output to Excel File */
 putexcel set "[excel file name].xlsx", sheet(RRT48) modify
 putexcel A1=matrix(r(table)), names /* Output Model OR Table */
 
/* Calculate Marginal Probabilites (Risks) */
 margins balancemeasure48, post 
 putexcel A20=matrix(r(table)), names /* Output results to excel */
 
 /* Calculate Risk Differences */
 nlcom _b[1.balancemeasure48] - _b[0.balancemeasure48]

 putexcel G20=matrix(r(table)), names /* Output results to excel */



  /******************************** 6 Hours ********************************/
/* Primary Cohort */
import sas using "[filepath]\secondarycohort_data_10plus.sas7bdat", clear
keep if other6 >= 1000 /* Keep only hypoperfused without comorbidities cohort */

/* Create splines for cohort for models */
	mkspline spl_creatinine 5 = creatinine_high, pctile displayknots /* Creatinine Spline - 5 nodes */
	mkspline spl_lactate 5 = lactatemax_draw, pctile displayknots /* Lactate Spline - 5 nodes */
	mkspline spl_ratiomin 4 = ratio_min, pctile displayknots /* PaO2/FIO2 Spline - 4 nodes */
	mkspline spl_age 4 = age, pctile displayknots /* Age Spline - 4 nodes */
	mkspline spl_BMI 5 = BMI_calculated, pctile displayknots /* BMI Spline - 5 nodes */

/* In-hospital Mortality */

 melogit mortality_hosp ib0.balancemeasure6 c.spl_age? male postacutecare priorhosp KidneyDisease SevereLiverDisease CHF Metastatic mortality_predicted c.spl_BMI? c.spl_lactate? c.spl_creatinine? c.spl_creatinine?##KidneyDisease c.spl_ratiomin? ib2.max_temp ib2.max_HR ib1.max_RR alter_mental_status || hosp: , or

 /* Print Output to Excel File */
 putexcel set "[excel file name].xlsx", sheet(HospMort6) modify
 putexcel A1=matrix(r(table)), names /* Output Model OR Table */
 
/* Calculate Marginal Probabilites (Risks) */
 margins balancemeasure6, post 
 putexcel A20=matrix(r(table)), names /* Output results to excel */
 
 /* Calculate Risk Differences */
 nlcom _b[1.balancemeasure6] - _b[0.balancemeasure6]

 putexcel G20=matrix(r(table)), names /* Output results to excel */


/* LOS */

 poisson length_stay ib0.balancemeasure6 c.spl_age? male postacutecare priorhosp KidneyDisease SevereLiverDisease CHF Metastatic mortality_predicted c.spl_BMI? c.spl_lactate? c.spl_creatinine? c.spl_creatinine?##KidneyDisease c.spl_ratiomin? ib2.max_temp ib2.max_HR ib1.max_RR alter_mental_status 

 /* Print Output to Excel File */
 putexcel set "[excel file name].xlsx", sheet(LOS6) modify
 putexcel A1=matrix(r(table)), names /* Output Model OR Table */
 
/* Calculate Marginal Probabilites (Risks) */
 margins balancemeasure6, post 
 putexcel A20=matrix(r(table)), names /* Output results to excel */
 
 /* Calculate Risk Differences */
 nlcom _b[1.balancemeasure6] - _b[0.balancemeasure6]

 putexcel G20=matrix(r(table)), names /* Output results to excel */


 /* Every Required RRT */

 melogit EverRRT ib0.balancemeasure6 c.spl_age? male postacutecare priorhosp KidneyDisease SevereLiverDisease CHF Metastatic mortality_predicted c.spl_BMI? c.spl_lactate? c.spl_creatinine? c.spl_creatinine?##KidneyDisease c.spl_ratiomin? ib2.max_temp ib2.max_HR ib1.max_RR alter_mental_status || hosp: , or

 /* Print Output to Excel File */
 putexcel set "[excel file name].xlsx", sheet(RRT6) modify
 putexcel A1=matrix(r(table)), names /* Output Model OR Table */
 
/* Calculate Marginal Probabilites (Risks) */
 margins balancemeasure6, post 
 putexcel A20=matrix(r(table)), names /* Output results to excel */
 
 /* Calculate Risk Differences */
 nlcom _b[1.balancemeasure6] - _b[0.balancemeasure6]

 putexcel G20=matrix(r(table)), names /* Output results to excel */

 log close
 
