#* Plot out data from the iris dataset
#* @serializer contentType list(type='image/png')
#' @GET /plots/summary/render-plot
simon$handle$plots$summary$renderPlot <- expression(
    function(req, res, ...){
        args <- as.list(match.call())


        options(width = 360)

        data <- list( boxplot = NULL, rocplot = NULL, info = list(summary = NULL, differences = NULL))

        resampleID <- 0
        if("resampleID" %in% names(args)){
            resampleID <- as.numeric(args$resampleID)
        }
        modelsIDs <- NULL
        if("modelsIDs" %in% names(args)){
            modelsIDs <- jsonlite::fromJSON(args$modelsIDs)
        }
        ## 1st - Get all saved models for selected IDs
        modelsDetails <- db.apps.getModelsDetailsData(modelsIDs)

        modelsResampleData = list()
        modelsDetailsData = list()
        for(i in 1:nrow(modelsDetails)) {
            model <- modelsDetails[i,]
            modelPath <- downloadDataset(model$remotePathMain)    
            modelData <- loadRObject(modelPath)

            if (modelData$training$status == TRUE) {
                modelsResampleData[[model$modelInternalID]] = modelData$training$data
                modelsDetailsData[[model$modelInternalID]] <- list(
                        method = model$modelInternalID,
                        ROC = modelData$auc
                    )
            }
        }

        if(length(modelsResampleData) > 1){
            resamps <- caret::resamples(modelsResampleData)

            total_models <- length(modelsDetailsData)
            all_models <- as.character(total_models)
            colors <- RColorBrewer::brewer.pal(total_models, "Blues")
            my.settings <- list(
                strip.background=list(col=colors[6]),
                strip.border=list(col="black")
            )

            ## 1. BOX PLOT
            tmp <- tempfile()
            svg(tmp,  width = 8, height = 8, pointsize = 12, onefile = TRUE, family = "mono", bg = "white", antialias = "default")
                plot <- lattice::bwplot(resamps, metric = c("Accuracy", "Sensitivity", "Specificity", "F1", "Recall", "AUC"), scales = list(x = list(relation="free")), par.settings = my.settings)
                print(plot)
            dev.off()
            data$boxplot <- toString(RCurl::base64Encode(readBin(tmp, "raw", n = file.info(tmp)$size), "txt"))

            ## 2. SUMMARY
            data$info$summary <- R.utils::captureOutput(summary(resamps))
            data$info$summary <- paste(data$info$summary, collapse="\n")
            data$info$summary <- toString(RCurl::base64Encode(data$info$summary, "txt"))

            data$info$differences <- R.utils::captureOutput(summary(diff(resamps)))
            data$info$differences <- paste(data$info$differences, collapse="\n")
            data$info$differences <- toString(RCurl::base64Encode(data$info$differences, "txt"))
           
            ## 4. ROC_AUC_PLOT
            tmp <- tempfile()
            svg(tmp,  width = 8, height = 8, pointsize = 12, onefile = TRUE, family = "mono", bg = "white", antialias = "default")
                i = 1;
                for(model in modelsDetailsData){
                    all_models[i] <- model$method
                    plotData <- model$ROC$roc
                    if(i == 1){
                        plot(plotData, type = "S", col=colors[i])
                    }else{
                        plot(plotData, type = "S", col=colors[i])
                    }
                    if(i < total_models){
                        par(new=TRUE)
                    }
                    
                    i <- i + 1
                }
                legend("bottomright", inset=.05, title="Classifiers", all_models, fill=colors, horiz=TRUE)
            dev.off()
            data$rocplot <- toString(RCurl::base64Encode(readBin(tmp, "raw", n = file.info(tmp)$size), "txt"))
        }

        return (list(success = TRUE, message = data))
    }
)


