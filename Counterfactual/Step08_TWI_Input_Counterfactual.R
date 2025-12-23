#Code and comments taken from:https://vt-bioinformatics.github.io/rgeoraster.html
library(tidyverse)
library(raster)
library(sf)
library(whitebox)
library(tmap)

DEM_tiles  = st_read("/Users/kmathes/Desktop/Combustion Model/FABDEM_v1-2_tiles.geojson")%>%
  st_transform(crs = 3338)

FirePerimeter = st_read("/Users/kmathes/Desktop/Combustion Model/Counterfactual/Output/2007_MartenCreek/Perimeter_MartenCreek.shp")%>%
  st_transform(crs = 3338)


##Find overlaping DEM tiles with the fire points datafile 
Tile_intersection <- st_intersection(DEM_tiles, FirePerimeter)

cat(paste0(sprintf("'%s'", length(unique(Tile_intersection$tile_name)))))

##Set some themes 
#theme_set(theme_classic())
tmap_mode("view")

##download tile looking at arcGIS tile map, finding the tile(s) that overlap with individual fire perimeters. 
#https://woodwell.maps.arcgis.com/apps/mapviewer/index.html?webmap=b6e979647429461c992c789226b5622b
##load in DEM raster


 
############################ TWI Calculation ###################

dem <- raster("/Users/kmathes/Desktop/DATA/N67W145_FABDEM_V1-2.tif", crs = '+init=EPSG:4326')

writeRaster(dem, "Counterfactual/Output/TWI_Input/dem.tif", overwrite = TRUE) 

#an artifact of outputting the DEM for this analysis is that there are a bunch of errant cells around the border that don’t belong in the DEM. If we make a map with them, it really throws off the scale. So we are going to set any elevation values below 1500 ft to NA.
#this does not work!!!! The elevation is too low
#dem[dem < 1500] <- NA

##Plot DEM 

tm_shape(dem)+
  tm_raster(style = "cont", palette = "PuOr", legend.show = TRUE)+
  tm_scale_bar()


##Hillshade
wbt_hillshade(dem = "Counterfactual/Output/TWI_Input/dem.tif",
              output = "Counterfactual/Output/TWI_Input/brush_hillshade.tif",
              azimuth = 115)

hillshade <- raster("Counterfactual/Output/TWI_Input/brush_hillshade.tif")


##Fill and breach depressions in prep for TWI derivation 
tm_shape(hillshade)+
  tm_raster(style = "cont",  palette = "-Greys",legend.show = FALSE)+
  tm_scale_bar()


wbt_breach_depressions_least_cost(
  dem = "Counterfactual/Output/TWI_Input/dem.tif",
  output = "Counterfactual/Output/TWI_Input/breached.tif",
  dist = 5,
  fill = TRUE)

wbt_fill_depressions_wang_and_liu(
  dem = "Counterfactual/Output/TWI_Input/breached.tif",
  output = "Counterfactual/Output/TWI_Input/filled_breached.tif"
)

filled_breached <- raster("Counterfactual/Output/TWI_Input/filled_breached.tif")

## What did this do?

difference <- dem - filled_breached


difference[difference == 0] <- NA

tm_shape(hillshade)+
  tm_raster(style = "cont", palette = "-Greys", legend.show = FALSE)+
  
  tm_shape(difference)+
  tm_raster(style = "cont",legend.show = TRUE)


##D8 Flow accumulation 

wbt_d8_flow_accumulation(input = "Counterfactual/Output/TWI_Input/filled_breached.tif",
                         output = "Counterfactual/Output/TWI_Input/flowaccumulation.tif")

d8 <- raster("Counterfactual/Output/TWI_Input/flowaccumulation.tif")

tm_shape(hillshade)+
  tm_raster(style = "cont",palette = "-Greys", legend.show = FALSE)+
  tm_shape(log(d8))+
  tm_raster(style = "cont", palette = "PuOr", legend.show = TRUE, alpha = .5)+
  tm_scale_bar()


##dinfinity flow accumulation 
wbt_d_inf_flow_accumulation("Counterfactual/Output/TWI_Input/filled_breached.tif",
                            "Counterfactual/Output/TWI_Input/flowaccumulationdf.tif", 
                            out_type = "Specific Contributing Area")

dinf <- raster("Counterfactual/Output/TWI_Input/flowaccumulationdf.tif")



##TWI 
wbt_slope(dem = "Counterfactual/Output/TWI_Input/filled_breached.tif",
          output = "Counterfactual/Output/TWI_Input/demslope.tif",
          units = "degrees")

wbt_wetness_index(sca = "Counterfactual/Output/TWI_Input/flowaccumulation.tif",
                  slope = "Counterfactual/Output/TWI_Input/demslope.tif",
                  output = "Counterfactual/Output/TWI_Input/TWI_N67W145.tif")

TWI <- raster("Counterfactual/Output/TWI_Input/TWI_N67W145.tif")

tm_shape(TWI)+
  tm_raster(style = "cont",palette = "PuOr")

writeRaster(dem, "Counterfactual/Output/TWI_Input/dem_N66W144.tif", overwrite = TRUE) 
