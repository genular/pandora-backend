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


plot.heatmap <- function(   data, 
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
                            settings = NULL){

    pallets <- c("Blues", "Greens", "Greys", "Oranges", "Purples", "Reds")

    if(!is.null(removeNA) & removeNA == TRUE){
        data <- data[complete.cases(data), ]
    }

    annotationColumn = NULL
    legendColors = list()

    counter <- 0
    for(column in selectedColumns){
      counter <- counter + 1

        data[[column]] <- as.factor(data[[column]])
        data[[column]] <- factor(
            data[[column]],levels = levels(data[[column]])
        )
        if(is.null(annotationColumn)){
            annotationColumn = data.frame(
                    column = data[[column]]
                )
            colnames(annotationColumn)[colnames(annotationColumn)=="column"] <- column

        }else{
             annotationColumn[[column]] <- NA
             annotationColumn[[column]] <- data[[column]]
        }

        nb.cols <- length(unique(data[[column]]))
        if(nb.cols > 8){
          if(!is.null(settings)){
              colorsTemp <- grDevices::colorRampPalette(RColorBrewer::brewer.pal(8, settings$colorPalette))(nb.cols)
            }else{
              colorsTemp <- grDevices::colorRampPalette(RColorBrewer::brewer.pal(8, "Set2"))(nb.cols)
            }
        }else{
            colors.cutoff <- nb.cols
            if(colors.cutoff < 3){
                colors.cutoff <- 3
            }
          colorsTemp <- RColorBrewer::brewer.pal(colors.cutoff, pallets[counter])
        }
        colorsTemp <- head(colorsTemp,n=nb.cols)

        legendColorTemp <- setNames(colorsTemp, levels(data[[column]]))
        legendColorTemp <- legendColorTemp[!is.na(names(legendColorTemp))]
        legendColors[[column]] <- legendColorTemp

    }  

    rownames(annotationColumn) = rownames(data)

    if(!is.null(fileHeader)){
      names(annotationColumn) <- plyr::mapvalues(names(annotationColumn), from=fileHeader$remapped, to=fileHeader$original)
      names(legendColors) <- plyr::mapvalues(names(legendColors), from=fileHeader$remapped, to=fileHeader$original)
    }


    data <- subset(data, select = !(names(data) %in% selectedColumns) )
    if(!is.null(fileHeader)){
      names(data) <- plyr::mapvalues(names(data), from=fileHeader$remapped, to=fileHeader$original)
    }

    ## Transform data and order it by rowMeans
    t_data <- t(data)

    hClustRows <- calcOrdering(t_data, clustDistance, clustLinkage, clustOrdering)
    hClustCols <- calcOrdering(t(t_data), clustDistance, clustLinkage, clustOrdering)

    #image dimensions:
    picwIn = plotWidth / 2.54
    pichIn = picwIn * plotRatio
    dotsPerCm = 96 / 2.54 #how many points per cm
    picw = picwIn * 2.54 * dotsPerCm
    pich = pichIn * 2.54 * dotsPerCm


    input_args <- c(list(t_data,
                       cluster_row =  hClustRows,
                       cluster_cols = hClustCols,

                       scale = scale,
                       annotation_col = annotationColumn, 
                       annotation_colors = legendColors, 
                       
                       annotation_legend = displayLegend,
                       legend = displayLegend,

                       show_colnames = displayColnames,
                       show_rownames = displayRownames,
                       
                       fontface="bold", 
                       border_color="white", 
                       fontsize = fontSizeGeneral,
                       fontsize_row= fontSizeRow, 
                       fontsize_col = fontSizeCol,

                       display_numbers = displayNumbers,
                       number_format = paste0("%.2f"),
                       fontsize_number = fontSizeNumbers,
                       width = picwIn, 
                       height = pichIn
                    ))

    out <- do.call(pheatmap::pheatmap, input_args)

    return(out)
}
