*************************************************************************
Project Name: Munroe - Fluid Analysis
Written by: Emily Walzl
Date: August 3rd, 2026

BIG UPDATE FROM ORIGINAL PROJECT
NOW JUST FOCUSING ON BALANCED FLUID MEASURE, NO LONGER INCLUDING PORTION OF ANALYSIS RELATING TO 30 MLKG MEASURE
Aims:
Aim 1: Understand the association between receiving a majority balanced fluid overall (48 hours) and early resuscitation (6 hours) and clinical outcomes 
Aim 2: Evaluate the effect of receiving a majority balanced fluid and mortality across key subgroups based on septic shock, illness severity 
Aim 3: Evaluate the association between percent of resuscitative fluid that is balanced (0 to 100%) as a continuous exposure and 30-day mortality using spline regression models



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


This Code:
1.	Edit the variables needed for the manuscript tables.


Study Flow (Similar outline for both Aims 1 and 2):
- Figure 1: Variation in fluid volume (aim 1) in patients with sepsis across Michigan hospitals
- Table 1.1: Compliance with 30ml/kg measure across primary and sensitivity analysis populations
- Table 1.2: Comparing patient characteristics between patients who received ≥30ml/kg vs <30ml/kg actual body weight within 6 hours (Primary analysis population) 
- Table 1.3: Characteristics  of hospitals participating in HMS-sepsis cohort (Primary analysis population) 
- Table 1.4: Patient characteristics associated with receiving ≥30ml/kg (Primary Analysis)
- Table 1.5: Hospital level variation in receiving ≥30ml/kg across sensitivity analysis 
- Table 1.6:  Association of receiving ≥30ml/kg with 30-day mortality (aim 3)
- Figure 2: Variation in fluid type (aim 2) in patients with sepsis across Michigan hospitals
- Table 2.1: Compliance with balanced fluid measure measure across primary and sensitivity analysis population
- Table 2.2: Comparing patient characteristics between patients who received ≥75% balanced fluid vs those who did not (Primary analysis population) 
- Table 2.3: Characteristics of hospitals participating in HMS-sepsis cohort (Primary analysis population) 
- Table 2.4: Patient characteristics associated with receiving ≥75% balanced fluid (Primary Analysis population)
- Table 2.5: Hospital level variation in receiving ≥75% balanced across sensitivity analysis 
- Table 2.6: Association of receiving ≥75% balanced fluid with 30-day mortality (aim 3)


Outcomes:
    Primary outcome: 30-day mortality (from date of presentation)

    Secondary outcomes:
    A.	In hospital mortality or hospice discharge (died in hospital or discharged to hospice)
    B.	Hospital length of stay
    C.	Ever renal replacement therapy (RRT): required RRT during admission



Steps for code (Create code to output tables for analytic memo - create cohort in this code):
- Establish cohorts (main and sensitivity analysis cohorts)
- Create predictor and outcome variables
- Create tables/run analyses (in order listed in study flow)

***************************************************************************/;

/* save log file to review */
/* Specify the path for the external log */
*Specify the Path;
%let path=[log filepath]\Fluid Analysis Tabel Creation&sysdate9..log;

* Export Log to External Path;
proc printto log="&path.";
run;

libname out "[filepath 1]";
libname hospital "T:\IntMed-HospMed\HMS data\pgms\Emily Walzl\Emily's Master Notebook - All things Job!";
libname harsh "[filepath 2]";
libname adifile "[filepath 3]";
libname data "[filepath 2]";
	
/* Run code to get ADI scores */
%include "[filepath 4]\adi_score_sample (EW).sas";

data adi_calc;
	set adi_calc;
	keep nid quartile;
run;

proc datasets library=work;
   	save Adi_calc;
run;



/************************* 
 Merge Patient realted data sets into final sample 
**************************/
proc sql; create table sample1 as select 
		a.*, 
		b.*,
        c.*
	from out.sample_allvars_11aug2026 a 
	left join adi_calc b on a.nid=b.nid
    left join data.fluid_bins c on a.nid=c.nid;
quit;


/****************************************************************************************************************************/
/*********************************************** Variable Creation for tables ***********************************************/
/****************************************************************************************************************************/
data sample2;
    set sample1;

    /* Only want to consider cases who were measured on these variables - started measuring at the end of 21 */
    
    if discharge_date > mdy(12,25,21); 

    FORMAT deathtime vasoadmin hospenc sixhourcutoff firstlactate secondlactate DATETIME19. newdeathdate DATE9.;

    /*********************** Baseline Patient level Characteristics ***********************/
        /* Age - Median (IQR)*/
        if age >= 18; 

            if age >= 65 then age65 = 1; else age65 =0;

        /* Sex - N (%) */
        if gender="Male" then male=1;
        else if gender~="Male" then male=0; 
        else male = .;

        /* Calculate the percentage of black people at each hosp */
        if race = "Black or African American" then race_black = 1; else race_black = 0;

        /* Admitted from LTAC/SNF/SAR/AR - N (%)*/
        if PlaceResidence_496257 in ("Long Term Acute Care Hospital (LTACH)", "Skilled Nursing Facility", "Sub-acute Rehabilitation Facility","Inpatient Rehab") then postacutecare = 1;
        else postacutecare = 0;

        /* Hospitalized in prior 90 days - N (%)*/
        if priorhosp_496257="Yes" then priorhosp=1;
	    else priorhosp=0;

        /* Baseline fundctional impairments - # of functional limitations based on 6 core activites of daily living (ADLs): eating, bathing, dressing, toileting, transferring, taking medications - Median (IQR) */
        if ADLYes1_496257="Partially or Fully Dependent" then ADLYes1=1; else  ADLYes1=0; /* bathing */
        if ADLYes2_496257="Partially or Fully Dependent" then ADLYes2=1; else  ADLYes2=0; /* dressing */
        if ADLYes5_496257="Partially or Fully Dependent" then ADLYes5=1; else  ADLYes5=0; /* toileting */
        if ADLYes6_496257="Partially or Fully Dependent" then ADLYes6=1; else  ADLYes6=0; /* transferring */
        if ADLYes7_496257="Partially or Fully Dependent" then ADLYes7=1; else  ADLYes7=0; /* walking */
        if ADLYes12_496257="Partially or Fully Dependent" then ADLYes12=1; else  ADLYes12=0; /* medications */

        adl_scores = ADLYes1 + ADLYes2 + ADLYes5 + ADLYes6 + ADLYes7 + ADLYes12;

        /* Charlson Comorbity Index - Median (IQR) */
		if ComorbidCond21_496257='Y' then CMI1=1; else CMI1=0; /* Prior myocardial infarction */
		if ComorbidCond6_496257='Y' then CMI2=1; else CMI2=0; /* Congestive heart failure */   /******************/
		if ComorbidCond24_496257='Y' then CMI3=1; else CMI3=0; /* Peripheral Vascular disease */
		if ComorbidCond4_496257='Y' then CMI4=1; else CMI4=0; /* Cerebrovascular disease */
		if ComorbidCond8_496257='Y' then CMI5=1; else CMI5=0; /* Dementia */   /******************/
		if ComorbidCond7_496257='Y' then CMI6=1; else CMI6=0; /* Chronic pulmonary disease */   /******************/
		if ComorbidCond25_496257='Y' then CMI7=1; else CMI7=0; /* Rheumatologic disease */
		if ComorbidCond23_496257='Y' then CMI8=1; else CMI8=0; /* Peptic Ulcer disease */
		if ComorbidCond18_496257='Y' then CMI9=1; else CMI9=0; /* Mild liver disease */   /******************/
		if ComorbidCond10_496257='Y' then CMI10=1; else CMI10=0; /* Diabetes uncomplicated */
		if ComorbidCond12_496257='Y' then CMI11=2; else CMI11=0; /* Cerebrovascular (hemiplegia) event */
		if ComorbidCond20_496257='Y' then CMI12=2; else CMI12=0; /* Moderate-to-severe renal disease */   /******************/
		if ComorbidCond9_496257='Y' then CMI13=2; else CMI13=0; /* Diabetes with chronic complications */
		if ComorbidCond16_496257='Y' then CMI14=2; else CMI14=0; /* Cancer without metastases */   /******************/
		if ComorbidCond14_496257='Y' then CMI15=2; else CMI15=0; /* Leukemia */   /******************/
		if ComorbidCond15_496257='Y' then CMI16=2; else CMI16=0; /* Lymphoma */   /******************/
		if ComorbidCond19_496257='Y' then CMI17=3; else CMI17=0; /* Moderate or severe liver disease */   /******************/
		if ComorbidCond17_496257='Y' then CMI18=6; else CMI18=0; /* Metastatic solid tumor */   /******************/
		if ComorbidCond1_496257='Y' then CMI19=6; else CMI19=0; /* AIDS */
        Charlson = sum(of CMI1-CMI19);

        /* Comorbidities - N (%): 
        - Hypertension 
        - Diabetes 
        - Kidney Disease (moderate or severe) 
        - liver disease 
        - Chronic lung disease 
        - Cogestive heart failure 
        - Coronary Artery Disease 
        - Cerebrovascular Disease 
        - Peripheral vascualr disease 
        - Malignancy (Solid tumors w/ and w/out metastasis, Leukemia, and Lymphoma)*/

        if ComorbidCond11_496257='Y' then Hypertension=1; else Hypertension=0; *Hypertension;
        if CMI10 > 0 or CMI13 > 0 then diabetes = 1; else diabetes = 0; * Diabetes (complicated or uncomplicated);
        if CMI12 > 0 then KidneyDisease=1; else KidneyDisease=0; * Kidney Disease (moderate/severe);
        if CMI17 > 0 then LiverDisease=1; else LiverDisease=0; * Liver disease (moderate/severe);
        if CMI6 > 0 or ComorbidCond5_496257 in ("Y", "Yes") then ChrPulm = 1; else ChrPulm = 0; * Chronic Lung Disease;
        if ComorbidCond6_496257='Y' then CHF=1;	else 	CHF=0; * Congestive Heart Failure;
        if ComorbidCond3_496257 in ('Yes', 'Y') then coronaryart = 1; else coronaryart = 0; * Coronary Artery Disease;
        if CMI4 > 0 or CMI11 > 0 then Cerebrovasc = 1; else Cerebrovasc = 0; * Cerebrovascular Disease;
        if ComorbidCond24_496257 in ('Yes', 'Y') then Periphvasc = 1; else Periphvasc = 0; * Peripheral Vascular Disease;
        if CMI14 > 0 or CMI15 > 0 or CMI16 > 0 or CMI18 > 0 then Malignancy=1; else Malignancy=0; * Malignancy;
        if CMI18=6 then Metastatic = 1; else Metastatic = 0; /* Metastatic solid tumor */


        /* BMI (kg/m^2) - Median (IQR) */
        if HeightUnit_496257 = 'Inches' then do;
            height = (HeightNum_496257*2.54);
        end;
        else if HeightUnit_496257 = 'Centimeters' then do;
            height = HeightNum_496257*1;
        end;

        if WeightUnit_496257 = 'Pounds' then do;
            weight = WeightNum_496257/2.205;
        end;
        else if WeightUnit_496257 = 'Kilograms' then do;
            weight = WeightNum_496257*1;
        end;

        /* Patients who have missing heights/weights - impute CDC averages */
        /* Male - 90.7kg and 175.26cm*/
		impute_height = 0;
		impute_weight = 0;
        if gender = 'Male' and (height = . or height < 121.92) then do;
			height =  175.26;
			impute_height = 1;
		end;
        if gender = 'Male' and weight = . then do;
			weight = 90.7;
			impute_weight = 1;
		end;

        /* Female - 77.5kg and 161.29cm*/
        if gender ~= 'Male' and (height = . or height < 121.92) then do;
			height = 161.29;
			impute_height = 1;
		end;
        if gender ~= 'Male' and weight = . then do;
			weight = 77.5;
			impute_weight = 1;
		end;

        
		imputed_HW = max(impute_height, impute_weight);

        height_meters = height/100;

        BMI_calculated = (weight)/(height_meters**2);

        /* Ideal Body Weight */
        IF gender = 'Male' AND height ne . THEN ibw = 50 + (0.91 * (height - 152.4));
        ELSE IF gender = 'Female' AND height ne . THEN ibw = 45.5 + (0.91 * (height - 152.4));
        /* gender = "unknown" or blank */
        ELSE ibw = 50 + (0.91 * (height - 152.4));

    /* Illness severity on presentation */

    /************************* 
    Run the organ dysfunction calculator from Danny Teng 
    *************************/

        /* Lactate (mmol/L - max lactate within 6 hours of hospital arrival) - Median (IQR) */
            /* Use mmol/L (if provided in mg/dL, then must convert to mmol/L)
                Use lactate values from “Early Management – Labs” Form
                Use highest lactate value measured within 6 hours of encounter start time.
                If none available, then impute normal value (1.0) 
                Use time to lacate DRAW, not result time

                Note on units: mEq/L = mmol/L
                            mg/dL = mmol/L*18.0182
                            mmol/L = mg/dL/18.0182
                            "Value in mg/dL (mmol/L to mg/dL) = value in mmol/L x 18.0182"
            ************************/
            hospenc = input(VVALUE(hosp_enc_date) 
                            || ':' || STRIP(HospEncTime_HH_496257) 
                            || ':' || STRIP(HospEncTime_MM_496257) 
                            || ':00', anydtdtm.);

            IF FirstLacateLevel_319671 IN (999, 9999) THEN first_lactate = .;
            IF SecondLactateLevel_319671 IN (999, 9999) THEN second_lactate = .;

            invalid_date = input("01-01-1900:00:00:00", anydtdtm.);
            FORMAT invalid_date datetime19.;
            IF FirstLactateDate_319671 eq invalid_date OR FirstLactateTime_HH_319671 = "99" 
            OR FirstLactateTime_MM_319671 = "99" THEN DO;
                FirstLactateDate_319671 = .;
                FirstLactateTime_HH_319671 = "";
                FirstLactateTime_MM_319671 = "";
            END;

            IF SecondLactateDate_319671 eq invalid_date OR SecondLactateTime_HH_319671 = "99" 
            OR SecondLactateTime_MM_319671 = "99" THEN DO;
                SecondLactateDate_319671 = .;
                SecondLactateTime_HH_319671 = "";
                SecondLactateTime_MM_319671 = "";
            END;

            IF FirstLactateDate_319671 NOT = . AND FirstLactateTime_HH_319671 NOT = "" AND FirstLactateTime_MM_319671 NOT = "" THEN
            firstlactate = input(VVALUE(FirstLactateDate_319671) 
                        || ":" || STRIP(FirstLactateTime_HH_319671) 
                        || ":" || STRIP(FirstLactateTime_MM_319671) 
                        || ":00", anydtdtm.);

            IF SecondLactateDate_319671 NOT = . AND SecondLactateTime_HH_319671 NOT = "" AND SecondLactateTime_MM_319671 NOT = "" THEN
            secondlactate = input(VVALUE(SecondLactateDate_319671)
                        || ":" || STRIP(SecondLactateTime_HH_319671) 
                        || ":" || STRIP(SecondLactateTime_MM_319671) 
                        || ":00", anydtdtm.);

            first_lactate_hrs = (firstlactate - hospenc)/3600;
            second_lactate_hrs = (secondlactate - hospenc)/3600;


            /* convert mg/dL to mmol/L */
            IF FirstLactateUnit_319671 = "mEq/L" THEN first_lactate = FirstLacateLevel_319671;
            ELSE IF FirstLactateUnit_319671 = "mg/dL" THEN first_lactate = FirstLacateLevel_319671 * 0.0555;
            ELSE IF FirstLactateUnit_319671 = "mmol/L" THEN first_lactate = FirstLacateLevel_319671;
            ELSE IF FirstLactateUnit_319671 = "Not available" THEN first_lactate = .;
            ELSE first_lactate = .;

            IF SecondLactateUnit_319671 = "mEq/L" THEN second_lactate = SecondLactateLevel_319671;
            ELSE IF SecondLactateUnit_319671 = "mg/dL" THEN second_lactate = SecondLactateLevel_319671 * 0.0555;
            ELSE IF SecondLactateUnit_319671 = "mmol/L" THEN second_lactate = SecondLactateLevel_319671;
            ELSE IF SecondLactateUnit_319671 = "Not available" THEN second_lactate = .;
            ELSE second_lactate = .;


            /* Identify lactate level if the draw was within 6 hours
                note: some "missing" entries are entered as 99, 999 or 9999 
            */
            if 0<FirstLacateLevel_319671<99 and first_lactate_hrs<=6 then first_lactate_draw = first_lactate;
            else first_lactate_draw = -1; /* set all missing entries to -1 for the maximum function */

            if 0<SecondLactateLevel_319671<99 and second_lactate_hrs<=6 then second_lactate_draw = second_lactate;
            else second_lactate_draw = -1;

            /* take the maximum of the two first lactates */
            lactatemax_draw = max(first_lactate_draw,second_lactate_draw);

            /* impute missing values = 1 */
            if lactatemax_draw = -1 then lactatemax_draw = 1;

            /* Elevated lactate (≥4mmol/L) during first 3 hours */
            if (first_lactate >= 4 and 0 <= first_lactate_hrs <= 3) or 
                (second_lactate >= 4 and 0 <= second_lactate_hrs <= 3) then elevateLact4_3 = 1; else elevateLact4_3 = 0;

            /* Elevated lactate (≥2mmol/L) during first 3 hours */
            if (4 > first_lactate >= 2 and 0 <= first_lactate_hrs <= 3) or 
                (4 > second_lactate >= 2 and 0 <= second_lactate_hrs <= 3) then  elevateLact2_3 = 1; else elevateLact2_3 = 0;

            /* First Lactate > 2mmol/L (limit to first 6 hours) */
            if (first_lactate >= 2) then  elevateLact2 = 1; else elevateLact2 = 0;

            /* First lactate ≥4mmol/L (limit to first 6 hours)*/
            if first_lactate >= 4 then elevateLact4 = 1; else elevateLact4 = 0;

            /* First Lactate > 2mmol/L and < 4 (limit to first 6 hours) */
            if (4 > first_lactate >= 2) then  elevateLact24= 1; else elevateLact24 = 0;


        /* Creatinine (mg/dL - Max creatinine on day 1, if patient arrived after 6pm and had no day 1 labs, day 2 labs were used) - Median (IQR) */
            /* Day 1 value */
            if creat_day1 ne . then do;
                creatinine_high = creat_day1;
                creatinine_high_unit = creatunit_day1;
            end;
            /* If missing day 1 and admission time is after 6 pm, then use day 2 value */
            if creat_day1 = . and HospEncTime_HH_496257 in(18,19,20,21,22,23,24) then do;
                creatinine_high = creat_day2;
                creatinine_high_unit = creatunit_day2;
            end;

            /* convert units */
            if creatinine_high_unit = "mol/L" then creatinine_high = creatinine_high*88.42;
            if CreatinineLowUnits_688217 = "mol/L" then creatinine_low = CreatinineLow_688217*88.42; else creatinine_low = CreatinineLow_688217;

            /* Impute missing values */
            if creatinine_high = . then creatinine_high = 1;

            IF ESRDDiag_688217 NOT = "Y" AND ComorbidCKDStage_496257 NOT = "Stage 5" THEN DO;
                IF creatinine_high >= 1.2 and (creatinine_high >= (creatinine_low * 1.5) AND creatinine_low NOT = .)
                    THEN AKI=1;
                    else AKI = 0;
            END;

        /* PaO2:FiO2 ratioc  (with imputation used for mortality model - Minimum PaO2:FiO2 ratio within 3 hours of hospital arrival ) - Median (IQR)  */
        
            /**************************** HOUR 1 ****************************/
            /* Step 1a: Standardize oxygen support to FIO2 (21% when no supplemental oxygen) for hours 1, 2, 3 
                (Amount of oxygen administered (in liters) – variable name FirstPOSuppLiters_319671) */
            if firstPOSuppLiters_319671 = "<1L" then nfio1=0.21;
            else if firstPOSuppLiters_319671 = "1L" then nfio1=0.24;
            else if firstPOSuppLiters_319671 = "2L" then nfio1=0.28;
            else if firstPOSuppLiters_319671 = "3L" then nfio1=0.32;
            else if firstPOSuppLiters_319671 = "4L" then nfio1=0.36;
            else if firstPOSuppLiters_319671 = "5L" then nfio1=0.40;
            else if firstPOSuppLiters_319671 = "6L" then nfio1=0.44;
            else if firstPOSuppLiters_319671 = "7L" then nfio1=0.48;
            else if firstPOSuppLiters_319671 = "8L" then nfio1=0.52;
            else if firstPOSuppLiters_319671 = "9L" then nfio1=0.55;
            else if firstPOSuppLiters_319671 = "10L" then nfio1=0.60;
            else if firstPOSuppLiters_319671 = "11L" then nfio1=0.65;
            else if firstPOSuppLiters_319671 = "12L" then nfio1=0.70;
            else if firstPOSuppLiters_319671 = "13L" then nfio1=0.80;
            else if firstPOSuppLiters_319671 = "14L" then nfio1=0.90;
            else if firstPOSuppLiters_319671 = "15L" then nfio1=1.00;
            else if firstPOSuppLiters_319671 = ">15L" then nfio1=1.00;
            * else if firstPOSuppLiters_319671 = "Not available" then nfio1=0.2;

            /* Step 1b: Standardize oxygen support to FIO2 (21% when no supplemental oxygen) for hours 1, 2, 3 
                (Amount of oxygen administered (in percent) – variable name FirstPOSuppPercent_319671) */
            if firstPOSuppPercent_319671="21 (Room Air)" then nfio1=0.21;
            else if firstPOSuppPercent_319671="22-30" then nfio1=0.26;
            else if firstPOSuppPercent_319671="31-40" then nfio1=0.355;
            else if firstPOSuppPercent_319671="41-50" then nfio1=0.455;
            else if firstPOSuppPercent_319671="51-60" then nfio1=0.555;
            else if firstPOSuppPercent_319671="61-70" then nfio1=0.655;
            else if firstPOSuppPercent_319671="71-80" then nfio1=0.755;
            else if firstPOSuppPercent_319671="81-90" then nfio1=0.855;
            else if firstPOSuppPercent_319671="91-100" then nfio1=0.955;
            * else if firstPOSuppPercent_319671="Not available" then nfio1=0.21;

            /* Impute = 21% for all patients not on supplemental oxygen */
            if nfio1 =. and FirstPOSupp_319671 = "No" then nfio1=0.21;

            /* Step 2: Convert Pulse Oximetry to PaO2 for hours 1, 2, 3
                (based on oxygen-hemoglobin dissociation curve) 
                (variable name FirstPO_319671) */
            if FirstPO_319671 = "70 or less" then npao1=40;
            else if  FirstPO_319671 = "71-80" then npao1=44;
            else if FirstPO_319671 = "81-90" then npao1=55;
            else if  FirstPO_319671 = "91-95" then npao1=65;
            else if FirstPO_319671 = "96-100" then npao1=100;
            * else npao1=100; 

            /* Step 4: Calculate PaO2/FIO2  (ie, “P/F ratio”) for hour 1 */
            P_F_ratio1=npao1/nfio1;

            /* Step 3: EXCLUDE Pulse Ox measurements WHERE: Pulse Ox=96%+ AND FIO2>0.21 */
            if npao1 = 100 and nfio1 > .21 then P_F_ratio1 = 9999;
            if npao1 = . or nfio1 = . then P_F_ratio1 = 99999;

            /**************************** HOUR 2 ****************************/

            /* Step 1a: Standardize oxygen support to FIO2 (21% when no supplemental oxygen) for hours 1, 2, 3 
                (Amount of oxygen administered (in liters) – variable name secondPOSuppLiters_319671) */
            if secondPOSuppLiters_319671 = "<1L" then nfio2=0.21;
            else if secondPOSuppLiters_319671 = "1L" then nfio2=0.24;
            else if secondPOSuppLiters_319671 = "2L" then nfio2=0.28;
            else if secondPOSuppLiters_319671 = "3L" then nfio2=0.32;
            else if secondPOSuppLiters_319671 = "4L" then nfio2=0.36;
            else if secondPOSuppLiters_319671 = "5L" then nfio2=0.40;
            else if secondPOSuppLiters_319671 = "6L" then nfio2=0.44;
            else if secondPOSuppLiters_319671 = "7L" then nfio2=0.48;
            else if secondPOSuppLiters_319671 = "8L" then nfio2=0.52;
            else if secondPOSuppLiters_319671 = "9L" then nfio2=0.55;
            else if secondPOSuppLiters_319671 = "10L" then nfio2=0.60;
            else if secondPOSuppLiters_319671 = "11L" then nfio2=0.65;
            else if secondPOSuppLiters_319671 = "12L" then nfio2=0.70;
            else if secondPOSuppLiters_319671 = "13L" then nfio2=0.80;
            else if secondPOSuppLiters_319671 = "14L" then nfio2=0.90;
            else if secondPOSuppLiters_319671 = "15L" then nfio2=1.00;
            else if secondPOSuppLiters_319671 = ">15L" then nfio2=1.00;
            * else if secondPOSuppLiters_319671 = "Not available" then nfio2=0.2;

            /* Step 1b: Standardize oxygen support to FIO2 (21% when no supplemental oxygen) for hours 1, 2, 3 
                (Amount of oxygen administered (in percent) – variable name secondPOSuppPercent_319671) */
            if secondPOSuppPercent_319671="21 (Room Air)" then nfio2=0.21;
            else if secondPOSuppPercent_319671="22-30" then nfio2=0.26;
            else if secondPOSuppPercent_319671="31-40" then nfio2=0.355;
            else if secondPOSuppPercent_319671="41-50" then nfio2=0.455;
            else if secondPOSuppPercent_319671="51-60" then nfio2=0.555;
            else if secondPOSuppPercent_319671="61-70" then nfio2=0.655;
            else if secondPOSuppPercent_319671="71-80" then nfio2=0.755;
            else if secondPOSuppPercent_319671="81-90" then nfio2=0.855;
            else if secondPOSuppPercent_319671="91-100" then nfio2=0.955;
            * else if secondPOSuppPercent_319671="Not available" then nfio2=0.21;
            * if nfio2 =. then nfio2=0.21;

            /* Impute = 21% for all patients not on supplemental oxygen */
            if nfio2 =. and SecondPOSupp_319671 = "No" then nfio1=0.21;

            /* Step 2: Convert Pulse Oximetry to PaO2 for hours 1, 2, 3
                (based on oxygen-hemoglobin dissociation curve) 
                (variable name secondPO_319671) */
            if secondPO_319671 = "70 or less" then npao2=40;
            else if  secondPO_319671 = "71-80" then npao2=44;
            else if secondPO_319671 = "81-90" then npao2=55;
            else if  secondPO_319671 = "91-95" then npao2=65;
            else if secondPO_319671 = "96-100" then npao2=100;
            * else npao2=100; 


            /* Step 4: Calculate PaO2/FIO2  (ie, “P/F ratio”) for hour 1 */
            P_F_ratio2=npao2/nfio2;

            /* Step 3: EXCLUDE Pulse Ox measurements WHERE: Pulse Ox=96%+ AND FIO2>0.21
                Note - since we need to do a minimum function and we also want to know the
                number that will be imputed under this step, I will set = 9999 for now */
            if npao2 = 100 and nfio2 > .21 then P_F_ratio2 = 9999;
            if npao2 = . or nfio2 = . then P_F_ratio2 = 99999;

            /**************************** HOUR 3 ****************************/

            /* Step 1a: Standardize oxygen support to FIO2 (21% when no supplemental oxygen) for hours 1, 2, 3 
                (Amount of oxygen administered (in liters) – variable name thirdPOSuppLiters_319671) */
            if thirdPOSuppLiters_319671 = "<1L" then nfio3=0.21;
            else if thirdPOSuppLiters_319671 = "1L" then nfio3=0.24;
            else if thirdPOSuppLiters_319671 = "2L" then nfio3=0.28;
            else if thirdPOSuppLiters_319671 = "3L" then nfio3=0.32;
            else if thirdPOSuppLiters_319671 = "4L" then nfio3=0.36;
            else if thirdPOSuppLiters_319671 = "5L" then nfio3=0.40;
            else if thirdPOSuppLiters_319671 = "6L" then nfio3=0.44;
            else if thirdPOSuppLiters_319671 = "7L" then nfio3=0.48;
            else if thirdPOSuppLiters_319671 = "8L" then nfio3=0.52;
            else if thirdPOSuppLiters_319671 = "9L" then nfio3=0.55;
            else if thirdPOSuppLiters_319671 = "10L" then nfio3=0.60;
            else if thirdPOSuppLiters_319671 = "11L" then nfio3=0.65;
            else if thirdPOSuppLiters_319671 = "12L" then nfio3=0.70;
            else if thirdPOSuppLiters_319671 = "13L" then nfio3=0.80;
            else if thirdPOSuppLiters_319671 = "14L" then nfio3=0.90;
            else if thirdPOSuppLiters_319671 = "15L" then nfio3=1.00;
            else if thirdPOSuppLiters_319671 = ">15L" then nfio3=1.00;
            * else if thirdPOSuppLiters_319671 = "Not available" then nfio3=0.2;

            /* Step 1b: Standardize oxygen support to FIO2 (21% when no supplemental oxygen) for hours 1, 2, 3 
                (Amount of oxygen administered (in percent) – variable name thirdPOSuppPercent_319671) */
            if thirdPOSuppPercent_319671="21 (Room Air)" then nfio3=0.21;
            else if thirdPOSuppPercent_319671="22-30" then nfio3=0.26;
            else if thirdPOSuppPercent_319671="31-40" then nfio3=0.355;
            else if thirdPOSuppPercent_319671="41-50" then nfio3=0.455;
            else if thirdPOSuppPercent_319671="51-60" then nfio3=0.555;
            else if thirdPOSuppPercent_319671="61-70" then nfio3=0.655;
            else if thirdPOSuppPercent_319671="71-80" then nfio3=0.755;
            else if thirdPOSuppPercent_319671="81-90" then nfio3=0.855;
            else if thirdPOSuppPercent_319671="91-100" then nfio3=0.955;
            * else if thirdPOSuppPercent_319671="Not available" then nfio3=0.21;
            * if nfio3 =. then nfio3=0.21;

            /* Impute = 21% for all patients not on supplemental oxygen */
            if nfio3 =. and ThirdPOSupp_319671 = "No" then nfio1=0.21;

            /* Step 2: Convert Pulse Oximetry to PaO2 for hours 1, 2, 3
                (based on oxygen-hemoglobin dissociation curve) 
                (variable name thirdPO_319671) */
            if thirdPO_319671 = "70 or less" then npao3=40;
            else if  thirdPO_319671 = "71-80" then npao3=44;
            else if thirdPO_319671 = "81-90" then npao3=55;
            else if  thirdPO_319671 = "91-95" then npao3=65;
            else if thirdPO_319671 = "96-100" then npao3=100;
            * else npao3=100; 


            /* Step 4: Calculate PaO2/FIO2  (ie, “P/F ratio”) for hour 1 */
            P_F_ratio3=npao3/nfio3; 

            /* Step 3: EXCLUDE Pulse Ox measurements WHERE: Pulse Ox=96%+ AND FIO2>0.21
                Note - since we need to do a minimum function and we also want to know the
                number that will be imputed under this step, I will set = 9999 for now */
            if npao3 = 100 and nfio3 > .21 then P_F_ratio3 = 9999;
            if npao3 = . or nfio3 = . then P_F_ratio3 = 99999;

            /*********************** FINAL STEPS ****************************/

            /* Step 5: Select the lowest eligible P/F ratio from hour 1, 2, 3  */
            ratio_min=min(P_F_ratio3,P_F_ratio2,P_F_ratio1);

            /* Step 6: For patients with no P/F ratio from hour 1, 2, 3 
            (because Pulse Ox=96+ AND FIO2=0.21) for hour 1, hour 2, AND hour 3: 
            impute  P/F ratio =300 */
            ratio_imputed = 0;
            if ratio_min = 9999 then do;
                ratio_min = 300;
                ratio_imputed = 1;
            end;
            if ratio_min = 99999 then do;
                ratio_min = 476;
                ratio_imputed = 2;
            end;
        /* Mechanical Ventilation within 6 hours - N (%)*/
            if mechvent_319671 IN ('', 'No') THEN mechvent=0; else mechvent=1;

            /*************************** 
            Mechanical ventilation in first 6 hours 
            ***************************/

            mechdate = input(VVALUE(datemechvent_319671) 
                            || ':' || STRIP(timemechvent_HH_319671) 
                            || ':' || STRIP(timemechvent_MM_319671) 
                            || ':00', anydtdtm.);

            timeto_mech = (mechdate-hospenc)/3600;

            if mechvent=1 and timeto_mech <=6 then mechvent_6hr=1;
            else mechvent_6hr=0;

        /* Altered Mental Status - N (%)*/
        if PrimDiag_688217 ne "Sepsis" and MentalSymptoms_496257 = "Yes" and MentalStatusDoc_496257 = "Yes" then alter_mental_status = 1;
        else if PrimDiag_688217 = "Sepsis" and AlteredMentalStatus_688217 = "Y" then alter_mental_status = 1;
        else alter_mental_status = 0;

        /* Predicted mortality score - Median (IQR) */
        if mortality_predicted = . then mortality_predicted = mortality_predicted_Edit;

        /* Mortality - 30 day and Day to death */
		/* ashwin paper - risk adjusted mortality final mortality model output edit sepsis and out edit*/
                IF DeathDate_471893 = mdy(1, 1, 1900) THEN DeathDate_471893=.;
                IF DateofDeath_471893 = mdy(1, 1, 1900) THEN DateofDeath_471893=.;
                IF DeathDate_547147 = mdy(1, 1, 1900) THEN DeathDate_547147=.;
                IF DeathDate_471893 ne . THEN numdeath_471893 = DATEPART(DeathDate_471893);
                IF DateofDeath_471893 ne . THEN numdeath_471893 = DATEPART(DateofDeath_471893);
                IF DeathDate_547147 ne . THEN numdeath_547147 = DATEPART(DeathDate_547147);

            if mortality_30day = . then do;
                mortality_30day = 0;
                if EndStatus_547147='Death' and 0<=INT(DATDIF(hosp_enc_date, numdeath_547147, 'ACTUAL'))<=30 then mortality_30day = 1;
                if 0<=INT(DATDIF(hosp_enc_date, numdeath_471893, 'ACTUAL'))<=30 then mortality_30day = 1;
            end;


            if DeathDate_471893 ~= . then newdeathdate = divide (DeathDate_471893, 86400) ; 
            if DateofDeath_471893 ~= . then newdeathdate = divide (DateofDeath_471893, 86400) ; 
            if DeathDate_547147 ~= . then newdeathdate = divide (DeathDate_547147, 86400) ; 
        
            if newdeathdate - hosp_enc_date = 0 then deathday1 = 1;
            else deathday1 = 0;


        /* SBP < 90 during hours 1, 2, or 3 */
            /***************************
            Minimum blood pressure in first 3 hours
            ***************************/
            /* systolic BP */
            if FirstSysBP_319671 eq "Abnormal (Less than 90 mmHg)" or
                SecondSysBP_319671 eq "Abnormal (Less than 90 mmHg)" or
                ThirdSysBP_319671 eq "Abornaml (Less than 90 mmHg)" or
            0 < FirstSysBPNum_319671 < 90 OR 0 < SecondSysBPNum_319671 < 90 OR 0 < ThirdSysBPNum_319671 < 90 then SBP90 = 1; 
            else if FirstSysBP_319671 in ('Abnormal (90mmHg to 100 mmHg)', 'Normal (101 mmHg or greater)') or
                SecondSysBP_319671 in ('Abnormal (90mmHg to 100 mmHg)', 'Normal (101 mmHg or greater)') or
                ThirdSysBP_319671 eq in ('Abnormal (90mmHg to 100 mmHg)', 'Normal (101 mmHg or greater)') or
            FirstSysBPNum_319671 >= 90 OR SecondSysBPNum_319671>= 90 OR ThirdSysBPNum_319671 >= 90 then SBP90 = 2;
            else SBP90 = 0;



    /* Management Practices */

    if other48 >= 0 and balance48 = . then balance48 = 0;
    if other48 >= 0 and ns48 = . then ns48 = 0;
    if other6 >= 0 and balance6 = . then balance6 = 0;
    if other6 >= 0 and ns6 = . then ns6 = 0;
        /* Met balanced fluid  measure - N (%) - >75% balanced fluid within 48 hours */
            IF other48 >= 1000 and 
                /* because fluid form was added on later date 12-25-21 */
                discharge_date > mdy(12,25,21) 
                
                THEN DO;
                    percent_h48 = balance48/other48;
                    IF percent_h48 >= 0.75 THEN balancemeasure48 = 1;
                    ELSE balancemeasure48 = 0;
                    litre48 = 1;

                    /* Levels of Percent Balanced Fluids - 20% intervals */
                    if percent_h48 <= 0.20 then balance_48_cat = 1;
                    else if percent_h48 <= 0.40 then balance_48_cat = 2; 
                    else if percent_h48 <= 0.60 then balance_48_cat = 3; 
                    else if percent_h48 <= 0.80 then balance_48_cat = 4; 
                    else if percent_h48 > 0.80 then balance_48_cat = 5; 

                    /* Levels of Percent Balanced Fluids - 25% intervals (Update from 9/14/2026) */
                    if percent_h48 < 0.25 then balance_48_cat_25 = 1;
                    else if percent_h48 < 0.50 then balance_48_cat_25 = 2; 
                    else if percent_h48 < 0.75 then balance_48_cat_25 = 3; 
                    else if percent_h48 >= 0.75 then balance_48_cat_25 = 4; 



                END;
                ELSE if other48 < 1000 and 
                    /* because fluid form was added on later date 12-25-21 */
                    discharge_date > mdy(12,25,21) THEN DO;
                    balancemeasure48 = 0;
                    litre48 = 0;
                END;
                ELSE DO;
                    balancemeasure48 = .;
                    litre48 = .;
                END;

            true_other48 = other48 - balance48 - ns48;


            /* Total fluid given in 24 hrs - Median (IQR) - ≥ 30ml/kg */
            /* IBW/BMI calculations, Added Calculated Body Weight - cbw */	
                if 0 < BMI_calculated <= 30 then cbw= weight;
                else if BMI_calculated > 30 then cbw = IBW;

                IF prehospfluid ne . THEN six_hr_fluid = (prehospfluid + Fluid6_30mlkg);
                ELSE six_hr_fluid = Fluid6_30mlkg;

                IF prehospfluid ne . THEN tf_hr_fluid = (prehospfluid + Fluid24_30mlkg);
                ELSE tf_hr_fluid = Fluid24_30mlkg;
                
                IF prehospfluid ne . THEN fe_hr_fluid = (prehospfluid + Fluid48_30mlkg);
                ELSE fe_hr_fluid = Fluid48_30mlkg;

                IF cbw ne 0 THEN six = six_hr_fluid / cbw; 
                IF cbw ne 0 THEN twentyfour = tf_hr_fluid / cbw;
                IF cbw ne 0 THEN fourtyeight = fe_hr_fluid / cbw;
                IF six >= 30 THEN totalfluidmeasure6 = 1; /* 2022/2023 ~50% */
                    else totalfluidmeasure6 = 0;

        /* Met balanced fluid  measure - N (%) - >75% balanced fluid within 6 hours */
            IF other6 >= 1000 and 
                /* because fluid form was added on later date 12-25-21 */
                discharge_date > mdy(12,25,21) 
                
                THEN DO;
                    percent_h6 = balance6/other6;
                
                    IF other6 > 0 and percent_h6 >= 0.75 THEN balancemeasure6 = 1;
                    ELSE balancemeasure6 = 0;
                    litre6 = 1;

                    /* Levels of Percent Balanced Fluids */
                    if percent_h6 <= 0.20 then balance_6_cat = 1;
                    else if percent_h6 <= 0.40 then balance_6_cat = 2; 
                    else if percent_h6 <= 0.60 then balance_6_cat = 3; 
                    else if percent_h6 <= 0.80 then balance_6_cat = 4; 
                    else if percent_h6 > 0.80 then balance_6_cat = 5; 

                END;
                ELSE if other6 < 1000 and 
                    /* because fluid form was added on later date 12-25-21 */
                    discharge_date > mdy(12,25,21) THEN DO;
                    balancemeasure6 = 0;
                    litre6 = 0;
                END;
                ELSE DO;
                    balancemeasure6 = .;
                    litre6 = .;
                END;

            true_other6 = other6 - balance6 - ns6;


        /* First location after ED is ICU - N (%)*/
            if FirstLevelCare_496257 = "Intensive/Critical Care" then ICU_afterED = 1; else ICU_afterED = 0;

        /* Vasopressors within 6 hours of arrival - N (%)*/
            /* ie Treated with an IV vasopressor within 3 hours of arrival (angiotensin II, dopamine, epinephrine, norepinephrine, phenylephrine, vasopressin) */
        /* Vasopressor within 3 hours */
			invalid_date = input('01-01-1900:00:00:00', anydtdtm.);
            FORMAT invalid_date datetime19.;

            IF VasoAdminDate_319671 eq invalid_date OR VasoAdminTime_HH_319671 = '99' 
                OR VasoAdminTime_MM_319671 = '99' THEN DO;
                    VasoAdminDate_319671 = .;
                    VasoAdminTime_HH_319671 = .;
                    VasoAdminTime_MM_319671 = .;
                END;

                vasoadmin1 = input(VVALUE(VasoAdminDate_319671) 
                            || ':' || STRIP(VasoAdminTime_HH_319671) 
                            || ':' || STRIP(VasoAdminTime_MM_319671) 
                            || ':00', anydtdtm.);
            

            IF SecondVasoAdminDate_319671 eq invalid_date OR SecondVasoAdminTime_HH_319671 = '99' 
                OR SecondVasoAdminTime_MM_319671 = '99' THEN DO;
                    SecondVasoAdminDate_319671 = .;
                    SecondVasoAdminTime_HH_319671 = .;
                    SecondVasoAdminTime_MM_319671 = .;
                END;

                vasoadmin2 = input(VVALUE(SecondVasoAdminDate_319671) 
                            || ':' || STRIP(SecondVasoAdminTime_HH_319671) 
                            || ':' || STRIP(SecondVasoAdminTime_MM_319671)                                                                                         
                            || ':00', anydtdtm.);
                
            /** ===== time for first and second vasopressors ======== **/
                vasotime1 = (vasoadmin1 - hospenc)/3600;
                vasotime2 = (vasoadmin2 - hospenc)/3600;

            if (0 < vasotime1 <= 2 AND VasoAdminName_319671 ne 'Midodrine' AND VasoAdminRoute_319671 in ('Central Line', 'PICC', 'Port', 'Midline', 'Peripheral IV', 'Intraosseous (IO)'))
            or (0 < vasotime2 <= 2 AND SecondVasoAdminName_319671 ne 'Midodrine' AND SecondVasoAdminRoute_319671 in ('Central Line', 'PICC', 'Port', 'Midline', 'Peripheral IV', 'Intraosseous (IO)'))
            then IVvaso_2hrs=1; else IVvaso_2hrs=0;
            
            if (0 < vasotime1 <= 3 AND VasoAdminName_319671 ne 'Midodrine')or (0 < vasotime2 <= 3 AND SecondVasoAdminName_319671 ne 'Midodrine')
            then vaso_3hrs=1; else vaso_3hrs=0;

            if (0 < vasotime1 <= 6 AND VasoAdminName_319671 ne 'Midodrine')or (0 < vasotime2 <= 6 AND SecondVasoAdminName_319671 ne 'Midodrine')
            then vaso_6hrs=1; else vaso_6hrs=0;

            /* Mean Arterial Pressure (MAP) < 65 mmHg */
            if 0 < FirstMAP_319671 < 65 OR 0 < SecondMAP_319671 < 65 OR 0 < ThirdMAP_319671 < 65 then MAP65 = 1; 
            else if FirstMAP_319671 >= 65 OR SecondMAP_319671 >= 65 OR ThirdMAP_319671 >= 65 then MAP65 = 2;
            else MAP65 = 0;

            /* Liver disease (moderate/severe) */
            if ComorbidCond19_496257='Y' then SevereLiverDisease=1; else SevereLiverDisease=0;

             /* Highest temperature */
                max_temp = 999;
                array temp FirstTemp_319671 SecondTemp_319671 ThirdTemp_319671;
                do over temp;
                    if temp = "Abnormal (Less than 35 C)" and (max_temp<=0 or max_temp = 999) then max_temp = 0;
                    if temp = "Abnormal (35 C to 36 C)" and (max_temp<=1 or max_temp = 999) then max_temp = 1;
                    if temp = "Normal (36.1 C to 37.8 C)" and (max_temp<=2 or max_temp = 999) then max_temp = 2; /* Normal Temp */
                    if temp = "Abnormal (37.9 C to 38 C)" and (max_temp<=3 or max_temp = 999) then max_temp = 3;
                    if temp = "Abnormal (38.1 C to 38.3 C)" and (max_temp<=4 or max_temp = 999) then max_temp = 4;
                    if temp = "Abnormal (38.4 C to 39.9 C)" and (max_temp<=5 or max_temp = 999) then max_temp = 5;
                    if temp = "Abnormal (40 C or greater)" and (max_temp<=6 or max_temp = 999) then max_temp = 6;
                end;

                array tempp FirstTempNum_319671 SecondTempNum_319671 ThirdTempNum_319671;
                do over tempp;
                    if .<tempp<35 and (max_temp<=0 or max_temp = 999) then max_temp = 0;
                    if 35<=tempp<=36 and (max_temp<=1 or max_temp = 999) then max_temp = 1;
                    if 36<tempp<=37.8 and (max_temp<=2 or max_temp = 999) then max_temp = 2; /* Normal Temp */
                    if 37.8<tempp<=38 and (max_temp<=3 or max_temp = 999) then max_temp = 3;
                    if 38<tempp<=38.3 and (max_temp<=4 or max_temp = 999) then max_temp = 4;
                    if 38.3<tempp<=39.9 and (max_temp<=5 or max_temp = 999) then max_temp = 5;
                    if 39.9<tempp<999 and (max_temp<=6 or max_temp = 999) then max_temp = 6;
                end;

                if max_temp = 999 then max_temp = 2; /* Impute normal temp if misiing */

            /* Highest respiratory rate in first 3 hours */
                if FirstRR_319671 in("Not available","Normal (less than 20)",'') then FirstRR_N=1;
                else if FirstRR_319671 in("Abnormal (20)","Abnormal (21)") then FirstRR_N=2;
                else if FirstRR_319671 in("Abnormal (22-24)" ) then FirstRR_N=3;
                else if FirstRR_319671 in("Abnormal (25-30)") then FirstRR_N=4;
                else if FirstRR_319671 in("Abnormal (greater than 30)") then FirstRR_N=5; 
                else FirstRR_N=1; 

                if secondRR_319671 in("Not available","Normal (less than 20)",'') then secondRR_N=1;
                else if secondRR_319671 in("Abnormal (20)","Abnormal (21)") then secondRR_N=2;
                else if secondRR_319671 in("Abnormal (22-24)" ) then secondRR_N=3;
                else if secondRR_319671 in("Abnormal (25-30)") then secondRR_N=4;
                else if secondRR_319671 in("Abnormal (greater than 30)") then secondRR_N=5; 
                else secondRR_N=1;

                if thirdRR_319671 in("Not available","Normal (less than 20)",'') then thirdRR_N=1;
                else if thirdRR_319671 in("Abnormal (20)","Abnormal (21)") then thirdRR_N=2;
                else if thirdRR_319671 in("Abnormal (22-24)" ) then thirdRR_N=3;
                else if thirdRR_319671 in("Abnormal (25-30)") then thirdRR_N=4;
                else if thirdRR_319671 in("Abnormal (greater than 30)") then thirdRR_N=5; 
                else thirdRR_N=1; 

                /* Get highest of the first 3 respiratory rate values */
                max_RR = max(FirstRR_N,secondRR_N,thirdRR_N);

            /* Highest heart rate in first 3 hours */
                if FirstHR_319671 in("Less than 60 BPM") then mHR_first = 1;
                else if FirstHR_319671 in("60 - 89 BPM", "Normal (less than 90 BPM)") then mHR_first=2;
                else if FirstHR_319671 in("90 - 100 BPM" , "Abnormal (91 - 100 BPM)" , "Abnormal (90 BPM)") then mHR_first=3;
                else if FirstHR_319671 in("101 - 124 BPM" , "Abnormal (101 - 124 BPM)") then mHR_first=4;
                else if FirstHR_319671 in("Abnormal (greater than 124 BPM)", "Greater than 124 BPM") then mHR_first=5;
                else mHR_first=0;

                if secondHR_319671 in("Less than 60 BPM") then mHR_second = 1;
                else if secondHR_319671 in("60 - 89 BPM", "Normal (less than 90 BPM)") then mHR_second=2;
                else if secondHR_319671 in("90 - 100 BPM" , "Abnormal (91 - 100 BPM)" , "Abnormal (90 BPM)") then mHR_second=3;
                else if secondHR_319671 in("101 - 124 BPM" , "Abnormal (101 - 124 BPM)") then mHR_second=4;
                else if secondHR_319671 in("Abnormal (greater than 124 BPM)", "Greater than 124 BPM") then mHR_second=5;
                else mHR_second=0;

                if thirdHR_319671 in("Less than 60 BPM") then mHR_third = 1;
                else if thirdHR_319671 in("60 - 89 BPM", "Normal (less than 90 BPM)") then mHR_third=2;
                else if thirdHR_319671 in("90 - 100 BPM" , "Abnormal (91 - 100 BPM)" , "Abnormal (90 BPM)") then mHR_third=3;
                else if thirdHR_319671 in("101 - 124 BPM" , "Abnormal (101 - 124 BPM)") then mHR_third=4;
                else if thirdHR_319671 in("Abnormal (greater than 124 BPM)", "Greater than 124 BPM") then mHR_third=5;
                else mHR_third=0;

                /** ============= using the maximum values =================== **/
                max_HR=max(mHR_third, mHR_second, mHR_first);
                if max_HR = 0 then max_HR = 2; /* if missing variable, inputted as 60 - 89 BPM (normal)*/

            /* Maximum lactate */
            /* Day 1 value */
            if lactate_day1 ne . then do;
                lactate_high = lactate_day1;
                lactate_high_unit = lactateunit_day1; 
            end;
            /* If missing day 1 and admission time is after 6 pm, then use day 2 value */
            if lactate_day1 = . and HospEncTime_HH_496257 in(18,19,20,21,22,23,24) then do;
                lactate_high = lactate_day2;
                lactate_high_unit = lactateunit_day2;
            end;
            /* convert units */
            if lactate_high_unit = "mg/dL" then lactate_high = lactate_high/9;
            /* Flag extreme values */
            if lactate_high<0.2 or lactate_high>10 then do;
                lactate_high = .;
                lactate_high_flag = 1;
            end;
            /* Impute missing values */
            if lactate_high = . then do;
                lactate_imputed = 1;
                lactate_high = 1;
            end;



            /* 30 day Mortality - Median IQR */
            if m_c3 = '30-day Mortality (from encounter date)' then mortality_30day = 1; else mortality_30day = 0;

            /* 90 day Mortality - Median IQR */
            if m_c4 = '60-day Mortality (from encounter date)' then mortality_60day = 1; else mortality_60day = 0;

            /* In Hospital Mortality (died in hospital or discharged to hospice) */
            if m_C2 = "In-Hospital Mortality or Discharged to Hospice" then mortality_hosp = 1; else mortality_hosp = 0;

            /* Ever Event - Ever require renal replacement therapy */
            if dialysis_319671 in  ("Y", "Yes") then EverRRT = 1; else EverRRT = 0;

            /* Length of Stay */
            *length_stay;


    /* Patients whos BMI were under 10 or over 100 and values have not been verified by abstractors */
    if (bmi_calculated >= 10 and bmi_calculated <= 100) or (nid in (107491, 111209, 111263, 113232, 122303, 123763, 124415, 128879, 129423, 130962, 134115, 137929, 141984, 144404, 145460, 146943, 147353, 151256 ));

run;




Data sample;
    set sample2;
    /*********************** Creating Cohort Variables ***********************/
    /* ESRD or Stage 5 CKD */
    if ESRDDiag_688217 = 'Y' or (ComorbidCKDDoc_496257 = "Yes" AND ComorbidCKDStage_496257 = "Stage 5") then renal_disease = 1; else renal_disease = 0;

    /* No Ejectionfraction <= 39% */
    if EjecFrac_496257 = "Yes" and EjecFracPerc_496257 in ("35 - 39", "Less than 35") then VentEjeFrac = 1; else VentEjeFrac = 0;

    /* No moderate/severe critical aortic stenosis */
    if AortSten_496257 = "Yes" and AortStenSev_496257 in ("Severe", "Critical") then aortstenosis=1; else aortstenosis=0;

    /* Hypoperfused */
    if map65 = 1 or vaso_3hrs = 1 or elevateLact4_3 = 1 or SBP90 = 1 then hypoperfused = 1; else hypoperfused = 0;

    /* Intermediate Lactate */
    if map65 = 2 and vaso_3hrs = 0 and elevateLact2_3 = 1 and SBP90 = 2 and hypoperfused ~= 1 then intermediate_lactate = 1; else intermediate_lactate = 0;

    /* Without specified comorbidities - No ESRD, reduced LVEF,  severe/critical aortic stenosis */
    IF renal_disease = 0 AND VentEjeFrac = 0 AND aortstenosis = 0 THEN nospecificcomorbid = 1; ELSE nospecificcomorbid = 0;

    /* With specified comorbidity - ESRD, reduced LVEF, OR severe/critical aortic stenosis */
    IF renal_disease = 1 OR VentEjeFrac = 1 OR aortstenosis = 1 THEN specificcomorbid = 1; ELSE specificcomorbid = 0;

    /* Eligible for 30 ml/kg measure (bundle measure 8) */
    if hypoperfused = 1 and nospecificcomorbid = 1 then eligible_30mlkg = 1; else eligible_30mlkg = 0;



	/* Primary (overall resuscitation): All patients who receive at least 1L of fluid  */
        if other48 >= 1000 then primarycohort = 1;
            else primarycohort = 0;

	/* Secondary (early resuscitation): All patients who receive at least 1L of fluid within 6 hours */
        if primarycohort = 1 and other6 >= 1000 then secondarycohort = 1;
            else secondarycohort = 0;
 
    /* Subgroups: (based on a priori hypotheses and FISSH results) */
        /* 1. Septic shock (on intravenous vasopressor within 2 hrs of presentation and first lactate >2 mmol/L; limit to lactate drawn within 6 hours) -> KEY subgroup
                a. Based on Sepsis-3 definition of septic shock: requiring vasopressors and lactate >2 - Answerd: DO WE WANT THIS ALSO WITHIN 3 HOURS? no 3 hour mark */
        if IVvaso_2hrs = 1 and elevateLact2 = 1 then subgroup1 = 1; else subgroup1 = 0;

        /* 2. Initiated on intravenous vasopressor within 2 hours of arrival */
        if IVvaso_2hrs = 1 then subgroup2 = 1; else subgroup2 = 0;

        /* 3. Hypotensive within 2 hours of (SBP <90, MAP <65, or on vasopressors) */
        if  SBP90 = 1 or vaso_3hrs = 1 or MAP65 = 1 then subgroup3 = 1; else subgroup3 = 0;

        /* 4. First lactate ≥4 mmol/L (with or without hypotension); limit to lactate drawn within 6 hours - Answerd: DO WE WANT THIS ALSO WITHIN 3 HOURS? no 3 hour mark  */
        if elevateLact4 = 1 then subgroup4 = 1; else subgroup4 = 0;

        /* 5. First lactate 2-4 mmol/L and no hypotension (intermediate lactate population), limit to lactate drawn within 6 hours */
        if elevateLact24 = 1 and intermediate_lactate = 1 then subgroup5 = 1; else subgroup5 = 0;

        /* 6. AKI at presentation. Use initial creatinine and existing HMS measure for AKI present on presentation (use creatinine value used in mortality model) - Answerd: WHAT CREATEININE VALUES DO YOU WANT TO CONSIDER AKI? AND DO YOU ALSO WANT TO USE MODEERATRE TO SEVERE KIDNEY DISEASE? OR STAGE 5? Use the AKI definition from organ dysfunction calculator but with creatinine on day 1 only */
        if AKI = 1 then subgroup6 = 1; else subgroup6 = 0;

        /* 7. Age ≥65 years old */
        if age65 = 1 then subgroup7 = 1; else subgroup7 = 0;

run;



/********************************************************************************************************************************************************************/
/***********************************************************************Table Creation*******************************************************************************/
/********************************************************************************************************************************************************************/
/* Create datasets where hospitals with fewer than 10 observation are dropped */
    /* 48 Hours */
        /* Dataset for primary cohort (defined above) */
        data primarycohort_data;
            set sample;
            if primarycohort = 1;
        run;

        proc sql;
            create table aim2hosp as select
            hosp, count(hosp) as N
            from primarycohort_data
            group by hosp;
        run;

        proc sql;
            create table primarycohort_data_10plus as select
            a.*,
            b.N
            from primarycohort_data a
            left join aim2hosp b on a.hosp=b.hosp;
        run;

        data primarycohort_data_10plus;
            set primarycohort_data_10plus;
            if N >= 10;
        run;

        data out.primarycohort_data_10plus;
            set primarycohort_data_10plus;
        run;

    /* 6 Hours */
        /* Dataset for primary cohort (defined above) */
        data secondarycohort_data;
            set sample;
            if secondarycohort = 1;
        run;

        proc sql;
            create table aim2hosp as select
            hosp, count(hosp) as N
            from secondarycohort_data
            group by hosp;
        run;

        proc sql;
            create table secondarycohort_data_10plus as select
            a.*,
            b.N
            from secondarycohort_data a
            left join aim2hosp b on a.hosp=b.hosp;
        run;

        data secondarycohort_data_10plus;
            set secondarycohort_data_10plus;
            if N >= 10;
        run;

            data out.secondarycohort_data_10plus;
                set secondarycohort_data_10plus;
            run;

        proc datasets library=work;
                delete cat_: con_: chi: ttest: temp_:;
        run;

/*************************************************************** Figure 1 ***************************************************************/
 ods excel file="[filepath 5]\Figure 1 Data&sysdate9..xlsx" style=HTMLblue;
    ods excel options(sheet_name='Figure 1_48' sheet_interval="proc" embedded_titles = 'yes' embedded_footnotes = 'yes');
    proc means data = primarycohort_data n nmiss mean std min p25 median p75 max;
        where other48 >= 1000;
        class balancemeasure48;
        var balance48 ns48 true_other48;
    run;

    ods excel options(sheet_name='Figure 1_6' sheet_interval="proc" embedded_titles = 'yes' embedded_footnotes = 'yes');
    proc means data = secondarycohort_data n nmiss mean std min p25 median p75 max;
        where other6 >= 1000;
        class balancemeasure6;
        var balance6 ns6 true_other6;
    run;

ods excel close;
/********************************************************************************************************************************************************************/


/* Same general tables as aim 1 but now our main outcome focus is if patients recieved 75% balanced fluids - and different cohorts for this measure */

/******************************************************** Table 1 (previously Table 2.2) ******************************************************************/
/* Table 1 (previously Table 2.2) - Patient characteristics table for primary cohort */

/* 48 Hours */
    proc datasets library=work;
            delete cat_: con_: chi: ttest: temp_:;
    run;

    /* import data details for formatted tables */
    PROC IMPORT DATAFILE="[filepath 6]\indepvar_list_details.xlsx"
                OUT=variabledetails
                DBMS=XLSX
                REPLACE;
    RUN;

    %include '[filepath 4]\(Embedded) Demographic table_EW.sas';
    %demotb(   input_dir = 		[filepath 6]\
                , input_file = 		indepvar_list.csv
                , depvar = 			balancemeasure48 /* danny - change this to your dichotomous variable */
                , srcdata = 		primarycohort_data
                , cohort = 			
                , label1 = 			greater than 75 /* update these labels. this is the label for where depvar = 1 */
                , label0 = 			less than 75 /* the label for depvar = 0s */
            );


    data table1_column1_column2;
        length varname $100.;
        set cat_con_p;
    run;

    /* delete datasets from the macro */
    proc datasets library=work;
            delete cat_: con_: chi: ttest: temp_:;
    run;


    /* Create the final table */
    proc sql; create table table1_final as select 
            a.var_order, a.var_level, a.var_name,
            b.var_category, b.var_label,
            a.y_stats, a.n_stats, a.p_value, a.all_stats,
            a.missing_stats, a.min_stats, a.max_stats
        from table1_column1_column2 a left join variabledetails b on a.var_name=b.var_name and a.var_level=b.level; 
    quit;

    /* Delete reference categories for binary variables */
    data table1_final;
        set table1_final;
    run;


/* 6 Hours */
   
    proc datasets library=work;
            delete cat_: con_: chi: ttest: temp_:;
    run;

    /* import data details for formatted tables */
    PROC IMPORT DATAFILE="[filepath 6]\indepvar_list_details.xlsx"
                OUT=variabledetails
                DBMS=XLSX
                REPLACE;
    RUN;

    %include '[filepath 4]\(Embedded) Demographic table_EW.sas';
    %demotb(   input_dir = 		[filepath 6]\
                , input_file = 		indepvar_list.csv
                , depvar = 			balancemeasure6 /* danny - change this to your dichotomous variable */
                , srcdata = 		secondarycohort_data
                , cohort = 			
                , label1 = 			greater than 75 /* update these labels. this is the label for where depvar = 1 */
                , label0 = 			less than 75 /* the label for depvar = 0s */
            );


    data table1_2_column1_column2;
        length varname $100.;
        set cat_con_p;
    run;

    /* delete datasets from the macro */
    proc datasets library=work;
            delete cat_: con_: chi: ttest: temp_:;
    run;


    /* Create the final table */
    proc sql; create table table1_2_final as select 
            a.var_order, a.var_level, a.var_name,
            b.var_category, b.var_label,
            a.y_stats, a.n_stats, a.p_value, a.all_stats,
            a.missing_stats, a.min_stats, a.max_stats
        from table1_2_column1_column2 a left join variabledetails b on a.var_name=b.var_name and a.var_level=b.level; 
    quit;

    /* Delete reference categories for binary variables */
    data table1_2_final;
        set table1_2_final;
    run;


    /* sort by variable order */
    proc sort data = table1_final;
        by var_order var_level;
    run;
    ods excel file="[filepath 5]\New Table 1 Data&sysdate9..xlsx" style=HTMLblue;
    ods excel options(sheet_name='Table1.1 Raw' sheet_interval="proc" embedded_titles = 'yes' embedded_footnotes = 'yes');

        proc print data=table1_final label;run;

        proc means data = primarycohort_data n nmiss mean std min p25 median p75 max;
            where other48 >= 1000;
            var age adl_scores charlson bmi_calculated lactate_high creatinine_high ratio_min mortality_predicted eligible_30mlkg totalfluidmeasure6 six other6 fourtyeight other48;
        run;

        proc means data = primarycohort_data n nmiss mean std min p25 median p75 max;
            where other48 >= 1000;
            class balancemeasure48;
            var age adl_scores charlson bmi_calculated lactate_high creatinine_high ratio_min mortality_predicted eligible_30mlkg totalfluidmeasure6 six other6 fourtyeight other48;
        run;

        proc ttest data = primarycohort_data;
            where other48 >= 1000;
            class balancemeasure48;
            var age adl_scores charlson bmi_calculated lactate_high creatinine_high ratio_min mortality_predicted eligible_30mlkg totalfluidmeasure6 six other6 fourtyeight other48;
        run;

    ods excel options(sheet_name='Table1.2 Raw' sheet_interval="proc" embedded_titles = 'yes' embedded_footnotes = 'yes');

        proc print data=table1_2_final label;run;

        proc means data = secondarycohort_data n nmiss mean std min p25 median p75 max;
            where other6 >= 1000;
            var age adl_scores charlson bmi_calculated lactate_high creatinine_high ratio_min mortality_predicted eligible_30mlkg totalfluidmeasure6 six other6 fourtyeight other48;
        run;

        proc means data = secondarycohort_data n nmiss mean std min p25 median p75 max;
            where other6 >= 1000;
            class balancemeasure6;
            var age adl_scores charlson bmi_calculated lactate_high creatinine_high ratio_min mortality_predicted eligible_30mlkg totalfluidmeasure6 six other6 fourtyeight other48;
        run;

        proc ttest data = secondarycohort_data;
            where other6 >= 1000;
            class balancemeasure6;
            var age adl_scores charlson bmi_calculated lactate_high creatinine_high ratio_min mortality_predicted eligible_30mlkg totalfluidmeasure6 six other6 fourtyeight other48;
        run;

    ods excel close;
/*************************************************************************************************************************************/
/* Create datasets where hospitals with fewer than 10 observation are dropped for the remaining cohorts */
    /* Subgroup 1 - Septic Shock */
    data subgroup1_data;
            set sample;
            if subgroup1 = 1;
        run;

        proc sql;
            create table aim2hosp as select
            hosp, count(hosp) as N
            from subgroup1_data
            group by hosp;
        run;

        proc sql;
            create table subgroup1_data_10plus as select
            a.*,
            b.N
            from subgroup1_data a
            left join aim2hosp b on a.hosp=b.hosp;
        run;

        data subgroup1_data_10plus;
            set subgroup1_data_10plus;
            if N >= 10;
        run;

        data out.subgroup1_data_10plus;
            set subgroup1_data_10plus;
        run;

    /* Subgroup 2 - Initiated on intravenous vasopressor within 2 hours of arrival */
    data subgroup2_data;
            set sample;
            if subgroup2 = 1;
        run;

        proc sql;
            create table aim2hosp as select
            hosp, count(hosp) as N
            from subgroup2_data
            group by hosp;
        run;

        proc sql;
            create table subgroup2_data_10plus as select
            a.*,
            b.N
            from subgroup2_data a
            left join aim2hosp b on a.hosp=b.hosp;
        run;

        data subgroup2_data_10plus;
            set subgroup2_data_10plus;
            if N >= 10;
        run;

        data out.subgroup2_data_10plus;
            set subgroup2_data_10plus;
        run;

    /* Subgroup 3 - Hypotensive within 2 hours of (SBP <90, MAP <65, or on vasopressors) */
    data subgroup3_data;
            set sample;
            if subgroup3 = 1;
        run;

        proc sql;
            create table aim2hosp as select
            hosp, count(hosp) as N
            from subgroup3_data
            group by hosp;
        run;

        proc sql;
            create table subgroup3_data_10plus as select
            a.*,
            b.N
            from subgroup3_data a
            left join aim2hosp b on a.hosp=b.hosp;
        run;

        data subgroup3_data_10plus;
            set subgroup3_data_10plus;
            if N >= 10;
        run;

        data out.subgroup3_data_10plus;
            set subgroup3_data_10plus;
        run;

    /* Subgroup 4 - First lactate ≥4 mmol/L (with or without hypotension); limit to lactate drawn within 6 hours */
    data subgroup4_data;
            set sample;
            if subgroup4 = 1;
        run;

        proc sql;
            create table aim2hosp as select
            hosp, count(hosp) as N
            from subgroup4_data
            group by hosp;
        run;

        proc sql;
            create table subgroup4_data_10plus as select
            a.*,
            b.N
            from subgroup4_data a
            left join aim2hosp b on a.hosp=b.hosp;
        run;

        data subgroup4_data_10plus;
            set subgroup4_data_10plus;
            if N >= 10;
        run;

        data out.subgroup4_data_10plus;
            set subgroup4_data_10plus;
        run;

    /* Subgroup 5 - First lactate 2-4 mmol/L and no hypotension (intermediate lactate population), limit to lactate drawn within 6 hours */
    data subgroup5_data;
            set sample;
            if subgroup5 = 1;
        run;

        proc sql;
            create table aim2hosp as select
            hosp, count(hosp) as N
            from subgroup5_data
            group by hosp;
        run;

        proc sql;
            create table subgroup5_data_10plus as select
            a.*,
            b.N
            from subgroup5_data a
            left join aim2hosp b on a.hosp=b.hosp;
        run;

        data subgroup5_data_10plus;
            set subgroup5_data_10plus;
            if N >= 10;
        run;
        data out.subgroup5_data_10plus;
            set subgroup5_data_10plus;
        run;

    /* Subgroup 6 - AKI at presentation. Use initial creatinine and existing HMS measure for AKI present on presentation (use creatinine value used in mortality model) */
    data subgroup6_data;
            set sample;
            if subgroup6 = 1;
        run;

        proc sql;
            create table aim2hosp as select
            hosp, count(hosp) as N
            from subgroup6_data
            group by hosp;
        run;

        proc sql;
            create table subgroup6_data_10plus as select
            a.*,
            b.N
            from subgroup6_data a
            left join aim2hosp b on a.hosp=b.hosp;
        run;

        data subgroup6_data_10plus;
            set subgroup6_data_10plus;
            if N >= 10;
        run;
        data out.subgroup6_data_10plus;
            set subgroup6_data_10plus;
        run;

    /* Subgroup 7 - Age ≥65 years old */
    data subgroup7_data;
            set sample;
            if subgroup7 = 1;
        run;

        proc sql;
            create table aim2hosp as select
            hosp, count(hosp) as N
            from subgroup7_data
            group by hosp;
        run;

        proc sql;
            create table subgroup7_data_10plus as select
            a.*,
            b.N
            from subgroup7_data a
            left join aim2hosp b on a.hosp=b.hosp;
        run;

        data subgroup7_data_10plus;
            set subgroup7_data_10plus;
            if N >= 10;
        run;

        data out.subgroup7_data_10plus;
            set subgroup7_data_10plus;
        run;

    



/******************************************************** Table 2 (Previously Table 2.6) ******************************************************************/
/* Table 2 (Previously Table 2.6) - running regression models to find the associations between patients recieving >= 75% balanced fluid with 30-day mortality */

/* Can't use macro's for the models because they have the macro variables for the splines */
/* Calculate splines for model */
    /* Creatinine - 5 nodes */
    proc univariate data=primarycohort_data_10plus noprint;
    var creatinine_high;
    output out=pctls5_deriv_creat pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */
    run;

    data _null5_deriv_creat;
    set pctls5_deriv_creat;
    call symput('pctls5_creat_D',catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;

    /* Lactate - 5 nodes */
    proc univariate data=primarycohort_data_10plus noprint;
    var lactate_high;
    output out=pctls5_deriv_lact pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */
    run;
    
    data _null5_deriv_lact;
    set pctls5_deriv_lact;
    call symput("pctls5_lact_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;

    /* BMI - 5 nodes */
    proc univariate data=primarycohort_data_10plus noprint;
    var bmi_calculated;
    output out=pctls5_deriv_bmi pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */
    run;
    
    data _null5_deriv_bmi;
    set pctls5_deriv_bmi;
    call symput("pctls5_bmi_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;

    /* PF Ratio - 4 nodes */
    proc univariate data=primarycohort_data_10plus noprint;
    var ratio_min;
    output out=pctls4_deriv_ratio pctlpts=5 35 65 95 pctlpre=p_; /* specify the percentiles */
    run;
    
    data _null4_deriv_ratio;
    set pctls4_deriv_ratio;
    call symput("pctls4_ratio_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;

    /* Age - 4 nodes */
    proc univariate data=primarycohort_data_10plus noprint;
    var age;
    output out=pctls4_deriv_age pctlpts=5 35 65 95 pctlpre=p_; /* specify the percentiles */
    run;
    
    data _null4_deriv_age;
    set pctls4_deriv_age;
    call symput("pctls4_age_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;
/* 48 Hrs */
    /* Primary Cohort */
    PROC GLIMMIX data=primarycohort_data_10plus METHOD=LAPLACE;
        where other48 >= 1000;
        class hosp balancemeasure48(ref = '0') male(ref='0') postacutecare(ref='0') priorhosp(ref="0") KidneyDisease(ref="0") SevereLiverDisease(ref="0") CHF(ref="0") Metastatic(ref="0") max_temp(ref="2") max_HR(ref="2") max_RR(ref="1") mechvent_6hr(ref="0") alter_mental_status(ref="0") ;
        effect spl_creatinine = spline(creatinine_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_creat_D));
        effect spl_lactate = spline(lactate_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_lact_D));
        effect spl_ratiomin = spline(ratio_min/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_ratio_D));
        effect spl_age = spline(age/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_age_D));
        effect spl_BMI = spline(bmi_calculated/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_bmi_D));
        model mortality_30day(EVENT = '1') = balancemeasure48 spl_age male postacutecare priorhosp KidneyDisease SevereLiverDisease CHF Metastatic mortality_predicted spl_BMI spl_lactate spl_creatinine KidneyDisease*spl_creatinine spl_ratiomin max_temp max_HR max_RR mechvent_6hr alter_mental_status   / CL CovB DIST=BINARY LINK=LOGIT SOLUTION ODDSRATIO(DIFF=LAST LABEL) ddfm=bw;
        RANDOM INTERCEPT / S SUBJECT=hosp TYPE=VC SOLUTION CL;
        COVTEST/ WALD;
        ods output ParameterEstimates = MP_prim ;
        ods output OddsRatios = MO_prim (keep = Label Estimate Lower Upper);
    run;

    /* Subgroup 1 - Septic Shock */
    /* Calculate splines for model */
    /* Creatinine - 5 nodes */
    proc univariate data=Subgroup1_data_10plus noprint;
    var creatinine_high;
    output out=pctls5_deriv_creat pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */
    run;

    data _null5_deriv_creat;
    set pctls5_deriv_creat;
    call symput('pctls5_creat_D',catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;

    /* Lactate - 5 nodes */
    proc univariate data=Subgroup1_data_10plus noprint;
    var lactate_high;
    output out=pctls5_deriv_lact pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */
    run;
    
    data _null5_deriv_lact;
    set pctls5_deriv_lact;
    call symput("pctls5_lact_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;

    /* BMI - 5 nodes */
    proc univariate data=Subgroup1_data_10plus noprint;
    var bmi_calculated;
    output out=pctls5_deriv_bmi pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */
    run;
    
    data _null5_deriv_bmi;
    set pctls5_deriv_bmi;
    call symput("pctls5_bmi_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;

    /* PF Ratio - 4 nodes */
    proc univariate data=Subgroup1_data_10plus noprint;
    var ratio_min;
    output out=pctls4_deriv_ratio pctlpts=5 35 65 95 pctlpre=p_; /* specify the percentiles */
    run;
    
    data _null4_deriv_ratio;
    set pctls4_deriv_ratio;
    call symput("pctls4_ratio_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;

    /* Age - 4 nodes */
    proc univariate data=Subgroup1_data_10plus noprint;
    var age;
    output out=pctls4_deriv_age pctlpts=5 35 65 95 pctlpre=p_; /* specify the percentiles */
    run;
    
    data _null4_deriv_age;
    set pctls4_deriv_age;
    call symput("pctls4_age_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;

    PROC GLIMMIX data=Subgroup1_data_10plus METHOD=LAPLACE;
        where other48 >= 1000;
        class hosp balancemeasure48(ref = '0') male(ref='0') postacutecare(ref='0') priorhosp(ref="0") KidneyDisease(ref="0") SevereLiverDisease(ref="0") CHF(ref="0") Metastatic(ref="0") max_temp(ref="2") max_HR(ref="2") max_RR(ref="1") mechvent_6hr(ref="0") alter_mental_status(ref="0") ;
        effect spl_creatinine = spline(creatinine_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_creat_D));
        effect spl_lactate = spline(lactate_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_lact_D));
        effect spl_ratiomin = spline(ratio_min/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_ratio_D));
        effect spl_age = spline(age/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_age_D));
        effect spl_BMI = spline(bmi_calculated/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_bmi_D));
        model mortality_30day(EVENT = '1') = balancemeasure48 spl_age male postacutecare priorhosp KidneyDisease SevereLiverDisease CHF Metastatic mortality_predicted spl_BMI spl_lactate spl_creatinine KidneyDisease*spl_creatinine spl_ratiomin max_temp max_HR max_RR mechvent_6hr alter_mental_status   / CL CovB DIST=BINARY LINK=LOGIT SOLUTION ODDSRATIO(DIFF=LAST LABEL) ddfm=bw;
        RANDOM INTERCEPT / S SUBJECT=hosp TYPE=VC SOLUTION CL;
        COVTEST/ WALD;
        ods output ParameterEstimates = MP_sub1 ;
        ods output OddsRatios = MO_sub1 (keep = Label Estimate Lower Upper);
    run;

    /* Subgroup 2 - Initiated on intravenous vasopressor within 2 hours of arrival */
    /* Calculate splines for model */
    /* Creatinine - 5 nodes */
    proc univariate data=Subgroup2_data_10plus noprint;
    var creatinine_high;
    output out=pctls5_deriv_creat pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */
    run;

    data _null5_deriv_creat;
    set pctls5_deriv_creat;
    call symput('pctls5_creat_D',catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;

    /* Lactate - 5 nodes */
    proc univariate data=Subgroup2_data_10plus noprint;
    var lactate_high;
    output out=pctls5_deriv_lact pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */
    run;
    
    data _null5_deriv_lact;
    set pctls5_deriv_lact;
    call symput("pctls5_lact_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;

    /* BMI - 5 nodes */
    proc univariate data=Subgroup2_data_10plus noprint;
    var bmi_calculated;
    output out=pctls5_deriv_bmi pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */
    run;
    
    data _null5_deriv_bmi;
    set pctls5_deriv_bmi;
    call symput("pctls5_bmi_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;

    /* PF Ratio - 4 nodes */
    proc univariate data=Subgroup2_data_10plus noprint;
    var ratio_min;
    output out=pctls4_deriv_ratio pctlpts=5 35 65 95 pctlpre=p_; /* specify the percentiles */
    run;
    
    data _null4_deriv_ratio;
    set pctls4_deriv_ratio;
    call symput("pctls4_ratio_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;

    /* Age - 4 nodes */
    proc univariate data=Subgroup2_data_10plus noprint;
    var age;
    output out=pctls4_deriv_age pctlpts=5 35 65 95 pctlpre=p_; /* specify the percentiles */
    run;
    
    data _null4_deriv_age;
    set pctls4_deriv_age;
    call symput("pctls4_age_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;

    PROC GLIMMIX data=Subgroup2_data_10plus METHOD=LAPLACE;
        where other48 >= 1000;
        class hosp balancemeasure48(ref = '0') male(ref='0') postacutecare(ref='0') priorhosp(ref="0") KidneyDisease(ref="0") SevereLiverDisease(ref="0") CHF(ref="0") Metastatic(ref="0") max_temp(ref="2") max_HR(ref="2") max_RR(ref="1") mechvent_6hr(ref="0") alter_mental_status(ref="0") ;
        effect spl_creatinine = spline(creatinine_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_creat_D));
        effect spl_lactate = spline(lactate_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_lact_D));
        effect spl_ratiomin = spline(ratio_min/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_ratio_D));
        effect spl_age = spline(age/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_age_D));
        effect spl_BMI = spline(bmi_calculated/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_bmi_D));
        model mortality_30day(EVENT = '1') = balancemeasure48 spl_age male postacutecare priorhosp KidneyDisease SevereLiverDisease CHF Metastatic mortality_predicted spl_BMI spl_lactate spl_creatinine KidneyDisease*spl_creatinine spl_ratiomin max_temp max_HR max_RR mechvent_6hr alter_mental_status   / CL CovB DIST=BINARY LINK=LOGIT SOLUTION ODDSRATIO(DIFF=LAST LABEL) ddfm=bw;
        RANDOM INTERCEPT / S SUBJECT=hosp TYPE=VC SOLUTION CL;
        COVTEST/ WALD;
        ods output ParameterEstimates = MP_sub2 ;
        ods output OddsRatios = MO_sub2 (keep = Label Estimate Lower Upper);
    run;

    /* Subgroup 3 - Hypotensive within 2 hours of (SBP <90, MAP <65, or on vasopressors) */
    /* Calculate splines for model */
    /* Creatinine - 5 nodes */
    proc univariate data=Subgroup3_data_10plus noprint;
    var creatinine_high;
    output out=pctls5_deriv_creat pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */
    run;

    data _null5_deriv_creat;
    set pctls5_deriv_creat;
    call symput('pctls5_creat_D',catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;

    /* Lactate - 5 nodes */
    proc univariate data=Subgroup3_data_10plus noprint;
    var lactate_high;
    output out=pctls5_deriv_lact pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */
    run;
    
    data _null5_deriv_lact;
    set pctls5_deriv_lact;
    call symput("pctls5_lact_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;

    /* BMI - 5 nodes */
    proc univariate data=Subgroup3_data_10plus noprint;
    var bmi_calculated;
    output out=pctls5_deriv_bmi pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */
    run;
    
    data _null5_deriv_bmi;
    set pctls5_deriv_bmi;
    call symput("pctls5_bmi_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;

    /* PF Ratio - 4 nodes */
    proc univariate data=Subgroup3_data_10plus noprint;
    var ratio_min;
    output out=pctls4_deriv_ratio pctlpts=5 35 65 95 pctlpre=p_; /* specify the percentiles */
    run;
    
    data _null4_deriv_ratio;
    set pctls4_deriv_ratio;
    call symput("pctls4_ratio_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;

    /* Age - 4 nodes */
    proc univariate data=Subgroup3_data_10plus noprint;
    var age;
    output out=pctls4_deriv_age pctlpts=5 35 65 95 pctlpre=p_; /* specify the percentiles */
    run;
    
    data _null4_deriv_age;
    set pctls4_deriv_age;
    call symput("pctls4_age_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;

    PROC GLIMMIX data=Subgroup3_data_10plus METHOD=LAPLACE;
        where other48 >= 1000;
        class hosp balancemeasure48(ref = '0') male(ref='0') postacutecare(ref='0') priorhosp(ref="0") KidneyDisease(ref="0") SevereLiverDisease(ref="0") CHF(ref="0") Metastatic(ref="0") max_temp(ref="2") max_HR(ref="2") max_RR(ref="1") mechvent_6hr(ref="0") alter_mental_status(ref="0") ;
        effect spl_creatinine = spline(creatinine_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_creat_D));
        effect spl_lactate = spline(lactate_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_lact_D));
        effect spl_ratiomin = spline(ratio_min/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_ratio_D));
        effect spl_age = spline(age/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_age_D));
        effect spl_BMI = spline(bmi_calculated/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_bmi_D));
        model mortality_30day(EVENT = '1') = balancemeasure48 spl_age male postacutecare priorhosp KidneyDisease SevereLiverDisease CHF Metastatic mortality_predicted spl_BMI spl_lactate spl_creatinine KidneyDisease*spl_creatinine spl_ratiomin max_temp max_HR max_RR mechvent_6hr alter_mental_status   / CL CovB DIST=BINARY LINK=LOGIT SOLUTION ODDSRATIO(DIFF=LAST LABEL) ddfm=bw;
        RANDOM INTERCEPT / S SUBJECT=hosp TYPE=VC SOLUTION CL;
        COVTEST/ WALD;
        ods output ParameterEstimates = MP_sub3 ;
        ods output OddsRatios = MO_sub3 (keep = Label Estimate Lower Upper);
    run;

    /* Subgroup 4 - First lactate ≥4 mmol/L (with or without hypotension); limit to lactate drawn within 6 hours */
    /* Calculate splines for model */
    /* Creatinine - 5 nodes */
    proc univariate data=Subgroup4_data_10plus noprint;
    var creatinine_high;
    output out=pctls5_deriv_creat pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */
    run;

    data _null5_deriv_creat;
    set pctls5_deriv_creat;
    call symput('pctls5_creat_D',catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;

    /* Lactate - 5 nodes */
    proc univariate data=Subgroup4_data_10plus noprint;
    var lactate_high;
    output out=pctls5_deriv_lact pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */
    run;
    
    data _null5_deriv_lact;
    set pctls5_deriv_lact;
    call symput("pctls5_lact_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;

    /* BMI - 5 nodes */
    proc univariate data=Subgroup4_data_10plus noprint;
    var bmi_calculated;
    output out=pctls5_deriv_bmi pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */
    run;
    
    data _null5_deriv_bmi;
    set pctls5_deriv_bmi;
    call symput("pctls5_bmi_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;

    /* PF Ratio - 4 nodes */
    proc univariate data=Subgroup4_data_10plus noprint;
    var ratio_min;
    output out=pctls4_deriv_ratio pctlpts=5 35 65 95 pctlpre=p_; /* specify the percentiles */
    run;
    
    data _null4_deriv_ratio;
    set pctls4_deriv_ratio;
    call symput("pctls4_ratio_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;

    /* Age - 4 nodes */
    proc univariate data=Subgroup4_data_10plus noprint;
    var age;
    output out=pctls4_deriv_age pctlpts=5 35 65 95 pctlpre=p_; /* specify the percentiles */
    run;
    
    data _null4_deriv_age;
    set pctls4_deriv_age;
    call symput("pctls4_age_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;

    PROC GLIMMIX data=Subgroup4_data_10plus METHOD=LAPLACE;
        where other48 >= 1000;
        class hosp balancemeasure48(ref = '0') male(ref='0') postacutecare(ref='0') priorhosp(ref="0") KidneyDisease(ref="0") SevereLiverDisease(ref="0") CHF(ref="0") Metastatic(ref="0") max_temp(ref="2") max_HR(ref="2") max_RR(ref="1") mechvent_6hr(ref="0") alter_mental_status(ref="0") ;
        effect spl_creatinine = spline(creatinine_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_creat_D));
        effect spl_lactate = spline(lactate_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_lact_D));
        effect spl_ratiomin = spline(ratio_min/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_ratio_D));
        effect spl_age = spline(age/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_age_D));
        effect spl_BMI = spline(bmi_calculated/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_bmi_D));
        model mortality_30day(EVENT = '1') = balancemeasure48 spl_age male postacutecare priorhosp KidneyDisease SevereLiverDisease CHF Metastatic mortality_predicted spl_BMI spl_lactate spl_creatinine KidneyDisease*spl_creatinine spl_ratiomin max_temp max_HR max_RR mechvent_6hr alter_mental_status   / CL CovB DIST=BINARY LINK=LOGIT SOLUTION ODDSRATIO(DIFF=LAST LABEL) ddfm=bw;
        RANDOM INTERCEPT / S SUBJECT=hosp TYPE=VC SOLUTION CL;
        COVTEST/ WALD;
        ods output ParameterEstimates = MP_sub4 ;
        ods output OddsRatios = MO_sub4 (keep = Label Estimate Lower Upper);
    run;

    /* Subgroup 5 - First lactate 2-4 mmol/L and no hypotension (intermediate lactate population), limit to lactate drawn within 6 hours */
    /* Calculate splines for model */
    /* Creatinine - 5 nodes */
    proc univariate data=Subgroup5_data_10plus noprint;
    var creatinine_high;
    output out=pctls5_deriv_creat pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */
    run;

    data _null5_deriv_creat;
    set pctls5_deriv_creat;
    call symput('pctls5_creat_D',catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;

    /* Lactate - 5 nodes */
    proc univariate data=Subgroup5_data_10plus noprint;
    var lactate_high;
    output out=pctls5_deriv_lact pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */
    run;
    
    data _null5_deriv_lact;
    set pctls5_deriv_lact;
    call symput("pctls5_lact_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;

    /* BMI - 5 nodes */
    proc univariate data=Subgroup5_data_10plus noprint;
    var bmi_calculated;
    output out=pctls5_deriv_bmi pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */
    run;
    
    data _null5_deriv_bmi;
    set pctls5_deriv_bmi;
    call symput("pctls5_bmi_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;

    /* PF Ratio - 4 nodes */
    proc univariate data=Subgroup5_data_10plus noprint;
    var ratio_min;
    output out=pctls4_deriv_ratio pctlpts=5 35 65 95 pctlpre=p_; /* specify the percentiles */
    run;
    
    data _null4_deriv_ratio;
    set pctls4_deriv_ratio;
    call symput("pctls4_ratio_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;

    /* Age - 4 nodes */
    proc univariate data=Subgroup5_data_10plus noprint;
    var age;
    output out=pctls4_deriv_age pctlpts=5 35 65 95 pctlpre=p_; /* specify the percentiles */
    run;
    
    data _null4_deriv_age;
    set pctls4_deriv_age;
    call symput("pctls4_age_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;

    PROC GLIMMIX data=Subgroup5_data_10plus METHOD=LAPLACE;
        where other48 >= 1000;
        class hosp balancemeasure48(ref = '0') male(ref='0') postacutecare(ref='0') priorhosp(ref="0") KidneyDisease(ref="0") SevereLiverDisease(ref="0") CHF(ref="0") Metastatic(ref="0") max_temp(ref="2") max_HR(ref="2") max_RR(ref="1") mechvent_6hr(ref="0") alter_mental_status(ref="0") ;
        effect spl_creatinine = spline(creatinine_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_creat_D));
        effect spl_lactate = spline(lactate_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_lact_D));
        effect spl_ratiomin = spline(ratio_min/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_ratio_D));
        effect spl_age = spline(age/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_age_D));
        effect spl_BMI = spline(bmi_calculated/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_bmi_D));
        model mortality_30day(EVENT = '1') = balancemeasure48 spl_age male postacutecare priorhosp KidneyDisease SevereLiverDisease CHF Metastatic mortality_predicted spl_BMI spl_lactate spl_creatinine KidneyDisease*spl_creatinine spl_ratiomin max_temp max_HR max_RR mechvent_6hr alter_mental_status   / CL CovB DIST=BINARY LINK=LOGIT SOLUTION ODDSRATIO(DIFF=LAST LABEL) ddfm=bw;
        RANDOM INTERCEPT / S SUBJECT=hosp TYPE=VC SOLUTION CL;
        COVTEST/ WALD;
        ods output ParameterEstimates = MP_sub5 ;
        ods output OddsRatios = MO_sub5 (keep = Label Estimate Lower Upper);
    run;

    /* Subgroup 6 - AKI at presentation. Use initial creatinine and existing HMS measure for AKI present on presentation (use creatinine value used in mortality model) */
    /* Calculate splines for model */
    /* Creatinine - 5 nodes */
    proc univariate data=Subgroup6_data_10plus noprint;
    var creatinine_high;
    output out=pctls5_deriv_creat pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */
    run;

    data _null5_deriv_creat;
    set pctls5_deriv_creat;
    call symput('pctls5_creat_D',catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;

    /* Lactate - 5 nodes */
    proc univariate data=Subgroup6_data_10plus noprint;
    var lactate_high;
    output out=pctls5_deriv_lact pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */
    run;
    
    data _null5_deriv_lact;
    set pctls5_deriv_lact;
    call symput("pctls5_lact_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;

    /* BMI - 5 nodes */
    proc univariate data=Subgroup6_data_10plus noprint;
    var bmi_calculated;
    output out=pctls5_deriv_bmi pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */
    run;
    
    data _null5_deriv_bmi;
    set pctls5_deriv_bmi;
    call symput("pctls5_bmi_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;

    /* PF Ratio - 4 nodes */
    proc univariate data=Subgroup6_data_10plus noprint;
    var ratio_min;
    output out=pctls4_deriv_ratio pctlpts=5 35 65 95 pctlpre=p_; /* specify the percentiles */
    run;
    
    data _null4_deriv_ratio;
    set pctls4_deriv_ratio;
    call symput("pctls4_ratio_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;

    /* Age - 4 nodes */
    proc univariate data=Subgroup6_data_10plus noprint;
    var age;
    output out=pctls4_deriv_age pctlpts=5 35 65 95 pctlpre=p_; /* specify the percentiles */
    run;
    
    data _null4_deriv_age;
    set pctls4_deriv_age;
    call symput("pctls4_age_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;

    PROC GLIMMIX data=Subgroup6_data_10plus METHOD=LAPLACE;
        where other48 >= 1000;
        class hosp balancemeasure48(ref = '0') male(ref='0') postacutecare(ref='0') priorhosp(ref="0") KidneyDisease(ref="0") SevereLiverDisease(ref="0") CHF(ref="0") Metastatic(ref="0") max_temp(ref="2") max_HR(ref="2") max_RR(ref="1") mechvent_6hr(ref="0") alter_mental_status(ref="0") ;
        effect spl_creatinine = spline(creatinine_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_creat_D));
        effect spl_lactate = spline(lactate_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_lact_D));
        effect spl_ratiomin = spline(ratio_min/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_ratio_D));
        effect spl_age = spline(age/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_age_D));
        effect spl_BMI = spline(bmi_calculated/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_bmi_D));
        model mortality_30day(EVENT = '1') = balancemeasure48 spl_age male postacutecare priorhosp KidneyDisease SevereLiverDisease CHF Metastatic mortality_predicted spl_BMI spl_lactate spl_creatinine KidneyDisease*spl_creatinine spl_ratiomin max_temp max_HR max_RR mechvent_6hr alter_mental_status   / CL CovB DIST=BINARY LINK=LOGIT SOLUTION ODDSRATIO(DIFF=LAST LABEL) ddfm=bw;
        RANDOM INTERCEPT / S SUBJECT=hosp TYPE=VC SOLUTION CL;
        COVTEST/ WALD;
        ods output ParameterEstimates = MP_sub6 ;
        ods output OddsRatios = MO_sub6 (keep = Label Estimate Lower Upper);
    run;

    /* Subgroup 7 - Age ≥65 years old */
    /* Calculate splines for model */
    /* Creatinine - 5 nodes */
    proc univariate data=Subgroup7_data_10plus noprint;
    var creatinine_high;
    output out=pctls5_deriv_creat pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */
    run;

    data _null5_deriv_creat;
    set pctls5_deriv_creat;
    call symput('pctls5_creat_D',catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;

    /* Lactate - 5 nodes */
    proc univariate data=Subgroup7_data_10plus noprint;
    var lactate_high;
    output out=pctls5_deriv_lact pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */
    run;
    
    data _null5_deriv_lact;
    set pctls5_deriv_lact;
    call symput("pctls5_lact_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;

    /* BMI - 5 nodes */
    proc univariate data=Subgroup7_data_10plus noprint;
    var bmi_calculated;
    output out=pctls5_deriv_bmi pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */
    run;
    
    data _null5_deriv_bmi;
    set pctls5_deriv_bmi;
    call symput("pctls5_bmi_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;

    /* PF Ratio - 4 nodes */
    proc univariate data=Subgroup7_data_10plus noprint;
    var ratio_min;
    output out=pctls4_deriv_ratio pctlpts=5 35 65 95 pctlpre=p_; /* specify the percentiles */
    run;
    
    data _null4_deriv_ratio;
    set pctls4_deriv_ratio;
    call symput("pctls4_ratio_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;

    /* Age - 4 nodes */
    proc univariate data=Subgroup7_data_10plus noprint;
    var age;
    output out=pctls4_deriv_age pctlpts=5 35 65 95 pctlpre=p_; /* specify the percentiles */
    run;
    
    data _null4_deriv_age;
    set pctls4_deriv_age;
    call symput("pctls4_age_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;

    PROC GLIMMIX data=Subgroup7_data_10plus METHOD=LAPLACE;
        where other48 >= 1000;
        class hosp balancemeasure48(ref = '0') male(ref='0') postacutecare(ref='0') priorhosp(ref="0") KidneyDisease(ref="0") SevereLiverDisease(ref="0") CHF(ref="0") Metastatic(ref="0") max_temp(ref="2") max_HR(ref="2") max_RR(ref="1") mechvent_6hr(ref="0") alter_mental_status(ref="0") ;
        effect spl_creatinine = spline(creatinine_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_creat_D));
        effect spl_lactate = spline(lactate_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_lact_D));
        effect spl_ratiomin = spline(ratio_min/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_ratio_D));
        effect spl_age = spline(age/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_age_D));
        effect spl_BMI = spline(bmi_calculated/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_bmi_D));
        model mortality_30day(EVENT = '1') = balancemeasure48 spl_age male postacutecare priorhosp KidneyDisease SevereLiverDisease CHF Metastatic mortality_predicted spl_BMI spl_lactate spl_creatinine KidneyDisease*spl_creatinine spl_ratiomin max_temp max_HR max_RR mechvent_6hr alter_mental_status   / CL CovB DIST=BINARY LINK=LOGIT SOLUTION ODDSRATIO(DIFF=LAST LABEL) ddfm=bw;
        RANDOM INTERCEPT / S SUBJECT=hosp TYPE=VC SOLUTION CL;
        COVTEST/ WALD;
        ods output ParameterEstimates = MP_sub7 ;
        ods output OddsRatios = MO_sub7 (keep = Label Estimate Lower Upper);
    run;


/* Output model parameters and ORs for each model run */

/* 48 HR Measure */
ods excel file="[filepath 5]\Table 2 48hr &sysdate9..xlsx" style=HTMLblue;

/* Primary Cohort */
ods excel options(sheet_name='Primary' sheet_interval="proc" embedded_titles = 'yes' embedded_footnotes = 'yes');
proc freq data = primarycohort_data;
    tables mortality_30day*balancemeasure48;
run;

proc print data = MO_prim; run;
proc print data = MP_prim; run;

/* Subgroup 1 */
ods excel options(sheet_name='Sub 1_' sheet_interval="proc" embedded_titles = 'yes' embedded_footnotes = 'yes');
proc freq data = subgroup1_data;
    where other48 >= 1000;
    tables mortality_30day*balancemeasure48;
run;

proc print data = MO_sub1; run;
proc print data = MP_sub1; run;

/* Subgroup 2 */
ods excel options(sheet_name='Sub 2_' sheet_interval="proc" embedded_titles = 'yes' embedded_footnotes = 'yes');
proc freq data = subgroup2_data;
    where other48 >= 1000;
    tables mortality_30day*balancemeasure48;
run;

proc print data = MO_sub2; run;
proc print data = MP_sub2; run;

/* Subgroup 3 */
ods excel options(sheet_name='Sub 3_' sheet_interval="proc" embedded_titles = 'yes' embedded_footnotes = 'yes');
proc freq data = subgroup3_data;
    where other48 >= 1000;
    tables mortality_30day*balancemeasure48;
run;

proc print data = MO_sub3; run;
proc print data = MP_sub3; run;

/* Subgroup 4 */
ods excel options(sheet_name='Sub 4_' sheet_interval="proc" embedded_titles = 'yes' embedded_footnotes = 'yes');
proc freq data = subgroup4_data;
    where other48 >= 1000;
    tables mortality_30day*balancemeasure48;
run;

proc print data = MO_sub4; run;
proc print data = MP_sub4; run;

/* Subgroup 5 */
ods excel options(sheet_name='Sub 5_' sheet_interval="proc" embedded_titles = 'yes' embedded_footnotes = 'yes');
proc freq data = subgroup5_data;
    where other48 >= 1000;
    tables mortality_30day*balancemeasure48;
run;

proc print data = MO_sub5; run;
proc print data = MP_sub5; run;

/* Subgroup 6 */
ods excel options(sheet_name='Sub 6_' sheet_interval="proc" embedded_titles = 'yes' embedded_footnotes = 'yes');
proc freq data = subgroup6_data;
    where other48 >= 1000;
    tables mortality_30day*balancemeasure48;
run;

proc print data = MO_sub6; run;
proc print data = MP_sub6; run;

/* Subgroup 7 */
ods excel options(sheet_name='Sub 7_' sheet_interval="proc" embedded_titles = 'yes' embedded_footnotes = 'yes');
proc freq data = subgroup7_data;
    where other48 >= 1000;
    tables mortality_30day*balancemeasure48;
run;

proc print data = MO_sub7; run;
proc print data = MP_sub7; run;

ods excel close;

    proc datasets library=work;
            delete so_: sp_: mo_: mp_:;
    run;


/* 6 Hrs */
    /* Primary Cohort */
    /* Calculate splines for model */
    /* Creatinine - 5 nodes */
    proc univariate data=secondarycohort_data_10plus noprint;
    var creatinine_high;
    output out=pctls5_deriv_creat pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */
    run;

    data _null5_deriv_creat;
    set pctls5_deriv_creat;
    call symput('pctls5_creat_D',catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;

    /* Lactate - 5 nodes */
    proc univariate data=secondarycohort_data_10plus noprint;
    var lactate_high;
    output out=pctls5_deriv_lact pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */
    run;
    
    data _null5_deriv_lact;
    set pctls5_deriv_lact;
    call symput("pctls5_lact_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;

    /* BMI - 5 nodes */
    proc univariate data=secondarycohort_data_10plus noprint;
    var bmi_calculated;
    output out=pctls5_deriv_bmi pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */
    run;
    
    data _null5_deriv_bmi;
    set pctls5_deriv_bmi;
    call symput("pctls5_bmi_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;

    /* PF Ratio - 4 nodes */
    proc univariate data=secondarycohort_data_10plus noprint;
    var ratio_min;
    output out=pctls4_deriv_ratio pctlpts=5 35 65 95 pctlpre=p_; /* specify the percentiles */
    run;
    
    data _null4_deriv_ratio;
    set pctls4_deriv_ratio;
    call symput("pctls4_ratio_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;

    /* Age - 4 nodes */
    proc univariate data=secondarycohort_data_10plus noprint;
    var age;
    output out=pctls4_deriv_age pctlpts=5 35 65 95 pctlpre=p_; /* specify the percentiles */
    run;
    
    data _null4_deriv_age;
    set pctls4_deriv_age;
    call symput("pctls4_age_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;

    PROC GLIMMIX data=secondarycohort_data_10plus METHOD=LAPLACE;
        where other6 >= 1000;
        class hosp balancemeasure6(ref = '0') male(ref='0') postacutecare(ref='0') priorhosp(ref="0") KidneyDisease(ref="0") SevereLiverDisease(ref="0") CHF(ref="0") Metastatic(ref="0") max_temp(ref="2") max_HR(ref="2") max_RR(ref="1") alter_mental_status(ref="0") ;
        effect spl_creatinine = spline(creatinine_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_creat_D));
        effect spl_lactate = spline(lactate_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_lact_D));
        effect spl_ratiomin = spline(ratio_min/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_ratio_D));
        effect spl_age = spline(age/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_age_D));
        effect spl_BMI = spline(bmi_calculated/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_bmi_D));
        model mortality_30day(EVENT = '1') = balancemeasure6 spl_age male postacutecare priorhosp KidneyDisease SevereLiverDisease CHF Metastatic mortality_predicted spl_BMI spl_lactate spl_creatinine KidneyDisease*spl_creatinine spl_ratiomin max_temp max_HR max_RR alter_mental_status   / CL CovB DIST=BINARY LINK=LOGIT SOLUTION ODDSRATIO(DIFF=LAST LABEL) ddfm=bw;
        RANDOM INTERCEPT / S SUBJECT=hosp TYPE=VC SOLUTION CL;
        COVTEST/ WALD;
        ods output ParameterEstimates = MP_prim ;
        ods output OddsRatios = MO_prim (keep = Label Estimate Lower Upper);
    run;

    /* Subgroup 1 - Septic Shock */
    /* Calculate splines for model */
    /* Creatinine - 5 nodes */
    proc univariate data=Subgroup1_data_10plus noprint;
    var creatinine_high;
    output out=pctls5_deriv_creat pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */
    run;

    data _null5_deriv_creat;
    set pctls5_deriv_creat;
    call symput('pctls5_creat_D',catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;

    /* Lactate - 5 nodes */
    proc univariate data=Subgroup1_data_10plus noprint;
    var lactate_high;
    output out=pctls5_deriv_lact pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */
    run;
    
    data _null5_deriv_lact;
    set pctls5_deriv_lact;
    call symput("pctls5_lact_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;

    /* BMI - 5 nodes */
    proc univariate data=Subgroup1_data_10plus noprint;
    var bmi_calculated;
    output out=pctls5_deriv_bmi pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */
    run;
    
    data _null5_deriv_bmi;
    set pctls5_deriv_bmi;
    call symput("pctls5_bmi_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;

    /* PF Ratio - 4 nodes */
    proc univariate data=Subgroup1_data_10plus noprint;
    var ratio_min;
    output out=pctls4_deriv_ratio pctlpts=5 35 65 95 pctlpre=p_; /* specify the percentiles */
    run;
    
    data _null4_deriv_ratio;
    set pctls4_deriv_ratio;
    call symput("pctls4_ratio_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;

    /* Age - 4 nodes */
    proc univariate data=Subgroup1_data_10plus noprint;
    var age;
    output out=pctls4_deriv_age pctlpts=5 35 65 95 pctlpre=p_; /* specify the percentiles */
    run;
    
    data _null4_deriv_age;
    set pctls4_deriv_age;
    call symput("pctls4_age_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;

    PROC GLIMMIX data=Subgroup1_data_10plus METHOD=LAPLACE;
        where other6 >= 1000;
        class hosp balancemeasure6(ref = '0') male(ref='0') postacutecare(ref='0') priorhosp(ref="0") KidneyDisease(ref="0") SevereLiverDisease(ref="0") CHF(ref="0") Metastatic(ref="0") max_temp(ref="2") max_HR(ref="2") max_RR(ref="1") alter_mental_status(ref="0") ;
        effect spl_creatinine = spline(creatinine_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_creat_D));
        effect spl_lactate = spline(lactate_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_lact_D));
        effect spl_ratiomin = spline(ratio_min/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_ratio_D));
        effect spl_age = spline(age/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_age_D));
        effect spl_BMI = spline(bmi_calculated/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_bmi_D));
        model mortality_30day(EVENT = '1') = balancemeasure6 spl_age male postacutecare priorhosp KidneyDisease SevereLiverDisease CHF Metastatic mortality_predicted spl_BMI spl_lactate spl_creatinine KidneyDisease*spl_creatinine spl_ratiomin max_temp max_HR max_RR alter_mental_status   / CL CovB DIST=BINARY LINK=LOGIT SOLUTION ODDSRATIO(DIFF=LAST LABEL) ddfm=bw;
        RANDOM INTERCEPT / S SUBJECT=hosp TYPE=VC SOLUTION CL;
        COVTEST/ WALD;
        ods output ParameterEstimates = MP_sub1 ;
        ods output OddsRatios = MO_sub1 (keep = Label Estimate Lower Upper);
    run;

    /* Subgroup 2 - Initiated on intravenous vasopressor within 2 hours of arrival */
    /* Calculate splines for model */
    /* Creatinine - 5 nodes */
    proc univariate data=Subgroup2_data_10plus noprint;
    var creatinine_high;
    output out=pctls5_deriv_creat pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */
    run;

    data _null5_deriv_creat;
    set pctls5_deriv_creat;
    call symput('pctls5_creat_D',catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;

    /* Lactate - 5 nodes */
    proc univariate data=Subgroup2_data_10plus noprint;
    var lactate_high;
    output out=pctls5_deriv_lact pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */
    run;
    
    data _null5_deriv_lact;
    set pctls5_deriv_lact;
    call symput("pctls5_lact_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;

    /* BMI - 5 nodes */
    proc univariate data=Subgroup2_data_10plus noprint;
    var bmi_calculated;
    output out=pctls5_deriv_bmi pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */
    run;
    
    data _null5_deriv_bmi;
    set pctls5_deriv_bmi;
    call symput("pctls5_bmi_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;

    /* PF Ratio - 4 nodes */
    proc univariate data=Subgroup2_data_10plus noprint;
    var ratio_min;
    output out=pctls4_deriv_ratio pctlpts=5 35 65 95 pctlpre=p_; /* specify the percentiles */
    run;
    
    data _null4_deriv_ratio;
    set pctls4_deriv_ratio;
    call symput("pctls4_ratio_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;

    /* Age - 4 nodes */
    proc univariate data=Subgroup2_data_10plus noprint;
    var age;
    output out=pctls4_deriv_age pctlpts=5 35 65 95 pctlpre=p_; /* specify the percentiles */
    run;
    
    data _null4_deriv_age;
    set pctls4_deriv_age;
    call symput("pctls4_age_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;

    PROC GLIMMIX data=Subgroup2_data_10plus METHOD=LAPLACE;
        where other6 >= 1000;
        class hosp balancemeasure6(ref = '0') male(ref='0') postacutecare(ref='0') priorhosp(ref="0") KidneyDisease(ref="0") SevereLiverDisease(ref="0") CHF(ref="0") Metastatic(ref="0") max_temp(ref="2") max_HR(ref="2") max_RR(ref="1") alter_mental_status(ref="0") ;
        effect spl_creatinine = spline(creatinine_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_creat_D));
        effect spl_lactate = spline(lactate_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_lact_D));
        effect spl_ratiomin = spline(ratio_min/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_ratio_D));
        effect spl_age = spline(age/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_age_D));
        effect spl_BMI = spline(bmi_calculated/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_bmi_D));
        model mortality_30day(EVENT = '1') = balancemeasure6 spl_age male postacutecare priorhosp KidneyDisease SevereLiverDisease CHF Metastatic mortality_predicted spl_BMI spl_lactate spl_creatinine KidneyDisease*spl_creatinine spl_ratiomin max_temp max_HR max_RR alter_mental_status   / CL CovB DIST=BINARY LINK=LOGIT SOLUTION ODDSRATIO(DIFF=LAST LABEL) ddfm=bw;
        RANDOM INTERCEPT / S SUBJECT=hosp TYPE=VC SOLUTION CL;
        COVTEST/ WALD;
        ods output ParameterEstimates = MP_sub2 ;
        ods output OddsRatios = MO_sub2 (keep = Label Estimate Lower Upper);
    run;

    /* Subgroup 3 - Hypotensive within 2 hours of (SBP <90, MAP <65, or on vasopressors) */
    /* Calculate splines for model */
    /* Creatinine - 5 nodes */
    proc univariate data=Subgroup3_data_10plus noprint;
    var creatinine_high;
    output out=pctls5_deriv_creat pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */
    run;

    data _null5_deriv_creat;
    set pctls5_deriv_creat;
    call symput('pctls5_creat_D',catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;

    /* Lactate - 5 nodes */
    proc univariate data=Subgroup3_data_10plus noprint;
    var lactate_high;
    output out=pctls5_deriv_lact pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */
    run;
    
    data _null5_deriv_lact;
    set pctls5_deriv_lact;
    call symput("pctls5_lact_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;

    /* BMI - 5 nodes */
    proc univariate data=Subgroup3_data_10plus noprint;
    var bmi_calculated;
    output out=pctls5_deriv_bmi pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */
    run;
    
    data _null5_deriv_bmi;
    set pctls5_deriv_bmi;
    call symput("pctls5_bmi_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;

    /* PF Ratio - 4 nodes */
    proc univariate data=Subgroup3_data_10plus noprint;
    var ratio_min;
    output out=pctls4_deriv_ratio pctlpts=5 35 65 95 pctlpre=p_; /* specify the percentiles */
    run;
    
    data _null4_deriv_ratio;
    set pctls4_deriv_ratio;
    call symput("pctls4_ratio_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;

    /* Age - 4 nodes */
    proc univariate data=Subgroup3_data_10plus noprint;
    var age;
    output out=pctls4_deriv_age pctlpts=5 35 65 95 pctlpre=p_; /* specify the percentiles */
    run;
    
    data _null4_deriv_age;
    set pctls4_deriv_age;
    call symput("pctls4_age_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;

    PROC GLIMMIX data=Subgroup3_data_10plus METHOD=LAPLACE;
        where other6 >= 1000;
        class hosp balancemeasure6(ref = '0') male(ref='0') postacutecare(ref='0') priorhosp(ref="0") KidneyDisease(ref="0") SevereLiverDisease(ref="0") CHF(ref="0") Metastatic(ref="0") max_temp(ref="2") max_HR(ref="2") max_RR(ref="1") alter_mental_status(ref="0") ;
        effect spl_creatinine = spline(creatinine_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_creat_D));
        effect spl_lactate = spline(lactate_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_lact_D));
        effect spl_ratiomin = spline(ratio_min/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_ratio_D));
        effect spl_age = spline(age/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_age_D));
        effect spl_BMI = spline(bmi_calculated/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_bmi_D));
        model mortality_30day(EVENT = '1') = balancemeasure6 spl_age male postacutecare priorhosp KidneyDisease SevereLiverDisease CHF Metastatic mortality_predicted spl_BMI spl_lactate spl_creatinine KidneyDisease*spl_creatinine spl_ratiomin max_temp max_HR max_RR alter_mental_status   / CL CovB DIST=BINARY LINK=LOGIT SOLUTION ODDSRATIO(DIFF=LAST LABEL) ddfm=bw;
        RANDOM INTERCEPT / S SUBJECT=hosp TYPE=VC SOLUTION CL;
        COVTEST/ WALD;
        ods output ParameterEstimates = MP_sub3 ;
        ods output OddsRatios = MO_sub3 (keep = Label Estimate Lower Upper);
    run;

    /* Subgroup 4 - First lactate ≥4 mmol/L (with or without hypotension); limit to lactate drawn within 6 hours */
    /* Calculate splines for model */
    /* Creatinine - 5 nodes */
    proc univariate data=Subgroup4_data_10plus noprint;
    var creatinine_high;
    output out=pctls5_deriv_creat pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */
    run;

    data _null5_deriv_creat;
    set pctls5_deriv_creat;
    call symput('pctls5_creat_D',catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;

    /* Lactate - 5 nodes */
    proc univariate data=Subgroup4_data_10plus noprint;
    var lactate_high;
    output out=pctls5_deriv_lact pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */
    run;
    
    data _null5_deriv_lact;
    set pctls5_deriv_lact;
    call symput("pctls5_lact_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;

    /* BMI - 5 nodes */
    proc univariate data=Subgroup4_data_10plus noprint;
    var bmi_calculated;
    output out=pctls5_deriv_bmi pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */
    run;
    
    data _null5_deriv_bmi;
    set pctls5_deriv_bmi;
    call symput("pctls5_bmi_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;

    /* PF Ratio - 4 nodes */
    proc univariate data=Subgroup4_data_10plus noprint;
    var ratio_min;
    output out=pctls4_deriv_ratio pctlpts=5 35 65 95 pctlpre=p_; /* specify the percentiles */
    run;
    
    data _null4_deriv_ratio;
    set pctls4_deriv_ratio;
    call symput("pctls4_ratio_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;

    /* Age - 4 nodes */
    proc univariate data=Subgroup4_data_10plus noprint;
    var age;
    output out=pctls4_deriv_age pctlpts=5 35 65 95 pctlpre=p_; /* specify the percentiles */
    run;
    
    data _null4_deriv_age;
    set pctls4_deriv_age;
    call symput("pctls4_age_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;

    PROC GLIMMIX data=Subgroup4_data_10plus METHOD=LAPLACE;
        where other6 >= 1000;
        class hosp balancemeasure6(ref = '0') male(ref='0') postacutecare(ref='0') priorhosp(ref="0") KidneyDisease(ref="0") SevereLiverDisease(ref="0") CHF(ref="0") Metastatic(ref="0") max_temp(ref="2") max_HR(ref="2") max_RR(ref="1") alter_mental_status(ref="0") ;
        effect spl_creatinine = spline(creatinine_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_creat_D));
        effect spl_lactate = spline(lactate_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_lact_D));
        effect spl_ratiomin = spline(ratio_min/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_ratio_D));
        effect spl_age = spline(age/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_age_D));
        effect spl_BMI = spline(bmi_calculated/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_bmi_D));
        model mortality_30day(EVENT = '1') = balancemeasure6 spl_age male postacutecare priorhosp KidneyDisease SevereLiverDisease CHF Metastatic mortality_predicted spl_BMI spl_lactate spl_creatinine KidneyDisease*spl_creatinine spl_ratiomin max_temp max_HR max_RR  alter_mental_status   / CL CovB DIST=BINARY LINK=LOGIT SOLUTION ODDSRATIO(DIFF=LAST LABEL) ddfm=bw;
        RANDOM INTERCEPT / S SUBJECT=hosp TYPE=VC SOLUTION CL;
        COVTEST/ WALD;
        ods output ParameterEstimates = MP_sub4 ;
        ods output OddsRatios = MO_sub4 (keep = Label Estimate Lower Upper);
    run;

    /* Subgroup 5 - First lactate 2-4 mmol/L and no hypotension (intermediate lactate population), limit to lactate drawn within 6 hours */
    /* Calculate splines for model */
    /* Creatinine - 5 nodes */
    proc univariate data=Subgroup5_data_10plus noprint;
    var creatinine_high;
    output out=pctls5_deriv_creat pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */
    run;

    data _null5_deriv_creat;
    set pctls5_deriv_creat;
    call symput('pctls5_creat_D',catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;

    /* Lactate - 5 nodes */
    proc univariate data=Subgroup5_data_10plus noprint;
    var lactate_high;
    output out=pctls5_deriv_lact pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */
    run;
    
    data _null5_deriv_lact;
    set pctls5_deriv_lact;
    call symput("pctls5_lact_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;

    /* BMI - 5 nodes */
    proc univariate data=Subgroup5_data_10plus noprint;
    var bmi_calculated;
    output out=pctls5_deriv_bmi pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */
    run;
    
    data _null5_deriv_bmi;
    set pctls5_deriv_bmi;
    call symput("pctls5_bmi_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;

    /* PF Ratio - 4 nodes */
    proc univariate data=Subgroup5_data_10plus noprint;
    var ratio_min;
    output out=pctls4_deriv_ratio pctlpts=5 35 65 95 pctlpre=p_; /* specify the percentiles */
    run;
    
    data _null4_deriv_ratio;
    set pctls4_deriv_ratio;
    call symput("pctls4_ratio_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;

    /* Age - 4 nodes */
    proc univariate data=Subgroup5_data_10plus noprint;
    var age;
    output out=pctls4_deriv_age pctlpts=5 35 65 95 pctlpre=p_; /* specify the percentiles */
    run;
    
    data _null4_deriv_age;
    set pctls4_deriv_age;
    call symput("pctls4_age_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;

    PROC GLIMMIX data=Subgroup5_data_10plus METHOD=LAPLACE;
        where other6 >= 1000;
        class hosp balancemeasure6(ref = '0') male(ref='0') postacutecare(ref='0') priorhosp(ref="0") KidneyDisease(ref="0") SevereLiverDisease(ref="0") CHF(ref="0") Metastatic(ref="0") max_temp(ref="2") max_HR(ref="2") max_RR(ref="1") alter_mental_status(ref="0") ;
        effect spl_creatinine = spline(creatinine_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_creat_D));
        effect spl_lactate = spline(lactate_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_lact_D));
        effect spl_ratiomin = spline(ratio_min/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_ratio_D));
        effect spl_age = spline(age/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_age_D));
        effect spl_BMI = spline(bmi_calculated/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_bmi_D));
        model mortality_30day(EVENT = '1') = balancemeasure6 spl_age male postacutecare priorhosp KidneyDisease SevereLiverDisease CHF Metastatic mortality_predicted spl_BMI spl_lactate spl_creatinine KidneyDisease*spl_creatinine spl_ratiomin max_temp max_HR max_RR alter_mental_status   / CL CovB DIST=BINARY LINK=LOGIT SOLUTION ODDSRATIO(DIFF=LAST LABEL) ddfm=bw;
        RANDOM INTERCEPT / S SUBJECT=hosp TYPE=VC SOLUTION CL;
        COVTEST/ WALD;
        ods output ParameterEstimates = MP_sub5 ;
        ods output OddsRatios = MO_sub5 (keep = Label Estimate Lower Upper);
    run;

    /* Subgroup 6 - AKI at presentation. Use initial creatinine and existing HMS measure for AKI present on presentation (use creatinine value used in mortality model) */
    /* Calculate splines for model */
    /* Creatinine - 5 nodes */
    proc univariate data=Subgroup6_data_10plus noprint;
    var creatinine_high;
    output out=pctls5_deriv_creat pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */
    run;

    data _null5_deriv_creat;
    set pctls5_deriv_creat;
    call symput('pctls5_creat_D',catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;

    /* Lactate - 5 nodes */
    proc univariate data=Subgroup6_data_10plus noprint;
    var lactate_high;
    output out=pctls5_deriv_lact pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */
    run;
    
    data _null5_deriv_lact;
    set pctls5_deriv_lact;
    call symput("pctls5_lact_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;

    /* BMI - 5 nodes */
    proc univariate data=Subgroup6_data_10plus noprint;
    var bmi_calculated;
    output out=pctls5_deriv_bmi pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */
    run;
    
    data _null5_deriv_bmi;
    set pctls5_deriv_bmi;
    call symput("pctls5_bmi_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;

    /* PF Ratio - 4 nodes */
    proc univariate data=Subgroup6_data_10plus noprint;
    var ratio_min;
    output out=pctls4_deriv_ratio pctlpts=5 35 65 95 pctlpre=p_; /* specify the percentiles */
    run;
    
    data _null4_deriv_ratio;
    set pctls4_deriv_ratio;
    call symput("pctls4_ratio_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;

    /* Age - 4 nodes */
    proc univariate data=Subgroup6_data_10plus noprint;
    var age;
    output out=pctls4_deriv_age pctlpts=5 35 65 95 pctlpre=p_; /* specify the percentiles */
    run;
    
    data _null4_deriv_age;
    set pctls4_deriv_age;
    call symput("pctls4_age_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;

    PROC GLIMMIX data=Subgroup6_data_10plus METHOD=LAPLACE;
        where other6 >= 1000;
        class hosp balancemeasure6(ref = '0') male(ref='0') postacutecare(ref='0') priorhosp(ref="0") KidneyDisease(ref="0") SevereLiverDisease(ref="0") CHF(ref="0") Metastatic(ref="0") max_temp(ref="2") max_HR(ref="2") max_RR(ref="1") alter_mental_status(ref="0") ;
        effect spl_creatinine = spline(creatinine_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_creat_D));
        effect spl_lactate = spline(lactate_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_lact_D));
        effect spl_ratiomin = spline(ratio_min/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_ratio_D));
        effect spl_age = spline(age/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_age_D));
        effect spl_BMI = spline(bmi_calculated/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_bmi_D));
        model mortality_30day(EVENT = '1') = balancemeasure6 spl_age male postacutecare priorhosp KidneyDisease SevereLiverDisease CHF Metastatic mortality_predicted spl_BMI spl_lactate spl_creatinine KidneyDisease*spl_creatinine spl_ratiomin max_temp max_HR max_RR alter_mental_status   / CL CovB DIST=BINARY LINK=LOGIT SOLUTION ODDSRATIO(DIFF=LAST LABEL) ddfm=bw;
        RANDOM INTERCEPT / S SUBJECT=hosp TYPE=VC SOLUTION CL;
        COVTEST/ WALD;
        ods output ParameterEstimates = MP_sub6 ;
        ods output OddsRatios = MO_sub6 (keep = Label Estimate Lower Upper);
    run;

    /* Subgroup 7 - Age ≥65 years old */
    /* Calculate splines for model */
    /* Creatinine - 5 nodes */
    proc univariate data=Subgroup7_data_10plus noprint;
    var creatinine_high;
    output out=pctls5_deriv_creat pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */
    run;

    data _null5_deriv_creat;
    set pctls5_deriv_creat;
    call symput('pctls5_creat_D',catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;

    /* Lactate - 5 nodes */
    proc univariate data=Subgroup7_data_10plus noprint;
    var lactate_high;
    output out=pctls5_deriv_lact pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */
    run;
    
    data _null5_deriv_lact;
    set pctls5_deriv_lact;
    call symput("pctls5_lact_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;

    /* BMI - 5 nodes */
    proc univariate data=Subgroup7_data_10plus noprint;
    var bmi_calculated;
    output out=pctls5_deriv_bmi pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */
    run;
    
    data _null5_deriv_bmi;
    set pctls5_deriv_bmi;
    call symput("pctls5_bmi_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;

    /* PF Ratio - 4 nodes */
    proc univariate data=Subgroup7_data_10plus noprint;
    var ratio_min;
    output out=pctls4_deriv_ratio pctlpts=5 35 65 95 pctlpre=p_; /* specify the percentiles */
    run;
    
    data _null4_deriv_ratio;
    set pctls4_deriv_ratio;
    call symput("pctls4_ratio_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;

    /* Age - 4 nodes */
    proc univariate data=Subgroup7_data_10plus noprint;
    var age;
    output out=pctls4_deriv_age pctlpts=5 35 65 95 pctlpre=p_; /* specify the percentiles */
    run;
    
    data _null4_deriv_age;
    set pctls4_deriv_age;
    call symput("pctls4_age_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;

    PROC GLIMMIX data=Subgroup7_data_10plus METHOD=LAPLACE;
        where other6 >= 1000;
        class hosp balancemeasure6(ref = '0') male(ref='0') postacutecare(ref='0') priorhosp(ref="0") KidneyDisease(ref="0") SevereLiverDisease(ref="0") CHF(ref="0") Metastatic(ref="0") max_temp(ref="2") max_HR(ref="2") max_RR(ref="1") alter_mental_status(ref="0") ;
        effect spl_creatinine = spline(creatinine_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_creat_D));
        effect spl_lactate = spline(lactate_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_lact_D));
        effect spl_ratiomin = spline(ratio_min/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_ratio_D));
        effect spl_age = spline(age/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_age_D));
        effect spl_BMI = spline(bmi_calculated/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_bmi_D));
        model mortality_30day(EVENT = '1') = balancemeasure6 spl_age male postacutecare priorhosp KidneyDisease SevereLiverDisease CHF Metastatic mortality_predicted spl_BMI spl_lactate spl_creatinine KidneyDisease*spl_creatinine spl_ratiomin max_temp max_HR max_RR alter_mental_status   / CL CovB DIST=BINARY LINK=LOGIT SOLUTION ODDSRATIO(DIFF=LAST LABEL) ddfm=bw;
        RANDOM INTERCEPT / S SUBJECT=hosp TYPE=VC SOLUTION CL;
        COVTEST/ WALD;
        ods output ParameterEstimates = MP_sub7 ;
        ods output OddsRatios = MO_sub7 (keep = Label Estimate Lower Upper);
    run;


/* Output model parameters and ORs for each model run */

/* 48 HR Measure */
ods excel file="[filepath 5]\Table 2 6hr &sysdate9..xlsx" style=HTMLblue;

/* Primary Cohort */
ods excel options(sheet_name='Primary' sheet_interval="proc" embedded_titles = 'yes' embedded_footnotes = 'yes');
proc freq data = secondarycohort_data;
    tables mortality_30day*balancemeasure6;
run;

proc print data = MO_prim; run;
proc print data = MP_prim; run;

/* Subgroup 1 */
ods excel options(sheet_name='Sub 1_' sheet_interval="proc" embedded_titles = 'yes' embedded_footnotes = 'yes');
proc freq data = subgroup1_data;
    where other6 >= 1000;
    tables mortality_30day*balancemeasure6;
run;

proc print data = MO_sub1; run;
proc print data = MP_sub1; run;

/* Subgroup 2 */
ods excel options(sheet_name='Sub 2_' sheet_interval="proc" embedded_titles = 'yes' embedded_footnotes = 'yes');
proc freq data = subgroup2_data;
    where other6 >= 1000;
    tables mortality_30day*balancemeasure6;
run;

proc print data = MO_sub2; run;
proc print data = MP_sub2; run;

/* Subgroup 3 */
ods excel options(sheet_name='Sub 3_' sheet_interval="proc" embedded_titles = 'yes' embedded_footnotes = 'yes');
proc freq data = subgroup3_data;
    where other6 >= 1000;
    tables mortality_30day*balancemeasure6;
run;

proc print data = MO_sub3; run;
proc print data = MP_sub3; run;

/* Subgroup 4 */
ods excel options(sheet_name='Sub 4_' sheet_interval="proc" embedded_titles = 'yes' embedded_footnotes = 'yes');
proc freq data = subgroup4_data;
    where other6 >= 1000;
    tables mortality_30day*balancemeasure6;
run;

proc print data = MO_sub4; run;
proc print data = MP_sub4; run;

/* Subgroup 5 */
ods excel options(sheet_name='Sub 5_' sheet_interval="proc" embedded_titles = 'yes' embedded_footnotes = 'yes');
proc freq data = subgroup5_data;
    where other6 >= 1000;
    tables mortality_30day*balancemeasure6;
run;

proc print data = MO_sub5; run;
proc print data = MP_sub5; run;

/* Subgroup 6 */
ods excel options(sheet_name='Sub 6_' sheet_interval="proc" embedded_titles = 'yes' embedded_footnotes = 'yes');
proc freq data = subgroup6_data;
    where other6 >= 1000;
    tables mortality_30day*balancemeasure6;
run;

proc print data = MO_sub6; run;
proc print data = MP_sub6; run;

/* Subgroup 7 */
ods excel options(sheet_name='Sub 7_' sheet_interval="proc" embedded_titles = 'yes' embedded_footnotes = 'yes');
proc freq data = subgroup7_data;
    where other6 >= 1000;
    tables mortality_30day*balancemeasure6;
run;

proc print data = MO_sub7; run;
proc print data = MP_sub7; run;

ods excel close;

    proc datasets library=work;
            delete so_: sp_: mo_: mp_:;
    run;


/*************************************************************************************************************************************/

/******************************************************** Table 3 ******************************************************************/
/* Secondary outcomes Association of receiving ≥75% balanced fluid with secondary outcomes  
For the manuscript, we are using only the multi-level regression models with 30-day mortality as the dependent outcome and receipt of ≥75% balanced fluid as the main 
independent variable, adjusting for patient level covariates in eTable 1 above */
/* Calculate splines for model */
    /* Creatinine - 5 nodes */
    proc univariate data=primarycohort_data_10plus noprint;
    var creatinine_high;
    output out=pctls5_deriv_creat pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */
    run;

    data _null5_deriv_creat;
    set pctls5_deriv_creat;
    call symput('pctls5_creat_D',catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;

    /* Lactate - 5 nodes */
    proc univariate data=primarycohort_data_10plus noprint;
    var lactate_high;
    output out=pctls5_deriv_lact pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */
    run;
    
    data _null5_deriv_lact;
    set pctls5_deriv_lact;
    call symput("pctls5_lact_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;

    /* BMI - 5 nodes */
    proc univariate data=primarycohort_data_10plus noprint;
    var bmi_calculated;
    output out=pctls5_deriv_bmi pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */
    run;
    
    data _null5_deriv_bmi;
    set pctls5_deriv_bmi;
    call symput("pctls5_bmi_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;

    /* PF Ratio - 4 nodes */
    proc univariate data=primarycohort_data_10plus noprint;
    var ratio_min;
    output out=pctls4_deriv_ratio pctlpts=5 35 65 95 pctlpre=p_; /* specify the percentiles */
    run;
    
    data _null4_deriv_ratio;
    set pctls4_deriv_ratio;
    call symput("pctls4_ratio_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;

    /* Age - 4 nodes */
    proc univariate data=primarycohort_data_10plus noprint;
    var age;
    output out=pctls4_deriv_age pctlpts=5 35 65 95 pctlpre=p_; /* specify the percentiles */
    run;
    
    data _null4_deriv_age;
    set pctls4_deriv_age;
    call symput("pctls4_age_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;

ods excel file="[filepath 5]\Table 3 &sysdate9..xlsx" style=HTMLblue;

/* Primary - 48 Hours*/
    /* 30 day Mortality */
    *Same as table 2;

    /* In-hospital Mortality */
    ods excel options(sheet_name='Hosp Mort48' sheet_interval="proc" embedded_titles = 'yes' embedded_footnotes = 'yes');
    proc freq data = primarycohort_data;
        where other48 >= 1000;
        tables mortality_hosp*balancemeasure48;
    run;
    PROC GLIMMIX data=primarycohort_data_10plus METHOD=LAPLACE;
        where other48 >= 1000;
        class hosp balancemeasure48(ref = '0') male(ref='0') postacutecare(ref='0') priorhosp(ref="0") KidneyDisease(ref="0") SevereLiverDisease(ref="0") CHF(ref="0") Metastatic(ref="0") max_temp(ref="2") max_HR(ref="2") max_RR(ref="1") mechvent_6hr(ref="0") alter_mental_status(ref="0") ;
        effect spl_creatinine = spline(creatinine_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_creat_D));
        effect spl_lactate = spline(lactate_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_lact_D));
        effect spl_ratiomin = spline(ratio_min/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_ratio_D));
        effect spl_age = spline(age/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_age_D));
        effect spl_BMI = spline(bmi_calculated/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_bmi_D));
        model mortality_hosp(EVENT = '1') = balancemeasure48 spl_age male postacutecare priorhosp KidneyDisease SevereLiverDisease CHF Metastatic mortality_predicted spl_BMI spl_lactate spl_creatinine KidneyDisease*spl_creatinine spl_ratiomin max_temp max_HR max_RR mechvent_6hr alter_mental_status   / CL CovB DIST=BINARY LINK=LOGIT SOLUTION ODDSRATIO(DIFF=LAST LABEL) ddfm=bw;
        RANDOM INTERCEPT / S SUBJECT=hosp TYPE=VC SOLUTION CL;
        COVTEST/ WALD;
        ods output ParameterEstimates = MP_hospmort ;
        ods output OddsRatios = MO_hospmort (keep = Label Estimate Lower Upper);
    run;

    /* LOS */
    ods excel options(sheet_name='LOS48' sheet_interval="proc" embedded_titles = 'yes' embedded_footnotes = 'yes');
    proc means data = primarycohort_data n nmiss mean std min p25 median p75 max;
        where other48 >= 1000;
        class balancemeasure48;
        var length_stay;
    run;
    PROC GLIMMIX data=primarycohort_data_10plus METHOD=LAPLACE;
        where other48 >= 1000;
        effect 	spl_creatinine = spline(creatinine_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_creat_D));
        effect	spl_lactate = spline(lactate_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_lact_D));
        effect	spl_ratiomin = spline(ratio_min/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_ratio_D));
        effect	spl_age = spline(age/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_age_D));
        effect	spl_BMI = spline(bmi_calculated/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_bmi_D));
        class hosp balancemeasure48(ref = '0')  male(ref='0') postacutecare(ref='0') priorhosp(ref="0") KidneyDisease(ref="0") SevereLiverDisease(ref="0") CHF(ref="0") Metastatic(ref="0") max_temp(ref="2") max_HR(ref="2") max_RR(ref="1") mechvent_6hr(ref="0") alter_mental_status(ref="0") ;
        model length_stay = balancemeasure48 spl_age male postacutecare priorhosp KidneyDisease SevereLiverDisease CHF Metastatic mortality_predicted spl_BMI spl_lactate spl_creatinine KidneyDisease*spl_creatinine spl_ratiomin max_temp max_HR max_RR mechvent_6hr alter_mental_status    / CL CovB DIST=poisson LINK=log SOLUTION ODDSRATIO(DIFF=LAST LABEL) ddfm=bw;
        RANDOM INTERCEPT / S SUBJECT=hosp TYPE=VC SOLUTION CL;
        COVTEST/ WALD;
    run;

    /* Every Required RRT */
    ods excel options(sheet_name='RRT48' sheet_interval="proc" embedded_titles = 'yes' embedded_footnotes = 'yes');
    proc freq data = primarycohort_data;
        where other48 >= 1000;
        tables everRRT*balancemeasure48;
    run;
    PROC GLIMMIX data=secondarycohort_data_10plus METHOD=LAPLACE;
        where other48 >= 1000;
        class hosp balancemeasure48(ref = '0') male(ref='0') postacutecare(ref='0') priorhosp(ref="0") KidneyDisease(ref="0") SevereLiverDisease(ref="0") CHF(ref="0") Metastatic(ref="0") max_temp(ref="2") max_HR(ref="2") max_RR(ref="1") mechvent_6hr(ref="0") alter_mental_status(ref="0") ;
        effect spl_creatinine = spline(creatinine_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_creat_D));
        effect spl_lactate = spline(lactate_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_lact_D));
        effect spl_ratiomin = spline(ratio_min/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_ratio_D));
        effect spl_age = spline(age/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_age_D));
        effect spl_BMI = spline(bmi_calculated/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_bmi_D));
        model everRRT(EVENT = '1') = balancemeasure48 spl_age male postacutecare priorhosp KidneyDisease SevereLiverDisease CHF Metastatic mortality_predicted spl_BMI spl_lactate spl_creatinine KidneyDisease*spl_creatinine spl_ratiomin max_temp max_HR max_RR mechvent_6hr alter_mental_status   / CL CovB DIST=BINARY LINK=LOGIT SOLUTION ODDSRATIO(DIFF=LAST LABEL) ddfm=bw;
        RANDOM INTERCEPT / S SUBJECT=hosp TYPE=VC SOLUTION CL;
        COVTEST/ WALD;
        ods output ParameterEstimates = MP_everRRT ;
        ods output OddsRatios = MO_everRRT (keep = Label Estimate Lower Upper);
    run;

    /* Calculate splines for model */
    /* Creatinine - 5 nodes */
    proc univariate data=secondarycohort_data_10plus noprint;
    var creatinine_high;
    output out=pctls5_deriv_creat pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */
    run;

    data _null5_deriv_creat;
    set pctls5_deriv_creat;
    call symput('pctls5_creat_D',catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;

    /* Lactate - 5 nodes */
    proc univariate data=secondarycohort_data_10plus noprint;
    var lactate_high;
    output out=pctls5_deriv_lact pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */
    run;
    
    data _null5_deriv_lact;
    set pctls5_deriv_lact;
    call symput("pctls5_lact_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;

    /* BMI - 5 nodes */
    proc univariate data=secondarycohort_data_10plus noprint;
    var bmi_calculated;
    output out=pctls5_deriv_bmi pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */
    run;
    
    data _null5_deriv_bmi;
    set pctls5_deriv_bmi;
    call symput("pctls5_bmi_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;

    /* PF Ratio - 4 nodes */
    proc univariate data=secondarycohort_data_10plus noprint;
    var ratio_min;
    output out=pctls4_deriv_ratio pctlpts=5 35 65 95 pctlpre=p_; /* specify the percentiles */
    run;
    
    data _null4_deriv_ratio;
    set pctls4_deriv_ratio;
    call symput("pctls4_ratio_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;

    /* Age - 4 nodes */
    proc univariate data=secondarycohort_data_10plus noprint;
    var age;
    output out=pctls4_deriv_age pctlpts=5 35 65 95 pctlpre=p_; /* specify the percentiles */
    run;
    
    data _null4_deriv_age;
    set pctls4_deriv_age;
    call symput("pctls4_age_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;

/* Secondary - 6 hours */
    /* 30 day Mortality */
    *Same as table 2;

    /* In-hospital Mortality */ 
    ods excel options(sheet_name='Hosp Mort6' sheet_interval="proc" embedded_titles = 'yes' embedded_footnotes = 'yes');
    proc freq data = primarycohort_data;
        where other6 >= 1000;
        tables mortality_hosp*balancemeasure6;
    run;
    PROC GLIMMIX data=secondarycohort_data_10plus METHOD=LAPLACE;
        where other6 >= 1000;
        class hosp balancemeasure6(ref = '0') male(ref='0') postacutecare(ref='0') priorhosp(ref="0") KidneyDisease(ref="0") SevereLiverDisease(ref="0") CHF(ref="0") Metastatic(ref="0") max_temp(ref="2") max_HR(ref="2") max_RR(ref="1")  alter_mental_status(ref="0") ;
        effect spl_creatinine = spline(creatinine_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_creat_D));
        effect spl_lactate = spline(lactate_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_lact_D));
        effect spl_ratiomin = spline(ratio_min/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_ratio_D));
        effect spl_age = spline(age/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_age_D));
        effect spl_BMI = spline(bmi_calculated/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_bmi_D));
        model mortality_hosp(EVENT = '1') = balancemeasure6 spl_age male postacutecare priorhosp KidneyDisease SevereLiverDisease CHF Metastatic mortality_predicted spl_BMI spl_lactate spl_creatinine KidneyDisease*spl_creatinine spl_ratiomin max_temp max_HR max_RR  alter_mental_status   / CL CovB DIST=BINARY LINK=LOGIT SOLUTION ODDSRATIO(DIFF=LAST LABEL) ddfm=bw;
        RANDOM INTERCEPT / S SUBJECT=hosp TYPE=VC SOLUTION CL;
        COVTEST/ WALD;
        ods output ParameterEstimates = MP_mortality_hosp ;
        ods output OddsRatios = MO_mortality_hosp (keep = Label Estimate Lower Upper);
    run;

    /* LOS */
    ods excel options(sheet_name='LOS6' sheet_interval="proc" embedded_titles = 'yes' embedded_footnotes = 'yes');
    proc means data = primarycohort_data n nmiss mean std min p25 median p75 max;
        where other6 >= 1000;
        class balancemeasure6;
        var length_stay;
    run;
    PROC GLIMMIX data=secondarycohort_data_10plus METHOD=LAPLACE;
        where other6 >= 1000;
        effect 	spl_creatinine = spline(creatinine_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_creat_D));
        effect	spl_lactate = spline(lactate_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_lact_D));
        effect	spl_ratiomin = spline(ratio_min/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_ratio_D));
        effect	spl_age = spline(age/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_age_D));
        effect	spl_BMI = spline(bmi_calculated/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_bmi_D));
        class hosp balancemeasure6(ref = '0')  male(ref='0') postacutecare(ref='0') priorhosp(ref="0") KidneyDisease(ref="0") SevereLiverDisease(ref="0") CHF(ref="0") Metastatic(ref="0") max_temp(ref="2") max_HR(ref="2") max_RR(ref="1") /* mechvent_6hr(ref="0") */ alter_mental_status(ref="0") ;
        model length_stay = balancemeasure6 spl_age male postacutecare priorhosp KidneyDisease SevereLiverDisease CHF Metastatic mortality_predicted spl_BMI spl_lactate spl_creatinine KidneyDisease*spl_creatinine spl_ratiomin max_temp max_HR max_RR /* mechvent_6hr */ alter_mental_status    / CL CovB DIST=poisson LINK=log SOLUTION ODDSRATIO(DIFF=LAST LABEL) ddfm=bw;
        RANDOM INTERCEPT / S SUBJECT=hosp TYPE=VC SOLUTION CL;
        COVTEST/ WALD;
    run;

    /* Every Required RRT */
    ods excel options(sheet_name='RRT6' sheet_interval="proc" embedded_titles = 'yes' embedded_footnotes = 'yes');
    proc freq data = primarycohort_data;
        where other6 >= 1000;
        tables everRRT*balancemeasure6;
    run;
    PROC GLIMMIX data=secondarycohort_data_10plus METHOD=LAPLACE;
        where other6 >= 1000;
        class hosp balancemeasure6(ref = '0') male(ref='0') postacutecare(ref='0') priorhosp(ref="0") KidneyDisease(ref="0") SevereLiverDisease(ref="0") CHF(ref="0") Metastatic(ref="0") max_temp(ref="2") max_HR(ref="2") max_RR(ref="1")  alter_mental_status(ref="0") ;
        effect spl_creatinine = spline(creatinine_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_creat_D));
        effect spl_lactate = spline(lactate_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_lact_D));
        effect spl_ratiomin = spline(ratio_min/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_ratio_D));
        effect spl_age = spline(age/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_age_D));
        effect spl_BMI = spline(bmi_calculated/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_bmi_D));
        model everRRT(EVENT = '1') = balancemeasure6 spl_age male postacutecare priorhosp KidneyDisease SevereLiverDisease CHF Metastatic mortality_predicted spl_BMI spl_lactate spl_creatinine KidneyDisease*spl_creatinine spl_ratiomin max_temp max_HR max_RR alter_mental_status   / CL CovB DIST=BINARY LINK=LOGIT SOLUTION ODDSRATIO(DIFF=LAST LABEL) ddfm=bw;
        RANDOM INTERCEPT / S SUBJECT=hosp TYPE=VC SOLUTION CL;
        COVTEST/ WALD;
        ods output ParameterEstimates = MPeverRRT;
        ods output OddsRatios = MOeverRRT (keep = Label Estimate Lower Upper);
    run;

ods excel close;
 



/* Table 4 - additional table for Association with % balanced (CATEGORICAL VARIABLE) and 30-day mortality */
/* Only worry about 48 hour group */

/* Calculate splines for model */
    /* Creatinine - 5 nodes */
    proc univariate data=primarycohort_data_10plus noprint;
    var creatinine_high;
    output out=pctls5_deriv_creat pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */
    run;

    data _null5_deriv_creat;
    set pctls5_deriv_creat;
    call symput('pctls5_creat_D',catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;

    /* Lactate - 5 nodes */
    proc univariate data=primarycohort_data_10plus noprint;
    var lactate_high;
    output out=pctls5_deriv_lact pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */
    run;
    
    data _null5_deriv_lact;
    set pctls5_deriv_lact;
    call symput("pctls5_lact_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;

    /* BMI - 5 nodes */
    proc univariate data=primarycohort_data_10plus noprint;
    var bmi_calculated;
    output out=pctls5_deriv_bmi pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */
    run;
    
    data _null5_deriv_bmi;
    set pctls5_deriv_bmi;
    call symput("pctls5_bmi_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;

    /* PF Ratio - 4 nodes */
    proc univariate data=primarycohort_data_10plus noprint;
    var ratio_min;
    output out=pctls4_deriv_ratio pctlpts=5 35 65 95 pctlpre=p_; /* specify the percentiles */
    run;
    
    data _null4_deriv_ratio;
    set pctls4_deriv_ratio;
    call symput("pctls4_ratio_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;

    /* Age - 4 nodes */
    proc univariate data=primarycohort_data_10plus noprint;
    var age;
    output out=pctls4_deriv_age pctlpts=5 35 65 95 pctlpre=p_; /* specify the percentiles */
    run;
    
    data _null4_deriv_age;
    set pctls4_deriv_age;
    call symput("pctls4_age_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */
    run;
/* 48 Hrs */
    /* Primary Cohort */
    PROC GLIMMIX data=primarycohort_data_10plus METHOD=LAPLACE;
        where other48 >= 1000;
        class hosp balance_48_cat(ref = '1') male(ref='0') postacutecare(ref='0') priorhosp(ref="0") KidneyDisease(ref="0") SevereLiverDisease(ref="0") CHF(ref="0") Metastatic(ref="0") max_temp(ref="2") max_HR(ref="2") max_RR(ref="1") mechvent_6hr(ref="0") alter_mental_status(ref="0") ;
        effect spl_creatinine = spline(creatinine_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_creat_D));
        effect spl_lactate = spline(lactate_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_lact_D));
        effect spl_ratiomin = spline(ratio_min/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_ratio_D));
        effect spl_age = spline(age/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_age_D));
        effect spl_BMI = spline(bmi_calculated/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_bmi_D));
        model mortality_30day(EVENT = '1') = balance_48_cat spl_age male postacutecare priorhosp KidneyDisease SevereLiverDisease CHF Metastatic mortality_predicted spl_BMI spl_lactate spl_creatinine KidneyDisease*spl_creatinine spl_ratiomin max_temp max_HR max_RR mechvent_6hr alter_mental_status   / CL CovB DIST=BINARY LINK=LOGIT SOLUTION ODDSRATIO(DIFF=LAST LABEL) ddfm=bw;
        RANDOM INTERCEPT / S SUBJECT=hosp TYPE=VC SOLUTION CL;
        COVTEST/ WALD;
        ods output ParameterEstimates = MP_prim ;
        ods output OddsRatios = MO_prim (keep = Label Estimate Lower Upper);
    run;

/*************************************************************************************************************************************/

/****************************************************************** Table 5 ******************************************************************/
/* Fluid types used among patients who received 0% balanced fluid (Update from 9/14/2026) */
/* 48 Hrs */
proc sql;
    select count(nid), 100*(sum(balance48)/sum(other48)) as percent_balance, 100*(sum(true_other48)/sum(other48)) as percent_other, 100*(sum(ns48)/sum(other48)) as percent_ns
    from primarycohort_data_10plus
    where percent_h48 = 0 and other48 >= 1000;
quit;

/* 6 Hrs */
proc sql;
    select count(nid), 100*(sum(balance6)/sum(other6)) as percent_balance, 100*(sum(true_other6)/sum(other6)) as percent_other, 100*(sum(ns6)/sum(other6)) as percent_ns
    from secondarycohort_data_10plus
    where percent_h6 = 0 and other6 >= 1000;
quit;

/*************************************************************************************************************************************/

/* Print the log into the SAS window */
proc printto log=log; run;

*Read the Log from the External file and Display in the Log Window;
data _null_;
   infile "&path.";
   input;
   putlog ">" _infile_;
run;
