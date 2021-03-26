calculate_umap <- function(dataset, groupingVariable = NULL, settings, fileHeader){

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

	knn_clusters <- settings$knn_clusters
    if(nrow(umap_data) < knn_clusters){
    	knn_clusters <- round(nrow(umap_data) / 2)
    	print(paste0("====> Quick-fix - Adjusting KNN k to: ", knn_clusters))
    }

	pca_clusters <- settings$pca_clusters
    if(min(nrow(umap_data), ncol(umap_data)) <= pca_clusters){
    	pca_clusters <- NULL
    	print(paste0("====> Quick-fix - Adjusting PCA clusters"))
    }

	n_trees <- ceiling((nrow(umap_data) * 0.001)) * 10
    print(paste0("====> Quick-fix - Adjusting n_trees: ", n_trees))

	if(!is_null(groupingVariable)){

		dataset[[groupingVariable]] <- as.factor(dataset[[groupingVariable]])
		#dataset[[groupingVariable]] <- as.factor(dataset[[groupingVariable]])
		reduced_umap <- umap(umap_data, y = dataset[[groupingVariable]],
	                           n_neighbors = knn_clusters, min_dist = 0.001, verbose = FALSE,
	                           n_threads = 8, pca = pca_clusters, n_trees = n_trees,
	                           a = 1.8956, b = 0.8006, approx_pow = TRUE, init = "spca",
	                           target_weight = 0.5, ret_model = TRUE)
	}else{
		reduced_umap <- umap(umap_data,
	                           n_neighbors = knn_clusters, min_dist = 0.001, verbose = FALSE,
	                           n_threads = 8, pca = pca_clusters, n_trees = n_trees,
	                           a = 1.8956, b = 0.8006, approx_pow = TRUE, init = "spca",
	                           target_weight = 0.5, ret_model = TRUE)
	}

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
