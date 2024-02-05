## T-Distributed Stochastic Neighbor Embedding using a Barnes-Hut Implementation
## https://cran.r-project.org/web/packages/Rtsne/Rtsne.pdf
calculate_tsne <- function(dataset, settings, fileHeader, removeGroups = TRUE){
	info.norm <- dataset
	names(info.norm) <- plyr::mapvalues(names(info.norm), from=fileHeader$remapped, to=fileHeader$original)

    if(!is.null(settings$groupingVariables) && removeGroups == TRUE){
    	print(paste0("====> Removing grouping variables"))
    	dataset <- dataset %>% select(-any_of(settings$groupingVariables)) 
    }

    ## To be sure remove all other non numeric columns
	tsne_data <- dataset %>% select(where(is.numeric))

    ## Check perplexity
	# Adjust perplexity based on the dataset size
	perplexity <- min(settings$perplexity, nrow(dataset)/2)
	if (perplexity != settings$perplexity) {
		message("====> Adjusting perplexity to: ", perplexity)
	}

	header_mapped <- fileHeader %>% filter(remapped %in% names(tsne_data))

	pca.scale <- TRUE
	if(!is.null(settings$preProcessDataset) && length(settings$preProcessDataset) > 0){
		pca.scale <- FALSE
	}

	tsne.norm  <- Rtsne::Rtsne(
		as.matrix(tsne_data), 
		perplexity = perplexity, 
		pca = TRUE, ## Whether an initial PCA step should be performed
		verbose = FALSE, 
		max_iter = 2000, 
		pca_scale = pca.scale,  
		pca_center = pca.scale, 
		check_duplicates = FALSE)

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
cluster_tsne_hierarchical <- function(info.norm, tsne.norm, settings){
	set.seed(1337)
	hc.norm = stats::hclust(dist(tsne.norm$Y), method = settings$clustLinkage) 
	
	info.norm$cluster = factor(cutree(hc.norm, settings$clustGroups))

	lc.cent = info.norm %>% group_by(cluster) %>% 
							select(tsne1, tsne2) %>% 
							summarize_all(mean)


	return(list(info.norm = info.norm, cluster_data = lc.cent))
}

# Mclust clustering
cluster_tsne_mclust <- function(info.norm, tsne.norm, settings){

    print(paste("==> cluster_tsne_mclust clustGroups: ", settings$clustGroups))

	set.seed(1337)
	mc.norm = mclust::Mclust(tsne.norm$Y, settings$clustGroups)

	info.norm$cluster = factor(mc.norm$classification)

	lc.cent = info.norm %>% group_by(cluster) %>% 
							select(tsne1, tsne2) %>% 
							summarize_all(mean)

	return(list(info.norm = info.norm, cluster_data = lc.cent))
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

	plotData <- ggplot(info.norm, aes(x = tsne1, y = tsne2, colour = cluster)) + 
						geom_point(size = settings$pointSize) + 
						ggrepel::geom_label_repel(aes(label = cluster), data = cluster_data) + 
						guides(colour = FALSE) +
						labs(x = "t-SNE dimension 1", y = "t-SNE dimension 2") + 
	    				scale_color_brewer(palette=settings$colorPalette) + 
        				theme(text=element_text(size=settings$fontSize), legend.position = settings$legendPosition)

    tmp_path <- tempfile(pattern =  tmp_hash, tmpdir = tempdir(), fileext = ".svg")
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
