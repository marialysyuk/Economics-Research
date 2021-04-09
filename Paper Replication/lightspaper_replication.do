* 2011/04/10
* lightspaper_replication.do
* this stata script reproduces all tables, graphs, and ad hoc numbers in 
* Henderson, Storeygard and Weil (2011) "Measuring Economic Growth from Outer Space"
* exception: Africa results in section 5 (see africa_coastmalariaprimate.do)

#delimit cr
cd F:\adam\replication
capture log close
set logtype text
log using lightspaper_replicationlog.txt, replace
display c(current_time)

version 10.1
clear

* 2010/09/22
*This should run all of the tables, graphs, and ad hoc numbers that appear in the paper:

* requires unique and outreg2:
net install http://fmwww.bc.edu/RePEc/bocode/u/unique
net install http://fmwww.bc.edu/RePEc/bocode/o/outreg2

set matsize 1000

****************
* misc. stats: *
****************

* calculate average and standard deviation of coverage days (on land) across all satellites and countries:
* (each column in the input file corresponds to one of 30 satellite-years)
odbc load, dialog(complete) dsn("dBASE Files") table("isocvout") clear
* isonv10 is a numerical country identifier:
gen isonv10 = floor(VALUE/1000)
gen days = VALUE - (isonv10 * 1000)
egen cells = rowtotal(CVCT*)
drop VALUE CVCT*
collapse (sum) cells, by(days)
gen tmp = 1
table tmp [fw=cells], c(mean days sd days) replace
rename table1 mean_days
rename table2 sd_days
save results_days, replace

* calculate changes quoted for South Korea, North Korea, and Indonesia:
use global_total_dn_uncal.dta, clear
keep if ((iso3v10=="PRK" | iso3v10=="KOR") & (year==1992 | year==2008)) | (iso3v10=="IDN" & (year==1997 | year==1998))
keep lndn lngdpwdilocal iso3v10 year
reshape wide lndn lngdpwdilocal, i(iso3v10) j(year)
gen pctchangedn9208 = (exp(lndn2008) - exp(lndn1992)) / exp(lndn1992) if iso3v10=="PRK" | iso3v10=="KOR"
gen pctchangedn9798 = (exp(lndn1998) - exp(lndn1997)) / exp(lndn1997) if iso3v10=="IDN"
gen pctchangegdp9208 = (exp(lngdpwdilocal2008) - exp(lngdpwdilocal1992)) / exp(lngdpwdilocal1992) if iso3v10=="PRK" | iso3v10=="KOR"
gen pctchangegdp9798 = (exp(lngdpwdilocal1998) - exp(lngdpwdilocal1997)) / exp(lngdpwdilocal1997) if iso3v10=="IDN"
keep  iso3v10 pctchangedn9208 pctchangedn9798 pctchangegdp9208 pctchangegdp9798
list
save results_korea_indonesia, replace

* some basic statistics
use global_total_dn_uncal.dta, clear
drop if iso3v10=="GNQ" | iso3v10=="BHR" | iso3v10=="SGP" | iso3v10=="HKG"
drop if missing(lngdpwdilocal)
* # countries
unique iso3v10
unique iso3v10 if ~missing(wbdqtotal)
unique iso3v10 if missing(wbdqtotal) & imftypenum==1
* # countries per year:
table year, replace
rename table1 countries
save results_countries_by_year, replace

* electricity sample
use global_total_dn_uncal_longdiff9206.dta, clear
drop if iso3v10=="GNQ" | iso3v10=="BHR" | iso3v10=="SGP" | iso3v10=="HKG"
drop if missing(lngdpwdilocallongdiff)
sum  lnkwh_uselongdiff lndnlongdiff lngdpwdilocallongdiff if wbdqtotal<3.5 & ~missing(lndnlongdiff) & ~missing(lngdpwdilocallongdiff)
unique iso3v10
unique iso3v10 if ~missing(wbdqtotal)

* say something about the countries with no WDI data - do they have electricity?
use global_total_dn_uncal.dta, clear
keep if year<2007
tab country if missing(lngdpwdilocal) & missing(lnkwh_use)
bysort iso3v10: egen meanpop = mean(SPPOPTOTL)
tab country if missing(lngdpwdilocal) & missing(lnkwh_use) & meanpop>1000000 & ~missing(meanpop)
tab country if missing(lngdpwdilocal) & ~missing(lnkwh_use) & meanpop>1000000 & ~missing(meanpop)
tab country if missing(lngdpwdilocal) & missing(lnkwh_use)
tab country if missing(lngdpwdilocal) & ~missing(lnkwh_use)

* begin Table 1:
use global_total_dn_uncal_longdiff9208.dta, clear
sort iso3v10
save global_total_dn_uncal_longdiff9208.dta, replace

* basic stats for countries in Table 1:
use global_total_dn_uncal.dta, clear
keep if iso3v10=="BGD" | iso3v10=="USA" | iso3v10=="CAN" | iso3v10=="NLD" | iso3v10=="BRA" | iso3v10=="CRI" | iso3v10=="GTM" | iso3v10=="MWI" | iso3v10=="MDG" | iso3v10=="MOZ"
gen pctunlit = 1 - pctlit
keep  year iso3v10 country avdn pctunlit lgini ENPOPDNST SPURBTOTLINZS GDP_percap_PPP NYGDPPCAPKD 
rename ENPOPDNST popdens
gen fracurban = SPURBTOTLINZS / 100
rename GDP_percap_PPP gdppercap_ppp2005dollars
rename NYGDPPCAPKD gdppercap_2000dollars
collapse pctunlit avdn lgini popdens fracurban gdppercap_ppp2005dollars gdppercap_2000dollars, by(country iso3v10)
sort iso3v10
drop iso3v10 
xpose,  varname clear

drop if _varname=="country" 
rename v1 Bangladesh
rename v2 Brazil
rename v3 Canada
rename v4 CostaRica
rename v5 Guatemala
rename v6 Madagascar
rename v7 Mozambique
rename v8 Malawi
rename v9 Netherlands
rename v10 USA
gen dncat = _n+6
drop _varname
save ten_country_avg_allyr_v4, replace

use global_total_dn_uncal.dta, clear
keep isonv10 iso3v10
sort isonv10 
save isonumtext, replace

* DN distribution for table 1
clear
* this file contains a breakdown of cells by country and digital number, with a column for each of the 30 satellite-years
odbc load, dialog(complete) dsn("dBASE Files") table("ginioutu")
* isonv10 is a country identifier:
gen isonv10 = floor(VALUE/100)
* dn is the digital number:
gen dn = VALUE - (isonv10 * 100)
drop VALUE
egen counttot = rowtotal( CTG101992-CTG162008)
drop if counttot==0
drop CTG*
sort isonv10
merge isonv10 using isonumtext

keep if iso3v10=="BGD" | iso3v10=="USA" | iso3v10=="CAN" | iso3v10=="NLD" | iso3v10=="BRA" | iso3v10=="CRI" | iso3v10=="GTM" | iso3v10=="MWI" | iso3v10=="MDG" | iso3v10=="MOZ"
drop _merge isonv10
reshape wide counttot, i(dn) j(iso3v10) string
gen dncat = 0
replace dncat = 1 if dn>0
replace dncat = 2 if dn>2
replace dncat = 3 if dn>5
replace dncat = 4 if dn>10
replace dncat = 5 if dn>20
replace dncat = 6 if dn>62
collapse (sum) counttot*, by(dncat)
format count* %9.0f

foreach i in "BGD" "USA" "CAN" "NLD" "BRA" "CRI" "GTM" "MDG" "MOZ" "MWI" {
	egen mn`i' = mean(counttot`i')
	gen pct`i' = counttot`i'/(mn`i' * _N)
	drop mn`i' counttot`i'
	format pct`i'
}

rename pctUSA USA
rename pctCAN Canada
rename pctNLD Netherlands
rename pctBGD Bangladesh
rename pctBRA Brazil
rename pctCRI CostaRica
rename pctGTM Guatemala
rename pctMDG Madagascar
rename pctMOZ Mozambique
rename pctMWI Malawi

* combine the two parts of table 1
append using ten_country_avg_allyr_v4
erase ten_country_avg_allyr_v4.dta
lab def dncats 0 "'0" 1 "'1-2" 2 "'3-5" 3 "'6-10" 4 "'11-20" 5 "21-62" 6 "'63" 7 "% unlit" 8 "avg. DN" 9 "gini(DN)" 10 "pop. density (per sq. km)" 11 "percent urban" 12 "GDP per capita, PPP (2005 $)" 13 "GDP per capita (2000 $)" 
lab val dncat dncats

outsheet using lightspaper_table1_092210uncal.csv, comma replace

* Table 2
use global_total_dn_uncal.dta, clear
drop if iso3v10=="GNQ" | iso3v10=="BHR" | iso3v10=="SGP" | iso3v10=="HKG"
drop if missing(lngdpwdilocal)
replace year = year - 1992
xtset isonv10 year

* baseline
xi: xtreg lngdpwdilocal lndn i.year, fe robust cluster(isonv10)
outreg2 using lightspaper_table2_092210uncal.txt, bdec(3) label br replace
xi: xtreg lngdpwdilocal lndn lndnsq i.year, fe robust cluster(isonv10)
outreg2 using lightspaper_table2_092210uncal.txt, dec(4) label br
xi: xtreg lngdpwdilocal lndn lntopcodedcount lnunlitcount i.year, fe robust cluster(isonv10)
outreg2 using lightspaper_table2_092210uncal.txt, bdec(4) label br
xi: xtreg lngdpwdilocal lndn lgini i.year, fe robust cluster(isonv10)
outreg2 using lightspaper_table2_092210uncal.txt, bdec(3) label br
* electricity sample
xi: xtreg lngdpwdilocal lndn i.year if ~missing(lnkwh_use), fe robust cluster(isonv10)
outreg2 using lightspaper_table2_092210uncal.txt, bdec(3) label br
* add electricity:
xi: xtreg lngdpwdilocal lnkwh_use i.year, fe robust cluster(isonv10)
outreg2 using lightspaper_table2_092210uncal.txt, bdec(3) label br
xi: xtreg lngdpwdilocal lnkwh_use lndn i.year, fe robust cluster(isonv10)
outreg2 using lightspaper_table2_092210uncal.txt, bdec(3) label br
xi: xtreg lngdpwdilocal lndnnogf i.year, fe robust cluster(isonv10)
outreg2 using lightspaper_table2_092210uncal.txt, bdec(3) label br

* table 2a: 
* dhs electricity:

xi: xtreg lngdpwdilocal lndn i.year if ~missing(HHpctelect_total), fe robust
outreg2 using lightspaper_table2a_092210uncal.txt, bdec(3) label br replace
xi: xtreg lngdpwdilocal lndn HHpctelect_total i.year, fe robust
outreg2 using lightspaper_table2a_092210uncal.txt, bdec(3) label br

xi: xtreg lngdpwdilocal lndn lnkwh_use i.year if ~missing(HHpctelect_total) & ~missing(lnkwh_use), fe robust
outreg2 using lightspaper_table2a_092210uncal.txt, bdec(3) label br
xi: xtreg lngdpwdilocal lndn HHpctelect_total lnkwh_use i.year, fe robust
outreg2 using lightspaper_table2a_092210uncal.txt, bdec(3) label br

* electricity:
xi: xtreg lndn lnkwh_use i.year, fe robust
outreg2 using lightspaper_table2a_092210uncal.txt, bdec(3) label br

*higher order polynomials:

qui: xi: reg lndn i.isonv10 i.year
predict lndnresid, residual
qui: xi: reg lnlsd i.isonv10 i.year
predict lnlsdresid, residual
corr lndnresid lnlsdresid
qui: xi: reg lngdpwdilocal i.year i.isonv10 
predict lngdpresid, residuals

gen lndnresid2 = lndnresid * lndnresid
gen lndnresid3 = lndnresid2 * lndnresid
gen lndnresid4 = lndnresid3 * lndnresid
gen lndnresid5 = lndnresid4 * lndnresid

reg lngdpresid lndnresid                                            , robust cluster(isonv10)
outreg2 using lightspaper_table2a_092210uncal.txt, bdec(3) label br
reg lngdpresid lndnresid lndnresid2                                 , robust cluster(isonv10)
outreg2 using lightspaper_table2a_092210uncal.txt, bdec(3) label br
reg lngdpresid lndnresid lndnresid2 lndnresid3                      , robust cluster(isonv10)
outreg2 using lightspaper_table2a_092210uncal.txt, bdec(3) label br
reg lngdpresid lndnresid lndnresid2 lndnresid3 lndnresid4           , robust cluster(isonv10)
outreg2 using lightspaper_table2a_092210uncal.txt, bdec(3) label br
reg lngdpresid lndnresid lndnresid2 lndnresid3 lndnresid4 lndnresid5, robust cluster(isonv10)
outreg2 using lightspaper_table2a_092210uncal.txt, bdec(3) label br

* interaction:
xi: xtreg lngdpwdilocal lndn lgini lndnlgini i.year, fe robust cluster(isonv10)
outreg2 using lightspaper_table2a_092210uncal.txt, bdec(3) label br
* translog
xi: xtreg lngdpwdilocal lndn lgini lndnlgini lndnsq lginisq i.year, fe robust cluster(isonv10)
outreg2 using lightspaper_table2a_092210uncal.txt, bdec(3) label br

* table 3
gen poslightresiddum = (lndnresid>0)
gen neglightresiddum = (lndnresid<0)
gen poslightresid = poslightresiddum * lndnresid
gen neglightresid = - neglightresiddum * lndnresid
* baseline
xi: xtreg lngdpwdilocal lndn i.year, fe robust cluster(isonv10)
outreg2 using lightspaper_table3_092210uncal.txt, bdec(3) label br replace
* country trends
xi: xtreg lngdpwdilocal lndn i.year           i.isonv10|year , fe robust
outreg2 using lightspaper_table3_092210uncal.txt, bdec(3) label br
* residuals pos/neg
reg lngdpresid poslightresid neglightresid, cluster(isonv10)
outreg2 using lightspaper_table3_092210uncal.txt, bdec(3) label br 

* RESET test
reg  lngdpresid lndnresid, robust
ovtest

* long difference regressions:
use global_total_dn_uncal_longdiff9206.dta, clear
drop if iso3v10=="GNQ" | iso3v10=="BHR" | iso3v10=="SGP" | iso3v10=="HKG"
drop if missing(lngdpwdilocallongdiff)

reg lngdpwdilocallongdiff lndnlongdiff, robust
ovtest
outreg2 using lightspaper_table3_092210uncal.txt, bdec(3) label br
reg lngdpwdilocallongdiff lndnlongdiff lntopcodedcountlongdiff lnunlitcountlongdiff, robust
outreg2 using lightspaper_table3_092210uncal.txt, bdec(3) label br

* table 4
* LD:
use global_total_dn_uncal_longdiff9206.dta, clear
drop if iso3v10=="GNQ" | iso3v10=="BHR" | iso3v10=="SGP" | iso3v10=="HKG"
drop if missing(lngdpwdilocallongdiff) | missing(lndnlongdiff)
keep if ~missing(wbdqtotal)

gen samp115class2_35 = wbdqtotal>3.5
reg lngdpwdilocallongdiff lndnlongdiff, r
outreg2 using lightspaper_table4_092210uncal.txt, bdec(3) label br replace
xi: reg lngdpwdilocallongdiff i.samp115class2_35*lndnlongdiff, r
outreg2 using lightspaper_table4_092210uncal.txt, bdec(3) label br
* het tests
reg lngdpwdilocallongdiff lndnlongdiff
estat hettest samp115class2_35
predict gdpresid, residual
gen gdpresidsq = gdpresid^2
reg gdpresidsq samp115class2_35
outreg2 using lightspaper_table4_092210uncal.txt, dec(4) label br

* FE:
use global_total_dn_uncal.dta, clear
drop if iso3v10=="GNQ" | iso3v10=="BHR" | iso3v10=="SGP" | iso3v10=="HKG"
drop if missing(lngdpwdilocal) | missing(lndn)
replace year = year-1992
xtset isonv10 year
keep if ~missing(wbdqtotal)
gen samp115class2_35 = wbdqtotal>3.5

* no trends
xi: xtreg lngdpwdilocal                 lndn i.year                , fe robust cluster(isonv10)
outreg2 using lightspaper_table4_092210uncal.txt, bdec(3) label br
xi: xtreg lngdpwdilocal i.samp115class2_35*lndn i.year                , fe robust cluster(isonv10)
outreg2 using lightspaper_table4_092210uncal.txt, bdec(3) label br

* trends
xi: xtreg lngdpwdilocal                 lndn i.year i.isonv10|year , fe robust cluster(isonv10)
outreg2 using lightspaper_table4_092210uncal.txt, bdec(3) label br
xi: xtreg lngdpwdilocal i.samp115class2_35*lndn i.year i.isonv10|year , fe robust cluster(isonv10)
outreg2 using lightspaper_table4_092210uncal.txt, bdec(3) label br

* het tests
qui: xi: reg lngdpwdilocal lndn i.year i.isonv10
predict gdpresid, residual
estat hettest samp115class2_35
gen gdpresidsq = gdpresid^2
reg gdpresidsq samp115class2_35
outreg2 using lightspaper_table4_092210uncal.txt, dec(4) label br

qui: xi: reg lngdpwdilocal lndn i.year i.isonv10 i.isonv10*year
predict gdpresid_trend, residual
estat hettest samp115class2_35
gen gdpresid_trendsq = gdpresid_trend^2
reg gdpresid_trendsq samp115class2_35
outreg2 using lightspaper_table4_092210uncal.txt, dec(4) label br

* table 4a
* 141 sample (needed for statement about how different the 27 rich countries are different from the others)
use global_total_dn_uncal_longdiff9206.dta, clear
drop if iso3v10=="GNQ" | iso3v10=="BHR" | iso3v10=="SGP" | iso3v10=="HKG"
drop if missing(lngdpwdilocallongdiff) | missing(lndnlongdiff)
keep if (imftype=="SDDS" & missing(wbdqtotal)) | ~missing(wbdqtotal)

gen samp141class3 = wbdqtotal>4.5 & ~missing(wbdqtotal)
replace samp141class3 = 2 if imftype=="SDDS" & ~missing(imftype) & missing(wbdqtotal)
gen samp141class2 = samp141class3>1
tab samp141class3 samp141class2 
reg lngdpwdilocallongdiff lndnlongdiff, r
outreg2 using lightspaper_table4a_092210uncal.txt, bdec(4) label br replace
xi: reg lngdpwdilocallongdiff i.samp141class2*lndnlongdiff, r
outreg2 using lightspaper_table4a_092210uncal.txt, bdec(4) label br

* LD:
use global_total_dn_uncal_longdiff9206.dta, clear
drop if iso3v10=="GNQ" | iso3v10=="BHR" | iso3v10=="SGP" | iso3v10=="HKG"
drop if missing(lngdpwdilocallongdiff) | missing(lndnlongdiff)
keep if ~missing(wbdqtotal)

gen samp115class3_3565 = wbdqtotal>3.5
replace samp115class3_3565 = 2 if wbdqtotal>6.5
reg lngdpwdilocallongdiff lndnlongdiff, r
outreg2 using lightspaper_table4a_092210uncal.txt, bdec(4) label br
xi: reg lngdpwdilocallongdiff i.samp115class3_3565*lndnlongdiff, r
outreg2 using lightspaper_table4a_092210uncal.txt, bdec(4) label br
* het tests
reg lngdpwdilocallongdiff lndnlongdiff
outreg2 using lightspaper_table4a_092210uncal.txt, bdec(4) label br
xi: estat hettest i.samp115class3_3565
predict gdpresid, residual
gen gdpresidsq = gdpresid^2
xi: reg gdpresidsq i.samp115class3_3565
outreg2 using lightspaper_table4a_092210uncal.txt, bdec(4) label br

* FE:
use global_total_dn_uncal.dta, clear
drop if iso3v10=="GNQ" | iso3v10=="BHR" | iso3v10=="SGP" | iso3v10=="HKG"
drop if missing(lngdpwdilocal) | missing(lndn)
replace year = year-1992
xtset isonv10 year
keep if ~missing(wbdqtotal)
gen samp115class3_3565 = wbdqtotal>3.5
replace samp115class3_3565 = 2 if wbdqtotal>6.5
gen samp115class3_3565_1 = samp115class3_3565==1
gen samp115class3_3565_2 = samp115class3_3565==2

* no trends
xi: xtreg lngdpwdilocal                 lndn i.year                , fe robust cluster(isonv10)
outreg2 using lightspaper_table4a_092210uncal.txt, bdec(4) label br
xi: xtreg lngdpwdilocal i.samp115class3_3565*lndn i.year                , fe robust cluster(isonv10)
outreg2 using lightspaper_table4a_092210uncal.txt, bdec(4) label br

* trends
xi: xtreg lngdpwdilocal                 lndn i.year i.isonv10|year , fe robust cluster(isonv10)
outreg2 using lightspaper_table4a_092210uncal.txt, bdec(4) label br
xi: xtreg lngdpwdilocal i.samp115class3_3565*lndn i.year i.isonv10|year , fe robust cluster(isonv10)
outreg2 using lightspaper_table4a_092210uncal.txt, bdec(4) label br

* het tests
qui: xi: reg lngdpwdilocal lndn i.year i.isonv10
predict gdpresid, residual
estat hettest  samp115class3_3565_1 samp115class3_3565_2 
gen gdpresidsq = gdpresid^2
xi: reg gdpresidsq i.samp115class3_3565
outreg2 using lightspaper_table4a_092210uncal.txt, bdec(4) label br

qui: xi: reg lngdpwdilocal lndn i.year i.isonv10 i.isonv10*year
predict gdpresid_trend, residual
estat hettest  samp115class3_3565_1 samp115class3_3565_2 
gen gdpresid_trendsq = gdpresid_trend^2
xi: reg gdpresid_trendsq i.samp115class3_3565
outreg2 using lightspaper_table4a_092210uncal.txt, bdec(4) label br

* table 5
* two-sample statistical exercise

use global_total_dn_uncal_longdiff9206.dta, clear
drop if iso3v10=="GNQ" | iso3v10=="BHR" | iso3v10=="SGP" | iso3v10=="HKG"
drop if missing(lngdpwdilocallongdiff) | missing(lndnlongdiff) | missing(wbdqtotal)

gen phiG=.
gen varzG=.
gen varzB=.
gen cov=.
gen varx=.
gen nG=.
gen nB=.
gen nTot=.

gen phiB=.
gen sigmasqx=.
gen sigmasqy=.
gen sigmasqzG=.
gen sigmasqzB=.
gen beta=.
gen lambdaG=.
gen lambdaB=.

local rownum = 0

local rowsboth = 5

local goodsample = "wbdqtotal>3.5"
local badsample = "wbdqtotal<3.5"

forvalues j = 1(1)`rowsboth' {
	local rownum = `rownum' + 1
	replace phiG = 1.1 - `j'*0.1 if _n==`rownum'
	qui: corr lngdpwdilocallongdiff lndnlongdiff if `goodsample', cov
	replace varzG = r(Var_1) if _n==`rownum'
	replace nG = r(N) if _n==`rownum'
	qui: corr lngdpwdilocallongdiff lndnlongdiff if `badsample', cov
	replace varzB = r(Var_1) if _n==`rownum'
	replace nB = r(N) if _n==`rownum'
	qui: corr lngdpwdilocallongdiff lndnlongdiff, cov
	replace varx = r(Var_2) if _n==`rownum'
	replace cov = r(cov_12) if _n==`rownum'
	replace nTot = r(N) if _n==`rownum'

	replace sigmasqy = varzG * phiG if _n==`rownum'
	replace phiB = sigmasqy / varzB if _n==`rownum'
	replace beta = cov / sigmasqy if _n==`rownum'
	replace sigmasqx = varx - cov if _n==`rownum'
	replace sigmasqzB = varzB - sigmasqy if _n==`rownum'
	replace sigmasqzG = varzG - sigmasqy if _n==`rownum'

	replace lambdaB = sigmasqx*sigmasqy / ( sigmasqx*sigmasqy + sigmasqzB*(beta*beta*sigmasqy + sigmasqx) ) if _n==`rownum'
	replace lambdaG = sigmasqx*sigmasqy / ( sigmasqx*sigmasqy + sigmasqzG*(beta*beta*sigmasqy + sigmasqx) ) if _n==`rownum'
}

local rownum = `rownum' + 1
replace phiB = phiB[2] if _n==`rownum'
local phiB = phiB[2]
qui: corr lngdpwdilocallongdiff lndnlongdiff if `badsample', cov
replace varzB = r(Var_1) if _n==`rownum'
replace nB = r(N) if _n==`rownum'
replace varx = r(Var_2) if _n==`rownum'
replace cov = r(cov_12) if _n==`rownum'
replace nTot = r(N) if _n==`rownum'

replace sigmasqy = varzB * phiB if _n==`rownum'
replace beta = cov / sigmasqy if _n==`rownum'
replace sigmasqx = varx - cov if _n==`rownum'
replace sigmasqzB = varzB - sigmasqy if _n==`rownum'

replace lambdaB = sigmasqx*sigmasqy / ( sigmasqx*sigmasqy + sigmasqzB*(beta*beta*sigmasqy + sigmasqx) ) if _n==`rownum'

keep  phiG phiB beta lambdaG lambdaB sigmasqy sigmasqzB sigmasqzG sigmasqx
order phiG phiB beta lambdaG lambdaB sigmasqy sigmasqzB sigmasqzG sigmasqx
* only report sigmas for phiG==0.9 in text - no sigmas in table
foreach i in sigmasqy sigmasqzB sigmasqzG sigmasqx {
	replace `i' = . if abs(phiG - 0.9) > 0.01
}
keep if ~missing(beta)
outsheet using lightspaper_table5_092210uncal.csv, comma replace

* Figure 7
keep if round(phiG * 10)==9
local phi = phiB[1]
local lambda = lambdaB[1]
* stat graph for wbdqtotal<3.5
use global_total_dn_uncal_longdiff9206.dta, clear
drop if iso3v10=="GNQ" | iso3v10=="BHR" | iso3v10=="SGP" | iso3v10=="HKG"
keep if wbdqtotal<3.5 & ~missing(wbdqtotal)
drop if missing(lngdpwdilocallongdiff) | missing(lndnlongdiff)
reg lngdpwdilocallongdiff lndnlongdiff, robust
predict lngdpwdilocalldpred
corr lngdpwdilocallongdiff lndnlongdiff
local rho = r(rho)
gen zero = 0
gen lngdp_ld_opt =.

local years = 13
replace lngdp_ld_opt = `lambda' * lngdpwdilocallongdiff + (1 - `lambda')* lngdpwdilocalldpred
local lambdaround = int(`lambda'*1000+0.5)/1000
local phiround = int(`phi'*1000+0.5)/1000

gen wdipred_annual = exp(lngdpwdilocalldpred/`years') - 1
gen wdi_annual = exp(lngdpwdilocallongdiff/`years') - 1
sort wdi_annual
local slope = -`lambda'/(1-`lambda')
local ymin = 0
local ymax = .08
local xmin = -0.02
local xmax = .11
local iso0 = 0
local iso1 = 0.02
local iso2 = 0.04
local iso3 = 0.06
local iso4 = 0.08

gen tmp0 = (`iso0'+1)^(1/(1-`lambda'))*(wdi_annual+1)^(-`lambda'/(1-`lambda')) - 1
gen tmp1 = (`iso1'+1)^(1/(1-`lambda'))*(wdi_annual+1)^(-`lambda'/(1-`lambda')) - 1
gen tmp2 = (`iso2'+1)^(1/(1-`lambda'))*(wdi_annual+1)^(-`lambda'/(1-`lambda')) - 1
gen tmp3 = (`iso3'+1)^(1/(1-`lambda'))*(wdi_annual+1)^(-`lambda'/(1-`lambda')) - 1
gen tmp4 = (`iso4'+1)^(1/(1-`lambda'))*(wdi_annual+1)^(-`lambda'/(1-`lambda')) - 1

twoway (line wdi_annual wdi_annual if wdi_annual<`xmax' & wdi_annual<`ymax') ///
(line tmp0 wdi_annual if tmp0>`ymin' & tmp0<`ymax' & wdi_annual>`xmin' & wdi_annual<`xmax', lcolor(green)) ///
(line tmp1 wdi_annual if tmp1>`ymin' & tmp1<.06 & wdi_annual>`xmin' & wdi_annual<`xmax', lcolor(green)) ///
(line tmp2 wdi_annual if tmp2>`ymin' & tmp2<`ymax' & wdi_annual>`xmin' & wdi_annual<`xmax', lcolor(green)) ///
(line tmp3 wdi_annual if tmp3>`ymin' & tmp3<`ymax' & wdi_annual>`xmin' & wdi_annual<`xmax', lcolor(green)) ///
(line zero wdi_annual, lcolor(black)) ///
(line wdi_annual zero if wdi_annual<`ymax', lcolor(black)) ///
(scatter wdipred_annual wdi_annual, mlabel(iso3v10) mlabsize(2) msize(.5) mcolor(red) mlabcolor(red) ///
xtitle("annualized % change in GDP, WDI LCU") ytitle("predicted annualized % change in GDP from lights", size(3) bcolor(ltbluishgray) lcolor(ltbluishgray) box bmargin(1 2 1 1)) ///
note("lambda=`lambdaround', phi=`phiround'", ring(0) position(8) bcolor(white) lcolor(black) box bmargin(1 1 1 1)) ///
yscale(range(`ymin' `ymax')) ylabel(0 "0%" .02 "2%" .04 "4%" .06 "6%" .08 "8%") /// 
xlabel(0 "0%" .02 "2%" .04 "4%" .06 "6%" .08 "8%") ///
xline(0(.02).1, lwidth(medthin) lcolor(ltbluishgray)) ///
title("Figure 7: Growth in fitted lights vs. WDI for WBDQ<3.5 countries 1992-2006", size(3.5)) ///
legend(order(1 "identity" 2 "annualized iso-composite growth lines") rows(2) ring(0) position(4)))  

graph export fig7baduncal.ps, replace logo(off)

* Table 6
local ldyears = 13
keep country iso3v10 lngdpwdilocallongdiff lngdpwdilocalldpred lngdp_ld_opt
sort iso3v10
drop if missing(lngdp_ld_opt)
gen difference =  lngdp_ld_opt -  lngdpwdilocallongdiff
* convert to annual growth rates:
replace lngdpwdilocalldpred = exp(lngdpwdilocalldpred / `ldyears') - 1
replace lngdpwdilocallongdiff = exp(lngdpwdilocallongdiff / `ldyears') - 1
replace lngdp_ld_opt = exp(lngdp_ld_opt / `ldyears') - 1
replace difference = exp(difference / `ldyears') - 1
order country
rename  lngdp_ld_opt optimal_combination
rename lngdpwdilocalldpred fitted_lights
rename  lngdpwdilocallongdiff WDI_LCU
sort difference
outsheet using "lightspaper_table6_092210uncal.csv", comma replace

* bootstrap
use global_total_dn_uncal_longdiff9206.dta, clear
drop if iso3v10=="GNQ" | iso3v10=="BHR" | iso3v10=="SGP" | iso3v10=="HKG"
drop if missing(lngdpwdilocallongdiff) | missing(lndnlongdiff) | missing(wbdqtotal)
local badsample = "wbdqtotal<3.5"
bootstrap  beta = (r(cov_12) / (r(Var_1) * `phiB')), reps(200) : corr lngdpwdilocallongdiff lndnlongdiff if `badsample', cov

use global_total_dn_uncal.dta, clear
xtset isonv10 year
drop if iso3v10=="GNQ" | iso3v10=="BHR" | iso3v10=="SGP" | iso3v10=="HKG"
drop if missing(lngdpwdilocal) | missing(lndn)

* calculate predicted values and graph for whole sample
qui: xi: reg lngdpwdilocal lndn i.isonv10 i.year, robust
predict ypred_cfes

* Figure 3 graph: Indonesia
twoway (line lngdpwdilocal year if iso3v10=="IDN") ///
(line ypred_cfes year if iso3v10=="IDN"), ///
xlabel(1992(2)2008) ylabel(34.6(.2)35.2) legend(on order(1 "Actual ln(GDP)" 2 "ln(GDP) predicted by lights") ///
cols(2) position(5) ring(0) size(8)) xsize(3.9) ysize(1.1)

graph export IDN_trend_graph_uncal_allyears.tif, replace

* Figure 4 graph: Rwanda
twoway (line lngdpwdilocal year if iso3v10=="RWA") ///
(line ypred_cfes year if iso3v10=="RWA", ///
xlabel(1992(2)2008) legend(on order(1 "Actual ln(GDP)" 2 "ln(GDP) predicted by lights") cols(2) position(5) ring(0)) ///
xsize(5.1) ysize(3.525))

graph export RWA_trend_graph_uncal_allyears.tif, replace

* Figure 6a
use global_total_dn_uncal.dta, clear
xtset isonv10 year
drop if iso3v10=="GNQ" | iso3v10=="BHR" | iso3v10=="SGP" | iso3v10=="HKG"
drop if missing(lngdpwdilocal) | missing(lndn)

* FE scatter:
qui xi: reg lngdpwdilocal i.isonv10 i.year if ~missing(lndn)
predict lngdpresid, residuals
qui xi: reg lndn i.isonv10 i.year if ~missing(lngdpwdilocal) 
predict lndnresid, residual
lab var lngdpresid "ln(GDP) net of country and year fixed effects"
lab var lndnresid "ln(lights/area) net of country and year fixed effects"
lowess lngdpresid lndnresid , msize(tiny) ylabel(-1(.5).5) xlabel(-1(.5)1) xline(-1(.5)1, lwidth(medthin) lcolor(ltbluishgray)) title("Figure 6a. GDP versus lights: overall panel") 
graph export Fig6a_panelscatter_notrends.ps, replace 
* Figure A1
lowess lngdpresid lndnresid if abs(lndnresid)<0.4, msize(tiny) ylabel(-.4(.4).4) xlabel(-.4(.2).4) xline(-.4(.2).4, lwidth(medthin) lcolor(ltbluishgray)) ///
title("Figure 6b. GDP versus lights: restricted interval panel") note("notes: 1. bandwidth = .8; 2. excludes 5% of country-years to the left and right")
graph export FigA1_panelscatter_notrends_lim.ps, replace 

* Figure 6b
use global_total_dn_uncal_longdiff9206.dta, clear
drop if iso3v10=="GNQ" | iso3v10=="BHR" | iso3v10=="SGP" | iso3v10=="HKG"
drop if missing(lngdpwdilocallongdiff) | missing(lndnlongdiff)
twoway (scatter lngdpwdilocallongdiff lndnlongdiff, yscale(range(-.2 1.4)) ///
ylabel(0(.4)1.2) xlabel(-.8(.4)2) msize(tiny) mlabel(iso3v10) mlabsize(tiny) ///
xline(-.8 -.4 0 .4 .8 1.2 1.6 2, lwidth(medthin) lcolor(ltbluishgray)) ///
ytitle("ln(GDP 05-06) - ln(GDP 92-93)") ///
title("Figure 6b. GDP versus lights: long differences")) ///
(lowess lngdpwdilocallongdiff lndnlongdiff), note("bandwidth = .8") legend(off)
graph export Fig6b_LDscatter.ps, replace

* Appendix table:

foreach i in "mean" "sd" "min" "max" "count" {
	use global_total_dn_uncal.dta, clear
	drop if iso3v10=="BHR" | iso3v10=="SGP" | iso3v10=="GNQ"
	drop if missing(lndn) | missing(lngdpwdilocal)
	collapse (`i') lndn lngdpwdilocal lnkwh_use fraccellstopcoded fracunlit lgini
	xpose, varname clear
	rename v1 `i'
	save `i'1, replace
}

foreach i in "mean" "sd" "min" "max" "count" {
	use global_total_dn_uncal.dta, clear
	drop if iso3v10=="BHR" | iso3v10=="SGP" | iso3v10=="GNQ"
	drop if missing(lndn) | missing(lngdpwdilocal)
	drop if missing(wbdqtotal)
	collapse (`i') lndn lngdpwdilocal 
	xpose, varname clear
	rename v1 `i'
	save `i'2, replace
}

foreach i in "mean" "sd" "min" "max" "count" {
	use global_total_dn_uncal.dta, clear
	drop if iso3v10=="BHR" | iso3v10=="SGP" | iso3v10=="GNQ"
	drop if missing(lndn) | missing(lngdpwdilocal)
	drop if missing(wbdqtotal) | wbdqtotal>3.5
	collapse (`i') lndn lngdpwdilocal 
	xpose, varname clear
	rename v1 `i'
	save `i'3, replace
}

foreach i in "mean" "sd" "min" "max" "count" {
	use global_total_dn_uncal_longdiff9206.dta, clear
	drop if iso3v10=="BHR" | iso3v10=="SGP" | iso3v10=="GNQ"
	drop if missing(lndnlongdiff) | missing(lngdpwdilocallongdiff)
	collapse (`i') lndnlongdiff lngdpwdilocallongdiff
	xpose, varname clear
	rename v1 `i'
	save `i'4, replace
}

foreach i in "mean" "sd" "min" "max" "count" {
	use global_total_dn_uncal_longdiff9206.dta, clear
	drop if iso3v10=="BHR" | iso3v10=="SGP" | iso3v10=="GNQ"
	drop if missing(lndnlongdiff) | missing(lngdpwdilocallongdiff)
	drop if missing(wbdqtotal)
	collapse (`i') lndnlongdiff lngdpwdilocallongdiff
	xpose, varname clear
	rename v1 `i'
	save `i'5, replace
}

foreach i in "mean" "sd" "min" "max" "count" {
	use global_total_dn_uncal_longdiff9206.dta, clear
	drop if iso3v10=="BHR" | iso3v10=="SGP" | iso3v10=="GNQ"
	drop if missing(lndnlongdiff) | missing(lngdpwdilocallongdiff)
	drop if missing(wbdqtotal) | wbdqtotal>3.5
	collapse (`i') lndnlongdiff lngdpwdilocallongdiff
	xpose, varname clear
	rename v1 `i'
	save `i'6, replace
}

foreach i in "mean" "sd" "min" "max" "count" {
	clear
	gen `i' = .
	forvalues j = 1(1)6 {
		append using `i'`j'
		erase `i'`j'.dta
	}
	save `i', replace
}

use mean, clear
foreach i in "mean" "sd" "min" "max" "count" {
	merge using `i', _merge(_m`i')
	erase `i'.dta
}
sum _m*
drop _m*
rename _varnam variable
order variable

replace variable = "ln(lights)" if variable=="lndn"
replace variable = "delta ln(lights)" if variable=="lndnlongdiff"
replace variable = "ln(GDP, LCU)" if variable=="lngdpwdilocal"
replace variable = "delta ln(GDP, LCU)" if variable=="lngdpwdilocallongdiff"

replace variable = "ln(electricity use)" if variable=="lnkwh_use"
replace variable = "fraction topcoded" if variable=="fraccellstopcoded"
replace variable = "fraction unlit" if variable=="fracunlit"
replace variable = "spatial gini" if variable=="lgini"

* note this depends on the exact set of vars and samples considered:
gen sample = ceil(_n/2) - 2
replace sample = 1 if sample < 1
replace sample = mod(sample - 1,3) + 1

lab def samples 1 "full" 2 "low-middle income" 3 "low-middle income, DQ score 0-3"
lab val sample samples
outsheet using lightspaper_tableB1_092210uncal.csv, comma replace

display c(current_time)
* table A1
clear
set mem 900m
* import a cell-level file of calibrated and uncalibrated data from 1997:
insheet using samptab.txt, tab clear
* calculate row and column numbers based on latitude and longitude coordinates:
gen int row = round((75-y)*120)+1
gen long col = round((x+180)*120)+1
* create local addresses by which which neighboring cells can be agggregated to various levels:
foreach i in 1 2 5 10 20 40 80 100 {
	gen long ag`i' = ceil(row/`i')*100000 + ceil(col/`i')
}
drop x y row col
* restrict to cells that are lit in both datasets:
drop if l121997nm==0
* apply the scaling factor associated with the calibrated data:
gen radcalnz15 = radcalnz^1.5
drop radcalnz
save samptabagprep.dta, replace

gen lnl121997nm = ln(l121997nm)
drop l121997nm
gen lnradcalnz15 = ln(radcalnz15)
drop radcalnz15

* regress the uncalibrated on the calibrated:
reg lnl121997nm lnradcalnz15, robust
outreg2 using lightspaper_tableA1_092210uncal.txt, sdec(5) bdec(5) label br replace

* regress aggregated versions of the uncalibrated on the calibrated for increasing levels of aggregation:
foreach i in 2 5 10 20 40 80 100 {
	use samptabagprep.dta, clear
	keep radcalnz15 l121997nm ag`i'
	collapse (sum) radcalnz15 l121997nm, by(ag`i')
	gen lnl121997nm = ln(l121997nm)
	drop l121997nm
	gen lnradcalnz15 = ln(radcalnz15)
	drop radcalnz15
	reg lnl121997nm lnradcalnz15, robust
	outreg2 using lightspaper_tableA1_092210uncal.txt, sdec(5) bdec(5) label br
}

display c(current_time)
log close
exit, clear
