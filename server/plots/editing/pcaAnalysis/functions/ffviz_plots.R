plots_fviz_eig <-function(inputData, settings, tmp_hash){

    theme_set(eval(parse(text=paste0(settings$theme, "()"))))

    plotData <- fviz_eig(inputData, addlabels = TRUE, ylim = c(0, 50)) +
        scale_fill_brewer(palette=settings$colorPalette) +
        theme(text=element_text(size=settings$fontSize))

    tmp_path <- tempfile(pattern =  tmp_hash, tmpdir = tempdir(), fileext = ".svg")
    svg(tmp_path, width = settings$plot_size * settings$aspect_ratio, height = settings$plot_size, pointsize = 12, onefile = TRUE, family = "Arial", bg = "white", antialias = "default")
        print(plotData)
    dev.off()   

    return(tmp_path)
}


plots_fviz_pca_ind_grouped <- function(inputData, dataset, settings, groupingVariable, fileHeader, tmp_hash){
    theme_set(eval(parse(text=paste0(settings$theme, "()"))))

    plotData <- fviz_pca_ind(inputData,
                                geom.ind = "point", # show points only (nbut not "text")
                                col.ind = dataset[[groupingVariable]], # color by groups
                                palette = settings$colorPalette,
                                addEllipses = settings$addEllipses,
                                ellipse.alpha = settings$ellipseAlpha,
                                label = "var",
                                pointsize = settings$pointSize,
                                labelsize = settings$labelSize,
                                col.var = "black",
                                repel = TRUE, 
                                legend.title = groupingVariable) + 
                                #scale_fill_brewer(palette=settings$colorPalette) +
                                theme(text=element_text(size=settings$fontSize))

    tmp_path <- tempfile(pattern =  tmp_hash, tmpdir = tempdir(), fileext = ".svg")
    svg(tmp_path, width = settings$plot_size * settings$aspect_ratio, height = settings$plot_size, pointsize = 12, onefile = TRUE, family = "Arial", bg = "white", antialias = "default")
        print(plotData)
    dev.off()  

    return(tmp_path) 

}


plots_fviz_pca_biplot_grouped <- function(inputData, dataset, settings, groupingVariable, fileHeader, tmp_hash){

    theme_set(eval(parse(text=paste0(settings$theme, "()"))))

    plotData <- fviz_pca_biplot(inputData, 
                                # Individuals
                                geom.ind = "point",
                                fill.ind = dataset[[groupingVariable]],
                                col.ind = "black",
                                pointshape = 21, 
                                pointsize = settings$pointSize,
                                labelsize = settings$labelSize,

                                palette = settings$colorPalette,
                                addEllipses = settings$addEllipses,
                                ellipse.alpha = settings$ellipseAlpha,

                                # Variables
                                alpha.var ="contrib",
                                col.var = "contrib",
                                gradient.cols = settings$colorPalette,
                                
                                legend.title = list(
                                    fill = groupingVariable,
                                    color = "Contrib",
                                    alpha = "Contrib")
                                ) + 
                                #scale_fill_brewer(palette=settings$colorPalette) +
                                theme(text=element_text(size=settings$fontSize))

    tmp_path <- tempfile(pattern =  tmp_hash, tmpdir = tempdir(), fileext = ".svg")
    svg(tmp_path, width = settings$plot_size * settings$aspect_ratio, height = settings$plot_size, pointsize = 12, onefile = TRUE, family = "Arial", bg = "white", antialias = "default")
        print(plotData)
    dev.off()  

    return(tmp_path) 

}



plots_fviz_pca <-function(inputData, choice = "cos2", type = "var", settings, tmp_hash, dataset, fileHeader, cluster = FALSE){
    theme_set(eval(parse(text=paste0(settings$theme, "()"))))

	if(type == "var"){
        if(cluster == TRUE){
            # Color variables by groups
            plotData <- fviz_pca_var(inputData, col.var = choice, 
                            palette = settings$colorPalette,
                            labelsize = settings$labelSize,
                            legend.title = "Cluster")
        }else{
            plotData <- fviz_pca_var(inputData, 
                            col.var = choice,
                            labelsize = settings$labelSize,
                            gradient.cols = c("#00AFBB", "#E7B800", "#FC4E07"), 
                            repel = TRUE)
        }
	}else{
        plotData <- fviz_pca_ind(inputData,
                        col.ind = choice,
                        pointsize = settings$pointSize,
                        labelsize = settings$labelSize,
                        gradient.cols = c("#00AFBB", "#E7B800", "#FC4E07"), 
                        repel = TRUE
        )
	}

    plotData <- plotData +
        scale_fill_brewer(palette=settings$colorPalette) +
        theme(text=element_text(size=settings$fontSize))

    tmp_path <- tempfile(pattern =  tmp_hash, tmpdir = tempdir(), fileext = ".svg")
    svg(tmp_path, width = settings$plot_size * settings$aspect_ratio, height = settings$plot_size, pointsize = 12, onefile = TRUE, family = "Arial", bg = "white", antialias = "default")
        print(plotData)
    dev.off()   

    return(tmp_path)
}

plots_corrplot <-function(inputData, settings, tmp_hash){

    tmp_path <- tempfile(pattern =  tmp_hash, tmpdir = tempdir(), fileext = ".svg")
    svg(tmp_path, width = settings$plot_size * settings$aspect_ratio, height = settings$plot_size, pointsize = 12, onefile = TRUE, family = "Arial", bg = "white", antialias = "default")
        plotData <- corrplot(inputData, is.corr=FALSE)
        print(plotData)
    dev.off()   

    return(tmp_path)
}

plots_fviz_cos2 <-function(inputData, choice = "var", settings, tmp_hash){

    theme_set(eval(parse(text=paste0(settings$theme, "()"))))

	plotData <- fviz_cos2(inputData, choice = choice, axes = 1:2) +
        scale_fill_brewer(palette=settings$colorPalette) +
        theme(text=element_text(size=settings$fontSize)) + coord_flip()

    tmp_path <- tempfile(pattern =  tmp_hash, tmpdir = tempdir(), fileext = ".svg")
    svg(tmp_path, width = settings$plot_size * settings$aspect_ratio, height = settings$plot_size, pointsize = 12, onefile = TRUE, family = "Arial", bg = "white", antialias = "default")
        print(plotData)
    dev.off()   

    return(tmp_path)
}

plots_fviz_contrib <-function(inputData, choice, axes, top, settings, tmp_hash){

    theme_set(eval(parse(text=paste0(settings$theme, "()"))))

	plotData <- fviz_contrib(inputData, choice = choice, axes = axes, top = top) +
        scale_fill_brewer(palette=settings$colorPalette) +
        theme(text=element_text(size=settings$fontSize)) + coord_flip()

    tmp_path <- tempfile(pattern =  tmp_hash, tmpdir = tempdir(), fileext = ".svg")
    svg(tmp_path, width = settings$plot_size * settings$aspect_ratio, height = settings$plot_size, pointsize = 12, onefile = TRUE, family = "Arial", bg = "white", antialias = "default")
        print(plotData)
    dev.off()   

    return(tmp_path)
}


