#* Plot out data from the iris dataset
#* @serializer contentType list(type='image/png')
#' @post /plots/heatmap/renderPlot
simon$handle$plots$heatmap$renderPlot <- expression(
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
            if(file.exists(cachedFile)){
                results$status <- TRUE
                results$image = as.character(RCurl::base64Encode(readBin(cachedFile, "raw", n = file.info(cachedFile)$size), "txt"))
                return(list(status = results$status, image = results$image))
            }
        }

        ## 1st - Get JOB and his Info from database
        resampleDetails <- db.apps.getFeatureSetData(resampleID)
        ## save(resampleDetails, file = "/tmp/testing.rds")

        if(length(settings$selectedColumns) == 0) {
            settings$selectedColumns <- tail(resampleDetails[[1]]$outcome$remapped, 2)
        }
        if(length(settings$selectedRows) == 0) {
            settings$selectedRows <- tail(resampleDetails[[1]]$features$remapped, 20)
        }

        resamplePath <- downloadDataset(resampleDetails[[1]]$remotePathMain)     
        data <- data.table::fread(resamplePath, header = T, sep = ',', stringsAsFactors = FALSE, data.table = FALSE)
        ## Remove all other than necessary selectedColumns
        data <- data[, names(data) %in% c(settings$selectedRows, settings$selectedColumns)]



        
        input_args <- c(list(data=data, 
                            resampleDetails=resampleDetails,
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
            svg(tmp_path, width = 8, height = 8, pointsize = 12, onefile = TRUE, family = "Arial", bg = "white", antialias = "default")
            print(results$data)
            dev.off()        

            ## Optimize SVG using svgo package
            system(paste0(which_cmd("svgo")," ",tmp_path," -o ",tmp_path), intern = TRUE, ignore.stdout = TRUE, ignore.stderr = TRUE, wait = TRUE)

            results$image = as.character(RCurl::base64Encode(readBin(tmp_path, "raw", n = file.info(tmp_path)$size), "txt"))
        }

       return(list(status = results$status, image = results$image))
    }
)


