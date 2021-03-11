#* Generate t-SNE plot
#* @serializer contentType list(type='image/png')
#' @post /plots/editing/tsne/renderPlot
simon$handle$plots$editing$tsne$renderPlot <- expression(
    function(req, res, ...){
        args <- as.list(match.call())

        response_data <- list(
            table_plot = NULL, table_plot_png = NULL, 
            distribution_plot = NULL, distribution_plot_png = NULL)


        selectedFileID <- 0
        if("selectedFileID" %in% names(args)){
            selectedFileID <- as.numeric(args$selectedFileID)
        }
        settings <- NULL
        if("settings" %in% names(args)){
            settings <- jsonlite::fromJSON(args$settings)
        }

        if(length(settings$groupingVariable) == 0){
            settings$groupingVariable = NULL
        }

        if(length(settings$preProcessDataset) == 0){
            settings$preProcessDataset = NULL
        }

        if(length(settings$fontSize) == 0) {
            settings$fontSize <- 12
        }

        if(length(settings$theme) == 0) {
            settings$theme <- "theme_gray"
        }

        if(length(settings$colorPalette) == 0) {
            settings$colorPalette <- "RdPu"
        }

        if(length(settings$aspect_ratio) == 0) {
            settings$aspect_ratio <- 1
        }

        if(length(settings$clusterType) == 0) {
            settings$clusterType <- "Louvain"
        }


        plot_unique_hash <- list(
            tsne_plot = digest::digest(paste0(selectedFileID, "_",args$settings,"_tsne_plot"), algo="md5", serialize=F),
            tsne_knn_plot = digest::digest(paste0(selectedFileID, "_",args$settings,"_tsne_knn_plot"), algo="md5", serialize=F)
        )

        ## we will return this hash to the client so we can request download of generated data
        saveObjectHash <- digest::digest(paste0(selectedFileID, "_",args$settings,"_editing_tsne_render_plot"), algo="md5", serialize=F)

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
        
        if(tmp_check_count == 4){
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

        if(!is.null(settings$groupingVariable)){
            settings$groupingVariable <- fileHeader %>% filter(remapped %in% settings$groupingVariable)
            settings$groupingVariable <- settings$groupingVariable$remapped
        }

        plot_all_columns <- FALSE
        if(length(settings$selectedColumns) == 0) {
            selectedColumns <- fileHeader %>% arrange(unique_count) %>% slice(5) %>% arrange(position) %>% select(remapped)
            settings$selectedColumns <- tail(selectedColumns$remapped, 5)
            plot_all_columns <- TRUE
        }else if(length(settings$selectedColumns) == nrow(fileHeader)) {
            plot_all_columns <- TRUE
        }

        print("Selecting columns:")
        print(settings$selectedColumns)
        print(length(settings$selectedColumns))
        print(nrow(fileHeader))

        print("Selecting grouping variables:")
        print(settings$groupingVariable)

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
        save(dataset, file = "/tmp/dataset")
        save(dataset_filtered, file = "/tmp/dataset_filtered")
        save(settings, file = "/tmp/settings")
        print("Generating tsne plot")

        tsne_calc <- calculate_tsne(dataset_filtered, settings, fileHeader)

        rendered_plot_tsne <- plot_tsne(tsne_calc$info.norm, settings, fileHeader)
        tmp_path <- tempfile(pattern = plot_unique_hash[["tsne_plot"]], tmpdir = tempdir(), fileext = ".svg")
        svg(tmp_path, width = 12 * settings$aspect_ratio, height = 12, pointsize = 12, onefile = TRUE, family = "Arial", bg = "white", antialias = "default")
            print(rendered_plot_tsne)
        dev.off()
        ## Optimize SVG using svgo package
        tmp_path_png <- stringr::str_replace(tmp_path, ".svg", ".png")
        png_cmd <- paste0(which_cmd("rsvg-convert")," ",tmp_path," -f png -o ",tmp_path_png)
        # convert_cmd <- paste0(which_cmd("svgo")," ",tmp_path," -o ",tmp_path, " --config='{ \"plugins\": [{ \"removeDimensions\": true }] }' && ", png_cmd)
        convert_cmd <- paste0(which_cmd("svgo")," ",tmp_path," -o ",tmp_path, " && ", png_cmd)
        system(convert_cmd, intern = TRUE, ignore.stdout = TRUE, ignore.stderr = TRUE, wait = TRUE)

        svg_data <- readBin(tmp_path, "raw", n = file.info(tmp_path)$size)
        response_data$tsne_plot = as.character(RCurl::base64Encode(svg_data, "txt"))
        response_data$tsne_plot_png =  as.character(RCurl::base64Encode(readBin(tmp_path_png, "raw", n = file.info(tmp_path_png)$size), "txt"))



        print(settings$clusterType)
        
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
        ## Optimize SVG using svgo package
        tmp_path_png <- stringr::str_replace(tmp_path, ".svg", ".png")
        png_cmd <- paste0(which_cmd("rsvg-convert")," ",tmp_path," -f png -o ",tmp_path_png)
        # convert_cmd <- paste0(which_cmd("svgo")," ",tmp_path," -o ",tmp_path, " --config='{ \"plugins\": [{ \"removeDimensions\": true }] }' && ", png_cmd)
        convert_cmd <- paste0(which_cmd("svgo")," ",tmp_path," -o ",tmp_path, " && ", png_cmd)
        system(convert_cmd, intern = TRUE, ignore.stdout = TRUE, ignore.stderr = TRUE, wait = TRUE)

        svg_data <- readBin(tmp_path, "raw", n = file.info(tmp_path)$size)
        response_data$tsne_knn_plot = as.character(RCurl::base64Encode(svg_data, "txt"))
        response_data$tsne_knn_plot_png =  as.character(RCurl::base64Encode(readBin(tmp_path_png, "raw", n = file.info(tmp_path_png)$size), "txt"))



        ## save data for latter use
        tmp_path <- tempfile(pattern = saveObjectHash, tmpdir = tempdir(), fileext = ".Rdata")
        processingData <- list(
            tsne = tsne_calc,
            tsne_plot = rendered_plot_tsne,
            tsne_knn_plot = rendered_plot_tsne,
            settings = settings,
            dataset = dataset,
            dataset_filtered_processed = dataset_filtered
        )
        save(processingData, file = tmp_path)

        return (list(success = TRUE, message = response_data, saveObjectHash = saveObjectHash, info.norm = clust_plot_tsne$info.norm))
    }
)
