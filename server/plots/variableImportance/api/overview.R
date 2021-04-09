#* Render models overview plot
#* @serializer contentType list(type='image/png')
#' @post /plots/variableImportance/renderOverviewPlot
simon$handle$plots$variableImportance$renderOverviewPlot <- expression(
    function(req, res, ...){
        args <- as.list(match.call())
        results <- list(status = TRUE, data = NULL, image = NULL, image_png = NULL)
        plotUniqueHash <- ""

        resampleID <- 0
        if("resampleID" %in% names(args)){
            resampleID <- as.numeric(args$resampleID)
            plotUniqueHash <- paste0(plotUniqueHash, resampleID)
        }
        variables <- NULL
        if("variables" %in% names(args)){
            variables <- jsonlite::fromJSON(args$variables)
            plotUniqueHash <- paste0(plotUniqueHash, args$variables)
        }
        modelsID <- NULL
        if("modelsID" %in% names(args)){
            modelsID <- jsonlite::fromJSON(args$modelsID)
            plotUniqueHash <- paste0(plotUniqueHash, args$modelsID)
        }
        settings <- NULL
        if("settings" %in% names(args)){
            settings <- jsonlite::fromJSON(args$settings)
            plotUniqueHash <- paste0(plotUniqueHash, args$settings)
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
        if(length(settings$aspect_ratio) == 0) {
            settings$aspect_ratio <- 1
        }

        plotUniqueHash <-  digest::digest(plotUniqueHash, algo="md5", serialize=F)

        tmp_dir <- tempdir(check = TRUE)
        cachedFile <- list.files(tmp_dir, full.names = TRUE, pattern=paste0(plotUniqueHash, ".*\\.svg"))
        if(length(cachedFile) > 1){
            cachedFile <- cachedFile[1]
        }
        ## Check if some files where found in tmpdir that match our unique hash
        if(identical(cachedFile, character(0)) == FALSE){
            if(file.exists(cachedFile) == TRUE){
                raw_file <- readBin(cachedFile, "raw", n = file.info(cachedFile)$size)
                encoded_file <- RCurl::base64Encode(raw_file, "txt")
                results$image = as.character(encoded_file)

                cachedFile_png <- stringr::str_replace(cachedFile, ".svg", ".png")
                if(file.exists(cachedFile_png) == TRUE){
                    results$image_png = as.character(RCurl::base64Encode(readBin(cachedFile_png, "raw", n = file.info(cachedFile_png)$size), "txt"))
                }

                return(list(status = results$status, image = results$image, image_png = results$image_png))
            }
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
        tmp_path <- tempfile(pattern = plotUniqueHash, tmpdir = tempdir(), fileext = ".svg")
        svg(tmp_path, height = 12, width = 12 * settings$aspect_ratio,  pointsize = 24, onefile = TRUE, family = "Arial", bg = "white", antialias = "default")

        theme_set(eval(parse(text=paste0(settings$theme, "()"))))

        results$data <- ggplot(data, aes_string(x = resampleDetails[[1]]$outcome$remapped, fill = resampleDetails[[1]]$outcome$remapped, y = "value")) +
                        ## https://ggplot2.tidyverse.org/reference/geom_dotplot.html
                        geom_dotplot(binaxis='y', stackdir='center', stackratio=1.5, dotsize=settings$dotsize, colour=NA, na.rm = TRUE) + 
                        stat_summary(geom = "crossbar", width=0.65, fatten=0, color="black", fun.data = function(x){ return(c(y=median(x), ymin=median(x), ymax=median(x))) }) +
                        #coord_cartesian(ylim=c(min(data$value), max(data$value) )) + 
                        facet_wrap(~variable, scales="free_y", labeller = labeller(variable = function(inputValue) {
                            features <- resampleDetails[[1]]$features[resampleDetails[[1]]$features$remapped %in% inputValue, ]
                            return(unique(features$original))
                        })) +
                        scale_fill_brewer(palette=settings$colorPalette) + 
                        theme(text=element_text(size=settings$fontSize), axis.title.x = element_blank(), axis.text.x = element_blank(), axis.ticks.x = element_blank()) + 
                        ylab("Value") + 
                        guides(fill=guide_legend(title=resampleDetails[[1]]$outcome$original))

        print(results$data)
        dev.off()

        ## Optimize SVG using svgo package
        tmp_path_png <- stringr::str_replace(tmp_path, ".svg", ".png")
        png_cmd <- paste0(which_cmd("rsvg-convert")," ",tmp_path," -f png -o ",tmp_path_png)
        convert_cmd <- paste0(which_cmd("svgo")," ",tmp_path," -o ",tmp_path, " && ", png_cmd)
        system(convert_cmd, intern = TRUE, ignore.stdout = TRUE, ignore.stderr = TRUE, wait = TRUE)

        svg_data <- readBin(tmp_path, "raw", n = file.info(tmp_path)$size)
        results$image = as.character(RCurl::base64Encode(svg_data, "txt"))
        results$image_png =  as.character(RCurl::base64Encode(readBin(tmp_path_png, "raw", n = file.info(tmp_path_png)$size), "txt"))

        return(list(status = results$status, image = results$image, image_png = results$image_png))
    }
)


