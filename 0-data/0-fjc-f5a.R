# Downloading files from uscourts.gov on bankruptcy
# https://www.fjc.gov/research/idb
#  bankruptcy-cases-filed-terminated-and-pending-fy-2008-present

# ---- start --------------------------------------------------------------

library("haven")
library("lubridate")
library("rvest")
library("stringr")
library("tidyverse")
sumn <- function(x) sum(x, na.rm = T)

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


# Create a directory for the data
local_dir    <- "0-data/fjc/IDB"
data_source <- paste0(local_dir, "/raw")
if (!file.exists(local_dir)) dir.create(local_dir, recursive = T)
if (!file.exists(data_source)) dir.create(data_source)

# years <- str_pad(8:parse_number(format(Sys.Date(), "%y")),
#                  2, "left", "0")
# links <- paste0("https://www.fjc.gov/sites/default/files/idb/datasets/cpbank",
#                 years, ".zip")
# 
# link_files <- paste0(data_source, "/", basename(links))
# 
# map2(link_files, links, function(x, y){
#   if (!file.exists(x)) {
#     temp   <- GET(y)
#     
#     # In case the file doesn't exist:
#     if (temp$status_code > 400) return()
#     download.file(y, x)
#   }
# })

districts <- read_csv("0-data/fjc/district_cross.csv") %>% 
  rename_all(toupper)

raw_files <- dir(data_source, full.names = T)


# ---- read ---------------------------------------------------------------

# j5 <- read_sas(raw_files[10])

all_chap <- c("7", "11", "12", "13")

summaries <- map(raw_files, function(x) {
  j5 <- read_sas(x) %>% 
    rename_all(toupper) %>% 
    mutate(org_chap  = if_else(FILEDATE < "2005-10-16",
                               pre_bapcpa_chp(ORGFLCHP),
                               chp(ORGFLCHP)),
           crnt_chap = if_else(FILEDATE < "2005-10-16",
                               pre_bapcpa_chp(CRNTCHP),
                               chp(CRNTCHP)),
           cl_chap   = if_else(FILEDATE < "2005-10-16",
                               pre_bapcpa_chp(CLCHPT),
                               chp(CLCHPT)),
           result  = fdsp(D1FDSP, CLOSEDT),
           result2 = fdsp(D2FDSP, CLOSEDT),
           snap = as.Date(paste0(year(SNAPSHOT) - 1, "-09-30")))
  
  bus <- j5 %>% 
    filter(FILEDATE > snap) %>% 
    left_join(districts)
  
  bus <- bus %>% 
    ungroup() %>% 
    mutate(file_qtr = lubridate::quarter(FILEDATE, with_year = T),
           qtr = str_sub(file_qtr, -2),
           yr  = str_sub(file_qtr, 1, 4),
           QTR_ENDED = case_when(qtr == ".1" ~ paste0(yr, "-03-31"),
                                 qtr == ".2" ~ paste0(yr, "-06-30"),
                                 qtr == ".3" ~ paste0(yr, "-09-30"),
                                 qtr == ".4" ~ paste0(yr, "-12-31"))) %>% 
    group_by(QTR_ENDED, DISTRICT_NS, D1CNTY) %>% 
    summarise(TOTAL_FILINGS = sumn(org_chap %in% all_chap),
              CHAP_7 = sumn(org_chap == "7"),
              CHAP_11 = sumn(org_chap == "11"),
              CHAP_12 = sumn(org_chap == "12"),
              CHAP_13 = sumn(org_chap == "13"),
              TOTAL_BUSINESS_FILINGS = sumn(org_chap %in% all_chap &
                                              NTRDBT == "b"),
              BCHAP_7 = sumn(org_chap == "7" & NTRDBT == "b"),
              BCHAP_11 = sumn(org_chap == "11" & NTRDBT == "b"),
              BCHAP_12 = sumn(org_chap == "12" & NTRDBT == "b"),
              BCHAP_13 = sumn(org_chap == "13" & NTRDBT == "b"),
              TOTAL_NON_BUSINESS_FILINGS = sumn(org_chap %in% all_chap &
                                                  NTRDBT == "c"),
              NBCHAP_7 = sumn(org_chap == "7" & NTRDBT == "c"),
              NBCHAP_11 = sumn(org_chap == "11" & NTRDBT == "c"),
              NBCHAP_12 = sumn(org_chap == "12" & NTRDBT == "c"),
              NBCHAP_13 = sumn(org_chap == "13" & NTRDBT == "c"))
  
  return(bus)
})

f5a_qtr <- bind_rows(summaries)


write_csv(f5a_qtr, paste0(local_dir, "/f5a_quarterly.csv"))
write_rds(f5a_qtr, paste0(local_dir, "/f5a_quarterly.rds"))
