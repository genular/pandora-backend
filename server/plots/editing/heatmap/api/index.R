#* Plot out data from the iris dataset
#* @serializer contentType list(type='image/png')
#' @post /plots/editing/heatmap/renderPlot
pandora$handle$plots$editing$heatmap$renderPlot <- expression(
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
            print("==> Serving request response from cache")
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

        dataset <- loadDataFromFileSystem(selectedFilePath)

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

        num_test <- dataset %>% select(where(is.numeric))
        for (groupVariable in settings$selectedColumns) {
            if(groupVariable %in% names(num_test)){
                dataset[[groupVariable]] <-paste("g",dataset[[groupVariable]],sep="_")
            }
        }

        dataset_filtered <- dataset
        print(paste("==> Selected Columns 4: ", length(settings$selectedColumns), " Dataset columns:",ncol(dataset_filtered)))
        if(!is.null(settings$preProcessDataset) && length(settings$preProcessDataset) > 0){
            ## Preprocess data except grouping variables

            # if(settings$categoricalVariables == TRUE){
            #     ## settings$preProcessDataset <- c("medianImpute")
            # }
            print(paste0("=====> Preprocessing dataset: ", paste(settings$preProcessDataset, collapse = ", ")))

            ## Preprocess resample data
            preProcessMapping <- preProcessResample(dataset_filtered, 
                settings$preProcessDataset, 
                settings$groupingVariables, 
                settings$groupingVariables)

            dataset_filtered <- preProcessMapping$datasetData

            print(paste("==> Selected Columns 4.1: ", length(settings$selectedColumns), " Dataset columns: ",ncol(dataset_filtered), " Dataset rows: ", nrow(dataset_filtered)))
        }

        if(settings$removeNA == TRUE){
            dataset_filtered <- na.omit(dataset_filtered)
        }

        if (settings$datasetAnalysisGrouped == TRUE) {

            group_column <- settings$datasetAnalysisGroupedColumn
            # Ensure the grouping column exists in the dataset
            if (!(group_column %in% colnames(dataset_filtered))) {
                print(paste0("Error: Column '", group_column, "' does not exist in dataset_filtered."))
            }else{
                print(paste0("Grouping dataset by column '", group_column, "'"))
                dataset_filtered <- dataset_filtered %>%
                    group_by(across(all_of(group_column))) %>%
                    summarise(across(everything(), ~ mean(.x, na.rm = TRUE)), .groups = 'drop')
    
                dataset_filtered <- as.data.frame(dataset_filtered)
                settings$scale <- "row"
            }
        }


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
            print("===> Plotting clustering plot")
            tmp_path <- tempfile(pattern =  plot_unique_hash[["clustering_plot"]], tmpdir = tempdir(), fileext = ".svg")
            svg(tmp_path, width = 24, height = 24, pointsize = 12, onefile = TRUE, family = "Arial", bg = "white", antialias = "default")
                print(clustering_out)
            dev.off()        

            response_data$clustering_plot = optimizeSVGFile(tmp_path)
            response_data$clustering_plot_png = convertSVGtoPNG(tmp_path)

        }else{
            print("===> Error while plot.heatmap")
            print("=============> Columns used in clustering")
            header_mapped <- fileHeader %>% filter(remapped %in% names(dataset_filtered))
            print(header_mapped$original)
            print("=============> Clustering output:")
            print(clustering_out)
        }

        ## save data for latter use
        tmp_path <- tempfile(pattern = plot_unique_hash[["saveObjectHash"]], tmpdir = tempdir(), fileext = ".Rdata")
        processingData <- list(
            input_args = ifelse(exists("input_args"), input_args, FALSE),
            clustering_out = ifelse(exists("clustering_out"), clustering_out, FALSE),
            settings = ifelse(exists("settings"), settings, FALSE),
            dataset = ifelse(exists("dataset"), dataset, FALSE),
            dataset_filtered_processed = ifelse(exists("dataset_filtered"), dataset_filtered, FALSE)
        )
        saveCachedList(tmp_path, processingData)
        response_data$saveObjectHash = substr(basename(tmp_path), 1, nchar(basename(tmp_path))-6)

        return (list(success = TRUE, message = response_data))
    }
)


