
##library 
library(tidyverse)

##Data
all_predictors <- read.csv("Retraining/all_predictors.csv")

##Remove the variables we can't use and NAs
belowground_predictors <- all_predictors%>%
  filter(., !is.na(below.ground.carbon.combusted))%>%
  dplyr::select(!above.carbon.combusted)%>%
  dplyr::select(!NDII)%>%
  dplyr::select(!NDVI)%>%
  dplyr::select(!brightness)%>%
  dplyr::select(!greenness)%>%
  dplyr::select(!wetness)%>%
  dplyr::select(!dNBR)%>%
  dplyr::select(!rbr)%>%
  dplyr::select(!rdnbr)%>%
  dplyr::select(!FWI)%>%
  dplyr::select(!FFMC)%>%
  dplyr::select(!DC)%>%
  dplyr::select(!BUI)%>%
  dplyr::select(!DMC)%>%
  dplyr::select(!DSR)%>%
  dplyr::select(!ISI)%>%
  dplyr::select(!Relative.humidity)%>%
  dplyr::select(!Temperature)%>%
  dplyr::select(!VPD)%>%
  dplyr::select(!Wind.speed)%>%
  dplyr::select(!Date)%>%
  dplyr::select(!TWI)%>%
  dplyr::select(!elevation)%>%
  dplyr::select(!aspect)%>%
  dplyr::select(!slope)%>%
  dplyr::select(!Ruggedness)%>%
  drop_na()
  

aboveground_predictors <- all_predictors%>%
  filter(., !is.na(above.carbon.combusted))%>%
  dplyr::select(!below.ground.carbon.combusted)%>%
  dplyr::select(!NDII)%>%
  dplyr::select(!NDVI)%>%
  dplyr::select(!brightness)%>%
  dplyr::select(!greenness)%>%
  dplyr::select(!wetness)%>%
  dplyr::select(!dNBR)%>%
  dplyr::select(!rbr)%>%
  dplyr::select(!rdnbr)%>%
  dplyr::select(!FWI)%>%
  dplyr::select(!FFMC)%>%
  dplyr::select(!DC)%>%
  dplyr::select(!BUI)%>%
  dplyr::select(!DMC)%>%
  dplyr::select(!DSR)%>%
  dplyr::select(!ISI)%>%
  dplyr::select(!Relative.humidity)%>%
  dplyr::select(!Temperature)%>%
  dplyr::select(!VPD)%>%
  dplyr::select(!Wind.speed)%>%
  dplyr::select(!Date)%>%
  dplyr::select(!TWI)%>%
  dplyr::select(!elevation)%>%
  dplyr::select(!aspect)%>%
  dplyr::select(!slope)%>%
  dplyr::select(!Ruggedness)%>%
  drop_na()



##FWI (Copernicus dataset)

fwi <- list.files(path="Retraining/FWI_data/",pattern='*.csv', full.names = TRUE) %>% 
  purrr::map(., read_csv) %>% 
  bind_rows() %>%
  dplyr::select(!.geo)

## Merge with new FWI parameters
aboveground_predictors_newFWI <- aboveground_predictors%>%
  left_join(., fwi, by = c("id", "DOB_lst", "burn_year"))

belowground_predictors_newFWI <- belowground_predictors%>%
  left_join(., fwi, by = c("id", "DOB_lst", "burn_year"))


##Static terrain data (DEM, TWI, slope, aspect)
staticterrain <- list.files(path="Retraining/TWI_output/",pattern='*.csv', full.names = TRUE) %>% 
  purrr::map(., read_csv) %>% 
  bind_rows() %>%
  rename(project.name = projectname)%>%
  dplyr::select(!"system:index")%>%
  dplyr::select(!.geo)

## Merge with new static terrain parameters
aboveground_predictors_new_FWI_ST <- aboveground_predictors_newFWI%>%
  left_join(., staticterrain, by = c("id", "project.name", "burn_year"))

belowground_predictors_newFWI_ST <- belowground_predictors_newFWI%>%
  left_join(., staticterrain, by = c("id", "project.name", "burn_year")) 



aboveground_predictors_new_FWI_ST_noNA <- aboveground_predictors_new_FWI_ST%>%
  drop_na()

write_csv(aboveground_predictors_new_FWI_ST_noNA, "Retraining/new_aboveground_training_data.csv")

belowground_predictors_new_FWI_ST_noNA <- belowground_predictors_newFWI_ST%>%
  drop_na()

write_csv(belowground_predictors_new_FWI_ST_noNA, "Retraining/new_belowground_training_data.csv")

