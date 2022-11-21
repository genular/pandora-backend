#' @get /analysis/other/sam/renderOptions
simon$handle$analysis$other$sam$renderOptions <- expression(
    function(){
        data <- list()

        data$deltaInput <-list(value = 0.01, min = 0.01, max = 10, step = 0.01)

        data$responseType_array <- list(
            list(title = "Quantitative", value="Quantitative"),
            list(title = "Two class unpaired", value="Two class unpaired"),
            list(title = "Survival", value="Survival"),
            list(title = "Multiclass", value="Multiclass"),
            list(title = "One class'", value="One class"),
            list(title = "Two class paired", value="Two class paired"),
            list(title = "Two class unpaired timecourse", value="Two class unpaired timecourse"),
            list(title = "One class timecourse", value="One class timecourse"),
            list(title = "Two class paired timecourse", value="Two class paired timecourse"),
            list(title = "Pattern discovery", value="Pattern discovery")
        )

        data$testStatistic <- list(
            list(title="T-statistic", value="standard"),
            list(title="Wilcoxon", value="wilcoxon")
        )

        data$centerArrays <-  list(
             list(title="Yes", value="Yes"),
             list(title="No", value="No")
        )

        data$analysisType <- list(
            list(title="Standard (genes)", value="Standard"),
            list(title="Gene sets", value="Gene sets")
        )
        data$timeSummaryType <- list(
             list(title="Slope", value="slope"),
             list(title="Signed Area", value="signed.area")
        )

        data$numberOfNeighbors <- list(value = 10, min = 1, max = 50, step = 1)
        data$nperms <- list(value = 100, min = 25, max = 5000, step = 5)
        data$random_seed <- sample(1000:10000, 1)

        return(list(
            status = "success",
            message = data
        ))
    }
)

#' @get /analysis/other/sam/renderPlot
simon$handle$analysis$other$sam$renderPlot <- expression(
    function(req, res, ...){
        args <- as.list(match.call())

        resampleID <- 0
        if("resampleID" %in% names(args)){
            resampleID <- as.numeric(args$resampleID)
        }

        settings <- NULL
        if("settings" %in% names(args)){
            settings <- jsonlite::fromJSON(RCurl::base64Decode(URLdecode(args$settings)))
        }

        ## Get JOB and his Info from database
        resampleDetails <- db.apps.getFeatureSetData(resampleID)

        ## Download dataset if not downloaded already
        resamplePath <- downloadDataset(resampleDetails[[1]]$remotePathMain)  

        dataset <- loadDataFromFileSystem(resamplePath)

        ## Remap outcome values to original ones
        dataset[[resampleDetails[[1]]$outcome$remapped]] <- as.factor(dataset[[resampleDetails[[1]]$outcome$remapped]])

        ## Adjust rownames for samr analysis
        n <- nrow(dataset)
        rownames(dataset) <- paste0(c(1:n), "_", dataset[[resampleDetails[[1]]$outcome$remapped]])

        ## Drop all columns that are not in analyzed feature set of the resample
        data <- dataset[, names(dataset) %in% c(resampleDetails[[1]]$features$remapped)]

        ## Rename all columns back to its original column names
        ##                   original position remapped
        ## 1              Pregnancies        0  column0
        names(data) <- plyr::mapvalues(names(data), from=resampleDetails[[1]]$features$remapped, to=resampleDetails[[1]]$features$original)

        data <- t(data)

        sam_data <- list(x=data, 
            y=dataset[[resampleDetails[[1]]$outcome$remapped]],
            geneid = row.names(data),
            genenames = row.names(data),
            logged2=FALSE, 
            censoring.status = NULL,
            ## Eigengene to be used (just for resp.type="Pattern discovery")
            eigengene.number = NULL,
            imputedX = NULL,
            originalX = NULL) 

        ## Correlates a large number of features (eg genes) with an outcome variable, such as a group indicato
        ## https://cran.r-project.org/web/packages/samr/samr.pdf
        SAM <- samr::samr(sam_data, 
            resp.type = settings$responseType_array,
            # assay.type = "array",
            s0.perc = NULL,
            nperms = settings$nperms$value,
            # center.arrays = settings$centerArrays,
            testStatistic = settings$testStatistic,
            time.summary.type = "slope",
            regression.method = "standard", 
            random.seed = settings$random_seed,
            knn.neighbors = settings$numberOfNeighbors$value)


        ## Report estimated p-values for each gene, from a SAM analysis
        pv = samr::samr.pvalues.from.perms(SAM$tt, SAM$ttstar)
        ## Computes tables of thresholds, cutpoints and corresponding False Discovery rates for SAM
        delta.table <- samr::samr.compute.delta.table(SAM, min.foldchange = 0)
        #select a FDR cut-off and assign the corresponding delta values to delta
        delta <- settings$deltaInput$value
        ## Computes significant genes table, starting with samr object "samr.obj" and delta.table "delta.table"
        siggenes.table <- samr::samr.compute.siggenes.table(SAM, delta, sam_data, delta.table)

        data_up    <- NULL
        if(siggenes.table$ngenes.up > 0){
            data_up    <- as.data.frame(siggenes.table$genes.up)
            data_up$status <- "UP"
        }
        
        data_down    <- NULL
        if(siggenes.table$ngenes.lo > 0){
            data_down    <- as.data.frame(siggenes.table$genes.lo)
            data_down$status <- "DOWN"
        }

        if(is.null(data_up) && !is.null(data_down)){
            output <- data_down
        }else if(!is.null(data_up) && is.null(data_down)){
            output <- data_up
        }else if(!is.null(data_up) && !is.null(data_down)){
            output <- dplyr::full_join(data_up, data_down)
        }

        rename_from <- c("Row", "Gene ID", "Gene Name", "Score(d)", "Numerator(r)", "Denominator(s+s0)", "Fold Change", "q-value(%)", "status")
        rename_to <- c("row", "gene_id", "gene_name", "score", "numerator", "denominator", "fold_change", "q_value", "status")
        names(output) <- plyr::mapvalues(names(output), from=rename_from, to=rename_to)

        return(list(
                    status = "success",
                    message = list(
                            pv = pv,
                            sig_table = output,
                            request = settings
                        )
                )
            )
    }
)
