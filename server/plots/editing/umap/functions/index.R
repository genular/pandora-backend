calculate_umap <- function(dataset, groupingVariable = NULL, settings, fileHeader){

    # Detect CPU cores for parallel processing
    cpu_cores <- parallel::detectCores(logical = FALSE)
    message(paste("==> Detected CPU cores:", cpu_cores))

    names(dataset) <- plyr::mapvalues(names(dataset), from=fileHeader$remapped, to=fileHeader$original)

    if(!is.null(groupingVariable)){
        print(paste0("====> Removing grouping variable: ", groupingVariable))
        umap_data <- dataset %>% select(-any_of(groupingVariable)) 

        if(settings$includeOtherGroups == FALSE){
            print(paste0("====> Removing all other grouping variables"))
            other_groups <- fileHeader %>% filter(remapped %in% settings$groupingVariables)
            other_groups <- other_groups$original

            umap_data <- umap_data %>% select(-any_of(other_groups))
            print(names(umap_data))
        }
    }else{
        umap_data <- dataset
    }

    umap_data <- umap_data %>% select(where(is.numeric))

    # Dynamically adjust parameters based on the input data
    n_samples <- nrow(umap_data)
    n_features <- ncol(umap_data)

    # Cap PCA components to fewer than features or a maximum of 50
    pca_clusters <- min(settings$pca_clusters, n_features)
    pca_result <- NULL

    if (n_features > pca_clusters) {
        message("==> Reducing dimensions with PCA")
        pca_result <- stats::prcomp(umap_data, center = TRUE, scale. = TRUE, rank. = pca_clusters)
        umap_data <- as.data.frame(pca_result$x)

    }


    # Set UMAP parameters dynamically
    n_neighbors <- if (n_samples < 1000) 30 else if (n_samples < 10000) 40 else min(50, round(sqrt(n_samples) / 2))
    min_dist <- if (n_samples < 1000) 0.01 else if (n_samples < 10000) 0.05 else 0.1
    spread <- if (n_samples < 10000) 1.0 else 1.2
    init_method <- if (n_samples > 50) "pca" else "random"
    learning_rate <- if (n_samples < 5000) 1.5 else if (n_samples < 50000) 2.0 else 2.5
    nn_method <- if (n_samples > 10000) "annoy" else "nndescent"
    n_epochs <- if (n_samples > 10000) 200 else 750  # Increased epochs for smaller data

    # Metric setting
    metric <- "cosine"


  message("==> Running UMAP with dynamically adjusted parameters")
    reduced_umap <- umap(
        X = umap_data,
        y = if (!is.null(groupingVariable)) as.factor(dataset[[groupingVariable]]) else NULL,
        n_neighbors = n_neighbors,
        n_components = 2,
        metric = metric,
        n_epochs = n_epochs,
        learning_rate = learning_rate,
        init = init_method,
        target_weight = 0.5,
        ret_model = TRUE,
        spread = spread,
        min_dist = min_dist,
        nn_method = nn_method,
        n_trees = ceiling(nrow(umap_data) * 0.001),
        # search_k = if (nn_method == "annoy") 2 * n_neighbors * ceiling(nrow(umap_data) * 0.001) * 10 else NULL,
        pca = pca_clusters,
        batch = TRUE,
        n_threads = cpu_cores,
        n_sgd_threads = "auto",
        verbose = TRUE
    )

    message("==> UMAP completed successfully")


    return(list(umap_data = reduced_umap, umap_dataset = umap_data, dataset = dataset, pca_result = pca_result))
}


plot_umap <- function(umap_data, pca_result = NULL, umap_dataset, type = "train", groupingVariable = NULL, settings, fileHeader, tmp_hash){
    theme_set(eval(parse(text=paste0(settings$theme, "()"))))

    if(type == "train"){
        inputData <- as.data.frame(umap_data$embedding) 
    }else if(type == "test"){
        names(umap_dataset) <- plyr::mapvalues(names(umap_dataset), from=fileHeader$remapped, to=fileHeader$original)
        data_input_test <- umap_dataset %>% select(where(is.numeric))

        if(!is.null(groupingVariable)){
            data_input_test <- data_input_test %>% select(-any_of(groupingVariable)) 
        }

        if(!is.null(pca_result)){
            pca_test_result <- predict(pca_result, newdata = data_input_test)
            inputData <- as.data.frame(umap_transform(pca_test_result, umap_data))
        }else{
            reduced_umap <- umap_transform(data_input_test, umap_data)
            inputData <- as.data.frame(reduced_umap)
        }
    }

    # If a grouping variable is provided, use it for coloring
    if(!is.null(groupingVariable)){
        inputData$Categories <- umap_dataset[[groupingVariable]]

        # Creating a custom color palette
        num_categories <- length(unique(inputData$Categories))
        palette <- as.vector(Polychrome::createPalette(
          num_categories + 2,
          seedcolors = c("#ffffff", "#000000"),
          range = c(10, 90)
        )[-(1:2)])  # Excluding the first two for more variance

        plotData <- ggplot(inputData, aes(x = V1, y = V2, color = Categories)) +
                    geom_point(alpha = 0.6, size = 1.0) +
                    scale_color_manual(values = palette) +
                    theme_minimal() +
                    labs(title = "UMAP Visualization", x = "", y = "", color = "Categories") +
                    theme(legend.position = "right") +
                    guides(color = guide_legend(override.aes = list(size = 5, alpha = 1)))
    }else{
        plotData <- ggplot(inputData, aes(x = V1, y = V2)) +
                    geom_point(cex=1.5) +
                    theme_minimal() +
                    labs(x = "UMAP V1", y = "UMAP V2")
    }

    # Save plot to SVG
    tmp_path <- tempfile(pattern = tmp_hash, tmpdir = tempdir(), fileext = ".svg")
    svg(tmp_path, width = settings$plot_size * settings$aspect_ratio, height = settings$plot_size, pointsize = 12, onefile = TRUE, family = "Arial", bg = "white", antialias = "default")
    print(plotData)
    dev.off() 

    return(tmp_path) 
}
