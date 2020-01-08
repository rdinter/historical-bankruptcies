# Robert Dinterman

# NOTE: ORGFLDT only applies to cases that were split, transferred or reopened
#  SEQ indicates how many times the case has been opened/reopened

# These dollar limits do sound arbitrary, and to some extent they are, simply 
#  reflecting a Congressional compromise going back 34 years to the original
#  passage of the Bankruptcy Code in 1978. The limits back then were only
#  $100,000 unsecured debt and $350,000 secured debt. These didn’t change until
#  more than doubling in 1994 to $250,000 and $750,000, respectively, with
#  inflationary increases every three years thereafter. The current amounts
#  have been in effect since April 1, 2010 and will change again on
#  April 1, 2013.
# https://wassonthornhill.com/the-chapter-13-debt-limits/

# ---- start --------------------------------------------------------------

library("lubridate")
library("stringr")
library("tidyverse")
library("zipcode")
data(zipcode)

meann <- function(x) mean(x, na.rm = T)
sumn  <- function(x) sum(x, na.rm = T)
Mode  <- function(x) {
  x  <- na.omit(x)
  ux <- unique(x)
  ux[which.max(tabulate(match(x, ux)))]
}
# instead of the slow group_by method:
first_non <- function(x) x[which(!is.na(x))[1]]
monnb <- function(d) {
  lt <- as.POSIXlt(as.Date(d, origin = "1900-01-01"))
  lt$year*12 + lt$mon 
  } 
# compute a month difference as a difference between two monnb's
mondf <- function(d1, d2) { monnb(d1) - monnb(d2) }
# take it for a spin
mondf(as.Date("2008-01-01"), Sys.Date())

local_dir   <- "1-tidy/bankruptcy"
if (!file.exists(local_dir)) dir.create(local_dir)

bus <- read_rds("0-data/fjc/IDB/raw_business_new.rds") %>% 
  # Denote the debt limit at the time of filing
  # In 1978, limits were $100,000 and $350,000. Then changed in
  # 1994 - $250,000 and $750,000
  # 1998 - $270,000 and $807,000
  # 2001 - $290,525 and $871,550
  # 2004 - $307,675 and $922,975
  # 2007 - $336,900 and $1,010,650
  # 2010 - $360,475 and $1,081,400
  # 2013 - $383,175 and $1,149,525
  # 2016 - $394,725 and $1,184,200
  # 2019 - ???
  mutate(ch13_unsec_limit = case_when(FILEDATE < "1994-04-01" ~ 100000,
                                      FILEDATE < "1998-04-01" ~ 250000,
                                      FILEDATE < "2001-04-01" ~ 270000,
                                      FILEDATE < "2004-04-01" ~ 290525,
                                      FILEDATE < "2007-04-01" ~ 307675,
                                      FILEDATE < "2010-04-01" ~ 336900,
                                      FILEDATE < "2013-04-01" ~ 360475,
                                      FILEDATE < "2016-04-01" ~ 383175,
                                      FILEDATE < "2019-04-01" ~ 394725,
                                      FILEDATE > "2019-04-01" ~ 419275),
         ch13_sec_limit = case_when(FILEDATE < "1994-04-01" ~ 350000,
                                    FILEDATE < "1998-04-01" ~ 750000,
                                    FILEDATE < "2001-04-01" ~ 807000,
                                    FILEDATE < "2004-04-01" ~ 871550,
                                    FILEDATE < "2007-04-01" ~ 922975,
                                    FILEDATE < "2010-04-01" ~ 1010650,
                                    FILEDATE < "2013-04-01" ~ 1081400,
                                    FILEDATE < "2016-04-01" ~ 1149525,
                                    FILEDATE < "2019-04-01" ~ 1184200,
                                    FILEDATE > "2019-04-01" ~ 1257850),
         debt_limit = case_when(FILEDATE < "2005-10-17" ~ 1500000,
                                FILEDATE < "2007-04-01" ~ 3237000,
                                FILEDATE < "2010-04-01" ~ 3544525,
                                FILEDATE < "2013-04-01" ~ 3792650,
                                FILEDATE < "2016-04-01" ~ 4031575,
                                FILEDATE < "2019-04-01" ~ 4153150,
                                FILEDATE > "2019-04-01" ~ 4411400))

# Other variables to consider:
#  # of creditors - ECRDTRS (estimated)
#  pro se - D1FPRSE (filing pro se, first listed debtor)
#  previous filer - PRFILE (prior filing)
#  corporation - DBTRTYP (type of debtor) 
#  involuntary - CASETYP (involuntary versus voluntary)

farm <- read_rds("0-data/fjc/IDB/raw_ch12s_new.rds") %>% 
  # Denote the debt limit at the time of filing
  # $1,500,000 prior to BAPCPA
  # $3,237,000 in 2005, adjusted every 3 years by CPI on April 1
  # $3,544,525 in 2008
  # $3,792,650 in 2011
  # $4,031,575 in 2014
  # $4,153,150 in 2017
  mutate(debt_limit = case_when(FILEDATE < "2005-10-17" ~ 1500000,
                                FILEDATE < "2007-04-01" ~ 3237000,
                                FILEDATE < "2010-04-01" ~ 3544525,
                                FILEDATE < "2013-04-01" ~ 3792650,
                                FILEDATE < "2016-04-01" ~ 4031575,
                                FILEDATE < "2019-04-01" ~ 4153150,
                                FILEDATE > "2019-04-01" ~ 4411400))

j5 <- farm %>% 
  mutate(start = if_else(is.na(ORGFLDT), FILEDATE, ORGFLDT),
         close = if_else(is.na(CLOSEDT), as.Date("2019-09-30"), CLOSEDT),
         start_year = year(start)) %>% 
  group_by(CASEKEY) %>% 
  arrange(SNAPSHOT) %>% 
  slice(n()) %>% 
  # group_by(CASEKEY, start_year, FILEFY, D1CNTY, D1ZIP, DISTRICT_NS, NOB,
  #          debt_limit, result, PRFILE, D1FPRSE, JOINT, D2FPRSE,
  #          ECRDTRS, DBTRTYP, org_chap, crnt_chap, cl_chap, SEQ) %>% 
  summarise(start_year = first_non(start_year), FILEFY = first_non(FILEFY),
            D1CNTY = first_non(D1CNTY), D1ZIP = first_non(D1ZIP),
            DISTRICT_NS = first_non(DISTRICT_NS), NOB = first_non(NOB),
            debt_limit = first_non(debt_limit), result = first_non(result),
            PRFILE = first_non(PRFILE), D1FPRSE = first_non(D1FPRSE),
            JOINT = first_non(JOINT), D2FPRSE = first_non(D2FPRSE),
            ECRDTRS = first_non(ECRDTRS), DBTRTYP = first_non(DBTRTYP),
            CASETYP = first_non(CASETYP),
            org_chap = first_non(org_chap), crnt_chap = first_non(crnt_chap),
            cl_chap = first_non(cl_chap), SEQ = first_non(SEQ),
            duration = max(close) - max(start),
            duration_day = difftime(max(close), max(start), units = "days"),
            duration_weeks = difftime(max(close), max(start), units = "weeks"),
            duration_months = mondf(max(close), max(start)),
            start = min(start),
            close = max(close),
            closed = sum(!is.na(CLOSEDT)) > 0,
            assets = Mode(TOTASSTS),
            real_property = Mode(REALPROP),
            personal_property = Mode(PERSPROP),
            liabilities = Mode(TOTLBLTS),
            secured = Mode(SECURED),
            unsecured1 = Mode(UNSECPR),
            unsecured2 = Mode(UNSECNPR),
            debts = Mode(TOTDBT),
            discharged = Mode(DSCHRGD),
            not_discharged = Mode(NDSCHRGD),
            income_average = Mode(AVGMNTHI),
            income_current = Mode(CNTMNTHI),
            expenses_average = Mode(AVGMNTHE)) %>% 
  ungroup()

county <- read_delim("0-data/shapefiles/raw/2015_Gaz_counties_national.zip",
                     "\t", escape_double = FALSE, trim_ws = TRUE)

j5 <- j5 %>% 
  mutate(zip = str_sub(D1ZIP, 1, 5)) %>% 
  left_join(zipcode)

j5 <- county %>% 
  select(D1CNTY = GEOID, INTPTLAT, INTPTLONG) %>% 
  right_join(j5)

j5 <- j5 %>% 
  mutate(lat = if_else(is.na(latitude), INTPTLAT, latitude),
         long = if_else(is.na(longitude), INTPTLONG, longitude))

write_csv(j5, paste0(local_dir, "/ch12_bankruptcy.csv"))
write_rds(j5, paste0(local_dir, "/ch12_bankruptcy.rds"))

j5 <- filter(j5, start > "2007-09-30")

write_csv(j5, paste0(local_dir, "/ch12_bankruptcy_f2008.csv"))

# ---- business -----------------------------------------------------------
# 
# 
# j5 <- bus %>% 
#   mutate(start = if_else(is.na(ORGFLDT), FILEDATE, ORGFLDT),
#          close = if_else(is.na(CLOSEDT), as.Date("2018-09-30"), CLOSEDT),
#          start_year = year(start)) %>% 
#   group_by(CASEKEY) %>% 
#   arrange(SNAPSHOT) %>% 
#   slice(n()) %>% 
#   # group_by(CASEKEY, start_year, FILEFY, D1CNTY, DISTRICT_NS, NOB,
#   #          ch13_unsec_limit, ch13_sec_limit, debt_limit, result,
#   #          PRFILE, D1FPRSE, JOINT, D2FPRSE, ECRDTRS, DBTRTYP,
#   #          org_chap, crnt_chap, cl_chap, SEQ) %>% 
#   summarise(start_year = first_non(start_year),
#             FILEFY = first_non(FILEFY), D1CNTY = first_non(D1CNTY),
#             DISTRICT_NS = first_non(DISTRICT_NS), NOB = first_non(NOB),
#             ch13_unsec_limit = first_non(ch13_unsec_limit),
#             ch13_sec_limit = first_non(ch13_sec_limit),
#             debt_limit = first_non(debt_limit), result = first_non(result),
#             PRFILE = first_non(PRFILE), D1FPRSE = first_non(D1FPRSE),
#             JOINT = first_non(JOINT), D2FPRSE = first_non(D2FPRSE),
#             ECRDTRS = first_non(ECRDTRS), DBTRTYP = first_non(DBTRTYP),
#             CASETYP = first_non(CASETYP),
#             org_chap = first_non(org_chap), crnt_chap = first_non(crnt_chap),
#             cl_chap = first_non(cl_chap), SEQ = first_non(SEQ),
#             duration = max(close) - max(start),
#             duration_day = difftime(max(close), max(start), units = "days"),
#             duration_weeks = difftime(max(close), max(start), units = "weeks"),
#             duration_months = mondf(max(close), max(start)),
#             start = min(start),
#             close = max(close),
#             closed = sum(!is.na(CLOSEDT)) > 0,
#             assets = Mode(TOTASSTS),
#             real_property = Mode(REALPROP),
#             personal_property = Mode(PERSPROP),
#             liabilities = Mode(TOTLBLTS),
#             secured = Mode(SECURED),
#             unsecured1 = Mode(UNSECPR),
#             unsecured2 = Mode(UNSECNPR),
#             debts = Mode(TOTDBT),
#             discharged = Mode(DSCHRGD),
#             not_discharged = Mode(NDSCHRGD),
#             income_average = Mode(AVGMNTHI),
#             income_current = Mode(CNTMNTHI),
#             expenses_average = Mode(AVGMNTHE)) %>% 
#   ungroup()
# 
# write_csv(j5, paste0(local_dir, "/business_bankruptcy.csv"))
# write_rds(j5, paste0(local_dir, "/business_bankruptcy.rds"))
# 
