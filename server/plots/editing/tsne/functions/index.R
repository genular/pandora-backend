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



#' Perform KNN and Louvain Clustering on t-SNE Results
#'
#' This function performs clustering on t-SNE results by first applying K-Nearest Neighbors (KNN) to construct a graph, 
#' and then using the Louvain method for community detection. The function dynamically adjusts KNN parameters based on the 
#' size of the dataset, ensuring scalability. Additionally, it computes the silhouette score to evaluate cluster quality 
#' and calculates cluster centroids for visualization.
#'
#' @param info.norm A data frame containing the normalized data on which the t-SNE analysis was carried out.
#' @param tsne.norm A list containing the t-SNE results, including a 2D t-SNE coordinate matrix in the `Y` element.
#' @param settings A list of settings for the analysis, including:
#' \itemize{
#'   \item `knn_clusters`: The number of nearest neighbors to use for KNN (default: 250).
#'   \item `target_clusters_range`: A numeric vector specifying the target range for the number of clusters.
#'   \item `start_resolution`: The starting resolution for Louvain clustering.
#'   \item `end_resolution`: The maximum resolution to test.
#'   \item `min_modularity`: The minimum acceptable modularity for valid clusterings.
#' }
#' @param resolution_increment The step size for incrementing the Louvain clustering resolution. Defaults to 0.1.
#' @param min_modularity The minimum modularity score allowed for a valid clustering. Defaults to 0.5.
#'
#' @importFrom FNN get.knn
#' @importFrom igraph graph_from_data_frame simplify cluster_louvain membership modularity
#' @importFrom dplyr group_by select summarise across left_join n mutate
#' @importFrom cluster silhouette
#' @importFrom stats dist median
#'
#' @return A list containing the following elements:
#' \itemize{
#'   \item `info.norm`: The input data frame with an additional `pandora_cluster` column for cluster assignments.
#'   \item `cluster_data`: A data frame containing cluster centroids and cluster labels.
#'   \item `avg_silhouette_score`: The average silhouette score, a measure of clustering quality.
#'   \item `modularity`: The modularity score of the Louvain clustering.
#'   \item `num_clusters`: The number of clusters found.
#' }
#'
#' @details 
#' This function begins by constructing a KNN graph from the t-SNE results, then applies the Louvain algorithm for 
#' community detection. The KNN parameter is dynamically adjusted based on the size of the dataset to ensure scalability. 
#' The function evaluates clustering quality using silhouette scores and calculates cluster centroids for visualization. 
#' NA cluster assignments are handled by assigning them to a separate cluster labeled as "100."
#'
#' @keywords internal
cluster_tsne_knn_louvain <- function(info.norm, tsne.norm, settings, resolution_increment = 0.1, min_modularity = 0.5){

    # Adjust KNN clusters if needed
    knn_clusters <- settings$knn_clusters
    if (nrow(tsne.norm$Y) < knn_clusters) {
        knn_clusters <- round(nrow(tsne.norm$Y) / 2)
        message(paste0("===> INFO: Adjusted KNN clusters to half the number of samples: ", knn_clusters))
    }
    # Determine the dimensionality of the dataset
    n_obs <- nrow(tsne.norm$Y)
    n_vars <- ncol(tsne.norm$Y)

    # Choose the nearest neighbor algorithm based on dimensionality
    algorithm <- if (n_vars > n_obs * 0.15) {
        "cover_tree"  # Preferred for higher dimensionality
    } else if (n_vars < 30) {
        "kd_tree"  # Better suited for lower dimensions
    } else {
        "brute"  # Default option for general cases
    }

    knn.norm = FNN::get.knn(as.matrix(tsne.norm$Y), k = knn_clusters, algorithm = algorithm)
    knn.norm = data.frame(
                    from = rep(1:nrow(knn.norm$nn.index), knn_clusters), 
                    to = as.vector(knn.norm$nn.index), 
                    weight = 1/(1 + as.vector(knn.norm$nn.dist)))

    # Build graph from KNN results and simplify it
    nw.norm = igraph::graph_from_data_frame(knn.norm, directed = FALSE)
    nw.norm = igraph::simplify(nw.norm)

    # Find optimal resolution for Louvain clustering
    resolution <- find_optimal_resolution(nw.norm, 
                                            start_resolution = 0.1, 
                                            end_resolution = 10, 
                                            resolution_increment = resolution_increment, 
                                            min_modularity = min_modularity, 
                                            target_clusters_range = settings$target_clusters_range
                                         )
    if (is.null(resolution)) {
        optimal_resolution <- NULL
    } else {
        optimal_resolution <- resolution$selected$optimal_resolution
    }
    
    # Initialize a list to store the results
    cluster_results <- list()
    num_clusters_list <- numeric(10)

    for (i in 1:10) {
        if (is.null(optimal_resolution)) {
            lc.norm <- igraph::cluster_louvain(nw.norm)
        }else{
            lc.norm <- igraph::cluster_louvain(nw.norm, resolution = optimal_resolution)
        }
        # Log cluster results
        num_clusters <- length(unique(igraph::membership(lc.norm)))
        # Store the result
        cluster_results[[i]] <- lc.norm
        num_clusters_list[i] <- num_clusters
    }
    
    # Find the most frequent number of clusters
    most_frequent_clusters <- as.numeric(names(sort(table(num_clusters_list), decreasing = TRUE)[1]))
    # Get the corresponding lc.norm where the number of clusters matches the most frequent one
    lc.norm <- cluster_results[[which(num_clusters_list == most_frequent_clusters)[1]]]

    # Log cluster results
    num_clusters <- length(unique(igraph::membership(lc.norm)))
    message(paste0("===> INFO: Number of clusters found: ", num_clusters))
    modularity <- igraph::modularity(lc.norm)
    message(paste0("===> INFO: Modularity score: ", modularity))

    # Assign clusters to the info.norm data frame
    info.norm$pandora_cluster <- as.factor(igraph::membership(lc.norm))

    # Debugging: Check for NA values in pandora_cluster
    num_na_clusters <- sum(is.na(info.norm$pandora_cluster))
    if(num_na_clusters > 0) {
        warning(paste0("===> INFO: Number of NA clusters in pandora_cluster: ", num_na_clusters))    
    }

    # Handle NA clusters by assigning them to cluster "100"
    na_indices <- is.na(info.norm$pandora_cluster)
    num_na <- sum(na_indices)
    if(num_na > 0){
        # Add 100 to the levels of pandora_cluster
        info.norm$pandora_cluster <- factor(info.norm$pandora_cluster, levels = c(levels(info.norm$pandora_cluster), "100"))
        # Now assign 100 to NA indices
        info.norm$pandora_cluster[na_indices] <- "100"
        message(paste0("===> INFO: Replaced ", num_na, " NA cluster assignments with '100'"))
    }

    # Calculate the distance matrix for silhouette score computation
    distance_matrix <- dist(tsne.norm$Y)    


    # Calculate silhouette scores to evaluate cluster quality
    silhouette_scores <- cluster::silhouette(as.integer(info.norm$pandora_cluster), distance_matrix)
    if (is.matrix(silhouette_scores)) {
        avg_silhouette_score <- mean(silhouette_scores[, "sil_width"], na.rm = TRUE)
        message(paste0("===> INFO: Average silhouette score: ", avg_silhouette_score))
    } else {
        message("===> WARNING: Silhouette score calculation did not return a matrix.")
        avg_silhouette_score <- NA
    }

    # Compute cluster centers
    lc.cent <- info.norm %>%
        group_by(pandora_cluster) %>%
        summarise(across(c(tsne1, tsne2), ~ median(.x, na.rm = TRUE)), .groups = 'drop')


    # Log number of cluster centers
    message(paste0("===> INFO: Cluster centers computed for ", nrow(lc.cent), " clusters"))

    # Compute cluster sizes
    cluster_sizes <- info.norm %>%
      group_by(pandora_cluster) %>%
      summarise(num_samples = n(), .groups = 'drop') # Calculate the number of samples in each cluster

    # Add cluster size labels
    lc.cent <- lc.cent %>%
      left_join(cluster_sizes, by = "pandora_cluster")

    # Create the 'label' column that combines cluster ID and number of samples
    lc.cent <- lc.cent %>%
      mutate(label = paste(pandora_cluster, "-", num_samples))

    # Drop the 'num_samples' column if you no longer need it
    lc.cent <- select(lc.cent, -num_samples)

    return(list(info.norm = info.norm, cluster_data = lc.cent, 
        avg_silhouette_score = avg_silhouette_score, modularity = modularity, 
        num_clusters = num_clusters,
        resolution = resolution))
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



#' Find Optimal Resolution for Louvain Clustering
#'
#' This function iterates over a range of resolution values to find the optimal resolution for 
#' Louvain clustering, balancing the number of clusters and modularity. It aims to identify a 
#' resolution that results in a reasonable number of clusters while maintaining a high modularity score.
#'
#' @param graph An \code{igraph} object representing the graph to be clustered.
#' @param start_resolution Numeric. The starting resolution for the Louvain algorithm. Default is 0.1.
#' @param end_resolution Numeric. The maximum resolution to test. Default is 10.
#' @param resolution_increment Numeric. The increment to adjust the resolution at each step. Default is 0.1.
#' @param min_modularity Numeric. The minimum acceptable modularity for valid clusterings. Default is 0.3.
#' @param target_clusters_range Numeric vector of length 2. Specifies the acceptable range for the number of clusters (inclusive). Default is \code{c(3, 6)}.
#'
#' @return A list containing:
#' \item{selected}{A list with the optimal resolution, best modularity, and number of clusters.}
#' \item{frequent_clusters_results}{A data frame containing results for resolutions that yielded the most frequent number of clusters.}
#' \item{all_results}{A data frame with the resolution, number of clusters, and modularity for all tested resolutions.}
#'
#' @details
#' The function performs Louvain clustering at different resolutions, starting from \code{start_resolution} and 
#' ending at \code{end_resolution}, incrementing by \code{resolution_increment} at each step. At each resolution, 
#' the function calculates the number of clusters and modularity. The results are filtered to select those 
#' where modularity exceeds \code{min_modularity} and the number of clusters falls within the specified range 
#' \code{target_clusters_range}. The optimal resolution is chosen based on the most frequent number of clusters and 
#' the median resolution that satisfies these criteria.
find_optimal_resolution <- function(graph, 
    start_resolution = 0.1, 
    end_resolution = 10, 
    resolution_increment = 0.1, 
    min_modularity = 0.3, 
    target_clusters_range = c(3, 6)) {
    results <- data.frame(
        resolution = numeric(),
        num_clusters = integer(),
        modularity = numeric(),
        stringsAsFactors = FALSE
    )
    
    res <- start_resolution
    
    # Iterate over resolutions from start_resolution to end_resolution
    while (res <= end_resolution) {
        lc <- igraph::cluster_louvain(graph, resolution = res)  # Perform Louvain clustering
        modularity_value <- igraph::modularity(lc)  # Calculate modularity
        num_clusters <- length(unique(igraph::membership(lc)))  # Get the number of clusters

        # Skip clusterings that are not within the target_clusters_range
        if (num_clusters < target_clusters_range[1] || num_clusters > target_clusters_range[2]) {
            res <- res + resolution_increment
            next
        }
        # Collect the results into a dataframe
        results <- rbind(results, data.frame(resolution = res, num_clusters = num_clusters, modularity = modularity_value))
        
        # Increment resolution by 0.1 for the next iteration
        res <- res + resolution_increment
    }
    
    # Filter results for modularity above threshold and number of clusters within the target range
    valid_results <- results[results$modularity >= min_modularity &
                               results$num_clusters >= target_clusters_range[1] &
                               results$num_clusters <= target_clusters_range[2], ]
    
    if (nrow(valid_results) == 0) {
        message("===> INFO: No valid resolutions found")
        return(NULL)
    }
    
    # Find the most frequent number of clusters
    most_frequent_clusters <- as.numeric(names(sort(table(valid_results$num_clusters), decreasing = TRUE)[1]))
    
    # Subset the results where the number of clusters matches the most frequent one
    frequent_clusters_results <- valid_results[valid_results$num_clusters == most_frequent_clusters, ]
    
    # Find the median resolution from the frequent clusters subset
    median_resolution <- median(frequent_clusters_results$resolution)
    
    # Get the row with the median resolution
    best_row <- frequent_clusters_results[which.min(abs(frequent_clusters_results$resolution - median_resolution)), ]
    
    # Output the selected clustering result
    message(paste0("===> INFO: Selected resolution: ", best_row$resolution, 
                   " Modularity: ", best_row$modularity, 
                   " Clusters: ", best_row$num_clusters))

    return(list(
            selected = list(optimal_resolution = best_row$resolution, 
                best_modularity = best_row$modularity, 
                best_clusters = best_row$num_clusters),
            frequent_clusters_results = frequent_clusters_results,
            all_results = results
        ))
}

#' Automated Machine Learning Model Building
#'
#' This function automates the process of building machine learning models using the caret package. 
#' It supports both binary and multi-class classification and allows users to specify a list of 
#' machine learning algorithms to be trained on the dataset. The function splits the dataset into 
#' training and testing sets, applies preprocessing steps, and trains models using cross-validation.
#' It computes relevant performance metrics such as confusion matrix, AUROC (for binary classification), 
#' and prAUC (for binary classification).
#'
#' @param dataset_ml A data frame containing the dataset for training. All columns except the outcome 
#'   column should contain the features.
#' @param settings A list containing the following parameters:
#'   \itemize{
#'     \item{\code{outcome}}: A string specifying the name of the outcome column in \code{dataset_ml}. Defaults to "immunaut" if not provided.
#'     \item{\code{excludedColumns}}: A vector of column names to be excluded from the training data. Defaults to \code{NULL}.
#'     \item{\code{preProcessDataset}}: A vector of preprocessing steps to be applied (e.g., \code{c("center", "scale", "medianImpute")}). Defaults to \code{NULL}.
#'     \item{\code{selectedPartitionSplit}}: A numeric value specifying the proportion of data to be used for training. Must be between 0 and 1. Defaults to 0.7.
#'     \item{\code{selectedPackages}}: A character vector specifying the machine learning algorithms to be used for training (e.g., \code{"nb"}, \code{"rpart"}). Defaults to \code{c("nb", "rpart")}.
#'   }
#'
#' @details
#' The function performs preprocessing (e.g., centering, scaling, and imputation of missing values) on the dataset based on the provided settings. 
#' It splits the data into training and testing sets using the specified partition, trains models using cross-validation, and computes performance metrics.
#' 
#' For binary classification problems, the function calculates AUROC and prAUC. For multi-class classification, it calculates macro-averaged AUROC, though prAUC is not used.
#' 
#' The function returns a list of trained models along with their performance metrics, including confusion matrix, variable importance, and post-resample metrics.
#'
#' @return A list where each element corresponds to a trained model for one of the algorithms specified in 
#'   \code{settings$selectedPackages}. Each element contains:
#'   \itemize{
#'     \item{\code{info}}: General information about the model, including resampling indices, problem type, 
#'         and outcome mapping.
#'     \item{\code{training}}: The trained model object and variable importance.
#'     \item{\code{predictions}}: Predictions on the test set, including probabilities, confusion matrix, 
#'         post-resample statistics, AUROC (for binary classification), and prAUC (for binary classification).
#'   }
#'
#' @importFrom caret train createDataPartition trainControl confusionMatrix varImp postResample
#' @importFrom pROC roc auc
#' @importFrom PRROC pr.curve
#' @importFrom stats as.formula
#' @importFrom R.utils withTimeout
#' @importFrom parallel detectCores makePSOCKcluster stopCluster
#' @importFrom doParallel registerDoParallel
#'
#' @examples
#' \dontrun{
#' dataset <- read.csv("fc_wo_noise.csv", header = TRUE, row.names = 1)
#' 
#' # Generate a file header for the dataset to use in downstream analysis
#' file_header <- generate_file_header(dataset)
#' 
#' settings <- list(
#'     fileHeader = file_header,
#'     # Columns selected for analysis
#'     selectedColumns = c("ExampleColumn1", "ExampleColumn2"), 
#'     clusterType = "Louvain",
#'     removeNA = TRUE,
#'     preProcessDataset = c("scale", "center", "medianImpute", "corr", "zv", "nzv"),
#'     target_clusters_range = c(3,4),
#'     resolution_increments = c(0.01, 0.05, 0.1, 0.2, 0.3, 0.4, 0.5),
#'     min_modularities = c(0.4, 0.5, 0.6, 0.7, 0.8, 0.85, 0.9),
#'     pickBestClusterMethod = "Modularity",
#'     seed = 1337
#' )
#' 
#' result <- immunaut(dataset, settings)
#' dataset_ml <- result$dataset$original
#' dataset_ml$pandora_cluster <- tsne_clust[[i]]$info.norm$pandora_cluster
#' dataset_ml <- dplyr::rename(dataset_ml, immunaut = pandora_cluster)
#' dataset_ml <- dataset_ml[, c("immunaut", setdiff(names(dataset_ml), "immunaut"))]
#' settings_ml <- list(
#'     excludedColumns = c("ExampleColumn0"),
#'     preProcessDataset = c("scale", "center", "medianImpute", "corr", "zv", "nzv"),
#'     selectedPartitionSplit = split,  # Use the current partition split
#'     selectedPackages = c("rf", "RRF", "RRFglobal", "rpart2", "c5.0", "sparseLDA", 
#'     "gcvEarth", "cforest", "gaussPRPoly", "monmlp", "slda", "spls"),
#'     trainingTimeout = 180  # Timeout 3 minutes
#' )
#' ml_results <- auto_simon_ml(dataset_ml, settings_ml)
#' }
#'
#' @export
auto_simon_ml <- function(dataset_ml, settings) {
    set.seed(settings$seed)
    

    if (is_var_empty(settings$outcome) == TRUE) {
        settings$outcome = "immunaut"
    }

    if (is_var_empty(settings$selectedColumns) == TRUE) {
        settings$selectedColumns = NULL
    }

    if (is_var_empty(settings$excludedColumns) == TRUE) {
        settings$excludedColumns = NULL
    }

    if (is_var_empty(settings$trainingTimeout) == TRUE) {
        settings$trainingTimeout = 180
    }

    if (is_var_empty(settings$preProcessDataset) == TRUE) {
        settings$preProcessDataset = NULL
    }
    if (is_var_empty(settings$selectedPartitionSplit) == TRUE) {
        settings$selectedPartitionSplit = 0.7
    }
    if (is_var_empty(settings$selectedPackages) == TRUE) {
        settings$selectedPackages = c("nb", "rpart")
    }
    
    ## If the outcome column is not found, return an error
    if (!settings$outcome %in% colnames(dataset_ml)) {
        stop(paste(
            "Outcome column",
            settings$outcome,
            "not found in the dataset."
        ))
    }
    ##  Exclude columns from the dataset if specified
    if (!is.null(settings$selectedColumns)) {
        message(paste("Selected columns: ", paste(c(settings$outcome, settings$selectedColumns), collapse = ", ")))
        dataset_ml <- dataset_ml[, c(settings$outcome, settings$selectedColumns)]
    }

    ##  Exclude columns from the dataset if specified
    if (!is.null(settings$excludedColumns)) {
        message(paste("Excluding columns: ", paste(settings$excludedColumns, collapse = ", ")))
        dataset_ml <- dataset_ml[, !colnames(dataset_ml) %in% settings$excludedColumns]
    }
    
    ## If no packages are selected, return an error
    if (length(settings$selectedPackages) == 0) {
        stop("No machine learning packages selected for training.")
    }
    
    ## If the selected partition split is invalid, return an error
    if (settings$selectedPartitionSplit <= 0 ||
        settings$selectedPartitionSplit >= 1) {
        stop("Invalid partition split value. Please choose a value between 0 and 1.")
    }

    # Preprocess dataset
    if (!is.null(settings$preProcessDataset)) {
        preProcessMapping <- preProcessResample(dataset_ml, settings$preProcessDataset, settings$outcome, settings$outcome)
        dataset_ml <- preProcessMapping$datasetData

    }else if (is.null(settings$preProcessDataset) && anyNA(dataset_ml)) {
        message("No preprocessing steps specified, but missing values detected. Applying default median imputation.")
        # Apply default preprocessing (median imputation for NAs, and optionally scaling/centering)
        preProcessMapping <- preProcessResample(dataset_ml, 
                                                c("medianImpute", "scale", "center"), 
                                                settings$outcome, 
                                                c(settings$outcome, settings$excludedColumns))
        dataset_ml <- preProcessMapping$datasetData
    }

    ## Make sure outcome levels are valid
    levels(dataset_ml[[settings$outcome]]) <- make.names(levels(dataset_ml[[settings$outcome]]))


    # Create an empty list to store model results
    model_list <- list()
    
    # Prepare data
    outcome_col <- dataset_ml[[settings$outcome]]
    
    # Encode outcome to factor for classification and apply make.names to the levels
    if (!is.factor(outcome_col)) {
        outcome_col <- as.factor(outcome_col)
    }
    
    # Ensure factor levels are valid R variable names
    levels(outcome_col) <- make.names(levels(outcome_col))


    message(paste0("===> INFO: Unique outcome levels: ", paste(levels(dataset_ml[[settings$outcome]]), collapse = ", ")))
    message(paste0("===> INFO: Dataset columns after preprocessing: ", paste(colnames(dataset_ml), collapse = ", ")))
    
    # Split the data into training and testing sets
    trainIndex <-
        caret::createDataPartition(outcome_col,
                                   p = settings$selectedPartitionSplit,
                                   list = FALSE)
    trainData <- dataset_ml[trainIndex,]
    testData <- dataset_ml[-trainIndex,]
    
    # Determine if the problem is binary or multi-class classification
    is_binary_classification <- length(unique(outcome_col)) == 2

    message(paste("===> INFO: Problem type:", ifelse(is_binary_classification, "Binary Classification", "Multi-Class Classification")))
    

    num_cores <- parallel::detectCores(logical = TRUE)
    cl <- parallel::makePSOCKcluster(num_cores-1)
    doParallel::registerDoParallel(cl)
    on.exit(parallel::stopCluster(cl)) 

    # Iterate through each model in selectedPackages for training and evaluation
    for (model_name in settings$selectedPackages) {
        message(paste("===> INFO: Training model:", model_name))
        
        # Wrap model training in tryCatch and timeout for error and timeout handling
        tryCatch({
            R.utils::withTimeout({
                
                # Define control for cross-validation, using summary function based on classification type
                train_control <- caret::trainControl(
                    method = "cv",
                    number = 5,
                    savePredictions = "final",
                    classProbs = TRUE,
                    summaryFunction = if (is_binary_classification)
                        caret::twoClassSummary
                    else
                        caret::multiClassSummary
                )
                
                # Train the model with specified formula, data, method, and control
                trained_model <- caret::train(
                    as.formula(paste(settings$outcome, "~ .")),
                    data = trainData,
                    method = model_name,
                    trControl = train_control,
                    metric = "ROC",  # Use ROC as a performance metric
                    preProcess = c("center", "scale")  # Standardize data
                )
                
                # Generate predictions on test data
                predictions <- predict(trained_model, newdata = testData)
                probabilities <- predict(trained_model, newdata = testData, type = "prob")
                
                # Calculate confusion matrix and resampling metrics
                confusion_matrix <- caret::confusionMatrix(predictions, testData[[settings$outcome]])
                post_resample_metrics <- caret::postResample(predictions, testData[[settings$outcome]])
                
                # Initialize AUROC and prAUC placeholders
                auroc <- NA
                prAUC <- NA
                
                # Performance metrics for binary and multi-class classifications
                if (is_binary_classification) {
                    # Binary AUROC and prAUC
                    roc_curve <- pROC::roc(testData[[settings$outcome]], probabilities[, 2])
                    auroc <- pROC::auc(roc_curve)
                    prAUC <- PRROC::pr.curve(
                        scores.class0 = probabilities[, 2],
                        weights.class0 = testData[[settings$outcome]] == levels(testData[[settings$outcome]])[2]
                    )$auc.integral
                } else {
                    # Macro-averaged AUROC for multi-class
                    roc_curves <- lapply(levels(testData[[settings$outcome]]), function(class) {
                        pROC::roc(testData[[settings$outcome]] == class, probabilities[, class])
                    })
                    auroc <- mean(sapply(roc_curves, pROC::auc), na.rm = TRUE)
                    
                    # Weighted AUROC for imbalanced classes
                    class_counts <- table(testData[[settings$outcome]])
                    total_samples <- sum(class_counts)
                    weighted_auroc <- sum(sapply(seq_along(levels(testData[[settings$outcome]])), function(i) {
                        class_name <- levels(testData[[settings$outcome]])[i]
                        class_roc <- roc_curves[[i]]
                        pROC::auc(class_roc) * (class_counts[class_name] / total_samples)
                    }), na.rm = TRUE)
                    
                    # Calculate macro-averaged F1 score
                    f1_scores <- sapply(levels(testData[[settings$outcome]]), function(class) {
                        caret::confusionMatrix(predictions, testData[[settings$outcome]], mode = "prec_recall")$byClass["F1"]
                    })
                    macro_f1 <- mean(f1_scores, na.rm = TRUE)
                }
                
                # Store model details and metrics in the model list
                model_list[[model_name]] <- list(
                    info = list(
                        resampleID = trainIndex,
                        problemType = if (is_binary_classification) "Binary Classification" else "Multi-Class Classification",
                        data = trainData,
                        outcome = settings$outcome,
                        outcome_mapping = levels(outcome_col)
                    ),
                    training = list(
                        raw = trained_model,
                        varImportance = caret::varImp(trained_model)
                    ),
                    predictions = list(
                        raw = predictions,
                        processed = probabilities,
                        prAUC = prAUC,
                        AUROC = auroc,
                        weightedAUROC = if (!is_binary_classification) weighted_auroc else NA,
                        macroF1 = if (!is_binary_classification) macro_f1 else NA,
                        postResample = post_resample_metrics,
                        confusionMatrix = confusion_matrix
                    )
                )
                
                message(paste("===> INFO: Finished training model:", model_name))
            }, timeout = settings$trainingTimeout)  # Set timeout for 3 minutes (180 seconds)
        }, TimeoutException = function(ex) {
            message(paste("===> ERROR: Model training for", model_name, "timed out."))
        }, error = function(e) {
            message(paste("===> ERROR: Failed to train model:", model_name, "Error message:", e$message))
        })
    }

    
    # Return the list of models with details
    return(list(models = model_list, dataset = dataset_ml, trainData = trainData, testData = testData, is_binary_classification = is_binary_classification))
}

#' Select the Best Clustering Based on Weighted Scores: AUROC, Modularity, and Silhouette
#'
#' This function selects the optimal clustering configuration from a list of `t-SNE` clustering results
#' by evaluating each configuration's AUROC, modularity, and silhouette scores. These scores are combined
#' using a weighted average, allowing for a more comprehensive assessment of each configuration's relevance.
#'
#' @param dataset A data frame representing the original dataset, where each observation will be assigned cluster labels
#'                from each clustering configuration in \code{tsne_clust}.
#' @param tsne_clust A list of clustering results from different t-SNE configurations, with each element containing 
#'                   \code{pandora_cluster} assignments and clustering information.
#' @param tsne_calc An object containing t-SNE results on \code{dataset}.
#' @param settings A list of settings for machine learning model training and scoring, including:
#' \describe{
#'   \item{excludedColumns}{A character vector of columns to exclude from the analysis.}
#'   \item{preProcessDataset}{A character vector of preprocessing steps (e.g., scaling, centering).}
#'   \item{selectedPartitionSplit}{Numeric; the partition split ratio for train/test splits.}
#'   \item{selectedPackages}{Character vector of machine learning models to train.}
#'   \item{trainingTimeout}{Numeric; time limit (in seconds) for training each model.}
#'   \item{weights}{A list of weights for scoring criteria: \code{weights$AUROC}, \code{weights$modularity}, 
#'   and \code{weights$silhouette} (default is 0.4, 0.3, and 0.3 respectively).}
#' }
#'
#' @details
#' For each clustering configuration in \code{tsne_clust}, this function:
#' \enumerate{
#'   \item Assigns cluster labels to the dataset.
#'   \item Trains machine learning models specified in \code{settings} on the dataset with cluster labels.
#'   \item Evaluates each model based on AUROC, modularity, and silhouette scores.
#'   \item Selects the clustering configuration with the highest weighted average score as the best clustering result.
#' }
#'
#' @return A list containing the best clustering configuration (with the highest weighted score) and its associated information.
#'
#' @import dplyr
#' 
#' @keywords internal
pick_best_cluster_simon <- function(dataset, tsne_clust, tsne_calc, settings) {
    if (length(tsne_clust) == 0) {
        stop("The tsne_clust list is empty.")
    }

    # Initialize arrays for holding each metric
    all_aurocs <- numeric(length(tsne_clust))
    all_modularities <- numeric(length(tsne_clust))
    all_silhouettes <- numeric(length(tsne_clust))

    # Gather AUROC, modularity, and silhouette for all clusters
    for (i in seq_along(tsne_clust)) {
        dataset_ml <- dataset
        dataset_ml$pandora_cluster <- tsne_clust[[i]]$info.norm$pandora_cluster
        dataset_ml <- dplyr::rename(dataset_ml, immunaut = pandora_cluster)
        dataset_ml <- dataset_ml[, c("immunaut", setdiff(names(dataset_ml), "immunaut"))]

        # Train models on current cluster configuration and calculate average AUROC
        ml_results <- auto_simon_ml(dataset_ml, settings)
        model_auroc_table <- data.frame(Model = character(), AUROC = numeric(), stringsAsFactors = FALSE)

        for (model_name in names(ml_results$models)) {
            auroc_value <- if (ml_results$is_binary_classification) {
                ml_results$models[[model_name]][["predictions"]][["AUROC"]]
            } else {
                if (!is.na(ml_results$models[[model_name]][["predictions"]][["weightedAUROC"]])) {
                    ml_results$models[[model_name]][["predictions"]][["weightedAUROC"]]
                } else {
                    ml_results$models[[model_name]][["predictions"]][["AUROC"]]
                }
            }
            if (!is.na(auroc_value)) {
                model_auroc_table <- rbind(model_auroc_table, data.frame(Model = model_name, AUROC = auroc_value))
            }
        }

        # Calculate the average AUROC for the top 5 models and store in arrays
        all_aurocs[i] <- mean(utils::head(model_auroc_table[order(model_auroc_table$AUROC, decreasing = TRUE), "AUROC"], 5), na.rm = TRUE)
        all_modularities[i] <- tsne_clust[[i]]$modularity
        all_silhouettes[i] <- tsne_clust[[i]]$avg_silhouette_score
    }

    # Apply normalization to all metrics
    norm_aurocs <- normalize(all_aurocs)
    norm_modularities <- normalize(all_modularities)
    norm_silhouettes <- normalize(all_silhouettes)

    # Track the best score and associated cluster
    best_score <- -Inf
    best_cluster <- NULL

    # Calculate and evaluate the combined score for each configuration
    for (i in seq_along(tsne_clust)) {
        combined_score <- (settings$weights$AUROC * norm_aurocs[i]) + 
                          (settings$weights$modularity * norm_modularities[i]) + 
                          (settings$weights$silhouette * norm_silhouettes[i])

        # Logging for diagnostics
        message(paste("===> SIMON: Cluster", i,
                      " Clusters: ", tsne_clust[[i]]$num_clusters,
                      " MOD:", round(norm_modularities[i], 3),
                      " SILH:", round(norm_silhouettes[i], 3),
                      " AUROC:", round(norm_aurocs[i], 3),
                      " CS:", round(combined_score, 3)))

        # Update best cluster if this one has a higher score
        if (combined_score > best_score) {
            best_score <- combined_score
            best_cluster <- list(
                tsne_clust = tsne_clust[[i]],
                combined_score = combined_score,
                modularity = all_modularities[i],
                silhouette = all_silhouettes[i],
                auroc = all_aurocs[i]
            )
        }
    }

    if (is.null(best_cluster)) {
        stop("No valid clustering result found with non-missing values for AUROC, modularity, and silhouette.")
    }

    message(paste0(
        "===> INFO: Best clustering selected with combined score: ", 
        round(best_cluster$combined_score, 3),
        " | Clusters: ", best_cluster$tsne_clust$num_clusters, 
        " | MOD: ", round(best_cluster$tsne_clust$modularity, 3), 
        " | SIL: ", round(best_cluster$tsne_clust$avg_silhouette_score, 3),
        " | AUC: ", round(max(best_cluster$auroc), 3)
    ))


    return(best_cluster)
}


#' Pick Best Cluster by Modularity
#'
#' This function selects the best cluster from a list of clustering results
#' based on the highest modularity score.
#'
#' @param tsne_clust A list of clustering results where each element contains clustering information,
#' including the modularity score.
#'
#' @return Returns the clustering result with the highest modularity score.
#' 
#' @details The function iterates over a list of clustering results (`tsne_clust`) and 
#' selects the cluster with the highest modularity score. If no clusters are valid or 
#' the `tsne_clust` list is empty, the function will stop and return an error.
#' 
#'
#' @keywords internal
pick_best_cluster_modularity <- function(tsne_clust) {
    if (length(tsne_clust) == 0) {
        stop("The tsne_clust list is empty.")
    }
    
    best_modularity <- -Inf
    best_cluster <- NULL
    
    # Iterate through tsne_clust to find the cluster with the highest modularity
    for (i in seq_along(tsne_clust)) {
        modularity <- tsne_clust[[i]]$modularity
        
        if (!is.null(modularity) && modularity > best_modularity) {
            best_modularity <- modularity
            best_cluster <- tsne_clust[[i]]
        }
    }
    
    if (is.null(best_cluster)) {
        stop("No valid clusters found.")
    }
    
    message(paste("===> INFO: Best cluster selected with modularity: ", best_modularity, " Clusters: ", best_cluster$num_clusters))
    
    return(best_cluster)
}

#' Pick Best Cluster by Silhouette Score
#'
#' This function selects the best cluster from a list of clustering results
#' based on the highest average silhouette score.
#'
#' @param tsne_clust A list of clustering results where each element contains clustering information,
#' including the average silhouette score.
#'
#' @return Returns the clustering result with the highest average silhouette score.
#' 
#' @details The function iterates over a list of clustering results (`tsne_clust`) and 
#' selects the cluster with the highest average silhouette score. If no clusters are valid or 
#' the `tsne_clust` list is empty, the function will stop and return an error.
#' 
#'
#' @keywords internal
pick_best_cluster_silhouette <- function(tsne_clust) {
    if (length(tsne_clust) == 0) {
        stop("The tsne_clust list is empty.")
    }
    
    best_silhouette <- -Inf
    best_cluster <- NULL
    
    # Iterate through tsne_clust to find the cluster with the highest average silhouette score
    for (i in seq_along(tsne_clust)) {
        silhouette <- tsne_clust[[i]]$avg_silhouette_score
        
        if (!is.null(silhouette) && silhouette > best_silhouette) {
            best_silhouette <- silhouette
            best_cluster <- tsne_clust[[i]]
        }
    }
    
    if (is.null(best_cluster)) {
        stop("No valid clusters found.")
    }
    
    message(paste("Best cluster selected with silhouette score:", best_silhouette, " Clusters: ", best_cluster$num_clusters))
    return(best_cluster)
}

#' Pick the Best Clustering Result Based on Multiple Metrics
#'
#' This function evaluates multiple clustering results based on various metrics such as modularity, silhouette score, 
#' Davies-Bouldin Index (DBI), and Calinski-Harabasz Index (CH). It normalizes the scores across all metrics, 
#' calculates a combined score for each clustering result, and selects the best clustering result.
#'
#' @param tsne_clust A list of clustering results. Each result should contain metrics such as modularity, silhouette score, 
#' and cluster assignments for the dataset.
#' @param tsne_calc A list containing the t-SNE results. It includes the t-SNE coordinates of the dataset used for clustering.
#'
#' @return The clustering result with the highest combined score based on modularity, silhouette score, 
#' Davies-Bouldin Index (DBI), and Calinski-Harabasz Index (CH).
#'
#' @details 
#' The function computes four different metrics for each clustering result:
#' \itemize{
#'   \item Modularity: A measure of the quality of the division of the network into clusters.
#'   \item Silhouette score: A measure of how similar data points are to their own cluster compared to other clusters.
#'   \item Davies-Bouldin Index (DBI): A ratio of within-cluster distances to between-cluster distances, with lower values being better.
#'   \item Calinski-Harabasz Index (CH): The ratio of the sum of between-cluster dispersion to within-cluster dispersion, with higher values being better.
#' }
#' The scores for each metric are normalized between 0 and 1, and an overall score is calculated for each clustering result. The clustering result with the highest overall score is selected as the best.
#'
#' @importFrom clusterSim index.DB
#' @importFrom fpc cluster.stats
#' @importFrom dplyr filter
#' 
#'
#' @keywords internal
pick_best_cluster_overall <- function(tsne_clust, tsne_calc) {
   if (length(tsne_clust) == 0) {
        stop("The tsne_clust list is empty.")
    }
    
    # Initialize a list to store scores for each clustering result
    score_list <- lapply(tsne_clust, function(clust) {
        # Ensure modularity and silhouette are numeric
        modularity <- as.numeric(clust$modularity)
        silhouette <- as.numeric(clust$avg_silhouette_score)
        
        # Convert cluster labels (pandora_cluster) to numeric if needed
        cluster_labels <- as.numeric(as.factor(clust$info.norm$pandora_cluster)) 
        
        # Calculate Davies-Bouldin Index (lower is better)
        dbi <- tryCatch({
            as.numeric(index.DB(tsne_calc$info.norm, cluster_labels)$DB)
        }, error = function(e) NA)  # Handle error in DB index calculation
        
        # Calculate Calinski-Harabasz Index (higher is better)
        ch_index <- tryCatch({
            as.numeric(cluster.stats(d = dist(tsne_calc$info.norm), cluster_labels)$ch)
        }, error = function(e) NA)  # Handle error in CH index calculation
        
        # Return a list with all scores
        list(modularity = modularity, 
             silhouette = silhouette, 
             dbi = dbi, 
             ch_index = ch_index)
    })
    
    # Remove any NULL or missing values from the score_list
    score_list <- Filter(function(x) {
        !is.null(x$modularity) && !is.null(x$silhouette) && !is.na(x$modularity) && !is.na(x$silhouette)
    }, score_list)
    
    # Check if there are any valid scores to evaluate
    if (length(score_list) == 0) {
        stop("No valid clustering results with all necessary metrics.")
    }
    
    # Debugging message: show score list length
    message("Valid score list calculated: ", length(score_list), " valid results")
    
    # Normalize and combine the scores for each clustering result
    combined_scores <- sapply(score_list, function(x) {
        if (any(is.na(c(x$modularity, x$silhouette, x$dbi, x$ch_index)))) {
            return(NA)  # Skip if any score is NA
        }
        mean(c(normalize(as.numeric(x$modularity)), 
               normalize(as.numeric(x$silhouette)), 
               1 - normalize(as.numeric(x$dbi)),  # Inverse DBI since lower is better
               normalize(as.numeric(x$ch_index))))
    })
    
    # Debugging message: show combined scores
    message("Combined scores: ", paste(combined_scores, collapse = ", "))
    
    # Check if combined_scores is empty or contains only NAs
    if (all(is.na(combined_scores))) {
        stop("No valid combined scores found.")
    }
    
    # Find the index of the clustering result with the highest combined score
    best_index <- which.max(combined_scores)
    
    # Check if best_index is valid
    if (length(best_index) == 0 || is.na(best_index)) {
        stop("Unable to find the best clustering result (no valid index found).")
    }
    
    # Return the best clustering result
    return(tsne_clust[[best_index]])
}
