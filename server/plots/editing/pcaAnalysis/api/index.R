#* Plot out data from the selected dataset
#* @serializer contentType list(type='image/png')
#' @post /plots/editing/pcaAnalysis/renderPlot
simon$handle$plots$editing$pcaAnalysis$renderPlot <- expression(
    function(req, res, ...){
        args <- as.list(match.call())

        res.data <- list(
            plot_scree = NULL, plot_scree_png = NULL,
            plot_var_cos2_correlation = NULL, plot_var_cos2_correlation_png = NULL,
            plot_var_cos2_correlation_cluster = NULL, plot_var_cos2_correlation_cluster_png = NULL,
            plot_var_cos2_corrplot = NULL, plot_var_cos2_corrplot_png = NULL,
            plot_var_bar_plot = NULL, plot_var_bar_plot_png = NULL,
            
            plot_var_contrib_correlation = NULL, plot_var_contrib_correlation_png = NULL,
            plot_var_contrib_corrplot = NULL, plot_var_contrib_corrplot_png = NULL,
            plot_var_contrib_bar_plot = NULL, plot_var_contrib_bar_plot_png = NULL,
            
            plot_ind_cos2_correlation = NULL, plot_ind_cos2_correlation_png = NULL,

            plot_ind_cos2_correlation_grouped = NULL,
            plot_ind_cos2_correlation_grouped_biplot = NULL,

            plot_ind_cos2_corrplot = NULL, plot_ind_cos2_corrplot_png = NULL,
            plot_ind_bar_plot = NULL, plot_ind_bar_plot_png = NULL,
            
            plot_ind_contrib_correlation = NULL, plot_ind_contrib_correlation_png = NULL,
            plot_ind_contrib_corrplot = NULL, plot_ind_contrib_corrplot_png = NULL,
            plot_ind_contrib_bar_plot = NULL, plot_ind_contrib_bar_plot_png = NULL
        )

        res.info <- list(
            bartlett = NULL,
            kmo = NULL,
            pca = NULL,
            eig = NULL,
            desc_dim_1 = NULL,
            desc_dim_2 = NULL,
            var = list(
                coord = NULL,
                cos2 =  NULL,
                contrib = NULL
            ),
            ind = list(
                coord = NULL,
                cos2 =  NULL,
                contrib = NULL
            )
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

        if(is_var_empty(settings$groupingVariables) == TRUE){
            settings$groupingVariables = NULL
        }

        if(is_var_empty(settings$pcaComponentsDisplayX) == TRUE){
            settings$pcaComponentsDisplayX = "PC1"
        }
        
        if(is_var_empty(settings$pcaComponentsDisplayY) == TRUE){
            settings$pcaComponentsDisplayY = "PC2"
        }

        if(is_var_empty(settings$preProcessDataset) == TRUE){
            settings$preProcessDataset = TRUE
        }

        if(is_var_empty(settings$removeNA) == TRUE){
            settings$removeNA = TRUE
        }

        if(is_var_empty(settings$displayLoadings) == TRUE){
            settings$displayLoadings = TRUE
        }
        
        if(is_var_empty(settings$fontSize) == TRUE){
            settings$fontSize <- 12
        }

        if(is_var_empty(settings$pointSize) == TRUE){
            settings$pointSize <- 1.5
        }

        if(is_var_empty(settings$theme) == TRUE){
            settings$theme <- "theme_gray"
        }

        if(is_var_empty(settings$colorPalette) == TRUE){
            settings$colorPalette <- "RdPu"
        }

        if(is_var_empty(settings$aspect_ratio) == TRUE){
            settings$aspect_ratio <- 1
        }

        if(is_var_empty(settings$plot_size) == TRUE){
            settings$plot_size <- 12
        }



        plot_unique_hash <- list(
            plot_scree = digest::digest(paste0(selectedFileID, "_",args$settings,"plot_scree"), algo="md5", serialize=F),
            plot_var_cos2_correlation = digest::digest(paste0(selectedFileID, "_",args$settings,"plot_var_cos2_correlation"), algo="md5", serialize=F),
            plot_var_cos2_correlation_cluster = digest::digest(paste0(selectedFileID, "_",args$settings,"plot_var_cos2_correlation_cluster"), algo="md5", serialize=F),
            plot_var_cos2_corrplot = digest::digest(paste0(selectedFileID, "_",args$settings,"plot_var_cos2_corrplot"), algo="md5", serialize=F),
            plot_var_bar_plot = digest::digest(paste0(selectedFileID, "_",args$settings,"plot_var_bar_plot"), algo="md5", serialize=F),
            plot_var_contrib_correlation = digest::digest(paste0(selectedFileID, "_",args$settings,"plot_var_contrib_correlation"), algo="md5", serialize=F),
            plot_var_contrib_corrplot = digest::digest(paste0(selectedFileID, "_",args$settings,"plot_var_contrib_corrplot"), algo="md5", serialize=F),
            plot_var_contrib_bar_plot = digest::digest(paste0(selectedFileID, "_",args$settings,"plot_var_contrib_bar_plot"), algo="md5", serialize=F),
            plot_ind_cos2_correlation = digest::digest(paste0(selectedFileID, "_",args$settings,"plot_ind_cos2_correlation"), algo="md5", serialize=F),

            plot_ind_cos2_correlation_grouped = list(),
            plot_ind_cos2_correlation_grouped_biplot =  list(),

            plot_ind_cos2_corrplot = digest::digest(paste0(selectedFileID, "_",args$settings,"plot_ind_cos2_corrplot"), algo="md5", serialize=F),
            plot_ind_bar_plot = digest::digest(paste0(selectedFileID, "_",args$settings,"plot_ind_bar_plot"), algo="md5", serialize=F),
            plot_ind_contrib_correlation = digest::digest(paste0(selectedFileID, "_",args$settings,"plot_ind_contrib_correlation"), algo="md5", serialize=F),
            plot_ind_contrib_corrplot = digest::digest(paste0(selectedFileID, "_",args$settings,"plot_ind_contrib_corrplot"), algo="md5", serialize=F),
            plot_ind_contrib_bar_plot = digest::digest(paste0(selectedFileID, "_",args$settings,"plot_ind_contrib_bar_plot"), algo="md5", serialize=F),

            saveObjectHash = digest::digest(paste0(selectedFileID, "_",args$settings,"_plot_pca_all"), algo="md5", serialize=F)
        )

        if(!is.null(settings$groupingVariables)){
            res.data$plot_ind_cos2_correlation_grouped = list()
            res.data$plot_ind_cos2_correlation_grouped_biplot = list()

            for(groupVariable in settings$groupingVariables){
                res.data$plot_ind_cos2_correlation_grouped[[groupVariable]] <- list(name = NULL, svg = NULL, png = NULL)
                res.data$plot_ind_cos2_correlation_grouped_biplot[[groupVariable]] <- list(name = NULL, svg = NULL, png = NULL)

                plot_unique_hash$plot_ind_cos2_correlation_grouped[[groupVariable]] <- digest::digest(paste0(selectedFileID, "_",args$settings,"plot_ind_cos2_correlation_grouped_",groupVariable), algo="md5", serialize=F)
                plot_unique_hash$plot_ind_cos2_correlation_grouped_biplot[[groupVariable]] <- digest::digest(paste0(selectedFileID, "_",args$settings,"plot_ind_cos2_correlation_grouped_biplot_",groupVariable), algo="md5", serialize=F)
            }
        }

        #resp_check <- getPreviouslySavedResponse(plot_unique_hash, res.data, 5)
        #if(is.list(resp_check)){
            #print("==> Serving request response from cache")
            #return(resp_check)
        #}

        ## 1st - Get JOB and his Info from database
        selectedFileDetails <- db.apps.getFileDetails(selectedFileID)
        selectedFilePath <- downloadDataset(selectedFileDetails[1,]$file_path)

        fileHeader <- jsonlite::fromJSON(selectedFileDetails[1,]$details)
        fileHeader <- plyr::ldply (fileHeader$header$formatted, data.frame)
        fileHeader <- subset (fileHeader, select = -c(.id))

        fileHeader <- fileHeader %>% mutate(unique_count = as.numeric(unique_count)) %>% mutate(position = as.numeric(position))
        fileHeader$remapped = as.character(fileHeader$remapped)
        fileHeader$original = as.character(fileHeader$original)

        if(!is.null(settings$groupingVariables)){
            settings$groupingVariables <- fileHeader %>% filter(remapped %in% settings$groupingVariables)
            settings$groupingVariables <- settings$groupingVariables$remapped
        }

        if(is.null(settings$selectedColumns)){
            selectedColumns <- fileHeader %>% arrange(unique_count) %>% slice(5) %>% arrange(position) %>% select(remapped)
            settings$selectedColumns <- tail(selectedColumns$remapped, 5)
        }else{
            settings$selectedColumns <- fileHeader %>% filter(remapped %in% settings$selectedColumns)
            settings$selectedColumns <- settings$selectedColumns$remapped
        }

        ## Remove grouping variable from selected columns
        settings$selectedColumns <-  setdiff(settings$selectedColumns, settings$groupingVariables)

        dataset <- data.table::fread(selectedFilePath, header = T, sep = ',', stringsAsFactors = FALSE, data.table = FALSE)
        ## Drop all columns expect selected and grouping ones
        dataset_filtered <- dataset[, names(dataset) %in% c(settings$selectedColumns, settings$groupingVariables)]

        ## Check if grouping variable is numeric and add prefix to it
        num_test <- dataset_filtered %>% select(where(is.numeric))
        for (groupVariable in settings$groupingVariables) {
            if(groupVariable %in% names(num_test)){
                dataset_filtered[[groupVariable]] <- paste("g",dataset_filtered[[groupVariable]],sep="_")
            }
        }

        if(!is.null(settings$preProcessDataset)){
            ## Preprocess data except grouping variables
            preProcessedData <- preProcessData(dataset_filtered, settings$groupingVariables , settings$groupingVariables , methods = c("medianImpute", "center", "scale"))
            dataset_filtered <- preProcessedData$processedMat
            preProcessedData <- preProcessData(dataset_filtered, settings$groupingVariables , settings$groupingVariables ,  methods = c("nzv", "zv"))
            dataset_filtered <- preProcessedData$processedMat
        }else{
            dataset_filtered <- dataset
        }

        if(settings$removeNA == TRUE){
            dataset_filtered <- na.omit(dataset_filtered)
        }

        input_data <- dataset_filtered
        if(!is.null(settings$groupingVariables)){
            input_data <- input_data[ , -which(names(input_data) %in% settings$groupingVariables)]
        }

        names(dataset_filtered) <- plyr::mapvalues(names(dataset_filtered), from=fileHeader$remapped, to=fileHeader$original)
        names(input_data) <- plyr::mapvalues(names(input_data), from=fileHeader$remapped, to=fileHeader$original)

        input_data_num <- input_data[,sapply(input_data, is.numeric)]

        res.pca <- PCA(input_data, scale.unit = FALSE, ncp = 5, graph = FALSE)

        res.info$pca <- convertToString(summary(res.pca))
        res.info$kmo <- convertToString(kmo_test(input_data_num))
        res.info$bartlett <- convertToString(psych::cortest.bartlett(cor(input_data_num), n = nrow(input_data_num)))

        # Eigenvalues / Variances
        eig.val <- get_eigenvalue(res.pca)
        res.info$eig <- convertToString(eig.val)

        # Dimension description
        res.desc <- dimdesc(res.pca, axes = c(1,2), proba = 0.05)
        # Description of dimension
        res.info$desc_dim_1 <- convertToString(round_df(res.desc$Dim.1$quanti, 4))
        res.info$desc_dim_2 <- convertToString(round_df(res.desc$Dim.2$quanti, 4))

        # Visualize the eigenvalues
        tmp_path <- plots_fviz_eig(res.pca, settings, plot_unique_hash[["plot_scree"]])
        res.data$plot_scree = optimizeSVGFile(tmp_path)
        res.data$plot_scree_png = convertSVGtoPNG(tmp_path)

        ############# Graph of variables
        var <- get_pca_var(res.pca)
        ## Coordinates
        res.info$var$coord <- var$coord
        ## Cos2: quality on the factore map
        res.info$var$cos2 <- var$cos2
        ## Contributions to the principal components
        res.info$var$contrib <- var$contrib

        # Visualize the results individuals and variables, respectively.
        tmp_path <- plots_fviz_pca(res.pca, "cos2", "var", settings, plot_unique_hash[["plot_var_cos2_correlation"]], dataset_filtered, fileHeader)
        res.data$plot_var_cos2_correlation = optimizeSVGFile(tmp_path)
        res.data$plot_var_cos2_correlation_png = convertSVGtoPNG(tmp_path)

        # Classify the variables into 3 groups using the kmeans clustering algorithm. 
        set.seed(123)
        res.km <- kmeans(var$coord, centers = 3, nstart = 256)
        grp <- as.factor(res.km$cluster)

        tmp_path <- plots_fviz_pca(res.pca, grp, "var", settings, plot_unique_hash[["plot_var_cos2_correlation_cluster"]], dataset_filtered, fileHeader, TRUE)
        res.data$plot_var_cos2_correlation_cluster = optimizeSVGFile(tmp_path)
        res.data$plot_var_cos2_correlation_cluster_png = convertSVGtoPNG(tmp_path)



        # Visualize the cos2 of variables on all the dimensions using the corrplot package
        tmp_path <- plots_corrplot(var$cos2, settings, plot_unique_hash[["plot_var_cos2_corrplot"]])
        res.data$plot_var_cos2_corrplot = optimizeSVGFile(tmp_path)
        res.data$plot_var_cos2_corrplot_png = convertSVGtoPNG(tmp_path)
        #  bar plot of variables cos2 
        tmp_path <- plots_fviz_cos2(res.pca, "var", settings, plot_unique_hash[["plot_var_bar_plot"]])
        res.data$plot_var_bar_plot = optimizeSVGFile(tmp_path)
        res.data$plot_var_bar_plot_png = convertSVGtoPNG(tmp_path)


        # The most important (or, contributing) variables highlighted on the correlation plot
        tmp_path <- plots_fviz_pca(res.pca, "contrib", "var", settings, plot_unique_hash[["plot_var_contrib_correlation"]], dataset_filtered, fileHeader)
        res.data$plot_var_contrib_correlation = optimizeSVGFile(tmp_path)
        res.data$plot_var_contrib_correlation_png = convertSVGtoPNG(tmp_path)
        # Highlight the most contributing variables for each dimension:
        tmp_path <- plots_corrplot(var$contrib, settings, plot_unique_hash[["plot_var_contrib_corrplot"]])
        res.data$plot_var_contrib_corrplot = optimizeSVGFile(tmp_path)
        res.data$plot_var_contrib_corrplot_png = convertSVGtoPNG(tmp_path)
        # Draw a bar plot of variable contributions
        tmp_path <- plots_fviz_contrib(res.pca, "var", 1:2, 10, settings, plot_unique_hash[["plot_var_contrib_bar_plot"]])
        res.data$plot_var_contrib_bar_plot = optimizeSVGFile(tmp_path)
        res.data$plot_var_contrib_bar_plot_png = convertSVGtoPNG(tmp_path)


        ############# Graph of individuals
        ind <- get_pca_ind(res.pca)
        ## Coordinates
        res.info$ind$coord <- ind$coord
        ## Cos2: quality on the factore map
        res.info$ind$cos2 <- ind$cos2
        ## Contributions to the principal components
        res.info$ind$contrib <- ind$contrib

        # Correlation circle
        tmp_path <- plots_fviz_pca(res.pca, "cos2", "ind", settings, plot_unique_hash[["plot_ind_cos2_correlation"]], dataset_filtered, fileHeader)
        res.data$plot_ind_cos2_correlation = optimizeSVGFile(tmp_path)
        res.data$plot_ind_cos2_correlation_png = convertSVGtoPNG(tmp_path)

        if(!is.null(settings$groupingVariables)){

            for(groupVariable in settings$groupingVariables){
                # groupVariable is remaped value
                groupingVariable <- fileHeader %>% filter(remapped %in% groupVariable)
                groupingVariable <- groupingVariable$original

                tmp_path <- plots_fviz_pca_ind_grouped(res.pca, dataset_filtered, settings, groupingVariable, fileHeader, plot_unique_hash$plot_ind_cos2_correlation_grouped[[groupVariable]])
                res.data$plot_ind_cos2_correlation_grouped[[groupVariable]]$name <- groupingVariable
                res.data$plot_ind_cos2_correlation_grouped[[groupVariable]]$svg <- optimizeSVGFile(tmp_path)
                res.data$plot_ind_cos2_correlation_grouped[[groupVariable]]$png <- convertSVGtoPNG(tmp_path)


                tmp_path <- plots_fviz_pca_biplot_grouped(res.pca, dataset_filtered, settings, groupingVariable, fileHeader, plot_unique_hash$plot_ind_cos2_correlation_grouped_biplot[[groupVariable]])
                res.data$plot_ind_cos2_correlation_grouped_biplot[[groupVariable]]$name <- groupingVariable
                res.data$plot_ind_cos2_correlation_grouped_biplot[[groupVariable]]$svg <- optimizeSVGFile(tmp_path)
                res.data$plot_ind_cos2_correlation_grouped_biplot[[groupVariable]]$png <- convertSVGtoPNG(tmp_path)
            }
        }


        # Quality of representation
        tmp_path <- plots_corrplot(ind$cos2, settings, plot_unique_hash[["plot_ind_cos2_corrplot"]])
        res.data$plot_ind_cos2_corrplot = optimizeSVGFile(tmp_path)
        res.data$plot_ind_cos2_corrplot_png = convertSVGtoPNG(tmp_path)
        #  bar plot of variables cos2 
        tmp_path <- plots_fviz_cos2(res.pca, "ind", settings, plot_unique_hash[["plot_ind_bar_plot"]])
        res.data$plot_ind_bar_plot = optimizeSVGFile(tmp_path)
        res.data$plot_ind_bar_plot_png = convertSVGtoPNG(tmp_path)

        # The most important (or, contributing) variables highlighted on the correlation plot
        tmp_path <- plots_fviz_pca(res.pca, "contrib", "ind", settings, plot_unique_hash[["plot_ind_contrib_correlation"]], dataset_filtered, fileHeader)
        res.data$plot_ind_contrib_correlation = optimizeSVGFile(tmp_path)
        res.data$plot_ind_contrib_correlation_png = convertSVGtoPNG(tmp_path)
        # Contributions of individuals to PCs
        tmp_path <- plots_corrplot(ind$contrib, settings, plot_unique_hash[["plot_ind_contrib_corrplot"]])
        res.data$plot_ind_contrib_corrplot = optimizeSVGFile(tmp_path)
        res.data$plot_ind_contrib_corrplot_png = convertSVGtoPNG(tmp_path)
        # Contributions of individuals to PC1 and PC2
        tmp_path <- plots_fviz_contrib(res.pca, "ind", 1:2, 10, settings, plot_unique_hash[["plot_ind_contrib_bar_plot"]])
        res.data$plot_ind_contrib_bar_plot = optimizeSVGFile(tmp_path)
        res.data$plot_ind_contrib_bar_plot_png = convertSVGtoPNG(tmp_path)


        tmp_path <- tempfile(pattern = plot_unique_hash[["saveObjectHash"]], tmpdir = tempdir(), fileext = ".Rdata")
        processingData <- list(
            res.info = res.info, 
            res.pca = res.pca, 
            input_data = input_data, 
            settings = settings, 
            dataset_filtered = dataset_filtered, 
            fileHeader = fileHeader,
            res.km = res.km,
            res.data = res.data
        )
        saveCachedList(tmp_path, processingData)
        res.data$saveObjectHash = substr(basename(tmp_path), 1, nchar(basename(tmp_path))-6)

        return (list(success = TRUE, message = res.data, details = res.info))
    }
)
