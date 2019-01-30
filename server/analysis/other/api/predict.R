#' @get /analysis/other/predict/catboost/renderOptions
simon$handle$analysis$other$predict$catboost$renderOptions <- expression(
    function(){
        data <- list()

        data$kFolds <-list(value= 5, min= 1, max= 10, step= 1)
        data$cvRepeats <-list(value= 3, min= 1, max= 10, step= 1)
        data$tuneLength <-list(value= 5, min= 1, max= 10, step= 1)
        data$random_seed <- sample(1000:10000, 1)

        return(list(
            status = "success",
            message = data
        ))
    }
)


#' @get /analysis/other/predict/catboost/submit
simon$handle$analysis$other$predict$catboost$submit <- expression(
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
        dataset <- data.table::fread(resamplePath, header = T, sep = ',', stringsAsFactors = FALSE, data.table = FALSE)

        ## Remap outcome values to original ones
        dataset[[resampleDetails[[1]]$outcome$remapped]] <- as.factor(dataset[[resampleDetails[[1]]$outcome$remapped]])

        ## Drop all columns that are not in analyzed feature set of the resample
        data <- dataset[, names(dataset) %in% c(resampleDetails[[1]]$features$remapped)]

        ## Rename all columns back to its original column names
        ##                   original position remapped
        ## 1              Pregnancies        0  column0
        names(data) <- plyr::mapvalues(names(data), from=resampleDetails[[1]]$features$remapped, to=resampleDetails[[1]]$features$original)

        fit_control <-  trainControl(
            method = 'repeatedcv', 
            number = settings$kFolds$value,
            repeats = settings$cvRepeats$value,
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
            border_count = 64
        )


      training_model <- train(x, as.factor(make.names(y)),
                   method = catboost.caret,
                   verbose = TRUE, preProc = NULL,
                   tuneLength=settings$tuneLength$value, trControl = fit_control)

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
