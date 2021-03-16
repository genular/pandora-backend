#* Generate t-SNE plot
#* @serializer contentType list(type='image/png')
#' @post /plots/editing/tsne/renderPlot
simon$handle$plots$editing$tsne$renderPlot <- expression(
    function(req, res, ...){
        args <- as.list(match.call())

        response_data <- list(
            tsne_plot = NULL, tsne_plot_png = NULL, 
            tsne_cluster_plot = NULL, tsne_cluster_plot_png = NULL, 
            tsne_cluster_heatmap_plot = NULL, tsne_cluster_heatmap_plot_png = NULL
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

        if(is_var_empty(settings$excludedColumns) == TRUE){
            settings$excludedColumns = NULL
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

        if(is_var_empty(settings$clusterType) == TRUE){
            settings$clusterType <- "Louvain"
        }


        plot_unique_hash <- list(
            tsne_plot = digest::digest(paste0(selectedFileID, "_",args$settings,"_tsne_plot"), algo="md5", serialize=F),
            tsne_cluster_plot = digest::digest(paste0(selectedFileID, "_",args$settings,"_tsne_cluster_plot"), algo="md5", serialize=F),
            tsne_cluster_heatmap_plot = digest::digest(paste0(selectedFileID, "_",args$settings,"_tsne_cluster_heatmap_plot"), algo="md5", serialize=F),
            saveObjectHash = digest::digest(paste0(selectedFileID, "_",args$settings,"_editing_tsne_render_plot"), algo="md5", serialize=F)
        )

        resp_check <- getPreviouslySavedResponse(plot_unique_hash, response_data, 5)
        if(is.list(resp_check)){
            print("==> Serving request response from cache")
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

        ## Load dataset
        dataset <- data.table::fread(selectedFilePath, header = T, sep = ',', stringsAsFactors = FALSE, data.table = FALSE)
        dataset_filtered <- dataset[, names(dataset) %in% c(settings$selectedColumns, settings$groupingVariable)]


        num_test <- dataset_filtered %>% select(where(is.numeric))
        for (groupVariable in settings$groupingVariable) {
            if(groupVariable %in% names(num_test)){
                dataset_filtered[[groupVariable]] <-paste("g",dataset_filtered[[groupVariable]],sep="_")
            }
        }

        if(!is.null(settings$preProcessedData)){
            ## Preprocess data except grouping variables
            preProcessedData <- preProcessData(dataset_filtered, settings$groupingVariable, settings$groupingVariable, methods = c("medianImpute", "center", "scale"))
            dataset_filtered <- preProcessedData$processedMat
            #preProcessedData <- preProcessData(dataset_filtered, settings$groupingVariable , settings$groupingVariable ,  methods = c("nzv", "zv"))
            #dataset_filtered <- preProcessedData$processedMat
        }
        tsne_calc <- calculate_tsne(dataset_filtered, settings, fileHeader)

        rendered_plot_tsne <- plot_tsne(tsne_calc$info.norm, settings, fileHeader)

        tmp_path <- tempfile(pattern = plot_unique_hash[["tsne_plot"]], tmpdir = tempdir(), fileext = ".svg")
        svg(tmp_path, width = 12 * settings$aspect_ratio, height = 12, pointsize = 12, onefile = TRUE, family = "Arial", bg = "white", antialias = "default")
            print(rendered_plot_tsne)
        dev.off()

        response_data$tsne_plot <- optimizeSVGFile(tmp_path)
        response_data$tsne_plot_png <- convertSVGtoPNG(tmp_path)

        print(paste0("===> Clustering using", settings$clusterType))

        if(settings$clusterType == "Louvain"){
           clust_plot_tsne <- cluster_tsne_knn_louvain(tsne_calc$info.norm, tsne_calc$tsne.norm, settings)
        }else if(settings$clusterType == "Hierarchical"){
           clust_plot_tsne <- cluster_tsne_hierarchical(tsne_calc$info.norm, tsne_calc$tsne.norm, settings)
        }else if(settings$clusterType == "Mclust"){
           clust_plot_tsne <- cluster_tsne_mclust(tsne_calc$info.norm, tsne_calc$tsne.norm, settings)
        }else if(settings$clusterType == "Density"){
           clust_plot_tsne <- cluster_tsne_density(tsne_calc$info.norm, tsne_calc$tsne.norm, settings)
        }else{
           clust_plot_tsne <- cluster_tsne_knn_louvain(tsne_calc$info.norm, tsne_calc$tsne.norm, settings)
        }

        rendered_plot_tsne <- plot_clustered_tsne(clust_plot_tsne$info.norm, clust_plot_tsne$cluster_data, settings)

        svg(tmp_path, width = 12 * settings$aspect_ratio, height = 12, pointsize = 12, onefile = TRUE, family = "Arial", bg = "white", antialias = "default")
            print(rendered_plot_tsne)
        dev.off()

        response_data$tsne_cluster_plot <- optimizeSVGFile(tmp_path)
        response_data$tsne_cluster_plot_png <- convertSVGtoPNG(tmp_path)

        ## save data for latter use
        tmp_path <- tempfile(pattern = plot_unique_hash[["saveObjectHash"]], tmpdir = tempdir(), fileext = ".Rdata")
        processingData <- list(
            tsne = ifelse(exists("tsne_calc"), tsne_calc, FALSE),
            tsne_plot = ifelse(exists("rendered_plot_tsne"), rendered_plot_tsne, FALSE),
            tsne_cluster_plot = ifelse(exists("rendered_plot_tsne"), rendered_plot_tsne, FALSE),
            tsne_clustered = ifelse(exists("clust_plot_tsne"), clust_plot_tsne, FALSE),
            settings = ifelse(exists("settings"), settings, FALSE),
            dataset = ifelse(exists("dataset"), dataset, FALSE),
            dataset_filtered_processed = ifelse(exists("dataset_filtered"), dataset_filtered, FALSE)
        )
        saveCachedList(tmp_path, processingData)
        response_data$saveObjectHash = substr(basename(tmp_path), 1, nchar(basename(tmp_path))-6)

        return (list(success = TRUE, message = response_data, info.norm = clust_plot_tsne$info.norm))
    }
)
