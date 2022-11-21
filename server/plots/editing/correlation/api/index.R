#' @get /plots/correlation/renderOptions
simon$handle$plots$editing$correlation$renderOptions <- expression(
    function(){
        data <- list()

        data$correlation_method <- eval(formals(cor)$method)
        data$na_action <- c(
                            "everything",
                            "all.obs",
                            "complete.obs",
                            "na.or.complete",
                            "pairwise.complete.obs"
                        )
        ## Only if confidence interval is not selected
        data$plot_method <- c("mixed", eval(formals(corrplot)$method))
        data$plot_method_mixed = list()
        data$plot_method_mixed$lower_method <- eval(formals(corrplot)$method)
        data$plot_method_mixed$upper_method <- eval(formals(corrplot)$method)

        data$plot_type <- eval(formals(corrplot)$type)
        data$reorder_correlation <- eval(formals(corrplot)$order)
        data$reorder_correlation_hclust = list()
        data$reorder_correlation_hclust$method <- eval(formals(corrplot)$hclust.method)
        data$reorder_correlation_hclust$number_of_rectangles <- 3

        data$text_size <- list(value = 0.4, min = 0.2, max = 3, step = 0.2)

        data$significance = list()
        data$significance$level <- list(value = 0.05, min = 0, max = 1, step = 0.05)
        data$significance$insignificant_action <- eval(formals(corrplot)$insig)

        data$confidence = list()
        data$confidence$ploting_method <- eval(formals(corrplot)$plotCI)[-1]
        data$confidence$level <- list(value = 0.95, min = 0, max = 1, step = 0.05)

        return(list(
            status = "success",
            data = data
        ))
    }
)

#* Plot out data from the iris dataset
#* @serializer contentType list(type='image/png')
#' @post /plots/correlation/renderPlot
simon$handle$plots$editing$correlation$renderPlot <- expression(
    function(req, res, ...){
        args <- as.list(match.call())

        response_data <- list(
            correlation_plot = NULL, correlation_plot_png = NULL, 
            saveObjectHash = NULL
        )


        selectedFileID <- 0
        if("selectedFileID" %in% names(args)){
            selectedFileID <- as.numeric(args$selectedFileID)
        }

        settings <- NULL
        if("settings" %in% names(args)){
            settings <- jsonlite::fromJSON(args$settings)
        }

        if(is_var_empty(settings$selectedColumns) == TRUE){
            settings$selectedColumns = NULL
        }

        if(is_var_empty(settings$cutOffColumnSize) == TRUE){
            settings$cutOffColumnSize = 100
        }

        plot_unique_hash <- list(
            correlation_plot = digest::digest(paste0(selectedFileID, "_",args$settings,"_editing_correlation_plot"), algo="md5", serialize=F), 
            saveObjectHash = digest::digest(paste0(selectedFileID, "_",args$settings,"_editing_correlation_render_plot"), algo="md5", serialize=F)
        )
        
        resp_check <- getPreviouslySavedResponse(plot_unique_hash, response_data, 3)
        if(is.list(resp_check)){
            print("==> Serving request response from cache")
            # return(resp_check)
        }

        ## 1st - Get JOB and his Info from database
        selectedFileDetails <- db.apps.getFileDetails(selectedFileID)
        selectedFilePath <- downloadDataset(selectedFileDetails[1,]$file_path)


        fileHeader <- jsonlite::fromJSON(selectedFileDetails[1,]$details)
        fileHeader <- plyr::ldply (fileHeader$header$formatted, data.frame)
        fileHeader <- subset (fileHeader, select = -c(.id))

        fileHeader <- fileHeader %>% mutate(unique_count = as.numeric(unique_count)) %>% mutate(position = as.numeric(position))
        fileHeader$remapped = as.character(fileHeader$remapped)
        fileHeader$original = as.character(fileHeader$original)

        dataset <- loadDataFromFileSystem(selectedFilePath)

        if(is_null(settings$selectedColumns)) {
            selectedColumns <- fileHeader %>% arrange(unique_count) %>% arrange(position) %>% select(remapped)
            settings$selectedColumns <- tail(selectedColumns$remapped, n=settings$cutOffColumnSize)
        }

        ## Remove all columns expect selected features
        dataset <- dataset %>% select(all_of(settings$selectedColumns)) 

        remapping_header <- fileHeader %>%
                            filter(remapped %in% settings$selectedColumns) %>%
                            select(remapped, original)

        ## Rename remapped columns to original ones
        dataset <- dataset %>% rename_(.dots=with(remapping_header, setNames(as.list(as.character(remapped)), original)))

        ## Drop all non numeric columns
        numeric_columns <- names(select_if(dataset, is.numeric))
        dropped_columns <- setdiff(settings$selectedColumns, numeric_columns)

        dataset_filtered <- dataset %>% select(all_of(numeric_columns))


        ### DEFINE ALL RETURN VARIABLES 
        data <- NULL
        p.mat <- NULL
        input_args <- NULL
        corrplot_out <- NULL


        if(ncol(dataset_filtered) <= 1){
            error_check <- TRUE
            # Not enough numerical columns found in database.
        }else{
            error_check <- FALSE
        }

        if(error_check == FALSE){

            #save(dataset_filtered, file = "/tmp/dataset_filtered")
            data <- cor(dataset_filtered, use = settings$na_action, method = settings$correlation_method)

            #save(data, file = "/tmp/data")

            if(settings$significance$enable == TRUE){
                print("==> Info: significance enable corTest")
                p.mat <- corTest(data, settings$confidence$level$value)

                if(settings$significance$adjust_p_value == TRUE){
                    print("==> Info: Adjusting p-values")
                    pAdj <- p.adjust(p.mat[[1]], method = "BH")
                    p.mat[[1]] <- matrix(pAdj, ncol = dim(p.mat[[1]])[1])
                }
            }

            args <- list(data,
                            number.cex= 7/ncol(dataset_filtered),
                            tl.cex=settings$text_size$value,
                            cl.cex=settings$text_size$value,
                            mar=c(0,0,1,0),
                            order = if(settings$reorder_correlation == "manual") "original" else settings$reorder_correlation, 
                            hclust.method = settings$reorder_correlation_hclust$method, 
                            addrect = settings$reorder_correlation_hclust$number_of_rectangles,
                            is.corr=TRUE,

                            sig.level = if(settings$significance$enable == TRUE) settings$significance$level$value else NULL,
                            insig = if(settings$significance$enable == TRUE) settings$significance$insignificant_action else NULL,

                            p.mat = if(settings$significance$enable == TRUE) p.mat[[1]] else NULL,
                            lowCI.mat = if(settings$significance$enable == TRUE) p.mat[[2]] else NULL,
                            uppCI.mat = if(settings$significance$enable == TRUE) p.mat[[3]] else NULL,

                            plotCI = if(settings$confidence$enable == TRUE) settings$confidence$ploting_method else "n",
                            tl.col = "black",
                            addgrid.col="transparent",
                            col=grDevices::colorRampPalette(c("blue","white","red"))(200)
                        )



            if(settings$confidence$enable == TRUE) {
                input_args <- c(list(type = settings$plot_type), args)
            } else if(settings$plot_method == "mixed") {
                input_args <- c(list(lower = settings$plot_method_mixed$lower_method,
                                             upper = settings$plot_method_mixed$upper_method),
                                        args)
            } else {
                input_args <- c(list(method = settings$plot_method, type = settings$plot_type), args)
            }

            tmp_path <- tempfile(pattern = plot_unique_hash[["correlation_plot"]], tmpdir = tempdir(), fileext = ".svg")
            svg(tmp_path, width = 12, height = 12, pointsize = 12, onefile = TRUE, family = "Arial", bg = "white", antialias = "default")

            corrplot_out <- FALSE
            process.execution <- tryCatch( garbage <- R.utils::captureOutput(corrplot_out <- R.utils::withTimeout(do.call(corrplot, input_args), timeout=300, onTimeout = "error") ), error = function(e){ return(e) } )
                print(corrplot_out)
            dev.off()

            response_data$correlation_plot = optimizeSVGFile(tmp_path)
            response_data$correlation_plot_png =  convertSVGtoPNG(tmp_path)
        }

        ## save data for latter use
        tmp_path <- tempfile(pattern = plot_unique_hash[["saveObjectHash"]], tmpdir = tempdir(), fileext = ".Rdata")

        processingData = list(
            data = data,
            p.mat = p.mat,
            input_args = input_args,
            corrplot = corrplot_out,
            settings = settings,
            dataset = dataset,
            dataset_filtered_processed = dataset_filtered
        )
        saveCachedList(tmp_path, processingData)

        response_data$saveObjectHash = substr(basename(tmp_path), 1, nchar(basename(tmp_path))-6)

        return (list(success = TRUE, message = response_data))
    }
)
