#######################this script will translate my python setup to get variables and grid search combustion#####################
library(tidyverse)
library(caret)
library(doSNOW)
library(ranger)
library(parallel)
library(viridis)


#set a random seed, this is for reproducibility 
set.seed(170) 


#read in the training data (Get rid of all predictor variables that we cannot use)
df <- read_csv("Retraining/new_belowground_training_data.csv")

##Get rid of other ID variables that are unnecessary for the model training and the two climate variables that Stefano said to remove. 
###For above and belowground models remove the respectful NA values and then remove the other response variables 
df <- df%>%
  dplyr::select(!burn_year)%>%
  dplyr::select(!project.name)%>%
  dplyr::select(!latitude)%>%
  dplyr::select(!longitude)%>%
  dplyr::select(!Date)%>%
  dplyr::select(!CNA_MAR)%>%
  dplyr::select(!CNA_DD_0_5_8)%>%
  dplyr::select(!"system:index")%>%
  dplyr::select(!DOB_lst)%>%
  drop_na()

write.csv(df, "Retraining/new_belowground_data_training_fortraining.csv")


#shuffle the dataframe
df <- df[sample(1:nrow(df)), ]

#function to normalize if desired
normalized <- function(x) (x- min(x))/(max(x) - min(x))

#function to inverse normalize
inv_norm <- function(original, normalized) normalized*(max(original) - min(original)) + min(original)

#function for R2
rsq <- function (x, y) cor(x, y) ^ 2

#function for RMSE
RMSE = function(m, o){
  sqrt(mean((m - o)^2))
}

#get all model names in caret
modelnames <- paste(names(getModelInfo()), collapse = ', ')

#look up parameters which can be tuned
# modelLookup('xgbTree') #gradient boosted
# modelLookup('ranger') #ranger rf
# modelLookup('rf') #standard rf
# modelLookup('qrf') #quantile rf
# modelLookup('lasso') #lasso regression
# modelLookup('ridge') #ridge
# modelLookup('earth') #MARS
# modelLookup('bam') #GAM
# modelLookup('gamboost') #boosted GAM
# modelLookup('svmLinear2') #svm linear
# modelLookup('svmPoly') #svm poly
# modelLookup('svmRadial') #svm radial
# modelLookup('gam') #svm radial

# stopCluster(cl)

#a function to run all my comparisons
model_compare <- function(df, out_path){
  
  ##arguments are:
  #df = input dataframe which has only the x and y variables, very import y is the first column!!
  #out_path = output destination
  ##
  
  #set up cluster - requires doSNOW, and parallel packages, allows to use multiple cpus
  cores <- detectCores() - 2 #if you want to use your computer for things other than the model, subtract 1 or 2.
  cl <-makeCluster(cores)
  registerDoSNOW(cl)
  
  #create the outpath in case it doesn't exist
  dir.create(out_path, recursive = T)
  
  #an emptry list to store function output
  #item 1 is the tuned models, 2 is the names and 3 is the median R2 comparisons, 4 is all 10 cv 100 repeats and 5 is the plot
  for_output <- list()
  
  #this is unique ids for each row (for me they are field sample sites)
  ids <- df$id
  
  #don't model with id
  df <- df %>% dplyr::select(-id)
  
  #rename the first column (y) to y
  df <- df %>% dplyr::rename(y = names(df)[1])
  
  #function to normalize if desired
  # normalized <- function(x) (x- min(x))/(max(x) - min(x))
  
  #normaize the predictor variables 0-1
  df[, 2:length(colnames(df))] <- lapply(df[, 2:length(colnames(df))], normalized)
  
  
  #set up the recursive feature elimination, you can play with the functoins and methods,
  #in particular LOOCV was probably a better idea for me in hindsight, depends
  #on your data size. More info here, https://topepo.github.io/caret/recursive-feature-elimination.html
  
  set.seed(221)
  control <- rfeControl(functions = rfFuncs,
                        method = "repeatedcv",
                        repeats = 3,
                        verbose = FALSE,
                        allowParallel = T)
  
  #name of target
  outcomeName<- names(df)[1]
  
  #names of predictors
  predictors<-names(df)[!names(df) %in% outcomeName]
  
  #recursive feature elimination, the sizes is how many variables at once you will check
  pred_importance <- rfe(as.matrix(df[,predictors]), as.matrix(df[,outcomeName]),
                         rfeControl = control, sizes = c(1:10, 15, 20, 30, 40, 45, 48))
  
  #save the selected variables to a csv
  rfe_df = as_tibble(pred_importance$results)
  write_csv(rfe_df, file.path(out_path, "rfe.csv"))
  
  #plot it
  plot(pred_importance, type=c("g", "o"))
  
  #get optimal variables
  opt <- pred_importance$optVariables
  
  #add in the y 
  opt[[length(opt) + 1]] <- "y"
  
  #select the good variables
  df <- df %>% dplyr::select(opt)
  
  #put y as first column again
  df <- df %>% dplyr::select(y, everything())
  
  #use random forest to get feature importance
  control <- trainControl(method = 'repeatedcv', number = 10, repeats = 3)
  
  mod <- train(y~., data = df, method = 'rf', trControl = control, importance = T)
  
  importance <- varImp(mod, scale = F)
  plot(importance)
  
  #make a tibble of importance
  importance <- as.matrix(varImp(mod)$importance)
  importance <- data.frame(importance)
  importance <- as_tibble(tibble::rownames_to_column(importance, "Variables"))
  
  write_csv(importance, file.path(out_path, 'rfe_importance.csv'))
  
  
  #first lets get the best parameters for each model, here I am using RMSE to select them,
  #it is using a 10 fold CV repeated 3 times.
  set.seed(100)
  fitControl <- trainControl(method = "repeatedcv",
                             number = 10,
                             repeats = 3,
                             savePredictions = 'final',
                             index = createResample(df$y, 25),
                             allowParallel = T)
  
  #get the best model parameters with a random grid search
  # model_xgbtree <- train(y ~., data = df, method = 'xgbTree', tuneLength = 5, metric = 'RMSE', trControl = fitControl)
  model_ranger <- train(y ~., data = df, method = 'ranger', tuneLength = 10, metric = 'RMSE', trControl = fitControl)
  model_quantile <- train(y ~., data = df, method = 'qrf', tuneLength = 10, metric = 'RMSE', trControl = fitControl)
  model_lasso <- train(y ~., data = df, method = 'lasso', tuneLength = 10, metric = 'RMSE', trControl = fitControl)
  model_ridge <- train(y ~., data = df, method = 'ridge', tuneLength = 10, metric = 'RMSE', trControl = fitControl)
  # model_gam <- train(y ~., data = df, method = 'bam',  tuneLength = 4, metric = 'RMSE', trControl = fitControl)
  model_svmlinear <- train(y ~., data = df, method = 'svmLinear2', tuneLength = 5, metric = 'RMSE', trControl = fitControl)
  model_svmpoly <- train(y~., data = df, method = 'svmPoly', tuneLength = 5, metric = 'RMSE', trControl = fitControl)
  model_svmradial <- train(y ~., data = df, method = 'svmRadial', tuneLength = 5, metric = 'RMSE', trControl = fitControl)
  
  #save a list of tuned model comparisons
  pre_final <- list(model_ranger, model_quantile, model_lasso, model_ridge,
                    model_svmlinear, 
                    model_svmpoly, model_svmradial)
  
  for_output[1] <- pre_final
  
  #get estimated model performance with a 10 fold cv repeated 100 times,
  #really you might just using LOOCV again though if the data is small
  set.seed(201)
  
  fitControl <- trainControl(method = "repeatedcv",
                             number = 10,
                             repeats = 100,
                             savePredictions = 'final',  
                             allowParallel = T)
  
  #use the best parameters for each model to see how well it is performing
  # model_xgbtree_final <- train(y ~., data = df, method = 'xgbTree', tuneGrid=data.frame(.nrounds = model_xgbtree_final$bestTune$nrounds, 
  #                                                                                       .max_depth = model_xgbtree_final$bestTune$max_depth,
  #                                                                                       .eta = model_xgbtree_final$bestTune$eta,
  #                                                                                       .gamma = model_xgbtree_final$bestTune$gamma,
  #                                                                                       .colsample_bytree = model_xgbtree_final$bestTune$colsample_bytree,
  #                                                                                       .min_child_weight = model_xgbtree_final$bestTune$min_child_weight,
  #                                                                                       .subsample, model_xgbtree_final$bestTune$subsample), trControl = fitControl)
  
  model_ranger_final <- train(y ~., data = df, method = 'ranger', tuneGrid=data.frame(.mtry = model_ranger$bestTune$mtry, .splitrule = model_ranger$bestTune$splitrule, .min.node.size = model_ranger$bestTune$min.node.size), trControl = fitControl)
  model_quantile_final <- train(y ~., data = df, method = 'qrf', tuneGrid=data.frame(.mtry = model_quantile$bestTune$mtry), trControl = fitControl)
  model_lasso_final <- train(y ~., data = df, method = 'lasso', tuneGrid=data.frame(.fraction = model_lasso$bestTune$fraction), trControl = fitControl)
  model_ridge_final <- train(y ~., data = df, method = 'ridge', tuneGrid=data.frame(.lambda = model_ridge$bestTune$lambda), trControl = fitControl)
  # model_gam_final <- train(y ~., data = df, method = 'gamboost', tuneGrid=data.frame(.mstop = 450, .prune = 'no'), trControl = fitControl)
  model_svmlinear_final <- train(y ~., data = df, method = 'svmLinear2', tuneGrid=data.frame(.cost = model_svmlinear$bestTune$cost), trControl = fitControl)
  model_svmpoly_final <- train(y~., data = df, method = 'svmPoly', tuneGrid=data.frame(.degree= model_svmpoly$bestTune$degree, .scale = model_svmpoly$bestTune$scale, .C = model_svmpoly$bestTune$C), trControl = fitControl)
  model_svmradial_final <- train(y ~., data = df, method = 'svmRadial', tuneGrid=data.frame(.sigma = model_svmradial$bestTune$sigma, .C = model_svmradial$bestTune$C), trControl = fitControl)
  
  #save all the models to a list
  all_final <- list(model_ranger_final, model_quantile_final, model_lasso_final, model_ridge_final,
                    model_svmlinear_final, 
                    model_svmpoly_final, model_svmradial_final)
  
  #a list of corresponsing names
  all_names <- list('ranger', 'quantile', 'lasso', 'ridge', 'svmlinear', 'svmpoly', 'svmradial')

  #save a heat map of all observed vs predicted svm radial and ranger
  compare_radial <- as_tibble(model_svmradial_final$pred)
  compare_radial <- compare_radial %>% mutate(Resids = obs - pred)
  
  compare_ranger <- as_tibble(model_ranger_final$pred)
  compare_ranger <- compare_ranger %>% mutate(Resids = obs - pred)
  
  # Get density of points in 2 dimensions.
  # @param x A numeric vector.
  # @param y A numeric vector.
  # @param n Create a square n by n grid to compute density.
  # @return The density within each square.
  get_density <- function(x, y, ...) {
    dens <- MASS::kde2d(x, y, ...)
    ix <- findInterval(x, dens$x)
    iy <- findInterval(y, dens$y)
    ii <- cbind(ix, iy)
    return(dens$z[ii])
  }
  
  #get density
  compare_radial$density <- get_density(compare_radial$obs, compare_radial$pred, n = 100)
  compare_ranger$density <- get_density(compare_ranger$obs, compare_ranger$pred, n = 100)
  
  #get density of residuals
  compare_radial$density2 <- get_density(compare_radial$obs, compare_radial$Resids, n = 100)
  compare_ranger$density2 <- get_density(compare_ranger$obs, compare_ranger$Resids, n = 100)
  
  #break into three bins
  quantiles = quantile(compare_ranger$obs, probs = c(0.90)) #0.83 for above
  compare_ranger = compare_ranger %>% mutate(quantile = ifelse(obs < quantiles, 1, 2))
  
  #get the mean residual
  mean_resids = compare_ranger %>% group_by(quantile) %>% summarize(Resids = mean(Resids))
  
  #get the mean observation
  mean_obs = compare_ranger %>% group_by(quantile) %>% summarize(obs = mean(obs))
  
  #join
  for_plot = left_join(mean_obs, mean_resids) 
  for_plot = for_plot %>% mutate(Diff = abs(Resids / obs) * 100) 
  
  #calculate percent
  
   #save the ranger plot
   p <- ggplot(compare_ranger)  +
    geom_point(aes(obs, pred, color = density)) + scale_color_viridis() +
    labs(x = Observed ~ (kg ~C/m^2), y = Predicted ~ (kg ~C/m^2)) +  
    xlim(0, 3) + ylim(0, 3) +
    geom_abline(intercept = 0, slope = 1, color = 'red', linetype = 'dashed', size = 0.6) +
    theme_bw() +
    theme(text=element_text(size=18)) 
    ggsave(p, filename = file.path(out_path,  'ranger_heat_map.png'), device = 'png', dpi = 150, width = 10, height = 10)
  
   #save the svm plot
   p2 <- ggplot(compare_radial)  +
     geom_point(aes(obs, pred, color = density)) + scale_color_viridis() +
     labs(x = Observed ~ (kg ~C/m^2), y = Predicted ~ (kg ~C/m^2)) +  
     xlim(0, 3) + ylim(0, 3) + 
     geom_abline(intercept = 0, slope = 1, color = 'red', linetype = 'dashed', size = 0.6) +
     theme_bw() +
     theme(text=element_text(size=18)) 
     ggsave(p2, filename = file.path(out_path,  'svm_heat_map.png'), device = 'png', dpi = 150, width = 10, height = 10)
 
   #save the residual plots
   p3 <- ggplot(compare_ranger)  +
     geom_point(aes(pred, Resids, color = density2)) + scale_color_viridis() +
     labs(x = Predicted ~ (kg ~C/m^2), y = Residual ~ (kg ~C/m^2)) +  
     theme_bw() +
     theme(text=element_text(size=18)) 
     ggsave(p3, filename = file.path(out_path,  'ranger_residuals.png'), device = 'png', dpi = 150, width = 10, height = 10)
   
   
   p4 <- ggplot(compare_radial)  +
     geom_point(aes(pred, Resids, color = density2)) + scale_color_viridis() +
     labs(x = Predicted ~ (kg ~C/m^2), y = Residual ~ (kg ~C/m^2)) +  
     theme_bw() +
     theme(text=element_text(size=18)) 
     ggsave(p4, filename = file.path(out_path,  'svm_residuals.png'), device = 'png', dpi = 150, width = 10, height = 10)
   
  #---get the vectors of all predictions as one df
  final_df <- list()
  
  for (model in 1:length(all_final)){
    in_model <- all_final[[model]]
    in_name <- all_names[[model]]
    
    final <- tibble(Model = in_name,
                    Values = in_model$resample$Rsquared)
    
    final_df[[length(final_df) + 1]] <- final
  }
  final_df = bind_rows(final_df)
  
  #rearange high to low
  order <- final_df %>% drop_na() %>% group_by(Model) %>% dplyr::summarize(Value = median(Values)) %>% arrange(desc(Value))
  
  order <- order %>% mutate(Model = as.factor(Model))
  
  #order the levels by descending R2 values
  order$Model <- reorder(order$Model, order$Value)
  levels <- levels(order$Model)
  
  # final_df <- final_df %>% mutate(Model = as.factor(Model)) 
  final_df <- final_df %>% mutate(Model = factor(Model, levels = levels))

  #save the final csv
  write_csv(final_df, file.path(out_path, 'repeated_cv.csv'))
  write_csv(order, file.path(out_path, 'median_r2_compare.csv'))
  
  #save the box and violin plot
  dodge <- position_dodge(width = 0.8)
  p <- ggplot(final_df, aes(Model, Values)) +
    # scale_color_brewer(palette = 'Set2') +
    # scale_color_manual(values = c('gray', 'gray', 'gray', 'gray', 'gray'))+
    geom_violin(position = dodge, fill = '#A4A4A4') +
    geom_boxplot(width=.15, outlier.colour=NA, position = dodge) +
    coord_flip() +
    theme_classic() +
    xlab('') + ylab(expression(R^{2})) +
    theme(legend.position="none") +
    theme(text=element_text(size=24)) 
    ggsave(p, filename = file.path(out_path, 'violin_plot.png'), device = 'png', dpi = 150, width = 10, height = 10)
  
  final_ranger <- train(y ~., data = df, method = 'ranger', tuneGrid=data.frame(.mtry = model_ranger$bestTune$mtry, .splitrule = model_ranger$bestTune$splitrule, .min.node.size = model_ranger$bestTune$min.node.size))
  final_svm <- train(y ~., data = df, method = 'svmRadial', tuneGrid=data.frame(.sigma = model_svmradial$bestTune$sigma, .C = model_svmradial$bestTune$C))

  
  saveRDS(final_ranger, file=file.path(out_path, 'full_model_ranger.rds'))
  saveRDS(final_svm, file=file.path(out_path, 'full_model_svmradial.rds'))
  
  #get full model predictions and rsq
  all_ranger_predicteds <- predict(final_ranger, newdata=df %>% select(-y))
  all_svm_predicteds <- predict(final_svm, newdata=df %>% select(-y))
  
  full_ranger_rsq = rsq(df$y, all_ranger_predicteds)
  full_svm_rsq = rsq(df$y, all_svm_predicteds)
  
  #get obs and preds
  ranger_compare <- tibble(Obs = df$y, 
                    Pred = all_ranger_predicteds,
                    id = ids)
  svm_compare <- tibble(Obs = df$y, 
                           Pred = all_svm_predicteds,
                        id = ids)
  
  write_csv(ranger_compare, file.path(out_path,  'ranger_full_model_ob_pred.csv'))
  #plot the full model
  p <- ggplot(ranger_compare, aes(x = Obs, y =  Pred)) + 
    geom_point() +
    labs(x = Observed ~ (kg ~C/m^2), y = Predicted ~ (kg ~C/m^2)) +  
    xlim(0, limit) + ylim(0, limit) + 
    geom_abline(intercept = 0, slope = 1, color = 'red', linetype = 'dashed', size = 0.6) +
    theme_bw() +
    theme(text=element_text(size=18)) 
    ggsave(pm, filename = file.path(out_path, 'ranger_full_model_ob_pred.png'), device = 'png', dpi = 150, width = 10, height = 10)
  
  p2 <- ggplot(svm_compare, aes(x = Obs, y =  Pred)) + 
    geom_point() +
    labs(x = Observed ~ (kg ~C/m^2), y = Predicted ~ (kg ~C/m^2)) +  
    xlim(0, limit) + ylim(0, limit) + 
    geom_abline(intercept = 0, slope = 1, color = 'red', linetype = 'dashed', size = 0.6) +
    theme_bw() +
    theme(text=element_text(size=18)) 
    ggsave(p2, filename = file.path(out_path,  'svm_full_model_ob_pred.png'), device = 'png', dpi = 150, width = 10, height = 10)
  

  #stop the cluster
  stopCluster(cl)
  
  #return the output
  return(for_output)
}

result <- model_compare(df = df, out_path = "Retraining/out_path_below_adjusted3")





