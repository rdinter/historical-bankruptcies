# Downloading files from uscourts.gov on bankruptcy
# https://www.fjc.gov/research/idb
#  bankruptcy-cases-filed-terminated-and-pending-fy-2008-present

# ---- start --------------------------------------------------------------

library("haven")
library("stringr")
library("tidyverse")
sumn <- function(x) sum(x, na.rm = T)

# Create a directory for the data
local_dir    <- "0-data/fjc/IDB"
data_source <- paste0(local_dir, "/raw")
if (!file.exists(local_dir)) dir.create(local_dir, recursive = T)
if (!file.exists(data_source)) dir.create(data_source)

# ---- parse --------------------------------------------------------------

districts <- read_csv("0-data/fjc/district_cross.csv") %>% 
  rename_all(toupper)

fjc_files <- dir(data_source, full.names = T)
fjc_files <- fjc_files[!grepl("on_0", fjc_files)]

# All as a tsv -- runs into memory issues due to >= 4GB file
# j5_tsv <- read_tsv("0-data/fjc/IDB/raw/cpbank08on_0.zip",
#                    col_types = cols(.default = "c"))
# j5_vroom <- vroom::vroom("0-data/fjc/IDB/raw/cpbank08on_0.zip",
#                          delim = "\t",
#                          col_types = cols(.default = "c"))
# j5_fread <- data.table::fread("unzip -p 0-data/fjc/IDB/raw/cpbank08on_0.zip")

j5 <- map(fjc_files, read_sas)

# Convert these vars:
# ORGFLCHP CRNTCHP CLCHPT

# October 17, 2005
# 7 = Chapter 7
# 9 = Chapter 9
# 11 = Chapter 11
# 13 = Chapter 13
# 12 = Chapter 12
# 15a = Chapter 15 foreign main proceeding, or in the
# alternative, foreign nonmain proceeding
# 15m = Chapter 15 foreign main proceeding
# 15n = Chapter 15 foreign nonmain proceeding
# 15x = Chapter 15 (unknown whether main or nonmain; used for
#                   cases filed 10/17/05 through 10/16/2006)
# Blank = Missing 

# Before
# 1 = Chapter 7
# 4 = Chapter 9
# 5 = Chapter 11
# 7 = Chapter 13 
# 304 = Section 304 (these cases had earlier been coded as 8)
# 9 = Chapter 12
# Blank = Missing 

pre_bapcpa_chp <- function(x) {
  case_when(x == "1" ~ "7",
            x == "4" ~ "9",
            x == "5" ~ "11",
            x == "7" ~ "13",
            x == "9" ~ "12",
            x %in% c("15m","15n","15x") ~ "15",
            T ~ x)
}

chp <- function(x) {
  case_when(x %in% c("15m","15n","15x") ~ "15",
            T ~ x)
}

# Result D1FDSP
# A = Standard Discharge
# B = Hardship Discharge
# D = Discharge Not Applicable
# E = Discharge Denied
# F = Discharge Waived
# G = Discharge Revoked
# H = Dismissed for Failure to Pay Filing Fee
# I = Dismissed for Failure to File Information
# J = Dismissed for Abuse
# K = Dismissed for Other Reason
# L = Inter-District Transfer
# M = Intra-District Transfer
# N = Discharge Withheld for Failure to Submit Certification
# of Financial Management Course and Pay Domestic
# Support Obligation
# 0 = Discharge Withheld for Failure to Submit Certification
# of Financial Management Course
# P = Discharge Withheld for Failure to Comply with Domestic
# Support Obligation
# R = Homestead Exemption/Felony Conviction
# S = Discharge Withheld for Other Reasons
# T = Dismissed for Failure to Make Plan Payments (beginning
#                                              with CM/ECF 3.3.1, 12/22/2008)
# U = Dismissed for Failure to Pay Filing Fee and to File
# Information (beginning with CM/ECF 3.3.1, 12/22/2008)
# X = Filed in Error (beginning with CM/ECF 3.3.1,
#                     12/22/2008)
# Y = Split or Deconsolidated (beginning with CM/ECF 3.3.2,
#                              05/27/2009)
# Z = Closed in Error (beginning with CM/ECF 3.3.1,
#                      12/22/2008) 

# Values for cases filed April 1991 through approximately October 17, 2006
# 1 = Discharge Granted
# 2 = Discharge Denied
# 3 = Discharge Waived/Revoked
# 4 = Discharge Not Applicable
# 5 = Petition Dismissed
# 6 = Transferred to Another District 
# 7 = Intra-District Transfer
# 8 = Other Court Purpose
# 0 = No Category Checked
# Blank = Missing / Case Still Pending

fdsp <- function(x, y) {
  case_when(x %in% c("A","B","D","4") ~ "discharge",
            x %in% c("H","I","J","K","T","U") ~ "dismiss",
            x %in% c("L","M") ~ "transfer",
            x %in% c("N","O","P","S") ~ "withheld",
            x %in% c("E","F","G","R","X","Y","Z")~"other",
            is.na(y) ~ "open",
            T ~ "")
}

pre_bapcpa_fdsp <- function(x, y) {
  case_when(x %in% c("1","4") ~ "discharge",
            x %in% c("5") ~ "dismiss",
            x %in% c("6","7") ~ "transfer",
            x %in% c("2","3","8","0") ~ "other",
            is.na(y) ~ "open",
            T ~ "")
}

bus <- j5 %>% 
  map(function(x) filter(x, NTRDBT == "b")) %>% 
  bind_rows() %>% 
  # CASEKEY changed in 2019 to not include the BK component
  mutate(CASEKEY = str_remove(CASEKEY, "BK"),
         org_chap  = if_else(FILEDATE < "2005-10-16",
                             pre_bapcpa_chp(ORGFLCHP),
                             chp(ORGFLCHP)),
         crnt_chap = if_else(FILEDATE < "2005-10-16",
                             pre_bapcpa_chp(CRNTCHP),
                             chp(CRNTCHP)),
         cl_chap   = if_else(FILEDATE < "2005-10-16",
                             pre_bapcpa_chp(CLCHPT),
                             chp(CLCHPT)),
         result  = fdsp(D1FDSP, CLOSEDT),
         result2 = fdsp(D2FDSP, CLOSEDT))

# Not necessary after they renamed the variables to be all uppercase
# bus <- bus %>% 
#   mutate(DISTRICT = if_else(is.na(DISTRICT), District, DISTRICT)) %>% 
#   select(-District)

bus <- left_join(bus, districts)

write_csv(bus, paste0(local_dir, "/raw_business_new.csv"))
write_rds(bus, paste0(local_dir, "/raw_business_new.rds"))

banks <- j5 %>% 
  map(function(x) {
    x %>% 
      # CASEKEY changed in 2019 to not include the BK component
      mutate(CASEKEY = str_remove(CASEKEY, "BK"),
             org_chap  = if_else(FILEDATE < "2005-10-16",
                                 pre_bapcpa_chp(ORGFLCHP),
                                 chp(ORGFLCHP)),
             crnt_chap = if_else(FILEDATE < "2005-10-16",
                                 pre_bapcpa_chp(CRNTCHP),
                                 chp(CRNTCHP)),
             cl_chap   = if_else(FILEDATE < "2005-10-16",
                                 pre_bapcpa_chp(CLCHPT),
                                 chp(CLCHPT))) %>% 
      filter(org_chap == "12" | crnt_chap == "12" | cl_chap == "12")
  }) %>% 
  bind_rows() %>% 
  # mutate(DISTRICT = if_else(is.na(DISTRICT), District, DISTRICT)) %>% 
  # select(-District) %>% 
  mutate(result  = fdsp(D1FDSP, CLOSEDT),
         result2 = fdsp(D2FDSP, CLOSEDT))

# banks <- banks %>% 
#   mutate(DISTRICT = if_else(is.na(DISTRICT), District, DISTRICT)) %>% 
#   select(-District)

banks <- left_join(banks, districts)

write_csv(banks, paste0(local_dir, "/raw_ch12s_new.csv"))
write_rds(banks, paste0(local_dir, "/raw_ch12s_new.rds"))

banks <- filter(banks, SNAPFILE == 1, org_chap == "12")

write_csv(banks, paste0(local_dir, "/ch12s_post08_new.csv"))
write_rds(banks, paste0(local_dir, "/ch12s_post08_new.rds"))
