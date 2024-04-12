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

                    outcome_mappings <- db.apps.getDatasetResamplesMappings(resampleID)

                    selected_ids <- settings$selectedOutcomeOptionsIDs
                    # Remove any occurrences of 0 from selected_ids
                    selected_ids <- selected_ids[selected_ids != 0]
                    if (length(selected_ids) > 0) {
                        # Filter the outcome_mappings dataframe to include only selected IDs
                        outcome_mappings <- outcome_mappings[outcome_mappings$id %in% selected_ids, ]
                    }

                    ### TRAINING
                    ## (PLOT 1) TRAINIG ROC - SINGLE:
                    print(paste0("===> INFO: Calculating ROC TRAINING (PLOT 1)"))

                    results <- roc_training_single(modelData, settings, resampleID, outcome_mappings)

                    print(paste0("===> INFO: Plotting (PLOT 1)"))

                    plot_unique_hash[["training"]]$auc_roc[[method]] <- digest::digest(paste0(resampleID, "_",args$settings,"_training_auc_roc_", method), algo="md5", serialize=F)
                    tmp_path <- plot_auc_roc_multiclass_training_single(results$roc_data, results$auc_labels, settings, plot_unique_hash[["training"]]$auc_roc[[method]])

                    res.data$training$auc_roc[[method]] <- optimizeSVGFile(tmp_path)
                    res.data$training$auc_roc_png[[method]] <- convertSVGtoPNG(tmp_path)

                    ## (PLOT 2) TRAINIG ROC - MULTI:
                    print(paste0("===> INFO: Calculating ROC TRAINING (PLOT 2)"))
                    results <- roc_training_multi(modelData, settings, resampleID, outcome_mappings)

                    plot_unique_hash[["training"]]$auc_roc_multiclass[[method]] <- digest::digest(paste0(resampleID, "_",args$settings,"_training_auc_roc_multiclass_", method), algo="md5", serialize=F)
                    tmp_path <- plot_auc_roc_multiclass_training(results$roc_data, settings, plot_unique_hash[["training"]]$auc_roc_multiclass[[method]])

                    res.data$training$auc_roc_multiclass[[method]] <- optimizeSVGFile(tmp_path)
                    res.data$training$auc_roc_multiclass_png[[method]] <- convertSVGtoPNG(tmp_path)

                    ### TESTING
                    ## (PLOT 1) TESTING ROC - SINGLE:
                    print(paste0("===> INFO: Calculating ROC TESTING (PLOT 1)"))
                    results <- roc_testing_single(modelData, settings, resampleID, outcome_mappings)

                    plot_unique_hash[["testing"]]$auc_roc[[method]] <- digest::digest(paste0(resampleID, "_",args$settings,"_testing_auc_roc_", method), algo="md5", serialize=F)
                    tmp_path <- plot_auc_roc_multiclass_testing_single(results$roc_data, results$auc_labels, settings, plot_unique_hash[["testing"]]$auc_roc[[method]])

                    res.data$testing$auc_roc[[method]] <- optimizeSVGFile(tmp_path)
                    res.data$testing$auc_roc_png[[method]] <- convertSVGtoPNG(tmp_path)

                    ## (PLOT 2) TESTING ROC - MULTI:
                    print(paste0("===> INFO: Calculating ROC TESTING (PLOT 2)"))
                    results <- roc_testing_multi(modelData, settings, resampleID, outcome_mappings)

                    plot_unique_hash[["testing"]]$auc_roc_multiclass[[method]] <- digest::digest(paste0(resampleID, "_",args$settings,"_testing_auc_roc_multiclass_", method), algo="md5", serialize=F)
                    tmp_path <- plot_auc_roc_multiclass_testing(results$roc_data, settings, plot_unique_hash[["testing"]]$auc_roc_multiclass[[method]])

                    res.data$testing$auc_roc_multiclass[[method]] <- optimizeSVGFile(tmp_path)
                    res.data$testing$auc_roc_multiclass_png[[method]] <- convertSVGtoPNG(tmp_path)
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
