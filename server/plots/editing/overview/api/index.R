#* Get available column stats
#* @serializer contentType list(type='image/png')
#' @post /plots/editing/overview/getAvaliableColumns
pandora$handle$plots$editing$overview$getAvaliableColumns <- expression(
    function(req, res, ...){
        args <- as.list(match.call())

        response_data <- list(
            columns = NULL,
            summary = NULL, 
            saveObjectHash = NULL
        )

        selectedFileID <- 0
        if("selectedFileID" %in% names(args)){
            selectedFileID <- as.numeric(args$selectedFileID)
        }
        settings <- NULL
        if("settings" %in% names(args)){
            settings <- jsonlite::fromJSON(args$settings)
        }

        plot_unique_hash <- list(
            columns = digest::digest(paste0(selectedFileID, "_",args$settings,"_editing_overview_getAvaliableColumns_columns"), algo="md5", serialize=F), 
            summary = digest::digest(paste0(selectedFileID, "_",args$settings,"_editing_overview_getAvaliableColumns_summary"), algo="md5", serialize=F), 
            saveObjectHash = digest::digest(paste0(selectedFileID, "_",args$settings,"_editing_overview_getAvaliableColumns_hash"), algo="md5", serialize=F)
        )

        resp_check <- getPreviouslySavedResponse(plot_unique_hash, response_data, 3)
        if(is.list(resp_check)){
            # return(resp_check)
        }

        # Step 2 - Retrieve File Details
        message("==> Step 2: Retrieving file details")
        step_time <- Sys.time()
        selectedFileDetails <- db.apps.getFileDetails(selectedFileID)
        selectedFilePath <- downloadDataset(selectedFileDetails[1,]$file_path)
        message("==> Completed Step 2: File details retrieved in ", Sys.time() - step_time)


        # Step 3 - Process File Header
        message("==> Step 3: Processing file header")
        step_time <- Sys.time()
        fileHeader <- jsonlite::fromJSON(selectedFileDetails[1,]$details)
        fileHeader <- plyr::ldply(fileHeader$header$formatted, data.frame)
        fileHeader <- subset(fileHeader, select = -c(.id))
        fileHeader <- fileHeader %>% mutate(
            unique_count = as.numeric(unique_count), 
            position = as.numeric(position),
            remapped = as.character(remapped), 
            original = as.character(original)
        )
        message("==> Completed Step 3: File header processed in ", Sys.time() - step_time)


        # Step 4 - Load Dataset
        message("==> Step 4: Loading dataset")
        step_time <- Sys.time()
        dataset <- loadDataFromFileSystem(selectedFilePath, header = T, sep = ',', stringsAsFactors = FALSE, data.table = FALSE, retype = FALSE)
        message("==> Completed Step 4: Dataset loaded in ", Sys.time() - step_time)


       # Step 5 - Filter Columns
        message("==> Step 5: Filtering columns")
        step_time <- Sys.time()
        col_check <- dataset[, sapply(dataset, is.numeric)]
        valid_numeric <- names(col_check)
        col_check <- col_check[, !apply(col_check, MARGIN = 2, function(x) max(x, na.rm = TRUE) == min(x, na.rm = TRUE))]
        valid_zv <- names(col_check)
        
        col_check <- sapply(seq(1, ncol(dataset)), function(i) {
            unique_values_count <- length(unique(dataset[, i]))
            total_values_count <- nrow(dataset)
            unique_values_count < total_values_count / 10 || 
            (unique_values_count >= 2 && unique_values_count <= 5 && total_values_count <= 25)
        })
        valid_10p <- names(dataset[, col_check, drop = FALSE])
        message("==> Completed Step 5: Columns filtered in ", Sys.time() - step_time)


        # Step 6 - Calculate NA Percentage
        message("==> Step 6: Calculating NA percentage")
        step_time <- Sys.time()
        na_percentage <- purrr::map(dataset, ~mean(is.na(.)))
        na_percentage <- data.frame(t(sapply(unlist(na_percentage), c)))
        na_percentage <- reshape2::melt(na_percentage)
        na_percentage$value <- round(na_percentage$value, digits = 2)
        message("==> Completed Step 6: NA percentage calculated in ", Sys.time() - step_time)

        # Step 7 - Prepare Response Data
        message("==> Step 7: Preparing response data")
        step_time <- Sys.time()
        response_data$columns <- fileHeader %>%
            mutate(
                valid_numeric = if_else(remapped %in% valid_numeric, 1, 0),
                valid_zv = if_else(remapped %in% valid_zv, 1, 0),
                valid_10p = if_else(remapped %in% valid_10p, 1, 0),
                na_percentage = na_percentage[na_percentage$variable == remapped, ]$value
            ) %>% arrange(desc(valid_10p))
        message("==> Completed Step 7: Response data prepared in ", Sys.time() - step_time)



        tmp_path <- tempfile(pattern = plot_unique_hash[["columns"]], tmpdir = tempdir(), fileext = ".RDS")
        saveCachedList(tmp_path, response_data$columns)

        tmp_path <- tempfile(pattern = plot_unique_hash[["saveObjectHash"]], tmpdir = tempdir(), fileext = ".Rdata")
        processingData <- list(
            columns = response_data$columns,
            settings = settings,
            fileHeader = fileHeader
        )
        saveCachedList(tmp_path, processingData)
        response_data$saveObjectHash = substr(basename(tmp_path), 1, nchar(basename(tmp_path))-6)

        return (list(success = TRUE, message = response_data))
    }
)


#* Plot tableplot
#* @serializer contentType list(type='image/png')
#' @post /plots/editing/overview/render-plot
pandora$handle$plots$editing$overview$renderPlot <- expression(
    function(req, res, ...){
        args <- as.list(match.call())
        start_time <- Sys.time()
        message("==> Step 1: Function start at ", start_time)

        response_data <- list(
            table_plot = NULL, table_plot_png = NULL, 
            distribution_plot = NULL, distribution_plot_png = NULL,
            saveObjectHash = NULL)

        selectedFileID <- if("selectedFileID" %in% names(args)) as.numeric(args$selectedFileID) else 0
        settings <- if("settings" %in% names(args)) jsonlite::fromJSON(args$settings) else NULL

        # Default settings
        settings$selectedColumns <- if(is_var_empty(settings$selectedColumns)) NULL else settings$selectedColumns
        settings$cutOffColumnSize <- if(is_var_empty(settings$cutOffColumnSize)) 50 else settings$cutOffColumnSize
        settings$groupingVariable <- if(is_var_empty(settings$groupingVariable)) NULL else settings$groupingVariable
        settings$preProcessDataset <- if(is_var_empty(settings$preProcessDataset)) NULL else settings$preProcessDataset
        settings$fontSize <- if(is_var_empty(settings$fontSize)) 12 else settings$fontSize
        settings$theme <- if(is_var_empty(settings$theme)) "theme_gray" else settings$theme
        settings$colorPalette <- if(is_var_empty(settings$colorPalette)) "RdPu" else settings$colorPalette
        settings$aspect_ratio <- if(is_var_empty(settings$aspect_ratio)) 1 else settings$aspect_ratio

        # Step 2 - Generate unique hashes for caching
        message("==> Step 2: Generating unique hashes")
        step_time <- Sys.time()
        plot_unique_hash <- list(
            table_plot = digest::digest(paste0(selectedFileID, "_",args$settings,"_table_plot"), algo="md5", serialize=F), 
            distribution_plot = digest::digest(paste0(selectedFileID, "_",args$settings,"_distribution_plot"), algo="md5", serialize=F),
            saveObjectHash = digest::digest(paste0(selectedFileID, "_",args$settings,"_editing_overview_render_plot"), algo="md5", serialize=F)
        )
        message("==> Completed Step 2: Hash generation took ", Sys.time() - step_time)

        # Step 3 - Check cached response
        message("==> Step 3: Checking cache")
        step_time <- Sys.time()
        resp_check <- getPreviouslySavedResponse(plot_unique_hash, response_data, 5)
        if(is.list(resp_check)){
            message("==> Serving request from cache")
            return(resp_check)
        }
        message("==> Completed Step 3: Cache check took ", Sys.time() - step_time)

        # Step 4 - Get file details
        message("==> Step 4: Retrieving file details")
        step_time <- Sys.time()
        selectedFileDetails <- db.apps.getFileDetails(selectedFileID)
        selectedFilePath <- downloadDataset(selectedFileDetails[1,]$file_path)
        message("==> Completed Step 4: File details retrieval took ", Sys.time() - step_time)

        # Step 5 - Process file header
        message("==> Step 5: Processing file header")
        step_time <- Sys.time()
        fileHeader <- jsonlite::fromJSON(selectedFileDetails[1,]$details)
        fileHeader <- plyr::ldply(fileHeader$header$formatted, data.frame) %>%
            subset(select = -c(.id)) %>%
            mutate(unique_count = as.numeric(unique_count), position = as.numeric(position),
                   remapped = as.character(remapped), original = as.character(original))
        message("==> Completed Step 5: File header processing took ", Sys.time() - step_time)

        # Step 6 - Load dataset
        message("==> Step 6: Loading dataset")
        step_time <- Sys.time()
        dataset <- loadDataFromFileSystem(selectedFilePath, header = TRUE, sep = ',', stringsAsFactors = FALSE, data.table = FALSE, retype = FALSE)
        message("==> Completed Step 6: Dataset loading took ", Sys.time() - step_time)

        # Step 7 - Prepare columns and grouping variable
        message("==> Step 7: Preparing columns and grouping variable")
        step_time <- Sys.time()
        if(!is_null(settings$groupingVariable)){
            settings$groupingVariable <- fileHeader %>% filter(remapped %in% settings$groupingVariable) %>% pull(remapped)
        }
        if(is_null(settings$selectedColumns)) {
            selectedColumns <- fileHeader %>% arrange(unique_count) %>% slice(settings$cutOffColumnSize) %>% arrange(position) %>% select(remapped)
            settings$selectedColumns <- tail(selectedColumns$remapped, settings$cutOffColumnSize)
        }
        message("==> Completed Step 7: Columns and grouping preparation took ", Sys.time() - step_time)

        # Step 8 - Filter and preprocess dataset
        message("==> Step 8: Filtering and preprocessing dataset")
        step_time <- Sys.time()
        dataset_filtered <- dataset[, names(dataset) %in% c(settings$selectedColumns, settings$groupingVariable)]
        if(!is.null(settings$preProcessedData)){
            preProcessedData <- preProcessData(dataset_filtered, NULL , NULL, methods = c("medianImpute", "center", "scale"))
            if(!is.null(preProcessedData$processedMat)){
                dataset_filtered <- preProcessedData$processedMat
            }
        }
        message("==> Completed Step 8: Dataset filtering/preprocessing took ", Sys.time() - step_time)

        # Step 9 - Render table plot
        message("==> Step 9: Rendering table plot")
        step_time <- Sys.time()
        rendered_plot_tableplot <- plot_tableplot(dataset_filtered, settings, fileHeader)
        if(rendered_plot_tableplot$status == TRUE){
            tmp_path <- tempfile(pattern = plot_unique_hash[["table_plot"]], tmpdir = tempdir(), fileext = ".svg")
            save_tableplot_info <- save_tableplot(rendered_plot_tableplot$data, tmp_path, settings)
            if(save_tableplot_info$status == TRUE){
                response_data$table_plot = optimizeSVGFile(tmp_path)
                response_data$table_plot_png =  convertSVGtoPNG(tmp_path)
            }
        }
        message("==> Completed Step 9: Table plot rendering took ", Sys.time() - step_time)

        # Step 10 - Render distribution plot
        message("==> Step 10: Rendering distribution plot")
        step_time <- Sys.time()
        rendered_plot_matrix <- plot_matrix_plot(dataset_filtered, settings, fileHeader)
        if(!is.null(rendered_plot_matrix)){
            tmp_path <- tempfile(pattern = plot_unique_hash[["distribution_plot"]], tmpdir = tempdir(), fileext = ".svg")
            message("==> Saving distribution plot to ", tmp_path)
            
            svg(tmp_path, width = 12 * settings$aspect_ratio, height = 12, pointsize = 12, onefile = TRUE, family = "Arial", bg = "white", antialias = "default")
                print(rendered_plot_matrix)
            dev.off()
            
            message("==> Optimizing SVG file")
            response_data$distribution_plot = optimizeSVGFile(tmp_path)
            message("==> Converting SVG to PNG")
            response_data$distribution_plot_png = convertSVGtoPNG(tmp_path)
        }
        message("==> Completed Step 10: Distribution plot rendering took ", Sys.time() - step_time)

        # Step 11 - Save cached data
        message("==> Step 11: Caching data")
        step_time <- Sys.time()
        tmp_path <- tempfile(pattern = plot_unique_hash[["saveObjectHash"]], tmpdir = tempdir(), fileext = ".Rdata")
        processingData <- list(
            plot_tableplot = if (exists("rendered_plot_tableplot") && length(rendered_plot_tableplot) > 0) rendered_plot_tableplot else FALSE,
            plot_matrix = if (exists("rendered_plot_matrix") && length(rendered_plot_matrix) > 0) rendered_plot_matrix else FALSE,
            settings = if (exists("settings") && length(settings) > 0) settings else FALSE,
            dataset_filtered_processed = if (exists("dataset_filtered") && length(dataset_filtered) > 0) dataset_filtered else FALSE
        )
        saveCachedList(tmp_path, processingData)
        response_data$saveObjectHash = substr(basename(tmp_path), 1, nchar(basename(tmp_path)) - 6)
        message("==> Completed Step 11: Data caching took ", Sys.time() - step_time)

        # Final Step - Return response
        end_time <- Sys.time()
        total_time <- end_time - start_time
        message("==> Function completed in total time: ", total_time)

        return(list(success = TRUE, message = response_data))
    }
)
