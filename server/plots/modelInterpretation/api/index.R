#* Plot out data from the iris dataset
#* @serializer contentType list(type='image/png')
#' @GET /plots/modelsummary/render-plot
pandora$handle$plots$modelInterpretation$renderPlot <- expression(
    function(req, res, ...){
        args <- as.list(match.call())

        res.data <- list(            
            scatter =  list(),
            heatmap =  list(),
            ice =  list(),
            lime =  list(),
            iml =  list()
        )


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
        if(is_var_empty(settings$displayVariableImportance, "displayVariableImportance") == TRUE){
            settings$displayVariableImportance = NULL
        }


        plot_unique_hash <- list(
            scatter =  list(),
            heatmap =  list(),
            ice =  list(),
            lime =  list(),
            iml =  list(),

            saveObjectHash = digest::digest(paste0(resampleID, "_",args$settings,"_exploration_interpretation"), algo="md5", serialize=F)
        )

        ## 1st - Get all saved models for selected IDs
        modelsDetails <- db.apps.getModelsDetailsData(modelsIDs)
        modelsResampleData = list()

        print(paste0("===> INFO: Found ", nrow(modelsDetails), " models"))


        for(i in 1:nrow(modelsDetails)) {
            model <- modelsDetails[i,]
            modelPath <- downloadDataset(model$remotePathMain)
            if(modelPath == FALSE){
                return (list(success = FALSE, message = "Remote Error. Cannot locate and load file"))
            }

            print(paste0("===> INFO: Loading model ", model$modelInternalID))

            modelData <- loadRObject(modelPath, TRUE)

            if (!is.null(modelData) && modelData$training$raw$status == TRUE) {
                modelsResampleData[[model$modelInternalID]] = modelData
            }
        }

        print(paste0("===> INFO: Found ", length(modelsResampleData), " valid models"))


        for (method in names(modelsResampleData)) {
            
            modelData <- modelsResampleData[[method]]

            variableImp <- modelData[["training"]][["varImportance"]]
            model <- modelData$training$raw$data

            feature_mapping <- modelData[["info"]][["dataset_queue_options"]][["features"]]
            outcome_mapping <- modelData[["info"]][["dataset_queue_options"]][["outcome"]]
            
            ## Original Training Data
            data_training <- modelData$info$data$training
            data_testing <- modelData$info$data$testing
            rename_vector <- setNames(feature_mapping$original, feature_mapping$remapped)
            
            # Rename columns in the training dataset
            colnames(data_training) <- rename_vector[colnames(data_training)]
            # Rename columns in the testing dataset
            colnames(data_testing) <- rename_vector[colnames(data_testing)]
            

            if(is.null(settings$displayVariableImportance)){
                print(paste0("===> INFO: No variable importance selected, using top 2"))
                selected_features <- variableImp$feature_name[1:2]
            }else{
                print(paste0("===> INFO: Using selected variable importance"))
                selected_features <- variableImp[variableImp$feature_name %in% settings$displayVariableImportance, ]$feature_name
            }
            

            
            # Loop through each of the top 10 features
            for (predictVar in selected_features) {
                
                original_feature_name <- feature_mapping$original[feature_mapping$remapped == predictVar]
                original_outcome_name <- outcome_mapping$original  # Assuming single outcome, adjust if needed
                
                print(paste0("===> INFO (scatter): Processing feature: ", predictVar, " (", original_feature_name, ")"))
                
                original_feature_name <- sanitize_filename(original_feature_name)
                
                # Generate PDP data
                pdp_data <- tryCatch({
                    pdp::partial(model, pred.var = predictVar)
                }, error = function(e) {
                    NULL
                })

                if (is.null(pdp_data)) {
                    print(paste0("===> WARNING: Partial dependence data could not be generated.\n"))
                    next
                }
                
                # Rename the column in pdp_data
                if (length(original_feature_name) > 0) {
                    names(pdp_data)[names(pdp_data) == predictVar] <- original_feature_name
                } else {
                    next  # Skip this iteration if no original name is found
                }
                
                plot_unique_hash[["scatter"]][[method]] <- digest::digest(paste0(resampleID, "_",args$settings,"_scatter_",original_feature_name,"_", method), algo="md5", serialize=F)
                
                print(paste0("===> INFO (scatter): Plotting"))
                tmp_path <- plot_interpretation_scatter(pdp_data, original_feature_name, original_outcome_name, settings, plot_unique_hash[["scatter"]][[method]])

                res.data$scatter[[method]][[paste0(original_feature_name,"_",original_outcome_name)]] <- optimizeSVGFile(tmp_path)
                res.data$scatter_png[[method]][[paste0(original_feature_name,"_",original_outcome_name)]] <- convertSVGtoPNG(tmp_path)
                
            }
            
            
            if (length(selected_features) %% 2 == 0) {
                for (i in 1:(length(selected_features) - 1)) {
                    for (j in (i + 1):length(selected_features)) {
                        feature1 <- selected_features[i]
                        feature2 <- selected_features[j]
                        
                        # Extract original feature names
                        original_name1 <- feature_mapping$original[feature_mapping$remapped == feature1]
                        original_name2 <- feature_mapping$original[feature_mapping$remapped == feature2]
                        
                        # Sanitize names
                        original_name1 <- sanitize_filename(original_name1)
                        original_name2 <- sanitize_filename(original_name2)

                        print(paste0("===> INFO (heatmap): Processing features: ", feature1, " (", original_name1, ") and ", feature2, " (", original_name2, ")"))
                        
                        if(feature1 == feature2){
                            print(paste0("===> WARNING: Skipping heatmap for duplicate features: ", feature1))
                            next
                        }

                        # Compute Partial Dependence Data for both variables
                        pd_interaction <- tryCatch({
                            pdp::partial(model, pred.var = c(feature1, feature2), chull = TRUE, grid.resolution = 10)
                        }, error = function(e) {
                            NULL
                        })

                        if (is.null(pd_interaction)) {
                            print(paste0("===> WARNING: Partial dependence data could not be generated.\n"))
                            next
                        }

                        names(pd_interaction)[names(pd_interaction) == feature1] <- original_name1
                        names(pd_interaction)[names(pd_interaction) == feature2] <- original_name2
                        
                        plot_unique_hash[["heatmap"]][[method]] <- digest::digest(paste0(resampleID, "_",args$settings,"_heatmap_",original_name1,"_",original_name2,"_", method), algo="md5", serialize=F)
                        
                        print(paste0("===> INFO (heatmap): Plotting"))
                        tmp_path <- plot_interpretation_heatmap(pd_interaction, original_name1, original_name2, settings, plot_unique_hash[["heatmap"]][[method]])

                        res.data$heatmap[[method]][[paste0(original_name1,"_vs_",original_name2)]] <- optimizeSVGFile(tmp_path)
                        res.data$heatmap_png[[method]][[paste0(original_name1,"_vs_",original_name2)]] <- convertSVGtoPNG(tmp_path)
                    }
                }
            }
            
            # Loop through each of the top 10 features for ICE plots
            for (predictVar in selected_features) {
                original_feature_name <- feature_mapping$original[feature_mapping$remapped == predictVar]
                original_feature_name <- sanitize_filename(original_feature_name)

                print(paste0("===> INFO (ice): Processing feature: ", predictVar, " (", original_feature_name, ")"))

                # Compute ICE plot data
                ice_data <- tryCatch({
                    pdp::partial(model, pred.var = predictVar, ice = TRUE, grid.resolution = 50)
                }, error = function(e) {
                    NULL
                })

                if (is.null(ice_data)) {
                    print(paste0("===> WARNING: Partial dependence data could not be generated.\n"))
                    next
                }
                
                names(ice_data)[names(ice_data) == predictVar] <- original_feature_name
                
                plot_unique_hash[["ice"]][[method]] <- digest::digest(paste0(resampleID, "_",args$settings,"_ice_",original_feature_name,"_", method), algo="md5", serialize=F)
                print(paste0("===> INFO (ice): Plotting"))
                tmp_path <- plot_interpretation_ice(ice_data, original_feature_name, settings, plot_unique_hash[["ice"]][[method]])

                res.data$ice[[method]][[original_feature_name]] <- optimizeSVGFile(tmp_path)
                res.data$ice_png[[method]][[original_feature_name]] <- convertSVGtoPNG(tmp_path)
            }
            
            
            
            # Prepare the explainer
            explainer <- tryCatch({
                lime::lime(modelData$info$data$training, model, bin_continuous = FALSE)
            }, error = function(e) {
                # Optionally return NULL or some other indication of failure
                NULL
            })

            if (!is.null(explainer)) {
                # Explain predictions for a subset of the training data
                explanation <- tryCatch({
                    # Generate explanations for a subset of the training data
                    lime::explain(modelData$info$data$training[1:5, ], explainer, n_labels = 1, n_features = 3)
                }, error = function(e) {
                     # Optionally return NULL or some other indication of failure
                    NULL
                })
 
                if (!is.null(explanation)) {
                    # Correctly map remapped names to original names in the explanation dataframe
                    explanation$feature <- feature_mapping$original[match(explanation$feature, feature_mapping$remapped)]
                    
                    # Plot and save LIME explanations using original feature names
                    for (i in seq_len(nrow(explanation))) {
                        # Sanitize feature names for use in filenames
                        features_in_title <- sanitize_filename(paste(unique(explanation[i, ]$feature), collapse="_"))

                        plot_unique_hash[["lime"]][[method]] <- digest::digest(paste0(resampleID, "_",args$settings,"_lime_",features_in_title,"_", method), algo="md5", serialize=F)
                        
                        print(paste0("===> INFO (lime): Plotting: ", features_in_title))
                        
                        tmp_path <- plot_interpretation_lime(explanation[i, ], i, settings, plot_unique_hash[["ice"]][[method]])

                        if(!is.null(tmp_path)){
                            res.data$lime[[method]][[features_in_title]] <- optimizeSVGFile(tmp_path)
                            res.data$lime_png[[method]][[features_in_title]] <- convertSVGtoPNG(tmp_path)
                        }
                    }
                }
            }


            plot_unique_hash[["iml"]][[method]] <- digest::digest(paste0(resampleID, "_",args$settings,"_iml_",features_in_title,"_", method), algo="md5", serialize=F)
            
            print(paste0("===> INFO (iml): Plotting"))
            tmp_path <- plot_interpretation_iml(model, modelData$info$data$testing, modelData$info$outcome, settings, plot_unique_hash[["iml"]][[method]])

            if(!is.null(tmp_path)){
                res.data$iml[[method]][[modelData$info$outcome]] <- optimizeSVGFile(tmp_path)
                res.data$iml_png[[method]][[modelData$info$outcome]] <- convertSVGtoPNG(tmp_path)
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
