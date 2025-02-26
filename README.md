# Combustion Model
<<<<<<< HEAD

Workflow to estimate above and belowground combustion for historical fires on yedoma in the boreal Alaska Interior that were suppressed with early action. 
Using this model to quantify both "real" combustion, combustion that occured before the fire was contained/controlled. 
And, using this model to quantify "avoided" combustion from the retrospective fire spreads that would have occured without suppression. 

This is a modified workflow for using Stefano Potter's machine learning model to predict above and belowground combustion from boreal wildfires. 
Workflow was modified from Anna Talucci's code. 






## Retraining 

This machine learning model needed to be retrained, because we could not use all the vegetation, fire severity parameters that are included in the orginial model. Additionally, we needed to use different TWI and FWI data, so the model 
needed to be retrained with those new topographic data sources. 

### Preparing the training dataset (Provided by Stefano Potter: using field data across NA boreal domain)
"Preparing_training_dataframe.R": This script eliminates the parameters we cannot measure with the hypothetical fire spreads (post-fire vegetation parameters). Then it adds the new TWI and FWI data. 

For preparing the TWI parameters for retraining dataset: 

  Step 1: R: TWI_Retraining.R: Create DEM and TWI tifs that overlay the region of the fire. 
  Step 2: GEE: https://code.earthengine.google.com/c6a3d9e28a571603977a83638e9f666f: Calculate the TWI parameters (Ruggedness, TWI, slope, aspect) for each fire burn point 

For preparing the FWI parameters for retraining dataset: 

  Step 1: Turn Day of burn (DOB_1st) into calendar data and upload a csv of all retraining datapoints with calendar date 
  Step 2: GEE: https://code.earthengine.google.com/cb24372bf20114cedb4e61ee4bfd5e53: Calculate the FWI variables for the training dataset. 

### Retraining: Stefano's training models 
"combustion_training_workflow_mathes.R": Runs random forest model on the retraining dataset, and creates the machine learning models for above and belowground combusiton prediction.  

   Model_Above: Above_full_model_ranger.rds
                  rfe_importance.csv
                  
   Model_Below: Below_full_model_ranger.rds
                  rfe_importance.csv           
        


=======

Workflow to estimate above and belowground combustion for historical fires on yedoma in the boreal Alaska Interior that were suppressed with early action. 
Using this model to quantify both "real" combustion, combustion that occured before the fire was contained/controlled. 
And, using this model to quantify "avoided" combustion from the retrospective fire spreads that would have occured without suppression. 

This is a modified workflow for using Stefano Potter's machine learning model to predict above and belowground combustion from boreal wildfires. 
Workflow was modified from Anna Talucci's code. 






## Retraining 

This machine learning model needed to be retrained, because we could not use all the vegetation, fire severity parameters that are included in the orginial model. Additionally, we needed to use different TWI and FWI data, so the model 
needed to be retrained with those new topographic data sources. 

### Preparing the training dataset (Provided by Stefano Potter: using field data across NA boreal domain)
"Preparing_training_dataframe.R": This script eliminates the parameters we cannot measure with the hypothetical fire spreads (post-fire vegetation parameters). Then it adds the new TWI and FWI data. 

For preparing the TWI parameters for retraining dataset: 

  Step 1: R: TWI_Retraining.R: Create DEM and TWI tifs that overlay the region of the fire. 
  Step 2: GEE: https://code.earthengine.google.com/c6a3d9e28a571603977a83638e9f666f: Calculate the TWI parameters (Ruggedness, TWI, slope, aspect) for each fire burn point 

For preparing the FWI parameters for retraining dataset: 

  Step 1: Turn Day of burn (DOB_1st) into calendar data and upload a csv of all retraining datapoints with calendar date 
  Step 2: GEE: https://code.earthengine.google.com/cb24372bf20114cedb4e61ee4bfd5e53: Calculate the FWI variables for the training dataset. 

### Retraining: Stefano's training models 
"combustion_training_workflow_mathes.R": Runs random forest model on the retraining dataset, and creates the machine learning models for above and belowground combusiton prediction.  

      Model_Above: Above_full_model_ranger.rds
                  rfe_importance.csv
                  
      Model_Below: Below_full_model_ranger.rds
                  rfe_importance.csv   
>>>>>>> eab6db33e17d5b16931fccf82c4c9113cce974b3
