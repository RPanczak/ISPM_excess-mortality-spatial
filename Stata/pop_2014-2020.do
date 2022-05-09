forv YR = 14/20 {

	import delim "C:\projects\ISPM_geo-mortality\data-raw\BfS-closed\STATPOP\statpop20`YR'_220098p.csv", clear 
	
	drop classagefiveyears statdate

	* only data linkable to GWS
	fre indic_egid
	keep if indic_egid == 1
	drop indic_egid
	
	* only main type of residence(Ständige Wohnbevölkerung)
	fre populationtype
	keep if populationtype == 1
	drop populationtype

	* that also solves - only main place of residence (Hauptwohnsitz)
	fre typeofresidence
	keep if typeofresidence == 1
	drop typeofresidence
	
	* still posible to include only (Nur ein Hauptwohnsitz) TBC @ BfS
	fre mainresidencecategory
	* keep if typeofresidence == 1	
	drop mainresidencecategory
	
	* su age
	* mdesc geocoord?
	
	rename statyear year
	rename nationalitycategory nationality
	rename federalbuildingid egid
	order egid, first

	sa "C:/projects/ISPM_geo-mortality/data/BfS-closed/STATPOP/r`YR'_pe.dta", replace

}

/* coordinates checksortsort egid, stable
by egid: egen egid_max = max(geocoorde)
by egid: egen egid_min = min(geocoorde)

count if egid_max != egid_min
*/