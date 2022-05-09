import delim "C:\projects\ISPM_geo-mortality\data-raw\BfS-closed\SNC\SNC_220098p.csv", clear

keep sncid mortid dod dob sex death_count imputed last_census_seen r??_geo?

ren dod dob last_census_seen, u

g dob = date(DOB, "MDY")
g dod = date(DOD, "MDY")
g last_census_seen = date(LAST_CENSUS_SEEN, "MDY")
format dod dob last_census_seen %tdCCYY-NN-DD
order dob dod last_census_seen, a(mortid)
drop LAST_CENSUS_SEEN DOB DOD

keep if dod >= mdy(1,1,2014) & !missing(dod)

gen yod = year(dod)
order yod, a(dod)
fre yod

* death_count
fre death_count
ta yod death_count, m
keep if death_count == 1
drop death_count 

* imputed
fre imputed 
ta yod imputed, m row
keep if imputed == 0
drop imputed

* last_census_seen
ta last_census_seen yod, m


* br if yod == 2014 & last_census_seen > mdy(12, 31, 2014)
* br if yod == 2015 & last_census_seen > mdy(12, 31, 2015)

drop if yod == 2014 & last_census_seen > mdy(12, 31, 2014)
drop if yod == 2015 & last_census_seen > mdy(12, 31, 2015)
drop if yod == 2016 & last_census_seen > mdy(12, 31, 2016)
drop if yod == 2017 & last_census_seen > mdy(12, 31, 2017)
drop if yod == 2018 & last_census_seen > mdy(12, 31, 2018)

drop last_census_seen

* XY coordinates
* mdesc *_geox
* mvpatterns *_geox, sort

d r??_geox r??_geoy

* precison below m???
replace r10_geox = round(r10_geox)
replace r10_geoy = round(r10_geoy)
replace r11_geox = round(r11_geox)
replace r11_geoy = round(r11_geoy)

compress 

* last coordinates available
g int geoyear = .
g long geox = .
g long geoy = .

forv year = 10/19 {
	
	replace geox = r`year'_geox if !mi(r`year'_geox)
	replace geoy = r`year'_geoy if !mi(r`year'_geoy)
	replace geoyear = 2000 + `year' if !mi(r`year'_geox)
	
}

drop r??_geox r??_geoy
ta geoyear yod, m row

gen int age_death = (dod - dob)/365.25

order age_death, a(yod)

sa "C:/projects/ISPM_geo-mortality/data/BfS-closed/SNC/deaths.dta", replace