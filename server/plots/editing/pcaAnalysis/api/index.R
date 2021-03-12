#* @serializer contentType list(type='image/png')
#' @post /plots/editing/pcaAnalysis/renderPlotZoomed
simon$handle$plots$editing$pcaAnalysis$renderPlotZoomed <- expression(
    function(req, res, ...){
        args <- as.list(match.call())

        response_data <- list(
            plot_pca_zoomed = NULL, plot_pca_zoomed_png = NULL)


        selectedFileID <- 0
        if("selectedFileID" %in% names(args)){
            selectedFileID <- as.numeric(args$selectedFileID)
        }

        settings <- NULL
        if("settings" %in% names(args)){
            settings <- jsonlite::fromJSON(args$settings)
        }
        if(length(settings$pcaComponentsDisplayX) == 0){
            settings$pcaComponentsDisplayX = "PC1"
        }
        if(length(settings$pcaComponentsDisplayY) == 0){
            settings$pcaComponentsDisplayY = "PC2"
        }

        selected_cordinates <- NULL
        if("selected_cordinates" %in% names(args)){
            selected_cordinates <- args$selected_cordinates

            print("Selected coordinates:")
            print(selected_cordinates)

            selected_cordinates <- strsplit(selected_cordinates, "\\s+")
            selected_cordinates <- as.data.frame(selected_cordinates, stringsAsFactors=FALSE)
            colnames(selected_cordinates) <- "cordinates"
            selected_cordinates <- stringr::str_split_fixed(selected_cordinates$cordinates, ",", 2)

            selected_cordinates <- as.data.frame(selected_cordinates)
            selected_cordinates[] <- lapply(selected_cordinates, function(x) as.numeric(as.character(x)))

            colnames(selected_cordinates)[1] <- "xlim"
            colnames(selected_cordinates)[2] <- "ylim"
        }

        plot_unique_hash <- list(
            plot_pca_zoomed =  digest::digest(paste0(selectedFileID, "_",args$settings,"_plot_pca_zoomed_redraw"), algo="md5", serialize=F)
        )

        analysisUniqueHash <-  digest::digest(paste0(selectedFileID, "_",args$settings,"_plot_pca_all"), algo="md5", serialize=F)

        tmp_dir <- tempdir(check = TRUE)
        tmp_check_count <- 0
        for (name in names(plot_unique_hash)) {
            cachedFiles <- list.files(tmp_dir, full.names = TRUE, pattern=paste0(plot_unique_hash[[name]], ".*")) 

            for(cachedFile in cachedFiles){
                cachedFileExtension <- tools::file_ext(cachedFile)

                ## Check if some files where found in tmpdir that match our unique hash
                if(identical(cachedFile, character(0)) == FALSE){
                    if(file.exists(cachedFile) == TRUE){
                        raw_file <- readBin(cachedFile, "raw", n = file.info(cachedFile)$size)
                        encoded_file <- RCurl::base64Encode(raw_file, "txt")

                        if(cachedFileExtension == "svg"){
                            response_data[[name]] = as.character(encoded_file)    
                        }else if(cachedFileExtension == "png"){
                            response_data[[paste0(name, "_png")]] = as.character(encoded_file)
                        }
                        
                        tmp_check_count <- tmp_check_count + 1
                    }
                }
            }
        }
        
        if(tmp_check_count == 6){
            # return (list(success = TRUE, message = response_data))
        }

        save(selected_cordinates, file = paste0("/tmp/selected_cordinates"))

        load(paste0(tmp_dir,"/", analysisUniqueHash))

        xlim <- c(round(min(selected_cordinates$xlim), 1), round(max(selected_cordinates$xlim), 1))
        ylim <- c(round(min(selected_cordinates$ylim), 1), round(max(selected_cordinates$ylim), 1))


        print(xlim)
        print(ylim)

        plot_pca_zoomed <- saveData$pca_details$plot_pca + coord_cartesian(xlim = xlim, ylim = ylim) 

        tmp_path <- tempfile(pattern = plot_unique_hash[["plot_pca_zoomed"]], tmpdir = tempdir(), fileext = ".svg")
        tempdir(check = TRUE)
        svg(tmp_path, width = 12, height = 12, pointsize = 12, onefile = TRUE, family = "Arial", bg = "white", antialias = "default")
            print(plot_pca_zoomed)
        dev.off()

        ## Optimize SVG using svgo package
        tmp_path_png <- stringr::str_replace(tmp_path, ".svg", ".png")
        png_cmd <- paste0(which_cmd("rsvg-convert")," ",tmp_path," -f png -o ",tmp_path_png)
        convert_cmd <- paste0(which_cmd("svgo")," ",tmp_path," -o ",tmp_path, " && ", png_cmd)
        system(convert_cmd, intern = TRUE, ignore.stdout = TRUE, ignore.stderr = TRUE, wait = TRUE)

        response_data$plot_pca_zoomed <- toString(RCurl::base64Encode(readBin(tmp_path, "raw", n = file.info(tmp_path)$size), "txt"))
        response_data$plot_pca_zoomed_png <- toString(RCurl::base64Encode(readBin(tmp_path_png, "raw", n = file.info(tmp_path_png)$size), "txt"))


        return (list(success = TRUE, message = response_data))
    }
)

#* Get available columns for PCA analysis
#* @serializer contentType list(type='image/png')
#' @post /plots/editing/pcaAnalysis/getColumns
simon$handle$plots$editing$pcaAnalysis$getAvaliableColumns <- expression(
    function(req, res, ...){
        args <- as.list(match.call())

        response_data <- list(
            columns_all = NULL, 
            columns_grouping = NULL,
            columns_excluded_all = NULL,
            columns_excluded_grouping = NULL
        )

        selectedFileID <- 0
        if("selectedFileID" %in% names(args)){
            selectedFileID <- as.numeric(args$selectedFileID)
        }
        settings <- NULL
        if("settings" %in% names(args)){
            settings <- jsonlite::fromJSON(args$settings)
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

        ## Load dataset
        dataset <- data.table::fread(selectedFilePath, header = T, sep = ',', stringsAsFactors = FALSE, data.table = FALSE)

        ## =========== AVALIABLE COLUMNS
        # we only want to show numeric cols
        valid_columns <- dataset[,sapply(dataset,is.numeric)]
        # exclude cols with zero variance
        valid_columns <- valid_columns[,!apply(valid_columns, MARGIN = 2, function(x) max(x, na.rm = TRUE) == min(x, na.rm = TRUE))]
        availableColumns <- names(valid_columns)

        response_data$columns_all <- fileHeader %>% filter(remapped %in% availableColumns)
        

        response_data$columns_excluded_all <-  setdiff(availableColumns, names(dataset))
        response_data$columns_excluded_all <-  fileHeader %>% filter(remapped %in% response_data$columns_excluded_all)

        ## =========== AVALIABLE GROUPING COLUMNS
        # For grouping we want to see only cols where the number of unique values are less than 
        # 10% the number of observations
        grouping_cols <- sapply(seq(1, ncol(dataset)), function(i) length(unique(dataset[,i])) < nrow(dataset)/10 )
        groupingVariable <- names(dataset[, grouping_cols, drop = FALSE])
        response_data$columns_grouping <- fileHeader %>% filter(remapped %in% groupingVariable)


        response_data$columns_excluded_grouping <-  setdiff(groupingVariable, names(dataset))
        response_data$columns_excluded_grouping <-  fileHeader %>% filter(remapped %in% response_data$columns_excluded_grouping)

        return (list(success = TRUE, message = response_data))
    }
)


#* Plot out data from the selected dataset
#* @serializer contentType list(type='image/png')
#' @post /plots/editing/pcaAnalysis/renderPlot
simon$handle$plots$editing$pcaAnalysis$renderPlot <- expression(
    function(req, res, ...){
        args <- as.list(match.call())

        response_data <- list(
            plot_scree = NULL, plot_scree_png = NULL, 
            plot_pca = NULL, plot_pca_png = NULL, 
            plot_pca_zoomed = NULL, plot_pca_zoomed_png = NULL)


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

        if(is_var_empty(settings$pcaComponentsDisplayX) == TRUE){
            settings$pcaComponentsDisplayX = "PC1"
        }
        
        if(is_var_empty(settings$pcaComponentsDisplayY) == TRUE){
            settings$pcaComponentsDisplayY = "PC2"
        }

        plot_unique_hash <- list(
            plot_scree = digest::digest(paste0(selectedFileID, "_",args$settings,"_plot_scree"), algo="md5", serialize=F), 
            plot_pca =  digest::digest(paste0(selectedFileID, "_",args$settings,"_plot_pca"), algo="md5", serialize=F), 
            plot_pca_zoomed =  digest::digest(paste0(selectedFileID, "_",args$settings,"_plot_pca_zoomed"), algo="md5", serialize=F)
        )

        analysisUniqueHash <-  digest::digest(paste0(selectedFileID, "_",args$settings,"_plot_pca_all"), algo="md5", serialize=F)

        tmp_dir <- tempdir(check = TRUE)
        tmp_check_count <- 0
        for (name in names(plot_unique_hash)) {
            cachedFiles <- list.files(tmp_dir, full.names = TRUE, pattern=paste0(plot_unique_hash[[name]], ".*")) 

            for(cachedFile in cachedFiles){
                cachedFileExtension <- tools::file_ext(cachedFile)

                ## Check if some files where found in tmpdir that match our unique hash
                if(identical(cachedFile, character(0)) == FALSE){
                    if(file.exists(cachedFile) == TRUE){
                        raw_file <- readBin(cachedFile, "raw", n = file.info(cachedFile)$size)
                        encoded_file <- RCurl::base64Encode(raw_file, "txt")

                        if(cachedFileExtension == "svg"){
                            response_data[[name]] = as.character(encoded_file)    
                        }else if(cachedFileExtension == "png"){
                            response_data[[paste0(name, "_png")]] = as.character(encoded_file)
                        }
                        
                        tmp_check_count <- tmp_check_count + 1
                    }
                }
            }
        }
        
        if(tmp_check_count == 6){
            # return (list(success = TRUE, message = response_data))
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
        #save(fileHeader, file = "/tmp/fileHeader")

        if(!is.null(settings$groupingVariable)){
            settings$groupingVariable <- fileHeader %>% filter(remapped %in% settings$groupingVariable)
            settings$groupingVariable <- settings$groupingVariable$remapped
        }

        if(is.null(settings$selectedColumns)){
            selectedColumns <- fileHeader %>% arrange(unique_count) %>% slice(5) %>% arrange(position) %>% select(remapped)
            settings$selectedColumns <- tail(selectedColumns$remapped, 5)
        }else{
            settings$selectedColumns <- fileHeader %>% filter(remapped %in% settings$selectedColumns)
            settings$selectedColumns <- settings$selectedColumns$remapped
        }

        ## Remove grouping variable from selected columns
        settings$selectedColumns <-  setdiff(settings$selectedColumns, settings$groupingVariable)

        dataset <- data.table::fread(selectedFilePath, header = T, sep = ',', stringsAsFactors = FALSE, data.table = FALSE)
        ## Drop all columns expect selected and grouping ones
        dataset_filtered <- dataset[, names(dataset) %in% c(settings$selectedColumns, settings$groupingVariable)]
        
        ## Preprocess data except grouping variables
        preProcessedData <- preProcessData(dataset_filtered, settings$groupingVariable , settings$groupingVariable , methods = c("medianImpute", "center", "scale"))
        dataset_filtered <- preProcessedData$processedMat
        preProcessedData <- preProcessData(dataset_filtered, settings$groupingVariable , settings$groupingVariable ,  methods = c("nzv", "zv"))
        dataset_filtered <- preProcessedData$processedMat



        the_data <- na.omit(dataset_filtered)
        the_data_subset <- na.omit(the_data %>% select(any_of(settings$selectedColumns)))
        the_data_num <- na.omit(the_data_subset[,sapply(the_data_subset, is.numeric)])

        ## Rempa column names from remaped to original
        names(the_data) <- plyr::mapvalues(names(the_data), from=fileHeader$remapped, to=fileHeader$original)
        names(the_data_subset) <- plyr::mapvalues(names(the_data_subset), from=fileHeader$remapped, to=fileHeader$original)
        names(the_data_num) <- plyr::mapvalues(names(the_data_num), from=fileHeader$remapped, to=fileHeader$original)


        ## from stats package
        pca_output <- prcomp(the_data_num, 
                             center = FALSE, 
                             scale. = FALSE)

        # data.frame of PCs
        pcs_df <- cbind(the_data, pca_output$x)

        pca_details = list(the_data = the_data, 
                           the_data_num = the_data_num,
                           pca_output = pca_output, 
                           pcs_df = pcs_df, 
                           pca_components = colnames(pca_output$x),
                           plot_scree = NULL,
                           plot_pca = NULL
                        )
        pca_details_output <- list(
                pca_components = colnames(pca_output$x),
                pca_rotation = pca_output$rotation,
                pca_summary = convertToString(summary(pca_output)),
                panel_scales_y = NULL,
                panel_scales_x = NULL,
                summary_bartlett = convertToString(psych::cortest.bartlett(cor(the_data_num), n = nrow(the_data_num))),
                summary_kmo = convertToString(kmo_test(the_data_num)),
                pca_dataframe = pcs_df
        )


        pca_details$plot_scree <- plot_scree(pca_details$pca_output)

        tmp_path <- tempfile(pattern = plot_unique_hash[["plot_scree"]], tmpdir = tempdir(), fileext = ".svg")
        tempdir(check = TRUE)
        svg(tmp_path, width = 18, height = 12, pointsize = 12, onefile = TRUE, family = "Arial", bg = "white", antialias = "default")
            print(pca_details$plot_scree)
        dev.off()

        ## Optimize SVG using svgo package
        tmp_path_png <- stringr::str_replace(tmp_path, ".svg", ".png")
        png_cmd <- paste0(which_cmd("rsvg-convert")," ",tmp_path," -f png -o ",tmp_path_png)
        convert_cmd <- paste0(which_cmd("svgo")," ",tmp_path," -o ",tmp_path, " && ", png_cmd)
        system(convert_cmd, intern = TRUE, ignore.stdout = TRUE, ignore.stderr = TRUE, wait = TRUE)

        response_data$plot_scree <- toString(RCurl::base64Encode(readBin(tmp_path, "raw", n = file.info(tmp_path)$size), "txt"))
        response_data$plot_scree_png <- toString(RCurl::base64Encode(readBin(tmp_path_png, "raw", n = file.info(tmp_path_png)$size), "txt"))


        if(is.null(settings$groupingVariable)){
            pca_details$plot_pca <- plot_pca(pca_details$pcs_df, pca_details$pca_output, settings)
        }else{
            groupingVariable <- fileHeader %>% filter(remapped %in% settings$groupingVariable)
            pca_details$plot_pca <- plot_pca_grouped(pca_details$pcs_df, pca_details$pca_output, settings, groupingVariable$original)
        }


        tmp_path <- tempfile(pattern = plot_unique_hash[["plot_pca"]], tmpdir = tempdir(), fileext = ".svg")
        tempdir(check = TRUE)
        svg(tmp_path, width = 12, height = 12, pointsize = 12, onefile = TRUE, family = "Arial", bg = "white", antialias = "default")
            print(pca_details$plot_pca)
        dev.off()

        ## Optimize SVG using svgo package
        tmp_path_png <- stringr::str_replace(tmp_path, ".svg", ".png")
        png_cmd <- paste0(which_cmd("rsvg-convert")," ",tmp_path," -f png -o ",tmp_path_png)
        convert_cmd <- paste0(which_cmd("svgo")," ",tmp_path," -o ",tmp_path, " && ", png_cmd)
        system(convert_cmd, intern = TRUE, ignore.stdout = TRUE, ignore.stderr = TRUE, wait = TRUE)

        response_data$plot_pca <- toString(RCurl::base64Encode(readBin(tmp_path, "raw", n = file.info(tmp_path)$size), "txt"))
        response_data$plot_pca_png <- toString(RCurl::base64Encode(readBin(tmp_path_png, "raw", n = file.info(tmp_path_png)$size), "txt"))


        response_data$plot_pca_zoomed <- response_data$plot_pca
        response_data$plot_pca_zoomed_png <- response_data$plot_pca_png


        ggp <- ggplot_build(pca_details$plot_pca)
        pca_details_output$panel_scales_y <- ggp$layout$panel_scales_y[[1]]$range$range
        pca_details_output$panel_scales_x <- ggp$layout$panel_scales_x[[1]]$range$range


        print(paste0(tmp_dir,"/", analysisUniqueHash))
        saveData = list(pca_details = pca_details, pca_details_output = pca_details_output, cordinates_x = 0, cordinates_y = 0)
        save(saveData, file = paste0(tmp_dir,"/", analysisUniqueHash))
        rm(saveData)

        return (list(success = TRUE, message = response_data, details = pca_details_output))
    }
)
