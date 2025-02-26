###continuation of Step 5: FWI data calculations 
##need to take the average of the different potential days of burn for each fire 

library(tidyverse)
library(sf)
library(vroom)

f <- list.files(path = "YF_RealPerimeters/OutputYFFires/Step05/Days/", pattern = "*.csv", full.names = TRUE)
allData = vroom::vroom(f)


##Find the average of all the FWI variables

all_data_summary <- allData%>%
  group_by(NAME, ID2, RID)%>%
  summarise(build_up_index_ave = mean(build_up_index),
              burning_index_ave = mean(burning_index), 
                drought_code_ave = mean(drought_code), 
                  drought_factor_ave = mean(drought_factor), 
                      duff_moisture_code_ave = mean(duff_moisture_code), 
                        energy_release_component_ave = mean(energy_release_component), 
                          fine_fuel_moisture_code_ave = mean(fine_fuel_moisture_code),
                            fire_daily_severity_rating_ave = mean(fire_daily_severity_rating), 
                                fire_danger_index_ave = mean(fire_danger_index),
                                    fire_weather_index_ave = mean(fire_weather_index), 
                                      ignition_component_ave = mean(ignition_component), 
                                          initial_fire_spread_index_ave = mean(initial_fire_spread_index),
                                            keetch_byram_drought_index_ave = mean(keetch_byram_drought_index),
                                              spread_component_ave = mean(spread_component))


##Load the pts data to get the point geometry back: 

pts = st_read("YF_RealPerimeters/OutputYFFires/BurnPoints.shp", "BurnPoints")


pts1 = pts %>%
  dplyr::select(NAME, RID, geometry)

##join the pt and averaged FWI data together 
all_data_summary1 <- all_data_summary%>%
left_join(., pts1, by = join_by("RID", "NAME")) %>%
  st_as_sf() 

###vizualize some data 

##Add a day of burn (the number of days burned) to help vizualize the differences between days 

allData <- allData%>%
mutate(DayofBurn = case_when((NAME == "Burman Lake") ~ 1, 
                             (NAME == "Chahalie" & DOB_Ist == "195") ~ 1, 
                             (NAME == "Chahalie" & DOB_Ist == "196") ~ 2, 
                             (NAME == "Chloya Lakes" & DOB_Ist == "213") ~ 1, 
                              (NAME == "Chloya Lakes" & DOB_Ist == "214") ~ 2,
                              (NAME == "Chloya Lakes" & DOB_Ist == "215") ~ 3,
                               (NAME == "Discovery Creek" & DOB_Ist == "198") ~ 1, 
                                (NAME == "Discovery Creek" & DOB_Ist == "199")~ 2, 
                              (NAME == "Discovery Creek" & DOB_Ist == "200") ~ 3, 
                              (NAME == "Kuranakh" & DOB_Ist == "169")~1, 
                              (NAME == "Kuranakh" & DOB_Ist == "170")~2,
                             (NAME == "Little Mosquito") ~1,
                             (NAME == "Marten Creek" & DOB_Ist == "151")~1,
                             (NAME == "Marten Creek" & DOB_Ist == "152")~2,
                             (NAME == "Marten Creek" & DOB_Ist == "153")~3,
                             (NAME == "Medicine Lake" & DOB_Ist == "164")~1,
                             (NAME == "Medicine Lake" & DOB_Ist == "165")~2,
                             (NAME == "Vunle Lakes" & DOB_Ist == "189")~1,
                             (NAME == "Vunle Lakes" & DOB_Ist == "190")~2,
                             (NAME == "Vunle Lakes" & DOB_Ist == "191")~3))


allData$DayofBurn <- as.character(allData$DayofBurn)


##Vizualize the data 
ggplot(allData, aes(x = NAME, y = fire_weather_index, group = DayofBurn, fill = DayofBurn)) +
  geom_bar(position = "dodge", stat = "identity")

ggplot(allData, aes(x = NAME, y = build_up_index, group = DayofBurn, fill = DayofBurn)) +
  geom_bar(position = "dodge", stat = "identity")

##etc.....


##save the FWI data 
##As CSV
st_write(all_data_summary1, "YF_RealPerimeters/OutputYFFires/Step05/FWI_average.csv")

##As shapefile 

st_write(all_data_summary1, "YF_RealPerimeters/OutputYFFires/Step05/FWI_average.shp", driver="ESRI Shapefile", append = FALSE)
