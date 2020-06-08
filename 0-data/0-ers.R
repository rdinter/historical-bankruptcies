# Capitalization rate information, mostly from USDA-ERS:
# https://data.ers.usda.gov/reports.aspx?ID=17838

# Can't really download this in any automated way, so a manual update to the
#  "capitalization_rate.csv" file in the cap_rate folder needs to be done.
#  The "Total rate of return on farm equity" entry is what is used for the
#  equity rate variable titled "equity_rate_usda"

# Keep in mind that the values used for capitalization rates may be jumbled!
#  For instance, the rollbacks used in the tax year 2019 formula would be based
#  on the value that ODT has for the tax year 2018! Please read the 
#  documentation for the capitalization rate


# ---- start --------------------------------------------------------------

library("httr")
library("readxl")
library("rvest")
library("tidyverse")

# Create a directory for the data
local_dir    <- "0-data/ers"
data_source  <- paste0(local_dir, "/raw")
if (!file.exists(local_dir)) dir.create(local_dir, recursive = T)
if (!file.exists(data_source)) dir.create(data_source, recursive = T)

# ---- download ----------------------------------------------------------

# Go to url with the all of the current and archived data to scrape the links
ers_links <- paste0("https://www.ers.usda.gov/data-products/",
                    "farm-income-and-wealth-statistics/",
                    "data-files-us-and-state-level-farm-income-",
                    "and-wealth-statistics/") %>% 
  read_html() %>% 
  html_nodes("hr~ ul a:nth-child(1)") %>% 
  html_attr("href") %>% 
  paste0("https://www.ers.usda.gov", .)

# Remove any links that aren't the weathstatisticsdata
ers_links <- ers_links[grepl("wealthstatisticsdata", ers_links)]

# Download the most recent only if it hasn't already been downloaded
fil <- paste(data_source, basename(ers_links[1]), sep = "/")
if (!file.exists(fil)) download.file(ers_links[1], fil)

# Read in the most recent data file
# ers <- read_csv(fil, local = locale(encoding = "latin1"))
# 
# ers %>% 
#   filter(VariableDescriptionTotal %in%
#            c("Net cash income", "Net farm income")) %>%
#   View()
#  
# 
