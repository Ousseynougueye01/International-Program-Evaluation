// PROGRAM EVALUATION FOR INTERNATIONAL DEVELOPMENT
// PROFESSOR Omar SENE
/* preliminary stuff*/
clear all
set scheme s1mono
set more off
set seed 12345

* Définir l'URL de base pour les données
webuse set https://github.com/Ousseynougueye01/International-Program-Evaluation/raw/main/

* Charger les données
webuse "final5", clear
webuse "final4", clear

* Définir une commande Stata pour les statistiques descriptives
capture program drop summary_statistics
program define summary_statistics
    args data grade

    * Charger les données à partir de l'URL
    webuse `data', clear

    * Calculer le nombre de classes et d'écoles
    gen class_id = _n
    bysort schlcode: gen school_id = _n == 1
    sum school_id
    local schools = r(sum)
    local classes = _N

    * Générer les statistiques descriptives
    tabstat classize c_size tip_a verbsize mathsize avgverb avgmath, ///
        statistics(mean sd p10 p25 p50 p75 p90) columns(statistics) ///
        save

    * Convertir les résultats en matrice
    matrix stats = r(StatTotal)
    matrix stats_t = stats'  // Transposer la matrice

    * Ajouter des noms de lignes et de colonnes
    matrix colnames stats_t = "Mean" "SD" "P10" "P25" "P50" "P75" "P90"
    matrix rownames stats_t = "Class Size" "Enrollment" "Percent Disadvantaged" "Verbal Score" "Math Score" "Avg Verbal" "Avg Math"

    * Exporter la matrice transposée en LaTeX
    esttab matrix(stats_t) using "summary_stats_`grade'.tex", replace ///
        title("Unweighted Descriptive Statistics for `grade' Grade: `classes' classes, `schools' schools, tested in 1991") ///
        addnotes("SD = Standard Deviation, P10 = 10th Percentile, P75 = 75th Percentile, P90 = 90th Percentile") ///
        label
end

* Utiliser la commande pour les données de 5ème et 4ème
summary_statistics final5 "5th"
summary_statistics final4 "4th"


* Définir la commande pour la discontinuité principale
capture program drop discontinuity
program define discontinuity
    args full_sample

    * Charger les données à partir de l'URL
    webuse `full_sample', clear
    keep if (c_size >= 36 & c_size <= 45) | (c_size >= 76 & c_size <= 85) | (c_size >= 116 & c_size <= 125)
    save discontinuity_sample, replace
end

* Appliquer la discontinuité principale à data5 et data4

discontinuity final5
use "discontinuity_sample.dta", clear
save "discontinuity5.dta", replace
erase "discontinuity_sample.dta"

discontinuity final4
use "discontinuity_sample.dta", clear
save "discontinuity4.dta", replace
erase "discontinuity_sample.dta"

capture program drop summary_statistics_disc
program define summary_statistics_disc
    args data grade

    use `data', clear

    * Calculer le nombre de classes et d'écoles
    gen class_id = _n
    bysort schlcode: gen school_id = _n == 1
    sum school_id
    local schools = r(sum)
    local classes = _N

    * Générer les statistiques descriptives
    tabstat classize c_size tip_a verbsize mathsize avgverb avgmath, ///
        statistics(mean sd p10 p25 p50 p75 p90) columns(statistics) ///
        save

    * Convertir les résultats en matrice
    matrix stats = r(StatTotal)
    matrix stats_t = stats'  // Transposer la matrice

    * Ajouter des noms de lignes et de colonnes
    matrix colnames stats_t = "Mean" "SD" "P10" "P25" "P50" "P75" "P90"
    matrix rownames stats_t = "Class Size" "Enrollment" "Percent Disadvantaged" "Verbal Score" "Math Score" "Avg Verbal" "Avg Math"

    * Exporter la matrice transposée en LaTeX
    esttab matrix(stats_t) using "summary_stats_disc_`grade'.tex", replace ///
        title("Unweighted Descriptive Statistics for `grade' Grade: `classes' classes, `schools' schools, tested in 1991") ///
        addnotes("SD = Standard Deviation, P10 = 10th Percentile, P75 = 75th Percentile, P90 = 90th Percentile") ///
        label
end

* Générer les statistiques descriptives
summary_statistics_disc discontinuity5 "5th"
summary_statistics_disc discontinuity4 "4th"

*************************
* Définir la fonction pour calculer la taille de classe attendue
capture program drop expected_classize
program define expected_classize
    args c_size

    gen expected_class_size = .
    forvalues i = 1/`=_N' {
        local e = c_size[`i']
        local denominator = int((`e' - 1) / 40) + 1
        replace expected_class_size = `e' / `denominator' in `i'
    }
end

* Appliquer à la 5e année
webuse final5, clear
expected_classize c_size


* Appliquer à la 4e année
webuse final4, clear
expected_classize c_size



	   
************************************
* Charger les données de 5e année
webuse final5,clear

* Régressions pour la 5e année
regress avgverb classize, vce(cluster schlcode)
estimates store model1

regress avgverb classize tipuach, vce(cluster schlcode)
estimates store model2

regress avgverb classize tipuach c_size, vce(cluster schlcode)
estimates store model3

regress avgmath classize, vce(cluster schlcode)
estimates store model4

regress avgmath classize tipuach, vce(cluster schlcode)
estimates store model5

regress avgmath classize tipuach c_size, vce(cluster schlcode)
estimates store model6

* Afficher les résultats pour la 5e année
esttab model1 model2 model3 model4 model5 model6, ///
       title("OLS estimates for 1991 5th grade") ///
       mtitle("rc5.1" "rc5.2" "rc5.3" "m5.1" "m5.2" "m5.3") ///
       coeflabels(classize "Class size" tipuach "Percent Disadvantaged" c_size "Enrollment") ///
       se nogap label addnotes("rc := reading comprehension, m := math") ///
       compress

* Exporter les résultats de 5e année au format LaTeX
esttab model1 model2 model3 model4 model5 model6 using "table2_5th.tex", ///
       title("OLS estimates for 1991 5th grade") ///
       mtitle("rc5.1" "rc5.2" "rc5.3" "m5.1" "m5.2" "m5.3") ///
       coeflabels(classize "Class size" tipuach "Percent Disadvantaged" c_size "Enrollment") ///
       se nogap label addnotes("rc := reading comprehension, m := math") ///
       compress replace

* Charger les données de 4e année
webuse final4, clear

* Régressions pour la 4e année
regress avgverb classize, vce(cluster schlcode)
estimates store model7

regress avgverb classize tipuach, vce(cluster schlcode)
estimates store model8

regress avgverb classize tipuach c_size, vce(cluster schlcode)
estimates store model9

regress avgmath classize, vce(cluster schlcode)
estimates store model10

regress avgmath classize tipuach, vce(cluster schlcode)
estimates store model11

regress avgmath classize tipuach c_size, vce(cluster schlcode)
estimates store model12

* Afficher les résultats pour la 4e année
esttab model7 model8 model9 model10 model11 model12, ///
       title("OLS estimates for 1991 4th grade") ///
       mtitle("rc4.1" "rc4.2" "rc4.3" "m4.1" "m4.2" "m4.3") ///
       coeflabels(classize "Class size" tipuach "Percent Disadvantaged" c_size "Enrollment") ///
       se nogap label addnotes("rc := reading comprehension, m := math") ///
       compress

* Exporter les résultats de 4e année au format LaTeX
esttab model7 model8 model9 model10 model11 model12 using "table2_4th.tex", ///
       title("OLS estimates for 1991 4th grade") ///
       mtitle("rc4.1" "rc4.2" "rc4.3" "m4.1" "m4.2" "m4.3") ///
       coeflabels(classize "Class size" tipuach "Percent Disadvantaged" c_size "Enrollment") ///
       se nogap label addnotes("rc := reading comprehension, m := math") ///
       compress replace

	   ***************
webuse "final5.dta", clear
expected_classize c_size
gen discontinuity5_5th = (c_size >= 36 & c_size <= 45) | (c_size >= 76 & c_size <= 85) | (c_size >= 116 & c_size <= 125)
gen discontinuity3_5th = (c_size >= 38 & c_size <= 43) | (c_size >= 78 & c_size <= 83) | (c_size >= 118 & c_size <= 123)

* Modèles pour le 5ème grade (échantillon complet)
regress classize expected_class_size tipuach, vce(cluster schlcode)
est store full5_col1

regress classize expected_class_size tipuach c_size, vce(cluster schlcode)
est store full5_col2

regress avgverb expected_class_size tipuach, vce(cluster schlcode)
est store full5_col3

regress avgverb expected_class_size tipuach c_size, vce(cluster schlcode)
est store full5_col4

regress avgmath expected_class_size tipuach, vce(cluster schlcode)
est store full5_col5

regress avgmath expected_class_size tipuach c_size, vce(cluster schlcode)
est store full5_col6

* Modèles pour le 5ème grade (échantillon de discontinuité +/- 5)
use discontinuity5, clear
expected_classize c_size

regress classize expected_class_size tipuach, vce(cluster schlcode)
est store disc5_col1

regress classize expected_class_size tipuach c_size, vce(cluster schlcode)
est store disc5_col2

regress avgverb expected_class_size tipuach, vce(cluster schlcode)
est store disc5_col3

regress avgverb expected_class_size tipuach c_size, vce(cluster schlcode)
est store disc5_col4

regress avgmath expected_class_size tipuach, vce(cluster schlcode)
est store disc5_col5

regress avgmath expected_class_size tipuach c_size, vce(cluster schlcode)
est store disc5_col6

esttab full5_col1 full5_col2 full5_col3 full5_col4 full5_col5 full5_col6, ///
       title("Reduced-Form Estimates for 1991 5th Grade Full Sample") ///
       mtitle("cs5.1" "cs5.2" "rc5.1" "rc5.2" "m5.1" "m5.2") ///
       coeflabels(exp_classize "Expected Class Size" tipuach "Percent Disadvantaged" c_size "Enrollment") ///
    addnotes("cs := class size,rc := reading comprehension, m := math") ///
    se star(* 0.10 ** 0.05 *** 0.01) ///
    label




esttab full5_col1 full5_col2 full5_col3 full5_col4 full5_col5 full5_col6 ///
    using "table3_fullsample_5th.tex", replace ///
    title("Reduced-Form Estimates for 1991 5th Grade Full Sample") ///
    mtitle("cs5.1" "cs5.2" "rc5.1" "rc5.2" "m5.1" "m5.2") ///
    coeflabels(exp_classize "Expected Class Size" tipuach "Percent Disadvantaged" c_size "Enrollment") ///
    addnotes("cs := class size,rc := reading comprehension, m := math") ///
    se star(* 0.10 ** 0.05 *** 0.01) ///
    label

	* DISCONTINUITE
esttab disc5_col1 disc5_col2 disc5_col3 disc5_col4 disc5_col5 disc5_col6 ///
    using "table3_discsample_5th.tex", replace ///
    title("Reduced-Form Estimates for 1991 5th Grade Discontinuity") ///
    mtitle("cs5.1" "cs5.2" "rc5.1" "rc5.2" "m5.1" "m5.2") ///
    coeflabels(exp_classize "Expected Class Size" tipuach "Percent Disadvantaged" c_size "Enrollment") ///
    addnotes("cs := class size,rc := reading comprehension, m := math") ///
    se star(* 0.10 ** 0.05 *** 0.01) ///
    label	
	
* Pour le grade 4

webuse "final4.dta", clear
expected_classize c_size
gen discontinuity5_4th = (c_size >= 36 & c_size <= 45) | (c_size >= 76 & c_size <= 85) | (c_size >= 116 & c_size <= 125)
gen discontinuity3_4th = (c_size >= 38 & c_size <= 43) | (c_size >= 78 & c_size <= 83) | (c_size >= 118 & c_size <= 123)


* Modèles pour le 4ème grade (échantillon complet)
regress classize expected_class_size tipuach, vce(cluster schlcode)
est store full4_col1

regress classize expected_class_size tipuach c_size, vce(cluster schlcode)
est store full4_col2

regress avgverb expected_class_size tipuach, vce(cluster schlcode)
est store full4_col3

regress avgverb expected_class_size tipuach c_size, vce(cluster schlcode)
est store full4_col4

regress avgmath expected_class_size tipuach, vce(cluster schlcode)
est store full4_col5

regress avgmath expected_class_size tipuach c_size, vce(cluster schlcode)
est store full4_col6

* Modèles pour le 4ème grade (échantillon de discontinuité +/- 5)
use discontinuity4, clear
expected_classize c_size

regress classize expected_class_size tipuach , vce(cluster schlcode)
est store disc4_col1

regress classize expected_class_size tipuach c_size , vce(cluster schlcode)
est store disc4_col2

regress avgverb expected_class_size tipuach , vce(cluster schlcode)
est store disc4_col3

regress avgverb expected_class_size tipuach c_size , vce(cluster schlcode)
est store disc4_col4

regress avgmath expected_class_size tipuach , vce(cluster schlcode)
est store disc4_col5

regress avgmath expected_class_size tipuach c_size , vce(cluster schlcode)
est store disc4_col6

esttab full4_col1 full4_col2 full4_col3 full4_col4 full4_col5 full4_col6 ///
    using "table3_fullsample_4th.tex", replace ///
    title("Reduced-Form Estimates for 1991 4th Grade Full Sample") ///
    mtitle("cs4.1" "cs4.2" "rc4.1" "rc4.2" "m4.1" "m4.2") ///
    coeflabels(exp_classize "Expected Class Size" tipuach "Percent Disadvantaged" c_size "Enrollment") ///
    addnotes("cs := class size,rc := reading comprehension, m := math") ///
    se star(* 0.10 ** 0.05 *** 0.01) ///
    label

	* DISCONTINUITE
esttab disc4_col1 disc4_col2 disc4_col3 disc4_col4 disc4_col5 disc4_col6 ///
    using "table3_discsample_4th.tex", replace ///
    title("Reduced-Form Estimates for 1991 4th Grade Discontinuity") ///
    mtitle("cs5.1" "cs5.2" "rc5.1" "rc5.2" "m5.1" "m5.2") ///
    coeflabels(exp_classize "Expected Class Size" tipuach "Percent Disadvantaged" c_size "Enrollment") ///
    addnotes("cs := class size,rc := reading comprehension, m := math") ///
    se star(* 0.10 ** 0.05 *** 0.01) ///
    label	

*********** Tableau 4
webuse "final5.dta", clear

* Créer la tendance
gen trend = .
replace trend = c_size if c_size >= 0 & c_size <= 40
replace trend = 20 + c_size/2 if c_size >= 41 & c_size <= 80
replace trend = 100/3 + c_size/3 if c_size >= 81 & c_size <= 120
replace trend = 130/3 + c_size/4 if c_size >= 121 & c_size <= 160

expected_classize c_size

* Modèles pour l'échantillon complet
ivreg2 avgverb (classize = expected_class_size) tipuach, cluster(schlcode)
est store iv_full5_col1

ivreg2 avgverb (classize = expected_class_size) tipuach c_size, cluster(schlcode)
est store iv_full5_col2

ivreg2 avgverb (classize = expected_class_size) tipuach c_size trend, cluster(schlcode)
est store iv_full5_col3

ivreg2 avgmath (classize = expected_class_size) tipuach, cluster(schlcode)
est store iv_full5_col4

ivreg2 avgmath (classize = expected_class_size) tipuach c_size, cluster(schlcode)
est store iv_full5_col5

ivreg2 avgmath (classize = expected_class_size) tipuach c_size trend, cluster(schlcode)
est store iv_full5_col6

use discontinuity5, clear
expected_classize c_size

* Modèles pour l'échantillon de discontinuité +/- 5
ivreg2 avgverb (classize = expected_class_size) tipuach, cluster(schlcode)
est store iv_disc5_col1

ivreg2 avgverb (classize = expected_class_size) tipuach c_size, cluster(schlcode)
est store iv_disc5_col2

ivreg2 avgmath (classize = expected_class_size) tipuach, cluster(schlcode)
est store iv_disc5_col3

ivreg2 avgmath (classize = expected_class_size) tipuach c_size, cluster(schlcode)
est store iv_disc5_col4

webuse "final4.dta", clear
expected_classize c_size

* Créer la tendance
gen trend = .
replace trend = c_size if c_size >= 0 & c_size <= 40
replace trend = 20 + c_size/2 if c_size >= 41 & c_size <= 80
replace trend = 100/3 + c_size/3 if c_size >= 81 & c_size <= 120
replace trend = 130/3 + c_size/4 if c_size >= 121 & c_size <= 160

* Modèles pour l'échantillon complet
ivreg2 avgverb (classize = expected_class_size) tipuach, cluster(schlcode)
est store iv_full4_col1

ivreg2 avgverb (classize = expected_class_size) tipuach c_size, cluster(schlcode)
est store iv_full4_col2

ivreg2 avgverb (classize = expected_class_size) tipuach c_size trend, cluster(schlcode)
est store iv_full4_col3

ivreg2 avgmath (classize = expected_class_size) tipuach, cluster(schlcode)
est store iv_full4_col4

ivreg2 avgmath (classize = expected_class_size) tipuach c_size, cluster(schlcode)
est store iv_full4_col5

ivreg2 avgmath (classize = expected_class_size) tipuach c_size trend, cluster(schlcode)
est store iv_full4_col6

* Modèles pour l'échantillon de discontinuité +/- 5
use discontinuity4, clear
expected_classize c_size


ivreg2 avgverb (classize = expected_class_size) tipuach , cluster(schlcode)
est store iv_disc4_col1

ivreg2 avgverb (classize = expected_class_size) tipuach c_size , cluster(schlcode)
est store iv_disc4_col2

ivreg2 avgmath (classize = expected_class_size) tipuach , cluster(schlcode)
est store iv_disc4_col3

ivreg2 avgmath (classize = expected_class_size) tipuach c_size , cluster(schlcode)
est store iv_disc4_col4

esttab iv_full5_col1 iv_full5_col2 iv_full5_col3 iv_full5_col4 iv_full5_col5 iv_full5_col6 ///
    using "table4_fullsample_5th.tex", replace ///
    title("2SLS Estimates for 1991 5th Grade Full Sample") ///
    mtitle("rc5.1" "rc5.2" "rc5.3" "m5.1" "m5.2" "m5.3") ///
    coeflabels(classize "Class Size" tipuach "Percent Disadvantaged" c_size "Enrollment" trend "Trend") ///
    addnotes("rc := reading comprehension, m := math") ///
    se star(* 0.10 ** 0.05 *** 0.01) ///
    label

esttab iv_disc5_col1 iv_disc5_col2 iv_disc5_col3 iv_disc5_col4 ///
    using "table4_discsample_5th.tex", replace ///
    title("2SLS Estimates for 1991 5th Grade Discontinuity Sample") ///
    mtitle("rc5.1" "rc5.2" "m5.1" "m5.2") ///
    coeflabels(classize "Class Size" tipuach "Percent Disadvantaged" c_size "Enrollment") ///
    addnotes("rc := reading comprehension, m := math") ///
    se star(* 0.10 ** 0.05 *** 0.01) ///
    label
	
esttab iv_full4_col1 iv_full4_col2 iv_full4_col3 iv_full4_col4 iv_full4_col5 iv_full4_col6 ///
    using "table4_fullsample_4th.tex", replace ///
    title("2SLS Estimates for 1991 4th Grade Full Sample") ///
    mtitle("rc4.1" "rc4.2" "rc4.3" "m4.1" "m4.2" "m4.3") ///
    coeflabels(classize "Class Size" tipuach "Percent Disadvantaged" c_size "Enrollment" trend "Trend") ///
    addnotes("rc := reading comprehension, m := math") ///
    se star(* 0.10 ** 0.05 *** 0.01) ///
    label

esttab iv_disc4_col1 iv_disc4_col2 iv_disc4_col3 iv_disc4_col4 ///
    using "table4_discsample_4th.tex", replace ///
    title("2SLS Estimates for 1991 4th Grade Discontinuity Sample") ///
    mtitle("rc4.1" "rc4.2" "m4.1" "m4.2") ///
    coeflabels(classize "Class Size" tipuach "Percent Disadvantaged" c_size "Enrollment") ///
    addnotes("rc := reading comprehension, m := math") ///
    se star(* 0.10 ** 0.05 *** 0.01) ///
    label

* Graph 2a
webuse final5.dta, clear
expected_classize c_size
gen c_size_group = floor((c_size-1) / 10) * 10
replace c_size_group = 160 if c_size_group > 160
gen c_size_median = c_size_group + 5

preserve
collapse (mean) avgverb expected_class_size if grade==5 & c_size >9 & c_size <=190, by(c_size_median)  

twoway ///
    (line avgverb c_size_median, lcolor(black) lpattern(solid) lwidth(medium)) /// 
    (line expected_class_size c_size_median, yaxis(2) lcolor(black) lpattern(dash) lwidth(medium)) /// 
    , /// 
    ytitle("Average Reading Score", axis(1) margin(medium)) /// 
    ytitle("Predicted Class Size", axis(2) margin(medium)) /// 
    ylabel(68(2)82, axis(1)) ///  
    ylabel(10(5)40, axis(2)) ///  
    xtitle("Enrollment Count") ///  
    xlabel(5(20)165, labsize(small)) ///  
    legend(order(1 "Average Test Scores" 2 "Predicted Class Size") ///
           position(6) ring(0) cols(1) size(small)) ///  
    title("a. Fifth Grade", justification(left) size(medium) )  
     
restore


graph export "FigureII_a.png",replace


/*-----------------------------------graph II.b-------------------------------*/
webuse final4.dta, clear
expected_classize c_size
gen c_size_group = floor((c_size-1) / 10) * 10
replace c_size_group = 160 if c_size_group > 160
gen c_size_median = c_size_group + 5

preserve
collapse (mean) avgverb expected_class_size if grade==4 & c_size  >9 & c_size <=190, by(c_size_median) 

	
	twoway ///
    (line avgverb c_size_median, lcolor(black) lpattern(solid) lwidth(medium)) /// 
    (line expected_class_size c_size_median, yaxis(2) lcolor(black) lpattern(dash) lwidth(medium)) /// 
    , /// 
    ytitle("Average Reading Score", axis(1) margin(medium)) /// 
    ytitle("Predicted Class Size", axis(2) margin(medium)) /// 
    ylabel(68(2)82, axis(1)) ///  
    ylabel(10(5)40, axis(2)) ///  
    xtitle("Enrollment Count") ///  
    xlabel(5(20)165, labsize(small)) ///  
    legend(order(1 "Average Test Scores" 2 "Predicted Class Size") ///
           position(6) ring(0) cols(1) size(small)) ///  
    title("b. Fourth Grade", justification(left) size(medium) )     
    
restore


graph export "FigureII_b.png",replace
*------------------------------------------------------------------------------*



*-------------------------------* figure III *----------------------------------

/*-----------------------------graph III.a------------------------------------*/
webuse final5.dta, clear
expected_classize c_size
gen c_size_group = floor((c_size-1) / 10) * 10
replace c_size_group = 160 if c_size_group > 160
gen c_size_median = c_size_group + 5
preserve 
collapse (mean) avgverb expected_class_size tipuach if grade==5 & c_size >9 & c_size <=190, by(c_size_median) 

regress avgverb c_size_median tipuach
predict verb_resi, residuals
regress expected_class_size c_size_median tipuach
predict pred_resi, residuals

twoway ///  
    (line verb_resi c_size_median, lcolor(black) lpattern(solid) lwidth(medium)) ///  
    (line pred_resi c_size_median, yaxis(2) lcolor(black) lpattern(dash) lwidth(medium)) ///  
    , ///  
    ytitle("Reading score residuals", axis(1) margin(medium)) ///  
    ytitle("Size function residual", axis(2) margin(medium)) ///  
    ylabel(-5(1)5, axis(1)) ///   
    ylabel(-15(5)15, axis(2)) ///  
    xtitle("Enrollment count") ///  
    xlabel(5(20)165) ///  
    legend(order(1 "Average test scores" 2 "Predicted class size") position(6) ring(0)) ///  
    title("a. Fifth Grade (Reading)", justification(left) size(medium) )   
     
restore


graph export "FigureIII_a.png",replace



/*---------------------------------graph III.b--------------------------------*/

webuse final4.dta, clear
expected_classize c_size
gen c_size_group = floor((c_size-1) / 10) * 10
replace c_size_group = 160 if c_size_group > 160
gen c_size_median = c_size_group + 5

preserve 
collapse (mean) avgverb expected_class_size cohsize tipuach if grade==4 & c_size >9 & c_size <=190, by(c_size_median) 

regress avgverb c_size_median tipuach
predict verb_resi, residuals
regress expected_class_size c_size_median tipuach
predict pred_resi, residuals

twoway ///  
    (line verb_resi c_size_median, lcolor(black) lpattern(solid) lwidth(medium)) ///  
    (line pred_resi c_size_median, yaxis(2) lcolor(black) lpattern(dash) lwidth(medium)) ///  
    , ///  
    ytitle("Reading score residuals", axis(1) margin(medium)) ///  
    ytitle("Size function residual", axis(2) margin(medium)) ///  
    ylabel(-5(1)5, axis(1)) ///   
    ylabel(-15(5)15, axis(2)) ///  
    xtitle("Enrollment count") ///  
    xlabel(5(20)165) ///  
    legend(order(1 "Average test scores" 2 "Predicted class size") position(6) ring(0)) ///  
    title("b. Fourth Grade (Reading)", justification(left) size(medium) )   
    
restore


graph export "FigureIII_b.png",replace

*------------------------------------------------------------------------------*


/*------------------------------graph III.c-----------------------------------*/

webuse final5.dta, clear
expected_classize c_size
gen c_size_group = floor((c_size-1) / 10) * 10
replace c_size_group = 160 if c_size_group > 160
gen c_size_median = c_size_group + 5
preserve 
collapse (mean) avgmath expected_class_size cohsize tipuach if grade==5 & c_size >9 & c_size <=190, by(c_size_median) 

regress avgmath c_size_median tipuach
predict math_res, residuals
regress expected_class_size c_size_median tipuach
predict pred_res, residuals

twoway ///  
    (line math_res c_size_median, lcolor(black) lpattern(solid) lwidth(medium)) ///  
    (line pred_res c_size_median, yaxis(2) lcolor(black) lpattern(dash) lwidth(medium)) ///  
    , ///  
    ytitle("Math score residuals", axis(1) margin(medium)) ///  
    ytitle("Size function residual", axis(2) margin(medium)) ///  
    ylabel(-5(1)5, axis(1)) ///   
    ylabel(-15(5)15, axis(2)) ///  
    xtitle("Enrollment count") ///  
    xlabel(5(20)165) ///  
    legend(order(1 "Average test scores" 2 "Predicted class size") position(6) ring(0)) ///  
    title("c. Fifth Grade (Math)", justification(left) size(medium) )   
      
restore


graph export "FigureIII_c.png",replace
