#' @title Generate a specification for fitting a caret model
#' @description A caret model specificaiton consists of 2 parts: a model (as a string) and the argments to the train call for fitting that model
#' @param method the modeling method to pass to caret::train
#' @return a list of lists
#' @examples
#' caretModelSpec("rf", tuneLength=5, preProcess="ica")
caretModelSpec <- function(method="rf", ...){
    out <- c(list(method=method), list(...))
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
    tmp2 <- length(unique(modelLookup(tuneList$method)$parameter))

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
    y <- model.response(model.frame(form, data))
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
#' @param dataDir Data root save dir for current analysis
#' @return model fit
caretTrainModel <- function(data, model_details, problemType, outcomeColumn, preProcess = NULL, resampleID, dataDir){
    set.seed(1337)

    results <- list(
            status = FALSE,
            data = NULL)
    trControl <- NULL


    if(problemType == "classification"){
        classProbs = model_details$prob
        trControl <- caret::trainControl(method="repeatedcv", 
            number=10, repeats=5, 
            savePredictions = "final", 
            classProbs = classProbs, 
            summaryFunction = multiClassSummary, 

            verboseIter = TRUE, 
            allowParallel = TRUE)
    }else{
        trControl <- caret::trainControl(method="repeatedcv", 
            number=10, repeats=5, 
            savePredictions = "final", 
            # classProbs = TRUE, 
            # summaryFunction = multiClassSummary, 
            verboseIter = TRUE, 
            allowParallel = TRUE)
    }

    # Add arguments specific to models
    if (model_details$internal_id == "ranger") {
        trControl$importance <- "impurity"
    }

    # Make a tuneList
    tuneList <- caretModelSpec(model_details$internal_id, tuneLength=NULL, preProcess=preProcess)

    # TODO: Add indexes to trControl if they are missing
    if (!is.null(trControl) && is.null(trControl$index) && problemType == "classification") {
        cachePath <- paste0(dataDir,"/data/specific/folds_",resampleID,".RData")
        trainFormula <- as.formula(paste0("factor(", outcomeColumn, ") ~."))
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

    # TODO: add seeds
    ## Predefine seeds and cache it to use in all models across feature set
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


    train_args <- list(as.formula(paste0(outcomeColumn, " ~.")), data = data, trControl = trControl)
    train_args <- c(train_args, tuneList)
        
    model.execution <- tryCatch( garbage <- capture.output(results$data <- R.utils::withTimeout(do.call(caret::train, train_args), timeout=120, onTimeout = "error") ), error = function(e){ return(e) } )

    # Ignore warnings while processing errors
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
            message <- geterrmessage()
            model.execution$message <- message
        }
        cat(paste0("===> ERROR: caretTrainModel: ",model.execution$message," \r\n"))
        results$data <- model.execution$message
    }
    # Restore default warning reporting
    options(warn=0)

    return(results)
}

#' @title Predicts Testing data on previously trained model Fit
#' @description This function predicts Testing set if available, it returns class probabilities for predictions
#' @param trainingFit Model Fit from caret::train function
#' @param model Testing dataset with features and outcome
#' @return data frame
caretPredict <- function(trainingFit, data){
    results <- list(type = NULL, preds = NULL)

    if (is.null(data)) {
        data <- trainingFit[[1]]$trainingData
        if (is.null(data)) {
            stop("Could not find training data in the first model")
        }
    }

    type <- trainingFit$modelType
    if (type == "Classification") {
        if (trainingFit$control$classProbs) {
            results$type <- "prob"
            # Return probability predictions for only one of the classes as determined by
            # configured default response class level
            results$preds <- tryCatch( caret::predict.train(trainingFit, type = "prob", newdata = data) , error = function(e){ stop(e) } )
        } else {
            results$type <- "raw"
            results$preds <- tryCatch( caret::predict.train(trainingFit, type = "raw", newdata = data) , error = function(e){ stop(e) } )
        }
    } else if (type == "Regression") {
        results$type <- "raw"
        results$preds <- tryCatch( caret::predict.train(trainingFit, type = "raw", newdata = data) , error = function(e){ stop(e) } )
    } else {
        stop(paste("Unknown model type:", type))
    }

    return(results)
}
