# Combustion Model Workflow

## Overview 
Workflow to estimate above and belowground combustion for historical fires on yedoma in the boreal Alaska Interior that were suppressed with early action. 
We are leveraging this model to quantify both "real" combustion, combustion that occured before the fire was contained/controlled and 
 to quantify "avoided" combustion from the retrospective fire spreads that would have occured without suppression. 

This is a modified workflow for using Stefano Potter's machine learning model (Potter et al. 2023) to predict above and belowground combustion from boreal wildfires. 
Workflow was modified from Anna Talucci's code. 


## Gathering data layers and running combustion model 

Scripts and workflow for the counterfactual fire perimeters for historical fire dataset of 30 fires in interior Alaska. Using FSPRO, we modeled how large each of these fires would have gotten had suppression action not occured. 

### Step 01 
R script: “OrganizeShpData_MathesYFFires.Rmd”: 
Organize the shapefile data. Find the point data for the fires in the subdataset from the Alaska Large dataset Point shapefile (Fires in the dataset are not included in the polygon data). Create a burned area “polygon”: A circle buffer around the point equal to the size of the total burned area ( in m2). Save as the YFFiresPerimeter.shp series in Output file. 

Input file: Alaska large fire dataset (point shapefile)

Output file: YFFiresPerimeters shapefile (polygons of buffer zone around the fire point that is the size of the burned area)

### Step 02: LandsatForPoints
EE: https://code.earthengine.google.com/9498dd63d6a672e9b994af5d0eb3c51b
Landsat Image for points: extract tiff files of the centroid of the pixels for each fire. Tif file for each fires. Download the images as Step02 firename.tif in output file .

Input: Fire perimeter (Full extent of countefactual fire perimeters for each fire) (Output from step 1)

Output: tif files of pixel centroid 

### Step 03: 
R script: “RasterToPointsCounterfactual.Rmd”. 
Upload the rasters from the tif files created in step 2 and create the “BurnPoint" shp file for each fire


Input: Counterfactual Perimeters (Output from step 1) + tifs of burn pixels (output from step 2)

Output: Burnpoint shapefiles (shapefile of the centroid of the pixel for each fire) 

### Step 04: [WILL DELETE THIS]
R script: "DayofBurn_YFFires.Rmd": 
Create a day of burn shapefile by combining the burn point datafile with the manual day of burn csvs for each fire: Output: DayofBurn.shp series.  

Input: burnpoints.shp (output of step 3) + all the ManualDoB csv (output of step 3)

Output: DayofBurn shapefile 

### Step 04: 
EE:  https://code.earthengine.google.com/3f674b674b1a2c0215c83f0b4555c8b7
extract average FWI data for all the days of burn for each fire. Download the csv files into the Step 4 folder. 

Input: Burnpoint shapefile (output from step 3)

Output: FWI csv files for each fire 


### Step 06: 
GEE script: “Step06_StaticVegetation”: https://code.earthengine.google.com/6142989d303d29308590bfc84a66528b
Extract the landcover parameters for each fire. Download the csv file in Step 06. 

Input: Fire perimeter shapefile (output from step 1) + burnpoint shapefile (output from step 3)

Output: Static vegetation csv files 

### Step 07: 
GEE script: “TreeCoverExtract”: https://code.earthengine.google.com/d4e5cefbdf5bfb9f85439bc32915f8b9
Extract the tree cover percentage for each fire. Download the csv files in Step 07. 

Input: Fire perimeter shapefile (output from step 1) + burnpoint shapefile (output from step 3)

Output: Treecover extract csv files 

### Step 08: 
First: R script: “TWI_input.R” 
Calculate the TWI tif from the DEM files associated with each fire. Import these TWI tif files into GEE. 

Input: DEM tiles (From the FABDEM data downloads) + fire perimeters (Output from Step 1)

Output: TWI images for each fire 

Second: GEE “StaticTerrain: https://code.earthengine.google.com/3d6ff1205850b40b13972d33b874a5ca
Calculate the DEM, TWI, slope and aspect for each fire. Download the csv for each fire in Step 8. 

Input: TWI images for each fire (Input from step 8a) + Fire perimeter shapefile (output from step 1) + burnpoint shapefile (output from step 3)

Output: TWI csv files 

### Step 09: 
GEE script: “Static soil": https://code.earthengine.google.com/f03c3612dd1811b70fa1eba610d31267
Extract the soil parameters for each fire. Download the csv file in Step 09. 

Input: Fire perimeter shapefile (output from step 1) + burnpoint shapefile (output from step 3)

Output: static soil csv files 

### Step 10: 
GEE script: “PFI Static soil":https://code.earthengine.google.com/57e0658fcc4c6676408463aca86b87d6
Extract the PFI for soil parameters for each fire. Download the csv file in Step 10.

Input: Fire perimeter shapefile (output from step 1) + burnpoint shapefile (output from step 3)

Output: PFI Static soil csv files 

### Step 11: 
GEE: Climate_NA: https://code.earthengine.google.com/599ad1a227383cd055c1a3ae7e59c8ff
Climate NA data extract. Saved in the Climate NA output file. 

Input: Fire perimeter shapefile (output from step 1) + burnpoint shapefile (output from step 3)

Output: Climate NA csv files 

### Step 12: 
R script: "Step12_CombineData4CombustModel_MathesYFFires.Rmd"
combine all the parameters for the combustion model 

Input: Output from step 5 - 11

Output: combined dataset with all parameters csv 

### Step 13: 
R Script: "Step13_CombustionModel_MathesYFFires.Rmd"
run the combustion model on the retrained data! (See retraining steps below on how the model was retrained )

Input: Output from step 12

Output: above and belowground combustion prediction 

### Step 14: 


## Retraining 

This machine learning model needed to be retrained, because we could not us any of the post-fire paramters that were included in the original model. Additionally, we needed to use different TWI and FWI data, so the model needed to be retrained with those new topographic data sources. 

### Preparing the training dataset (Provided by Stefano Potter: using field data across NA boreal domain)
"Preparing_training_dataframe.R": This script eliminates the parameters we cannot measure with the hypothetical fire spreads (post-fire vegetation parameters). Then it adds the new TWI and FWI data. 

For preparing the TWI parameters for retraining dataset: 

  Step 1: R: TWI_Retraining.R: Create DEM and TWI tifs that overlay the region of the fire. 
  Step 2: GEE: https://code.earthengine.google.com/c6a3d9e28a571603977a83638e9f666f: Calculate the TWI parameters (Ruggedness, TWI, slope, aspect) for each fire burn point 

For preparing the FWI parameters for retraining dataset: 

  Step 1: Turn Day of burn (DOB_1st) into calendar date and upload a csv of all retraining datapoints with calendar date 
  Step 2: GEE: https://code.earthengine.google.com/cb24372bf20114cedb4e61ee4bfd5e53: Calculate the FWI variables for the training dataset. 

### Retraining: Stefano's training models 
"combustion_training_workflow_mathes.R": Runs random forest model on the retraining dataset, and creates the machine learning models for above and belowground combusiton prediction.  

Model_Above: Above_full_model_ranger.rds
                  rfe_importance.csv
                  
Model_Below: Below_full_model_ranger.rds
                  rfe_importance.csv           



