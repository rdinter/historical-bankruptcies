# NASS API for their Quickstats web interface:
# https://quickstats.nass.usda.gov/

# --- start ---------------------------------------------------------------

# devtools::install_github("rdinter/usdarnass")
library("usdarnass")
library("tidyverse")

not_all_na <- function(x) any(!is.na(x))

# Create a directory for the data
local_dir    <- "0-data/NASS"
data_source <- paste0(local_dir, "/raw")
if (!file.exists(local_dir)) dir.create(local_dir)
if (!file.exists(data_source)) dir.create(data_source)

# ---- operations ----------------------------------------------------------

operations <- nass_data(source_desc = "SURVEY", agg_level_desc = "NATIONAL",
                        commodity_desc = "FARM OPERATIONS",
                        short_desc = "FARM OPERATIONS - NUMBER OF OPERATIONS",
                        domain_desc = "TOTAL",
                        numeric_vals = T)

operations <- operations %>% 
  select(year, farms = Value) %>% 
  arrange(year) %>% 
  mutate(farm_change = farms - lag(farms),
         farm_pct_change = scales::percent(farm_change / lag(farms)))

write_csv(operations, paste0(local_dir, "/operations.csv"))
