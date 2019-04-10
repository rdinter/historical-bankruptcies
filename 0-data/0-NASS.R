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
  select(YEAR = year, FARMS = Value) %>% 
  arrange(YEAR) %>% 
  mutate(FARM_CHANGE = FARMS - lag(FARMS),
         FARM_PCT_CHANGE = scales::percent(FARM_CHANGE / lag(FARMS)))

write_csv(operations, paste0(local_dir, "/operations.csv"))


# ---- state-farms --------------------------------------------------------

state_farms <- nass_data(source_desc = "CENSUS", agg_level_desc = "STATE",
                         commodity_desc = "FARM OPERATIONS",
                         short_desc = "FARM OPERATIONS - NUMBER OF OPERATIONS",
                         domain_desc = "TOTAL",
                         numeric_vals = T)

state_farms <- state_farms %>% 
  select(YEAR = year, FARMS = Value, STATE = state_name) %>% 
  arrange(YEAR, STATE) %>% 
  group_by(STATE) %>% 
  mutate(FARM_CHANGE = FARMS - lag(FARMS),
         FARM_PCT_CHANGE = scales::percent(FARM_CHANGE / lag(FARMS)))

