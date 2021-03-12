
calculate_tsne <- function(dataset, settings, fileHeader){
	info.norm <- dataset
	names(info.norm) <- plyr::mapvalues(names(info.norm), from=fileHeader$remapped, to=fileHeader$original)

	tsne_data <- dataset %>% select(where(is.numeric))
	tsne.norm  <- Rtsne::Rtsne(as.matrix(tsne_data), pca = TRUE, verbose = TRUE, max_iter = 2000, pca_scale = FALSE, pca_center = FALSE)
	info.norm <- info.norm %>% mutate(tsne1 = tsne.norm$Y[, 1], tsne2 = tsne.norm$Y[,2])

	return(list(info.norm = info.norm, tsne.norm = tsne.norm))
}

plot_tsne <- function(info.norm, settings, fileHeader){
    theme_set(eval(parse(text=paste0(settings$theme, "()"))))

    if(!is.null(settings$groupingVariable)){
    	groupingVariable <- fileHeader %>% filter(remapped %in% settings$groupingVariable)
    	groupingVariable <- groupingVariable$original

    	renderedPlot <- ggplot(info.norm, aes_string(x = "tsne1", y = "tsne2", colour = groupingVariable))
	}else{
		renderedPlot <- ggplot(info.norm, aes_string(x = "tsne1", y = "tsne2"))
	}

	renderedPlot <- renderedPlot + 
	    geom_point(alpha = 0.3) + theme_bw() + 
	    labs(x = "t-SNE dimension 1", y = "t-SNE dimension 2") + 
	    scale_fill_brewer(palette=settings$colorPalette) + 
        theme(text=element_text(size=settings$fontSize), axis.title.x = element_blank(), axis.text.x = element_blank(), axis.ticks.x = element_blank())

	return(renderedPlot)
}

## https://jmonlong.github.io/Hippocamplus/2018/02/13/tsne-and-clustering/

# KNN graph and Louvain community detection
cluster_tsne_knn_louvain <- function(info.norm, tsne.norm, settings){
	k = 250
	knn.norm = FNN::get.knn(as.matrix(tsne.norm$Y), k = k)
	knn.norm = data.frame(
					from = rep(1:nrow(knn.norm$nn.index), k), 
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

	hc.norm = stats::hclust(dist(tsne.norm$Y), method = "ward.D")
	
	info.norm$cluster = factor(cutree(hc.norm, 9))

	lc.cent = info.norm %>% group_by(cluster) %>% 
							select(tsne1, tsne2) %>% 
							summarize_all(mean)


	return(list(info.norm = info.norm, cluster_data = lc.cent))
}

# Mclust clustering
cluster_tsne_mclust <- function(info.norm, tsne.norm, settings){

	mc.norm = mclust::Mclust(tsne.norm$Y, 9)
	info.norm$cluster = factor(mc.norm$classification)
	lc.cent = info.norm %>% group_by(cluster) %>% 
							select(tsne1, tsne2) %>% 
							summarize_all(mean)

	return(list(info.norm = info.norm, cluster_data = lc.cent))
}

#Density-based clustering
cluster_tsne_density <- function(info.norm, tsne.norm, settings){

	ds.norm = fpc::dbscan(tsne.norm$Y, 2)
	info.norm$cluster = factor(ds.norm$cluster)
	lc.cent = info.norm %>% group_by(cluster) %>% 
							select(tsne1, tsne2) %>% 
							summarize_all(mean)

	return(list(info.norm = info.norm, cluster_data = lc.cent))
}


plot_clustered_tsne <- function(info.norm, cluster_data, settings){

    theme_set(eval(parse(text=paste0(settings$theme, "()"))))

	renderedPlot <- ggplot(info.norm, aes(x = tsne1, y = tsne2, colour = cluster)) + 
						geom_point(alpha = 0.3) + 
						theme_bw() + 
						ggrepel::geom_label_repel(aes(label = cluster), data = cluster_data) + 
						guides(colour = FALSE) +
						labs(x = "t-SNE dimension 1", y = "t-SNE dimension 2") + 
					    scale_fill_brewer(palette=settings$colorPalette) + 
				        theme(text=element_text(size=settings$fontSize), axis.title.x = element_blank(), axis.text.x = element_blank(), axis.ticks.x = element_blank())

	return(renderedPlot)
}



