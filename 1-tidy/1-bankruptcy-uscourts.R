# Some tidy datasets for bankruptcies

# To do: national level bankruptcies at the annual level, one by calendar year
# the other by the fiscal but in the same sheet. Same for districts?

# ---- start --------------------------------------------------------------


library("lubridate")
library("stringr")
library("tidyverse")
library("zoo")

local_dir   <- "1-tidy/bankruptcy"
if (!file.exists(local_dir)) dir.create(local_dir, recursive = T)

# ---- national -----------------------------------------------------------

dates  <- seq(as.Date("1987/04/01"), Sys.Date(), by = "3 month") - 1

bank_dates  <- read_rds("0-data/uscourts/f2_three/f2_three.rds") %>%
  expand(nesting(DISTRICT_NS, DISTRICT, CIRCUIT, CIRCUIT_NUM, ST_ABRV),
         DATE = dates)

banks  <- read_rds("0-data/uscourts/f2_three/f2_three.rds") %>% 
  right_join(bank_dates)

natty <- banks %>% 
  group_by(YEAR) %>% 
  summarise(CHAP_12 = sum(impute, na.rm = T))

banks %>% 
  group_by(FISCAL_YEAR) %>% 
  summarise(CHAP_12_FISCAL = sum(impute, na.rm = T)) %>% 
  rename(YEAR = FISCAL_YEAR) %>% 
  right_join(natty) %>% 
  filter(!is.na(YEAR)) %>% 
  write_csv(paste0(local_dir, "/national_annual.csv"))

banks %>% 
  filter(DATE > "1995-12-30") %>% 
  group_by(DATE) %>% 
  summarise(CHAP_12 = sum(impute, na.rm = T)) %>% 
  write_csv(paste0(local_dir, "/national_quarterly.csv"))

banks %>% 
  filter(!is.na(TOTAL_FILINGS)) %>% 
  select(STATE:NBCHAP_13, YEAR:ST_ABRV) %>% 
  group_by(DATE) %>% 
  summarise_at(vars(TOTAL_FILINGS:NBCHAP_13), list(~sum(., na.rm = T))) %>% 
  write_csv(paste0(local_dir, "/national_quarterly_all.csv"))


# ---- district -----------------------------------------------------------

banks %>% 
  filter(DATE > "1995-12-30") %>% 
  group_by(DATE, DISTRICT, STATE, CIRCUIT) %>% 
  summarise(CHAP_12 = sum(impute, na.rm = T)) %>% 
  write_csv(paste0(local_dir, "/district_quarterly.csv"))


banks %>% 
  filter(!is.na(TOTAL_FILINGS)) %>% 
  select(STATE:NBCHAP_13, YEAR:ST_ABRV) %>% 
  group_by(DATE, DISTRICT, STATE, CIRCUIT) %>% 
  summarise_at(vars(TOTAL_FILINGS:NBCHAP_13), list(~sum(., na.rm = T))) %>% 
  write_csv(paste0(local_dir, "/district_quarterly_all.csv"))

# ---- monthly ------------------------------------------------------------

monthly <- read_rds("0-data/uscourts/f2_one/f2_one.rds")

monthly %>% 
  filter(!is.na(TOTAL_FILINGS)) %>% 
  select(STATE:NBCHAP_13, DATE, YEAR:ST_ABRV) %>% 
  group_by(DATE) %>% 
  summarise_at(vars(TOTAL_FILINGS:NBCHAP_13), list(~sum(., na.rm = T))) %>% 
  write_csv(paste0(local_dir, "/national_monthly.csv"))


monthly %>% 
  filter(!is.na(TOTAL_FILINGS)) %>% 
  select(STATE:NBCHAP_13, DATE, YEAR:ST_ABRV) %>% 
  group_by(DATE, DISTRICT, STATE, CIRCUIT) %>% 
  summarise_at(vars(TOTAL_FILINGS:NBCHAP_13), list(~sum(., na.rm = T))) %>% 
  write_csv(paste0(local_dir, "/district_monthly.csv"))


# ---- county -------------------------------------------------------------

county <- read_rds("0-data/uscourts/f5a/f5a.rds") %>% 
  filter(grepl("12/31/", QTR_ENDED)) %>% 
  select(-NBCHAP_12) %>% 
  group_by(DATE, FIPS) %>% 
  summarise_at(vars(TOTAL_FILINGS:NBCHAP_13), ~sum(., na.rm = T)) %>% 
  ungroup()

goss   <- read_rds("0-data/uscourts/archived/f5a/f5a_goss.rds") %>% 
  mutate(DATE = as.Date(paste0(YEAR, "-12-31"))) %>% 
  select(-YEAR, -NAME)

j5 <- county %>% 
  full_join(goss) %>% 
  complete(DATE, FIPS)

write_csv(j5, paste0(local_dir, "/county_annual.csv"))
