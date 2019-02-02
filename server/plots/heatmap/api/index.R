#* Plot out data from the iris dataset
#* @serializer contentType list(type='image/png')
#' @post /plots/heatmap/renderPlot
simon$handle$plots$heatmap$renderPlot <- expression(
    function(req, res, ...){
        args <- as.list(match.call())
        plot <- NULL

        resampleID <- 0
        if("resampleID" %in% names(args)){
            resampleID <- as.numeric(args$resampleID)
        }

        settings <- NULL
        if("settings" %in% names(args)){
            settings <- jsonlite::fromJSON(args$settings)
        }

        if(length(settings$removeNA) == 0){
            settings$removeNA = FALSE
        }
        if(length(settings$scale) == 0){
            settings$scale = "column"
        }
        # Define default values
        settings$displayNumbers = FALSE
        settings$displayLegend = FALSE
        settings$displayColnames = FALSE
        settings$displayRownames = FALSE

        if(length(settings$displayOptions) > 0) {
            if("numbers" %in% settings$displayOptions){
                settings$displayNumbers = TRUE
            }
            if("legend" %in% settings$displayOptions){
                settings$displayLegend = TRUE
            }
            if("colnames" %in% settings$displayOptions){
                settings$displayColnames = TRUE
            }
            if("rownames" %in% settings$displayOptions){
                settings$displayRownames = TRUE
            }
        }

        if(length(settings$plotWidth) == 0){
            settings$plotWidth = 20
        }
        if(length(settings$plotRatio) == 0){
            settings$plotRatio = 0.8
        }
        if(length(settings$clustDistance) == 0){
            settings$clustDistance = "correlation"
        }
        if(length(settings$clustLinkage) == 0){
            settings$clustLinkage = "ward.D2"
        }
        if(length(settings$clustOrdering) == 0){
            settings$clustOrdering = 1
        }
        if(length(settings$fontSizeGeneral) == 0){
            settings$fontSizeGeneral = 10
        }
        if(length(settings$fontSizeRow) == 0){
            settings$fontSizeRow = 9
        }
        if(length(settings$fontSizeCol) == 0){
            settings$fontSizeCol = 9
        }
        if(length(settings$fontSizeNumbers) == 0){
            settings$fontSizeNumbers = 7
        }

        ## 1st - Get JOB and his Info from database
        resampleDetails <- db.apps.getFeatureSetData(resampleID)
        ## save(resampleDetails, file = "/tmp/testing.rds")

        if(length(settings$selectedColumns) == 0) {
            settings$selectedColumns <- tail(resampleDetails[[1]]$outcome$remapped, 2)
        }
        if(length(settings$selectedRows) == 0) {
            settings$selectedRows <- tail(resampleDetails[[1]]$features$remapped, 20)
        }

        resamplePath <- downloadDataset(resampleDetails[[1]]$remotePathMain)     
        data <- data.table::fread(resamplePath, header = T, sep = ',', stringsAsFactors = FALSE, data.table = FALSE)

        ## Remove all other than necessary selectedColumns
        data <- data[, names(data) %in% c(settings$selectedRows, settings$selectedColumns)]

        tmp <- tempfile()
        svg(tmp,
            width = 8, height = 8, pointsize = 12,
            onefile = TRUE, family = "Arial", bg = "white",
            antialias = "default")

        print(plot.heatmap(data, 
                            resampleDetails,
                            settings$selectedColumns,
                            settings$selectedRows,
                            settings$removeNA,
                            settings$scale,
                            settings$displayNumbers,
                            settings$displayLegend,
                            settings$displayColnames,
                            settings$displayRownames,
                            settings$plotWidth,
                            settings$plotRatio,
                            settings$clustDistance,
                            settings$clustLinkage,
                            settings$clustOrdering,
                            settings$fontSizeGeneral,
                            settings$fontSizeRow,
                            settings$fontSizeCol,
                            settings$fontSizeNumbers)
            )
        

        dev.off() 
        return (list(image = as.character(RCurl::base64Encode(readBin(tmp, "raw", n = file.info(tmp)$size), "txt"))))
    }
)


