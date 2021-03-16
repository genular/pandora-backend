#* Plot out data from the selected dataset
#* @serializer contentType list(type='image/png')
#' @post /plots/editing/pcaAnalysis/renderPlot
simon$handle$plots$editing$pcaAnalysis$renderPlot <- expression(
    function(req, res, ...){
        args <- as.list(match.call())

        response_data <- list(
            plot_scree = NULL, plot_scree_png = NULL, 
            plot_pca = NULL, plot_pca_png = NULL)


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

        if(is_var_empty(settings$preProcessDataset) == TRUE){
            settings$preProcessDataset = TRUE
        }

        if(is_var_empty(settings$removeNA) == TRUE){
            settings$removeNA = TRUE
        }

        if(is_var_empty(settings$displayLoadings) == TRUE){
            settings$displayLoadings = TRUE
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
            plot_scree = digest::digest(paste0(selectedFileID, "_",args$settings,"_plot_scree"), algo="md5", serialize=F), 
            plot_pca =  digest::digest(paste0(selectedFileID, "_",args$settings,"_plot_pca"), algo="md5", serialize=F), 
            saveObjectHash = digest::digest(paste0(selectedFileID, "_",args$settings,"_plot_pca_all"), algo="md5", serialize=F)
        )

        resp_check <- getPreviouslySavedResponse(plot_unique_hash, response_data, 5)
        if(is.list(resp_check)){
            #print("==> Serving request response from cache")
            #return(resp_check)
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

        num_test <- dataset_filtered %>% select(where(is.numeric))
        for (groupVariable in settings$groupingVariable) {
            if(groupVariable %in% names(num_test)){
                dataset_filtered[[groupVariable]] <-paste("g",dataset_filtered[[groupVariable]],sep="_")
            }
        }

        if(!is.null(settings$preProcessDataset)){
            ## Preprocess data except grouping variables
            preProcessedData <- preProcessData(dataset_filtered, settings$groupingVariable , settings$groupingVariable , methods = c("medianImpute", "center", "scale"))
            dataset_filtered <- preProcessedData$processedMat
            preProcessedData <- preProcessData(dataset_filtered, settings$groupingVariable , settings$groupingVariable ,  methods = c("nzv", "zv"))
            dataset_filtered <- preProcessedData$processedMat
        }else{
            dataset_filtered <- dataset
        }

        if(settings$removeNA == TRUE){
            the_data <- na.omit(dataset_filtered)
        }


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


        pca_details$plot_scree <- plot_scree(pca_details$pca_output, settings)

        tmp_path <- tempfile(pattern = plot_unique_hash[["plot_scree"]], tmpdir = tempdir(), fileext = ".svg")
        tempdir(check = TRUE)
        svg(tmp_path, width = 18, height = 12, pointsize = 12, onefile = TRUE, family = "Arial", bg = "white", antialias = "default")
            print(pca_details$plot_scree)
        dev.off()

        response_data$plot_scree <- optimizeSVGFile(tmp_path)
        response_data$plot_scree_png <- convertSVGtoPNG(tmp_path)


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

        response_data$plot_pca <- optimizeSVGFile(tmp_path)
        response_data$plot_pca_png <- convertSVGtoPNG(tmp_path)

        tmp_path <- tempfile(pattern = plot_unique_hash[["saveObjectHash"]], tmpdir = tempdir(), fileext = ".Rdata")
        processingData <- list(
            pca_details = pca_details, 
            pca_details_output = pca_details_output, 
            response_data = response_data
        )
        saveCachedList(tmp_path, processingData)
        response_data$saveObjectHash = substr(basename(tmp_path), 1, nchar(basename(tmp_path))-6)

        return (list(success = TRUE, message = response_data, details = pca_details_output))
    }
)
