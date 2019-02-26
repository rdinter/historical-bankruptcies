# Compiling archived F-5A data from Ernie Goss

# ---- start --------------------------------------------------------------

library("lubridate")
library("tidyverse")

local_dir   <- "0-data/uscourts/archived/f5a"
data_source <- paste0(local_dir, "/raw")
if (!file.exists(local_dir)) dir.create(local_dir)
if (!file.exists(data_source)) dir.create(data_source)

csv_files <- dir(data_source, pattern = ".csv", full.names = T)

temp <- csv_files %>% 
  map(read_csv, col_types = cols(.default = "c")) %>% 
  bind_rows() %>% 
  mutate_at(vars(YEAR, FIPS:NBCHAP_13), parse_number)


temp <- temp %>% 
  select(-ST) %>% 
  mutate(NAME = toupper(NAME),
         NAME = gsub(",", "", NAME),
         NAME = gsub("\\.", "", NAME))

j5 <- temp %>% 
  group_by(YEAR, NAME, FIPS) %>% 
  summarise_all(function(x) sum(x, na.rm = T))

districts <- read_csv("0-data/uscourts/district_ns.csv")

j5 <- j5 %>% 
  filter(!is.na(FIPS), FIPS != 0,
         FIPS != 15005, FIPS != 40413) %>% 
  # filter(!(NAME %in% c(districts$DISTRICT_NS,
  #                      districts$CIRCUIT_NUM, "TOTAL", "0"))) %>% 
  arrange(FIPS, YEAR) %>% 
  ungroup()

# j5 <- j5 %>% 
#   mutate(FIPS = case_when(FIPS == 13150 ~ 13215,
#                           FIPS == 13510 ~ 13215,
#                           FIPS == 24007 ~ 24005,
#                           FIPS == 24510 ~ 24005,
#                           FIPS == 29193 ~ 29186,
#                           T ~ FIPS)) %>% 
#   group_by(YEAR, FIPS) %>% 
#   select(-NAME) %>% 
#   summarise_all(funs(sum(., na.rm = T))) %>% 
#   ungroup()

write.csv(j5, file = paste0(local_dir, "/f5a_goss.csv"), row.names = F)
write_rds(j5, paste0(local_dir, "/f5a_goss.rds"))