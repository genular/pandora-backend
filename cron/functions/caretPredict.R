#' @title Generate a specification for fitting a caret model
#' @description A caret model specificaiton consists of 2 parts: a model (as a string) and the argments to the train call for fitting that model
#' @param method the modeling method to pass to caret::train
#' @return a list of lists
#' @examples
#' caretModelSpec("rf", tuneLength=5, preProcess="ica")
caretModelSpec <- function(methodInclude="rf", ...){
    if(methodInclude == "catboost.caret"){
        ## Return a R function instead string in method
        methodInclude = base::get(methodInclude)
    }
    out <- c(list(method=methodInclude), list(...))
    return(out)
}

#' @title Check that the trainControl object supplied by the user is valid
#' @description This function checks the user-supplied trainControl object and makes sure it has all the required fields.
#' @param x a trainControl object.
#' @param y the target for the model. Used to determine resampling indexes.
#' @return trControl
trControlCheck <- function(x, y) {
    if (!length(x$savePredictions) == 1) {
        stop("Please pass exactly 1 argument to savePredictions, e.g. savePredictions='final'")
    }

    if (x$savePredictions == TRUE) {
        x$savePredictions <- "final"
    }

    if (!(x$savePredictions %in% c("all", "final"))) {
        x$savePredictions <- "final"
    }

    return(x)
}
#' @title Check that the trainControl has defined re-sampling indexes.
#' @description This function checks If the resampling indexes are missing, it adds them to the model.
#' @param x a trainControl object.
#' @param y the target for the model.  Used to determine resampling indexes.
#' @importFrom caret createResample createFolds createMultiFolds createDataPartition
#' @return trControl
trControlFolds <- function(x, y){
    set.seed(1337)

    if (is.null(x$index)) {
        if (x$method == "boot" | x$method == "adaptive_boot") {
            x$index <- caret::createResample(y, times = x$number, list = TRUE)
        } else if (x$method == "cv" | x$method == "adaptive_cv") {
            x$index <- caret::createFolds(y, k = x$number, list = TRUE, returnTrain = TRUE)
        } else if (x$method == "repeatedcv") {
            x$index <- caret::createMultiFolds(y, k = x$number, times = x$repeats) 

        } else if (x$method == "LGOCV" | x$method == "adaptive_LGOCV") {
            x$index <- caret::createDataPartition(y, times = x$number, p = 0.5, list = TRUE,
                groups = min(5, length(y)))
        } else {
            stop(paste0("caretList does not currently know how to handle cross-validation method='",
                x$method, "'. Please specify trControl$index manually"))
        }
    }
    return(x)
}

#' @title Create uniform seeds across model fits
#' @description Currently the seed structure is determined with the length of the 
#' seed list being number * repeats +1 and the length of all vectors B -1 being 
#' 20 * tuneLength^2 with the final vector being a single seed
#' @param ctrl trainControl object passed by the user
#' @param resampNumb the maximum number of resamples necessary
#' @return trControl
setSeeds <- function(ctrl, resampNumb){
    # resampNumb is the square of the tune-length
    B <- ctrl$number * ctrl$repeats 
    mseeds <- vector(mode = "list", length = B + 1) #length is = (n_repeats*nresampling)+1
    if(length(resampNumb) > 1){resampNumb <- max(resampNumb)}
    resampNumb <- resampNumb * 20 # hack for arbitrary scalar
    for(i in 1:B) mseeds[[i]] <- sample.int(n=resampNumb, resampNumb, replace = FALSE, prob = NULL)
    mseeds[[B+1]] <- sample.int(n=resampNumb, 1, replace = FALSE, prob = NULL)
    return(mseeds)
}

#' @title Create a list of several train models from the caret package
#' @param x a character vector of caret models
#' @return A list of train objects
tmpExtract <- function(x){
  if(is.null(names(x))){
    tmp <- 0
  } else if(names(x) == "tuneGrid"){
    tmp <- nrow(x$tuneGrid)
  } else{
    tmp <- max(x$tuneLength)
  }
  return(tmp)
}

#' @title Calculate maximum number of resamples necessary
#' @param tuneList trainControl object passed by the user
#' @param model the maximum number of resamples necessary
#' @return integer
getResamplesNumber <- function(tuneList){
    suppressWarnings(tmp <- tmpExtract(tuneList))
    tmp2 <- length(unique(caret::modelLookup(tuneList$method)$parameter))

    tmp <- as.numeric(tmp)
    tmp2 <- as.numeric(tmp2)

    resamplesNumber <- max(tmp^tmp2)

    return(resamplesNumber)
}

#' @title Extracts the target variable from a set of arguments headed to the caret::train function.
#' @description This function extracts the y variable from a set of arguments headed to a caret::train model.  Since there are 2 methods to call caret::train, this function also has 2 methods.
#' @param ... a set of arguments, as in the caret::train function
extractCaretTarget <- function(...){
    UseMethod("extractCaretTarget")
}

#' @title Extracts the target variable from a set of arguments headed to the caret::train.default function.
#' @description This function extracts the y variable from a set of arguments headed to a caret::train.default model.
#' @param x an object where samples are in rows and features are in columns. This could be a simple matrix, data frame or other type (e.g. sparse matrix). See Details below.
#' @param y a numeric or factor vector containing the outcome for each sample.
#' @param ... ignored
#' @method extractCaretTarget default
extractCaretTarget.default <- function(x, y, ...){
    return(y)
}

#' @title Extracts the target variable from a set of arguments headed to the caret::train.formula function.
#' @description This function extracts the y variable from a set of arguments headed to a caret::train.formula model.
#' @param form A formula of the form y ~ x1 + x2 + ...
#' @param data Data frame from which variables specified in formula are preferentially to be taken.
#' @param ... ignored
#' @method extractCaretTarget formula
extractCaretTarget.formula <- function(form, data, ...){
    y <- stats::model.response(stats::model.frame(form, data))
    names(y) <- NULL
    return(y)
}

#' @title Prepares and Trains Model with caret::train
#' @description This function prepares all parameters to use with caret::train function
#' @param data Data frame with features and outcome
#' @param model_details Details frame of current model
#' @param problemType classification or regression
#' @param outcomeColumn Name of the outcome column in data
#' @param preProcess c("pca")
#' @param resampleID Current Feature set ID
#' @param dataDir Data root save dir for current analysis (TEMP_DIR,"/cron_data/",dataset$userID,"/",dataset$queueID,"/",dataset$resampleID)
#' @return model fit
caretTrainModel <- function(data, model_details, problemType, outcomeColumn, preProcess = NULL, resampleID, dataDir){
    set.seed(1337)

    results <- list(status = FALSE, data = NULL)
    trControl <- NULL

    if(problemType == "classification"){
        trControl <- caret::trainControl(
                method=ifelse(is.null(model_details[["trControl"]][["method"]]), "repeatedcv", model_details$trControl$method), 
                ## Either the number of folds or number of resampling iterations
                number=ifelse(is.null(model_details[["trControl"]][["number"]]), 10, model_details$trControl$number),
                ## For repeated k-fold cross-validation only: the number of complete sets of folds to compute
                repeats=ifelse(is.null(model_details[["trControl"]][["repeats"]]), 2, model_details$trControl$repeats), 
                savePredictions =ifelse(is.null(model_details[["trControl"]][["savePredictions"]]), "final", model_details$trControl$savePredictions), 
                classProbs=ifelse(is.null(model_details[["trControl"]][["classProbs"]]), model_details$prob, model_details$trControl$classProbs), 
                summaryFunction=ifelse(is.null(model_details[["trControl"]][["summaryFunction"]]), caret::multiClassSummary, model_details$trControl$summaryFunction),
                verboseIter=ifelse(is.null(model_details[["trControl"]][["verboseIter"]]), TRUE, model_details$trControl$verboseIter), 
                allowParallel=ifelse(is.null(model_details[["trControl"]][["allowParallel"]]), TRUE, model_details$trControl$allowParallel)
            )
    }else{
        trControl <- caret::trainControl(
                method=ifelse(is.null(model_details[["trControl"]][["method"]]), "repeatedcv", model_details$trControl$method), 
                ## Either the number of folds or number of resampling iterations
                number=ifelse(is.null(model_details[["trControl"]][["number"]]), 10, model_details$trControl$number),
                ## For repeated k-fold cross-validation only: the number of complete sets of folds to compute
                repeats=ifelse(is.null(model_details[["trControl"]][["repeats"]]), 2, model_details$trControl$repeats), 
                savePredictions =ifelse(is.null(model_details[["trControl"]][["savePredictions"]]), "final", model_details$trControl$savePredictions), 
                # classProbs = TRUE, 
                # summaryFunction = caret::multiClassSummary, 
                verboseIter=ifelse(is.null(model_details[["trControl"]][["verboseIter"]]), TRUE, model_details$trControl$verboseIter), 
                allowParallel=ifelse(is.null(model_details[["trControl"]][["allowParallel"]]), TRUE, model_details$trControl$allowParallel)
            )
    }

    # Add arguments specific to models
    if (is.character(model_details$internal_id) && model_details$internal_id == "ranger") {
        trControl$importance <- "impurity"
    }

    # Make a tuneList
    # The tuneLength parameter tells the algorithm to try different default values for the main parameter
    tuneList <- caretModelSpec(model_details$internal_id, tuneLength=2, preProcess=preProcess)

    # Maybe we want to add model specific arguments
    model_specific_args <- NULL
    if(!is.null(model_details[["model_specific_args"]])){
        model_specific_args <- model_details$model_specific_args
    }

    if(!is.null(model_specific_args)){
        tuneList <- c(tuneList, model_specific_args)
    }
    # TODO: Add indexes to trControl if they are missing
    if (!is.null(trControl) && is.null(trControl$index) && problemType == "classification") {
        cat(paste0("===> INFO: Adding indexes to trControl \r\n"))
        
        cachePath <- paste0(dataDir,"/folds/train_control_folds.RData")
        trainFormula <- stats::as.formula(paste0("base::factor(", outcomeColumn, ") ~."))
        target <- extractCaretTarget(trainFormula, data)
        folds <- checkCachedList(cachePath)

        if(!is.null(folds)){
            trControl$index <- folds
            rm(folds)
        }else{
            trControl$index <- trControlFolds(x = trControl, y = target)$index
            saveCachedList(cachePath, trControl$index)
        }
        ## Check is Train Control is valid
        trControl <- trControlCheck(x = trControl, y = target)
    }

    ## Predefine seeds and cache it to use in all models across feature set
    ## make a tuneList method to identify the seed structure and build seeds
    ## resamplesNumber <- getResamplesNumber(tuneList)
    ## cachePath <- paste0(dataDir,"/data/specific/seeds_",resampleID,"_",resamplesNumber,".RData")
    ## cacheSeeds <- checkCachedList(cachePath)
    ## if(!is.null(cacheSeeds)){
    ##     mseeds <- cacheSeeds
    ## }else{
    ##     mseeds <- setSeeds(trControl, resamplesNumber)
    ##     saveCachedList(cachePath, mseeds)
    ## }
    ## trControl$seeds <- mseeds

    ## Use matrix interface for classification problems
    if(model_details$interface == "matrix"){
        data_x <- data[,!(names(data) %in% outcomeColumn)]
        data_y <- data[,c(outcomeColumn)]
        train_args <- list(data_x, base::as.factor(base::make.names(data_y)), trControl = trControl)

    }else if(model_details$interface == "formula"){
        train_args <- list(stats::as.formula(paste0(outcomeColumn, " ~.")), data = data, trControl = trControl)
    }else{
        cat(paste0("===> ERROR: model_details$interface is not defined \r\n"))
        print(model_details)
        die()
    }

    model_time_start <- Sys.time()
    cat(paste0("===> INFO: Model RAW training start: ",model_time_start," Timeout: ",model_details$process_timeout,"\r\n"))

    train_args <- c(train_args, tuneList)
    model.execution <- tryCatch( garbage <- R.utils::captureOutput(results$data <- R.utils::withTimeout(do.call(caret::train, train_args), substitute = FALSE, timeout=model_details$process_timeout, cpu=model_details$process_timeout, onTimeout = "error") ), error = function(e){ return(e) } )

    # Ignore warnings while processing errors, actually we should move this to have training suppressed as well!?
    options(warn = -1)
    if(!inherits(model.execution, "error") && !inherits(results$data, 'try-error') && !is.null(results$data)){
        params <- results$data$modelInfo$parameters$parameter
        params <- results$data$results[,params, drop = TRUE]
        if(length(params) > 0){   
            results$status <- TRUE
        }else{
            results$data <- "No performance parameters available"
        }
    }else{
        if(inherits(results$data, 'try-error')){
            message <- base::geterrmessage()
            model.execution$message <- message
        }
        # cat(paste0("===> ERROR: caretTrainModel: ",model.execution$message," \r\n"))
        results$data <- model.execution$message
    }
    # Restore default warning reporting
    options(warn=0)


    model_time_end <- Sys.time()
    time_passed <- as.numeric(ceiling(difftime(model_time_end, model_time_start,  units = c("secs"))))

    cat(paste0("===> INFO: Model RAW training stop: ",model_time_end," Time passed (sec): ",time_passed,"\r\n"))

    return(results)
}

#' @title Predicts Testing data on previously trained model Fit
#' @description This function predicts Testing set if available, it returns class probabilities for predictions
#' There are two types of evaluation we can do here, raw or prob. Raw gives you a class prediction, yes and nope, 
#' while prob gives you the probability on how sure the model is about it’s choice.
#' @param trainingFit Model Fit from caret::train function
#' @param dataTesting Testing set data with features and outcomes
#' @param outcomeColumn Name of the outcome column
#' @param model_details model_details list
#' @return data frame
caretPredict <- function(trainingFit, dataTesting, outcomeColumn, model_details){
    results <- list(status = TRUE, type = NULL, predictions = NULL)
    predictOnData <- NULL

    if (is.null(dataTesting)) {
        dataTesting <- trainingFit[[1]]$trainingData
        if (is.null(dataTesting)) {
            cat(paste0("===> ERROR: caretPredict: Could not find training data in the first model \r\n"))
            results$status <- FALSE
        }
    }

    ## Remove outcome column
    if(model_details$interface == "matrix"){
        predictOnData <- dataTesting[,!(names(dataTesting) %in% outcomeColumn)]
    }else if(model_details$interface == "formula"){
        predictOnData <- dataTesting
    }

    if(results$status == TRUE){
        if (trainingFit$modelType == "Classification") {
            ## Check if probabilities are supported by model
            if (trainingFit$control$classProbs) {
                results$type <- "prob"
            } else {
                results$type <- "raw"
            }
        } else if (trainingFit$modelType == "Regression") {
            results$type <- "raw"
        } else {
            cat(paste0("===> ERROR: caretPredict: Unknown modelType:", trainingFit$modelType," \r\n"))
            results$status <- FALSE
        }
        ## Finally make predictions
        if(results$status == TRUE){
            # Return probability predictions for only one of the classes as determined by
            # configured default response class level
            results$predictions <- tryCatch( caret::predict.train(trainingFit, type = results$type, newdata = predictOnData) , error = function(e){ 
                cat(paste0("===> ERROR: caretPredict:caret::predict.train\r\n"))
                return(NULL) 
            })

            # model's inability to predict certain classes returns NA
            if(!is.null(results$predictions) && any(is.na(results$predictions))){
                cat(paste0("===> WARNING: Imputing (mean) NaN predictions\r\n"))
                results$predictions <- results$predictions %>% mutate_all(~ifelse(is.na(.x), mean(.x, na.rm = TRUE), .x))

                # For Median use:
                # preProcessMapping <- preProcessResample(results$predictions, c("medianImpute"), NULL, NULL)
                # results$predictions <- preProcessMapping$datasetData
            }
        }
    }


    return(results)
}

#' @title Perform RFE with caret
#' @description Perform RFE with caret and return list of rel avant predictors
#' @param data Data frame with features and outcome
#' @param model_details Details frame of current model
#' @param problemType classification or regression
#' @param outcomeColumn Name of the outcome column in data
#' @return predictors
recursiveFeatureElimination <- function(data, model_details, outcomeColumn){
    set.seed(1337)
    
    # Initialize results list
    results <- list(status = FALSE, modelData = NULL, modelPredictors = NULL)


    #save(data, file = "/tmp/data")
    #save(model_details, file = "/tmp/model_details")
    #save(outcomeColumn, file = "/tmp/outcomeColumn")

    # Set up RFE control
    rfeControl <- caret::rfeControl(
        method = "repeatedcv",
        number = 10,
        repeats = 5,
        functions = caret::rfFuncs, 
        returnResamp = "all",
        saveDetails = TRUE,
        allowParallel = TRUE
    )


    # Separate predictor variables and outcome variable
    data_x <- data[,!(names(data) %in% outcomeColumn)]
    data_y <- data[,c(outcomeColumn)]

    # subset_size_seq <- generateRFESizes(data_x)


    # Set up training arguments
    train_args <- list(data_x, base::as.factor(base::make.names(data_y)), sizes = c(1:ncol(data_x)), rfeControl = rfeControl)

    model.execution <- tryCatch( garbage <- R.utils::captureOutput(results$modelData <- R.utils::withTimeout(do.call(caret::rfe, train_args), 
        timeout=model_details$process_timeout,
        onTimeout = "error") ), error = function(e){ return(e) } )

    # Suppress warnings temporarily
    options(warn = -1)

    if(!inherits(model.execution, "error") && !inherits(results$modelData, 'try-error') && !is.null(results$modelData)){
        results$status <- TRUE
    }else{
        if(inherits(results$modelData, 'try-error')){
            message <- base::geterrmessage()
            model.execution$message <- message
        }
        # cat(paste0("===> ERROR: caretTrainModel: ",model.execution$message," \r\n"))
        results$modelData <- model.execution$message
    }

    # Restore default warning reporting
    options(warn=0)

    if(results$status == TRUE){
        results$modelPredictors <- caret::predictors(results$modelData)
    }

    return(results)
}
