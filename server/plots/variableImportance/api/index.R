#* Plot out data from the iris dataset
#* @serializer contentType list(type='image/png')
#' @post /plots/variableImportance/renderPlot
simon$handle$plots$variableImportance$renderPlot <- expression(
    function(req, res, ...){
        args <- as.list(match.call())
        plot <- NULL

        resampleID <- 0
        if("resampleID" %in% names(args)){
            resampleID <- as.numeric(args$resampleID)
        }
        variables <- NULL
        if("variables" %in% names(args)){
            variables <- jsonlite::fromJSON(args$variables)
        }
        modelsID <- NULL
        if("modelsID" %in% names(args)){
            modelsID <- jsonlite::fromJSON(args$modelsID)
        }
        settings <- NULL
        if("settings" %in% names(args)){
            settings <- jsonlite::fromJSON(args$settings)
        }

        if(length(settings$dotsize) == 0) {
            settings$dotsize <- 0.50
        }
        if(length(settings$theme) == 0) {
            settings$theme <- "theme_gray"
        }
        if(length(settings$colorPalette) == 0) {
            settings$colorPalette <- "RdPu"
        }
        if(length(settings$fontSize) == 0) {
            settings$fontSize <- 12
        }

        ## 1st - Get JOB and his Info from database
        resampleDetails <- db.apps.getFeatureSetData(resampleID)
        ## save(resampleDetails, file = "/tmp/testing.rds")

        resamplePath <- downloadDataset(resampleDetails[[1]]$remotePathMain)     
        data <- data.table::fread(resamplePath, header = T, sep = ',', stringsAsFactors = FALSE, data.table = FALSE)

        ## Remove all other than necessary columns
        data <- data[, names(data) %in% c(variables, resampleDetails[[1]]$outcome$remapped)]
        data[[resampleDetails[[1]]$outcome$remapped]] <- as.factor(data[[resampleDetails[[1]]$outcome$remapped]])

        data <- reshape2::melt(data, id=c(resampleDetails[[1]]$outcome$remapped))

        # Modify the default image size.
        tmp <- tempfile()
        svg(tmp,
            width = 8, height = 8, pointsize = 12,
            onefile = TRUE, family = "Arial", bg = "white",
            antialias = "default")

        theme_set(eval(parse(text=paste0(settings$theme, "()"))))

        g_plot <- ggplot(data, aes_string(x = resampleDetails[[1]]$outcome$remapped, fill = resampleDetails[[1]]$outcome$remapped, y = "value")) +
                        geom_dotplot(binaxis='y', stackdir='center', stackratio=1.5, dotsize=settings$dotsize) + 
                        stat_summary(geom = "crossbar", width=0.65, fatten=0, color="black", fun.data = function(x){ return(c(y=median(x), ymin=median(x), ymax=median(x))) }) +
                        #coord_cartesian(ylim=c(min(data$value), max(data$value) )) + 
                        facet_wrap(~variable, scales="free", labeller = labeller(variable = function(inputValue) {
                            features <- resampleDetails[[1]]$features[resampleDetails[[1]]$features$remapped %in% inputValue, ]
                            return(unique(features$original))
                        })) +
                        scale_fill_brewer(palette=settings$colorPalette) + 
                        theme(text=element_text(size=settings$fontSize), axis.title.x = element_blank(), axis.text.x = element_blank(), axis.ticks.x = element_blank()) + 
                        ylab("Value") + 
                        guides(fill=guide_legend(title=resampleDetails[[1]]$outcome$original))

        print(g_plot)

        dev.off() 
        return (list(image = as.character(RCurl::base64Encode(readBin(tmp, "raw", n = file.info(tmp)$size), "txt"))))
    }
)


