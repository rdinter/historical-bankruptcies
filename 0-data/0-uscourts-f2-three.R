# Quarterly Bankruptcy Filings: F-2 Tables

# ---- start --------------------------------------------------------------

library("gdata")
library("readxl")
library("stringi")
library("stringr")
library("tidyverse")

# F-2 Tables, start quarterly on 31 March 2001 then continue indefinitely. The
#  files start of as .xls files, although there are two random years which are
#  pdfs, but it seems like they have shifted to the .xlsx format now.

# Create a directory for the data
local_dir    <- "0-data/uscourts/f2_three"
data_source <- paste0(local_dir, "/raw")
if (!file.exists(local_dir)) dir.create(local_dir, recursive = T)
if (!file.exists(data_source)) dir.create(data_source)

f2_files <- dir(data_source, full.names = T, pattern = ".xls")

# ---- excel-files --------------------------------------------------------

xls_f2 <- map(f2_files, function(x){
  print(x)
  temp    <- tryCatch(read_excel(x, col_names = F),
                      error = function(e) gdata::read.xls(x))
  
  # remove columns full of NA
  temp <- temp[, colSums(is.na(temp)) < nrow(temp)]
  
  # Sometimes read_excel doesn't read all the columns, so need to adjust
  if (ncol(temp) != 15) {
    if (tools::file_ext(x) != "xlsx") {
      temp <- read.xls(x)
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
  temp$DISTRICT_NS <- toupper(temp$DISTRICT_NS)
  
  begin   <- grep("TOTAL", temp$DISTRICT_NS)
  # in case of another "TOTAL" instance
  if (length(begin) > 1) begin <- begin[1]
  
  done    <- grep("GAS", temp$DISTRICT_NS)
  # in case of another "TOTAL" instance
  if (length(done) > 1) done <- done[1]
  
  results <- as.data.frame(temp[begin:done,])
  results <- filter(results, !is.na(DISTRICT_NS))
  
  file_date <- basename(x) %>% 
    str_sub(10, 19) %>% 
    str_replace_all("_", "/")
  results$DATE <- file_date
  
  # HACK for update to how the US Courts reports f2 tables with OTHER chapters
  if (file_date > "2018/09/29") {
    new_names <- c("DISTRICT_NS", "TOTAL_FILINGS", "CHAP_7", "CHAP_11",
                   "CHAP_13", "TOTAL_OTHER", "TOTAL_BUSINESS_FILINGS",
                   "BCHAP_7", "BCHAP_11", "BCHAP_13", "TOTAL_BCHAP_OTHER",
                   "TOTAL_NON_BUSINESS_FILINGS", "NBCHAP_7", "NBCHAP_11",
                   "NBCHAP_13", "DATE")
    names(results) <- new_names
    
    temp2 <- read_excel(x, sheet = 2)
    names(temp2) <- c("DISTRICT_NS", "TOTAL_FILINGS", "CHAP_9",
                      "CHAP_12", "CHAP_15", "OTHERS")
    
    # Format to upper case, remove punctuation and white spaces
    temp2$DISTRICT_NS <- gsub("[[:punct:]]", "", temp2$DISTRICT_NS)
    temp2$DISTRICT_NS <- gsub(" ", "", temp2$DISTRICT_NS)
    temp2$DISTRICT_NS <- toupper(temp2$DISTRICT_NS)
    
    begin   <- grep("TOTAL", temp2$DISTRICT_NS)
    # in case of another "TOTAL" instance
    if (length(begin) > 1) begin <- begin[1]
    
    done    <- grep("GAS", temp2$DISTRICT_NS)
    # in case of another "TOTAL" instance
    if (length(done) > 1) done <- done[1]
    
    results2 <- as.data.frame(temp2[begin:done,])
    results2 <- filter(results2, !is.na(DISTRICT_NS))
    
    results <- results2 %>% 
      select(DISTRICT_NS, CHAP_9, CHAP_12, CHAP_15) %>% 
      right_join(results)
  }
  
  return(results)
})

# ---- pdf-files ----------------------------------------------------------

# Need to read in the two missing xls files (2004-12-31 and 2005-03-31),
#  which are only PDFs
# devtools::install_github("ropensci/tabulizer")
library("tabulizer")
# sudo R CMD javareconf <- for eventual ubuntu error

f2_pdf <- dir(data_source, full.names = T, pattern = ".pdf")
f2_pdf <- f2_pdf[grepl("2004_12_31|2005_03_31", f2_pdf)]

# Read in those dang pdf files
pdf_f2 <- map(f2_pdf, function(x){
  temp <- extract_tables(x)
  
  temp_df <- map(temp, function(y){
    j5 <- apply(y, 1, function(z) c(z[!(z == "")], z[(z == "")]))
    
    j5 <- as.data.frame(t(j5))
    j5 <- j5[, 1:15]
  })
  
  temp <- bind_rows(temp_df)
  
  names(temp) <- c("DISTRICT_NS", "TOTAL_FILINGS", "CHAP_7", "CHAP_11",
                   "CHAP_12", "CHAP_13", "TOTAL_BUSINESS_FILINGS",
                   "BCHAP_7", "BCHAP_11", "BCHAP_12", "BCHAP_13",
                   "TOTAL_NON_BUSINESS_FILINGS", "NBCHAP_7", "NBCHAP_11",
                   "NBCHAP_13")
  
  # Format to upper case, remove punctuation and white spaces
  temp$DISTRICT_NS <- gsub("[[:punct:]]", "", temp$DISTRICT_NS)
  temp$DISTRICT_NS <- gsub(" ", "", temp$DISTRICT_NS)
  
  temp$DATE <- str_sub(basename(x), 10, 19)
  temp$DATE <- str_replace_all(temp$DATE, "_", "/")
  
  return(temp)
})

# ---- archived -----------------------------------------------------------

f2_three <- bind_rows(xls_f2, pdf_f2) %>% 
  mutate(DATE = as.Date(DATE, "%Y/%m/%d"))

# Next, need to remove the Circuits and Total. Then turn values to numeric.
#  There's a problem with commas when coerced to numeric, remove commas
circuits <- c("10TH", "11TH", "1ST", "2ND", "3RD", "4TH",
              "5TH", "6TH", "7TH", "8TH", "9TH", "TOTAL")
f2_three <- f2_three %>% 
  filter(!(DISTRICT_NS %in% circuits)) %>% 
  mutate_at(vars(-DISTRICT_NS, -DATE),
            funs(as.integer(gsub(",", "", .))))

f2_three[is.na(f2_three)] <- 0

# Set the "other" bankruptcies to NA prior to 2018-09-30
f2_three <- f2_three %>% 
  mutate(TOTAL_OTHER = if_else(DATE < "2018-09-30",
                               NA_real_, TOTAL_OTHER),
         TOTAL_BCHAP_OTHER = if_else(DATE < "2018-09-30",
                                     NA_real_, TOTAL_BCHAP_OTHER))

archived <- read_csv("0-data/uscourts/archived/f2_three/f2_three_archive.csv")

f2_three <- archived %>% 
  filter(!is.na(DISTRICT_NS), DATE < "2001-03-31") %>% 
  select(DATE, DISTRICT_NS, CHAP_12) %>% 
  bind_rows(f2_three) %>% 
  arrange(DATE)

# ADD IN TEMPORARY IMPUTATION METHOD FOR QUARTERLY DATA
j5 <- read_rds("0-data/uscourts/archived/f2/f2_temp.rds") %>% 
  filter(!is.na(STATE), DATE < "1995-12-31") %>%
  select(DATE, DISTRICT_NS, impute)

f2_three <- bind_rows(f2_three, j5) %>% 
  arrange(DATE) %>% 
  mutate(impute = ifelse(is.na(impute), CHAP_12, impute))

# ---- clean-up -----------------------------------------------------------

library("lubridate")

# 2018-09-30 combines Arkansas Eastern and Western into one, not sure why
arkansas_hack <- data.frame(STATE = "ARKANSAS", DISTRICT = "ARKANSAS",
                            DISTRICT_NS = "AR", CIRCUIT = "EIGHTH CIRCUIT",
                            CIRCUIT_NUM = "8TH")

f2_three_final <- read_csv("0-data/uscourts/district_ns.csv") %>% 
  bind_rows(arkansas_hack) %>% 
  right_join(f2_three) %>% 
  mutate(YEAR = year(DATE),
         QTR_ENDED = format(DATE, "%m/%d/%y"),
         FISCAL_YEAR = year(floor_date(DATE + 1, unit = "year")),
         ST_ABRV = state.abb[match(STATE,toupper(state.name))],
         ST_ABRV = case_when(STATE == "DISTRICT OF COLUMBIA" ~ "DC",
                             STATE == "PUERTO RICO" ~ "PR",
                             STATE == "VIRGIN ISLANDS" ~ "VI",
                             STATE == "NORTHERN MARIANA ISLANDS" ~ "NMI",
                             STATE == "GUAM" ~ "GU",
                             TRUE ~ ST_ABRV)) %>% 
  select(STATE:DATE, TOTAL_FILINGS, CHAP_7, CHAP_11, CHAP_12, everything())

write_csv(f2_three_final, paste0(local_dir, "/f2_three.csv"))
write_rds(f2_three_final, paste0(local_dir, "/f2_three.rds"))
