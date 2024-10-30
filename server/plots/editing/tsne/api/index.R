#* Generate t-SNE plot
#* @serializer contentType list(type='image/png')
#' @post /plots/editing/tsne/renderPlot
pandora$handle$plots$editing$tsne$renderPlot <- expression(
    function(req, res, ...){
        args <- as.list(match.call())

        res.data <- list(
            tsne_plot = list(
                main_plot = NULL
            ), 
            tsne_cluster_plot = NULL, tsne_cluster_plot_png = NULL, 
            tsne_cluster_heatmap_plot = NULL, tsne_cluster_heatmap_plot_png = NULL, 

            cluster_features_means = NULL, cluster_features_means_png = NULL, 
            cluster_features_means_separated = NULL, cluster_features_means_separated_png = NULL
        )

        selectedFileID <- 0
        if("selectedFileID" %in% names(args)){
            selectedFileID <- as.numeric(args$selectedFileID)
        }
        settings <- NULL
        if("settings" %in% names(args)){
            settings <- jsonlite::fromJSON(args$settings)
        }

        if(is_var_empty(settings$selectedColumns, "selectedColumns") == TRUE){
            settings$selectedColumns = NULL
        }

        if(is_var_empty(settings$cutOffColumnSize, "cutOffColumnSize") == TRUE){
            settings$cutOffColumnSize = 50000
        }

        if(is_var_empty(settings$excludedColumns, "excludedColumns") == TRUE){
            settings$excludedColumns = NULL
        }

        if(is_var_empty(settings$groupingVariables, "groupingVariables") == TRUE){
            settings$groupingVariables = NULL
        }

        if(is_var_empty(settings$colorVariables, "colorVariables") == TRUE){
            settings$colorVariables = NULL
        }

        if(is_var_empty(settings$preProcessDataset, "preProcessDataset") == TRUE){
            settings$preProcessDataset = NULL
        }

        if(is_var_empty(settings$fontSize, "fontSize") == TRUE){
            settings$fontSize <- 12
        }

        if(is_var_empty(settings$pointSize, "pointSize") == TRUE){
            settings$pointSize <- 1.5
        }

        if(is_var_empty(settings$theme, "theme") == TRUE){
            settings$theme <- "theme_gray"
        }

        if(is_var_empty(settings$colorPalette, "colorPalette") == TRUE){
            settings$colorPalette <- "RdPu"
        }

        if(is_var_empty(settings$aspect_ratio, "aspect_ratio") == TRUE){
            settings$aspect_ratio <- 1
        }

        if(is_var_empty(settings$clusterType, "clusterType") == TRUE){
            settings$clusterType <- "Louvain"
        }

        ## Louvain Specific START (immunaut)
        if(is_var_empty(settings$resolution_increments) == TRUE){
            settings$resolution_increments <-  c(0.01, 0.05, 0.1, 0.2, 0.3, 0.4, 0.5)
            #settings$resolution_increments <- c(0.01, 0.1, 0.2, 0.3, 0.4)
        }

        if(is_var_empty(settings$min_modularities) == TRUE){
            settings$min_modularities <- c(0.4, 0.5, 0.6, 0.7, 0.8, 0.85, 0.9)
            #settings$min_modularities <- c(0.5, 0.6, 0.7, 0.8) 
        }

        if(is_var_empty(settings$target_clusters_range) == TRUE){
            settings$target_clusters_range <- c(3, 6)
        }

        if(is_var_empty(settings$pickBestClusterMethod) == TRUE){
            settings$pickBestClusterMethod <- "Modularity" ## Modularity, Silhouette, Overall, SIMON
        }

        if(is_var_empty(settings$selectedColumnsSIMON) == TRUE){
            settings$selectedColumnsSIMON <- NULL
        }

        ## Louvain pickBestClusterMethod SIMON specific

        if(is_var_empty(settings$weights) == TRUE){
            settings$weights <- list(AUROC = 0.5, modularity = 0.3, silhouette = 0.2)
        }

        if(is_var_empty(settings$selectedPackages) == TRUE){
            settings$selectedPackages <- c("rf", "RRF", "RRFglobal", "gcvEarth", "cforest", "nb")
        }

        if(is_var_empty(settings$trainingTimeout) == TRUE){
            settings$trainingTimeout <- 360
        }

        ## Louvain Specific END


        if(is_var_empty(settings$removeNA, "removeNA") == TRUE){
            settings$removeNA = FALSE
        }

        if(is_var_empty(settings$datasetAnalysisGrouped, "datasetAnalysisGrouped") == TRUE){
            settings$datasetAnalysisGrouped = FALSE
        }

        if(is_var_empty(settings$plot_size, "plot_size") == TRUE){
            settings$plot_size <- 12
        }

        if(is_var_empty(settings$knn_clusters, "knn_clusters") == TRUE){
            settings$knn_clusters <- 250
        }

        if(is_var_empty(settings$perplexity, "perplexity") == TRUE){
            settings$perplexity <- NULL
        }
        if(is_var_empty(settings$exaggeration_factor, "exaggeration_factor") == TRUE){
            settings$exaggeration_factor <- NULL
        }
        if(is_var_empty(settings$max_iter, "max_iter") == TRUE){
            settings$max_iter <- NULL
        }
        if(is_var_empty(settings$theta, "theta") == TRUE){
            settings$theta <- NULL
        }
        if(is_var_empty(settings$eta, "eta") == TRUE){
            settings$eta <- NULL
        }

        if(is_var_empty(settings$clustLinkage, "clustLinkage") == TRUE){
            settings$clustLinkage = "ward.D2"
        }

        if(is_var_empty(settings$clustGroups, "clustGroups") == TRUE){
            settings$clustGroups = 9
        }

        ## OUTLIER DETECTION START
        if(is_var_empty(settings$distMethod, "distMethod") == TRUE){
            settings$distMethod = "euclidean"
        }

        if(is_var_empty(settings$minPtsAdjustmentFactor, "minPtsAdjustmentFactor") == TRUE){
            settings$minPtsAdjustmentFactor = 1
        }

        if(is_var_empty(settings$epsQuantile, "epsQuantile") == TRUE){
            settings$epsQuantile = 0.9
        }

        if(is_var_empty(settings$assignOutliers, "assignOutliers") == TRUE){
            settings$assignOutliers = TRUE
        }
        
        if(is_var_empty(settings$excludeOutliers, "excludeOutliers") == TRUE){
            settings$excludeOutliers = TRUE
        }

        ## OUTLIER DETECTION END

        if(is_var_empty(settings$legendPosition, "legendPosition") == TRUE){
            settings$legendPosition = "right"
        }

        ## dataset analysis settings
        if(is_var_empty(settings$datasetAnalysisClustLinkage, "datasetAnalysisClustLinkage") == TRUE){
            settings$datasetAnalysisClustLinkage = "ward.D2"
        }

        if(is_var_empty(settings$datasetAnalysisType, "datasetAnalysisType") == TRUE){
            settings$datasetAnalysisType = "heatmap"
        }

        if(is_var_empty(settings$datasetAnalysisRemoveOutliersDownstream, "datasetAnalysisRemoveOutliersDownstream") == TRUE){
            settings$datasetAnalysisRemoveOutliersDownstream = TRUE
        }


        if(is_var_empty(settings$datasetAnalysisSortColumn, "datasetAnalysisSortColumn") == TRUE){
            settings$datasetAnalysisSortColumn = "cluster"
        }

        if(is_var_empty(settings$datasetAnalysisClustOrdering, "datasetAnalysisClustOrdering") == TRUE){
            settings$datasetAnalysisClustOrdering = 1
        }

        if(is_var_empty(settings$anyNAValues, "anyNAValues") == TRUE){
            settings$anyNAValues <- FALSE
        }
        
        if(is_var_empty(settings$categoricalVariables, "categoricalVariables") == TRUE){
            settings$categoricalVariables <- FALSE
        }


        plot_unique_hash <- list(
            tsne_plot = list(
                main_plot = digest::digest(paste0(selectedFileID, "_",args$settings,"_tsne_plot_main"), algo="md5", serialize=F)
            ),

            tsne_cluster_plot = digest::digest(paste0(selectedFileID, "_",args$settings,"_tsne_cluster_plot"), algo="md5", serialize=F),
            tsne_cluster_heatmap_plot = digest::digest(paste0(selectedFileID, "_",args$settings,"_tsne_cluster_heatmap_plot"), algo="md5", serialize=F),
            cluster_features_means = digest::digest(paste0(selectedFileID, "_",args$settings,"_cluster_features_means"), algo="md5", serialize=F),
            cluster_features_means_separated = digest::digest(paste0(selectedFileID, "_",args$settings,"_cluster_features_means_separated"), algo="md5", serialize=F),
            saveObjectHash = digest::digest(paste0(selectedFileID, "_",args$settings,"_editing_tsne_render_plot"), algo="md5", serialize=F),
            saveDatasetHash = digest::digest(paste0(selectedFileID, "_",args$settings,"_editing_tsne_dataset_export"), algo="md5", serialize=F)
        )

        if(!is.null(settings$groupingVariables)){
            for(groupVariable in settings$groupingVariables){

                unique_hash <- paste0(selectedFileID, "_",args$settings,"_tsne_plot_",groupVariable)
                plot_unique_hash$tsne_plot[[groupVariable]] <- digest::digest(unique_hash, algo="md5", serialize=F)

                res.data$tsne_plot[[groupVariable]] <- list(name = NULL, svg = NULL, png = NULL, colorby = list())
                ## Color-by placeholder
                res.data$tsne_plot[[groupVariable]]$colorby <- list()
                if(!is.null(settings$colorVariables)){
                    for(colorVariable in settings$colorVariables){
                        unique_hash <- paste0(unique_hash,"_",colorVariable)
                        
                        plot_unique_hash$tsne_plot[[paste0(groupVariable,colorVariable)]] <- digest::digest(unique_hash, algo="md5", serialize=F)
                    }
                }
            }
        }

        resp_check <- getPreviouslySavedResponse(plot_unique_hash, res.data, 5)
        if(is.list(resp_check)){
            print("==> Serving request response from cache")
            ## return(resp_check)
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

        ## Load dataset
        dataset <- loadDataFromFileSystem(selectedFilePath)
        dataset_filtered <- dataset[, names(dataset) %in% c(settings$selectedColumns, settings$groupingVariables)]

        print(paste("==> Selected Columns 1: ", length(settings$selectedColumns), " Dataset columns: ",ncol(dataset_filtered), " Dataset rows: ", nrow(dataset_filtered)))

        ## Cast all non numeric values to NA
        vars_to_cast <- c(settings$colorVariables, settings$groupingVariables)
        if (is.null(vars_to_cast)){
            vars_to_cast <- character(0)
        }else{
            print(paste("==> Casting to NA: ", vars_to_cast))
        }

        print(paste0("==> castAllStringsToNA"))
        dataset_filtered <- castAllStringsToNA(dataset_filtered, vars_to_cast)

        print(paste0("==> Checking if variables are numeric"))
        ## TODO: Check if grouping variable is numeric and add prefix to it
        num_test <- dataset_filtered %>% select(where(is.numeric))

        for (groupVariable in settings$groupingVariables) {
            if(groupVariable %in% names(num_test)){
                dataset_filtered[[groupVariable]] <- paste("g",dataset_filtered[[groupVariable]],sep="_")
            }
        }

        ## save(settings, fileHeader, dataset, dataset_filtered, file = "/tmp/configuration.Rdata")

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

        print(paste("==> Selected Columns 5: ", length(settings$selectedColumns), " Dataset columns: ",ncol(dataset_filtered), " Dataset rows: ", nrow(dataset_filtered)))
        if(settings$removeNA == TRUE){
            print(paste0("=====> Removing NA Values"))
            dataset_filtered <- na.omit(dataset_filtered)
        }
        print(paste("==> Selected Columns 6: ", length(settings$selectedColumns), " Dataset columns: ",ncol(dataset_filtered), " Dataset rows: ", nrow(dataset_filtered)))

        if(nrow(dataset_filtered) <= 2) {
            print("==> No enough rows to proceed with PCA analysis")
            return (list(success = FALSE, message = FALSE, details = FALSE))
        }

        set.seed(1337)
        tsne_calc <- calculate_tsne(dataset_filtered, settings, fileHeader)

        res.data$tsne_perplexity <- tsne_calc$perplexity
        res.data$tsne_exaggeration_factor <- tsne_calc$exaggeration_factor
        res.data$tsne_max_iter <- tsne_calc$max_iter
        res.data$tsne_theta <- tsne_calc$theta
        res.data$tsne_eta <- tsne_calc$eta

        ## Main t-SNE plot 
        tmp_path <- plot_tsne(tsne_calc$info.norm, NULL, settings,  plot_unique_hash$tsne_plot[["main_plot"]])
        ## Color-by placeholder
        res.data$tsne_plot[["main_plot"]]$colorby <- list()
        res.data$tsne_plot[["main_plot"]]$name <- "Main plot"
        res.data$tsne_plot[["main_plot"]]$svg <- optimizeSVGFile(tmp_path)
        res.data$tsne_plot[["main_plot"]]$png <- convertSVGtoPNG(tmp_path)

        if(!is.null(settings$colorVariables)){

            for(colorVariable in settings$colorVariables){
                coloringVariable <- fileHeader %>% filter(remapped %in% colorVariable)
                coloringVariable <- coloringVariable$original

                plot_unique_hash$tsne_plot[[paste0("main_plot",colorVariable)]] <- digest::digest(paste0(selectedFileID, "_",args$settings,"_tsne_plot_main_",colorVariable), algo="md5", serialize=F)
                tmp_path_c <- plot_tsne_color_by(tsne_calc$info.norm, NULL, coloringVariable, settings,  plot_unique_hash$tsne_plot[[paste0("main_plot",colorVariable)]])

                res.data$tsne_plot[["main_plot"]]$colorby[[colorVariable]]$name <- coloringVariable
                res.data$tsne_plot[["main_plot"]]$colorby[[colorVariable]]$svg <- optimizeSVGFile(tmp_path_c)
                res.data$tsne_plot[["main_plot"]]$colorby[[colorVariable]]$png <- convertSVGtoPNG(tmp_path_c)
            }
        }


        if(!is.null(settings$groupingVariables)){
            for(groupVariable in settings$groupingVariables){
                # groupVariable is remaped value
                groupingVariable <- fileHeader %>% filter(remapped %in% groupVariable)
                groupingVariable <- groupingVariable$original

                tmp_path <- plot_tsne(tsne_calc$info.norm, groupingVariable, settings,  plot_unique_hash$tsne_plot[[groupVariable]])
                res.data$tsne_plot[[groupVariable]]$name <- groupingVariable
                res.data$tsne_plot[[groupVariable]]$svg <- optimizeSVGFile(tmp_path)
                res.data$tsne_plot[[groupVariable]]$png <- convertSVGtoPNG(tmp_path)

                if(!is.null(settings$colorVariables)){
                    for(colorVariable in settings$colorVariables){

                        coloringVariable <- fileHeader %>% filter(remapped %in% colorVariable)
                        coloringVariable <- coloringVariable$original

                        tmp_path_c <- plot_tsne_color_by(tsne_calc$info.norm, NULL, coloringVariable, settings,  plot_unique_hash$tsne_plot[[paste0(groupVariable,colorVariable)]])
                        res.data$tsne_plot[[groupVariable]]$colorby[[colorVariable]]$name <- coloringVariable
                        res.data$tsne_plot[[groupVariable]]$colorby[[colorVariable]]$svg <- optimizeSVGFile(tmp_path_c)
                        res.data$tsne_plot[[groupVariable]]$colorby[[colorVariable]]$png <- convertSVGtoPNG(tmp_path_c)
                    }
                }
            }
        }

        print(paste0("===> Clustering using", settings$clusterType))
        set.seed(1337)
        if(settings$clusterType == "Louvain"){
            tsne_clust <- list()
            iteration <- 1
            for (res_increment in settings$resolution_increments) {
                for (min_modularity in settings$min_modularities) {
                    tmp <- cluster_tsne_knn_louvain(tsne_calc$info.norm, tsne_calc$tsne.norm, settings, res_increment, min_modularity)

                    if(tmp$num_clusters < min(settings$target_clusters_range) && tmp$num_clusters > max(settings$target_clusters_range)){
                        message("===> INFO: Skipping cluster with ", tmp$num_clusters, " clusters")
                        next
                    }
                    
                    tsne_clust[[iteration]] <- tmp
                    iteration <- iteration + 1
                }
            }

            if(settings$pickBestClusterMethod == "Modularity"){
                tsne_clust <- pick_best_cluster_modularity(tsne_clust)
            }else if(settings$pickBestClusterMethod == "Silhouette"){
                tsne_clust <- pick_best_cluster_silhouette(tsne_clust)
            }else if(settings$pickBestClusterMethod == "Overall"){
                tsne_clust <- pick_best_cluster_overall(tsne_clust, tsne_calc)
            }else if(settings$pickBestClusterMethod == "SIMON"){

                if(is.null(settings$selectedColumnsSIMON)){
                    settings$selectedColumnsSIMON <- settings$selectedColumns
                    print(paste0("===> SIMON: Using selectedColumns: ", paste(settings$selectedColumnsSIMON, collapse = ", ")))
                }

                best_cluster <- pick_best_cluster_simon(dataset, tsne_clust, tsne_calc, settings)
                tsne_clust <- best_cluster$tsne_clust
            }else{
                tsne_clust <- pick_best_cluster_modularity(tsne_clust)
            }

        }else if(settings$clusterType == "Hierarchical"){
           tsne_clust <- cluster_tsne_hierarchical(tsne_calc$info.norm, tsne_calc$tsne.norm, settings)
        }else if(settings$clusterType == "Mclust"){
           tsne_clust <- cluster_tsne_mclust(tsne_calc$info.norm, tsne_calc$tsne.norm, settings)
        }else if(settings$clusterType == "Density"){
           tsne_clust <- cluster_tsne_density(tsne_calc$info.norm, tsne_calc$tsne.norm, settings)
        }else{
            tsne_clust <- list()
            iteration <- 1
            for (res_increment in settings$resolution_increments) {
                for (min_modularity in settings$min_modularities) {
                    tmp <- cluster_tsne_knn_louvain(tsne_calc$info.norm, tsne_calc$tsne.norm, settings, res_increment, min_modularity)

                    if(tmp$num_clusters < min(settings$target_clusters_range) && tmp$num_clusters > max(settings$target_clusters_range)){
                        message("===> INFO: Skipping cluster with ", tmp$num_clusters, " clusters")
                        next
                    }
                    
                    tsne_clust[[iteration]] <- tmp
                    iteration <- iteration + 1
                }
            }

            if(settings$pickBestClusterMethod == "Modularity"){
                tsne_clust <- pick_best_cluster_modularity(tsne_clust)
            }else if(settings$pickBestClusterMethod == "Silhouette"){
                tsne_clust <- pick_best_cluster_silhouette(tsne_clust)
            }else if(settings$pickBestClusterMethod == "Overall"){
                tsne_clust <- pick_best_cluster_overall(tsne_clust, tsne_calc)
            }else if(settings$pickBestClusterMethod == "SIMON"){
                if(is.null(settings$selectedColumnsSIMON)){
                    settings$selectedColumnsSIMON <- settings$selectedColumns
                    print(paste0("===> SIMON: Using selectedColumns: ", paste(settings$selectedColumnsSIMON, collapse = ", ")))
                }
                best_cluster <- pick_best_cluster_simon(dataset, tsne_clust, tsne_calc, settings)
                tsne_clust <- best_cluster$tsne_clust
            }else{
                tsne_clust <- pick_best_cluster_modularity(tsne_clust)
            }
        }

        res.data$avg_silhouette_score <- round(tsne_clust$avg_silhouette_score, 2)

        ## Get clusters from tsne_clust$info.norm[["cluster"]] and add it to original dataset in "dataset" variable
        dataset_with_clusters <- dataset
        if(nrow(dataset_with_clusters) == nrow(tsne_clust$info.norm)){
            dataset_with_clusters$pandora_cluster <- tsne_clust$info.norm$pandora_cluster
        }
        ## Rename column names to its originals
        names(dataset_with_clusters) <- plyr::mapvalues(names(dataset_with_clusters), from=fileHeader$remapped, to=fileHeader$original)
        
        dataset_with_clusters <- remove_outliers(dataset_with_clusters, settings)
        data_for_heatmap <- remove_outliers(tsne_clust$info.norm, settings)


        tmp_path <- plot_clustered_tsne(tsne_clust$info.norm, tsne_clust$cluster_data, settings, plot_unique_hash$tsne_cluster_plot)
        res.data$tsne_cluster_plot <- optimizeSVGFile(tmp_path)
        res.data$tsne_cluster_plot_png <- convertSVGtoPNG(tmp_path)

        tmp_path <- cluster_heatmap(data_for_heatmap, settings, plot_unique_hash$tsne_cluster_heatmap_plot)
        if(tmp_path != FALSE){
            res.data$tsne_cluster_heatmap_plot <- optimizeSVGFile(tmp_path)
            res.data$tsne_cluster_heatmap_plot_png <- convertSVGtoPNG(tmp_path)
        }

        tmp_path <- plot_cluster_features_means(data_for_heatmap, settings, plot_unique_hash$cluster_features_means)
        if(tmp_path != FALSE){
            res.data$cluster_features_means <- optimizeSVGFile(tmp_path)
            res.data$cluster_features_means_png <- convertSVGtoPNG(tmp_path)
        }

        tmp_path <- plot_cluster_features_means_separated(data_for_heatmap, settings, plot_unique_hash$cluster_features_means_separated)
        if(tmp_path != FALSE){
            res.data$cluster_features_means_separated <- optimizeSVGFile(tmp_path)
            res.data$cluster_features_means_separated_png <- convertSVGtoPNG(tmp_path)
        }

        # save(dataset_filtered, file="/tmp/dataset_filtered")
        # save(settings, file="/tmp/settings")
        # save(fileHeader, file="/tmp/fileHeader")

        ## save data for latter use
        tmp_path <- tempfile(pattern = plot_unique_hash[["saveObjectHash"]], tmpdir = tempdir(), fileext = ".Rdata")

        processingData <- list(
            # The original dataset loaded from the file system, containing all rows and columns before filtering or preprocessing.
            raw_dataset = dataset,
            # The dataset after filtering based on the selected columns, grouping variables, and preprocessing steps (e.g., removal of non-numeric values).
            filtered_dataset = dataset_filtered, 
             # The result of the t-SNE calculation, including the transformed data points (low-dimensional representation) and additional information like normalization.
            tsne_results = tsne_calc, 
            # The user-defined settings and parameters used for generating plots, t-SNE, clustering, and other analysis (e.g., point size, color palette, clustering method).
            analysis_settings = settings,
            # The results of clustering applied on the t-SNE output, including cluster assignments and silhouette scores.
            tsne_cluster_results = tsne_clust,
             # The original dataset enriched with the cluster assignments from the t-SNE clustering process, where each row now belongs to a cluster.
            dataset_with_clusters = dataset_with_clusters,
            # The data prepared for heatmap visualization, usually consisting of the clustered t-SNE output with additional features used for heatmap plotting.
            heatmap_data = data_for_heatmap
        )

        saveCachedList(tmp_path, processingData)
        res.data$saveObjectHash = substr(basename(tmp_path), 1, nchar(basename(tmp_path))-6)


        tmp_path <- tempfile(pattern = plot_unique_hash[["saveDatasetHash"]], tmpdir = tempdir(), fileext = ".csv")
        saveCachedList(tmp_path, dataset_with_clusters, type = "csv")
        res.data$saveDatasetHash = substr(basename(tmp_path), 1, nchar(basename(tmp_path))-4)



        return (list(success = TRUE, message = res.data))
    }
)
