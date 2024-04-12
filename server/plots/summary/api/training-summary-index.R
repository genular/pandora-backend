#* Plot out data from the iris dataset
#* @serializer contentType list(type='image/png')
#' @GET /plots/summary/render-plot
pandora$handle$plots$summary$renderPlot <- expression(
    function(req, res, ...){
        args <- as.list(match.call())

        data <- list(boxplot = NULL, rocplot = NULL, boxplot_png = NULL, rocplot_png = NULL, info = list(summary = NULL, differences = NULL))


        plotUniqueHash <- ""

        resampleID <- 0
        if("resampleID" %in% names(args)){
            resampleID <- as.numeric(args$resampleID)
            plotUniqueHash <- paste0(plotUniqueHash, resampleID)
        }
        modelsIDs <- NULL
        if("modelsIDs" %in% names(args)){
            modelsIDs <- jsonlite::fromJSON(args$modelsIDs)
            plotUniqueHash <- paste0(plotUniqueHash, args$modelsIDs)
        }

        plotUniqueHash <-  digest::digest(plotUniqueHash, algo="md5", serialize=F)

        print(paste0("==> INFO: Training Summery - modelIDs: ", paste(modelsIDs, collapse = ", ")))

        ## 1st - Get all saved models for selected IDs
        modelsDetails <- db.apps.getModelsDetailsData(modelsIDs)

        modelsResampleData = list()
        modelPredictionData <- NULL

        for(i in 1:nrow(modelsDetails)) {
            model <- modelsDetails[i,]
            modelPath <- downloadDataset(model$remotePathMain)    
            modelData <- loadRObject(modelPath)

            if (modelData$training$raw$status == TRUE) {
                modelsResampleData[[model$modelInternalID]] = modelData$training$raw$data

                if(is.null(modelPredictionData)){
                    modelPredictionData <- cbind(modelData$training$raw$data$pred, method = modelData$training$raw$data$method)
                }else{
                    modelData$training$raw$data$pred$method <- modelData$training$raw$data$method
                    modelPredictionData <- dplyr::bind_rows(modelPredictionData, modelData$training$raw$data$pred)
                }
            }
        }

        print("===> modelsResampleData")

        if(length(modelsResampleData) > 1){
            resamps <- caret::resamples(modelsResampleData)

            save(resamps, file = "/tmp/resamps")
            save(modelPredictionData, file = "/tmp/modelPredictionData")

            ## 1. BOX PLOT
            plotData <- reshape2::melt(resamps$values, id.vars = "Resample")
            tmp <- strsplit(as.character(plotData$variable), "~", fixed = TRUE)
            plotData$Model <- unlist(lapply(tmp, function(x) x[1]))
            plotData$Metric <- unlist(lapply(tmp, function(x) x[2]))
            plotData <- base::subset(plotData, Model %in% resamps$models & Metric  %in% resamps$metric)
            
            avPerf <- plyr::ddply(subset(plotData, Metric == resamps$metric[1]),plyr::.(Model),function(x) c(Median = median(x$value, na.rm = TRUE)))
            avPerf <- avPerf[order(avPerf$Median),]
            plotData$Model <- factor(as.character(plotData$Model),
                                     levels = avPerf$Model)


            tmp_path <- tempfile(pattern = "file", tmpdir = tempdir(), fileext = ".svg")
            tempdir(check = TRUE)
            svg(tmp_path, width = 8, height = 8, pointsize = 12, onefile = TRUE, family = "Arial", bg = "white", antialias = "default")
                
                plot <- ggplot(plotData, aes(x=Model, y=value, fill=Model)) +
                            geom_boxplot(position=position_dodge(1), colour = "#000000", lwd=0.25) +
                            theme_minimal() +
                            scale_color_brewer(palette="Set1") + 
                            facet_wrap(~Metric, scales="free")
                print(plot)
            dev.off()


            ## Optimize SVG using svgo package
            tmp_path_png <- stringr::str_replace(tmp_path, ".svg", ".png")
            png_cmd <- paste0(which_cmd("rsvg-convert")," ",tmp_path," -f png -o ",tmp_path_png)
            convert_cmd <- paste0(which_cmd("svgo")," ",tmp_path," -o ",tmp_path, " && ", png_cmd)
            system(convert_cmd, intern = TRUE, ignore.stdout = TRUE, ignore.stderr = TRUE, wait = TRUE)

            data$boxplot <- toString(RCurl::base64Encode(readBin(tmp_path, "raw", n = file.info(tmp_path)$size), "txt"))
            data$boxplot_png <- toString(RCurl::base64Encode(readBin(tmp_path_png, "raw", n = file.info(tmp_path_png)$size), "txt"))

            ## 2. SUMMARY
            data$info$summary <- R.utils::captureOutput(summary(resamps))
            data$info$summary <- paste(data$info$summary, collapse="\n")
            data$info$summary <- toString(RCurl::base64Encode(data$info$summary, "txt"))


            unique_pred_levels <- unique(c(levels(modelPredictionData$pred), levels(modelPredictionData$obs)))

            if(length(unique_pred_levels) <= 2){

                data$info$differences <- R.utils::captureOutput(summary(diff(resamps)))
                data$info$differences <- paste(data$info$differences, collapse="\n")
                data$info$differences <- toString(RCurl::base64Encode(data$info$differences, "txt"))

                ## 4. ROC_AUC_PLOT
                tmp_path <- tempfile(pattern = "file", tmpdir = tempdir(), fileext = ".svg")
                tempdir(check = TRUE)
                svg(tmp_path, width = 8, height = 8, pointsize = 12, onefile = TRUE, family = "Arial", bg = "white", antialias = "default")

                    plot <- ggplot(modelPredictionData, aes(m=B, d=factor(obs, levels = unique_pred_levels), fill = method, color = method)) + 
                        geom_roc(hjust = -0.4, vjust = 1.5, linealpha = 1, increasing = TRUE) + 
                        coord_equal() +
                        style_roc(major.breaks = c(0, 0.1, 0.25, 0.5, 0.75, 0.9, 1),
                                minor.breaks = c(seq(0, 0.1, by = 0.01), seq(0.9, 1, by = 0.01)),
                                guide = TRUE, 
                                xlab = "False positive fraction (1-specificity)",
                                ylab = "True positive fraction (sensitivity)", 
                                theme = theme_bw) + 
                        geom_abline(slope = 1, intercept = 0, color = "#D3D3D3", aplha = 0.85, linetype="longdash") +
                        scale_fill_brewer(palette="Set1")

                    print(plot)

                dev.off() 


                ## Optimize SVG using svgo package
                tmp_path_png <- stringr::str_replace(tmp_path, ".svg", ".png")
                png_cmd <- paste0(which_cmd("rsvg-convert")," ",tmp_path," -f png -o ",tmp_path_png)
                convert_cmd <- paste0(which_cmd("svgo")," ",tmp_path," -o ",tmp_path, " && ", png_cmd)
                system(convert_cmd, intern = TRUE, ignore.stdout = TRUE, ignore.stderr = TRUE, wait = TRUE)

                data$rocplot <- toString(RCurl::base64Encode(readBin(tmp_path, "raw", n = file.info(tmp_path)$size), "txt"))
                data$rocplot_png <- toString(RCurl::base64Encode(readBin(tmp_path_png, "raw", n = file.info(tmp_path_png)$size), "txt"))
            }
           

        }

        return (list(success = TRUE, message = data))
    }
)


