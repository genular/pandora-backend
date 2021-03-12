#* Get available column stats
#* @serializer contentType list(type='image/png')
#' @post /plots/editing/overview/getAvaliableColumns
simon$handle$plots$editing$overview$getAvaliableColumns <- expression(
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

        ## Load dataset
        dataset <- data.table::fread(selectedFilePath, header = T, sep = ',', stringsAsFactors = FALSE, data.table = FALSE)

        # we only want to show numeric cols
        valid_numeric <- NULL
        # exclude cols with zero variance
        valid_zv <- NULL
        # Unique values are less than 10% the number of observations
        valid_10p <- NULL

        col_check <- dataset[,sapply(dataset,is.numeric)]
        valid_numeric <- names(col_check)
        col_check <- col_check[,!apply(col_check, MARGIN = 2, function(x) max(x, na.rm = TRUE) == min(x, na.rm = TRUE))]
        valid_zv <- names(col_check)

        col_check <- sapply(seq(1, ncol(dataset)), function(i) length(unique(dataset[,i])) < nrow(dataset)/10 )
        valid_10p <- names(dataset[, col_check, drop = FALSE])

        na_percentage <- purrr::map(dataset, ~mean(is.na(.)))
        na_percentage <- data.frame(t(sapply(unlist(na_percentage),c)))
        na_percentage <- reshape2::melt(na_percentage)
        na_percentage$value <- round(na_percentage$value, digits = 2)


        response_data$columns <- fileHeader %>% mutate(valid_numeric = if_else(remapped %in% valid_numeric, 1, 0)) %>%
            mutate(valid_zv = if_else(remapped %in% valid_zv, 1, 0)) %>%
            mutate(valid_10p = if_else(remapped %in% valid_10p, 1, 0)) %>%
            mutate(na_percentage = na_percentage[na_percentage$variable == remapped, ]$value)
 

        data_summary <- summarytools::descr(dataset, stats = c("common"), transpose = TRUE, headings = FALSE)
        data_summary <- as.data.frame(data_summary)
        data_summary$remapped <- row.names(data_summary)
        row.names(data_summary) <- NULL

        response_data$summary <- data_summary %>% 
            left_join(fileHeader, by = "remapped", keep = FALSE) %>% dplyr::select(Mean, Std.Dev, Min, Median, Max, N.Valid, Pct.Valid, original)


        tmp_path <- tempfile(pattern = plot_unique_hash[["columns"]], tmpdir = tempdir(), fileext = ".RDS")
        saveCachedList(tmp_path, response_data$columns)

        tmp_path <- tempfile(pattern = plot_unique_hash[["summary"]], tmpdir = tempdir(), fileext = ".RDS")
        saveCachedList(tmp_path, response_data$summary)

        tmp_path <- tempfile(pattern = plot_unique_hash[["saveObjectHash"]], tmpdir = tempdir(), fileext = ".Rdata")
        processingData <- list(
            columns = response_data$columns,
            summary = response_data$summary,
            settings = settings,
            fileHeader = fileHeader,
            dataset = dataset
        )
        saveCachedList(tmp_path, processingData)
        response_data$saveObjectHash = substr(basename(tmp_path), 1, nchar(basename(tmp_path))-6)

        return (list(success = TRUE, message = response_data))
    }
)


#* Plot tableplot
#* @serializer contentType list(type='image/png')
#' @post /plots/editing/overview/render-plot
simon$handle$plots$editing$overview$renderPlot <- expression(
    function(req, res, ...){
        args <- as.list(match.call())

        response_data <- list(
            table_plot = NULL, table_plot_png = NULL, 
            distribution_plot = NULL, distribution_plot_png = NULL,
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

        if(is_var_empty(settings$groupingVariable) == TRUE){
            settings$groupingVariable = NULL
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

        plot_unique_hash <- list(
            table_plot = digest::digest(paste0(selectedFileID, "_",args$settings,"_table_plot"), algo="md5", serialize=F), 
            distribution_plot =  digest::digest(paste0(selectedFileID, "_",args$settings,"_distribution_plot"), algo="md5", serialize=F),
            saveObjectHash = digest::digest(paste0(selectedFileID, "_",args$settings,"_editing_overview_render_plot"), algo="md5", serialize=F)
        )


        resp_check <- getPreviouslySavedResponse(plot_unique_hash, response_data, 5)

        if(is.list(resp_check)){
            return(resp_check)
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

        if(!is.null(settings$groupingVariable)){
            settings$groupingVariable <- fileHeader %>% filter(remapped %in% settings$groupingVariable)
            settings$groupingVariable <- settings$groupingVariable$remapped
        }

        plot_all_columns <- FALSE
        if(is_null(settings$selectedColumns)) {
            selectedColumns <- fileHeader %>% arrange(unique_count) %>% slice(5) %>% arrange(position) %>% select(remapped)
            settings$selectedColumns <- tail(selectedColumns$remapped, 5)
            plot_all_columns <- TRUE
        }else if(length(settings$selectedColumns) == nrow(fileHeader)) {
            plot_all_columns <- TRUE
        }
        ## Remove grouping variable from selected columns
        settings$selectedColumns <-  setdiff(settings$selectedColumns, settings$groupingVariable)

        ## Load dataset
        dataset <- data.table::fread(selectedFilePath, header = T, sep = ',', stringsAsFactors = FALSE, data.table = FALSE)
        dataset_filtered <- dataset[, names(dataset) %in% c(settings$selectedColumns, settings$groupingVariable)]

        if(!is.null(settings$preProcessedData)){
            ## Preprocess data except grouping variables
            preProcessedData <- preProcessData(dataset_filtered, settings$groupingVariable , settings$groupingVariable , methods = c("medianImpute", "center", "scale"))
            dataset_filtered <- preProcessedData$processedMat
            #preProcessedData <- preProcessData(dataset_filtered, settings$groupingVariable , settings$groupingVariable ,  methods = c("nzv", "zv"))
            #dataset_filtered <- preProcessedData$processedMat
        }

        rendered_plot_tableplot <- plot_tableplot(dataset_filtered, settings, fileHeader)

        if(rendered_plot_tableplot$status == TRUE){
            tmp_path <- tempfile(pattern = plot_unique_hash[["table_plot"]], tmpdir = tempdir(), fileext = ".svg")
            save_tableplot_info <- save_tableplot(rendered_plot_tableplot$data, tmp_path, settings)

            if(save_tableplot_info$status == TRUE){
                ## Optimize SVG using svgo package
                tmp_path_png <- stringr::str_replace(tmp_path, ".svg", ".png")
                png_cmd <- paste0(which_cmd("rsvg-convert")," ",tmp_path," -f png -o ",tmp_path_png)
                # convert_cmd <- paste0(which_cmd("svgo")," ",tmp_path," -o ",tmp_path, " --config='{ \"plugins\": [{ \"removeDimensions\": true }] }' && ", png_cmd)
                convert_cmd <- paste0(which_cmd("svgo")," ",tmp_path," -o ",tmp_path, " && ", png_cmd)
                system(convert_cmd, intern = TRUE, ignore.stdout = TRUE, ignore.stderr = TRUE, wait = TRUE)

                svg_data <- readBin(tmp_path, "raw", n = file.info(tmp_path)$size)
                response_data$table_plot = as.character(RCurl::base64Encode(svg_data, "txt"))
                response_data$table_plot_png =  as.character(RCurl::base64Encode(readBin(tmp_path_png, "raw", n = file.info(tmp_path_png)$size), "txt"))
            }

        }
        rendered_plot_matrix <- plot_matrix_plot(dataset_filtered, settings, fileHeader)
        
        tmp_path <- tempfile(pattern = plot_unique_hash[["distribution_plot"]], tmpdir = tempdir(), fileext = ".svg")
        svg(tmp_path, width = 12 * settings$aspect_ratio, height = 12, pointsize = 12, onefile = TRUE, family = "Arial", bg = "white", antialias = "default")
            print(rendered_plot_matrix)
        dev.off()

        ## Optimize SVG using svgo package
        tmp_path_png <- stringr::str_replace(tmp_path, ".svg", ".png")
        png_cmd <- paste0(which_cmd("rsvg-convert")," ",tmp_path," -f png -o ",tmp_path_png)
        # convert_cmd <- paste0(which_cmd("svgo")," ",tmp_path," -o ",tmp_path, " --config='{ \"plugins\": [{ \"removeDimensions\": true }] }' && ", png_cmd)
        convert_cmd <- paste0(which_cmd("svgo")," ",tmp_path," -o ",tmp_path, " && ", png_cmd)
        system(convert_cmd, intern = TRUE, ignore.stdout = TRUE, ignore.stderr = TRUE, wait = TRUE)

        svg_data <- readBin(tmp_path, "raw", n = file.info(tmp_path)$size)
        response_data$distribution_plot = as.character(RCurl::base64Encode(svg_data, "txt"))
        response_data$distribution_plot_png =  as.character(RCurl::base64Encode(readBin(tmp_path_png, "raw", n = file.info(tmp_path_png)$size), "txt"))


        ## save data for latter use
        tmp_path <- tempfile(pattern = plot_unique_hash[["saveObjectHash"]], tmpdir = tempdir(), fileext = ".Rdata")
        processingData <- list(
            plot_tableplot = rendered_plot_tableplot,
            plot_matrix = rendered_plot_matrix,
            settings = settings,
            dataset = dataset,
            dataset_filtered_processed = dataset_filtered
        )
        saveCachedList(tmp_path, processingData)
        response_data$saveObjectHash = substr(basename(tmp_path), 1, nchar(basename(tmp_path))-6)

        return (list(success = TRUE, message = response_data))
    }
)
