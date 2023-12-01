# Monthly Bankruptcy Filings: F-2 Tables

library(lubridate)
library(readxl)
library(stringr)
library(tidyverse)
library(zoo)

# F-2 Tables, start quarterly on 31 March 2001 then continue indefinitely. The
#  files start of as .xls files, although there are two random years which are
#  pdfs, but it seems like they have shifted to the .xlsx format now.

# Create a directory for the data
local_dir    <- "0-data/uscourts/f2_one"
data_source  <- paste0(local_dir, "/raw")
if (!file.exists(local_dir)) dir.create(local_dir, recursive = T)
if (!file.exists(data_source)) dir.create(data_source)

f2_files <- dir(data_source, full.names = T, pattern = ".xls")

# ---- excel-files --------------------------------------------------------

# HACK: f2_one tables beginning on 2018-09-30 have 6 sheets instead of 3 due
#  to how they now lump chapters 9, 12, and 15

xls_f2 <- map(f2_files, function(x){
  f2_date <- str_replace_all(str_sub(basename(x), 8, 17), "_", "/")
  print(f2_date)
  f2_sheets <- excel_sheets(x)
  
  if (length(f2_sheets) > 3) { # Address changes in chapter reports
    #################################
    temp    <- map(f2_sheets, function(y) {
      temp1 <- read_excel(x, col_names = F, sheet = y)
      
      temp1 <- temp1[, colSums(is.na(temp1)) < nrow(temp1)]
      
      
      if (grepl("12", y)) {
        names(temp1) <- c("DISTRICT_NS", "TOTAL_FILINGS", "CHAP_9",
                          "CHAP_12", "CHAP_15", "OTHERS")
        
      } else if (!grepl("12", y)) {
        # Sometimes read_excel doesn't read all the columns, so need to adjust
        if (ncol(temp1) != 15) {
          if (tools::file_ext(x) != "xlsx") {
            # temp1 <- gdata::read.xls(x)
            temp1 <- temp1[, 1:15]
          } else {
            temp1 <- temp1[, 1:15]
          }
        }
        
        if (f2_date > "2018/09/29") {
          names(temp1) <- c("DISTRICT_NS", "TOTAL_FILINGS", "CHAP_7",
                            "CHAP_11", "CHAP_13", "TOTAL_OTHER",
                            "TOTAL_BUSINESS_FILINGS", "BCHAP_7", "BCHAP_11",
                            "BCHAP_13", "TOTAL_BCHAP_OTHER",
                            "TOTAL_NON_BUSINESS_FILINGS", "NBCHAP_7",
                            "NBCHAP_11", "NBCHAP_13")
        } else if (f2_date < "2018/09/29") {
          names(temp1) <- c("DISTRICT_NS", "TOTAL_FILINGS", "CHAP_7",
                            "CHAP_11", "CHAP_12", "CHAP_13",
                            "TOTAL_BUSINESS_FILINGS", "BCHAP_7", "BCHAP_11",
                            "BCHAP_12", "BCHAP_13",
                            "TOTAL_NON_BUSINESS_FILINGS", "NBCHAP_7",
                            "NBCHAP_11", "NBCHAP_13")
        }
      }
      
      # Format to upper case, remove punctuation and white spaces
      temp1$DISTRICT_NS <- gsub("[[:punct:]]", "", temp1$DISTRICT_NS)
      temp1$DISTRICT_NS <- toupper(gsub(" ", "", temp1$DISTRICT_NS))
      
      begin   <- grep("TOTAL", temp1$DISTRICT_NS)
      # in case of another "TOTAL" instance
      if (length(begin) > 1) begin <- begin[1]
      
      done    <- grep("GAS", temp1$DISTRICT_NS)
      # in case of another "TOTAL" instance
      if (length(done) > 1) done <- done[1]
      
      results <- as.data.frame(temp1[begin:done,])
      results <- filter(results, !is.na(DISTRICT_NS))
      
      results$DATE <- str_sub(basename(x), 8, 17)
      results$DATE <- str_replace_all(results$DATE, "_", "/")
      
      results$month <- as.numeric(str_sub(basename(x), 13, 14)) -
        3 + ceiling(match(y, f2_sheets)/2)
      
      results$DATE <- as.Date(as.yearmon(paste0(str_sub(results$DATE, 1, 5),
                                                results$month), "%Y/%m"),
                              frac = 1)
      
      return(results)
    })
  } else if (length(f2_sheets) == 3) {
    temp    <- map(1:3, function(y) {
      temp1 <- read_excel(x, col_names = F, sheet = y)
      
      temp1 <- temp1[, colSums(is.na(temp1)) < nrow(temp1)]
      
      # Sometimes read_excel doesn't read all the columns, so need to adjust
      if (ncol(temp1) != 15) {
        if (tools::file_ext(x) != "xlsx") {
          # temp1 <- gdata::read.xls(x)
          temp1 <- temp1[, 1:15]
        } else {
          temp1 <- temp1[, 1:15]
        }
      }
      names(temp1) <- c("DISTRICT_NS", "TOTAL_FILINGS", "CHAP_7", "CHAP_11",
                        "CHAP_12", "CHAP_13", "TOTAL_BUSINESS_FILINGS",
                        "BCHAP_7", "BCHAP_11", "BCHAP_12", "BCHAP_13",
                        "TOTAL_NON_BUSINESS_FILINGS", "NBCHAP_7", "NBCHAP_11",
                        "NBCHAP_13")
      
      
      # Format to upper case, remove punctuation and white spaces
      temp1$DISTRICT_NS <- gsub("[[:punct:]]", "", temp1$DISTRICT_NS)
      temp1$DISTRICT_NS <- gsub(" ", "", temp1$DISTRICT_NS)
      
      begin   <- grep("TOTAL", temp1$DISTRICT_NS)
      # in case of another "TOTAL" instance
      if (length(begin) > 1) begin <- begin[1]
      
      done    <- grep("GAS", temp1$DISTRICT_NS)
      # in case of another "TOTAL" instance
      if (length(done) > 1) done <- done[1]
      
      results <- as.data.frame(temp1[begin:done,])
      results <- filter(results, !is.na(DISTRICT_NS))
      
      results$DATE <- str_sub(basename(x), 8, 17)
      results$DATE <- str_replace_all(results$DATE, "_", "/")
      
      results$month <- as.numeric(str_sub(basename(x), 13, 14)) - 3 + y
      
      results$DATE <- as.Date(as.yearmon(paste0(str_sub(results$DATE, 1, 5),
                                                results$month), "%Y/%m"),
                              frac = 1)
      
      return(results)
    })
  }
  
  results <- bind_rows(temp)
  
  # Hack for 2018-09-30 and beyond
  results <- results %>% 
    group_by(DISTRICT_NS, DATE, month) %>% 
    summarise_all(list(~first(na.omit(.))))
  
  return(results)
})

# xls_f2

# ---- pacer --------------------------------------------------------------

f2_files <- dir(paste0(data_source, "/pacer"), full.names = T,
                pattern = ".xls")

pacer_f2 <- map(f2_files, function(x){
  # Error currently: Error in read_fun(path = path, sheet_i = sheet, limits =
  # limits, shim = shim,  : basic_string::_M_construct null not valid
  temp <- read_excel(x, col_names = F)
  # Alternative
  # temp <- gdata::read.xls(x)
  
  temp <- temp[, colSums(is.na(temp)) < nrow(temp)]
  
  # Sometimes read_excel doesn't read all the columns, so need to adjust
  if (ncol(temp) != 15) {
    if (tools::file_ext(x) != "xlsx") {
      # temp <- gdata::read.xls(x)
      temp <- temp[, 1:15]
    } else {
      temp <- temp[, 1:15]
    }
  }
  names(temp) <- c("DISTRICT_NS", "TOTAL_FILINGS", "CHAP_7", "CHAP_11",
                   "CHAP_12", "CHAP_13", "TOTAL_BUSINESS_FILINGS",
                   "BCHAP_7", "BCHAP_11", "BCHAP_12", "BCHAP_13",
                   "TOTAL_NON_BUSINESS_FILINGS", "NBCHAP_7", "NBCHAP_11",
                   "NBCHAP_13")
  
  
  # Format to upper case, remove punctuation and white spaces
  temp$DISTRICT_NS <- gsub("[[:punct:]]", "", temp$DISTRICT_NS)
  temp$DISTRICT_NS <- gsub(" ", "", temp$DISTRICT_NS)
  
  begin   <- grep("TOTAL", temp$DISTRICT_NS)
  # in case of another "TOTAL" instance
  if (length(begin) > 1) begin <- begin[1]
  
  done    <- grep("GAS", temp$DISTRICT_NS)
  # in case of another "TOTAL" instance
  if (length(done) > 1) done <- done[1]
  
  results <- as.data.frame(temp[begin:done,])
  results <- filter(results, !is.na(DISTRICT_NS))
  
  results$DATE <- str_sub(basename(x), 4, 13)
  results$DATE <- as.Date(str_replace_all(results$DATE, "-", "/"), "%Y/%m/%d")
  
  results$month <- month(results$DATE)
  
  return(results)
})

# ---- clean-up -----------------------------------------------------------

f2_one <- bind_rows(pacer_f2, xls_f2)

# Next, need to remove the Circuits and Total. Then turn values to numeric.
#  There's a problem with commas when coerced to numeric, remove commas
circuits <- c("10TH", "11TH", "1ST", "2ND", "3RD", "4TH",
              "5TH", "6TH", "7TH", "8TH", "9TH", "TOTAL")
f2_one <- f2_one %>% 
  filter(!(DISTRICT_NS %in% circuits)) %>% 
  mutate_at(vars(-DISTRICT_NS, -DATE, -month),
            list(~str_replace(., "-", "0"))) %>% 
  mutate_at(vars(-DISTRICT_NS, -DATE, -month),
            parse_number)

# 2018-09-30 combines Arkansas Eastern and Western into one, not sure why
arkansas_hack <- data.frame(STATE = "ARKANSAS", DISTRICT = "ARKANSAS",
                            DISTRICT_NS = "AR", CIRCUIT = "EIGHTH CIRCUIT",
                            CIRCUIT_NUM = "8TH")
# Guam hack
guam_hack <- data.frame(STATE = "GUAM", DISTRICT = "GUAM",
                        DISTRICT_NS = "GU", CIRCUIT = "NINTH CIRCUIT",
                        CIRCUIT_NUM = "9TH")

f2_one <- read_csv("0-data/uscourts/district_ns.csv") |> 
  bind_rows(arkansas_hack, guam_hack) |> 
  right_join(f2_one) |> 
  mutate(QTR_ENDED = quarter(DATE, with_year = T),
         YEAR = year(DATE),
         FISCAL_YEAR = year(floor_date(DATE + 1, unit = "year")),
         ST_ABRV = state.abb[match(STATE,toupper(state.name))],
         ST_ABRV = ifelse(STATE == "DISTRICT OF COLUMBIA", "DC", ST_ABRV)) |> 
  arrange(DATE)

write_csv(f2_one, paste0(local_dir, "/f2_one.csv"))
write_rds(f2_one, paste0(local_dir, "/f2_one.rds"))
