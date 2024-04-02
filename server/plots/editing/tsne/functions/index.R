## T-Distributed Stochastic Neighbor Embedding using a Barnes-Hut Implementation
## https://cran.r-project.org/web/packages/Rtsne/Rtsne.pdf
calculate_tsne <- function(dataset, settings, fileHeader, removeGroups = TRUE){
	info.norm <- dataset
	# Remap column names
	names(info.norm) <- plyr::mapvalues(names(info.norm), from=fileHeader$remapped, to=fileHeader$original)

    if(!is.null(settings$groupingVariables) && removeGroups == TRUE){
    	print(paste0("====> Removing grouping variables"))
    	dataset <- dataset %>% select(-any_of(settings$groupingVariables)) 
    }

    # Remove non-numeric columns
	tsne_data <- dataset %>% select(where(is.numeric))
	num_samples <- nrow(tsne_data)
	num_features <- ncol(tsne_data)

    pca_result <- prcomp(dataset %>% select(where(is.numeric)), scale. = TRUE)
    explained_variance <- cumsum(pca_result$sdev^2) / sum(pca_result$sdev^2)
    initial_dims <- max(which(explained_variance <= 0.9)) # Adjust to keep 90% variance
    initial_dims <- min(initial_dims, 100) # Set a reasonable upper limit to ensure computational efficiency

    print(paste0("Using initial_dims: ", initial_dims))

    # Adjust perplexity based on dataset size, not to exceed half the number of rows
	perplexity <- min(settings$perplexity, nrow(dataset)/2)
	if (perplexity != settings$perplexity) {
		message("====> Adjusting perplexity to: ", perplexity)
	}

	header_mapped <- fileHeader %>% filter(remapped %in% names(tsne_data))

	pca.scale <- TRUE
	if(!is.null(settings$preProcessDataset) && length(settings$preProcessDataset) > 0){
		pca.scale <- FALSE
	}

    # Adjust max_iter based on dataset size and complexity
    # Example heuristic: Increase max_iter for larger or more complex datasets
    base_iter <- 1000
    complexity_factor <- sqrt(num_samples * num_features) / 500 # Example heuristic
    
    max_iter <- base_iter + (500 * complexity_factor)
    max_iter <- min(max_iter, 10000) # Setting an upper limit
    max_iter <- round(max_iter, 0)

    print(paste0("Using max_iter: ", max_iter))

 	eta <- 150
    # Dynamically adjust theta based on dataset size
    # Smaller datasets can use a more accurate (lower) theta
    if (num_samples < 1000) {
        theta <- 0  # More accurate, suitable for small datasets
    } else if (num_samples >= 1000 && num_samples < 5000) {
        theta <- 0.2  # Balance between accuracy and speed
        eta <- 250
    } else {
        theta <- 0.5  # Faster, suitable for larger datasets
        eta <- 250
    }
    print(paste0("Using theta: ", theta))

    tsne.norm <- Rtsne::Rtsne(
        as.matrix(tsne_data),
        dims = 2,
        perplexity = perplexity,
        pca = TRUE,
        pca_center = pca.scale,
        pca_scale = pca.scale,
        check_duplicates = FALSE,
        initial_dims = initial_dims,
        max_iter = max_iter,
        theta = theta,
        eta = eta,
        verbose = FALSE
    )

	info.norm <- info.norm %>% mutate(tsne1 = tsne.norm$Y[, 1], tsne2 = tsne.norm$Y[,2])

	return(list(info.norm = info.norm, tsne.norm = tsne.norm, tsne_columns = header_mapped$original))
}

## Plot TSNE data
plot_tsne <- function(info.norm, groupingVariable = NULL, settings, tmp_hash){ 
    theme_set(eval(parse(text=paste0(settings$theme, "()"))))

    print("============> plot_tsne")
    print(groupingVariable)
    print(names(info.norm))

    if(!is.null(groupingVariable)){
    	info.norm[[groupingVariable]] <- as.factor(info.norm[[groupingVariable]])
    	plotData <- ggplot(info.norm, aes_string(x = "tsne1", y = "tsne2", colour = groupingVariable))
	}else{
		plotData <- ggplot(info.norm, aes_string(x = "tsne1", y = "tsne2"))
	}

	plotData <- plotData + 
	    geom_point(size = settings$pointSize) +
	    labs(x = "t-SNE dimension 1", y = "t-SNE dimension 2") + 
	    scale_color_brewer(palette=settings$colorPalette) + 
        theme(text=element_text(size=settings$fontSize), legend.position = settings$legendPosition)


    tmp_path <- tempfile(pattern =  tmp_hash, tmpdir = tempdir(), fileext = ".svg")
    svg(tmp_path, width = settings$plot_size * settings$aspect_ratio, height = settings$plot_size, pointsize = 12, onefile = TRUE, family = "Arial", bg = "white", antialias = "default")
        print(plotData)
    dev.off()  

    return(tmp_path) 
}

plot_tsne_color_by <- function(info.norm, groupingVariable = NULL, colorVariable, settings, tmp_hash){ 
    theme_set(eval(parse(text=paste0(settings$theme, "()"))))


    print("============> plot_tsne_color_by")
    print(groupingVariable)
    print(names(info.norm))

    if(!is.null(groupingVariable)){
    	info.norm[[groupingVariable]] <- as.factor(info.norm[[groupingVariable]])
    	plotData <- ggplot(info.norm, aes_string(x = "tsne1", y = "tsne2", colour = groupingVariable)) + 
				    geom_point(size = settings$pointSize) +
				    labs(x = "t-SNE dimension 1", y = "t-SNE dimension 2") + 
			        theme(text=element_text(size=settings$fontSize), legend.position = settings$legendPosition)
	}else{
		plotData <- ggplot(info.norm, aes_string(x = "tsne1", y = "tsne2", colour = colorVariable))+ 
				    geom_point(size = settings$pointSize) +
            		scale_color_continuous(low = "gray", high = "red", guide = "colourbar", aesthetics = "colour") +
				    labs(x = "t-SNE dimension 1", y = "t-SNE dimension 2") + 
			        theme(text=element_text(size=settings$fontSize), legend.position = settings$legendPosition)
	}


    tmp_path <- tempfile(pattern =  tmp_hash, tmpdir = tempdir(), fileext = ".svg")
    svg(tmp_path, width = settings$plot_size * settings$aspect_ratio, height = settings$plot_size, pointsize = 12, onefile = TRUE, family = "Arial", bg = "white", antialias = "default")
        print(plotData)
    dev.off()  

    return(tmp_path) 
}

## https://jmonlong.github.io/Hippocamplus/2018/02/13/tsne-and-clustering/

# KNN graph and Louvain community detection
cluster_tsne_knn_louvain <- function(info.norm, tsne.norm, settings){
	set.seed(1337)
	knn_clusters <- settings$knn_clusters
    if(nrow(tsne.norm$Y) < knn_clusters){
    	knn_clusters <- round(nrow(tsne.norm$Y) / 2)
    	print(paste0("====> Quick-fix - Rtsne->tsne.norm->Y rows: ",nrow(tsne.norm$Y)," Adjusting KNN k to half of it: ", knn_clusters))
    }

    print(paste0("====>Maximum number of nearest neighbors to search: ", knn_clusters))


	knn.norm = FNN::get.knn(as.matrix(tsne.norm$Y), k = knn_clusters)
	knn.norm = data.frame(
					from = rep(1:nrow(knn.norm$nn.index), knn_clusters), 
					to = as.vector(knn.norm$nn.index), 
					weight = 1/(1 + as.vector(knn.norm$nn.dist))
				)

	nw.norm = igraph::graph_from_data_frame(knn.norm, directed = FALSE)
	nw.norm = igraph::simplify(nw.norm)
	lc.norm = igraph::cluster_louvain(nw.norm)

	info.norm$cluster = as.factor(igraph::membership(lc.norm))

	lc.cent = info.norm %>% group_by(cluster) %>% 
							select(tsne1, tsne2) %>% 
							summarize_all(mean)

	return(list(info.norm = info.norm, cluster_data = lc.cent))
}

# Hierarchical clustering
cluster_tsne_hierarchical <- function(info.norm, tsne.norm, settings) {
    # Validate settings
    if (!"clustLinkage" %in% names(settings) || !"clustGroups" %in% names(settings)) {
        stop("Settings must include 'clustLinkage' and 'clustGroups'.")
    }

    # Prepare data for DBSCAN
    tsne_data <- tsne.norm$Y

    # Calculate minPts and eps dynamically based on settings
    minPts_baseline <- dim(tsne_data)[2] * 2
    minPts <- max(2, settings$minPtsAdjustmentFactor * minPts_baseline)
    k_dist <- dbscan::kNNdist(tsne_data, k = minPts - 1)
    eps_quantile <- settings$epsQuantile
    eps <- stats::quantile(k_dist, eps_quantile)
    dbscan_result <- dbscan::dbscan(tsne_data, eps = eps, minPts = minPts)

    # Update info.norm with DBSCAN results (cluster assignments, including noise)
    info.norm$cluster <- as.factor(dbscan_result$cluster)
    non_noise_indices <- which(dbscan_result$cluster != 0)

    # Decision to include or exclude outliers in the hierarchical clustering
    data_for_clustering <- if (settings$excludeOutliers) tsne_data[non_noise_indices, ] else tsne_data
    indices_for_clustering <- if (settings$excludeOutliers) non_noise_indices else seq_len(nrow(tsne_data))

     if (settings$excludeOutliers){
     	message("Excluding outliers from hierarchical clustering.")
     }else{
	 	message("Including outliers in hierarchical clustering.")
	 }

    if (length(indices_for_clustering) >= 2) {
        dist_matrix <- dist(data_for_clustering, method = settings$distMethod)
        hc.norm <- hclust(dist_matrix, method = settings$clustLinkage)
        h_clusters <- cutree(hc.norm, settings$clustGroups)

        # Apply cluster assignments back based on exclusion/inclusion decision
        info.norm$cluster[indices_for_clustering] <- as.factor(h_clusters)
    } else {
        warning("Not enough data points for hierarchical clustering.")
    }

    # Reassign outliers to a unique cluster if enabled
    if (settings$assignOutliers && any(dbscan_result$cluster == 0)) {
        outlier_cluster <- max(as.integer(info.norm$cluster), na.rm = TRUE) + 1
        info.norm$cluster[dbscan_result$cluster == 0] <- as.factor(outlier_cluster)
    }

    # Compute cluster centers based on final clustering results
    lc.cent <- info.norm %>%
        group_by(cluster) %>%
        summarize(across(c(tsne1, tsne2), median, na.rm = TRUE), .groups = 'drop')

    return(list(info.norm = info.norm, cluster_data = lc.cent, is_outlier = dbscan_result$cluster == 0, eps = eps, minPts = minPts))
}


# Mclust clustering
cluster_tsne_mclust <- function(info.norm, tsne.norm, settings) {
    print(paste("==> cluster_tsne_mclust clustGroups: ", settings$clustGroups))

    # Prepare data for DBSCAN
    tsne_data <- tsne.norm$Y

    # Calculate minPts and eps dynamically based on settings
    minPts_baseline <- dim(tsne_data)[2] * 2
    minPts <- max(2, settings$minPtsAdjustmentFactor * minPts_baseline)
    k_dist <- dbscan::kNNdist(tsne_data, k = minPts - 1)
    eps_quantile <- settings$epsQuantile
    eps <- stats::quantile(k_dist, eps_quantile)

    dbscan_result <- dbscan::dbscan(tsne_data, eps = eps, minPts = minPts)

    # Update info.norm with DBSCAN results (cluster assignments, including noise)
    info.norm$cluster <- as.factor(dbscan_result$cluster)
    non_noise_indices <- which(dbscan_result$cluster != 0)

    # Decision to include or exclude outliers in the hierarchical clustering
    data_for_clustering <- if (settings$excludeOutliers) tsne_data[non_noise_indices, ] else tsne_data
    indices_for_clustering <- if (settings$excludeOutliers) non_noise_indices else seq_len(nrow(tsne_data))

     if (settings$excludeOutliers){
        message("Excluding outliers from hierarchical clustering.")
     }else{
        message("Including outliers in hierarchical clustering.")
     }

    if (length(indices_for_clustering) >= 2) {
        # Perform Mclust clustering on non-noise points
        mc.norm <- mclust::Mclust(data_for_clustering, G = settings$clustGroups)
        # Update Mclust cluster assignments back to the original dataset
        info.norm$cluster[indices_for_clustering] <- factor(mc.norm$classification)
    } else {
        warning("Not enough data points for hierarchical clustering.")
    }

    # Reassign outliers to a unique cluster if enabled
    if (settings$assignOutliers && any(dbscan_result$cluster == 0)) {
        outlier_cluster <- max(as.integer(info.norm$cluster), na.rm = TRUE) + 1
        info.norm$cluster[dbscan_result$cluster == 0] <- as.factor(outlier_cluster)
    }

    # Compute cluster centers for non-outlier clusters
    lc.cent <- info.norm %>%
        group_by(cluster) %>%
        summarize(across(c(tsne1, tsne2), median, na.rm = TRUE), .groups = 'drop')

    return(list(info.norm = info.norm, cluster_data = lc.cent, is_outlier = dbscan_result$cluster == 0, eps = eps, minPts = minPts))
}

#Density-based clustering
cluster_tsne_density <- function(info.norm, tsne.norm, settings){
	set.seed(1337)
	ds.norm = fpc::dbscan(tsne.norm$Y, settings$reachabilityDistance)
	info.norm$cluster = factor(ds.norm$cluster)
	lc.cent = info.norm %>% group_by(cluster) %>% 
							select(tsne1, tsne2) %>% 
							summarize_all(mean)

	return(list(info.norm = info.norm, cluster_data = lc.cent))
}


plot_clustered_tsne <- function(info.norm, cluster_data, settings, tmp_hash){
    theme_set(eval(parse(text=paste0(settings$theme, "()"))))

    # Convert 'cluster' to a factor with consistent levels in both data frames
    unique_clusters <- sort(unique(c(info.norm$cluster, cluster_data$cluster)))

    info.norm$cluster <- factor(info.norm$cluster, levels = unique_clusters)
    cluster_data$cluster <- factor(cluster_data$cluster, levels = unique_clusters)

    # Create the plot with consistent color mapping
    plotData <- ggplot(info.norm, aes(x = tsne1, y = tsne2)) + 
                    geom_point(aes(color = cluster), size = settings$pointSize) +  # Color by cluster for points
                    scale_color_brewer(palette = settings$colorPalette) +  # Use Brewer palette for consistent color scale
                    labs(x = "t-SNE dimension 1", y = "t-SNE dimension 2", color = "Cluster") +  # Label axes and legend
                    theme_classic(base_size = settings$fontSize) +  # Use a classic theme as base
                    theme(legend.position = settings$legendPosition,  # Adjust legend position
                          legend.background = element_rect(fill = "white", colour = "black"),  # Legend background
                          legend.key.size = unit(0.5, "cm"),  # Size of legend keys
                          legend.title = element_text(face = "bold"),  # Bold legend title
                          plot.background = element_rect(fill = "white", colour = NA))  # White plot background

    # Adding cluster center labels with the same color mapping
    plotData <- plotData +
                geom_label(data = cluster_data, aes(x = tsne1, y = tsne2, label = as.character(cluster), color = cluster),
                           fill = "white",  # Background color of the label; adjust as needed
                           size = settings$fontSize / 2,  # Adjust text size within labels as needed
                           fontface = "bold",  # Make text bold
                           show.legend = FALSE)  # Do not show these labels in the legend



    # Specify the file path for the output plot
    tmp_path <- tempfile(pattern = tmp_hash, tmpdir = tempdir(), fileext = ".svg")
    svg(tmp_path, width = settings$plot_size * settings$aspect_ratio, height = settings$plot_size, pointsize = 12, onefile = TRUE, family = "Arial", bg = "white", antialias = "default")
        print(plotData)
    dev.off()

    return(tmp_path)
}

cluster_heatmap <-function(clust_plot_tsne, settings, tmp_hash){

	## To be sure remove all other non numeric columns
	clust_plot_tsne$info.norm$cluster <- as.numeric(clust_plot_tsne$info.norm$cluster)

	info.norm.num <- clust_plot_tsne$info.norm %>% select(where(is.numeric))
	all_columns <- colnames(info.norm.num)

	selectedRows <- all_columns[! all_columns %in% c("tsne1", "tsne2", "cluster", settings$groupingVariables)] 
	input_data <- info.norm.num %>% select(any_of(all_columns[! all_columns %in% c("tsne1", "tsne2", settings$groupingVariables)]))


    if(settings$datasetAnalysisType == "heatmap"){
    	plotClustered <- FALSE
    }else{
    	plotClustered <- TRUE
    }

	# Dynamic font size adjustment based on the number of rows and columns
	num_rows <- nrow(input_data)
	num_columns <- length(selectedRows)

	base_font_size <- settings$fontSize
	adjusted_font_size_row <- max(base_font_size - num_rows / 50, 1)
	adjusted_font_size_col <- max(base_font_size - num_columns / 25, 1)

	print(paste0("====> Adjusted font size row: ", base_font_size - num_rows / 50))
	print(paste0("====> Adjusted font size row: ", adjusted_font_size_row))

	print(paste0("====> Adjusted font size col: ", base_font_size - num_columns / 25))
	print(paste0("====> Adjusted font size col: ", adjusted_font_size_col))

	# Use the smaller of the two sizes for general text to ensure consistency
	adjusted_font_size_general <- min(adjusted_font_size_row, adjusted_font_size_col)
	print(paste0("====> Adjusted font size general: ", adjusted_font_size_general))

    input_args <- c(list(data=input_data, 
						fileHeader=NULL,

						selectedColumns=c("cluster"),
						selectedRows=selectedRows,

						removeNA=TRUE,

						scale="column",

						displayNumbers=FALSE,
						displayLegend=TRUE,
						displayColnames=FALSE,
						displayRownames=TRUE,

						plotWidth=settings$plot_size,
						plotRatio=settings$aspect_ratio,

						clustDistance="euclidean",
						clustLinkage=settings$datasetAnalysisClustLinkage, 
						clustOrdering=settings$datasetAnalysisClustOrdering,

						fontSizeGeneral = adjusted_font_size_general,
						fontSizeRow = adjusted_font_size_row,
						fontSizeCol = adjusted_font_size_col,
						fontSizeNumbers = max(adjusted_font_size_general - 2, 3),  # Ensure numbers are slightly smaller for clarity

						settings=settings,

						plotClustered = plotClustered,
						orederingColumn = settings$datasetAnalysisSortColumn))


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
	    tmp_path <- tempfile(pattern =  tmp_hash, tmpdir = tempdir(), fileext = ".svg")
	    svg(tmp_path, width = settings$plot_size * settings$aspect_ratio, height = settings$plot_size, pointsize = 12, onefile = TRUE, family = "Arial", bg = "white", antialias = "default")
	        print(clustering_out)
	    dev.off()  
	    return(tmp_path)
    }else{
    	print("===> Error while processing:")
    	print(clustering_out)
    	return(FALSE)
    }
}
