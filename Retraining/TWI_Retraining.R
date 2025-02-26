#Code and comments taken from:https://vt-hydroinformatics.github.io/rgeoraster.html
library(tidyverse)
library(raster)
library(sf)
library(whitebox)
library(tmap)


DEM_tiles  = st_read("/Users/kmathes/Desktop/COMBUSTION MODEL/combustion_model/FABDEM_v1-2_tiles.geojson")%>%
  st_transform(crs = 4326)


allPredictors = read.csv("/Users/kmathes/Desktop/COMBUSTION MODEL/combustion_model/Retraining/all_predictors.csv")

all_predictors_forGEE <- allPredictors%>%
  dplyr::select(project.name, burn_year, id, latitude, longitude)

write_csv(all_predictors_forGEE, "Retraining/allpredictors_forGEE.csv")


allPredictors <- st_as_sf(allPredictors, coords = c("longitude", "latitude"), crs = 4326)

cat(paste0(sprintf("'%s'", sort(unique(allPredictors$project.name))), collapse = ", "))

##Break up the allpredictors into geographic regions (based on project name)

AK_KT <- allPredictors%>%
  filter(project.name == "AK_KT")

AK_Rogers <- allPredictors%>%
  filter(project.name == "AK_Rogers")

CAN_deGroot <- allPredictors%>%
  filter(project.name == "CAN_deGroot")

Hoy_AK <- allPredictors%>%
  filter(project.name == "Hoy_AK")

JFSP_Boby <- allPredictors%>%
  filter(project.name == "JFSP_Boby")

NWT_BCKE <- allPredictors%>%
  filter(project.name == "NWT_BCKE")

NWT_MackWalker <- allPredictors%>%
  filter(project.name == "NWT_MackWalker")

SK_RTJ <- allPredictors%>%
  filter(project.name == "SK_RTJ")



##Find overlaping DEM tiles with the predictors dataframe (Broken up by project.name) 
Tile_intersection_Rogers <- st_intersection(DEM_tiles, AK_Rogers)%>%
  dplyr::select(tile_name, file_name, zipfile_name, id, project.name, burn_year)

Tile_intersection_CAN_deGroot <- st_intersection(DEM_tiles, CAN_deGroot)%>%
  dplyr::select(tile_name, file_name, zipfile_name, id, project.name, burn_year)

Tile_intersection_Hoy_AK <- st_intersection(DEM_tiles, Hoy_AK)%>%
  dplyr::select(tile_name, file_name, zipfile_name, id, project.name, burn_year)

Tile_intersection_AK_KT <- st_intersection(DEM_tiles, AK_KT)%>%
  dplyr::select(tile_name, file_name, zipfile_name, id, project.name, burn_year)

Tile_intersection_JFSP_Boby <- st_intersection(DEM_tiles, JFSP_Boby)%>%
  dplyr::select(tile_name, file_name, zipfile_name, id, project.name, burn_year)

Tile_intersection_NWT_BCKE <- st_intersection(DEM_tiles, NWT_BCKE)%>%
  dplyr::select(tile_name, file_name, zipfile_name, id, project.name, burn_year)

Tile_intersection_NWT_MackWalker <- st_intersection(DEM_tiles, NWT_MackWalker)%>%
  dplyr::select(tile_name, file_name, zipfile_name, id, project.name, burn_year)

Tile_intersection_SK_RTJ <- st_intersection(DEM_tiles, SK_RTJ)%>%
  dplyr::select(tile_name, file_name, zipfile_name, id, project.name, burn_year)

cat(paste0(sprintf("'%s'", length(unique(Tile_intersection_JFSP_Boby$tile_name)))))

cat(paste0(sprintf("'%s'", sort(unique(Tile_intersection_SK_RTJ$tile_name)), collapse = ", ")))

###Reference for GEE script 
###Tiles for CAN_deGroot: 
####'N55W098' 'N55W099' 'N56W098' 'N56W099' 'N60W114' 'N60W115' 'N63W139' 'N64W139'

###tiles for NWT_BCKE: 
##'N056W112' 'N060W115' 'N060W117' 'N060W118' 'N061W117' 'N061W118' 'N061W120' 'N062W114' 'N062W117'

##Tiles for NWT_MackWalker: 
#'N060W116' 'N060W117' 'N060W118' 'N061W117' 'N061W118' 'N061W120' 'N061W121' 'N061W122' 'N062W117' 'N063W114' 'N063W115' 'N064W115' 'N064W118'





##Unique tiles to analyze: 




# 'N60W114'
# 'N60W115' 
# 'N60W116'
# 'N60W117'
# 'N60W118'
# 'N61W117'
# 'N61W118'
# 'N61W120'
# 'N61W121'
# 'N61W122'
# 'N62W114'
# 'N62W117'
# 'N63W114'
# 'N63W115'
# 'N63W139'
# 'N64W115'
# 'N64W118'

# 'N64W139'




##Set some themes 
#theme_set(theme_classic())
tmap_mode("view")

##download tile looking at arcGIS tile map, finding the tile(s) that overlap with individual fire perimeters. 
#https://woodwell.maps.arcgis.com/apps/mapviewer/index.html?webmap=b6e979647429461c992c789226b5622b
##load in DEM raster



############################ TWI formula (Insert tile of interest/change the names of the associated end products) ###################

dem <- raster("Retraining/TWI/dem_N64W139.tif", crs = '+init=EPSG:4326')

##change name 
writeRaster(dem, "Retraining/TWI/dem.tif", overwrite = TRUE) 

#an artifact of outputting the DEM for this analysis is that there are a bunch of errant cells around the border that don’t belong in the DEM. If we make a map with them, it really throws off the scale. So we are going to set any elevation values below 1500 ft to NA.
#this does not work!!!! The elevation is too low
#dem[dem < 1500] <- NA

##Plot DEM 

tm_shape(dem)+
  tm_raster(style = "cont", palette = "PuOr", legend.show = TRUE)+
  tm_scale_bar()

##change name
##Hillshade
wbt_hillshade(dem = "Retraining/TWI/dem.tif",
              output = "Retraining/TWI/brush_hillshade.tif",
              azimuth = 115)

hillshade <- raster("Retraining/TWI/brush_hillshade.tif")


##Fill and breach depressions in prep for TWI derivation 
tm_shape(hillshade)+
  tm_raster(style = "cont",  palette = "-Greys",legend.show = FALSE)+
  tm_scale_bar()


wbt_breach_depressions_least_cost(
  dem = "Retraining/TWI/dem.tif",
  output = "Retraining/TWI/breached.tif",
  dist = 5,
  fill = TRUE)

wbt_fill_depressions_wang_and_liu(
  dem = "Retraining/TWI/breached.tif",
  output = "Retraining/TWI/filled_breached.tif"
)

filled_breached <- raster("Retraining/TWI/filled_breached.tif")

## What did this do?

difference <- dem - filled_breached


difference[difference == 0] <- NA

tm_shape(hillshade)+
  tm_raster(style = "cont", palette = "-Greys", legend.show = FALSE)+
  
  tm_shape(difference)+
  tm_raster(style = "cont",legend.show = TRUE)


##D8 Flow accumulation 

wbt_d8_flow_accumulation(input = "Retraining/TWI/filled_breached.tif",
                         output = "Retraining/TWI/flowaccumulation.tif")

d8 <- raster("Retraining/TWI/flowaccumulation.tif")

tm_shape(hillshade)+
  tm_raster(style = "cont",palette = "-Greys", legend.show = FALSE)+
  tm_shape(log(d8))+
  tm_raster(style = "cont", palette = "PuOr", legend.show = TRUE, alpha = .5)+
  tm_scale_bar()


##dinfinity flow accumulation 
wbt_d_inf_flow_accumulation("Retraining/TWI/filled_breached.tif",
                            "Retraining/TWI/flowaccumulationdf.tif", 
                            out_type = "Specific Contributing Area")

dinf <- raster("Retraining/TWI/flowaccumulationdf.tif")



##TWI 
wbt_slope(dem = "Retraining/TWI/filled_breached.tif",
          output = "Retraining/TWI/demslope.tif",
          units = "degrees")

wbt_wetness_index(sca = "Retraining/TWI/flowaccumulation.tif",
                  slope = "Retraining/TWI/demslope.tif",
                  output = "Retraining/TWI/TWI_N64W139.tif")

##change name
TWI <- raster("Retraining/TWI/TWI_N64W139.tif")

tm_shape(TWI)+
  tm_raster(style = "cont",palette = "PuOr")

##writeRaster(dem, "Retraining/TWI/dem_N55W098.tif", overwrite = TRUE) 





