#* Plot out data from the iris dataset
#* @serializer contentType list(type='image/png')
#' @GET /plots/modelsummary/render-plot
simon$handle$plots$modelsummary$renderPlot <- expression(
    function(req, res, ...){
        args <- as.list(match.call())

        data <- list(histogram = NULL, histogram_png = NULL, density = NULL, density_png = NULL, boxplot = NULL, boxplot_png = NULL)


        plotUniqueHash <- ""

        resampleID <- 0
        if("resampleID" %in% names(args)){
            resampleID <- as.numeric(args$resampleID)
            plotUniqueHash <- paste0(plotUniqueHash, resampleID)
        }
        modelsIDs <- NULL
        if("modelsIDs" %in% names(args)){
            modelsIDs <- jsonlite::fromJSON(args$modelsIDs)
            plotUniqueHash <- paste0(plotUniqueHash, args$modelsIDs)
        }

        plotUniqueHash <-  digest::digest(plotUniqueHash, algo="md5", serialize=F)

        ## 1st - Get all saved models for selected IDs
        modelsDetails <- db.apps.getModelsDetailsData(modelsIDs)

        data <- NULL
        outcome_column <- NULL

        for(i in 1:nrow(modelsDetails)) {
            model <- modelsDetails[i,]
            modelPath <- downloadDataset(model$remotePathMain)    
            modelData <- loadRObject(modelPath)

            data <- modelData$info$data
            ## training, testing
            outcome_column <- modelData$info$outcome
        }


        ## 1. Histogram and density plots with multiple groups
        ## 1.1 Overlaid histograms
        tmp_path <- tempfile(pattern = "file", tmpdir = tempdir(), fileext = ".svg")
        tempdir(check = TRUE)
        svg(tmp_path, width = 8, height = 8, pointsize = 12, onefile = TRUE, family = "Arial", bg = "white", antialias = "default")
            plot <- ggplot(dat, aes(x=rating, fill=cond)) +
                        geom_histogram(binwidth=.5, alpha=.5, position="identity")
            print(plot)
        dev.off()

        ## Optimize SVG using svgo package
        tmp_path_png <- stringr::str_replace(tmp_path, ".svg", ".png")
        png_cmd <- paste0(which_cmd("rsvg-convert")," ",tmp_path," -f png -o ",tmp_path_png)
        convert_cmd <- paste0(which_cmd("svgo")," ",tmp_path," -o ",tmp_path, " && ", png_cmd)
        system(convert_cmd, intern = TRUE, ignore.stdout = TRUE, ignore.stderr = TRUE, wait = TRUE)

        data$histogram <- toString(RCurl::base64Encode(readBin(tmp_path, "raw", n = file.info(tmp_path)$size), "txt"))
        data$histogram_png <- toString(RCurl::base64Encode(readBin(tmp_path_png, "raw", n = file.info(tmp_path_png)$size), "txt"))

        ## 1.2 Density plots
        tmp_path <- tempfile(pattern = "file", tmpdir = tempdir(), fileext = ".svg")
        tempdir(check = TRUE)
        svg(tmp_path, width = 8, height = 8, pointsize = 12, onefile = TRUE, family = "Arial", bg = "white", antialias = "default")
            plot <- ggplot(dat, aes(x=rating, colour=cond)) + geom_density()
            print(plot)
        dev.off()

        ## Optimize SVG using svgo package
        tmp_path_png <- stringr::str_replace(tmp_path, ".svg", ".png")
        png_cmd <- paste0(which_cmd("rsvg-convert")," ",tmp_path," -f png -o ",tmp_path_png)
        convert_cmd <- paste0(which_cmd("svgo")," ",tmp_path," -o ",tmp_path, " && ", png_cmd)
        system(convert_cmd, intern = TRUE, ignore.stdout = TRUE, ignore.stderr = TRUE, wait = TRUE)

        data$density <- toString(RCurl::base64Encode(readBin(tmp_path, "raw", n = file.info(tmp_path)$size), "txt"))
        data$density_png <- toString(RCurl::base64Encode(readBin(tmp_path_png, "raw", n = file.info(tmp_path_png)$size), "txt"))

        ## 1.3 Boxplot
        tmp_path <- tempfile(pattern = "file", tmpdir = tempdir(), fileext = ".svg")
        tempdir(check = TRUE)
        svg(tmp_path, width = 8, height = 8, pointsize = 12, onefile = TRUE, family = "Arial", bg = "white", antialias = "default")
            plot <- ggplot(dat, aes(x=cond, y=rating, fill=cond)) + geom_boxplot()
            print(plot)
        dev.off()

        ## Optimize SVG using svgo package
        tmp_path_png <- stringr::str_replace(tmp_path, ".svg", ".png")
        png_cmd <- paste0(which_cmd("rsvg-convert")," ",tmp_path," -f png -o ",tmp_path_png)
        convert_cmd <- paste0(which_cmd("svgo")," ",tmp_path," -o ",tmp_path, " && ", png_cmd)
        system(convert_cmd, intern = TRUE, ignore.stdout = TRUE, ignore.stderr = TRUE, wait = TRUE)

        data$boxplot <- toString(RCurl::base64Encode(readBin(tmp_path, "raw", n = file.info(tmp_path)$size), "txt"))
        data$boxplot_png <- toString(RCurl::base64Encode(readBin(tmp_path_png, "raw", n = file.info(tmp_path_png)$size), "txt"))

    
        return (list(success = TRUE, message = data))
    }
)
