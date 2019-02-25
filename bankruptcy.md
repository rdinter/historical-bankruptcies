# Farm Bankruptcies

- [FJC data exploration](2-eda/bankruptcy/2-fjc-individual)
- [FJC Survival Paper](5-results/survival/5-aaea-survival-2018)

Main project for this repository, which has the overarching goal of analyzing how farm financial stress has varied in recent years. The primary measure here is to utilize farm bankruptcies as a proxy for financial stress. This involved a time consuming process of understanding what a farm bankruptcy is, how it has changed over time, and where we can find the data.

## Organization

1. Main data sources are through the [USCourts](0-data/uscourts), which contains current and historical values of bankruptcies. There are filings at the district level since 1987 for every quarter (subject to some imputation) and for every month since 2007. We are in the process of adding county level data (from where the filers place of residence), which we have for every quarter since September of 2012.
    - Additional data found through the [Federal Judicial Center](https://www.fjc.gov/research/idb/bankruptcy-cases-filed-terminated-and-pending-fy-2008-present) that includes government fiscal year filings since 2008. This data includes cases filed, pending, and terminated in that particular year.
    - Potential for use with the [ICPSR Data](https://www.icpsr.umich.edu/icpsrweb/ICPSR/series/72) of the same FJC data above but going back to 1994.
2. Data are put into the tidy format in [1-tidy/bankruptcy](1-tidy/bankruptcy). If you want raw data of [state bankruptcies](1-tidy/bankruptcy/banks_state.csv), [time series data](1-tidy/bankruptcy/time.csv), or [an annual time series](1-tidy/bankruptcy/time_annual.csv) of the relevant data then click those links.
3. Exploratory data analysis is performed in [2-eda/bankruptcy](2-eda/bankruptcy). As of right now, the only exploration is a [long-winded and winding](2-eda/bankruptcy/2-bankruptcy-initial.html) analysis of the data and now a shorter [FJC Data exploration](2-eda/bankruptcy/2-fjc-individual) for the publicly available FJC dataset.
4. The [3-basic/bankruptcy](3-basic/bankruptcy) repository is pretty barren because most of the analysis is done in NORC and therefore confidential.
5. At the moment, there is no [4-advanced/bankruptcy](4-advanced/bankruptcy) folder but with more research on the topic there might be.
6. The basic outputs for this project can be found in [5-results/bankruptcy](5-results/bankruptcy) which contains the following:
    - [Farm Science Review Questions](5-results/bankruptcy/5-FSR) - questions related to farm financial stress to be presented at farm science review.
    - [EAAE Presentation](5-results/bankruptcy/5-EAAE-presentation) - a rough draft version of the European Association of Agricultural Economists (EAAE) that has been presented multiple times previously.
    - [Bankruptcies Website](5-results/bankruptcy/bankruptcies-website) - a rough draft version of trying to disseminate bankruptcy data information to a larger audience.
    - [Farmer Mac](5-results/bankruptcy/farmer-mac) - similarly to the published version of our Farmer Mac [Summer 2017](https://www.farmermac.com/wp-content/uploads/The-Feed-Spring-2017.pdf).
7. Final touches of finished products are found in [6-edits/bankruptcy](6-edits/bankruptcy).
    - [AFR referee response](6-edits/bankruptcy/afr-response.html) contains my loose thoughts of the three referee reports we received.

## Tasks

There are limited number of tasks related to this project since it is far along. Currently, the tasks are:

1. Finish response to AFR referees and the edits of the submission.
2. Data finding, there are a few places where we could access F-5A data that could be pursued. This would be county level bankruptcy filings.
3. Salvage the [bankruptcies website](5-results/bankruptcy/bankruptcies-website) output into a choices style article on bankruptcies.
4. Does FCA data fit within this project? That needs to be parsed through.