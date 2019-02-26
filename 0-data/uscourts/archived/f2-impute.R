# Aggregating and imputing old F2 data down to the 3 month value

library("tidyverse")

f2full <- read_csv("0-data/uscourts/archived/f2/f2_full.csv") %>% 
  rename(CHAP_12_full = CHAP_12) %>% 
  filter(DATE < "1997-09-30") %>% 
  # Add in the imputed values I came up with for the missing 11th circuit
  mutate(CHAP_12_full = case_when(DISTRICT_NS == "ALN" &
                                    DATE == "1993-03-31" ~ 16,
                                  DISTRICT_NS == "ALM" &
                                    DATE == "1993-03-31" ~ 3,
                                  DISTRICT_NS == "ALS" &
                                    DATE == "1993-03-31" ~ 0,
                                  DISTRICT_NS == "FLN" &
                                    DATE == "1993-03-31" ~ 13,
                                  DISTRICT_NS == "FLM" &
                                    DATE == "1993-03-31" ~ 9,
                                  DISTRICT_NS == "FLS" &
                                    DATE == "1993-03-31" ~ 0,
                                  DISTRICT_NS == "GAN" &
                                    DATE == "1993-03-31" ~ 6,
                                  DISTRICT_NS == "GAM" &
                                    DATE == "1993-03-31" ~ 57,
                                  DISTRICT_NS == "GAS" &
                                    DATE == "1993-03-31" ~ 9,
                                  TRUE ~ CHAP_12_full))

f2_3 <- read_csv("0-data/uscourts/archived/f2_three/f2_three_archive.csv")

dates  <- seq(as.Date("1987/01/01"), as.Date("1996-12-31"), by="3 month") - 1

rdates <- rev(dates)

# ---- f2-full ------------------------------------------------------------

f2 <- left_join(f2full, f2_3) %>% 
  mutate(impute = CHAP_12)

f2$impute1 <- NA

f2$impute1[f2$DATE=="1987-03-31"] <- f2$CHAP_12_full[f2$DATE=="1987-03-31"]
f2$impute1[f2$DATE=="1987-06-30"] <- f2$CHAP_12_full[f2$DATE=="1987-06-30"] -
  f2$impute1[f2$DATE=="1987-03-31"]
f2$impute1[f2$DATE=="1987-09-30"] <- f2$CHAP_12_full[f2$DATE=="1987-09-30"] -
  f2$impute1[f2$DATE=="1987-06-30"] - f2$impute1[f2$DATE=="1987-03-31"]
# Missing the full 12 month of the 1987-12-31 report!
# f2$impute1[f2$DATE=="1988-03-31"] <- f2$CHAP_12_full[f2$DATE=="1988-03-31"] -
#   f2$impute1[f2$DATE=="1987-09-30"] - f2$impute1[f2$DATE=="1987-06-30"]

# --- brute ---------------------------------------------------------------

for(i in seq_along(rdates)){
  
  # Skip if we cannot calculate due to missing CHAP_12_full or out of range
  if (all(is.na(f2$CHAP_12_full[f2$DATE==rdates[i]]))) next
  if (all(is.na(f2$CHAP_12_full[f2$DATE==rdates[i+1]]))) next
  if (i > length(rdates) - 4) next
  
  f2$impute[f2$DATE==rdates[i+4]] <- f2$CHAP_12_full[f2$DATE==rdates[i+1]] +
    f2$impute[f2$DATE==rdates[i]] - f2$CHAP_12_full[f2$DATE==rdates[i]]
  print(rdates[i])
}

for(i in seq_along(dates)){
  
  # Skip if we cannot calculate due to missing CHAP_12_full or out of range
  if (all(is.na(f2$CHAP_12_full[f2$DATE==dates[i+4]]))) next
  if (all(is.na(f2$CHAP_12_full[f2$DATE==dates[i+3]]))) next
  if (i > length(dates) - 4) next
  
  f2$impute1[f2$DATE==dates[i]] <- f2$CHAP_12_full[f2$DATE==dates[i+3]] +
    f2$impute[f2$DATE==dates[i+4]] - f2$CHAP_12_full[f2$DATE==dates[i+4]]
  
  print(dates[i])
}

f2$impute <- ifelse(is.na(f2$impute), f2$impute1, f2$impute)

# Impute the impossible ones by splitting in half
f2$impute[f2$DATE == "1987-12-31"] <- f2$impute[f2$DATE == "1988-03-31"] <-
  (f2$CHAP_12_full[f2$DATE == "1988-03-31"] -
     f2$impute[f2$DATE == "1987-09-30"] - f2$impute[f2$DATE == "1987-06-30"])/2
f2$impute[f2$DATE == "1988-12-31"] <- f2$impute[f2$DATE == "1989-03-31"] <-
  (f2$CHAP_12_full[f2$DATE == "1989-03-31"] -
     f2$impute[f2$DATE == "1988-09-30"] - f2$impute[f2$DATE == "1988-06-30"])/2

write_csv(f2, "0-data/uscourts/archived/f2/f2_impute.csv")
write_rds(f2, "0-data/uscourts/archived/f2/f2_impute.rds")

# ---- graphs -------------------------------------------------------------

f2 %>% 
  filter(!is.na(STATE)) %>% 
  group_by(STATE, DATE) %>% 
  summarise(impute = sum(impute, na.rm = T)) %>% 
  gather(key, val, -DATE, -STATE) %>% 
  ggplot(aes(DATE, val, group = STATE, color = STATE)) +
  geom_line() +
  guides(color = FALSE) +
  coord_cartesian(ylim = c(-10, 50))
