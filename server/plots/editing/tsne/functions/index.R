## T-Distributed Stochastic Neighbor Embedding using a Barnes-Hut Implementation
## https://cran.r-project.org/web/packages/Rtsne/Rtsne.pdf
## The calculate_tsne function is designed to perform t-distributed Stochastic Neighbor Embedding (t-SNE) on a given dataset, 
## with careful handling of potential edge cases to ensure robustness across various use cases. 
## 
## Dimensionality Reduction: The primary purpose of the function is to reduce high-dimensional data into a 2-dimensional space 
## using t-SNE for visualization and analysis.
## Dynamic Parameter Adjustment: It dynamically adjusts t-SNE parameters based on the dataset's characteristics 
## to optimize performance and prevent errors.
## Data Validation: Implements several checks to ensure the input data is suitable for t-SNE, handling issues like 
## insufficient data, missing values, and non-numeric columns.

calculate_tsne <- function(dataset, settings, fileHeader, removeGroups = TRUE){
    set.seed(1337)

    info.norm <- dataset
    # Remap column names
    names(info.norm) <- plyr::mapvalues(names(info.norm), from = fileHeader$remapped, to = fileHeader$original)

    if(!is.null(settings$groupingVariables) && removeGroups == TRUE){
        print(paste0("====> Removing grouping variables: ", settings$groupingVariables))
        dataset <- dataset %>% select(-any_of(settings$groupingVariables)) 
    }

    # Remove non-numeric columns
    tsne_data <- dataset %>% select(where(is.numeric))

    # Check for sufficient numeric columns
    if(ncol(tsne_data) < 1){
        stop("Not enough numeric columns to perform t-SNE.")
    }

    # Remove columns with zero variance
    tsne_data <- tsne_data %>% select(where(~ var(.) != 0))

    # Re-check after removing zero variance columns
    if(ncol(tsne_data) < 1){
        stop("Not enough variable numeric columns to perform t-SNE.")
    }

    # Check for NA values
    if(any(is.na(tsne_data))){
        stop("Input data for t-SNE contains missing values.")
    }

    num_samples <- nrow(tsne_data)
    num_features <- ncol(tsne_data)

    # Ensure sufficient samples
    if(num_samples < 4){
        stop("Not enough data to perform t-SNE (minimum 4 samples required).")
    }

    # Perform PCA to determine initial_dims
    pca_result <- prcomp(tsne_data, scale. = TRUE)
    explained_variance <- cumsum(pca_result$sdev^2) / sum(pca_result$sdev^2)

    if(any(explained_variance <= 0.9)){
        initial_dims <- max(which(explained_variance <= 0.9))
    } else {
        initial_dims <- 1
    }
    initial_dims <- min(initial_dims, ncol(tsne_data), 100)
    initial_dims <- max(initial_dims, 1)

    print(paste0("Using initial_dims: ", initial_dims))

    # Adjust perplexity based on dataset size

    if (!is.null(settings$perplexity) && settings$perplexity > 0){
        print("Using provided perplexity")

        perplexity <- settings$perplexity
    }else{
        print("Using dynamic perplexity")

        settings$perplexity <- 30
        max_perplexity <- floor((num_samples - 1) / 3)
        if(max_perplexity < 1){
            stop("Not enough data to compute perplexity.")
        }
        perplexity <- min(settings$perplexity, max_perplexity)
        if (perplexity != settings$perplexity) {
            message("====> Adjusting perplexity to: ", perplexity)
        }
    }


    header_mapped <- fileHeader %>% filter(remapped %in% names(tsne_data))

    pca.scale <- TRUE
    if(!is.null(settings$preProcessDataset) && length(settings$preProcessDataset) > 0){
        pca.scale <- FALSE
    }


    # Set t-SNE parameters
    # Check if settings are provided and not zero
    if (!is.null(settings$max_iter) && settings$max_iter != 0 ||
        !is.null(settings$eta) && settings$eta != 0) {
        # Use the provided settings
        max_iter <- settings$max_iter
        eta <- settings$eta

        theta <- settings$theta
    } else {
        # Adjust max_iter and other parameters based on dataset size
        if (num_samples < 500) {
            max_iter <- 10000  # Increased iterations for small datasets
            theta <- 0         # Use exact t-SNE
            eta <- 500         # Higher learning rate
        } else {
            # Adjust max_iter based on dataset complexity
            base_iter <- 3000
            complexity_factor <- sqrt(num_samples * num_features) / 500
            max_iter <- base_iter + (500 * complexity_factor)
            max_iter <- min(max_iter, 10000)
            max_iter <- round(max_iter, 0)
            
            eta <- 150
            # Dynamically adjust theta and eta based on dataset size
            if (num_samples < 5000) {
                theta <- 0.2
                eta <- 250
            } else {
                theta <- 0.5
                eta <- 250
            }
        }
    }


    # Set exaggeration_factor
    if (!is.null(settings$exaggeration_factor) && settings$exaggeration_factor != 0) {
        exaggeration_factor <- settings$exaggeration_factor
    } else {
        # Adjust exaggeration_factor based on dataset size
        if (num_samples < 500) {
            exaggeration_factor <- 4
        } else if (num_samples < 2000) {
            exaggeration_factor <- 8
        } else {
            exaggeration_factor <- 12
        }
    }

    print(paste0("Using max_iter: ", max_iter))
    print(paste0("Using theta: ", theta))
    print(paste0("Using eta: ", eta))
    print(paste0("Using exaggeration_factor: ", exaggeration_factor))

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
        exaggeration_factor = exaggeration_factor,
        verbose = FALSE,
        num_threads = 1
    )

    info.norm <- info.norm %>% mutate(tsne1 = tsne.norm$Y[, 1], tsne2 = tsne.norm$Y[,2])

    return(list(
        info.norm = info.norm,
        tsne.norm = tsne.norm, 
        tsne_columns = header_mapped$original, 
        initial_dims = initial_dims, 
        perplexity = perplexity, 
        exaggeration_factor = exaggeration_factor,
        max_iter = max_iter, 
        theta = theta, 
        eta = eta
    ))
}



## Plot TSNE data
plot_tsne <- function(info.norm, groupingVariable = NULL, settings, tmp_hash){ 
    theme_set(eval(parse(text=paste0(settings$theme, "()"))))

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


# KNN graph and Louvain community detection
## https://jmonlong.github.io/Hippocamplus/2018/02/13/tsne-and-clustering/
cluster_tsne_knn_louvain <- function(info.norm, tsne.norm, settings){
	set.seed(1337)

    # Debugging: Print dimensions of info.norm and tsne.norm$Y
    print(paste0("===> INFO: info.norm dimensions: ", paste(dim(info.norm), collapse = " x ")))
    print(paste0("===> INFO: tsne.norm$Y dimensions: ", paste(dim(tsne.norm$Y), collapse = " x ")))

	knn_clusters <- settings$knn_clusters
    if(nrow(tsne.norm$Y) < knn_clusters){
    	knn_clusters <- round(nrow(tsne.norm$Y) / 2)
    	print(paste0("===> INFO: Quick-fix - Rtsne->tsne.norm->Y rows: ",nrow(tsne.norm$Y)," Adjusting KNN k to half of it: ", knn_clusters))
    }

    print(paste0("===> INFO: Maximum number of nearest neighbors to search: ", knn_clusters))

	knn.norm = FNN::get.knn(as.matrix(tsne.norm$Y), k = knn_clusters)
	knn.norm = data.frame(
					from = rep(1:nrow(knn.norm$nn.index), knn_clusters), 
					to = as.vector(knn.norm$nn.index), 
					weight = 1/(1 + as.vector(knn.norm$nn.dist))
				)

	nw.norm = igraph::graph_from_data_frame(knn.norm, directed = FALSE)
	nw.norm = igraph::simplify(nw.norm)

    lc.norm <- igraph::cluster_louvain(nw.norm)

    # Debugging: Print number of clusters found
    num_clusters <- length(unique(igraph::membership(lc.norm)))
    print(paste0("===> INFO: Number of clusters found by cluster_louvain: ", num_clusters))
    modularity <- igraph::modularity(lc.norm)
    print(paste0("===> INFO: Modularity: ", modularity))

    info.norm$pandora_cluster <- as.factor(igraph::membership(lc.norm))

    # Debugging: Check for NA values in pandora_cluster
    num_na_clusters <- sum(is.na(info.norm$pandora_cluster))
    print(paste0("===> INFO: Number of NA clusters in pandora_cluster: ", num_na_clusters))

    # Replace NA values with 100 specifically
    na_indices <- is.na(info.norm$pandora_cluster)
    num_na <- sum(na_indices)
    if(num_na > 0){
        # Add 100 to the levels of pandora_cluster
        info.norm$pandora_cluster <- factor(info.norm$pandora_cluster, levels = c(levels(info.norm$pandora_cluster), "100"))
        # Now assign 100 to NA indices
        info.norm$pandora_cluster[na_indices] <- "100"
        print(paste0("===> INFO: Replaced ", num_na, " NA cluster assignments with 100"))
    }

    distance_matrix <- dist(tsne.norm$Y)
    print(paste0("===> INFO: Distance matrix computed with size: ", attr(distance_matrix, "Size")))

    silhouette_scores <- cluster::silhouette(as.integer(info.norm$pandora_cluster), distance_matrix)
    if(is.matrix(silhouette_scores)) {
        # Extract the silhouette widths from the scores
        silhouette_widths <- silhouette_scores[, "sil_width"]
        avg_silhouette_score <- mean(silhouette_widths, na.rm = TRUE)
        print(paste0("===> INFO: Average silhouette score: ", avg_silhouette_score))
    } else {
        print("===> INFO: Silhouette scores computation did not return a matrix.")
    }

    # Compute cluster centers based on final clustering results
    lc.cent <- info.norm %>%
        group_by(pandora_cluster) %>%
        summarize(across(c(tsne1, tsne2), median, na.rm = TRUE), .groups = 'drop')

    # Debugging: Print number of cluster centers computed
    print(paste0("===> INFO: Computed cluster centers for ", nrow(lc.cent), " clusters"))

    # Compute cluster sizes (number of samples per cluster)
    cluster_sizes <- info.norm %>%
      group_by(pandora_cluster) %>%
      summarise(num_samples = n(), .groups = 'drop') # Calculate the number of samples in each cluster

    # Join the cluster sizes back to the lc.cent dataframe to include the number of samples per cluster
    lc.cent <- lc.cent %>%
      left_join(cluster_sizes, by = "pandora_cluster")

    # Create the 'label' column that combines cluster ID and number of samples
    lc.cent <- lc.cent %>%
      mutate(label = paste(pandora_cluster, "-", num_samples))

    # Drop the 'num_samples' column if you no longer need it
    lc.cent <- select(lc.cent, -num_samples)

    return(list(info.norm = info.norm, cluster_data = lc.cent, avg_silhouette_score = avg_silhouette_score, modularity = modularity))
}

# Hierarchical clustering
cluster_tsne_hierarchical <- function(info.norm, tsne.norm, settings) {
    set.seed(1337)
    # Validate settings
    if (!"clustLinkage" %in% names(settings) || !"clustGroups" %in% names(settings)) {
        stop("Settings must include 'clustLinkage' and 'clustGroups'.")
    }

    avg_silhouette_score <- 0

    # Prepare data for DBSCAN
    tsne_data <- tsne.norm$Y

    # Calculate minPts and eps dynamically based on settings
    minPts_baseline <- dim(tsne_data)[2] * 2
    minPts <- max(2, settings$minPtsAdjustmentFactor * minPts_baseline)
    k_dist <- dbscan::kNNdist(tsne_data, k = minPts - 1)
    eps_quantile <- settings$epsQuantile
    eps <- stats::quantile(k_dist, eps_quantile)
    dbscan_result <- dbscan::dbscan(tsne_data, eps = eps, minPts = minPts)

    # Mark outliers as cluster "100"
    dbscan_result$cluster[dbscan_result$cluster == 0] <- 100
    # Update info.norm with DBSCAN results (cluster assignments, including marked outliers)
    info.norm$pandora_cluster <- as.factor(dbscan_result$cluster)
    non_noise_indices <- which(dbscan_result$cluster != 100) # Outliers are now marked as "100"
    noise_indices <- which(dbscan_result$cluster == 100)

    # Include or exclude outliers in the hierarchical clustering based on settings
    data_for_clustering <- if (settings$excludeOutliers) tsne_data[non_noise_indices, ] else tsne_data
    indices_for_clustering <- if (settings$excludeOutliers) non_noise_indices else seq_len(nrow(tsne_data))

    if (settings$excludeOutliers) {
        message("Excluding outliers from hierarchical clustering.")
    } else {
        message("Including outliers in hierarchical clustering.")
    }
    if (length(indices_for_clustering) >= 2) {
        dist_matrix <- dist(data_for_clustering, method = settings$distMethod)
        hc.norm <- hclust(dist_matrix, method = settings$clustLinkage)
        h_clusters <- cutree(hc.norm, settings$clustGroups)

        if(length(indices_for_clustering) < nrow(tsne_data)){
            info.norm$pandora_cluster[indices_for_clustering] <- as.factor(h_clusters)
        }else{
            info.norm$pandora_cluster <- as.factor(h_clusters)
        }

        # Replace NA values with 100 specifically
        na_indices <- is.na(info.norm$pandora_cluster)
        info.norm$pandora_cluster[na_indices] <- 100

        # Calculate distances based on the exact data used for clustering
        distance_matrix <- dist(data_for_clustering)
        # Ensure cluster labels are integers and align with the distance matrix
        cluster_labels <- as.integer(factor(info.norm$pandora_cluster[indices_for_clustering]))
        # Calculate silhouette scores using the aligned data
        silhouette_scores <- cluster::silhouette(cluster_labels, distance_matrix)

        if(is.matrix(silhouette_scores)) {
            # Extract the silhouette widths from the scores
            silhouette_widths <- silhouette_scores[, "sil_width"]
            avg_silhouette_score <- mean(silhouette_widths, na.rm = TRUE)
        }

        if(length(noise_indices) > 0){
            print(paste("====> Noise indices: ", length(noise_indices)))
            if(!"100" %in% levels(info.norm$pandora_cluster)) {
                info.norm$pandora_cluster <- factor(info.norm$pandora_cluster, levels = c(levels(info.norm$pandora_cluster), "100"))
                info.norm$pandora_cluster[noise_indices] <- "100"
            }
        }

        print(paste("====> Noise indices done"))

    } else {
        warning("Not enough data points for hierarchical clustering.")
    }

    # Ensure all cluster assignments, including outliers marked as "100", are recognized as valid levels
    info.norm$pandora_cluster <- factor(info.norm$pandora_cluster, levels = unique(as.character(info.norm$pandora_cluster)))

    # Compute cluster centers based on final clustering results
    lc.cent <- info.norm %>%
      group_by(pandora_cluster) %>%
      summarise(tsne1 = if(unique(pandora_cluster) == "100") min(tsne1, na.rm = TRUE) + settings$pointSize/2 else median(tsne1, na.rm = TRUE),
                tsne2 = if(unique(pandora_cluster) == "100") min(tsne2, na.rm = TRUE) + settings$pointSize/2 else median(tsne2, na.rm = TRUE),
                .groups = 'drop')
    # Compute cluster sizes (number of samples per cluster)
    cluster_sizes <- info.norm %>%
      group_by(pandora_cluster) %>%
      summarise(num_samples = n(), .groups = 'drop') # Calculate the number of samples in each cluster
    # Join the cluster sizes back to the lc.cent dataframe to include the number of samples per cluster
    lc.cent <- lc.cent %>%
      left_join(cluster_sizes, by = "pandora_cluster")
    # Create the 'label' column that combines cluster ID and number of samples
    lc.cent <- lc.cent %>%
      mutate(label = paste(pandora_cluster, "-", num_samples))
    # Drop the 'num_samples' column if you no longer need it
    lc.cent <- select(lc.cent, -num_samples)

    return(list(info.norm = info.norm, cluster_data = lc.cent, avg_silhouette_score = avg_silhouette_score))
}



# Mclust clustering
cluster_tsne_mclust <- function(info.norm, tsne.norm, settings) {
    set.seed(1337)
    print(paste("==> cluster_tsne_mclust clustGroups: ", settings$clustGroups))

    avg_silhouette_score <- 0

    # Prepare data for DBSCAN
    tsne_data <- tsne.norm$Y

    # Calculate minPts and eps dynamically based on settings
    minPts_baseline <- dim(tsne_data)[2] * 2
    minPts <- max(2, settings$minPtsAdjustmentFactor * minPts_baseline)
    k_dist <- dbscan::kNNdist(tsne_data, k = minPts - 1)
    eps_quantile <- settings$epsQuantile
    eps <- stats::quantile(k_dist, eps_quantile)
    
    dbscan_result <- dbscan::dbscan(tsne_data, eps = eps, minPts = minPts)

    # Mark outliers as cluster "100"
    dbscan_result$cluster[dbscan_result$cluster == 0] <- 100

    # Update info.norm with DBSCAN results (cluster assignments, including marked outliers)
    info.norm$pandora_cluster <- as.factor(dbscan_result$cluster)
    non_noise_indices <- which(dbscan_result$cluster != 100) # Outliers are now marked as "100"
    noise_indices <- which(dbscan_result$cluster == 100)

    # Include or exclude outliers in the Mclust clustering based on settings
    data_for_clustering <- if (settings$excludeOutliers) tsne_data[non_noise_indices, ] else tsne_data
    indices_for_clustering <- if (settings$excludeOutliers) non_noise_indices else seq_len(nrow(tsne_data))

    if (settings$excludeOutliers) {
        message("Excluding outliers from Mclust clustering.")
    } else {
        message("Including outliers in Mclust clustering.")
    }


    if (length(indices_for_clustering) >= 2) {
        mc.norm <- mclust::Mclust(data_for_clustering, G = settings$clustGroups)

        if(length(indices_for_clustering) < nrow(tsne_data)){
            info.norm$pandora_cluster[indices_for_clustering] <- as.factor(mc.norm$classification)
        }else{
            info.norm$pandora_cluster <- as.factor(mc.norm$classification)
        }

        # Replace NA values with 100 specifically
        na_indices <- is.na(info.norm$pandora_cluster)
        info.norm$pandora_cluster[na_indices] <- "100"

        # Calculate distances based on the exact data used for clustering
        distance_matrix <- dist(data_for_clustering)
        # Ensure cluster labels are integers and align with the distance matrix
        cluster_labels <- as.integer(factor(info.norm$pandora_cluster[indices_for_clustering]))
        # Calculate silhouette scores using the aligned data
        silhouette_scores <- cluster::silhouette(cluster_labels, distance_matrix)
        if(is.matrix(silhouette_scores)) {
            # Extract the silhouette widths from the scores
            silhouette_widths <- silhouette_scores[, "sil_width"]
            avg_silhouette_score <- mean(silhouette_widths, na.rm = TRUE)
        }

        if(length(noise_indices) > 0){
            print(paste("====> Noise indices: ", length(noise_indices)))
            if(!"100" %in% levels(info.norm$pandora_cluster)) {
                info.norm$pandora_cluster <- factor(info.norm$pandora_cluster, levels = c(levels(info.norm$pandora_cluster), "100"))
                info.norm$pandora_cluster[noise_indices] <- "100"
            }
        }

    } else {
        warning("Not enough data points for hierarchical clustering.")
    }

    # Ensure all cluster assignments, including outliers marked as "100", are recognized as valid levels
    info.norm$pandora_cluster <- factor(info.norm$pandora_cluster, levels = unique(as.character(info.norm$pandora_cluster)))




    # Compute cluster centers based on final clustering results
    lc.cent <- info.norm %>%
      group_by(pandora_cluster) %>%
      summarise(tsne1 = if(unique(pandora_cluster) == "100") min(tsne1, na.rm = TRUE) + settings$pointSize/2 else median(tsne1, na.rm = TRUE),
                tsne2 = if(unique(pandora_cluster) == "100") min(tsne2, na.rm = TRUE) + settings$pointSize/2 else median(tsne2, na.rm = TRUE),
                .groups = 'drop')
    # Compute cluster sizes (number of samples per cluster)
    cluster_sizes <- info.norm %>%
      group_by(pandora_cluster) %>%
      summarise(num_samples = n(), .groups = 'drop') # Calculate the number of samples in each cluster
    # Join the cluster sizes back to the lc.cent dataframe to include the number of samples per cluster
    lc.cent <- lc.cent %>%
      left_join(cluster_sizes, by = "pandora_cluster")
    # Create the 'label' column that combines cluster ID and number of samples
    lc.cent <- lc.cent %>%
      mutate(label = paste(pandora_cluster, "-", num_samples))
    # Drop the 'num_samples' column if you no longer need it
    lc.cent <- select(lc.cent, -num_samples)

    return(list(info.norm = info.norm, cluster_data = lc.cent, avg_silhouette_score = avg_silhouette_score))
}


#Density-based clustering
cluster_tsne_density <- function(info.norm, tsne.norm, settings){
    set.seed(1337)

    # Prepare data for DBSCAN
    tsne_data <- tsne.norm$Y

    # Calculate minPts and eps dynamically based on settings
    minPts_baseline <- dim(tsne_data)[2] * 2
    minPts <- max(2, settings$minPtsAdjustmentFactor * minPts_baseline)
    k_dist <- dbscan::kNNdist(tsne_data, k = minPts - 1)

    eps_quantile <- settings$epsQuantile
    eps <- stats::quantile(k_dist, eps_quantile)

	ds.norm = fpc::dbscan(tsne_data, eps = eps, MinPts = minPts)
	info.norm$pandora_cluster = factor(ds.norm$cluster)

    print(paste("====> Density-based clustering"))

    # Replace NA values with 100 specifically
    na_indices <- is.na(info.norm$pandora_cluster)
    info.norm$pandora_cluster[na_indices] <- 100

    # Compute the distance matrix based on t-SNE results
    distance_matrix <- dist(tsne_data)
    silhouette_scores <- cluster::silhouette(as.integer(info.norm$pandora_cluster), distance_matrix)
    if(is.matrix(silhouette_scores)) {
        # Extract the silhouette widths from the scores
        silhouette_widths <- silhouette_scores[, "sil_width"]
        avg_silhouette_score <- mean(silhouette_widths, na.rm = TRUE)
    }

    # Compute cluster centers based on final clustering results
    lc.cent <- info.norm %>%
        group_by(pandora_cluster) %>%
        summarize(across(c(tsne1, tsne2), median, na.rm = TRUE), .groups = 'drop')


    # Compute cluster sizes (number of samples per cluster)
    cluster_sizes <- info.norm %>%
      group_by(pandora_cluster) %>%
      summarise(num_samples = n(), .groups = 'drop') # Calculate the number of samples in each cluster
    # Join the cluster sizes back to the lc.cent dataframe to include the number of samples per cluster
    lc.cent <- lc.cent %>%
      left_join(cluster_sizes, by = "pandora_cluster")
    # Create the 'label' column that combines cluster ID and number of samples
    lc.cent <- lc.cent %>%
      mutate(label = paste(pandora_cluster, "-", num_samples))
    # Drop the 'num_samples' column if you no longer need it
    lc.cent <- select(lc.cent, -num_samples)


	return(list(info.norm = info.norm, cluster_data = lc.cent, avg_silhouette_score = avg_silhouette_score))
}


plot_clustered_tsne <- function(info.norm, cluster_data, settings, tmp_hash){
    theme_set(eval(parse(text=paste0(settings$theme, "()"))))

    info.norm$pandora_cluster <- as.character(info.norm$pandora_cluster)
    info.norm$pandora_cluster <- as.numeric(info.norm$pandora_cluster)

    cluster_data$pandora_cluster <- as.character(cluster_data$pandora_cluster)
    cluster_data$pandora_cluster <- as.numeric(cluster_data$pandora_cluster)

    # Convert 'cluster' to a factor with consistent levels in both data frames
    unique_clusters <- sort(unique(c(info.norm$pandora_cluster, cluster_data$pandora_cluster)))

    info.norm$pandora_cluster <- factor(info.norm$pandora_cluster, levels = unique_clusters)
    cluster_data$pandora_cluster <- factor(cluster_data$pandora_cluster, levels = unique_clusters)

    colorsTemp <- grDevices::colorRampPalette(
        RColorBrewer::brewer.pal(min(8, length(unique_clusters)), settings$colorPalette)
    )(length(unique_clusters))

    # Create the plot with consistent color mapping
    plotData <- ggplot(info.norm, aes(x = tsne1, y = tsne2)) + 
                    geom_point(aes(color = pandora_cluster), size = settings$pointSize, alpha = 0.7) +  # Color by cluster for points
                    scale_color_manual(values = colorsTemp) +  # Use Brewer palette for consistent color scale
                    labs(x = "t-SNE dimension 1", y = "t-SNE dimension 2", color = "Cluster") +  # Label axes and legend
                    theme_classic(base_size = settings$fontSize) +  # Use a classic theme as base
                    theme(legend.position = settings$legendPosition,  # Adjust legend position
                          legend.background = element_rect(fill = "white", colour = "black"),  # Legend background
                          legend.key.size = unit(0.5, "cm"),  # Size of legend keys
                          legend.title = element_text(face = "bold"),  # Bold legend title
                          plot.background = element_rect(fill = "white", colour = NA),  # White plot background
                          axis.title.x = element_text(size = settings$fontSize * 1.2),  # Increase X axis label size
                          axis.title.y = element_text(size = settings$fontSize * 1.2))  # Increase Y axis label size

    # Adding cluster center labels with the same color mapping
    plotData <- plotData +
                geom_label(data = cluster_data, aes(x = tsne1, y = tsne2, label = as.character(label), color = pandora_cluster),
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


plot_cluster_features_means <- function(data, settings, tmp_hash){

    if(!is.null(settings$groupingVariables)){
        data <- data %>% select(-any_of(settings$groupingVariables))
    }

    # Define the specific columns to always retain
    specific_cols <- c("tsne1", "tsne2", "pandora_cluster")
    # Construct a logical vector to identify columns to keep
    cols_to_keep <- sapply(data, is.numeric) | names(data) %in% specific_cols
    # Use the vector to select columns from the dataframe
    data_filtered <- select(data, which(cols_to_keep))

    # Calculate cluster means for each feature
    cluster_means <- data_filtered %>%
        select(-c(tsne1, tsne2)) %>%
        group_by(pandora_cluster) %>%
        summarise(across(everything(), mean)) %>%
        ungroup()

    cluster_feature_means <- tidyr::pivot_longer(cluster_means, -pandora_cluster, names_to = "feature", values_to = "mean_value")

    unique_features <- unique(cluster_feature_means$feature) 
    colorsTemp <- grDevices::colorRampPalette(
        RColorBrewer::brewer.pal(min(8, length(unique_features)), settings$colorPalette)
    )(length(unique_features))

    # Plot the means of the top features for each cluster
    plotData <- ggplot(cluster_feature_means, aes(x = factor(pandora_cluster), y = mean_value, fill = feature)) +
        geom_bar(stat = "identity", position = "dodge") +
        scale_color_manual(values = colorsTemp) +
        theme_minimal() +
        labs(x = "Cluster", y = "Mean Feature Value", fill = "Feature") +
        theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
        ggtitle("Mean Values of Features by Cluster")

    # Specify the file path for the output plot
    tmp_path <- tempfile(pattern = tmp_hash, tmpdir = tempdir(), fileext = ".svg")
    svg(tmp_path, width = settings$plot_size * settings$aspect_ratio, height = settings$plot_size, pointsize = 12, onefile = TRUE, family = "Arial", bg = "white", antialias = "default")
        print(plotData)
    dev.off()

    return(tmp_path)
}

plot_cluster_features_means_separated <- function(data, settings, tmp_hash){

    if(!is.null(settings$groupingVariables)){
        data <- data %>% select(-any_of(settings$groupingVariables))
    }

    # Define the specific columns to always retain
    specific_cols <- c("tsne1", "tsne2", "pandora_cluster")
    # Construct a logical vector to identify columns to keep
    cols_to_keep <- sapply(data, is.numeric) | names(data) %in% specific_cols
    # Use the vector to select columns from the dataframe
    data_filtered <- select(data, which(cols_to_keep))

    # Calculate cluster means for each feature
    cluster_means <- data_filtered %>%
        dplyr::select(-c(tsne1, tsne2)) %>%
        dplyr::group_by(pandora_cluster) %>%
        dplyr::summarise(across(everything(), mean)) %>%
        dplyr::ungroup()


    overall_means <- base::colMeans(data_filtered %>% select(-c(tsne1, tsne2, pandora_cluster)))

    # Calculate overall means for each feature
    cluster_feature_means_separated <- cluster_means %>%
        tidyr::pivot_longer(-pandora_cluster, names_to = "feature", values_to = "cluster_mean") %>%
        mutate(overall_mean = purrr::map_dbl(feature, ~overall_means[.]),
               fold_change = case_when(
                   cluster_mean > overall_mean ~ cluster_mean / overall_mean,
                   cluster_mean < overall_mean ~ -1 * overall_mean / cluster_mean,
                   TRUE ~ 1.0
               ))


    # View the calculated fold changes
    cluster_feature_means_separated %>%
        arrange(pandora_cluster, desc(abs(fold_change))) %>%
        select(pandora_cluster, feature, fold_change)

    unique_features <- unique(cluster_feature_means_separated$feature) 
    colorsTemp <- grDevices::colorRampPalette(
        RColorBrewer::brewer.pal(min(8, length(unique_features)), settings$colorPalette)
    )(length(unique_features))

    plotData <- ggplot(cluster_feature_means_separated, aes(x = factor(pandora_cluster), y = fold_change, fill = feature)) +
        geom_col() +
        coord_flip() +
        scale_color_manual(values = colorsTemp) +
        theme_minimal() +
        labs(x = "Cluster", y = "Fold Change", fill = "Feature") +
        ggtitle("Fold Change of Features Across Clusters")

    # Specify the file path for the output plot
    tmp_path <- tempfile(pattern = tmp_hash, tmpdir = tempdir(), fileext = ".svg")
    svg(tmp_path, width = settings$plot_size * settings$aspect_ratio, height = settings$plot_size, pointsize = 12, onefile = TRUE, family = "Arial", bg = "white", antialias = "default")
        print(plotData)
    dev.off()

    return(tmp_path)
}



cluster_heatmap <-function(cluster_data, settings, tmp_hash){

    cluster_data$pandora_cluster <- as.character(cluster_data$pandora_cluster) # First, convert factors to characters to preserve the actual labels
    cluster_data$pandora_cluster <- as.numeric(cluster_data$pandora_cluster) # Now convert characters to numeric

    if(length(unique(cluster_data$pandora_cluster)) <= 1){
        print(paste0("===> WARNING: Skipping heatmap generation. Not enough clusters in pandora_cluster: ", length(cluster_data$pandora_cluster)))
        return(FALSE)
    }

	info.norm.num <- cluster_data %>% select(where(is.numeric))
	all_columns <- colnames(info.norm.num)

	selectedRows <- all_columns[! all_columns %in% c("tsne1", "tsne2", "pandora_cluster", settings$groupingVariables)] 
	input_data <- info.norm.num %>% select(any_of(all_columns[! all_columns %in% c("tsne1", "tsne2", settings$groupingVariables)]))

    heatmapScale = "column"
    if(settings$datasetAnalysisGrouped == TRUE){
        input_data <- input_data %>%
          group_by(pandora_cluster) %>%
          summarise(across(everything(), mean, na.rm = TRUE), .groups = 'drop')

        input_data <- as.data.frame(input_data)
        heatmapScale = "row"
    }

    if(settings$datasetAnalysisType == "heatmap"){
    	plotClustered <- FALSE
    }else{
    	plotClustered <- TRUE
    }

	# Dynamic font size adjustment based on the number of rows and columns
	num_columns <- nrow(input_data)
	num_rows <- length(selectedRows)

    # Settings from the user
    min_font_size <- settings$fontSize # Minimum font size
    max_font_size <- max(min_font_size + 10, 24) # Maximum font size, set a reasonable default or user-defined
    plotWidth <- settings$plot_size # Plot width in cm as defined by the user
    plotRatio <- settings$aspect_ratio # Plot aspect ratio as defined by the user

    # Calculate image dimensions in inches and then in dots (pixels)
    picwIn <- plotWidth / 2.54 # Width in inches
    pichIn <- picwIn * plotRatio # Height in inches, calculated using aspect ratio
    dotsPerCm <- 96 / 2.54 # Dots per cm (assuming standard 96 DPI)
    picw <- picwIn * 2.54 * dotsPerCm # Width in dots (pixels)
    pich <- pichIn * 2.54 * dotsPerCm # Height in dots (pixels)

    aspect_ratio_factor <- sqrt(picw / pich)
    data_density_factor <- sqrt(num_rows * num_columns) / 100

    # Base font size could initially be set as the user-defined minimum font size
    base_font_size <- min_font_size

    scaling_factor_col_base <- 25 # Remains the same for column adjustments

    if (num_rows > 100) {
        # Increase the aggressiveness of the scaling for datasets with more than 100 rows
        scaling_factor_row_base <- 5; # More aggressive scaling for rows
    } else {
        scaling_factor_row_base <- 30; # Less aggressive scaling for smaller datasets
    }


    adjusted_scaling_factor_col <- base_font_size / (num_columns / scaling_factor_col_base)


    # Use the non-linearly adjusted scaling factors to determine font sizes
    if (num_rows > 200) {
        # For large numbers of rows, adjust the formula to reduce the font size more significantly
        adjusted_font_size_row <- 4
    }else if (num_rows > 100) {
        # For large numbers of rows, adjust the formula to reduce the font size more significantly
        adjusted_font_size_row <- max(min_font_size, (base_font_size - sqrt(num_rows) / scaling_factor_row_base) / 2)
    } else {
        # For smaller datasets, use a less aggressive adjustment
        adjusted_font_size_row <- max(min_font_size, base_font_size - sqrt(num_rows) / scaling_factor_row_base)
    }
    adjusted_font_size_col <- max(min_font_size, base_font_size - num_columns / adjusted_scaling_factor_col)
    adjusted_font_size_general <- min(adjusted_font_size_row, adjusted_font_size_col)

    # Ensure the adjusted font size is within the user-defined limits
    adjusted_font_size_general = max(adjusted_font_size_general, min_font_size)
    adjusted_font_size_general = min(adjusted_font_size_general, max_font_size)

    input_args <- c(list(data=input_data, 
						fileHeader=NULL,

						selectedColumns=c("pandora_cluster"),
						selectedRows=selectedRows,

						removeNA=TRUE,

						scale=heatmapScale,

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


remove_outliers <- function(dataset, settings) {
    if(settings$datasetAnalysisRemoveOutliersDownstream == TRUE) {
        print("===> INFO: Trying to remove outliers from dataset")
        if("pandora_cluster" %in% names(dataset)) {
            if(100 %in% dataset$pandora_cluster) {
                dataset <- dataset[dataset$pandora_cluster != 100, ]
                print("===> INFO: Rows with pandora_cluster == 100 have been removed.")
            } else {
                print("===> INFO: Cluster 100 does not exist in pandora_cluster.")
            }
        } else {
            print("===> INFO: No outliers detected")
        }
    }
    return(dataset)
}
