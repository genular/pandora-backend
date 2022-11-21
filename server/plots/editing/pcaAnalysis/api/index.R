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

        if(is_var_empty(settings$cutOffColumnSize) == TRUE){
            settings$cutOffColumnSize = 50000
        }

        if(is_var_empty(settings$excludedColumns) == TRUE){
            settings$excludedColumns = NULL
        }

        if(is_var_empty(settings$cutOffUnique) == TRUE){
            settings$cutOffUnique = TRUE
        }

        if(is_var_empty(settings$cutOffUniqueSize) == TRUE){
            settings$cutOffUniqueSize = 5
        }

        if(is_var_empty(settings$remove_less_10p) == TRUE){
            settings$remove_less_10p = FALSE
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
            settings$pointSize <- 2
        }

        if(is_var_empty(settings$labelSize) == TRUE){
            settings$labelSize <- 4
        }

        if(is_var_empty(settings$ellipseAlpha) == TRUE){
            settings$ellipseAlpha <- 0.05
        }

        if(is_var_empty(settings$addEllipses) == TRUE){
            settings$addEllipses <- TRUE
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

        if(is_var_empty(settings$kmo_bartlett_limit) == TRUE){
            settings$kmo_bartlett_limit <- 1500
        }

        ## Method: PCA or MCA
        ## http://factominer.free.fr/factomethods/
        if(is_var_empty(settings$method) == TRUE){
            settings$method <- "MCA"
        }

        if(is_var_empty(settings$anyNAValues) == TRUE){
            settings$anyNAValues <- FALSE
        }

        if(is_var_empty(settings$categoricalVariables) == TRUE){
            settings$categoricalVariables <- FALSE
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

        if(is_null(settings$selectedColumns)) {
            selectedColumns <- fileHeader %>% arrange(unique_count) %>% arrange(position)
            if(settings$cutOffUnique == TRUE) {
                selectedColumns <- selectedColumns %>% filter(unique_count >= settings$cutOffUniqueSize)
            }
            settings$selectedColumns  <- selectedColumns %>% select(remapped)
            settings$selectedColumns <- tail(selectedColumns$remapped, n=settings$cutOffColumnSize)
        }

        # Remove grouping variables from selectedColumns and excludedColumns
        if(!is_null(settings$groupingVariables)) {
            if(is_null(settings$selectedColumns)) {
                settings$selectedColumns <-  setdiff(settings$selectedColumns, settings$groupingVariables)
            }
            if(is_null(settings$excludedColumns)) {
                settings$excludedColumns <-  setdiff(settings$excludedColumns, settings$groupingVariables)
            }
            if(is_null(settings$colorVariables)) {
                settings$colorVariables <-  setdiff(settings$colorVariables, settings$groupingVariables)
            }
        }

        # Remove any excluded columns from selected columns
        if(!is_null(settings$excludedColumns)) {
            ## Remove excluded from selected columns
            settings$selectedColumns <-  setdiff(settings$selectedColumns, settings$excludedColumns)
            # settings$selectedColumns <- settings$selectedColumns[settings$selectedColumns %!in% settings$excludedColumns]
        }
        print(paste("==> Selected Columns 1: ", length(settings$selectedColumns)))
        print(paste("==> Grouping Columns 1: ", length(settings$groupingVariables)))


        ## Remove grouping variable from selected columns
        settings$selectedColumns <-  setdiff(settings$selectedColumns, settings$groupingVariables)
        print(paste("==> Selected Columns 2: ", length(settings$selectedColumns)))

        dataset <- loadDataFromFileSystem(selectedFilePath)
        ## Drop all columns expect selected and grouping ones
        dataset_filtered <- dataset[, names(dataset) %in% c(settings$selectedColumns, settings$groupingVariables)]

        info_msg <- paste0("=====> Total selected columns + grouping variables before filtering: ",ncol(dataset_filtered))
        print(info_msg)

        ## TODO: add this information to fileHeader and make check when selectingColumns
        if(settings$remove_less_10p == TRUE) {
            col_check <- sapply(seq(1, ncol(dataset_filtered)), function(i) length(unique(dataset_filtered[,i])) < nrow(dataset_filtered)/10 )
            valid_10p <- names(dataset_filtered[, col_check, drop = FALSE])

            settings$selectedColumns <-  setdiff(settings$selectedColumns, valid_10p)
        }

        if(length(settings$selectedColumns) <= 2) {
            print("==> No enough columns to proceed with PCA analysis")
            return (list(success = FALSE, message = FALSE, details = FALSE))
        }else{
            print(paste("==> Selected Columns 3: ", length(settings$selectedColumns), " Dataset columns:",ncol(dataset_filtered)))
        }

        ## Check if grouping variable is numeric and add prefix to it
        num_test <- dataset_filtered %>% select(where(is.numeric))
        for (groupVariable in settings$groupingVariables) {
            if(groupVariable %in% names(num_test)){
                dataset_filtered[[groupVariable]] <- paste("g",dataset_filtered[[groupVariable]],sep="_")
            }
        }

        print(paste("==> Selected Columns 4: ", length(settings$selectedColumns), " Dataset columns:",ncol(dataset_filtered)))

        if(!is.null(settings$preProcessDataset) && settings$preProcessDataset == TRUE) {
            ## Preprocess data except grouping variables
            preprocess_methods <- c("medianImpute", "center", "scale")
            if(settings$categoricalVariables == TRUE || settings$method == "MCA"){
                preprocess_methods <- c("medianImpute")
            }
            print(paste0("=====> Preprocessing dataset", paste(preprocess_methods, collapse = ", ")))

            preProcessedData <- preProcessData(dataset_filtered, settings$groupingVariables , settings$groupingVariables , methods = preprocess_methods)
            dataset_filtered <- preProcessedData$processedMat

            print(paste("==> Selected Columns 4.1: ", length(settings$selectedColumns), " Dataset columns: ",ncol(dataset_filtered), " Dataset rows: ", nrow(dataset_filtered)))

            preProcessedData <- preProcessData(dataset_filtered, settings$groupingVariables , settings$groupingVariables ,  methods = c("nzv", "zv"))
            dataset_filtered <- preProcessedData$processedMat
            print(paste("==> Selected Columns 4.2: ", length(settings$selectedColumns), " Dataset columns: ",ncol(dataset_filtered), " Dataset rows: ", nrow(dataset_filtered)))
        }

        print(paste("==> Selected Columns 5: ", length(settings$selectedColumns), " Dataset columns: ",ncol(dataset_filtered), " Dataset rows: ", nrow(dataset_filtered)))
        if(settings$removeNA == TRUE){
            print(paste0("=====> Removing NA Values"))
            dataset_filtered <- na.omit(dataset_filtered)
        }
        print(paste("==> Selected Columns 6: ", length(settings$selectedColumns), " Dataset columns: ",ncol(dataset_filtered), " Dataset rows: ", nrow(dataset_filtered)))

        if(nrow(dataset_filtered) <= 2) {
            print("==> No enough rows to proceed with PCA analysis")
            return (list(success = FALSE, message = FALSE, details = FALSE))
        }

        input_data <- dataset_filtered
        if(!is.null(settings$groupingVariables)){
            input_data <- input_data[ , -which(names(input_data) %in% settings$groupingVariables)]
        }

        ## Data without grouping variables
        names(dataset_filtered) <- plyr::mapvalues(names(dataset_filtered), from=fileHeader$remapped, to=fileHeader$original)
        
        ## Data without grouping variables
        names(input_data) <- plyr::mapvalues(names(input_data), from=fileHeader$remapped, to=fileHeader$original)  

        ## START PCA
        print(paste("==> Selected Columns 7: ", length(settings$selectedColumns), " PCA Dataset columns:",ncol(input_data), " Dataset rows: ", nrow(dataset_filtered)))

        # FactoMineR
        scale.unit <- TRUE
        if(settings$preProcessDataset == TRUE){
            scale.unit <- FALSE
        }
        
        print(paste("==> Using METHOD: ", settings$method))

        # write.csv(input_data,"/tmp/pca_testing.csv", row.names = FALSE)

        if(settings$method == "PCA"){
            analysis_results <- PCA(input_data, scale.unit = scale.unit, ncp = 10, graph = FALSE)
        }else if(settings$method == "MCA"){
            ## Convert to factors
            col_names <- names(input_data)
            input_data[,col_names] <- lapply(input_data[,col_names] , factor)

            analysis_results <- MCA(input_data, ncp = 10, graph = FALSE)
        }else{
            analysis_results <- PCA(input_data, scale.unit = scale.unit, ncp = 10, graph = FALSE)
        }
        print(paste("==> analysis completed"))

        res.info$pca <- convertToString(summary(analysis_results))

        ## Strictly numeric dataframe for kmo and cor methods
        input_data_numeric <- input_data[,sapply(input_data, is.numeric)]

        if(ncol(input_data_numeric) < settings$kmo_bartlett_limit){

            columns_with_na <- names(which(colSums(is.na(input_data_numeric))>0))

            if(length(columns_with_na) == 0 && settings$method == "PCA"){
                print("=====> Calculating KMO and bartlett")
                data_correlation <- cor(input_data_numeric)
                
                res.info$kmo <- convertToString(kmo_test(data_correlation))
                res.info$bartlett <- convertToString(psych::cortest.bartlett(data_correlation, n = nrow(input_data_numeric)))
            }else{
                if(length(columns_with_na) > 0){
                    info_msg <- paste0("=====> Skipping calculation of KMO and bartlett, because of NA values in following columns: ",paste(columns_with_na, collapse = ", "))
                }else if(settings$method == "MCA"){
                    info_msg <- paste0("=====> Skipping calculation of KMO and bartlett. Not supported for MCA method")
                }
                res.info$kmo <-  convertToString(info_msg)
                res.info$bartlett <-  convertToString(info_msg)
                print(info_msg)
            }
        }else{
            info_msg <- paste0("=====> Skipping calculation of KMO and bartlett, more than ",settings$kmo_bartlett_limit," columns detected: ", ncol(input_data_numeric))

            res.info$kmo <-  convertToString(info_msg)
            res.info$bartlett <-  convertToString(info_msg)

            print(info_msg)
        }


        print("=====> INFO: Eigenvalues / Variances")
        # Eigenvalues / Variances
        eig.val <- get_eigenvalue(analysis_results)

        res.info$eig <- convertToString(eig.val)

        print("=====> INFO: Eigenvalues DONE")

        # Dimension description
        print("=====> INFO: Dimension description START")
        res.desc <- dimdesc(analysis_results, axes = c(1,2), proba = 0.05)
        print("=====> INFO: Dimension description DONE")

        if(settings$method == "PCA"){
            # Description of dimension
            res.info$desc_dim_1 <- convertToString(round_df(res.desc$Dim.1$quanti, 4))
            res.info$desc_dim_2 <- convertToString(round_df(res.desc$Dim.2$quanti, 4))
        }else if(settings$method == "MCA"){
            # Description of dimension
            res.info$desc_dim_1 <- convertToString(res.desc$Dim.1$quanti)
            res.info$desc_dim_2 <- convertToString(res.desc$Dim.2$quanti)
        }

        # Visualize the eigenvalues
        print("=====> INFO: Visualize the eigenvalues START")
        tmp_path <- plots_fviz_eig(analysis_results, settings, plot_unique_hash[["plot_scree"]]) 
        res.data$plot_scree = optimizeSVGFile(tmp_path)
        res.data$plot_scree_png = convertSVGtoPNG(tmp_path)
        print("=====> INFO: Visualize the eigenvalues DONE")

        ############# Graph of variables
        print("=====> INFO: Visualize variables START")
        var <- plots_fviz_var(analysis_results, settings)
        print("=====> INFO: Visualize variables DONE")

        ## Coordinates
        res.info$var$coord <- var$coord
        ## Cos2: quality on the factore map
        res.info$var$cos2 <- var$cos2
        ## Contributions to the principal components
        res.info$var$contrib <- var$contrib

        # Visualize the results individuals and variables, respectively.
        print("=====> INFO: Visualize individuals and variables START")
        tmp_path <- plots_fviz_ind_vars(analysis_results, "cos2", "var", settings, plot_unique_hash[["plot_var_cos2_correlation"]], dataset_filtered, fileHeader)

        res.data$plot_var_cos2_correlation = optimizeSVGFile(tmp_path)
        res.data$plot_var_cos2_correlation_png = convertSVGtoPNG(tmp_path)
        print("=====> INFO: Visualize individuals and variables DONE")

        # Classify the variables into 3 groups using the kmeans clustering algorithm. 
        set.seed(1337)
        print("=====> INFO: kmeans START")
        res.km <- kmeans(var$coord, centers = 3, nstart = 256)
        print("=====> INFO: kmeans END")
        grp <- as.factor(res.km$cluster)

        tmp_path <- plots_fviz_ind_vars(analysis_results, grp, "var", settings, plot_unique_hash[["plot_var_cos2_correlation_cluster"]], dataset_filtered, fileHeader, TRUE)

        res.data$plot_var_cos2_correlation_cluster = optimizeSVGFile(tmp_path)
        res.data$plot_var_cos2_correlation_cluster_png = convertSVGtoPNG(tmp_path)

        # Visualize the cos2 of variables on all the dimensions using the corrplot package
        tmp_path <- plots_corrplot(var$cos2, settings, plot_unique_hash[["plot_var_cos2_corrplot"]])
        res.data$plot_var_cos2_corrplot = optimizeSVGFile(tmp_path)
        res.data$plot_var_cos2_corrplot_png = convertSVGtoPNG(tmp_path)
        #  bar plot of variables cos2 
        tmp_path <- plots_fviz_cos2(analysis_results, "var", settings, plot_unique_hash[["plot_var_bar_plot"]])
        res.data$plot_var_bar_plot = optimizeSVGFile(tmp_path)
        res.data$plot_var_bar_plot_png = convertSVGtoPNG(tmp_path)

        # The most important (or, contributing) variables highlighted on the correlation plot
        tmp_path <- plots_fviz_ind_vars(analysis_results, "contrib", "var", settings, plot_unique_hash[["plot_var_contrib_correlation"]], dataset_filtered, fileHeader)
        res.data$plot_var_contrib_correlation = optimizeSVGFile(tmp_path)
        res.data$plot_var_contrib_correlation_png = convertSVGtoPNG(tmp_path)
        # Highlight the most contributing variables for each dimension:
        tmp_path <- plots_corrplot(var$contrib, settings, plot_unique_hash[["plot_var_contrib_corrplot"]])
        res.data$plot_var_contrib_corrplot = optimizeSVGFile(tmp_path)
        res.data$plot_var_contrib_corrplot_png = convertSVGtoPNG(tmp_path)
        # Draw a bar plot of variable contributions
        tmp_path <- plots_fviz_contrib(analysis_results, "var", 1:2, 10, settings, plot_unique_hash[["plot_var_contrib_bar_plot"]])
        res.data$plot_var_contrib_bar_plot = optimizeSVGFile(tmp_path)
        res.data$plot_var_contrib_bar_plot_png = convertSVGtoPNG(tmp_path)

        ############# Graph of individuals
        ind <- plots_fviz_ind(analysis_results, settings)

        ## Coordinates
        res.info$ind$coord <- ind$coord
        ## Cos2: quality on the factore map
        res.info$ind$cos2 <- ind$cos2
        ## Contributions to the principal components
        res.info$ind$contrib <- ind$contrib

        # Correlation circle
        tmp_path <- plots_fviz_ind_vars(analysis_results, "cos2", "ind", settings, plot_unique_hash[["plot_ind_cos2_correlation"]], dataset_filtered, fileHeader)
        res.data$plot_ind_cos2_correlation = optimizeSVGFile(tmp_path)
        res.data$plot_ind_cos2_correlation_png = convertSVGtoPNG(tmp_path)

        if(!is.null(settings$groupingVariables)){

            for(groupVariable in settings$groupingVariables){
                # groupVariable is remaped value
                groupingVariable <- fileHeader %>% filter(remapped %in% groupVariable)
                groupingVariable <- groupingVariable$original

                tmp_path <- plots_fviz_ind_grouped(analysis_results, dataset_filtered, settings, groupingVariable, fileHeader, plot_unique_hash$plot_ind_cos2_correlation_grouped[[groupVariable]])
                res.data$plot_ind_cos2_correlation_grouped[[groupVariable]]$name <- groupingVariable
                res.data$plot_ind_cos2_correlation_grouped[[groupVariable]]$svg <- optimizeSVGFile(tmp_path)
                res.data$plot_ind_cos2_correlation_grouped[[groupVariable]]$png <- convertSVGtoPNG(tmp_path)

                tmp_path <- plots_fviz_biplot_grouped(analysis_results, dataset_filtered, settings, groupingVariable, fileHeader, plot_unique_hash$plot_ind_cos2_correlation_grouped_biplot[[groupVariable]])
                res.data$plot_ind_cos2_correlation_grouped_biplot[[groupVariable]]$name <- groupingVariable
                res.data$plot_ind_cos2_correlation_grouped_biplot[[groupVariable]]$svg <- optimizeSVGFile(tmp_path)
                res.data$plot_ind_cos2_correlation_grouped_biplot[[groupVariable]]$png <- convertSVGtoPNG(tmp_path)
            }
        }

        print("=====> INFO: Generating images for PCA")

        # Quality of representation
        tmp_path <- plots_corrplot(ind$cos2, settings, plot_unique_hash[["plot_ind_cos2_corrplot"]])
        res.data$plot_ind_cos2_corrplot = optimizeSVGFile(tmp_path)
        res.data$plot_ind_cos2_corrplot_png = convertSVGtoPNG(tmp_path)
        #  bar plot of variables cos2 
        tmp_path <- plots_fviz_cos2(analysis_results, "ind", settings, plot_unique_hash[["plot_ind_bar_plot"]])
        res.data$plot_ind_bar_plot = optimizeSVGFile(tmp_path)
        res.data$plot_ind_bar_plot_png = convertSVGtoPNG(tmp_path)
        # The most important (or, contributing) variables highlighted on the correlation plot
        tmp_path <- plots_fviz_ind_vars(analysis_results, "contrib", "ind", settings, plot_unique_hash[["plot_ind_contrib_correlation"]], dataset_filtered, fileHeader)
        res.data$plot_ind_contrib_correlation = optimizeSVGFile(tmp_path)
        res.data$plot_ind_contrib_correlation_png = convertSVGtoPNG(tmp_path)
        # Contributions of individuals to PCs
        tmp_path <- plots_corrplot(ind$contrib, settings, plot_unique_hash[["plot_ind_contrib_corrplot"]])
        res.data$plot_ind_contrib_corrplot = optimizeSVGFile(tmp_path)
        res.data$plot_ind_contrib_corrplot_png = convertSVGtoPNG(tmp_path)
        # Contributions of individuals to PC1 and PC2
        tmp_path <- plots_fviz_contrib(analysis_results, "ind", 1:2, 10, settings, plot_unique_hash[["plot_ind_contrib_bar_plot"]])
        res.data$plot_ind_contrib_bar_plot = optimizeSVGFile(tmp_path)
        res.data$plot_ind_contrib_bar_plot_png = convertSVGtoPNG(tmp_path)

        tmp_path <- tempfile(pattern = plot_unique_hash[["saveObjectHash"]], tmpdir = tempdir(), fileext = ".Rdata")
        processingData <- list(
            res.info = res.info, 
            res.pca = analysis_results, 
            input_data = input_data, 
            settings = settings, 
            dataset_filtered = dataset_filtered, 
            fileHeader = fileHeader,
            res.km = res.km,
            res.data = res.data
        )
        saveCachedList(tmp_path, processingData)
        res.data$saveObjectHash = substr(basename(tmp_path), 1, nchar(basename(tmp_path))-6)


        print("=====> INFO: Serving final result")

        return (list(success = TRUE, message = res.data, details = res.info))
    }
)
