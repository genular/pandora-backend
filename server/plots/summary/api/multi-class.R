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
                auc_roc = list()
            ),
            ## ROC for Testing predictions on out leave out data
            testing = list(
                auc_roc = list()
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

                    ## TESTING ROC:
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

                    plot_unique_hash[["testing"]]$auc_roc[[method]] <- digest::digest(paste0(resampleID, "_",args$settings,"_testing_auc_", method), algo="md5", serialize=F)
                    tmp_path <- plot_auc_roc_testing_multiclass(roc_data_df, auc_value, settings, plot_unique_hash[["testing"]]$auc_roc[[method]])

                    res.data$testing$auc_roc[[method]] <- optimizeSVGFile(tmp_path)
                    res.data$testing$auc_roc_png[[method]] <- convertSVGtoPNG(tmp_path)

                    ## TRAINIG ROC:
                    observed <- modelData$training$raw$data$pred$obs
                    classes <- unique(observed)
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
                    auc_labels <- sprintf("%s: %.2f", names(auc_values), auc_values)

                    plot_unique_hash[["training"]]$auc_roc[[method]] <- digest::digest(paste0(resampleID, "_",args$settings,"_training_auc_", method), algo="md5", serialize=F)
                    tmp_path <- plot_auc_roc_trainig_multiclass(roc_data, auc_labels, settings, plot_unique_hash[["training"]]$auc_roc[[method]])

                    res.data$training$auc_roc[[method]] <- optimizeSVGFile(tmp_path)
                    res.data$training$auc_roc_png[[method]] <- convertSVGtoPNG(tmp_path)
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
