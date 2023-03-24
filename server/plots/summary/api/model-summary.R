#* Plot out data from the iris dataset
#* @serializer contentType list(type='image/png')
#' @GET /plots/modelsummary/render-plot
pandora$handle$plots$modelsummary$renderPlot <- expression(
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
                auc_roc = digest::digest(paste0(resampleID, "_",args$settings,"_training_auc"), algo="md5", serialize=F),
                partial_dependence =  digest::digest(paste0(resampleID, "_",args$settings,"_training_partial_dependence"), algo="md5", serialize=F)
            ),
            testing = list(
                auc_roc = digest::digest(paste0(resampleID, "_",args$settings,"_testing_auc"), algo="md5", serialize=F),
                auc_roc_full =  digest::digest(paste0(resampleID, "_",args$settings,"_testing_auc_roc_full"), algo="md5", serialize=F)
            ),
            saveObjectHash = digest::digest(paste0(resampleID, "_",args$settings,"_exploration_modelsummary"), algo="md5", serialize=F)
        )

        ## 1st - Get all saved models for selected IDs
        modelsDetails <- db.apps.getModelsDetailsData(modelsIDs)

        trainingPredictions <- NULL
        testingPredictions <- NULL

        for(i in 1:nrow(modelsDetails)) {
            model <- modelsDetails[i,]
            modelPath <- downloadDataset(model$remotePathMain)
            if(modelPath == FALSE){
                return (list(success = FALSE, message = "Remote download error. Cannot locate and load model file."))
            } 
            modelData <- loadRObject(modelPath)

            save(modelData, file = "/tmp/modelData")
            if (modelData$training$raw$status == TRUE) {
                if(is.null(trainingPredictions)){
                    trainingPredictions <- cbind(modelData$training$raw$data$pred, method = modelData$training$raw$data$method)
                }else{
                    modelData$training$raw$data$pred$method <- modelData$training$raw$data$method
                    trainingPredictions <- dplyr::bind_rows(trainingPredictions, modelData$training$raw$data$pred)
                }

                if(!is.null(modelData$predictions$raw$predictions)){
                    if("B" %in% colnames(modelData$predictions$raw$predictions)){
                        predData <- as.data.frame(cbind(modelData$info$data$testing[[modelData$info$outcome]], modelData$predictions$raw$predictions[, "B"], modelData$training$raw$data$method), stringsAsFactors = FALSE)
                        names(predData) <- c("referenceData", "predictionObject", "method")
                        if(is.null(testingPredictions)){
                            testingPredictions <- predData
                        }else{
                            testingPredictions <- dplyr::bind_rows(testingPredictions, predData)
                        }
                    }
                }
            }
        }


        if(!is.null(trainingPredictions)){ 
            tmp_path <- plot_auc_roc_training(trainingPredictions, settings, plot_unique_hash[["training"]][["auc_roc"]])

            res.data$training$auc_roc = optimizeSVGFile(tmp_path)
            res.data$training$auc_roc_png = convertSVGtoPNG(tmp_path)
        }
        
        # Plot AUC Testing
        if(!is.null(testingPredictions)){

            testingPredictions$predictionObject <- as.numeric(testingPredictions$predictionObject)
            testingPredictions$referenceData <- as.numeric(testingPredictions$referenceData)
                        
            tmp_path <- plot_auc_roc_testing(testingPredictions, settings, plot_unique_hash[["testing"]][["auc_roc"]])
            
            res.data$testing$auc_roc = optimizeSVGFile(tmp_path)
            res.data$testing$auc_roc_png = convertSVGtoPNG(tmp_path)
        }
        
        # Plot AUC Testing FULL
        #tmp_path <- plot_auc_roc_testing_full(modelData, settings, plot_unique_hash[["testing"]][["auc_roc_full"]])
        #res.data$testing$auc_roc_full = optimizeSVGFile(tmp_path)
        #res.data$testing$auc_roc_full_png = convertSVGtoPNG(tmp_path)
        
        # Plot partial dependence
        #tmp_path <- plot_partial_dependence(modelData, settings, plot_unique_hash[["training"]][["partial_dependence"]])
        #res.data$training$partial_dependence = optimizeSVGFile(tmp_path)
        #res.data$training$partial_dependence_png = convertSVGtoPNG(tmp_path)

        ## Plot feature interaction


        #tmp_path <- plot_feature_interaction(modelData, settings, plot_unique_hash[["training"]][["feature_interaction"]])
        #res.data$training$feature_interaction = optimizeSVGFile(tmp_path)
        #res.data$training$feature_interaction_png = convertSVGtoPNG(tmp_path)

        ## https://stackoverflow.com/questions/30997876/how-to-obtain-coefficient-for-matthews-correlation-after-running-these-two-lines

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
