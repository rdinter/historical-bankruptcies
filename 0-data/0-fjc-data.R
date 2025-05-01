# Downloading files from uscourts.gov on bankruptcy
# https://www.fjc.gov/research/idb
#  bankruptcy-cases-filed-terminated-and-pending-fy-2008-present

# ---- start --------------------------------------------------------------

library(httr)
library(rvest)
library(tidyverse)

# Create a directory for the data
local_dir    <- "0-data/fjc/IDB"
data_source <- paste0(local_dir, "/raw")
if (!file.exists(local_dir)) dir.create(local_dir, recursive = T)
if (!file.exists(data_source)) dir.create(data_source)

# ---- download -----------------------------------------------------------

# Rvest links
# read in url from above, then extract the links that comply with:
links <- paste0("https://www.fjc.gov/research/idb/bankruptcy-cases-filed-",
                "terminated-and-pending-fy-2008-present") |> 
  read_html() |> 
  html_nodes(".views-field-field-description a") |> 
  html_attr("href")

# years <- str_pad(8:parse_number(format(Sys.Date(), "%y")),
#                  2, "left", "0")
# links <- paste0("https://www.fjc.gov/sites/default/files/idb/datasets/cpbank",
#                 years, ".zip")
# # Links hack for 2019 and 2020
# links <- append(links, paste0("https://www.fjc.gov/sites/default/files/idb/",
#                               "datasets/cpbank19_0.zip"))
# links <- append(links, paste0("https://www.fjc.gov/sites/default/files/idb/",
#                               "datasets/cpbank20_0.zip"))

link_files <- paste0(data_source, "/", basename(links))

# Certificate error correction:
set_config(config(ssl_verifypeer = 0L))
# For Ubuntu:
# sudo apt-get update && apt-get install ca-certificates
# sudo update-ca-certificates

# these are large files, may need to set a higher timeout limit
options(timeout=10*60)

download_links <- map2(link_files, links,  function(x, y) {
  
  if (!file.exists(x)) {
    Sys.sleep(runif(1, 30, 50))
    tryCatch(download.file(y, x, method = "libcurl"),
             warning = function(w) {
               "bad"
             })
  } else "exists"
})

# 
# map2(link_files, links, function(x, y){
#   if (!file.exists(x)) {
#     temp   <- GET(y)
#     
#     # In case the file doesn't exist:
#     if (temp$status_code > 400) return()
#     
#     # Wait so the server isn't overloaded
#     Sys.sleep(runif(1, 2, 5))
#     
#     GET(y, write_disk(x, overwrite = TRUE))
#   }
# })
# 
# File for the 2008 onward:
link08_on <- paste0("https://www.fjc.gov/sites/default/files/idb/textfiles/",
                    "cpbank08on_0.zip")
file08_on <- paste0(data_source, "/", basename(link08_on))

if (!file.exists(file08_on)) {
  library(RCurl)
  #
  f = CFILE(file08_on, mode="wb")
  curlPerform(url = link08_on, writedata = f@ref)
  close(f)
  
}
