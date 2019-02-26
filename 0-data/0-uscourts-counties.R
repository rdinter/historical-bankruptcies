# Scraping the court data for counties:
# https://www.pacer.gov/psco/cgi-bin/county-code.pl

library("rvest")
library("tidyverse")

# Create a directory for the data
local_dir    <- "0-data/uscourts/"
if (!file.exists(local_dir)) dir.create(local_dir, recursive = T)

page <- "https://www.pacer.gov/psco/cgi-bin/county-code.pl"

j5 <- html_session(page)

# Get options from site
fips_list <- j5$response %>%
  read_html() %>%
  html_nodes("option") %>% 
  html_attr("value") %>% 
  .[-1] # need to remove the first "default" which doesn't link to anything

# Now create a function to run through each of said fips values
scrape_courts <- function(fips, session, wait = 1){
  Sys.sleep(runif(1, 0, wait)) # be nice and don't overload their server
  
  j6   <- html_form(session)[[1]]
  form <- set_values(j6, county_code = fips)
  j7   <- submit_form(j5, form)
  
  out  <- j7$response %>% read_html() %>% 
    html_nodes("table") %>% 
    html_table(fill = TRUE) %>% # table is a bit strange, there's 2 of them
    .[[2]]
  
  # extract the actual values and attach a name to it
  out <- as.data.frame(t(out[2:6, 2]))
  names(out) <- c("FIPS", "COUNTY", "STATE", "DISTRICT", "CIRCUIT")
  
  return(out)
}

start <- Sys.time()
paste0("Started at ", start)

# Take the default values and cycle through them as the input across function
fips_courts <- map(fips_list, scrape_courts, session = j5)

done <- Sys.time()
paste0("Finished at ", done)
difftime(done, start)

# Merge the entire list into one data.frame, then inspect it
#  there should be 94 districts
#  http://www.uscourts.gov/about-federal-courts/court-role-and-structure
fips_data <- bind_rows(fips_courts)

table(fips_data$CIRCUIT)

table(fips_data$DISTRICT)
length(table(fips_data$DISTRICT)) # Shows 95 districts, why?

filter(fips_data, DISTRICT == "") # Problem "FIPS" are 66666, 88888, and 99999


# Export it as a .csv
write_csv(fips_data, paste0(local_dir, "/district_counties.csv"))