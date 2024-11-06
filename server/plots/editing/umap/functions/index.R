calculate_umap <- function(dataset, groupingVariable = NULL, settings, fileHeader) {
    # Detect CPU cores for parallel processing
    cpu_cores <- parallel::detectCores(logical = FALSE)
    message(paste("==> Detected CPU cores:", cpu_cores))

    # Convert dataset to data.table for more efficient handling
    data.table::setDT(dataset)
    message("==> Dataset converted to data.table")

    # Map values for column names based on file header
    message("==> Renaming columns based on file header")
    data.table::setnames(dataset, old = fileHeader$remapped, new = fileHeader$original, skip_absent = TRUE)

    # Filter out grouping variables if specified
    if (!is.null(groupingVariable)) {
        message("==> Removing specified grouping variable and other groups if not included")
        dataset[, (groupingVariable) := NULL]
        
        if (!settings$includeOtherGroups) {
            other_groups <- dplyr::filter(fileHeader, remapped %in% settings$groupingVariables) %>% dplyr::pull(original)
            dataset[, (other_groups) := NULL]
        }
    }

    # Select only numeric columns
    numeric_cols <- names(Filter(is.numeric, dataset))
    umap_data <- dataset[, ..numeric_cols]

    # Dynamically calculate PCA components if dataset has high dimensions
    pca_clusters <- min(50, ncol(umap_data))  # Cap PCA components to 50 or fewer
    if (ncol(umap_data) > pca_clusters) {
        message("==> Reducing dimensions with PCA")
        pca_result <- stats::prcomp(umap_data, center = TRUE, scale. = TRUE, rank. = pca_clusters)
        umap_data <- data.table::as.data.table(pca_result$x)
    }

    # Choose nn_method dynamically
    nn_method <- if (nrow(umap_data) > 10000) "annoy" else "fnn"
    n_neighbors <- max(15, min(100, sqrt(nrow(umap_data)) / 2))
    min_dist <- if (nrow(umap_data) > 50000) 0.1 else 0.05
    spread <- if (nrow(umap_data) > 50000) 1.2 else 1.0
    learning_rate <- if (nrow(umap_data) > 100000) 2.0 else 1.5
    init_method <- if (ncol(umap_data) > 100) "pca" else "spectral"
    init_sdev <- if (nrow(umap_data) > 50000) 0.1 else 0.05

    message("==> Running UMAP with method:", nn_method, "and", cpu_cores, "threads")
    reduced_umap <- uwot::umap(
        X = umap_data,
        y = if (!is.null(groupingVariable)) dataset[[groupingVariable]] else NULL,
        n_neighbors = n_neighbors,
        n_components = 2,
        metric = "euclidean",
        n_epochs = ifelse(nrow(umap_data) > 10000, 200, 500),
        learning_rate = learning_rate,
        init = init_method,
        init_sdev = init_sdev,
        spread = spread,
        min_dist = min_dist,
        nn_method = nn_method,
        n_trees = if (nn_method == "annoy") ceiling(nrow(umap_data) * 0.001) * 10 else NULL,
        search_k = if (nn_method == "annoy") 2 * n_neighbors * ceiling(nrow(umap_data) * 0.001) * 10 else NULL,
        pca = pca_clusters,
        batch = TRUE,
        n_threads = cpu_cores,
        n_sgd_threads = "auto",
        verbose = TRUE
    )

    message("==> UMAP completed")

    return(list(umap_data = reduced_umap, umap_dataset = umap_data, dataset = dataset))
}



plot_umap <- function(umap_data, umap_dataset, type = "train", groupingVariable = NULL, settings, fileHeader, tmp_hash){
    theme_set(eval(parse(text=paste0(settings$theme, "()"))))

    if(type == "train"){
    	inputData <- as.data.frame(umap_data$embedding)	
    }else if(type == "test"){

		names(umap_dataset) <- plyr::mapvalues(names(umap_dataset), from=fileHeader$remapped, to=fileHeader$original)
    	data_input_test <- umap_dataset %>% select(where(is.numeric))

	    if(!is.null(groupingVariable)){
	    	data_input_test <- data_input_test %>% select(-any_of(groupingVariable)) 
	    }else{
	    	data_input_test <- data_input_test
	    }

		reduced_umap <- umap_transform(data_input_test, umap_data)
		inputData <- as.data.frame(reduced_umap)
    }
	

    if(!is_null(groupingVariable)){
		plotData <- inputData %>%
		    mutate(Categories = umap_dataset[[groupingVariable]]) %>%
		    ggplot(aes(V1, V2, color = Categories))
    }else{
		plotData <- inputData %>%
		    ggplot(aes(V1, V2)) + geom_point(cex=1.5)
    }

	plotData <- plotData + geom_point(cex=1.5) +
	    labs(x = "UMAP V1", y = "UMAP V2") + 
	    scale_color_brewer(palette=settings$colorPalette) + 
        theme(text=element_text(size=settings$fontSize))


    tmp_path <- tempfile(pattern =  tmp_hash, tmpdir = tempdir(), fileext = ".svg")
    svg(tmp_path, width = settings$plot_size * settings$aspect_ratio, height = settings$plot_size, pointsize = 12, onefile = TRUE, family = "Arial", bg = "white", antialias = "default")
        print(plotData)
    dev.off() 

    return(tmp_path) 
}
