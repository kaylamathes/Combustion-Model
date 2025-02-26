#Code and comments taken from:https://vt-hydroinformatics.github.io/rgeoraster.html
library(tidyverse)
library(raster)
library(sf)
library(whitebox)
library(tmap)

DEM_tiles  = st_read("/Users/kmathes/Desktop/COMBUSTION MODEL/combustion_model/FABDEM_v1-2_tiles.geojson")%>%
  st_transform(crs = 3338)

YFFireperimeters = st_read("/Users/kmathes/Desktop/COMBUSTION MODEL/combustion_model/YF_RealPerimeters/OutputYFFires/YFFiresPerimeters.shp")%>%
  st_transform(crs = 3338)


##Find overlaping DEM tiles with the fire points datafile 
Tile_intersection <- st_intersection(DEM_tiles, YFFireperimeters)%>%
  dplyr::select(tile_name, file_name, zipfile_name, fireYr, NAME)

cat(paste0(sprintf("'%s'", length(unique(Tile_intersection$tile_name)))))

##Set some themes 
#theme_set(theme_classic())
tmap_mode("view")

##download tile looking at arcGIS tile map, finding the tile(s) that overlap with individual fire perimeters. 
#https://woodwell.maps.arcgis.com/apps/mapviewer/index.html?webmap=b6e979647429461c992c789226b5622b
##load in DEM raster


###Nine YFFires 
############################ Little Mosquito ###################

dem <- raster("/Users/kmathes/Desktop/DATA/FABDEM/N60W150-N70W140_FABDEM_V1-2/N65W145_FABDEM_V1-2.tif", crs = '+init=EPSG:4326')

writeRaster(dem, "YF_RealPerimeters/TWI/dem_LittleMosquito.tif", overwrite = TRUE) 

#an artifact of outputting the DEM for this analysis is that there are a bunch of errant cells around the border that don’t belong in the DEM. If we make a map with them, it really throws off the scale. So we are going to set any elevation values below 1500 ft to NA.
#this does not work!!!! The elevation is too low
#dem[dem < 1500] <- NA

##Plot DEM 

tm_shape(dem)+
  tm_raster(style = "cont", palette = "PuOr", legend.show = TRUE)+
  tm_scale_bar()


##Hillshade
wbt_hillshade(dem = "YF_RealPerimeters/TWI/dem_LittleMosquito.tif",
              output = "YF_RealPerimeters/TWI/brush_hillshade_LittleMosquito.tif",
              azimuth = 115)

hillshade <- raster("YF_RealPerimeters/TWI/brush_hillshade_LittleMosquito.tif")


##Fill and breach depressions in prep for TWI derivation 
tm_shape(hillshade)+
  tm_raster(style = "cont",  palette = "-Greys",legend.show = FALSE)+
  tm_scale_bar()


wbt_breach_depressions_least_cost(
  dem = "YF_RealPerimeters/TWI/dem_LittleMosquito.tif",
  output = "YF_RealPerimeters/TWI/breached_LittleMosquito.tif",
  dist = 5,
  fill = TRUE)

wbt_fill_depressions_wang_and_liu(
  dem = "YF_RealPerimeters/TWI/breached_LittleMosquito.tif",
  output = "YF_RealPerimeters/TWI/filled_breached_LittleMosquito.tif"
)

filled_breached <- raster("YF_RealPerimeters/TWI/filled_breached_LittleMosquito.tif")

## What did this do?

difference <- dem - filled_breached


difference[difference == 0] <- NA

tm_shape(hillshade)+
  tm_raster(style = "cont", palette = "-Greys", legend.show = FALSE)+
  
  tm_shape(difference)+
  tm_raster(style = "cont",legend.show = TRUE)


##D8 Flow accumulation 

wbt_d8_flow_accumulation(input = "YF_RealPerimeters/TWI/filled_breached_LittleMosquito.tif",
                         output = "YF_RealPerimeters/TWI/flowaccumulation_LittleMosquito.tif")

d8 <- raster("YF_RealPerimeters/TWI/flowaccumulation_LittleMosquito.tif")

tm_shape(hillshade)+
  tm_raster(style = "cont",palette = "-Greys", legend.show = FALSE)+
  tm_shape(log(d8))+
  tm_raster(style = "cont", palette = "PuOr", legend.show = TRUE, alpha = .5)+
  tm_scale_bar()


##dinfinity flow accumulation 
wbt_d_inf_flow_accumulation("YF_RealPerimeters/TWI/filled_breached_LittleMosquito.tif",
                            "YF_RealPerimeters/TWI/flowaccumulationdf_LittleMosquito.tif", 
                            out_type = "Specific Contributing Area")

dinf <- raster("YF_RealPerimeters/TWI/flowaccumulationdf_LittleMosquito.tif")



##TWI 
wbt_slope(dem = "YF_RealPerimeters/TWI/filled_breached_LittleMosquito.tif",
          output = "YF_RealPerimeters/TWI/demslope_LittleMosquito.tif",
          units = "degrees")

wbt_wetness_index(sca = "YF_RealPerimeters/TWI/flowaccumulation_LittleMosquito.tif",
                  slope = "YF_RealPerimeters/TWI/demslope_LittleMosquito.tif",
                  output = "YF_RealPerimeters/TWI/TWI_LittleMosquito.tif")

TWI <- raster("YF_RealPerimeters/TWI/TWI_LittleMosquito.tif")

tm_shape(TWI)+
  tm_raster(style = "cont",palette = "PuOr")


################################ Kuranakh ############


dem <- raster("/Users/kmathes/Desktop/DATA/FABDEM/N60W150-N70W140_FABDEM_V1-2/N66W146_FABDEM_V1-2.tif", crs = '+init=EPSG:4326')

writeRaster(dem, "YF_RealPerimeters/TWI/dem_Kuranakh.tif", overwrite = TRUE) 

#an artifact of outputting the DEM for this analysis is that there are a bunch of errant cells around the border that don’t belong in the DEM. If we make a map with them, it really throws off the scale. So we are going to set any elevation values below 1500 ft to NA.
#this does not work!!!! The elevation is too low
#dem[dem < 1500] <- NA

##Plot DEM 

tm_shape(dem)+
  tm_raster(style = "cont", palette = "PuOr", legend.show = TRUE)+
  tm_scale_bar()


##Hillshade
wbt_hillshade(dem = "YF_RealPerimeters/TWI/dem_Kuranakh.tif",
              output = "YF_RealPerimeters/TWI/brush_hillshade_Kuranakh.tif",
              azimuth = 115)

hillshade <- raster("YF_RealPerimeters/TWI/brush_hillshade_Kuranakh.tif")


##Fill and breach depressions in prep for TWI derivation 
tm_shape(hillshade)+
  tm_raster(style = "cont",  palette = "-Greys",legend.show = FALSE)+
  tm_scale_bar()


wbt_breach_depressions_least_cost(
  dem = "YF_RealPerimeters/TWI/dem_Kuranakh.tif",
  output = "YF_RealPerimeters/TWI/breached_Kuranakh.tif",
  dist = 5,
  fill = TRUE)

wbt_fill_depressions_wang_and_liu(
  dem = "YF_RealPerimeters/TWI/breached_Kuranakh.tif",
  output = "YF_RealPerimeters/TWI/filled_breached_Kuranakh.tif"
)

filled_breached <- raster("YF_RealPerimeters/TWI/filled_breached_Kuranakh.tif")

## What did this do?

difference <- dem - filled_breached


difference[difference == 0] <- NA

tm_shape(hillshade)+
  tm_raster(style = "cont", palette = "-Greys", legend.show = FALSE)+
  
  tm_shape(difference)+
  tm_raster(style = "cont",legend.show = TRUE)


##D8 Flow accumulation 

wbt_d8_flow_accumulation(input = "YF_RealPerimeters/TWI/filled_breached_Kuranakh.tif",
                         output = "YF_RealPerimeters/TWI/flowaccumulation_Kuranakh.tif")

d8 <- raster("YF_RealPerimeters/TWI/flowaccumulation_Kuranakh.tif")

tm_shape(hillshade)+
  tm_raster(style = "cont",palette = "-Greys", legend.show = FALSE)+
  tm_shape(log(d8))+
  tm_raster(style = "cont", palette = "PuOr", legend.show = TRUE, alpha = .5)+
  tm_scale_bar()


##dinfinity flow accumulation 
wbt_d_inf_flow_accumulation("YF_RealPerimeters/TWI/filled_breached_Kuranakh.tif",
                            "YF_RealPerimeters/TWI/flowaccumulationdf_Kuranakh.tif", 
                            out_type = "Specific Contributing Area")

dinf <- raster("YF_RealPerimeters/TWI/flowaccumulationdf_Kuranakh.tif")



##TWI 
wbt_slope(dem = "YF_RealPerimeters/TWI/filled_breached_Kuranakh.tif",
          output = "YF_RealPerimeters/TWI/demslope_Kuranakh.tif",
          units = "degrees")

wbt_wetness_index(sca = "YF_RealPerimeters/TWI/flowaccumulation_Kuranakh.tif",
                  slope = "YF_RealPerimeters/TWI/demslope_Kuranakh.tif",
                  output = "YF_RealPerimeters/TWI/TWI_Kuranakh.tif")

TWI <- raster("YF_RealPerimeters/TWI/TWI_Kuranakh.tif")

tm_shape(TWI)+
  tm_raster(style = "cont",palette = "PuOr")

############################### Burman Lake #############


dem <- raster("/Users/kmathes/Desktop/DATA/FABDEM/N60W150-N70W140_FABDEM_V1-2/N66W146_FABDEM_V1-2.tif", crs = '+init=EPSG:4326')

writeRaster(dem, "YF_RealPerimeters/TWI/dem_BurmanLake.tif", overwrite = TRUE) 

#an artifact of outputting the DEM for this analysis is that there are a bunch of errant cells around the border that don’t belong in the DEM. If we make a map with them, it really throws off the scale. So we are going to set any elevation values below 1500 ft to NA.
#this does not work!!!! The elevation is too low
#dem[dem < 1500] <- NA

##Plot DEM 

tm_shape(dem)+
  tm_raster(style = "cont", palette = "PuOr", legend.show = TRUE)+
  tm_scale_bar()


##Hillshade
wbt_hillshade(dem = "YF_RealPerimeters/TWI/dem_BurmanLake.tif",
              output = "YF_RealPerimeters/TWI/brush_hillshade_BurmanLake.tif",
              azimuth = 115)

hillshade <- raster("YF_RealPerimeters/TWI/brush_hillshade_BurmanLake.tif")


##Fill and breach depressions in prep for TWI derivation 
tm_shape(hillshade)+
  tm_raster(style = "cont",  palette = "-Greys",legend.show = FALSE)+
  tm_scale_bar()


wbt_breach_depressions_least_cost(
  dem = "YF_RealPerimeters/TWI/dem_BurmanLake.tif",
  output = "YF_RealPerimeters/TWI/breached_BurmanLake.tif",
  dist = 5,
  fill = TRUE)

wbt_fill_depressions_wang_and_liu(
  dem = "YF_RealPerimeters/TWI/breached_BurmanLake.tif",
  output = "YF_RealPerimeters/TWI/filled_breached_BurmanLake.tif"
)

filled_breached <- raster("YF_RealPerimeters/TWI/filled_breached_BurmanLake.tif")

## What did this do?

difference <- dem - filled_breached


difference[difference == 0] <- NA

tm_shape(hillshade)+
  tm_raster(style = "cont", palette = "-Greys", legend.show = FALSE)+
  
  tm_shape(difference)+
  tm_raster(style = "cont",legend.show = TRUE)


##D8 Flow accumulation 

wbt_d8_flow_accumulation(input = "YF_RealPerimeters/TWI/filled_breached_BurmanLake.tif",
                         output = "YF_RealPerimeters/TWI/flowaccumulation_BurmanLake.tif")

d8 <- raster("YF_RealPerimeters/TWI/flowaccumulation_BurmanLake.tif")

tm_shape(hillshade)+
  tm_raster(style = "cont",palette = "-Greys", legend.show = FALSE)+
  tm_shape(log(d8))+
  tm_raster(style = "cont", palette = "PuOr", legend.show = TRUE, alpha = .5)+
  tm_scale_bar()


##dinfinity flow accumulation 
wbt_d_inf_flow_accumulation("YF_RealPerimeters/TWI/filled_breached_BurmanLake.tif",
                            "YF_RealPerimeters/TWI/flowaccumulationdf_BurmanLake.tif", 
                            out_type = "Specific Contributing Area")

dinf <- raster("YF_RealPerimeters/TWI/flowaccumulationdf_BurmanLake.tif")



##TWI 
wbt_slope(dem = "YF_RealPerimeters/TWI/filled_breached_BurmanLake.tif",
          output = "YF_RealPerimeters/TWI/demslope_BurmanLake.tif",
          units = "degrees")

wbt_wetness_index(sca = "YF_RealPerimeters/TWI/flowaccumulation_BurmanLake.tif",
                  slope = "YF_RealPerimeters/TWI/demslope_BurmanLake.tif",
                  output = "YF_RealPerimeters/TWI/TWI_BurmanLake.tif")

TWI <- raster("YF_RealPerimeters/TWI/TWI_BurmanLake.tif")

tm_shape(TWI)+
  tm_raster(style = "cont",palette = "PuOr")


####################### Vunle Lakes ##########


dem <- raster("/Users/kmathes/Desktop/DATA/FABDEM/N60W150-N70W140_FABDEM_V1-2/N66W144_FABDEM_V1-2.tif", crs = '+init=EPSG:4326')

writeRaster(dem, "YF_RealPerimeters/TWI/dem_VunleLakes.tif", overwrite = TRUE) 

#an artifact of outputting the DEM for this analysis is that there are a bunch of errant cells around the border that don’t belong in the DEM. If we make a map with them, it really throws off the scale. So we are going to set any elevation values below 1500 ft to NA.
#this does not work!!!! The elevation is too low
#dem[dem < 1500] <- NA

##Plot DEM 

tm_shape(dem)+
  tm_raster(style = "cont", palette = "PuOr", legend.show = TRUE)+
  tm_scale_bar()


##Hillshade
wbt_hillshade(dem = "YF_RealPerimeters/TWI/dem_VunleLakes.tif",
              output = "YF_RealPerimeters/TWI/brush_hillshade_VunleLakes.tif",
              azimuth = 115)

hillshade <- raster("YF_RealPerimeters/TWI/brush_hillshade_VunleLakes.tif")


##Fill and breach depressions in prep for TWI derivation 
tm_shape(hillshade)+
  tm_raster(style = "cont",  palette = "-Greys",legend.show = FALSE)+
  tm_scale_bar()


wbt_breach_depressions_least_cost(
  dem = "YF_RealPerimeters/TWI/dem_VunleLakes.tif",
  output = "YF_RealPerimeters/TWI/breached_VunleLakes.tif",
  dist = 5,
  fill = TRUE)

wbt_fill_depressions_wang_and_liu(
  dem = "YF_RealPerimeters/TWI/breached_VunleLakes.tif",
  output = "YF_RealPerimeters/TWI/filled_breached_VunleLakes.tif"
)

filled_breached <- raster("YF_RealPerimeters/TWI/filled_breached_VunleLakes.tif")

## What did this do?

difference <- dem - filled_breached


difference[difference == 0] <- NA

tm_shape(hillshade)+
  tm_raster(style = "cont", palette = "-Greys", legend.show = FALSE)+
  
  tm_shape(difference)+
  tm_raster(style = "cont",legend.show = TRUE)


##D8 Flow accumulation 

wbt_d8_flow_accumulation(input = "YF_RealPerimeters/TWI/filled_breached_VunleLakes.tif",
                         output = "YF_RealPerimeters/TWI/flowaccumulation_VunleLakes.tif")

d8 <- raster("YF_RealPerimeters/TWI/flowaccumulation_VunleLakes.tif")

tm_shape(hillshade)+
  tm_raster(style = "cont",palette = "-Greys", legend.show = FALSE)+
  tm_shape(log(d8))+
  tm_raster(style = "cont", palette = "PuOr", legend.show = TRUE, alpha = .5)+
  tm_scale_bar()


##dinfinity flow accumulation 
wbt_d_inf_flow_accumulation("YF_RealPerimeters/TWI/filled_breached_VunleLakes.tif",
                            "YF_RealPerimeters/TWI/flowaccumulationdf_VunleLakes.tif", 
                            out_type = "Specific Contributing Area")

dinf <- raster("YF_RealPerimeters/TWI/flowaccumulationdf_VunleLakes.tif")



##TWI 
wbt_slope(dem = "YF_RealPerimeters/TWI/filled_breached_VunleLakes.tif",
          output = "YF_RealPerimeters/TWI/demslope_VunleLakes.tif",
          units = "degrees")

wbt_wetness_index(sca = "YF_RealPerimeters/TWI/flowaccumulation_VunleLakes.tif",
                  slope = "YF_RealPerimeters/TWI/demslope_VunleLakes.tif",
                  output = "YF_RealPerimeters/TWI/TWI_VunleLakes.tif")

TWI <- raster("YF_RealPerimeters/TWI/TWI_VunleLakes.tif")

tm_shape(TWI)+
  tm_raster(style = "cont",palette = "PuOr")

################################# Discovery Creek ###########


dem <- raster("/Users/kmathes/Desktop/DATA/FABDEM/N60W150-N70W140_FABDEM_V1-2/N66W146_FABDEM_V1-2.tif", crs = '+init=EPSG:4326')

writeRaster(dem, "YF_RealPerimeters/TWI/dem_DiscoveryCreek.tif", overwrite = TRUE) 

#an artifact of outputting the DEM for this analysis is that there are a bunch of errant cells around the border that don’t belong in the DEM. If we make a map with them, it really throws off the scale. So we are going to set any elevation values below 1500 ft to NA.
#this does not work!!!! The elevation is too low
#dem[dem < 1500] <- NA

##Plot DEM 

tm_shape(dem)+
  tm_raster(style = "cont", palette = "PuOr", legend.show = TRUE)+
  tm_scale_bar()


##Hillshade
wbt_hillshade(dem = "YF_RealPerimeters/TWI/dem_DiscoveryCreek.tif",
              output = "YF_RealPerimeters/TWI/brush_hillshade_DiscoveryCreek.tif",
              azimuth = 115)

hillshade <- raster("YF_RealPerimeters/TWI/brush_hillshade_DiscoveryCreek.tif")


##Fill and breach depressions in prep for TWI derivation 
tm_shape(hillshade)+
  tm_raster(style = "cont",  palette = "-Greys",legend.show = FALSE)+
  tm_scale_bar()


wbt_breach_depressions_least_cost(
  dem = "YF_RealPerimeters/TWI/dem_DiscoveryCreek.tif",
  output = "YF_RealPerimeters/TWI/breached_DiscoveryCreek.tif",
  dist = 5,
  fill = TRUE)

wbt_fill_depressions_wang_and_liu(
  dem = "YF_RealPerimeters/TWI/breached_DiscoveryCreek.tif",
  output = "YF_RealPerimeters/TWI/filled_breached_DiscoveryCreek.tif"
)

filled_breached <- raster("YF_RealPerimeters/TWI/filled_breached_DiscoveryCreek.tif")

## What did this do?

difference <- dem - filled_breached


difference[difference == 0] <- NA

tm_shape(hillshade)+
  tm_raster(style = "cont", palette = "-Greys", legend.show = FALSE)+
  
  tm_shape(difference)+
  tm_raster(style = "cont",legend.show = TRUE)


##D8 Flow accumulation 

wbt_d8_flow_accumulation(input = "YF_RealPerimeters/TWI/filled_breached_DiscoveryCreek.tif",
                         output = "YF_RealPerimeters/TWI/flowaccumulation_DiscoveryCreek.tif")

d8 <- raster("YF_RealPerimeters/TWI/flowaccumulation_DiscoveryCreek.tif")

tm_shape(hillshade)+
  tm_raster(style = "cont",palette = "-Greys", legend.show = FALSE)+
  tm_shape(log(d8))+
  tm_raster(style = "cont", palette = "PuOr", legend.show = TRUE, alpha = .5)+
  tm_scale_bar()


##dinfinity flow accumulation 
wbt_d_inf_flow_accumulation("YF_RealPerimeters/TWI/filled_breached_DiscoveryCreek.tif",
                            "YF_RealPerimeters/TWI/flowaccumulationdf_DiscoveryCreek.tif", 
                            out_type = "Specific Contributing Area")

dinf <- raster("YF_RealPerimeters/TWI/flowaccumulationdf_DiscoveryCreek.tif")



##TWI 
wbt_slope(dem = "YF_RealPerimeters/TWI/filled_breached_DiscoveryCreek.tif",
          output = "YF_RealPerimeters/TWI/demslope_DiscoveryCreek.tif",
          units = "degrees")

wbt_wetness_index(sca = "YF_RealPerimeters/TWI/flowaccumulation_DiscoveryCreek.tif",
                  slope = "YF_RealPerimeters/TWI/demslope_DiscoveryCreek.tif",
                  output = "YF_RealPerimeters/TWI/TWI_DiscoveryCreek.tif")

TWI <- raster("YF_RealPerimeters/TWI/TWI_DiscoveryCreek.tif")

tm_shape(TWI)+
  tm_raster(style = "cont",palette = "PuOr")


##################################### Chahalie #####################

dem <- raster("/Users/kmathes/Desktop/DATA/FABDEM/N60W150-N70W140_FABDEM_V1-2/N66W144_FABDEM_V1-2.tif", crs = '+init=EPSG:4326')

writeRaster(dem, "YF_RealPerimeters/TWI/dem_Chahalie.tif", overwrite = TRUE) 

#an artifact of outputting the DEM for this analysis is that there are a bunch of errant cells around the border that don’t belong in the DEM. If we make a map with them, it really throws off the scale. So we are going to set any elevation values below 1500 ft to NA.
#this does not work!!!! The elevation is too low
#dem[dem < 1500] <- NA

##Plot DEM 

tm_shape(dem)+
  tm_raster(style = "cont", palette = "PuOr", legend.show = TRUE)+
  tm_scale_bar()


##Hillshade
wbt_hillshade(dem = "YF_RealPerimeters/TWI/dem_Chahalie.tif",
              output = "YF_RealPerimeters/TWI/brush_hillshade_Chahalie.tif",
              azimuth = 115)

hillshade <- raster("YF_RealPerimeters/TWI/brush_hillshade_Chahalie.tif")


##Fill and breach depressions in prep for TWI derivation 
tm_shape(hillshade)+
  tm_raster(style = "cont",  palette = "-Greys",legend.show = FALSE)+
  tm_scale_bar()


wbt_breach_depressions_least_cost(
  dem = "YF_RealPerimeters/TWI/dem_Chahalie.tif",
  output = "YF_RealPerimeters/TWI/breached_Chahalie.tif",
  dist = 5,
  fill = TRUE)

wbt_fill_depressions_wang_and_liu(
  dem = "YF_RealPerimeters/TWI/breached_Chahalie.tif",
  output = "YF_RealPerimeters/TWI/filled_breached_Chahalie.tif"
)

filled_breached <- raster("YF_RealPerimeters/TWI/filled_breached_Chahalie.tif")

## What did this do?

difference <- dem - filled_breached


difference[difference == 0] <- NA

tm_shape(hillshade)+
  tm_raster(style = "cont", palette = "-Greys", legend.show = FALSE)+
  
  tm_shape(difference)+
  tm_raster(style = "cont",legend.show = TRUE)


##D8 Flow accumulation 

wbt_d8_flow_accumulation(input = "YF_RealPerimeters/TWI/filled_breached_Chahalie.tif",
                         output = "YF_RealPerimeters/TWI/flowaccumulation_Chahalie.tif")

d8 <- raster("YF_RealPerimeters/TWI/flowaccumulation_Chahalie.tif")

tm_shape(hillshade)+
  tm_raster(style = "cont",palette = "-Greys", legend.show = FALSE)+
  tm_shape(log(d8))+
  tm_raster(style = "cont", palette = "PuOr", legend.show = TRUE, alpha = .5)+
  tm_scale_bar()


##dinfinity flow accumulation 
wbt_d_inf_flow_accumulation("YF_RealPerimeters/TWI/filled_breached_Chahalie.tif",
                            "YF_RealPerimeters/TWI/flowaccumulationdf_Chahalie.tif", 
                            out_type = "Specific Contributing Area")

dinf <- raster("YF_RealPerimeters/TWI/flowaccumulationdf_Chahalie.tif")



##TWI 
wbt_slope(dem = "YF_RealPerimeters/TWI/filled_breached_Chahalie.tif",
          output = "YF_RealPerimeters/TWI/demslope_Chahalie.tif",
          units = "degrees")

wbt_wetness_index(sca = "YF_RealPerimeters/TWI/flowaccumulation_Chahalie.tif",
                  slope = "YF_RealPerimeters/TWI/demslope_Chahalie.tif",
                  output = "YF_RealPerimeters/TWI/TWI_Chahalie.tif")

TWI <- raster("YF_RealPerimeters/TWI/TWI_Chahalie.tif")

tm_shape(TWI)+
  tm_raster(style = "cont",palette = "PuOr")


######################### Marten Creek ################

dem <- raster("/Users/kmathes/Desktop/DATA/FABDEM/N60W150-N70W140_FABDEM_V1-2/N67W146_FABDEM_V1-2.tif", crs = '+init=EPSG:4326')

writeRaster(dem, "YF_RealPerimeters/TWI/dem_MartenCreek.tif", overwrite = TRUE) 

#an artifact of outputting the DEM for this analysis is that there are a bunch of errant cells around the border that don’t belong in the DEM. If we make a map with them, it really throws off the scale. So we are going to set any elevation values below 1500 ft to NA.
#this does not work!!!! The elevation is too low
#dem[dem < 1500] <- NA

##Plot DEM 

tm_shape(dem)+
  tm_raster(style = "cont", palette = "PuOr", legend.show = TRUE)+
  tm_scale_bar()


##Hillshade
wbt_hillshade(dem = "YF_RealPerimeters/TWI/dem_MartenCreek.tif",
              output = "YF_RealPerimeters/TWI/brush_hillshade_MartenCreek.tif",
              azimuth = 115)

hillshade <- raster("YF_RealPerimeters/TWI/brush_hillshade_MartenCreek.tif")


##Fill and breach depressions in prep for TWI derivation 
tm_shape(hillshade)+
  tm_raster(style = "cont",  palette = "-Greys",legend.show = FALSE)+
  tm_scale_bar()


wbt_breach_depressions_least_cost(
  dem = "YF_RealPerimeters/TWI/dem_MartenCreek.tif",
  output = "YF_RealPerimeters/TWI/breached_MartenCreek.tif",
  dist = 5,
  fill = TRUE)

wbt_fill_depressions_wang_and_liu(
  dem = "YF_RealPerimeters/TWI/breached_MartenCreek.tif",
  output = "YF_RealPerimeters/TWI/filled_breached_MartenCreek.tif"
)

filled_breached <- raster("YF_RealPerimeters/TWI/filled_breached_MartenCreek.tif")

## What did this do?

difference <- dem - filled_breached


difference[difference == 0] <- NA

tm_shape(hillshade)+
  tm_raster(style = "cont", palette = "-Greys", legend.show = FALSE)+
  
  tm_shape(difference)+
  tm_raster(style = "cont",legend.show = TRUE)


##D8 Flow accumulation 

wbt_d8_flow_accumulation(input = "YF_RealPerimeters/TWI/filled_breached_MartenCreek.tif",
                         output = "YF_RealPerimeters/TWI/flowaccumulation_MartenCreek.tif")

d8 <- raster("YF_RealPerimeters/TWI/flowaccumulation_MartenCreek.tif")

tm_shape(hillshade)+
  tm_raster(style = "cont",palette = "-Greys", legend.show = FALSE)+
  tm_shape(log(d8))+
  tm_raster(style = "cont", palette = "PuOr", legend.show = TRUE, alpha = .5)+
  tm_scale_bar()


##dinfinity flow accumulation 
wbt_d_inf_flow_accumulation("YF_RealPerimeters/TWI/filled_breached_MartenCreek.tif",
                            "YF_RealPerimeters/TWI/flowaccumulationdf_MartenCreek.tif", 
                            out_type = "Specific Contributing Area")

dinf <- raster("YF_RealPerimeters/TWI/flowaccumulationdf_MartenCreek.tif")



##TWI 
wbt_slope(dem = "YF_RealPerimeters/TWI/filled_breached_MartenCreek.tif",
          output = "YF_RealPerimeters/TWI/demslope_MartenCreek.tif",
          units = "degrees")

wbt_wetness_index(sca = "YF_RealPerimeters/TWI/flowaccumulation_MartenCreek.tif",
                  slope = "YF_RealPerimeters/TWI/demslope_MartenCreek.tif",
                  output = "YF_RealPerimeters/TWI/TWI_MartenCreek.tif")

TWI <- raster("YF_RealPerimeters/TWI/TWI_MartenCreek.tif")

tm_shape(TWI)+
  tm_raster(style = "cont",palette = "PuOr")

############################ Chloya Lakes ####################
dem <- raster("/Users/kmathes/Desktop/DATA/FABDEM/N60W150-N70W140_FABDEM_V1-2/N66W146_FABDEM_V1-2.tif", crs = '+init=EPSG:4326')

writeRaster(dem, "YF_RealPerimeters/TWI/dem_ChloyaLakes.tif", overwrite = TRUE) 

#an artifact of outputting the DEM for this analysis is that there are a bunch of errant cells around the border that don’t belong in the DEM. If we make a map with them, it really throws off the scale. So we are going to set any elevation values below 1500 ft to NA.
#this does not work!!!! The elevation is too low
#dem[dem < 1500] <- NA

##Plot DEM 

tm_shape(dem)+
  tm_raster(style = "cont", palette = "PuOr", legend.show = TRUE)+
  tm_scale_bar()


##Hillshade
wbt_hillshade(dem = "YF_RealPerimeters/TWI/dem_ChloyaLakes.tif",
              output = "YF_RealPerimeters/TWI/brush_hillshade_ChloyaLakes.tif",
              azimuth = 115)

hillshade <- raster("YF_RealPerimeters/TWI/brush_hillshade_ChloyaLakes.tif")


##Fill and breach depressions in prep for TWI derivation 
tm_shape(hillshade)+
  tm_raster(style = "cont",  palette = "-Greys",legend.show = FALSE)+
  tm_scale_bar()


wbt_breach_depressions_least_cost(
  dem = "YF_RealPerimeters/TWI/dem_ChloyaLakes.tif",
  output = "YF_RealPerimeters/TWI/breached_ChloyaLakes.tif",
  dist = 5,
  fill = TRUE)

wbt_fill_depressions_wang_and_liu(
  dem = "YF_RealPerimeters/TWI/breached_ChloyaLakes.tif",
  output = "YF_RealPerimeters/TWI/filled_breached_ChloyaLakes.tif"
)

filled_breached <- raster("YF_RealPerimeters/TWI/filled_breached_ChloyaLakes.tif")

## What did this do?

difference <- dem - filled_breached


difference[difference == 0] <- NA

tm_shape(hillshade)+
  tm_raster(style = "cont", palette = "-Greys", legend.show = FALSE)+
  
  tm_shape(difference)+
  tm_raster(style = "cont",legend.show = TRUE)


##D8 Flow accumulation 

wbt_d8_flow_accumulation(input = "YF_RealPerimeters/TWI/filled_breached_ChloyaLakes.tif",
                         output = "YF_RealPerimeters/TWI/flowaccumulation_ChloyaLakes.tif")

d8 <- raster("YF_RealPerimeters/TWI/flowaccumulation_ChloyaLakes.tif")

tm_shape(hillshade)+
  tm_raster(style = "cont",palette = "-Greys", legend.show = FALSE)+
  tm_shape(log(d8))+
  tm_raster(style = "cont", palette = "PuOr", legend.show = TRUE, alpha = .5)+
  tm_scale_bar()


##dinfinity flow accumulation 
wbt_d_inf_flow_accumulation("YF_RealPerimeters/TWI/filled_breached_ChloyaLakes.tif",
                            "YF_RealPerimeters/TWI/flowaccumulationdf_ChloyaLakes.tif", 
                            out_type = "Specific Contributing Area")

dinf <- raster("YF_RealPerimeters/TWI/flowaccumulationdf_ChloyaLakes.tif")



##TWI 
wbt_slope(dem = "YF_RealPerimeters/TWI/filled_breached_ChloyaLakes.tif",
          output = "YF_RealPerimeters/TWI/demslope_ChloyaLakes.tif",
          units = "degrees")

wbt_wetness_index(sca = "YF_RealPerimeters/TWI/flowaccumulation_ChloyaLakes.tif",
                  slope = "YF_RealPerimeters/TWI/demslope_ChloyaLakes.tif",
                  output = "YF_RealPerimeters/TWI/TWI_ChloyaLakes.tif")

TWI <- raster("YF_RealPerimeters/TWI/TWI_ChloyaLakes.tif")

tm_shape(TWI)+
  tm_raster(style = "cont",palette = "PuOr")

###############################Medicine Lake###################

dem <- raster("/Users/kmathes/Desktop/DATA/FABDEM/N60W150-N70W140_FABDEM_V1-2/N65W145_FABDEM_V1-2.tif", crs = '+init=EPSG:4326')

writeRaster(dem, "YF_RealPerimeters/TWI/dem_MedicineLake.tif", overwrite = TRUE) 

#an artifact of outputting the DEM for this analysis is that there are a bunch of errant cells around the border that don’t belong in the DEM. If we make a map with them, it really throws off the scale. So we are going to set any elevation values below 1500 ft to NA.
#this does not work!!!! The elevation is too low
#dem[dem < 1500] <- NA

##Plot DEM 

tm_shape(dem)+
  tm_raster(style = "cont", palette = "PuOr", legend.show = TRUE)+
  tm_scale_bar()


##Hillshade
wbt_hillshade(dem = "YF_RealPerimeters/TWI/dem_MedicineLake.tif",
              output = "YF_RealPerimeters/TWI/brush_hillshade_MedicineLake.tif",
              azimuth = 115)

hillshade <- raster("YF_RealPerimeters/TWI/brush_hillshade_MedicineLake.tif")


##Fill and breach depressions in prep for TWI derivation 
tm_shape(hillshade)+
  tm_raster(style = "cont",  palette = "-Greys",legend.show = FALSE)+
  tm_scale_bar()


wbt_breach_depressions_least_cost(
  dem = "YF_RealPerimeters/TWI/dem_MedicineLake.tif",
  output = "YF_RealPerimeters/TWI/breached_MedicineLake.tif",
  dist = 5,
  fill = TRUE)

wbt_fill_depressions_wang_and_liu(
  dem = "YF_RealPerimeters/TWI/breached_MedicineLake.tif",
  output = "YF_RealPerimeters/TWI/filled_breached_MedicineLake.tif"
)

filled_breached <- raster("YF_RealPerimeters/TWI/filled_breached_MedicineLake.tif")

## What did this do?

difference <- dem - filled_breached


difference[difference == 0] <- NA

tm_shape(hillshade)+
  tm_raster(style = "cont", palette = "-Greys", legend.show = FALSE)+
  
  tm_shape(difference)+
  tm_raster(style = "cont",legend.show = TRUE)


##D8 Flow accumulation 

wbt_d8_flow_accumulation(input = "YF_RealPerimeters/TWI/filled_breached_MedicineLake.tif",
                         output = "YF_RealPerimeters/TWI/flowaccumulation_MedicineLake.tif")

d8 <- raster("YF_RealPerimeters/TWI/flowaccumulation_MedicineLake.tif")

tm_shape(hillshade)+
  tm_raster(style = "cont",palette = "-Greys", legend.show = FALSE)+
  tm_shape(log(d8))+
  tm_raster(style = "cont", palette = "PuOr", legend.show = TRUE, alpha = .5)+
  tm_scale_bar()


##dinfinity flow accumulation 
wbt_d_inf_flow_accumulation("YF_RealPerimeters/TWI/filled_breached_MedicineLake.tif",
                            "YF_RealPerimeters/TWI/flowaccumulationdf_MedicineLake.tif", 
                            out_type = "Specific Contributing Area")

dinf <- raster("YF_RealPerimeters/TWI/flowaccumulationdf_MedicineLake.tif")



##TWI 
wbt_slope(dem = "YF_RealPerimeters/TWI/filled_breached_MedicineLake.tif",
          output = "YF_RealPerimeters/TWI/demslope_MedicineLake.tif",
          units = "degrees")

wbt_wetness_index(sca = "YF_RealPerimeters/TWI/flowaccumulation_MedicineLake.tif",
                  slope = "YF_RealPerimeters/TWI/demslope_MedicineLake.tif",
                  output = "YF_RealPerimeters/TWI/TWI_MedicineLake.tif")

TWI <- raster("YF_RealPerimeters/TWI/TWI_MedicineLake.tif")

tm_shape(TWI)+
  tm_raster(style = "cont",palette = "PuOr")
