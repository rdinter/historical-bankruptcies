# Farmer Bankruptcy Data

This repository is meant as a way to disseminate data related to bankruptcies in the United States with a specific focus on farmer bankruptcies -- usually referred to as chapter 12. Chapter 12 was enacted in 1986 as a response to the 1980s farm crisis and it went into effect on November 26, 1986.

Please see our [Frequently Asked Questions](FAQ) section to better understand farm bankruptcies (ie chapter 12), the data, and the limitations in interpreting the data.

The data are at differing levels of observation with [national](1-tidy/bankruptcy/national_annual.csv) annually for both the calendar year and the fiscal year since the passage of Chapter 12. The government fiscal years goes from October 1 to September 30 for each year. In 1995, these [national](1-tidy/bankruptcy/national_quarterly.csv) values are available at the quarterly level as well as at the court [district](1-tidy/bankruptcy/district_quarterly.csv) level. In 2001, information on all other chapters of bankruptcy (business and non-business) are available for [national](1-tidy/bankruptcy/national_quarterly_all.csv) and [district](1-tidy/bankruptcy/district_quarterly_all.csv). And in 2007, the data are available at the monthly level onward for both the [national](1-tidy/bankruptcy/national_monthly.csv) and [district](1-tidy/bankruptcy/district_monthly.csv). Please see the [data issues](FAQ) for these data sources before using the data in an analysis.

<!--- County level data are available annually from 1990 onward and quarterly from September 2008 onward. County level data is generally problematic for bankruptcies because the listed county is for the residence of the bankruptcy filer and this may not correspond to where a business operates. For farmers, we do not find this to be a major issue as a filer of chapter 12 must be active in farming and most farmers will reside at or near their farming operation. --->


## Repository Organization

For most users, the raw data are of the most importance and they are referenced above. However, this project is open-source and meant to be allow users to replicate the results to cross-check the validity of the data. If any errors are found, please submit a pull request.

- Raw data can be found in the [0-data](0-data)
- Tidy data can be found in [1-tidy](1-tidy)
- Some generic figures can be found in [2-eda](2-eda)

## Packages Needed

A few packages needs to be installed to maintain this repository. Most of these are on CRAN and can be installed with the `install.packages()` command but one requires the devtools to be installed to install a package on GitHub:

```R
install.packages("devtools", "gdata", "haven", "httr", "lubridate", "readxl", "rvest", "stringr", "tidyverse", "zipcode", "zoo")
devtools::install_github("rdinter/usdarnass")
```

A quick reasoning for each package:

- gdata - for some old excel files which cannot be read with up to date packages
- haven - to read SAS files for the FJC data
- httr - web scraping the USCourts.gov
- lubridate - formatting for time series data
- readxl - reading newer excel files
- rvest - web scraping the USCourts.gov
- stringr - useful for string parsing
- tidyverse - useful for data munging
- usdarnass - downloading data from QuickStats
- zipcode - determining latitude and longitudes for locations in the FJC data
- zoo - useful for time series data
