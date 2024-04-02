round_df <- function(x, digits) {
    # round all numeric variables
    # x: data frame 
    # digits: number of digits to round
    numeric_columns <- sapply(x, mode) == 'numeric'
    x[numeric_columns] <-  round(x[numeric_columns], digits)
    return(x)
}

sort_hclust <- function(...) as.hclust(dendsort::dendsort(as.dendrogram(...), isReverse = FALSE))     

calcClustering = function(mat, distance= "correlation", linkage = "complete"){
  #calculate distances between rows of mat and clustering
  if(is.na(distance)){
    return(NA)
  } else if(distance == "correlation"){
    sds = apply(mat, 1, sd, na.rm = TRUE)
    if(any(is.na(sds) | (sds == 0))){
      print("some objects have zero standard deviation, please choose a distance other than correlation!")
      return(NA)
    }
    d = as.dist(1 - cor(t(mat)))
  } else {
    d = dist(mat, method = distance)
  }
  hclust(d, method = linkage)
}

#' @param linkage One from \code{"single"}, \code{"complete"}, \code{"average"}  (default), \code{"mcquitty"}, \code{"median"}, \code{"centroid"}, \code{"ward.D2"} or \code{"ward.D"}.
#' @param distance One from \code{"correlation"} (default), \code{"euclidean"}, \code{"maximum"}, \code{"manhattan"}, \code{"canberra"}, \code{"binary"}, \code{"minkowski"} or \code{NA} for no clustering.
#' @param ordering
## { id: 1, value: "tightest cluster first" },
## { id: 2, value: "higher median value first" },
## { id: 3, value: "higher mean value first" },
## { id: 4, value: "lower median value first" },
## { id: 5, value: "original" },
## { id: 6, value: "reverse original" }

calcOrdering = function(mat, distance, linkage, ordering){
    hc = calcClustering(mat, distance, linkage)

    if(class(hc) != "hclust") {
        return(hc)
    }
    if((length(unique(hc$height)) < length(hc$height)) && !is.na(ordering)){
        print("====> multiple objects have same distance, only tree ordering 'tightest cluster first' is supported!")
        return(hc)
    }
    if(!(all(hc$height == sort(hc$height)))){
        print("====> some clusters have distance lower than its subclusters, please choose a method other than median or centroid!")
        return(hc)
    }
    if(is.na(ordering) || ordering == 1){
        return(hc) #default hclust() output
    } else if(ordering == 2){
        wts = rank(-apply(mat, 1, median, na.rm = TRUE))
    } else if(ordering == 3){
        wts = rank(-rowMeans(mat, na.rm = TRUE)) #faster than apply
    } else if(ordering == 4){
        wts = rank(apply(mat, 1, median, na.rm = TRUE))
    } else if(ordering == 5){
        wts = rank(rowMeans(mat, na.rm = TRUE)) #faster than apply
    } else if(ordering == 6){
        wts = 1:nrow(mat)
    } else if(ordering == 7){
        wts = nrow(mat):1
    } else {
        return(NA)
    }
    hc2 = as.hclust(reorder(as.dendrogram(hc), wts, agglo.FUN = mean))
    return(hc2)
}

plot.heatmap <- function(data,
                         fileHeader,
                         selectedColumns,
                         selectedRows,
                         removeNA,
                         scale,
                         displayNumbers,
                         displayLegend,
                         displayColnames,
                         displayRownames,
                         plotWidth,
                         plotRatio,
                         clustDistance,
                         clustLinkage,
                         clustOrdering,
                         fontSizeGeneral,
                         fontSizeRow,
                         fontSizeCol,
                         fontSizeNumbers,
                         settings = NULL,
                         pallets = c("Blues", "Greens", "Greys", "Oranges", "Purples", "Reds"),
                         plotClustered = TRUE,
                         orederingColumn = "") {
    if (!is.null(removeNA) & removeNA == TRUE) {
        data <- data[complete.cases(data),]
    }
    
    if (plotClustered == FALSE & orederingColumn != "") {
        data <- data[with(data, order(data[[orederingColumn]])),]
    }
    
    annotationColumn = NULL
    legendColors = list()
    
    counter <- 0
    for (column in selectedColumns) {
        counter <- counter + 1
        
        # Ensure data[[column]] is a factor with the correct levels
        unique_levels <- unique(data[[column]])
        data[[column]] <- factor(data[[column]], levels = unique_levels)


        # Initialize annotationColumn if null, or append new column
        if(is.null(annotationColumn)){
            annotationColumn <- data.frame(column = data[[column]])
            colnames(annotationColumn) <- column
        } else {
            annotationColumn[[column]] <- data[[column]]
        }
        
        # Determine the number of unique levels and set colors
        nb.cols <- length(unique_levels)
        if(nb.cols > 8){
            colorsTemp <- if(!is.null(settings)) {
                grDevices::colorRampPalette(RColorBrewer::brewer.pal(min(8, nb.cols), settings$colorPalette))(nb.cols)
            } else {
                grDevices::colorRampPalette(RColorBrewer::brewer.pal(min(8, nb.cols), "Set2"))(nb.cols)
            }
        } else {
            colors.cutoff <- max(nb.cols, 3)
            colorsTemp <- RColorBrewer::brewer.pal(colors.cutoff, pallets[counter %>% min(length(pallets))])
        }
        legendColors[[column]] <- setNames(colorsTemp, unique_levels)
        
    }
    
    rownames(annotationColumn) = rownames(data)
    
    if (!is.null(fileHeader)) {
        names(annotationColumn) <-
            plyr::mapvalues(
                names(annotationColumn),
                from = fileHeader$remapped,
                to = fileHeader$original
            )
        names(legendColors) <-
            plyr::mapvalues(names(legendColors),
                            from = fileHeader$remapped,
                            to = fileHeader$original)
    }
    
    
    data <-
        subset(data, select = !(names(data) %in% selectedColumns))
    if (!is.null(fileHeader)) {
        names(data) <-
            plyr::mapvalues(names(data),
                            from = fileHeader$remapped,
                            to = fileHeader$original)
    }
    
    ## Transform data and order it by rowMeans
    
    t_data <- t(data)
    if (plotClustered == TRUE) {
        hClustRows <-
            calcOrdering(t_data, clustDistance, clustLinkage, clustOrdering)
        hClustCols <-
            calcOrdering(t(t_data), clustDistance, clustLinkage, clustOrdering)
    } else{
        hClustRows <- FALSE
        hClustCols <- FALSE
    }
    
    #image dimensions:
    picwIn = plotWidth / 2.54
    pichIn = picwIn * plotRatio
    dotsPerCm = 96 / 2.54 #how many points per cm
    picw = picwIn * 2.54 * dotsPerCm
    pich = pichIn * 2.54 * dotsPerCm
    
    
    # Start with the base list of input arguments for pheatmap
    input_args <- c(
        list(
            t_data,
            cluster_row =  hClustRows,
            cluster_cols = hClustCols,
            
            scale = scale,
            annotation_col = annotationColumn,
            annotation_colors = legendColors,
            
            annotation_legend = displayLegend,
            legend = displayLegend,
            
            show_colnames = displayColnames,
            show_rownames = displayRownames,
            
            fontface = "bold",
            border_color = "white",
            fontsize = fontSizeGeneral,
            fontsize_row = fontSizeRow,
            fontsize_col = fontSizeCol,
            
            display_numbers = displayNumbers,
            number_format = paste0("%.2f"),
            fontsize_number = fontSizeNumbers,
            width = picwIn,
            height = pichIn
        )
    )
    
    if (getRversion() >= "3.6.0") {
        input_args <-
            input_args[!names(input_args) %in% c("fontface", "border_color")]
    }
    
    out <- do.call(pheatmap::pheatmap, input_args)
    
    return(out)
}
