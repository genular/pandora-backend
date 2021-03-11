#* Plot out data from the iris dataset
#* @serializer contentType list(type='image/png')
#' @GET /plots/distribution/render-plot
simon$handle$plots$distribution$renderPlot <- expression(
    function(req, res, ...){
        args <- as.list(match.call())

        response_data <- list(histogram = NULL, histogram_png = NULL, density = NULL, density_png = NULL, boxplot = NULL, boxplot_png = NULL)

        resampleID <- 0
        ## distributionTraining, distributionTesting, distributionResample
        remoteDataset <- "distributionTraining"

        if("resampleID" %in% names(args)){
            resampleID <- as.numeric(args$resampleID)
        }

       if("remoteDataset" %in% names(args)){
            remoteDataset <- args$remoteDataset
        }


        plot_unique_hash <- list(histogram = digest::digest(paste0(resampleID, "_histogram_distribution"), algo="md5", serialize=F), 
            density = digest::digest(paste0(resampleID, "_density_distribution"), algo="md5", serialize=F), 
            boxplot = digest::digest(paste0(resampleID, "_boxplot_distribution"), algo="md5", serialize=F)
            )


        tmp_dir <- tempdir(check = TRUE)
        tmp_check_count <- 0
        for (name in names(plot_unique_hash)) {
            cachedFiles <- list.files(tmp_dir, full.names = TRUE, pattern=paste0(plot_unique_hash[[name]], ".*")) 

            for(cachedFile in cachedFiles){
                cachedFileExtension <- tools::file_ext(cachedFile)

                ## Check if some files where found in tmpdir that match our unique hash
                if(identical(cachedFile, character(0)) == FALSE){
                    if(file.exists(cachedFile) == TRUE){
                        raw_file <- readBin(cachedFile, "raw", n = file.info(cachedFile)$size)
                        encoded_file <- RCurl::base64Encode(raw_file, "txt")

                        if(cachedFileExtension == "svg"){
                            response_data[[name]] = as.character(encoded_file)    
                        }else if(cachedFileExtension == "png"){
                            response_data[[paste0(name, "_png")]] = as.character(encoded_file)
                        }
                        
                        tmp_check_count <- tmp_check_count + 1
                    }
                }
            }
        }
        
        if(tmp_check_count == 6){
            return (list(success = TRUE, message = response_data))
        }

        resampleDetails <- db.apps.getFeatureSetData(resampleID)
        resampleMappings <- db.apps.getDatasetResamplesMappings(resampleID)


        remotePathMain <- resampleDetails[[1]]$remotePathMain
        remotePathTrain <- resampleDetails[[1]]$remotePathTrain
        remotePathTest <-resampleDetails[[1]]$remotePathTest

        remotePath <- remotePathMain
        if(remoteDataset == "distributionTraining"){
            remotePath <- remotePathTrain
        }else if(remoteDataset == "distributionTesting"){
            remotePath <- remotePathTest
        }else if(remoteDataset == "distributionResample"){
            remotePath <- remotePathMain
        }


        datasetPath <- downloadDataset(remotePath)   
        data <- data.table::fread(datasetPath, header = T, sep = ',', stringsAsFactors = FALSE, data.table = FALSE)
        ## Remove all other than necessary selectedColumns
        data <- data[, names(data) %in% c(resampleDetails[[1]]$features$remapped, resampleDetails[[1]]$outcome$remapped)]


        data[[resampleDetails[[1]]$outcome$remapped]] <- plyr::mapvalues(data[[resampleDetails[[1]]$outcome$remapped]], 
                               from=resampleMappings$class_remapped, 
                               to=resampleMappings$class_original)
        
        colnames(data)[which(names(data) == resampleDetails[[1]]$outcome$remapped)] <- resampleDetails[[1]]$outcome$original

        data_plot <- reshape2::melt(data, id.vars=resampleDetails[[1]]$outcome$original)

        data_plot$variable <- plyr::mapvalues(data_plot$variable, 
                               from=resampleDetails[[1]]$features$remapped, 
                               to=resampleDetails[[1]]$features$original)


        ## 1. Histogram and density plots with multiple groups
        ## 1.1 Overlaid histograms
        tmp_path <- tempfile(pattern = plot_unique_hash[["histogram"]], tmpdir = tempdir(), fileext = ".svg")
        tempdir(check = TRUE)
        svg(tmp_path, width = 12, height = 12, pointsize = 12, onefile = TRUE, family = "Arial", bg = "white", antialias = "default")
            plot <- ggplot(data_plot, aes_string(x="value", fill=resampleDetails[[1]]$outcome$original)) +
                      geom_histogram(binwidth=.5, position="dodge") +
                      facet_wrap(~variable, scales="free_y") +
                      guides(fill=guide_legend(title=resampleDetails[[1]]$outcome$original)) + 
                      ylab("Count") + 
                      xlab("Value")

            print(plot)
        dev.off()

        ## Optimize SVG using svgo package
        tmp_path_png <- stringr::str_replace(tmp_path, ".svg", ".png")
        png_cmd <- paste0(which_cmd("rsvg-convert")," ",tmp_path," -f png -o ",tmp_path_png)
        convert_cmd <- paste0(which_cmd("svgo")," ",tmp_path," -o ",tmp_path, " && ", png_cmd)
        system(convert_cmd, intern = TRUE, ignore.stdout = TRUE, ignore.stderr = TRUE, wait = TRUE)

        response_data$histogram <- toString(RCurl::base64Encode(readBin(tmp_path, "raw", n = file.info(tmp_path)$size), "txt"))
        response_data$histogram_png <- toString(RCurl::base64Encode(readBin(tmp_path_png, "raw", n = file.info(tmp_path_png)$size), "txt"))

        ## 1.2 Density plots
        tmp_path <- tempfile(pattern = plot_unique_hash[["density"]], tmpdir = tempdir(), fileext = ".svg")
        tempdir(check = TRUE)
        svg(tmp_path, width = 12, height = 12, pointsize = 12, onefile = TRUE, family = "Arial", bg = "white", antialias = "default")
            plot <- ggplot(data_plot, aes_string(x="value", colour=resampleDetails[[1]]$outcome$original)) + 
                      geom_density() + 
                      facet_wrap(~variable, scales="free_y") +
                      guides(fill=guide_legend(title=resampleDetails[[1]]$outcome$original)) + 
                      ylab("Density") + 
                      xlab("Value")
            print(plot)
        dev.off()

        ## Optimize SVG using svgo package
        tmp_path_png <- stringr::str_replace(tmp_path, ".svg", ".png")

        png_cmd <- paste0(which_cmd("rsvg-convert")," ",tmp_path," -f png -o ",tmp_path_png)
        convert_cmd <- paste0(which_cmd("svgo")," ",tmp_path," -o ",tmp_path, " && ", png_cmd)
        system(convert_cmd, intern = TRUE, ignore.stdout = TRUE, ignore.stderr = TRUE, wait = TRUE)

        response_data$density <- toString(RCurl::base64Encode(readBin(tmp_path, "raw", n = file.info(tmp_path)$size), "txt"))
        response_data$density_png <- toString(RCurl::base64Encode(readBin(tmp_path_png, "raw", n = file.info(tmp_path_png)$size), "txt"))

        ## 1.3 Boxplot
        tmp_path <- tempfile(pattern = plot_unique_hash[["boxplot"]], tmpdir = tempdir(), fileext = ".svg")
        tempdir(check = TRUE)
        svg(tmp_path, width = 12, height = 12, pointsize = 12, onefile = TRUE, family = "Arial", bg = "white", antialias = "default")
            plot <- ggplot(data_plot, aes_string(x=resampleDetails[[1]]$outcome$original, y="value", fill=resampleDetails[[1]]$outcome$original)) + 
                      geom_boxplot() + 
                      facet_wrap(~variable)+
                      theme(axis.text.x=element_blank(),
                            axis.ticks.x=element_blank())
            print(plot)
        dev.off()

        ## Optimize SVG using svgo package
        tmp_path_png <- stringr::str_replace(tmp_path, ".svg", ".png")
        png_cmd <- paste0(which_cmd("rsvg-convert")," ",tmp_path," -f png -o ",tmp_path_png)
        convert_cmd <- paste0(which_cmd("svgo")," ",tmp_path," -o ",tmp_path, " && ", png_cmd)
        system(convert_cmd, intern = TRUE, ignore.stdout = TRUE, ignore.stderr = TRUE, wait = TRUE)

        response_data$boxplot <- toString(RCurl::base64Encode(readBin(tmp_path, "raw", n = file.info(tmp_path)$size), "txt"))
        response_data$boxplot_png <- toString(RCurl::base64Encode(readBin(tmp_path_png, "raw", n = file.info(tmp_path_png)$size), "txt"))

    
        return (list(success = TRUE, message = response_data))
    }
)
