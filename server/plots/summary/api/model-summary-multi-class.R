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

        if(is_var_empty(settings$selectedOutcomeOptionsIDs) == TRUE){
            settings$selectedOutcomeOptionsIDs <- c(0)
        }

        plot_unique_hash <- list(
            training = list(
                auc_roc = list(),
                auc_roc_multiclass = list(),
                comparison = list()
            ),
            ## ROC for Testing predictions on out leave out data
            testing = list(
                auc_roc = list(),
                auc_roc_multiclass = list(),
                comparison = list()
            ),
            saveObjectHash = digest::digest(paste0(resampleID, "_",args$settings,"_exploration_modelsummary"), algo="md5", serialize=F)
        )

        ## 1st - Get all saved models for selected IDs
        modelsDetails <- db.apps.getModelsDetailsData(modelsIDs)

        ## Only used for "single" when more than one model is selected
        trainingPredictions <- NULL
        testingPredictions <- NULL
        outcome_mapping_primary <- NULL
        outcome_mapping_secondary <- NULL

        for(i in 1:nrow(modelsDetails)) {
            model <- modelsDetails[i,]
            modelPath <- downloadDataset(model$remotePathMain)
            if(modelPath == FALSE){
                return (list(success = FALSE, message = "Remote download error. Cannot locate and load model file."))
            } 
            modelData <- loadRObject(modelPath)

            if (modelData$training$raw$status == TRUE) {
                method <- modelData$training$raw$data$method

                outcome_mappings <- db.apps.getDatasetResamplesMappings(resampleID)

                selected_ids <- settings$selectedOutcomeOptionsIDs
                # Remove any occurrences of 0 from selected_ids
                selected_ids <- selected_ids[selected_ids != 0]
                if (length(selected_ids) > 0) {
                    # Filter the outcome_mappings dataframe to include only selected IDs
                    outcome_mappings_filtered <- outcome_mappings[outcome_mappings$id %in% selected_ids, ]
                }else{
                    outcome_mappings_filtered <- outcome_mappings
                }
                outcome_mappings_filtered <- outcome_mappings_filtered[order(outcome_mappings_filtered$id, decreasing = TRUE), ]

                print(paste0("===> INFO: Selected outcomes: ", length(selected_ids), " Selected models: ", nrow(modelsDetails)))
                # Check if only one class is selected and more than one model is available
                print(paste0("===> INFO: Calculating single models comparisons"))

                if(is.null(outcome_mapping_primary)){
                    outcome_mapping_primary <- head(outcome_mappings_filtered, n=1)

                    outcome_mappings_excluding_primary <- subset(outcome_mappings, class_remapped != outcome_mapping_primary$class_remapped)
                    outcome_mapping_secondary <- head(outcome_mappings_excluding_primary, n=1)
                }

                print(paste0("==> INFO: Outcome Primary class: ", outcome_mapping_primary$class_remapped))
                print(paste0("==> INFO: Outcome Secondary class: ", outcome_mapping_secondary$class_remapped))

                if(is.null(trainingPredictions)){
                    trainingPredictions <- cbind(modelData$training$raw$data$pred, method = modelData$training$raw$data$method)
                }else{
                    modelData$training$raw$data$pred$method <- modelData$training$raw$data$method
                    trainingPredictions <- dplyr::bind_rows(trainingPredictions, modelData$training$raw$data$pred)
                }

                if(!is.null(modelData$predictions$raw$predictions)){
                    predictions_df <- data.frame(pred = as.character(modelData$predictions$raw$predictions), stringsAsFactors = FALSE)
                    predData <- NULL
                    ## Probabilities
                    if(outcome_mapping_primary$class_remapped %in% colnames(modelData$predictions$raw$predictions)){
                        predData <- as.data.frame(cbind(modelData$info$data$testing[[modelData$info$outcome]], modelData$predictions$raw$predictions[, outcome_mapping_primary$class_remapped], modelData$training$raw$data$method), stringsAsFactors = FALSE)
                        names(predData) <- c("referenceData", "predictionObject", "method")
                    ## Class labels
                    }else if(outcome_mapping_primary$class_remapped %in% modelData$predictions$raw$predictions){

                        # Case where only class labels are available
                        predData <- predictions_df %>%
                            dplyr::mutate(referenceData = modelData$info$data$testing[[modelData$info$outcome]],
                                   predictionObject = if_else(pred == outcome_mapping_primary$class_remapped, outcome_mapping_primary$class_remapped, outcome_mapping_secondary$class_remapped),
                                   method = method) %>%
                            dplyr::select(referenceData, predictionObject, method)
                    }
                    if(!is.null(predData)){
                        if (is.null(testingPredictions)) {
                            testingPredictions <- predData
                        } else {
                            testingPredictions <- bind_rows(testingPredictions, predData)
                        }
                    }
                }
                
                if (!"auc_roc" %in% names(res.data$training)) {
                    res.data$training$auc_roc <- list()
                    res.data$training$auc_roc_png <- list()
                }

                objExists <- safe_access(modelData, "training")
                if(objExists){
                    ### TRAINING
                    ## (PLOT 1) TRAINIG ROC - SINGLE:
                    print(paste0("===> INFO: Calculating ROC TRAINING (PLOT 1)"))
                    results <- roc_training_single(modelData, settings, resampleID, outcome_mappings_filtered)

                    if (!is.null(results$roc_data) && length(results$roc_data) > 0) {
                        plot_unique_hash[["training"]]$auc_roc[[method]] <- digest::digest(paste0(resampleID, "_",args$settings,"_training_auc_roc_", method), algo="md5", serialize=F)
                        tmp_path <- plot_auc_roc_multiclass_training_single(results$roc_data, results$auc_labels, settings, plot_unique_hash[["training"]]$auc_roc[[method]])

                        res.data$training$auc_roc[[method]] <- optimizeSVGFile(tmp_path)
                        res.data$training$auc_roc_png[[method]] <- convertSVGtoPNG(tmp_path)
                    }else{
                        res.data$training$auc_roc[[method]] <- FALSE
                        res.data$training$auc_roc_png[[method]] <- FALSE
                    }

                }else{
                    print(paste0("===> INFO: Skipping: roc_training_single"))
                    res.data$training$auc_roc[[method]] <- FALSE
                    res.data$training$auc_roc_png[[method]] <- FALSE
                }


                if (!"auc_roc_multiclass" %in% names(res.data$training)) {
                    res.data$training$auc_roc_multiclass <- list()
                    res.data$training$auc_roc_multiclass_png <- list()
                }

                objExists <- safe_access(modelData, "training")
                if(objExists){
                    ## (PLOT 2) TRAINIG ROC - MULTI:
                    print(paste0("===> INFO: Calculating ROC TRAINING (PLOT 2)"))
                    # results <- roc_training_multi(modelData, settings, resampleID, outcome_mappings_filtered)
                    results <- list(roc_data = NULL)
                    if (!is.null(results$roc_data) && length(results$roc_data) > 0) {
                        plot_unique_hash[["training"]]$auc_roc_multiclass[[method]] <- digest::digest(paste0(resampleID, "_",args$settings,"_training_auc_roc_multiclass_", method), algo="md5", serialize=F)
                        tmp_path <- plot_auc_roc_multiclass_training(results$roc_data, settings, plot_unique_hash[["training"]]$auc_roc_multiclass[[method]])

                        res.data$training$auc_roc_multiclass[[method]] <- optimizeSVGFile(tmp_path)
                        res.data$training$auc_roc_multiclass_png[[method]] <- convertSVGtoPNG(tmp_path)
                    }else{
                        res.data$training$auc_roc_multiclass[[method]] <- FALSE
                        res.data$training$auc_roc_multiclass_png[[method]] <- FALSE
                    }
                }else{
                    print(paste0("===> INFO: Skipping: roc_training_multi"))
                    res.data$training$auc_roc_multiclass[[method]] <- FALSE
                    res.data$training$auc_roc_multiclass_png[[method]] <- FALSE
                }


                if (!"auc_roc" %in% names(res.data$testing)) {
                    res.data$testing$auc_roc <- list()
                    res.data$testing$auc_roc_png <- list()
                }

                objExists <- safe_access(modelData, "predictions", "AUROC")
                if(objExists){
                    ### TESTING
                    ## (PLOT 1) TESTING ROC - SINGLE:
                    print(paste0("===> INFO: Calculating ROC TESTING (PLOT 1)"))
                    results <- roc_testing_single(modelData, settings, resampleID, outcome_mappings_filtered)

                    if (!is.null(results$roc_data) && length(results$roc_data) > 0) {
                        plot_unique_hash[["testing"]]$auc_roc[[method]] <- digest::digest(paste0(resampleID, "_",args$settings,"_testing_auc_roc_", method), algo="md5", serialize=F)
                        tmp_path <- plot_auc_roc_multiclass_testing_single(results$roc_data, results$auc_labels, settings, plot_unique_hash[["testing"]]$auc_roc[[method]])

                        res.data$testing$auc_roc[[method]] <- optimizeSVGFile(tmp_path)
                        res.data$testing$auc_roc_png[[method]] <- convertSVGtoPNG(tmp_path)
                    }else{
                        res.data$testing$auc_roc[[method]] <- FALSE
                        res.data$testing$auc_roc_png[[method]] <- FALSE
                    }
                }else{
                    print(paste0("===> INFO: Skipping: roc_testing_single"))
                    res.data$testing$auc_roc[[method]] <- FALSE
                    res.data$testing$auc_roc_png[[method]] <- FALSE
                }

                if (!"auc_roc_multiclass" %in% names(res.data$testing)) {
                    res.data$testing$auc_roc_multiclass <- list()
                    res.data$testing$auc_roc_multiclass_png <- list()
                }

                objExists <- safe_access(modelData, "predictions", "AUROC", "Multiclass", "ROC", "rocs")
                if(objExists){
                    ## (PLOT 2) TESTING ROC - MULTI:
                    print(paste0("===> INFO: Calculating ROC TESTING (PLOT 2)"))
                    ## results <- roc_testing_multi(modelData, settings, resampleID, outcome_mappings_filtered)
                    results <- list(roc_data = NULL)

                    if (!is.null(results$roc_data) && length(results$roc_data) > 0) {
                        plot_unique_hash[["testing"]]$auc_roc_multiclass[[method]] <- digest::digest(paste0(resampleID, "_",args$settings,"_testing_auc_roc_multiclass_", method), algo="md5", serialize=F)
                        tmp_path <- plot_auc_roc_multiclass_testing(results$roc_data, settings, plot_unique_hash[["testing"]]$auc_roc_multiclass[[method]])

                        res.data$testing$auc_roc_multiclass[[method]] <- optimizeSVGFile(tmp_path)
                        res.data$testing$auc_roc_multiclass_png[[method]] <- convertSVGtoPNG(tmp_path)
                    }else{
                        res.data$testing$auc_roc_multiclass[[method]] <- FALSE
                        res.data$testing$auc_roc_multiclass_png[[method]] <- FALSE
                    }
                }else{
                    print(paste0("===> INFO: Skipping: roc_testing_multi"))
                    res.data$testing$auc_roc_multiclass[[method]] <- FALSE
                    res.data$testing$auc_roc_multiclass_png[[method]] <- FALSE
                }
            }
        }

        print(paste0("===> INFO: Plotting model comparisons"))

        if (!"comparison" %in% names(res.data$training)) {
            res.data$training$comparison <- list()
            res.data$training$comparison_png <- list()
        }

        if(!is.null(trainingPredictions) && nrow(outcome_mappings) < 3){
            
            print(paste0("===> INFO: Plotting ROC Training"))
            plot_unique_hash[["training"]]$comparison[["comparison"]] <- digest::digest(paste0(resampleID, "_",args$settings,"_training_comparison_comparison"), algo="md5", serialize=F)
            

            if(!is.null(trainingPredictions[[outcome_mapping_primary$class_remapped]])){
                tmp_path <- plot_auc_roc_training_probabilities(trainingPredictions, outcome_mapping_primary, outcome_mapping_secondary, settings, plot_unique_hash[["training"]]$comparison[["comparison"]])
            }else{
                tmp_path <- plot_auc_roc_class_labels(trainingPredictions, outcome_mapping_primary, outcome_mapping_secondary, settings, plot_unique_hash[["training"]]$comparison[["comparison"]])
            }

            res.data$training$comparison[["comparison"]] <- optimizeSVGFile(tmp_path)
            res.data$training$comparison_png[["comparison"]] <- convertSVGtoPNG(tmp_path)
        }else{
            print(paste0("===> INFO: Skipping: plot_auc_roc_training"))
            res.data$training$comparison[["comparison"]] <- FALSE
            res.data$training$comparison_png[["comparison"]] <- FALSE
        }

        if (!"comparison" %in% names(res.data$testing)) {
            res.data$testing$comparison <- list()
            res.data$testing$comparison_png <- list()
        }

        if(!is.null(testingPredictions) && nrow(outcome_mappings) < 3){
            print(paste0("===> INFO: Plotting ROC Testing"))
            plot_unique_hash[["testing"]]$comparison[["comparison"]] <- digest::digest(paste0(resampleID, "_",args$settings,"_testing_comparison_comparison"), algo="md5", serialize=F)        
            

            if(!is.null(trainingPredictions[[outcome_mapping_primary$class_remapped]])){
                
                testingPredictions$predictionObject <- as.numeric(testingPredictions$predictionObject)
                testingPredictions$referenceData <- as.numeric(testingPredictions$referenceData)

                tmp_path <- plot_auc_roc_testing_probabilities(testingPredictions, outcome_mapping_primary, outcome_mapping_secondary, settings, plot_unique_hash[["testing"]]$comparison[["comparison"]])
            }else{
                tmp_path <- plot_auc_roc_class_labels(testingPredictions, outcome_mapping_primary, outcome_mapping_secondary, settings, plot_unique_hash[["testing"]]$comparison[["comparison"]])
            }
            res.data$testing$comparison[["comparison"]] <- optimizeSVGFile(tmp_path)
            res.data$testing$comparison_png[["comparison"]] <- convertSVGtoPNG(tmp_path)
        }else{
            print(paste0("===> INFO: Skipping: plot_auc_roc_testing"))
            res.data$testing$comparison[["comparison"]] <- FALSE
            res.data$testing$comparison_png[["comparison"]] <- FALSE
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
