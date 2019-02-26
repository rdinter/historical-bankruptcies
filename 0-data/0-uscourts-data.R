# Downloading files from uscourts.gov on bankruptcy, the tables we want are:
#  f2, f2_judicial, f2_one, f2_three, and f5a

library("httr")
library("rvest")
library("tidyverse")

# ---- f2 -----------------------------------------------------------------

# http://www.uscourts.gov/data-table-numbers/f-2

# f2 tables are at the district level and produced every quarter from
#  March 2001 onward. Each observations is for the 12-month period prior, so
#  while these are produced quarterly they are NOT quarterly data.

# Create a directory for the data
local_dir    <- "0-data/uscourts/f2"
data_source <- paste0(local_dir, "/raw")
if (!file.exists(local_dir)) dir.create(local_dir, recursive = T)
if (!file.exists(data_source)) dir.create(data_source)

base_url <- "http://www.uscourts.gov/statistics/table/f-2/bankruptcy-filings/"

# Starts in 2001, goes up until current year
years <- as.character(2001:format(Sys.Date(), "%Y"))
qtr   <- c("/03/31", "/06/30", "/09/30", "/12/31")

urls  <- expand.grid(years, qtr)
urls  <- paste0(urls$Var1, urls$Var2)


files <- map(urls, function(x){
  # Pause a second or three before downloading
  Sys.sleep(runif(1, 1, 3))
  x_urls <- paste0(base_url, x)
  temp   <- GET(x_urls)
  
  # In case the file doesn't exist:
  if (temp$status_code > 400) return()
  
  files <- temp %>% 
    read_html() %>% 
    html_nodes(".download-link") %>% 
    html_attr("href")
  file_type <- temp %>% 
    read_html() %>% 
    html_nodes(".file-info") %>%
    html_text()
  file_type <- gsub( ",.*$", "", file_type) # take characters before ,
  file_type <- gsub( "\\(", ".", file_type) # make ( a period
  
  file_name <- paste0(data_source, "/f2_", gsub("/", "_", x), file_type)
  
  map2(files, file_name, function(files, file_name){
    if (!file.exists(file_name)) {
      download.file(paste0("http://www.uscourts.gov", files), file_name)
    }
  })
  
  results <- data.frame(file_name = file_name, qtr = x)
  
  return(results)
})

files    <- bind_rows(files)

file_pdf <- files[grepl(".pdf", files$file_name), ]
file_xls <- files[grepl(".xls", files$file_name), ]

# ---- f2_judicial --------------------------------------------------------

# F-2 Tables, start in 1997 for September annually until 31 March 2001 then 
#  it is quarterly. Each data file is the 12-months prior number of filings.
#  They start off as pdfs, then they are xls. There's a subset called
#  "Judicial Business" which appear to be the Stam and Dixon data. It's every
#  September 30th and details previous 12-months.

# Create a directory for the data
local_dir    <- "0-data/uscourts/f2_judicial"
data_source <- paste0(local_dir, "/raw")
if (!file.exists(local_dir)) dir.create(local_dir, recursive = T)
if (!file.exists(data_source)) dir.create(data_source)

base_url <- "http://www.uscourts.gov/statistics/table/f-2/judicial-business/"

# Starts in 1997 goes to 2000 .... then the next grouping.
urls <- paste0(1997:format(Sys.Date(), "%Y"), "/09/30")

# http://www.uscourts.gov/statistics/table/f-2/judicial-business/1997/09/30

files <- map(urls, function(x){
  # Pause a second or three before downloading
  Sys.sleep(runif(1, 1, 3))
  x_urls <- paste0(base_url, x)
  temp   <- GET(x_urls)
  
  # In case the file doesn't exist:
  if (temp$status_code > 400) return()
  
  files <- temp %>% 
    read_html() %>% 
    html_nodes(".download-link") %>% 
    html_attr("href")
  file_type <- temp %>% 
    read_html() %>% 
    html_nodes(".file-info") %>%
    html_text()
  file_type <- gsub( ",.*$", "", file_type) # take characters before ,
  file_type <- gsub( "\\(", ".", file_type) # make ( a period
  
  file_name <- paste0(data_source, "/f2_judicial_", gsub("/", "_", x),
                      file_type)
  
  map2(files, file_name, function(files, file_name){
    if (!file.exists(file_name)) {
      download.file(paste0("http://www.uscourts.gov", files), file_name)
    }
  })
  
  results <- data.frame(file_name = file_name, qtr = x)
  
  return(results)
})

files    <- bind_rows(files)

file_pdf <- files[grepl(".pdf", files$file_name), ]
file_xls <- files[grepl(".xls", files$file_name), ]

# ---- f2_one -------------------------------------------------------------

# Monthly level data on bankruptcy filings begin on 31 March 2013. They appear
#  to always have a pdf, then mostly xls with at least one xlsx

# Create a directory for the data
local_dir    <- "0-data/uscourts/f2_one"
data_source <- paste0(local_dir, "/raw")
if (!file.exists(local_dir)) dir.create(local_dir, recursive = T)
if (!file.exists(data_source)) dir.create(data_source)

base_url <- paste0("http://www.uscourts.gov/statistics/table/",
                   "f-2-one-month/bankruptcy-filings/")

# Starts in 2013, goes up until current year as of right now.
years <- as.character(2013:format(Sys.Date(), "%Y"))
qtr   <- c("/03/31", "/06/30", "/09/30", "/12/31")

urls  <- expand.grid(years, qtr)
urls  <- paste0(urls$Var1, urls$Var2)

files <- map(urls, function(x){
  # Pause a second or three before downloading
  Sys.sleep(runif(1, 1, 3))
  x_urls <- paste0(base_url, x)
  temp   <- GET(x_urls)
  
  # In case the file doesn't exist:
  if (temp$status_code > 400) return()
  
  files <- temp %>% 
    read_html() %>% 
    html_nodes(".download-link") %>% 
    html_attr("href")
  file_type <- temp %>% 
    read_html() %>% 
    html_nodes(".file-info") %>%
    html_text()
  file_type <- gsub( ",.*$", "", file_type) # take characters before ,
  file_type <- gsub( "\\(", ".", file_type) # make ( a period
  
  file_name <- paste0(data_source, "/f2_one_", gsub("/", "_", x), file_type)
  
  map2(files, file_name, function(files, file_name){
    if (!file.exists(file_name)) {
      download.file(paste0("http://www.uscourts.gov", files), file_name)
    }
  })
  
  results <- data.frame(file_name = file_name, qtr = x)
  
  return(results)
})

files    <- bind_rows(files)

file_pdf <- files[grepl(".pdf", files$file_name), ]
file_xls <- files[grepl(".xls", files$file_name), ]

# ---- f2_three -----------------------------------------------------------

local_dir    <- "0-data/uscourts/f2_three"
data_source <- paste0(local_dir, "/raw")
if (!file.exists(local_dir)) dir.create(local_dir, recursive = T)
if (!file.exists(data_source)) dir.create(data_source)

base_url <- paste0("http://www.uscourts.gov/statistics/table/",
                   "f-2-three-months/bankruptcy-filings/")

# Starts in 2001, goes up until current year
years <- as.character(2001:format(Sys.Date(), "%Y"))
qtr   <- c("/03/31", "/06/30", "/09/30", "/12/31")

urls  <- expand.grid(years, qtr)
urls  <- paste0(urls$Var1, urls$Var2)

# http://www.uscourts.gov/statistics/table/f-2-three-months/
#  bankruptcy-filings/2016/09/30

files <- map(urls, function(x){
  # Pause a second or three before downloading
  Sys.sleep(runif(1, 1, 3))
  x_urls <- paste0(base_url, x)
  temp   <- GET(x_urls)
  
  # In case the file doesn't exist:
  if (temp$status_code > 400) return()
  
  files <- temp %>% 
    read_html() %>% 
    html_nodes(".download-link") %>% 
    html_attr("href")
  file_type <- temp %>% 
    read_html() %>% 
    html_nodes(".file-info") %>%
    html_text()
  file_type <- gsub( ",.*$", "", file_type) # take characters before ,
  file_type <- gsub( "\\(", ".", file_type) # make ( a period
  
  file_name <- paste0(data_source, "/f2_three_", gsub("/", "_", x), file_type)
  
  map2(files, file_name, function(files, file_name){
    if (!file.exists(file_name)) {
      download.file(paste0("http://www.uscourts.gov", files), file_name)
    }
  })
  
  results <- data.frame(file_name = file_name, qtr = x)
  
  return(results)
})

files    <- bind_rows(files)

file_pdf <- files[grepl(".pdf", files$file_name), ]
file_xls <- files[grepl(".xls", files$file_name), ]

# ---- f5a ----------------------------------------------------------------

# US Courts has county level observations for filings beginning in March 2013
#  there's a bit of conflict around what the FIPS mean
#  http://www.uscourts.gov/data-table-numbers/f-5a

local_dir    <- "0-data/uscourts/f5a"
data_source <- paste0(local_dir, "/raw")
if (!file.exists(local_dir)) dir.create(local_dir, recursive = T)
if (!file.exists(data_source)) dir.create(data_source)

base_url <- paste0("http://www.uscourts.gov/statistics/table/",
                   "f-5a/bankruptcy-filings/")

# Starts in 2013, goes up until current year
years <- as.character(2013:format(Sys.Date(), "%Y"))
qtr   <- c("/03/31", "/06/30", "/09/30", "/12/31")

urls  <- expand.grid(years, qtr)
urls  <- paste0(urls$Var1, urls$Var2)

# http://www.uscourts.gov/statistics/table/f-2-three-months/
#  bankruptcy-filings/2016/09/30

files <- map(urls, function(x){
  # Pause a second or three before downloading
  Sys.sleep(runif(1, 1, 3))
  x_urls <- paste0(base_url, x)
  temp   <- GET(x_urls)
  
  # In case the file doesn't exist:
  if (temp$status_code > 400) return()
  
  files <- temp %>% 
    read_html() %>% 
    html_nodes(".download-link") %>% 
    html_attr("href")
  file_type <- temp %>% 
    read_html() %>% 
    html_nodes(".file-info") %>%
    html_text()
  file_type <- gsub( ",.*$", "", file_type) # take characters before ,
  file_type <- gsub( "\\(", ".", file_type) # make ( a period
  
  file_name <- paste0(data_source, "/f5a_", gsub("/", "_", x), file_type)
  
  map2(files, file_name, function(files, file_name){
    if (!file.exists(file_name)) {
      download.file(paste0("http://www.uscourts.gov", files), file_name)
    }
  })
  
  results <- data.frame(file_name = file_name, qtr = x)
  
  return(results)
})

files    <- bind_rows(files)

file_pdf <- files[grepl(".pdf", files$file_name), ]
file_xls <- files[grepl(".xls", files$file_name), ]
