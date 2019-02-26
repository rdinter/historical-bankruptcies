# Robert Dinterman
# Combining the F-2 Judicial Tables from 1987 and onward, with a twist

# ---- start --------------------------------------------------------------


library("lubridate")
library("tidyverse")

dists <- read_csv("0-data/uscourts/district_ns.csv")

base <- expand.grid(DATE = seq(as.Date("1987/01/01"),
                               Sys.Date(), by = "3 month") - 1,
                    DISTRICT_NS = dists$DISTRICT_NS) %>% 
  left_join(dists) %>% 
  arrange(DISTRICT, DATE)

f2j <- read_csv("0-data/uscourts/archived/f2/f2_full.csv") %>% 
  mutate(month = month(DATE), FISCAL_YEAR = year(DATE)) %>% 
  filter(month == 9, !is.na(STATE)) %>% 
  select(-month)

f2j <- read_csv("0-data/uscourts/f2_judicial/f2_judicial.csv") %>% 
  bind_rows(f2j) %>% 
  distinct() %>% 
  select(DATE, STATE, DISTRICT, DISTRICT_NS,
         CIRCUIT, CHAP_12_j = CHAP_12) %>% 
  arrange(DISTRICT, DATE)

base <- base %>% 
  left_join(f2j) %>% 
  mutate(CHAP_12_j_q = CHAP_12_j / 4) %>% 
  fill(CHAP_12_j_q, .direction = "up")

quarters <- read_rds("0-data/uscourts/f2_three/f2_three.rds") %>% 
  select(DATE, STATE, DISTRICT, DISTRICT_NS,
         CIRCUIT, CHAP_12_q = CHAP_12)

base <- base %>% 
  left_join(quarters) %>% 
  mutate(CHAP_12_impute = ifelse(is.na(CHAP_12_q), CHAP_12_j_q, CHAP_12_q))

# ADD IN TEMPORARY IMPUTATION METHOD FOR QUARTERLY DATA
impute <- read_rds("0-data/uscourts/archived/f2/f2_impute.rds") %>% 
  filter(!is.na(STATE)) %>%
  select(-CHAP_12, -CHAP_12_full, -impute1, -QTR_ENDED)

base <- base %>% 
  left_join(impute) %>% 
  mutate(impute = ifelse(is.na(impute), CHAP_12_q, impute),
         YEAR = year(DATE),
         FISCAL_YEAR = year(floor_date(DATE + 1, unit = "year")))

write_csv(base, "0-data/uscourts/imputed_banks.csv")
write_rds(base, "0-data/uscourts/imputed_banks.rds")
