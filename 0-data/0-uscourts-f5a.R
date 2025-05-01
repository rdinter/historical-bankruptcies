# Annual Bankruptcy Filings at County Level: F-5a Tables
#  ! need to add in quarterly level values based upon subtracting values...

# ---- start --------------------------------------------------------------


library(lubridate)
library(readxl)
library(stringr)
library(tidyverse)
library(zoo)

# F-5a Tables start the quarter ending on 31 March 2013 then continue
#  indefinitely. The files start of as .xls files, but it seems like they
#  have shifted to the .xlsx format as of 31 September 2016.

# Create a directory for the data
local_dir    <- "0-data/uscourts/f5a"
data_source <- paste0(local_dir, "/raw")
if (!file.exists(local_dir)) dir.create(local_dir, recursive = T)
if (!file.exists(data_source)) dir.create(data_source)

# ---- read ---------------------------------------------------------------


# There's a problem with the .xlsx files. I had to manually save them as
#  .xls files for them to be readable. Will need to update this later.
f5a_files <- dir(data_source, full.names = T, pattern = ".xls", recursive = T)
f5a_files <- f5a_files[!grepl("1998", f5a_files)]
# f5a_files <- f5a_files[tools::file_ext(f5a_files) != "xlsx"]


# Need to have previously ran the IDB files 0-fjc-data.R and 0-fjc-f5a.R
f5a_qtrly <- read_csv("0-data/fjc/IDB/f5a_quarterly.csv") |> 
  # read_rds("0-data/fjc/IDB/f5a_quarterly.rds") |> 
  # ungroup() |> 
  rename_all(function(x) paste0(x, "_qtr")) |> 
  rename(DATE = QTR_ENDED_qtr, FIPS = D1CNTY_qtr,
         DISTRICT_NS = DISTRICT_NS_qtr) |> 
  group_by(DISTRICT_NS) |> 
  complete(FIPS, DATE) |> 
  mutate_if(is.numeric, ~ifelse(is.na(.), 0, .)) |> 
  # replace(is.na(.), 0) #|> 
  mutate(DATE = as.Date(DATE),
        FIPS = parse_number(FIPS))

f5a_year <- f5a_qtrly |> 
  group_by(DISTRICT_NS, FIPS) |> 
  mutate_at(vars(-DATE, -DISTRICT_NS, -FIPS),
            function(x) rollapplyr(x, 4, sum, fill = NA))

f5a_year1 <- read_csv("0-data/uscourts/district_ns.csv") |> 
  right_join(f5a_year) |> 
  mutate(DATE = as.Date(DATE, "%Y/%m/%d"),
         QTR_ENDED = format(DATE, "%m/%d/%y"),
         YEAR = year(DATE),
         FISCAL_YEAR = year(floor_date(DATE + 1, unit = "year")),
         ST_ABRV = state.abb[match(STATE,toupper(state.name))],
         ST_ABRV = ifelse(STATE == "DISTRICT OF COLUMBIA", "DC", ST_ABRV)) |> 
  arrange(DATE) |> 
  filter(!is.na(TOTAL_FILINGS_qtr), TOTAL_FILINGS_qtr != 0)

# Remove _qtr from names
names(f5a_year1) <- str_remove_all(names(f5a_year1), "_qtr")


# ---- text-files ---------------------------------------------------------

txt_pos <- fwf_widths(c(18, 5, 9, 10, 8, 4, 8, 9, 8, 7, 6, 7, 10, 10, 4, 8),
                      col_names = c("COUNTY", "FIPS", "TOTAL_FILINGS",
                                    "CHAP_7", "CHAP_11", "CHAP_12", "CHAP_13",
                                    "TOTAL_BUSINESS_FILINGS", "BCHAP_7",
                                    "BCHAP_11", "BCHAP_12", "BCHAP_13",
                                    "TOTAL_NON_BUSINESS_FILINGS", "NBCHAP_7",
                                    "NBCHAP_11", "NBCHAP_13"))

f5a_txt_files <- dir(data_source, pattern = ".txt",
                     full.names = T, recursive = T)

txt_f5a <- map(f5a_txt_files, function(x) {
  temp    <- read_fwf(x, col_positions = txt_pos,
                      col_types = cols(.default = "c"))
  
  # Sometimes read_excel doesn't read all the columns, so need to adjust
  if (ncol(temp) != 16) temp <- gdata::read.xls(x)
  
  temp <- temp[, colSums(is.na(temp)) < nrow(temp)]
  temp <- temp[rowSums(is.na(temp)) != ncol(temp), ]
  
  # Format to upper case, remove punctuation and white spaces
  temp$COUNTY <- gsub("[[:punct:]]", "", temp$COUNTY)
  temp$COUNTY <- gsub(" ", "", temp$COUNTY)
  
  begin   <- grep("TOTAL", toupper(temp$COUNTY))
  # in case of another "TOTAL" instance
  if (length(begin) > 1) begin <- begin[1]
  
  done    <- nrow(temp)
  
  results <- as.data.frame(temp[begin:done,])
  results[results == " "] <- ""
  results[results == ""] <- NA
  results$DISTRICT_NS <- ifelse(is.na(results$FIPS), results$COUNTY, NA)
  results <- fill(results, DISTRICT_NS)
  
  done   <- grep("GAS", toupper(results$DISTRICT_NS))
  results <- results[seq(1, max(done)),]
  
  results <- results |> 
    filter(!is.na(FIPS)) |> 
    mutate_at(vars(TOTAL_FILINGS:NBCHAP_13),
              list(~as.integer(gsub(",", "", .))))
  results[is.na(results)] <- 0
  
  results$DATE <- str_sub(basename(x), 5, 14)
  results$DATE <- str_replace_all(results$DATE, "_", "/")
  
  results$FIPS <- parse_number(str_remove(results$FIPS, "\\*"))
  
  return(results)
})

f5a_txt <- bind_rows(txt_f5a)

# ---- excel-files --------------------------------------------------------

xls_f5a <- map(f5a_files, function(x) {
  temp    <- tryCatch(read_excel(x, col_names = F),
                      error = function(e) xlsx::read.xls(x, 1))
  
  # Sometimes read_excel doesn't read all the columns, so need to adjust
  if (ncol(temp) != 16) temp <- xlsx::read.xls(x, 1)
  
  temp <- temp[, colSums(is.na(temp)) < nrow(temp)]
  
  names(temp) <- c("COUNTY", "FIPS", "TOTAL_FILINGS", "CHAP_7", "CHAP_11",
                   "CHAP_12", "CHAP_13", "TOTAL_BUSINESS_FILINGS",
                   "BCHAP_7", "BCHAP_11", "BCHAP_12", "BCHAP_13",
                   "TOTAL_NON_BUSINESS_FILINGS", "NBCHAP_7", "NBCHAP_11",
                   "NBCHAP_13")
  
  # Format to upper case, remove punctuation and white spaces
  temp$COUNTY <- gsub("[[:punct:]]", "", temp$COUNTY)
  temp$COUNTY <- gsub(" ", "", temp$COUNTY)
  temp$COUNTY <- toupper(temp$COUNTY)
  
  begin   <- grep("TOTAL", toupper(temp$COUNTY))
  # in case of another "TOTAL" instance
  if (length(begin) > 1) begin <- begin[1]
  
  done    <- nrow(temp)
  
  results <- as.data.frame(temp[begin:done,])
  results[results == " "] <- ""
  results[results == ""] <- NA
  results$DISTRICT_NS <- ifelse(is.na(results$FIPS), results$COUNTY, NA)
  results <- fill(results, DISTRICT_NS)
  
  
  done   <- grep("GAS", toupper(results$DISTRICT_NS))
  results <- results[seq(1, max(done)),]
  
  results <- results |> 
    filter(!is.na(FIPS)) |> 
    mutate_at(vars(TOTAL_FILINGS:NBCHAP_13),
              list(~as.integer(gsub(",", "", .))))
  results[is.na(results)] <- 0
  
  file_date <- basename(x) |> 
    str_sub(5, 14) |> 
    str_replace_all("_", "/")
  results$DATE <- file_date
  
  # HACK for update to how the US Courts reports f2 tables with OTHER chapters
  if (file_date > "2018/09/29") {
    new_names <- c("COUNTY", "FIPS", "TOTAL_FILINGS", "CHAP_7", "CHAP_11",
                   "CHAP_13", "TOTAL_OTHER", "TOTAL_BUSINESS_FILINGS",
                   "BCHAP_7", "BCHAP_11", "BCHAP_13", "TOTAL_BCHAP_OTHER",
                   "TOTAL_NON_BUSINESS_FILINGS", "NBCHAP_7", "NBCHAP_11",
                   "NBCHAP_13", "DISTRICT_NS", "DATE")
    names(results) <- new_names
    
    temp2 <- read_excel(x, sheet = 2)
    names(temp2) <- c("COUNTY", "FIPS", "TOTAL_FILINGS", "CHAP_9",
                      "CHAP_12", "CHAP_15", "OTHERS")
    
    # Format to upper case, remove punctuation and white spaces
    temp2$COUNTY <- gsub("[[:punct:]]", "", temp2$COUNTY)
    temp2$COUNTY <- gsub(" ", "", temp2$COUNTY)
    temp2$COUNTY <- toupper(temp2$COUNTY)
    
    begin   <- grep("TOTAL", toupper(temp2$COUNTY))
    # in case of another "TOTAL" instance
    if (length(begin) > 1) begin <- begin[1]
    
    done    <- nrow(temp2)
    
    results2 <- as.data.frame(temp2[begin:done,])
    results2[results2 == " "] <- ""
    results2[results2 == ""] <- NA
    results2$DISTRICT_NS <- ifelse(is.na(results2$FIPS), results2$COUNTY, NA)
    results2 <- fill(results2, DISTRICT_NS)
    
    results2 <- results2 |> 
      filter(!is.na(FIPS)) |> 
      mutate_at(vars(TOTAL_FILINGS:OTHERS),
                list(~as.integer(gsub(",", "", .))))
    results2[is.na(results2)] <- 0
    
    done   <- grep("GAS", toupper(results2$DISTRICT_NS))
    results2 <- results2[seq(1, max(done)),]
    
    results <- results2 |> 
      select(COUNTY, FIPS, DISTRICT_NS, CHAP_9, CHAP_12, CHAP_15) |> 
      right_join(results)
  }
  
  results <- results |> 
    mutate(FIPS = parse_number(str_remove(FIPS, "\\*")))
  
  return(results)
})

f5a <- bind_rows(xls_f5a) |> 
  bind_rows(f5a_txt)

# 2018-09-30 combines Arkansas Eastern and Western into one, not sure why
arkansas_hack <- data.frame(STATE = "ARKANSAS", DISTRICT = "ARKANSAS",
                            DISTRICT_NS = "AR", CIRCUIT = "EIGHTH CIRCUIT",
                            CIRCUIT_NUM = "8TH")
# Guam hack
guam_hack <- data.frame(STATE = "GUAM", DISTRICT = "GUAM",
                        DISTRICT_NS = "GU", CIRCUIT = "NINTH CIRCUIT",
                        CIRCUIT_NUM = "9TH")

f5a <- read_csv("0-data/uscourts/district_ns.csv") |> 
  bind_rows(arkansas_hack, guam_hack) |> 
  right_join(f5a) |> 
  mutate(DATE = as.Date(DATE, "%Y/%m/%d"),
         QTR_ENDED = format(DATE, "%m/%d/%y"),
         YEAR = year(DATE),
         FISCAL_YEAR = year(floor_date(DATE + 1, unit = "year")),
         ST_ABRV = state.abb[match(STATE,toupper(state.name))],
         ST_ABRV = ifelse(STATE == "DISTRICT OF COLUMBIA", "DC", ST_ABRV)) |> 
  arrange(DATE)

miss_date <- unique(f5a$DATE)

# Now bind_rows with the f5a_year
f5a <- f5a_year1 |> 
  filter(!(DATE %in% miss_date)) |> 
  bind_rows(f5a) |> 
  arrange(DATE, DISTRICT_NS, FIPS)

write_csv(f5a, paste0(local_dir, "/f5a.csv"))
write_rds(f5a, paste0(local_dir, "/f5a.rds"))


# ---- 3-month ------------------------------------------------------------


# The original f5a data are for the 12-month period, but we want this as a
#  quarterly measure since those are the intervals of observation.

# f5a_qtr <- f5a |> 
#   select(DISTRICT_NS, CIRCUIT_NUM, FIPS, DATE, TOTAL_FILINGS:NBCHAP_13,
#          CHAP_9:TOTAL_BCHAP_OTHER) |> 
#   group_by(DISTRICT_NS, CIRCUIT_NUM) |> 
#   complete(FIPS, DATE) |> 
#   replace(is.na(.), 0)
# 
# f5a_both <- f5a_qtr |> 
#   full_join(f5a_qtrly) |> 
#   arrange(DATE, DISTRICT_NS, FIPS)
# 
# fart <- f5a_both |> 
#   group_by(DISTRICT_NS, FIPS) |> 
#   mutate(fart = TOTAL_FILINGS - lag(TOTAL_FILINGS_qtr) -
#            lag(TOTAL_FILINGS_qtr, 2) - lag(TOTAL_FILINGS_qtr, 3))
# 
# 
# write_csv(f5a_qtr, paste0(local_dir, "/f5a_quarterly.csv"))
# write_rds(f5a_qtr, paste0(local_dir, "/f5a_quarterly.rds"))
