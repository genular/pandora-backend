#* Plot out data from the iris dataset
#* @serializer contentType list(type='image/png')
#' @GET /plots/modelsummary/render-plot
pandora$handle$plots$modelsummary$renderPlot$multiClass <- expression(
    function(req, res, ...){
        args <- as.list(match.call())

        res.data <- list(training = list(), testing = list())


        resampleID <- 0
        if("resampleID" %in% names(args)){
            resampleID <- as.numeric(args$resampleID)
        }
        modelsIDs <- NULL
        if("modelsIDs" %in% names(args)){
            modelsIDs <- jsonlite::fromJSON(args$modelsIDs)
        }

       settings <- NULL
        if("settings" %in% names(args)){
            settings <- jsonlite::fromJSON(args$settings)
        }
        
        if(is_var_empty(settings$theme) == TRUE){
            settings$theme <- "theme_gray"
        }

        if(is_var_empty(settings$colorPalette) == TRUE){
            settings$colorPalette <- "Set1"
        }
        
        if(is_var_empty(settings$fontSize) == TRUE){
            settings$fontSize <- 12
        }

        if(is_var_empty(settings$pointSize) == TRUE){
            settings$pointSize <- 0.5
        }

        if(is_var_empty(settings$labelSize) == TRUE){
            settings$labelSize <- 3.88
        }

        if(is_var_empty(settings$aspect_ratio) == TRUE){
            settings$aspect_ratio <- 1
        }

        if(is_var_empty(settings$plot_size) == TRUE){
            settings$plot_size <- 12
        }

        plot_unique_hash <- list(
            training = list(
                auc_roc = list(),
                auc_roc_multiclass = list()
            ),
            ## ROC for Testing predictions on out leave out data
            testing = list(
                auc_roc = list(),
                auc_roc_multiclass = list()
            ),
            saveObjectHash = digest::digest(paste0(resampleID, "_",args$settings,"_exploration_modelsummary"), algo="md5", serialize=F)
        )

        ## 1st - Get all saved models for selected IDs
        modelsDetails <- db.apps.getModelsDetailsData(modelsIDs)

        testingPredictions <- NULL

        for(i in 1:nrow(modelsDetails)) {
            model <- modelsDetails[i,]
            modelPath <- downloadDataset(model$remotePathMain)
            if(modelPath == FALSE){
                return (list(success = FALSE, message = "Remote download error. Cannot locate and load model file."))
            } 
            modelData <- loadRObject(modelPath)

            if (modelData$training$raw$status == TRUE) {
                method <- modelData$training$raw$data$method

                modelDataExists <- safe_access(modelData, "predictions", "AUROC", "Multiclass", "ROC", "rocs")

                if(modelDataExists) {

                    class_mapping <- setNames(modelData$info$outcome_mapping$class_original, modelData$info$outcome_mapping$class_remapped)
                    observed <- modelData$training$raw$data$pred$obs
                    classes <- unique(observed)

                    ## TESTING ROC (PLOT 1):
                    ## Extended One-vs-All Comparisons | MULTI

                    roc_objs <- modelData$predictions$AUROC$Multiclass$ROC$rocs
                    auc_value <- NA

                    modelDataExists <- safe_access(modelData, "predictions", "AUROC", "Multiclass", "AUC")
                    if(modelDataExists) {
                        auc_value <- as.numeric(modelData$predictions$AUROC$Multiclass$AUC)
                    }

                    roc_data <- lapply(names(roc_objs), function(class_comp) {
                        roc_item <- roc_objs[[class_comp]][[1]]

                        # Check if roc_item is correctly structured and contains the data
                        if(is.list(roc_item) && "specificities" %in% names(roc_item) && "sensitivities" %in% names(roc_item)) {
                            data.frame(
                                FPR = 1 - roc_item$specificities,
                                TPR = roc_item$sensitivities,
                                Thresholds = roc_item$thresholds,
                                Class = class_comp  # Use the class comparison label directly
                            )
                        } else {
                            NULL  # Return NULL if the structure is not as expected
                        }
                    })

                    # Filter out NULL elements if any incorrect structure was encountered
                    roc_data <- Filter(Negate(is.null), roc_data)
                    # Combine all ROC data into a single data frame
                    roc_data_df <- do.call(rbind, roc_data)

                    # Update the Class column in roc_data_df
                    roc_data_df$Class <- sapply(roc_data_df$Class, update_class_labels, class_mapping)

                    plot_unique_hash[["testing"]]$auc_roc_multiclass[[method]] <- digest::digest(paste0(resampleID, "_",args$settings,"_testing_auc_roc_multiclass_", method), algo="md5", serialize=F)
                    tmp_path <- plot_auc_roc_multiclass_testing(roc_data_df, auc_value, settings, plot_unique_hash[["testing"]]$auc_roc_multiclass[[method]])

                    res.data$testing$auc_roc_multiclass[[method]] <- optimizeSVGFile(tmp_path)
                    res.data$testing$auc_roc_multiclass_png[[method]] <- convertSVGtoPNG(tmp_path)

                    ## TESTING ROC (PLOT 2):
                    ## One-vs-All Strategy | SINGLE
                    
                    # Initialize an empty dataframe to store ROC data
                    roc_data_df <- data.frame(FPR = numeric(), TPR = numeric(), Thresholds = numeric(), Class = factor(), AUC = numeric())

                    # Loop over each class in the AUROC list, assuming each class has its separate ROC data
                    for(class_name in names(modelData$predictions$AUROC)) {
                        if(class_name == "Multiclass") {
                            next
                        }
                        # Access the ROC object and AUC value for each class
                        roc_obj <- modelData$predictions$AUROC[[class_name]]$ROC
                        auc_value <- as.numeric(modelData$predictions$AUROC[[class_name]]$AUC)
                        
                        # Check if the roc_obj is correctly structured and contains the data
                        if(is.list(roc_obj) && "specificities" %in% names(roc_obj) && "sensitivities" %in% names(roc_obj)) {
                            tmp_data <- data.frame(
                                FPR = 1 - roc_obj$specificities,
                                TPR = roc_obj$sensitivities,
                                Thresholds = roc_obj$thresholds,
                                Class = class_name,  # Use the class name directly
                                AUC = rep(auc_value, length(roc_obj$specificities))  # Repeat AUC value for length of the specifics
                            )
                            # Bind this temporary data frame to the main ROC data frame
                            roc_data_df <- rbind(roc_data_df, tmp_data)
                        }
                    }

                    # Ensure Class and AUC columns are properly formatted
                    roc_data_df$Class <- factor(roc_data_df$Class)
                    roc_data_df$AUC <- as.numeric(roc_data_df$AUC)

                    # Calculate the average AUC for each class
                    average_auc_per_class <- aggregate(AUC ~ Class, data = roc_data_df, FUN = mean)

                    # Create labels in the format "Class: AUC"
                    auc_labels <- sprintf("%s - (%.2f)", average_auc_per_class$Class, average_auc_per_class$AUC)

                    # Optionally, you can name the labels by their class for easier referencing in plots
                    names(auc_labels) <- average_auc_per_class$Class

                    plot_unique_hash[["testing"]]$auc_roc[[method]] <- digest::digest(paste0(resampleID, "_",args$settings,"_testing_auc_roc_", method), algo="md5", serialize=F)
                    tmp_path <- plot_auc_roc_multiclass_testing_single(roc_data_df, auc_labels, settings, plot_unique_hash[["testing"]]$auc_roc[[method]])

                    res.data$testing$auc_roc[[method]] <- optimizeSVGFile(tmp_path)
                    res.data$testing$auc_roc_png[[method]] <- convertSVGtoPNG(tmp_path)


                    ## TRAINIG ROC (PLOT 1):
                    ## One-vs-All Strategy | SINGLE
                    roc_list <- list()

                    for (class in classes) {
                        binary_observed <- ifelse(observed == class, 1, 0)
                        
                        # Compute ROC curve using pROC
                        roc_obj <- pROC::roc(binary_observed, modelData$training$raw$data$pred[[class]])
                        
                        # Store ROC object for later use
                        roc_list[[class]] <- roc_obj
                    }
                    # Initialize an empty data frame for ROC data
                    roc_data <- data.frame(FPR = numeric(), TPR = numeric(), Class = factor(), Thresholds = numeric())

                    # Extract and bind data for each class
                    for (class in names(roc_list)) {
                        roc_item <- roc_list[[class]]
                        # Create a temporary data frame with ROC data for the current class
                        tmp_data <- data.frame(
                            FPR = 1 - roc_item$specificities,
                            TPR = roc_item$sensitivities,
                            Thresholds = roc_item$thresholds,
                            Class = class  # Use the class comparison label directly
                        )
                        # Bind this temporary data frame to the main ROC data frame
                        roc_data <- rbind(roc_data, tmp_data)
                    }
                    # Calculating AUC for each class and storing it in a named vector for easy access
                    auc_values <- sapply(roc_list, function(roc_obj) {
                       as.numeric(pROC::auc(roc_obj))
                    })
                    names(auc_values) <- names(roc_list)

                    roc_data$Class <- class_mapping[roc_data$Class]
                    names(auc_values) <- class_mapping[names(auc_values)]
                    auc_labels <- sprintf("%s - (%.2f)", names(auc_values), auc_values)

                    plot_unique_hash[["training"]]$auc_roc[[method]] <- digest::digest(paste0(resampleID, "_",args$settings,"_training_auc_roc_", method), algo="md5", serialize=F)
                    tmp_path <- plot_auc_roc_multiclass_training_single(roc_data, auc_labels, settings, plot_unique_hash[["training"]]$auc_roc[[method]])

                    res.data$training$auc_roc[[method]] <- optimizeSVGFile(tmp_path)
                    res.data$training$auc_roc_png[[method]] <- convertSVGtoPNG(tmp_path)


                    ## TRAINIG ROC (PLOT 2):
                    ## Extended One-vs-All Comparisons | MULTI
                    
                    # Initialize an empty data frame for ROC data
                    roc_data_df <- data.frame(FPR = numeric(), TPR = numeric(), Class = factor(), Comparison = factor(), Thresholds = numeric())
                    auc_values <- list()  # Use a list to store AUC values for easier handling

                    # Loop through each class and compute ROC against each other class
                    for (primary_class in classes) {
                        for (comparison_class in classes) {
                            if (primary_class != comparison_class) {
                                binary_observed <- ifelse(observed == primary_class, 1, 0)
                                binary_predicted <- modelData$training$raw$data$pred[[comparison_class]]
                                
                                # Compute ROC curve using pROC
                                roc_obj <- pROC::roc(binary_observed, binary_predicted)
                                
                                # Create a temporary data frame with ROC data
                                tmp_data <- data.frame(
                                    FPR = 1 - roc_obj$specificities,
                                    TPR = roc_obj$sensitivities,
                                    Thresholds = roc_obj$thresholds,
                                    Class = class_mapping[primary_class],
                                    Comparison = class_mapping[comparison_class]  # New field for comparison class
                                )
                                
                                # Bind this temporary data frame to the main ROC data frame
                                roc_data_df <- rbind(roc_data_df, tmp_data)
                                
                                # Store AUC value in the list with an appropriate label
                                auc_values[[paste(class_mapping[primary_class], "vs", class_mapping[comparison_class])]] <- auc(roc_obj)
                            }
                        }
                    }

                    # Assuming 'Class' and 'Comparison' are already in the desired format but need pairing
                    roc_data_df$Comparison <- with(roc_data_df, paste(Class, "vs", Comparison))

                    # Now adjust the creation of AUC labels to match this new pairing format
                    auc_labels <- sapply(names(auc_values), function(name) {
                        sprintf("%s - (%.2f)", name, auc_values[[name]])
                    })

                    # Create a dataframe for AUC labels
                    auc_labels_df <- data.frame(
                        Label = auc_labels,
                        ClassComparison = names(auc_values)
                    )

                    roc_data_df$Comparison <- as.character(roc_data_df$Comparison)
                    auc_labels_df$ClassComparison <- as.character(auc_labels_df$ClassComparison)

                    # Merge AUC labels into the roc_data
                    roc_data_df <- base::merge(roc_data_df, auc_labels_df, by.x = "Comparison", by.y = "ClassComparison", all.x = TRUE)

                    plot_unique_hash[["training"]]$auc_roc_multiclass[[method]] <- digest::digest(paste0(resampleID, "_",args$settings,"_training_auc_roc_multiclass_", method), algo="md5", serialize=F)
                    tmp_path <- plot_auc_roc_multiclass_training(roc_data_df, auc_labels_df, settings, plot_unique_hash[["training"]]$auc_roc_multiclass[[method]])

                    res.data$training$auc_roc_multiclass[[method]] <- optimizeSVGFile(tmp_path)
                    res.data$training$auc_roc_multiclass_png[[method]] <- convertSVGtoPNG(tmp_path)
                }
            }
        }
        

        tmp_path <- tempfile(pattern = plot_unique_hash[["saveObjectHash"]], tmpdir = tempdir(), fileext = ".Rdata")
        processingData <- list(
            res.data = res.data, 
            modelData = modelData
        )
        saveCachedList(tmp_path, processingData)
        res.data$saveObjectHash = substr(basename(tmp_path), 1, nchar(basename(tmp_path))-6)



        return (list(success = TRUE, message = res.data))
    }
)
