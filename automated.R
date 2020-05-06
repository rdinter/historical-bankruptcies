# Robert Dinterman
# Automated bankruptcy data


# ---- data ---------------------------------------------------------------

# Download new data from USCourts.gov and FJC
source("0-data/0-uscourts-data.R") # new updates takes about 20 minutes dl time
source("0-data/0-fjc-data.R") # WARINING: this is a large download
# not needed anymore:
# source("0-uscourts-counties.R") # 0-data/uscourts/district_counties.csv

# Parsing files
source("0-data/0-uscourts-f2-one.R") # monthly data
source("0-data/0-uscourts-f2-three.R") # quarterly data
source("0-data/0-uscourts-f5a.R") # county level data
# This will take a long time:
# source("0-data/0-fjc-parse.R") # individual filings

# ---- tidy ---------------------------------------------------------------

# Automatically organizes the raw data into a consistent format
source("1-tidy/1-bankruptcy-uscourts.R")
source("1-tidy/1-bankruptcy-fjc.R")
