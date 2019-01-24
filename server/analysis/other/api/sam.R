#' @get /analysis/other/sam/renderOptions
simon$handle$analysis$other$sam$renderOptions <- expression(
    function(){
        data <- list()

        data$deltaInput <-list(value = 0.01, min = 0.01, max = 10, step = 0.01)
        data$responseType_array <- c('Quantitative','Two class unpaired', 'Survival', 'Multiclass', 'One class', 'Two class paired', 'Two class unpaired timecourse', 'One class timecourse', 'Two class paired timecourse','Pattern discovery')
        
        data$analysisType <- c("Standard (genes)" = "Standard", "Gene sets" = "Gene sets")
        data$testStatistic <- c("T-statistic"="standard", "Wilcoxon"="wilcoxon")

        data$timeSummaryType <- c("Slope"='slope', "Signed Area"='signed.area')
        data$centerArrays <-  c("Yes", "No")

        data$numberOfNeighbors <- list(value = 10, min = 1, max = 50, step = 1)
        data$nperms <- list(value = 100, min = 25, max = 5000, step = 5)
        data$random_seed <- sample(1000:10000, 1)

        return(list(
            status = "success",
            data = data
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
            settings <- jsonlite::fromJSON(args$settings)
        }

        ## 1st - Get JOB and his Info from database
        resampleDetails <- db.apps.getFeatureSetData(resampleID)

        ## 2nd - Download dataset if not downloaded already
        resamplePath <- downloadDataset(resampleDetails[[1]]$remotePathMain)     
        dataset <- data.table::fread(resamplePath, header = T, sep = ',', stringsAsFactors = FALSE, data.table = FALSE)

        ## dataset[[job_outcome]] <- plyr::mapvalues(dataset[[job_outcome]], from = c("1", "0"), to = c("1", "2"))
        dataset[[resampleDetails[[1]]$outcome$remapped]] <- as.factor(dataset[[resampleDetails[[1]]$outcome$remapped]])

        n <- nrow(dataset)
        rownames(dataset) <- paste0(c(1:n), "_", dataset[[resampleDetails[[1]]$outcome$remapped]])


        data <- dataset[, names(dataset) %in% c(resampleDetails[[1]]$features$remapped)]
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
        SAM <- samr::samr(sam_data, 
            resp.type = settings$responseType_array,
            assay.type = "array",
            s0.perc = NULL,
            nperms = settings$nperms$value,
            center.arrays = settings$centerArrays,
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

        return(list(
                    status = "success",
                    data = list(
                            pv = pv,
                            sig_table = output
                        )
                )
            )
    }
)



#' @get /apps/simon/analysis/catboost/<id>
simon$handle$analysis$other$sam$catboost <- expression(
    function(req, res, ...){
        args <- as.list(match.call())

        fs_id <- 0
        if("fs_id" %in% names(args)){
            fs_id <- as.numeric(args$fs_id)
        }


      # set CV params
      kFolds <- 5
      cvRepeats <- 3
      tuneLength <- 5
      #seeds <- hp.set.seed.cv(1234, kFolds, cvRepeats, tuneLength)

      fit_control <-  trainControl(
                          method = 'repeatedcv', 
                          number = kFolds,
                          repeats = cvRepeats,
                          ## seeds = seeds,
                          verboseIter = FALSE,
                          savePredictions = TRUE,
                          classProbs = TRUE,
                          allowParallel = TRUE
                          # MaxNWts = MaxNWts
                      )

      grid <- expand.grid(depth = c(4,6,8),
                          learning_rate = 0.01,
                          iterations = 500,
                          l2_leaf_reg = 1e-3,
                          rsm = 0.95,
                          border_count = 64)


      drop_columns = c("donor_id", "outcome")
      x <- data_training[,!(names(data_training) %in% drop_columns)]
      y <- data_training[,c("outcome")]

      training_model <- train(x, as.factor(make.names(y)),
                   method = catboost.caret,
                   verbose = TRUE, preProc = NULL,
                   tuneLength=tuneLength, trControl = fit_control)

      prediction <- predict(training_model,  data_testing, type = "prob")
      importance <- varImp(training_model, scale = FALSE)

      roc <- tryCatch(
          {
             roc(data_testing$outcome, prediction[, "high"], levels = levels(data_testing$outcome))
          },
          error=function(msg) {
              return(NULL)
          },
          warning=function(msg) {
              return(NULL)
          },
          finally={}
      ) 
      auc <- NULL 
      if(!is.null(roc)){
         auc <- as.numeric(pROC::auc(roc))    
      }
      return(list(
        training_model = training_model,
        prediction = prediction,
        importance = importance,
        roc = roc,
        auc = auc))
    }
)
