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
            iml_featureimp =  list(),
            iml_interaction =  list(),
            iml_featureeffect_ale =  list(),
            iml_featureeffect_pdp_ice =  list()
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

        if(is_var_empty(settings$selectedPlots, "selectedPlots") == TRUE){
            settings$selectedPlots = c("scatter", "heatmap", "ice", "lime", "iml_featureimp", "iml_interaction", "iml_featureeffect_ale", "iml_featureeffect_pdp_ice")
        }

        print(paste0("===> INFO: Processing plots: ", settings$selectedPlots))


        plot_unique_hash <- list(
            scatter =  list(),
            heatmap =  list(),
            ice =  list(),
            lime =  list(),
            iml_featureimp =  list(),
            iml_interaction =  list(),
            iml_featureeffect_ale =  list(),
            iml_featureeffect_pdp_ice =  list(),

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

        save(modelsResampleData, file = "/tmp/modelsResampleData")

        for (method in names(modelsResampleData)) {
            
            modelData <- modelsResampleData[[method]]

            variableImp <- modelData[["training"]][["varImportance"]]
            model <- modelData$training$raw$data

            feature_mapping <- modelData[["info"]][["dataset_queue_options"]][["features"]]
            feature_mapping$original <- sanitize_filename(feature_mapping$original)

            outcome_mapping <- modelData[["info"]][["dataset_queue_options"]][["outcome"]]
            
            ## Original Training Data
            data_training <- modelData$info$data$training
            data_testing <- modelData$info$data$testing
            rename_vector_features <- setNames(feature_mapping$original, feature_mapping$remapped)
            
            # Rename columns in the training dataset
            colnames(data_training) <- rename_vector_features[colnames(data_training)]
            # Rename columns in the testing dataset
            colnames(data_testing) <- rename_vector_features[colnames(data_testing)]


            rename_vector_outcome <- setNames(modelData[["info"]][["outcome_mapping"]][["class_original"]],
                                              modelData[["info"]][["outcome_mapping"]][["class_remapped"]])
            

            if(is.null(settings$displayVariableImportance)){
                print(paste0("===> INFO: No variable importance selected, using top 2"))
                selected_features <- variableImp$feature_name[1:2]
            }else{
                print(paste0("===> INFO: Using selected variable importance"))
                selected_features <- variableImp[variableImp$feature_name %in% settings$displayVariableImportance, ]$feature_name
            }
                        
            if("scatter" %in% settings$selectedPlots){
                for (predictVar in selected_features) {
                    original_feature_name <- feature_mapping$original[feature_mapping$remapped == predictVar]
                    original_outcome_name <- outcome_mapping$original  # Assuming single outcome, adjust if needed
                    
                    print(paste0("===> INFO (scatter): Processing feature: ", predictVar, " (", original_feature_name, ")"))
                    
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
                    if (!"scatter_png" %in% names(res.data)) {
                        res.data$scatter_png <- list()
                    }
                    res.data$scatter_png[[method]][[paste0(original_feature_name,"_",original_outcome_name)]] <- convertSVGtoPNG(tmp_path)
                    
                }
            } ## PLOT 1 - scatter
            
            if("heatmap" %in% settings$selectedPlots){
                if (length(selected_features) %% 2 == 0) {
                    for (i in 1:(length(selected_features) - 1)) {
                        for (j in (i + 1):length(selected_features)) {
                            feature1 <- selected_features[i]
                            feature2 <- selected_features[j]
                            
                            # Extract original feature names
                            original_name1 <- feature_mapping$original[feature_mapping$remapped == feature1]
                            original_name2 <- feature_mapping$original[feature_mapping$remapped == feature2]

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
                            if (!"heatmap_png" %in% names(res.data)) {
                                res.data$heatmap_png <- list()
                            }
                            res.data$heatmap_png[[method]][[paste0(original_name1,"_vs_",original_name2)]] <- convertSVGtoPNG(tmp_path)
                        }
                    }
                }
            }
            
            
            if("ice" %in% settings$selectedPlots){
                for (predictVar in selected_features) {
                    original_feature_name <- feature_mapping$original[feature_mapping$remapped == predictVar]

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
                    if (!"ice_png" %in% names(res.data)) {
                        res.data$ice_png <- list()
                    }
                    res.data$ice_png[[method]][[original_feature_name]] <- convertSVGtoPNG(tmp_path)
                }
            }
            
            
            if("lime" %in% settings$selectedPlots){
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
                        ## remap the feature name
                        explanation$feature_desc <- explanation$feature
                        ## remap outcome label
                        explanation$label <-modelData[["info"]][["outcome_mapping"]]$class_original[match(explanation$label,modelData[["info"]][["outcome_mapping"]]$class_remapped)]
                        
                        # Plot and save LIME explanations using original feature names
                        for (i in seq_len(nrow(explanation))) {
                            # Sanitize feature names for use in filenames
                            features_in_title <- paste(unique(explanation[i, ]$feature), collapse="_")

                            plot_unique_hash[["lime"]][[method]] <- digest::digest(paste0(resampleID, "_",args$settings,"_lime_",features_in_title,"_", method), algo="md5", serialize=F)
                            
                            print(paste0("===> INFO (lime): Plotting: ", features_in_title))
                            
                            tmp_path <- plot_interpretation_lime(explanation[i, ], i, settings, plot_unique_hash[["lime"]][[method]])

                            if(!is.null(tmp_path)){
                                res.data$lime[[method]][[features_in_title]] <- optimizeSVGFile(tmp_path)
                                if (!"lime_png" %in% names(res.data)) {
                                    res.data$lime_png <- list()
                                }
                                res.data$lime_png[[method]][[features_in_title]] <- convertSVGtoPNG(tmp_path)
                            }
                        }
                    }
                }
            }

            ## IML plots

            mod <- tryCatch({
                    options(warn = 2)  # Treat all warnings as errors
                    iml::Predictor$new(model, data = modelData$info$data$testing, y = modelData$info$outcome, type = "prob")
                }, error = function(e) {
                    options(warn = 0)  # Reset warning behavior
                    cat("===> WARNING: Failed to create model object: ", e$message, "\n")
                    NULL  # Return NULL if there is an error
                })

            if (!is.null(mod)) {

                if("iml_featureimp" %in% settings$selectedPlots){
                    print(paste0("===> INFO (iml_featureimp): Plotting"))
                    plot_unique_hash[["iml_featureimp"]][[outcome_mapping$original]] <- digest::digest(paste0(resampleID, "_",args$settings,"_iml_featureimp_",outcome_mapping$original,"_", method), algo="md5", serialize=F)
                    
                    tmp_path <- plot_interpretation_iml_featureimp(mod, 
                        rename_vector_features, 
                        settings, 
                        plot_unique_hash[["iml_featureimp"]][[outcome_mapping$original]])

                    if(!is.null(tmp_path)){
                        res.data$iml_featureimp[[method]][[outcome_mapping$original]] <- optimizeSVGFile(tmp_path)
                        if (!"iml_featureimp_png" %in% names(res.data)) {
                            res.data$iml_featureimp_png <- list()
                        }
                        res.data$iml_featureimp_png[[method]][[outcome_mapping$original]] <- convertSVGtoPNG(tmp_path)
                    }
                }
                
                if("iml_interaction" %in% settings$selectedPlots){
                    print(paste0("===> INFO (iml_interaction): Plotting"))
                    plot_unique_hash[["iml_interaction"]][[outcome_mapping$original]] <- digest::digest(paste0(resampleID, "_",args$settings,"_iml_interaction_",outcome_mapping$original,"_", method), algo="md5", serialize=F)
                    tmp_path <- plot_interpretation_iml_interaction(mod, 
                        rename_vector_features, 
                        rename_vector_outcome, 
                        settings, 
                        plot_unique_hash[["iml_interaction"]][[outcome_mapping$original]])
                    if(!is.null(tmp_path)){
                        res.data$iml_interaction[[method]][[outcome_mapping$original]] <- optimizeSVGFile(tmp_path)
                        if (!"iml_interaction_png" %in% names(res.data)) {
                            res.data$iml_interaction_png <- list()
                        }
                        res.data$iml_interaction_png[[method]][[outcome_mapping$original]] <- convertSVGtoPNG(tmp_path)
                    }
                }

                if("iml_featureeffect_ale" %in% settings$selectedPlots){
                    print(paste0("===> INFO (iml_featureeffect_ale): Plotting"))
                    if (length(selected_features) %% 2 == 0) {
                        for (i in 1:(length(selected_features) - 1)) {
                            for (j in (i + 1):length(selected_features)) {
                                feature1 <- selected_features[i]
                                feature2 <- selected_features[j]

                                if(feature1 == feature2){
                                    print(paste0("===> WARNING: Skipping iml_featureeffect_ale for same features: ", feature1))
                                    next
                                }

                                # Extract original feature names
                                original_name1 <- feature_mapping$original[feature_mapping$remapped == feature1]
                                original_name2 <- feature_mapping$original[feature_mapping$remapped == feature2]

                                print(paste0("===> INFO (iml_featureeffect_ale): Processing features: ", feature1, " (", original_name1, ") and ", feature2, " (", original_name2, ")"))
                                
                                plot_unique_hash[["iml_featureeffect_ale"]][[paste0(original_name1,"_vs_",original_name2)]] <- digest::digest(paste0(resampleID, "_",args$settings,"_iml_featureeffect_ale_",paste0(original_name1,"_vs_",original_name2),"_",outcome_mapping$original,"_", method), algo="md5", serialize=F)

                                tmp_path <- plot_interpretation_iml_featureeffect_ale(mod, 
                                    c(feature1, feature2), 
                                    rename_vector_features, 
                                    rename_vector_outcome, 
                                    settings, 
                                    plot_unique_hash[["iml_featureeffect_ale"]][[paste0(original_name1,"_vs_",original_name2)]])
                                
                                if(!is.null(tmp_path)){
                                    res.data$iml_featureeffect_ale[[method]][[paste0(original_name1,"_vs_",original_name2)]] <- optimizeSVGFile(tmp_path)
                                    if (!"iml_featureeffect_ale_png" %in% names(res.data)) {
                                        res.data$iml_featureeffect_ale_png <- list()
                                    }
                                    res.data$iml_featureeffect_ale_png[[method]][[paste0(original_name1,"_vs_",original_name2)]] <- convertSVGtoPNG(tmp_path)
                                }
                            }
                        }
                    }
                }

                if("iml_featureeffect_pdp_ice" %in% settings$selectedPlots){
                    print(paste0("===> INFO (iml_featureeffect_pdp_ice): Plotting"))
                    for (predictVar in selected_features) {
                        process_feature <- feature_mapping[feature_mapping$remapped == predictVar,]

                        print(paste0("===> INFO (iml_featureeffect_pdp_ice): Processing feature: ", predictVar, " (", process_feature$original, ")"))
                        plot_unique_hash[["iml_featureeffect_pdp_ice"]][[outcome_mapping$original]] <- digest::digest(paste0(resampleID, "_",args$settings,"_iml_featureeffect_pdp_ice_",process_feature$original,"_", method), algo="md5", serialize=F)
                        
                        tmp_path <- plot_interpretation_iml_featureeffect_pdp_ice(mod, 
                            process_feature, 
                            rename_vector_outcome, 
                            settings, 
                            plot_unique_hash[["iml_featureeffect_pdp_ice"]][[outcome_mapping$original]])
                        
                        if(!is.null(tmp_path)){
                            res.data$iml_featureeffect_pdp_ice[[method]][[process_feature$original]] <- optimizeSVGFile(tmp_path)
                            if (!"iml_featureeffect_pdp_ice_png" %in% names(res.data)) {
                                res.data$iml_featureeffect_pdp_ice_png <- list()
                            }
                            res.data$iml_featureeffect_pdp_ice_png[[method]][[process_feature$original]] <- convertSVGtoPNG(tmp_path)
                        }
                    }
                }

                print(paste0("===> INFO: Done processing IML for: ", method))
            }
        }

        print(paste0("===> INFO: Done processing all methods"))


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
