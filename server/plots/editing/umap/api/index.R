#* Generate umap plot
#* @serializer contentType list(type='image/png')
#' @post /plots/editing/umap/renderPlot
pandora$handle$plots$editing$umap$renderPlot <- expression(
    function(req, res, ...){
        args <- as.list(match.call())

        start_time <- Sys.time()
        message("==> Start rendering UMAP plot")

        res.data <- list(
            umap_plot = list(
                main_plot =  list(name = NULL, train = NULL)
            )
        )

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
        if(is_var_empty(settings$cutOffColumnSize) == TRUE){
            settings$cutOffColumnSize = 50000
        }
        if(is_var_empty(settings$excludedColumns) == TRUE){
            settings$excludedColumns = NULL
        }
        if(is_var_empty(settings$groupingVariables) == TRUE){
            settings$groupingVariables = NULL
        }
        if(is_var_empty(settings$preProcessDataset) == TRUE){
            settings$preProcessDataset = NULL
        }
        if(is_var_empty(settings$fontSize) == TRUE){
            settings$fontSize <- 12
        }
        if(is_var_empty(settings$theme) == TRUE){
            settings$theme <- "theme_gray"
        }
        if(is_var_empty(settings$colorPalette) == TRUE){
            settings$colorPalette <- "RdPu"
        }
        if(is_var_empty(settings$aspect_ratio) == TRUE){
            settings$aspect_ratio <- 1
        }
        if(is_var_empty(settings$removeNA) == TRUE){
            settings$removeNA = TRUE
        }
        if(is_var_empty(settings$plot_size) == TRUE){
            settings$plot_size <- 12
        }
        if(is_var_empty(settings$selectedPartitionSplit) == TRUE){
            settings$selectedPartitionSplit <- 85
        }
        if(is_var_empty(settings$knn_clusters) == TRUE){
            settings$knn_clusters <- 2
        }
        if(is_var_empty(settings$pca_clusters) == TRUE){
            settings$pca_clusters <- 25
        }
        if(is_var_empty(settings$includeOtherGroups) == TRUE){
            settings$includeOtherGroups <- FALSE
        }
        if(is_var_empty(settings$anyNAValues) == TRUE){
            settings$anyNAValues <- FALSE
        }
        if(is_var_empty(settings$categoricalVariables) == TRUE){
            settings$categoricalVariables <- FALSE
        }

        plot_unique_hash <- list(
            umap_plot = list(
                main_plot = list(
                    train = digest::digest(paste0(selectedFileID, "_",args$settings,"_umap_plot_main_plot_train"), algo="md5", serialize=F)
                )
            ),

            saveObjectHash = digest::digest(paste0(selectedFileID, "_",args$settings,"_editing_umap_render_plot"), algo="md5", serialize=F)
        )

        if(!is.null(settings$groupingVariables)){
            for(groupVariable in settings$groupingVariables){
                res.data$umap_plot[[groupVariable]] <- list(name = NULL, train = NULL, test = NULL, text = NULL)

                plot_unique_hash$umap_plot[[groupVariable]]$train <- digest::digest(paste0(selectedFileID, "_",args$settings,"_umap_plot_train",groupVariable), algo="md5", serialize=F)
                plot_unique_hash$umap_plot[[groupVariable]]$test <- digest::digest(paste0(selectedFileID, "_",args$settings,"_umap_plot_test",groupVariable), algo="md5", serialize=F)
            }
        }
        #resp_check <- getPreviouslySavedResponse(plot_unique_hash, res.data, 5)
        #if(is.list(resp_check)){
        #   print("==> Serving request response from cache")
        #    return(resp_check)
        #}

        # Step 1 - Get file details from database
        message("==> Retrieving file details from database")
        db_time <- Sys.time()

        selectedFileDetails <- db.apps.getFileDetails(selectedFileID)
        ## save(selectedFileDetails, file = "/tmp/testing.rds")
        selectedFilePath <- downloadDataset(selectedFileDetails[1,]$file_path)
        message("==> Retrieved file details in ", Sys.time() - db_time)

        # Step 2 - Process file header
        message("==> Processing file header")
        header_time <- Sys.time()
        fileHeader <- jsonlite::fromJSON(selectedFileDetails[1,]$details)
        fileHeader <- plyr::ldply (fileHeader$header$formatted, data.frame)
        fileHeader <- subset (fileHeader, select = -c(.id))

        fileHeader <- fileHeader %>% mutate(unique_count = as.numeric(unique_count)) %>% mutate(position = as.numeric(position))
        fileHeader$remapped = as.character(fileHeader$remapped)
        fileHeader$original = as.character(fileHeader$original)
        message("==> Processed file header in ", Sys.time() - header_time)

        # Step 3 - Filter grouping variables in settings
        message("==> Filtering grouping variables")
        group_time <- Sys.time()
        if(!is.null(settings$groupingVariables)){
            settings$groupingVariables <- fileHeader %>% filter(remapped %in% settings$groupingVariables)
            settings$groupingVariables <- settings$groupingVariables$remapped
        }

        # If no columns are selected, select by cut of size
        if(is_null(settings$selectedColumns)) {
            selectedColumns <- fileHeader %>% arrange(unique_count) %>% arrange(position) %>% select(remapped)
            settings$selectedColumns <- tail(selectedColumns$remapped, n=settings$cutOffColumnSize)
        }

        # Remove grouping variables from selectedColumns and excludedColumns
        if(!is_null(settings$groupingVariables)) {
            if(is_null(settings$selectedColumns)) {
                settings$selectedColumns <-  setdiff(settings$selectedColumns, settings$groupingVariables)
            }
            if(is_null(settings$excludedColumns)) {
                settings$excludedColumns <-  setdiff(settings$excludedColumns, settings$groupingVariables)
            }
            if(is_null(settings$colorVariables)) {
                settings$colorVariables <-  setdiff(settings$colorVariables, settings$groupingVariables)
            }
        }

        # Remove any excluded columns from selected columns
        if(!is_null(settings$excludedColumns)) {
            ## Remove excluded from selected columns
            settings$selectedColumns <-  setdiff(settings$selectedColumns, settings$excludedColumns)
            # settings$selectedColumns <- settings$selectedColumns[settings$selectedColumns %!in% settings$excludedColumns]
        }
        message("==> Grouping variables filtered in ", Sys.time() - group_time)

        # Step 4 - Load dataset
        message("==> Loading dataset")
        load_data_time <- Sys.time()
        dataset <- loadDataFromFileSystem(selectedFilePath, header = TRUE, sep = ',', stringsAsFactors = FALSE, data.table = FALSE, retype = FALSE)
        dataset_filtered <- dataset[, names(dataset) %in% c(settings$selectedColumns, settings$groupingVariables)]
        message("==> Dataset loaded in ", Sys.time() - load_data_time)

        num_test <- dataset_filtered %>% select(where(is.numeric))
        for (groupVariable in settings$groupingVariables) {
            if(groupVariable %in% names(num_test)){
                dataset_filtered[[groupVariable]] <-paste("g",dataset_filtered[[groupVariable]],sep="_")
            }
        }
        
        # Step 5 - Preprocess dataset if required
        if(!is.null(settings$preProcessDataset) && length(settings$preProcessDataset) > 0){
            message("==> Preprocessing dataset")
            preprocess_time <- Sys.time()
            preProcessMapping <- preProcessResample(dataset_filtered, settings$preProcessDataset, settings$groupingVariables, settings$groupingVariables)
            dataset_filtered <- preProcessMapping$datasetData
            message("==> Dataset preprocessed in ", Sys.time() - preprocess_time)
        }

        # Step 6 - Remove NA values if specified
        if(settings$removeNA == TRUE){
            message("==> Removing NA values")
            na_time <- Sys.time()
            dataset_filtered <- na.omit(dataset_filtered)
            message("==> NA values removed in ", Sys.time() - na_time)
        }

        if(nrow(dataset_filtered) <= 2) {
            print("==> No enough rows to proceed with PCA analysis")
            return (list(success = FALSE, message = FALSE, details = FALSE))
        }

        if(settings$selectedPartitionSplit < 100){
            if(!is.null(settings$groupingVariables)){
                data_training <- list()
                data_testing <- list()
                groupingVariables <- settings$groupingVariables
                for(groupVariable in groupingVariables){
                    print(paste0("=====> Creating data partitions grouping variable: ", groupVariable))
                    if(groupVariable %in% names(dataset_filtered)){
                        selectedPartitionSplit <- settings$selectedPartitionSplit
                        props <- table(dataset_filtered[[groupVariable]])

                        for (prop in props) {
                            check <- (as.numeric(prop) / length(dataset_filtered[[groupVariable]]) * 100)
                            if(check > selectedPartitionSplit){
                                selectedPartitionSplit <- floor(round(check, digits = 0))
                                print(paste0("=====> Creating data partitions percentage: ", selectedPartitionSplit))
                            }
                        }
                        selectedPartitionSplit <- (selectedPartitionSplit / 100)

                        partition_data <- createDataPartitions(dataset_filtered, groupVariable, selectedPartitionSplit)

                        data_training[[groupVariable]] <- partition_data$training
                        data_testing[[groupVariable]] <- partition_data$testing

                        res.data$umap_plot[[groupVariable]]$text <- paste0("Partition split: ", selectedPartitionSplit, ". Total rows in Training: ", nrow(partition_data$training), ". Total rows in Testing: ", nrow(partition_data$testing))

                    }else{
                        settings$groupingVariables <- setdiff(groupingVariables, groupVariable)
                    }
                }
            }
        }else{
            data_training <- dataset_filtered
        }

        # Step 7 - Calculate and plot UMAP
        message("==> Calculating UMAP")
        umap_calc_time <- Sys.time()

        umap_calc <- list()
        ## Calculate umap
        umap_calc[["main_plot"]] <- calculate_umap(dataset_filtered, NULL, settings, fileHeader)
        message("==> UMAP calculation and plot completed in ", Sys.time() - umap_calc_time)

        ## Plot umap
        tmp_path <- plot_umap(umap_calc[["main_plot"]]$umap_data, umap_calc[["main_plot"]]$pca_result, umap_calc[["main_plot"]]$dataset, "train", NULL, settings, fileHeader,  plot_unique_hash$umap_plot[["main_plot"]]$train)
        

        res.data$umap_plot[["main_plot"]]$name <- "Main Plot"
        res.data$umap_plot[["main_plot"]]$train <- list(
            svg = optimizeSVGFile(tmp_path),
            png = convertSVGtoPNG(tmp_path)
        )

        if(!is.null(settings$groupingVariables)){
            for(groupVariable in settings$groupingVariables){
                message("==> Calculating UMAP for grouping variable: ", groupVariable)
                group_var_time <- Sys.time()

                groupingVariable <- fileHeader %>% filter(remapped %in% groupVariable)
                groupingVariable <- groupingVariable$original

                ## Calculate only umap for each group on whole data without testing step
                if(settings$selectedPartitionSplit < 100){
                    umap_train_dataset <- data_training[[groupVariable]]
                }else{
                    umap_train_dataset <- dataset_filtered
                }

                ## Calculate umap for each target data for supervised dimension reduction
                umap_calc[[groupVariable]] <- calculate_umap(umap_train_dataset, groupingVariable, settings, fileHeader)
                tmp_path <- plot_umap(umap_calc[[groupVariable]]$umap_data, umap_calc[[groupVariable]]$pca_result, umap_calc[[groupVariable]]$dataset, "train", groupingVariable, settings, fileHeader,  plot_unique_hash$umap_plot[[groupVariable]]$train)

                res.data$umap_plot[[groupVariable]]$name <- groupingVariable
                res.data$umap_plot[[groupVariable]]$train <- list(
                    svg = optimizeSVGFile(tmp_path),
                    png = convertSVGtoPNG(tmp_path)
                )

                if(settings$selectedPartitionSplit < 100){
                    tmp_path <- plot_umap(umap_calc[[groupVariable]]$umap_data, umap_calc[[groupVariable]]$pca_result, data_testing[[groupVariable]], "test", groupingVariable, settings, fileHeader,  plot_unique_hash$umap_plot[[groupVariable]]$test)
                    res.data$umap_plot[[groupVariable]]$name <- groupingVariable
                    res.data$umap_plot[[groupVariable]]$test <- list(
                        svg = optimizeSVGFile(tmp_path),
                        png = convertSVGtoPNG(tmp_path)
                    )
                }
                message("==> Completed UMAP for grouping variable ", groupVariable, " in ", Sys.time() - group_var_time)
            }
        }

        # Step 9 - Cache processed data
        message("==> Caching processed data")
        cache_time <- Sys.time()
        
        tmp_path <- tempfile(pattern = plot_unique_hash[["saveObjectHash"]], tmpdir = tempdir(), fileext = ".Rdata")
        processingData <- list(
            umap_calc = umap_calc,
            dataset_filtered = dataset_filtered,
            data_training = data_training,
            settings = settings,
            fileHeader = fileHeader,
            plot_unique_hash = plot_unique_hash

        )
        saveCachedList(tmp_path, processingData)
        res.data$saveObjectHash = substr(basename(tmp_path), 1, nchar(basename(tmp_path))-6)
        message("==> Caching completed in ", Sys.time() - cache_time)

        end_time <- Sys.time()
        message("==> UMAP plot rendering completed in ", end_time - start_time)

        return (list(success = TRUE, message = res.data))
    }
)
