#' @get /plots/correlation/renderOptions
simon$handle$plots$correlation$renderOptions <- expression(
    function(){
        data <- list()

        data$correlation_method <- eval(formals(cor)$method)
        data$na_action <- c(
                            "everything",
                            "all.obs",
                            "complete.obs",
                            "na.or.complete",
                            "pairwise.complete.obs"
                        )
        ## Only if confidence interval is not selected
        data$plot_method <- c("mixed", eval(formals(corrplot)$method))
        data$plot_method_mixed = list()
        data$plot_method_mixed$lower_method <- eval(formals(corrplot)$method)
        data$plot_method_mixed$upper_method <- eval(formals(corrplot)$method)

        data$plot_type <- eval(formals(corrplot)$type)
        data$reorder_correlation <- eval(formals(corrplot)$order)
        data$reorder_correlation_hclust = list()
        data$reorder_correlation_hclust$method <- eval(formals(corrplot)$hclust.method)
        data$reorder_correlation_hclust$number_of_rectangles <- 3

        data$text_size <- list(value = 0.4, min = 0.2, max = 3, step = 0.2)

        data$significance = list()
        data$significance$level <- list(value = 0.05, min = 0, max = 1, step = 0.05)
        data$significance$insignificant_action <- eval(formals(corrplot)$insig)

        data$confidence = list()
        data$confidence$ploting_method <- eval(formals(corrplot)$plotCI)[-1]
        data$confidence$level <- list(value = 0.95, min = 0, max = 1, step = 0.05)

        return(list(
            status = "success",
            data = data
        ))
    }
)

#* Plot out data from the iris dataset
#* @serializer contentType list(type='image/png')
#' @post /plots/correlation/renderPlot
simon$handle$plots$correlation$renderPlot <- expression(
    function(req, res, ...){
        args <- as.list(match.call())
        results <- list(status = FALSE, data = NULL, image = NULL)
        plotUniqueHash <- ""

        resampleID <- 0
        if("resampleID" %in% names(args)){
            resampleID <- as.numeric(args$resampleID)
            plotUniqueHash <- paste0(plotUniqueHash, resampleID)
        }

        settings <- NULL
        if("settings" %in% names(args)){
            settings <- jsonlite::fromJSON(args$settings)
            plotUniqueHash <- paste0(plotUniqueHash, args$settings)
        }

        plotUniqueHash <-  digest::digest(plotUniqueHash, algo="md5", serialize=F)

        tmp_dir <- tempdir(check = TRUE)
        cachedFile <- list.files(tmp_dir, full.names = TRUE, pattern=paste0(plotUniqueHash, ".*\\.svg"))
        ## Check if some files where found in tmpdir that match our unique hash
        if(identical(cachedFile, character(0)) == FALSE){
            if(file.exists(cachedFile)){
                results$status <- TRUE
                results$image = as.character(RCurl::base64Encode(readBin(cachedFile, "raw", n = file.info(cachedFile)$size), "txt"))
                return(list(status = results$status, image = results$image))
            }
        }

        ## 1st - Get JOB and his Info from database
        resampleDetails <- db.apps.getFeatureSetData(resampleID)
        ## save(resampleDetails, file = "/tmp/testing.rds")

        resamplePath <- downloadDataset(resampleDetails[[1]]$remotePathMain)     
        dataset <- data.table::fread(resamplePath, header = T, sep = ',', stringsAsFactors = FALSE, data.table = FALSE)
        
        ## Remove all columns expect selected features
        dataset <- dataset[, names(dataset) %in% c(resampleDetails[[1]]$features$remapped)]

        names(dataset) <- plyr::mapvalues(names(dataset), from=resampleDetails[[1]]$features$remapped, to=resampleDetails[[1]]$features$original)


        ## TODO: also give this data for download!
        data <- cor(dataset, use = settings$na_action, method = settings$correlation_method)
        ## write.csv(data, file = "correlation.csv")

        if(settings$significance$enable == TRUE){
            p.mat <- corTest(data, settings$confidence$level$value)
        }

        args <- list(data,
                        number.cex= 7/ncol(dataset),
                        tl.cex=settings$text_size$value,
                        cl.cex=settings$text_size$value,
                        mar=c(0,0,1,0),
                        order = if(settings$reorder_correlation == "manual") "original" else settings$reorder_correlation, 
                        hclust.method = settings$reorder_correlation_hclust$method, 
                        addrect = settings$reorder_correlation_hclust$number_of_rectangles,
                        is.corr=TRUE,

                        sig.level = if(settings$significance$enable == TRUE) settings$significance$level$value else NULL,
                        insig = if(settings$significance$enable == TRUE) settings$significance$insignificant_action else NULL,

                        p.mat = if(settings$significance$enable == TRUE) p.mat[[1]] else NULL,
                        lowCI.mat = if(settings$significance$enable == TRUE) p.mat[[2]] else NULL,
                        uppCI.mat = if(settings$significance$enable == TRUE) p.mat[[3]] else NULL,

                        plotCI = if(settings$confidence$enable == TRUE) settings$confidence$ploting_method else "n",
                        tl.col = "black",
                        addgrid.col="transparent"
                        )



        if(settings$confidence$enable == TRUE) {
            input_args <- c(list(type = settings$plot_type), args)
        } else if(settings$plot_method == "mixed") {
            input_args <- c(list(lower = settings$plot_method_mixed$lower_method,
                                         upper = settings$plot_method_mixed$upper_method),
                                    args)
        } else {
            input_args <- c(list(method = settings$plot_method, type = settings$plot_type), args)
        }

        tmp_path <- tempfile(pattern = plotUniqueHash, tmpdir = tempdir(), fileext = ".svg")
        svg(tmp_path, width = 8, height = 8, pointsize = 12, onefile = TRUE, family = "Arial", bg = "white", antialias = "default")

        process.execution <- tryCatch( garbage <- R.utils::captureOutput(results$data <- R.utils::withTimeout(do.call(corrplot, input_args), timeout=300, onTimeout = "error") ), error = function(e){ return(e) } )
            print(results$data)
        dev.off()

        ## Optimize SVG using svgo package
        system(paste0(which_cmd("svgo")," ",tmp_path," -o ",tmp_path), intern = TRUE, ignore.stdout = TRUE, ignore.stderr = TRUE, wait = TRUE)

        results$image =  as.character(RCurl::base64Encode(readBin(tmp_path, "raw", n = file.info(tmp_path)$size), "txt"))
        results$status <- TRUE

        return (list(status = results$status, image = results$image))
    }
)