#' @title  getPredictROC
#' @description Build a ROC curve
#' @param responseData modelData$testing[[dataset$outcome]]
#' @param predictionsData predictionObject$predictions[, outcome_mapping[1, ]$class_remapped]
#' @param model_details
#' @return list
getPredictROC <- function(responseData, predictionsData, model_details) {
    results <- list(status = FALSE, data = NULL)
    input_args <- c(list(response = responseData, predictor = predictionsData, levels = levels(responseData)))

    process.execution <- tryCatch( garbage <- R.utils::captureOutput(results$data <- R.utils::withTimeout(do.call(pROC::roc, input_args), timeout=model_details$process_timeout, onTimeout = "error") ), error = function(e){ return(e) } )
    if(!inherits(process.execution, "error") && !inherits(results$data, 'try-error') && !is.null(results$data)){
        results$status <- TRUE
    }else{
        if(inherits(results$data, 'try-error')){
            message <- base::geterrmessage()
            process.execution$message <- message
        }
        results$data <- process.execution$message
    }
    return(results)
}

#' @title  getPostResample
#' @description postResample function to get an accuracy score
#' https://github.com/topepo/caret/blob/master/pkg/caret/R/postResample.R#L119
#' https://topepo.github.io/caret/measuring-performance.html
#' @param predictionProcessed predictionProcessed
#' @param referenceData dataTesting[,outcomeColumn]
#' @param model_details
#' @return list
getPostResample <- function(predictionProcessed, referenceData, model_details) {
    results <- list(status = FALSE, data = NULL)
    input_args <- c(list(pred=predictionProcessed, obs=as.factor(dataTesting[,outcomeColumn])))
    ## Old apply
    ## t <- apply(predictionProcessed, 2, caret::postResample, obs=base::as.factor(dataTesting[, outcomeColumn]))
    process.execution <- tryCatch( garbage <- R.utils::captureOutput(results$data <- R.utils::withTimeout(do.call(caret::postResample, input_args), timeout=model_details$process_timeout, onTimeout = "error") ), error = function(e){ return(e) } )
    if(!inherits(process.execution, "error") && !inherits(results$data, 'try-error') && !is.null(results$data)){
        results$status <- TRUE
    }else{
        if(inherits(results$data, 'try-error')){
            message <- base::geterrmessage()
            process.execution$message <- message
        }
        results$data <- process.execution$message
    }
    return(results)
}

#' @title  getConfusionMatrix
#' @description Calculation of confusionMatrix
#' @param predictionProcessed predictionProcessed
#' @param referenceData Outcome column 
#' @param model_details Model details list
#' @param mode caret::confusionMatrix mode
#' @return list
getConfusionMatrix <- function(predictionProcessed, referenceData, model_details, mode = "everything") {
    results <- list(status = FALSE, data = NULL)

    input_args <- c(list(data = predictionProcessed, reference = referenceData, mode = mode))

    process.execution <- tryCatch( garbage <- R.utils::captureOutput(results$data <- R.utils::withTimeout(do.call(caret::confusionMatrix, input_args), timeout=model_details$process_timeout, onTimeout = "error") ), error = function(e){ return(e) } )

    if(!inherits(process.execution, "error") && !inherits(results$data, 'try-error') && !is.null(results$data)){
        results$status <- TRUE
    }else{
        if(inherits(results$data, 'try-error')){
            message <- base::geterrmessage()
            process.execution$message <- message
        }
        results$data <- process.execution$message
    }

    return(results)
}

#' @title  getVariableImportance
#' @description Calculation of variable importance for regression and classification models
#' @param model Model Fit from caret::train function
#' @param scale 
#' @return data frame
getVariableImportance <- function(model, scale = TRUE) {
    out <- tryCatch(
        {
            caret::varImp(model, scale=scale)
        },
        error=function(msg) {
            cat(paste0("===> ERROR: getVariableImportance: ",match.call()[[1]]," (error): ", msg, "\r\n"))
            return(NULL)
        },
        warning=function(msg) {
            cat(paste0("===> ERROR: getVariableImportance: ",match.call()[[1]]," (warning): ", msg, "\r\n"))
            return(NULL)
        },
        finally={}
    )    
    return(out)
}

#' @title  prepareVariableImportance
#' @description 
#' @param model Model Fit from caret::train function
#' @return data frame
prepareVariableImportance <- function(model)
{
    importance <- NULL
    imp_perc = getVariableImportance(model, TRUE)
    imp_no = getVariableImportance(model, FALSE)

    if (!is.null(imp_perc) && !is.null(imp_no)) { 

        imp <- data.frame(imp_perc$importance)
        ## Take Overall column if available otherwise take first values row
        if("Overall" %in% names(imp)){
            importance_perc = imp[order(-imp$Overall), ,drop = FALSE]
        }else{
            importance_perc = imp[order(-imp[, 1]), ]
        }
        importance_perc$features <- rownames(importance_perc)
        importance_perc$rank <- 1:nrow(importance_perc)
        colnames(importance_perc)[1] <- "score_perc"

        importance_perc$score_perc <- round(as.numeric(as.character(importance_perc$score_perc)))
        importance_perc$score_perc[is.infinite(importance_perc$score_perc) | is.nan(importance_perc$score_perc) | is.na(importance_perc$score_perc) ] <- NA

        importance_perc <- importance_perc[!is.na(importance_perc$score_perc), ]
        importance_perc$score_perc[is.infinite(importance_perc$score_perc) | is.nan(importance_perc$score_perc) | is.na(importance_perc$score_perc) ] <- -10000


        imp <- data.frame(imp_no$importance)
        ## Take Overall if available otherwise take first values row
        if("Overall" %in% names(imp)){
            importance_no = imp[order(-imp$Overall), ,drop = FALSE]
        }else{
            importance_no = imp[order(-imp[, 1]), ]
        }
        importance_no$features <- rownames(importance_no)
        colnames(importance_no)[1] <- "score_no"

        importance_no$score_no <- round(as.numeric(as.character(importance_no$score_no)), 2)
        importance_no$score_no[is.infinite(importance_no$score_no) | is.nan(importance_no$score_no) | is.na(importance_no$score_no) ] <- NA 

        importance_no <- importance_no[!is.na(importance_no$score_no), ]
        importance_no$score_no[is.infinite(importance_no$score_no) | is.nan(importance_no$score_no) | is.na(importance_no$score_no) ] <- NA

        importance <- dplyr::full_join(importance_perc, importance_no, by = c("features"))

        if(nrow(importance) < 1 && is.na(importance)){
            cat(paste0("===> ERROR: prepareVariableImportance NA Values found\r\n"))
            print(importance_perc)
            print(importance_no)
            print(importance)
            ## Delete NA values
            # importance <- importance[!is.na(importance)]
            importance <- NULL
        }
    }

    return(importance)
}
