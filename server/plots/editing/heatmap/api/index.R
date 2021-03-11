#* Plot out data from the iris dataset
#* @serializer contentType list(type='image/png')
#' @post /plots/editing/heatmap/renderPlot
simon$handle$plots$editing$heatmap$renderPlot <- expression(
    function(req, res, ...){
        args <- as.list(match.call())
        results <- list(status = FALSE, data = NULL, image = NULL)
        plotUniqueHash <- "editing_clustering"

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

        if(length(settings$removeNA) == 0){
            settings$removeNA = FALSE
        }
        if(length(settings$scale) == 0){
            settings$scale = "column"
        }
        # Define default values
        settings$displayNumbers = FALSE
        settings$displayLegend = FALSE
        settings$displayColnames = FALSE
        settings$displayRownames = FALSE

        if(length(settings$displayOptions) > 0) {
            if("numbers" %in% settings$displayOptions){
                settings$displayNumbers = TRUE
            }
            if("legend" %in% settings$displayOptions){
                settings$displayLegend = TRUE
            }
            if("colnames" %in% settings$displayOptions){
                settings$displayColnames = TRUE
            }
            if("rownames" %in% settings$displayOptions){
                settings$displayRownames = TRUE
            }
        }

        if(length(settings$plotWidth) == 0){
            settings$plotWidth = 20
        }
        if(length(settings$plotRatio) == 0){
            settings$plotRatio = 0.8
        }
        if(length(settings$clustDistance) == 0){
            settings$clustDistance = "correlation"
        }
        if(length(settings$clustLinkage) == 0){
            settings$clustLinkage = "ward.D2"
        }
        if(length(settings$clustOrdering) == 0){
            settings$clustOrdering = 1
        }
        if(length(settings$fontSizeGeneral) == 0){
            settings$fontSizeGeneral = 10
        }
        if(length(settings$fontSizeRow) == 0){
            settings$fontSizeRow = 9
        }
        if(length(settings$fontSizeCol) == 0){
            settings$fontSizeCol = 9
        }
        if(length(settings$fontSizeNumbers) == 0){
            settings$fontSizeNumbers = 7
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
        fileHeader <- subset (fileHeader, select = -c(.id))



        fileHeader <- fileHeader %>% mutate(unique_count = as.numeric(unique_count)) %>% mutate(position = as.numeric(position))
        fileHeader$remapped = as.character(fileHeader$remapped)
        fileHeader$original = as.character(fileHeader$original)

        if(length(settings$selectedColumns) == 0) {
            selectedColumns <- fileHeader %>% arrange(unique_count) %>% slice(1) %>% arrange(position) %>% select(remapped)
            settings$selectedColumns <- tail(selectedColumns$remapped, 1)
        } 
        if(length(settings$selectedRows) == 0) {
            selectedRows <- fileHeader %>% arrange(unique_count) %>% slice(2:n()) %>% arrange(position) %>% select(remapped)
            settings$selectedRows <- tail(selectedRows$remapped, -1)
        }


        dataset <- data.table::fread(selectedFilePath, header = T, sep = ',', stringsAsFactors = FALSE, data.table = FALSE)
        dataset <- dataset[, names(dataset) %in% c(settings$selectedRows, settings$selectedColumns)]


        if(!is.null(settings$removeNA) & settings$removeNA == FALSE){
            preProcessedData <- preProcessData(dataset, settings$selectedColumns, settings$selectedColumns, methods = c("medianImpute", "center", "scale"))
            dataset <- preProcessedData$processedMat

            preProcessedData <- preProcessData(dataset, settings$selectedColumns, settings$selectedColumns,  methods = c("nzv", "zv"))
            dataset <- preProcessedData$processedMat
        }

        #save(dataset, file = "/tmp/dataset_pre_cor")
        #save(fileHeader, file = "/tmp/fileHeader")
        #save(settings, file = "/tmp/settings_cor")
        #save(dataset, file = "/tmp/dataset_cor")

        input_args <- c(list(data=dataset, 
                            fileHeader=fileHeader,
                            selectedColumns=settings$selectedColumns,
                            selectedRows=settings$selectedRows,
                            removeNA=settings$removeNA,
                            scale=settings$scale,
                            displayNumbers=settings$displayNumbers,
                            displayLegend=settings$displayLegend,
                            displayColnames=settings$displayColnames,
                            displayRownames=settings$displayRownames,
                            plotWidth=settings$plotWidth,
                            plotRatio=settings$plotRatio,
                            clustDistance=settings$clustDistance,
                            clustLinkage=settings$clustLinkage,
                            clustOrdering=settings$clustOrdering,
                            fontSizeGeneral=settings$fontSizeGeneral,
                            fontSizeRow=settings$fontSizeRow,
                            fontSizeCol=settings$fontSizeCol,
                            fontSizeNumbers=settings$fontSizeNumbers))

 
        process.execution <- tryCatch( garbage <- R.utils::captureOutput(results$data <- R.utils::withTimeout(do.call(plot.heatmap, input_args), timeout=300, onTimeout = "error") ), error = function(e){ return(e) } )
        if(!inherits(process.execution, "error") && !inherits(results$data, 'try-error') && !is.null(results$data)){
            results$status <- TRUE
        }else{
            if(inherits(results$data, 'try-error')){
                message <- base::geterrmessage()
                process.execution$message <- message
            }
            results$data <- process.execution$message
        }

        if(results$status == TRUE){

            tmp_path <- tempfile(pattern = plotUniqueHash, tmpdir = tempdir(), fileext = ".svg")
            svg(tmp_path, width = 24, height = 24, pointsize = 12, onefile = TRUE, family = "Arial", bg = "white", antialias = "default")
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

       return (list(status = results$status, image = results$image, image_png = results$image_png, dropped_columns = NULL, error_message = jsonlite::toJSON(results$data, force = TRUE)))
    }
)


