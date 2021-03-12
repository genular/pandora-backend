#* Plot out data from the iris dataset
#* @serializer contentType list(type='image/png')
#' @post /plots/editing/heatmap/renderPlot
simon$handle$plots$editing$heatmap$renderPlot <- expression(
    function(req, res, ...){
        args <- as.list(match.call())
        response_data <- list(
            clustering_plot = NULL, clustering_plot_png = NULL, 
            saveObjectHash = NULL)


        selectedFileID <- 0
        if("selectedFileID" %in% names(args)){
            selectedFileID <- as.numeric(args$selectedFileID)
        }

        settings <- NULL
        if("settings" %in% names(args)){
            settings <- jsonlite::fromJSON(args$settings)
        }

        if(is_var_empty(settings$selectedColumns) == TRUE){
            settings$selectedColumns = NULL
        }

        if(is_var_empty(settings$selectedRows) == TRUE){
            settings$selectedRows = NULL
        }

        if(is_var_empty(settings$removeNA) == TRUE){
            settings$removeNA = TRUE
        }
        if(is_var_empty(settings$scale) == TRUE){
            settings$scale = "column"
        }
        # Define default values
        settings$displayNumbers = FALSE
        settings$displayLegend = FALSE
        settings$displayColnames = FALSE
        settings$displayRownames = FALSE

        if(is_var_empty(settings$displayOptions) == FALSE) {
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

        if(is_var_empty(settings$plotWidth) == TRUE){
            settings$plotWidth = 20
        }
        if(is_var_empty(settings$plotRatio) == TRUE){
            settings$plotRatio = 0.8
        }
        if(is_var_empty(settings$clustDistance) == TRUE){
            settings$clustDistance = "correlation"
        }
        if(is_var_empty(settings$clustLinkage) == TRUE){
            settings$clustLinkage = "ward.D2"
        }
        if(is_var_empty(settings$clustOrdering) == TRUE){
            settings$clustOrdering = 1
        }
        if(is_var_empty(settings$fontSizeGeneral) == TRUE){
            settings$fontSizeGeneral = 10
        }
        if(is_var_empty(settings$fontSizeRow) == TRUE){
            settings$fontSizeRow = 9
        }
        if(is_var_empty(settings$fontSizeCol) == TRUE){
            settings$fontSizeCol = 9
        }
        if(is_var_empty(settings$fontSizeNumbers) == TRUE){
            settings$fontSizeNumbers = 7
        }
        if(is_var_empty(settings$preProcessDataset) == TRUE){
            settings$preProcessDataset = NULL
        }

        plot_unique_hash <- list(
            clustering_plot = digest::digest(paste0(selectedFileID, "_",args$settings,"_editing_clustering_plot"), algo="md5", serialize=F), 
            saveObjectHash = digest::digest(paste0(selectedFileID, "_",args$settings,"_editing_clustering_render_plot"), algo="md5", serialize=F)
        )
        
        resp_check <- getPreviouslySavedResponse(plot_unique_hash, response_data, 3)
        if(is.list(resp_check)){
            return(resp_check)
        }

        ## 1st - Get JOB and his Info from database
        selectedFileDetails <- db.apps.getFileDetails(selectedFileID)
        selectedFilePath <- downloadDataset(selectedFileDetails[1,]$file_path)

        fileHeader <- jsonlite::fromJSON(selectedFileDetails[1,]$details)
        fileHeader <- plyr::ldply (fileHeader$header$formatted, data.frame)
        fileHeader <- subset (fileHeader, select = -c(.id))

        fileHeader <- fileHeader %>% mutate(unique_count = as.numeric(unique_count)) %>% mutate(position = as.numeric(position))
        fileHeader$remapped = as.character(fileHeader$remapped)
        fileHeader$original = as.character(fileHeader$original)

        dataset <- data.table::fread(selectedFilePath, header = T, sep = ',', stringsAsFactors = FALSE, data.table = FALSE)

        if(is_null(settings$selectedColumns)) {
            print("Selected Columns are not set, taking initial ones")
            selectedColumns <- fileHeader %>% arrange(unique_count) %>% slice(1) %>% arrange(position) %>% select(remapped)
            settings$selectedColumns <- tail(selectedColumns$remapped, 1)
        } 
        if(is_null(settings$selectedRows)) {
            print("Selected Rows are not set, taking initial ones")
            selectedRows <- fileHeader %>% arrange(unique_count) %>% slice(2:n()) %>% arrange(position) %>% select(remapped)
            settings$selectedRows <- tail(selectedRows$remapped, -1)
        }
        settings$selectedRows <-  setdiff(settings$selectedRows, settings$selectedColumns)

        #print("===============> Selected columns")
        #print(settings$selectedColumns)
        #print("===============> Selected selectedRows")
        #print(settings$selectedRows)
        dataset <- dataset[, names(dataset) %in% c(settings$selectedRows, settings$selectedColumns)]

        if(!is.null(settings$preProcessDataset)){
            #print("===============> DATASET PREPROCESS")
            preProcessedData <- preProcessData(dataset, settings$selectedColumns, settings$selectedColumns, methods = c("medianImpute", "center", "scale"))
            dataset_filtered <- preProcessedData$processedMat

            preProcessedData <- preProcessData(dataset_filtered, settings$selectedColumns, settings$selectedColumns,  methods = c("nzv", "zv"))
            dataset_filtered <- preProcessedData$processedMat
        }else{
            dataset_filtered <- dataset
        }

        if(settings$removeNA == TRUE){
            #print("===============> DATASET na.omit")
            dataset_filtered <- na.omit(dataset_filtered)
        }

        #save(dataset_filtered, file = "/tmp/dataset_filtered")

        input_args <- c(list(data=dataset_filtered, 
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


        clustering_out <- FALSE
        clustering_out_status <- FALSE

        process.execution <- tryCatch( garbage <- R.utils::captureOutput(clustering_out <- R.utils::withTimeout(do.call(plot.heatmap, input_args), timeout=300, onTimeout = "error") ), error = function(e){ return(e) } )
        if(!inherits(process.execution, "error") && !inherits(clustering_out, 'try-error') && !is.null(clustering_out)){
            clustering_out_status <- TRUE
        }else{
            if(inherits(clustering_out, 'try-error')){
                message <- base::geterrmessage()
                process.execution$message <- message
            }
            clustering_out <- process.execution$message
        }

        if(clustering_out_status == TRUE){
            print("Plotting clustering plot")
            tmp_path <- tempfile(pattern =  plot_unique_hash[["clustering_plot"]], tmpdir = tempdir(), fileext = ".svg")
            svg(tmp_path, width = 24, height = 24, pointsize = 12, onefile = TRUE, family = "Arial", bg = "white", antialias = "default")
                print(clustering_out)
            dev.off()        

            ## Optimize SVG using svgo package
            tmp_path_png <- stringr::str_replace(tmp_path, ".svg", ".png")
            png_cmd <- paste0(which_cmd("rsvg-convert")," ",tmp_path," -f png -o ",tmp_path_png)
            convert_cmd <- paste0(which_cmd("svgo")," ",tmp_path," -o ",tmp_path, " && ", png_cmd)

            system(convert_cmd, intern = TRUE, ignore.stdout = TRUE, ignore.stderr = TRUE, wait = TRUE)

            svg_data <- readBin(tmp_path, "raw", n = file.info(tmp_path)$size)
            response_data$clustering_plot = as.character(RCurl::base64Encode(svg_data, "txt"))
            response_data$clustering_plot_png = as.character(RCurl::base64Encode(readBin(tmp_path_png, "raw", n = file.info(tmp_path_png)$size), "txt"))
        }

        ## save data for latter use
        tmp_path <- tempfile(pattern = plot_unique_hash[["saveObjectHash"]], tmpdir = tempdir(), fileext = ".Rdata")
        processingData <- list(
            input_args = input_args,
            clustering_out = clustering_out,
            settings = settings,
            dataset = dataset,
            dataset_filtered_processed = dataset_filtered
        )
        saveCachedList(tmp_path, processingData)
        response_data$saveObjectHash = substr(basename(tmp_path), 1, nchar(basename(tmp_path))-6)

        return (list(success = TRUE, message = response_data))
    }
)


