#' @get /plots/correlation/renderOptions
simon$handle$plots$editing$correlation$renderOptions <- expression(
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
simon$handle$plots$editing$correlation$renderPlot <- expression(
    function(req, res, ...){
        args <- as.list(match.call())
        results <- list(status = FALSE, data = NULL, image = NULL, image_png = NULL, dropped_columns = NULL, error_message = NULL)

        plotUniqueHash <- "editing_correlation"

        selectedFileID <- 0
        if("selectedFileID" %in% names(args)){
            selectedFileID <- as.numeric(args$selectedFileID)
            plotUniqueHash <- paste0(plotUniqueHash, selectedFileID)
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
            if(file.exists(cachedFile) == TRUE){
                results$status <- TRUE                
                results$image = as.character(RCurl::base64Encode(readBin(cachedFile, "raw", n = file.info(cachedFile)$size), "txt"))

                cachedFile_png <- stringr::str_replace(cachedFile, ".svg", ".png")
                if(file.exists(cachedFile_png) == TRUE){
                    results$image_png = as.character(RCurl::base64Encode(readBin(cachedFile_png, "raw", n = file.info(cachedFile_png)$size), "txt"))
                }

                return(list(status = results$status, image = results$image, image_png = results$image_png))
            }
        }

        ## 1st - Get JOB and his Info from database
        selectedFileDetails <- db.apps.getFileDetails(selectedFileID)
        ## save(selectedFileDetails, file = "/tmp/testing.rds")

        selectedFilePath <- downloadDataset(selectedFileDetails[1,]$file_path)     
        fileHeader <- jsonlite::fromJSON(selectedFileDetails[1,]$details)
        fileHeader <- plyr::ldply (fileHeader$header$formatted, data.frame)

        dataset <- data.table::fread(selectedFilePath, header = T, sep = ',', stringsAsFactors = FALSE, data.table = FALSE)

        if(length(settings$selectedColumns) == 0) {
            settings$selectedColumns <- fileHeader$remapped
        }

        ## Remove all columns expect selected features
        dataset <- dataset %>% select(all_of(settings$selectedColumns)) 

        remapping_header <- fileHeader %>%
                            filter(remapped %in% settings$selectedColumns) %>%
                            select(remapped, original)

        ## Rename remapped columns to original ones
        dataset <- dataset %>% rename_(.dots=with(remapping_header, setNames(as.list(as.character(remapped)), original)))

        ## Drop all non numeric columns
        numeric_columns <- names(select_if(dataset, is.numeric))
        dropped_columns <- setdiff(settings$selectedColumns, numeric_columns)

        dataset_filtered <- dataset %>% select(all_of(numeric_columns)) 
        if(ncol(dataset_filtered) <= 1){
            error_check <- TRUE
            results$error_message <- "Not enough numerical columns found in database."
        }else{
            error_check <- FALSE
        }

        if(error_check == FALSE){
            ## TODO: also give this data for download!
            data <- cor(dataset_filtered, use = settings$na_action, method = settings$correlation_method)
            ## write.csv(data, file = "correlation.csv")


            if(settings$significance$enable == TRUE){
                p.mat <- corTest(data, settings$confidence$level$value)
            }

            args <- list(data,
                            number.cex= 7/ncol(dataset_filtered),
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
            svg(tmp_path, width = 12, height = 12, pointsize = 12, onefile = TRUE, family = "Arial", bg = "white", antialias = "default")

            process.execution <- tryCatch( garbage <- R.utils::captureOutput(results$data <- R.utils::withTimeout(do.call(corrplot, input_args), timeout=300, onTimeout = "error") ), error = function(e){ return(e) } )
                print(results$data)
            dev.off()

            ## Optimize SVG using svgo package
            tmp_path_png <- stringr::str_replace(tmp_path, ".svg", ".png")
            png_cmd <- paste0(which_cmd("rsvg-convert")," ",tmp_path," -f png -o ",tmp_path_png)
            # convert_cmd <- paste0(which_cmd("svgo")," ",tmp_path," -o ",tmp_path, " --config='{ \"plugins\": [{ \"removeDimensions\": true }] }' && ", png_cmd)
            convert_cmd <- paste0(which_cmd("svgo")," ",tmp_path," -o ",tmp_path, " && ", png_cmd)
            system(convert_cmd, intern = TRUE, ignore.stdout = TRUE, ignore.stderr = TRUE, wait = TRUE)



            svg_data <- readBin(tmp_path, "raw", n = file.info(tmp_path)$size)
            results$image = as.character(RCurl::base64Encode(svg_data, "txt"))
            results$image_png =  as.character(RCurl::base64Encode(readBin(tmp_path_png, "raw", n = file.info(tmp_path_png)$size), "txt"))

            results$status <- TRUE
        }


        return (list(status = results$status, image = results$image, image_png = results$image_png, dropped_columns = dropped_columns, error_message = results$error_message))
    }
)
