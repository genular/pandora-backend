
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
    perplexity <- settings$perplexity
    if(nrow(tsne_data) < settings$perplexity){
    	perplexity <- 1
    	print(paste0("====> Quick-fix - Adjusting perplexity to: ", perplexity))
    }
	header_mapped <- fileHeader %>% filter(remapped %in% names(tsne_data))

	tsne.norm  <- Rtsne::Rtsne(as.matrix(tsne_data), perplexity = perplexity, pca = TRUE, verbose = FALSE, max_iter = 2000, pca_scale = FALSE, pca_center = FALSE, check_duplicates = FALSE)

	info.norm <- info.norm %>% mutate(tsne1 = tsne.norm$Y[, 1], tsne2 = tsne.norm$Y[,2])

	return(list(info.norm = info.norm, tsne.norm = tsne.norm, tsne_columns = header_mapped$original))
}

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
	    geom_point() +
	    labs(x = "t-SNE dimension 1", y = "t-SNE dimension 2") + 
	    scale_color_brewer(palette=settings$colorPalette) + 
        theme(text=element_text(size=settings$fontSize))


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
				    geom_point() +
				    labs(x = "t-SNE dimension 1", y = "t-SNE dimension 2") + 
			        theme(text=element_text(size=settings$fontSize))
	}else{
		plotData <- ggplot(info.norm, aes_string(x = "tsne1", y = "tsne2", colour = colorVariable))+ 
				    geom_point() +
            		scale_color_continuous(low = "blue", high = "red", guide = "colourbar", aesthetics = "colour") +
				    labs(x = "t-SNE dimension 1", y = "t-SNE dimension 2") + 
			        theme(text=element_text(size=settings$fontSize))
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
	knn_clusters <- settings$knn_clusters
    if(nrow(tsne.norm$Y) < knn_clusters){
    	knn_clusters <- round(nrow(tsne.norm$Y) / 2)
    	print(paste0("====> Quick-fix - Adjusting KNN k to: ", knn_clusters))
    }

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

	hc.norm = stats::hclust(dist(tsne.norm$Y), method = settings$clustLinkage) 
	
	info.norm$cluster = factor(cutree(hc.norm, settings$clustGroups))

	lc.cent = info.norm %>% group_by(cluster) %>% 
							select(tsne1, tsne2) %>% 
							summarize_all(mean)


	return(list(info.norm = info.norm, cluster_data = lc.cent))
}

# Mclust clustering
cluster_tsne_mclust <- function(info.norm, tsne.norm, settings){

	mc.norm = Mclust(tsne.norm$Y, settings$clustGroups)
	info.norm$cluster = factor(mc.norm$classification)
	lc.cent = info.norm %>% group_by(cluster) %>% 
							select(tsne1, tsne2) %>% 
							summarize_all(mean)

	return(list(info.norm = info.norm, cluster_data = lc.cent))
}

#Density-based clustering
cluster_tsne_density <- function(info.norm, tsne.norm, settings){

	ds.norm = fpc::dbscan(tsne.norm$Y, settings$reachabilityDistance)
	info.norm$cluster = factor(ds.norm$cluster)
	lc.cent = info.norm %>% group_by(cluster) %>% 
							select(tsne1, tsne2) %>% 
							summarize_all(mean)

	return(list(info.norm = info.norm, cluster_data = lc.cent))
}


plot_clustered_tsne <- function(info.norm, cluster_data, settings){

    theme_set(eval(parse(text=paste0(settings$theme, "()"))))

	renderedPlot <- ggplot(info.norm, aes(x = tsne1, y = tsne2, colour = cluster)) + 
						geom_point() + 
						ggrepel::geom_label_repel(aes(label = cluster), data = cluster_data) + 
						guides(colour = FALSE) +
						labs(x = "t-SNE dimension 1", y = "t-SNE dimension 2") + 
	    				scale_color_brewer(palette=settings$colorPalette) + 
        				theme(text=element_text(size=settings$fontSize))

	return(renderedPlot)
}



