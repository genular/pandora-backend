#' @title  getPrAUC
#' @description Calculate PRAUC
#' @param predictionProcessed predictionProcessed
#' @param responseData modelData$testing[[dataset$outcome]]
#' @param dataset
#' @param outcome_mapping
#' @return list
getPrAUC <- function(predictionProcessed, responseData, dataset, outcome_mapping, model_details) {
    results <- list(status = FALSE, data = list())
    
    # Ensure predictionProcessed is a dataframe with proper column names for class probabilities
    if(!is.data.frame(predictionProcessed)) {
        stop("predictionProcessed should be a dataframe with class probabilities as columns.")
    }
    
    # Check if it's a multi-class scenario and adjust accordingly
    unique_classes <- unique(responseData)
    
    for (class_name in unique_classes) {
        # Binarize the response for the current class vs all others
        binary_response <- ifelse(responseData == class_name, 1, 0)
        
        # Ensure predictionProcessed is probability scores; adapt as needed if using raw scores
        if (!is.null(predictionProcessed[[class_name]])) {
            class_probs <- predictionProcessed[[class_name]]
        } else {
            next # Skip if no predictions for this class
        }
        
        # Compute PrAUC using PRROC::pr.curve for the binary scenario of class vs all
        input_args <- list(scores.class0 = class_probs[binary_response == 1], 
                           scores.class1 = class_probs[binary_response == 0], 
                           curve = TRUE)
                           
        process.execution <- tryCatch({
            pr_curve_data <- R.utils::withTimeout(do.call(PRROC::pr.curve, input_args), 
                                                  timeout = model_details$process_timeout, 
                                                  onTimeout = "error")
            list(curve_data = pr_curve_data, class_name = class_name)
        }, error = function(e) {
            return(list(error = e$message, class_name = class_name))
        })

        if (!is.null(process.execution$curve_data) && is.null(process.execution$error)) {
            results$status <- TRUE
            results$data[[class_name]] <- process.execution$curve_data
        } else {
            results$data[[class_name]] <- paste("Error computing PrAUC for class", class_name, ":", process.execution$error)
        }
    }
    
    return(results)
}

# Helper function to compute ROC data frame for each class
compute_roc_df <- function(class_name, class_probs, true_labels, timeout = 60) {
    result <- list(roc_df = NULL, error = NULL)
    binary_labels <- ifelse(true_labels == class_name, 1, 0)
    
    # Use withTimeout to manage long-running operations
    roc_computation <- R.utils::withTimeout({
        roc_obj <- pROC::roc(binary_labels, class_probs[[class_name]], quiet = TRUE)
        roc_df <- data.frame(spec = (1 - roc_obj$specificities), sens = roc_obj$sensitivities)
        roc_df$class_name <- as.factor(class_name)
        return(roc_df)
    }, timeout = timeout, onTimeout = "error")
    
    if(inherits(roc_computation, "error")) {
        result$error <- paste("Timeout or error in ROC computation for class", class_name)
    } else {
        result$roc_df <- roc_computation
    }
    
    return(result)
}

#' @title  getPredictROC
#' @description Build a ROC curve
#' @param responseData modelData$testing[[dataset$outcome]]
#' @param predictionsData predictionObject$predictions[, outcome_mapping[1, ]$class_remapped]
#' @param model_details
#' @return list
getPredictROC <- function(responseData, predictionsData, model_details) {
    results <- list(status = FALSE, data = list())
    responseData <- factor(responseData)
    timeout <- model_details$process_timeout # assuming this field exists and is set in seconds
    
    if(nlevels(responseData) < 3) {
        # Binary classification
        binary_class <- levels(responseData)[1]
        roc_result <- compute_roc_df(binary_class, predictionsData, responseData, timeout)
        if(is.null(roc_result$error)) {
            results$data[[binary_class]] <- roc_result$roc_df
            results$status <- TRUE
        } else {
            results$data[[binary_class]] <- roc_result$error
        }
    } else {
        # Multi-class handling
        for(class_level in levels(responseData)) {
            if(class_level %in% colnames(predictionsData)) {
                roc_result <- compute_roc_df(class_level, predictionsData, responseData, timeout)
                if(is.null(roc_result$error)) {
                    results$data[[class_level]] <- roc_result$roc_df
                    results$status <- TRUE
                } else {
                    results$data[[class_level]] <- roc_result$error
                }
            } else {
                results$data[[class_level]] <- paste("Error: Class probabilities for", class_level, "not found in predictionsData.")
            }
        }
    }
    
    if(!results$status) {
        results$data <- "ROC calculation failed due to an error or timeout."
    }
    
    return(results)
}

compute_auc_for_class <- function(class_name, class_probs, true_labels, timeout_seconds = 30) {
    results <- list(status = FALSE, data = NULL, message = "")
    tryCatch({
        response_binary <- ifelse(true_labels == class_name, 1, 0)
        
        # Timeout wrapper
        roc_obj <- R.utils::withTimeout({
            pROC::roc(response = response_binary, predictor = class_probs[[class_name]], quiet = TRUE)
        }, timeout = timeout_seconds, onTimeout = "error")
        
        auc_value <- pROC::auc(roc_obj)
        roc_details <- data.frame(specificities = roc_obj$specificities, sensitivities = roc_obj$sensitivities)
        
        results$data <- list(
            Class = class_name,
            AUC = auc_value,
            ROC_Details = roc_details,
            ROC = roc_obj
        )
        results$status <- TRUE
    }, error = function(e) {
        results$message <- e$message
    })
    
    if(!results$status) {
        results$data <- results$message
    }
    
    return(results)
}

compute_multiclass_auc <- function(true_labels, class_probs, timeout_seconds = 30) {
    results <- list(status = FALSE, data = NULL, message = "")
    tryCatch({
        true_labels <- factor(true_labels, levels = colnames(class_probs))
        
        # Timeout wrapper
        multiclass_roc_obj <- R.utils::withTimeout({
            # one-vs-rest ROC curves for each class
            pROC::multiclass.roc(response = true_labels, predictor = class_probs)
        }, timeout = timeout_seconds, onTimeout = "error")
        
        auc_value <- multiclass_roc_obj$auc
        
        results$data <- list(
            AUC = auc_value,
            ROC = multiclass_roc_obj
        )
        results$status <- TRUE
    }, error = function(e) {
        results$message <- e$message
    })
    
    if(!results$status) {
        results$data <- results$message
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
    # Ensure observed data is a factor with levels matching the predicted classes
    referenceData <- factor(referenceData, levels = unique(c(referenceData, predictionProcessed)))
    predictionProcessed <- factor(predictionProcessed, levels = levels(referenceData))
    
    input_args <- list(pred=predictionProcessed, obs=referenceData)
    
    process.execution <- tryCatch({
        results$data <- R.utils::withTimeout(do.call(caret::postResample, input_args), 
                                             timeout=model_details$process_timeout, 
                                             onTimeout = "error")
        results$status <- TRUE
    }, error = function(e) {
        results$data <- e$message
        results$status <- FALSE
    })
    
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
            cat(paste0("===> ERROR: getVariableImportance: ",match.call()[[1]]," (error): ", msg))
            return(NULL)
        },
        warning=function(msg) {
            cat(paste0("===> ERROR: getVariableImportance: ",match.call()[[1]]," (warning): ", msg))
            return(NULL)
        },
        finally={}
    )    
    return(out)
}

#' @title  prepareVariableImportance
#' @description 
#' @param model Model Fit from caret::train function
#' @param outcome_mapping
#' @return data frame
prepareVariableImportance <- function(model, outcome_mapping) {
    importance <- NULL

    # Ensure that variable importance data is present
    imp_perc <- getVariableImportance(model, TRUE) # Importance in percentage
    imp_no <- getVariableImportance(model, FALSE) # Raw importance numbers

    if (!is.null(imp_perc) && !is.null(imp_no)) { 
        ## Remove columns that are not in outcome_mapping$class_remapped here:
        imp_perc$importance <- imp_perc$importance[, colnames(imp_perc$importance) %in% outcome_mapping$class_remapped]
        imp_no$importance <- imp_no$importance[, colnames(imp_no$importance) %in% outcome_mapping$class_remapped]

        imp_no$importance$overall <-  rowMeans(imp_perc$importance, na.rm = TRUE)
        imp_perc$importance$overall <- rowMeans(imp_no$importance, na.rm = TRUE)

        imp_no$importance$overall_sum <-  rowSums(imp_perc$importance, na.rm = TRUE)
        imp_perc$importance$overall_sum <- rowSums(imp_no$importance, na.rm = TRUE)

        # Process importance data
        importance_perc <- processImportanceData(imp_perc, "score_perc")
        importance_no <- processImportanceData(imp_no, "score_no")

        importance <- dplyr::full_join(importance_perc, importance_no, by = c("feature_name", "outcome_class"))
        # Clean data: Convert to numeric and handle NAs, NaNs, and Inf
        importance <- cleanImportanceData(importance)

        importance <- importance %>%
            dplyr::group_by(outcome_class) %>%
            dplyr::mutate(rank =  rank(-score_perc, ties.method = "first")) %>%
            dplyr::ungroup()


        importance <- importance %>%
          dplyr::left_join(outcome_mapping, by = c("outcome_class" = "class_remapped")) %>%
          dplyr::mutate(id = if_else(is.na(id), 0L, id)) %>%
          dplyr::select(-outcome_class) %>%
          dplyr::rename(drm_id = id)

        importance <- as.data.frame(importance)
    }

    return(importance)
}

processImportanceData <- function(imp_data, value_name) {
    # Convert the 'importance' data to a data frame and explicitly add a 'feature_name' column
    df <- as.data.frame(imp_data$importance, stringsAsFactors = FALSE)
    df$feature_name <- rownames(df)
    
    # Now, melt the data frame, ensuring 'feature_name' is treated as an ID variable
    melted <- reshape2::melt(df, id.vars = "feature_name", variable.name = "outcome_class", value.name = value_name)
    
    return(melted)
}

cleanImportanceData <- function(importance) {
    # Convert score columns to numeric and round
    importance$score_perc <- round(as.numeric(as.character(importance$score_perc)), digits = 10)
    importance$score_no <- round(as.numeric(as.character(importance$score_no)), digits = 10)

    # Replace Inf, -Inf, NaN with NA
    importance$score_perc[is.infinite(importance$score_perc) | is.nan(importance$score_perc)] <- NA
    importance$score_no[is.infinite(importance$score_no) | is.nan(importance$score_no)] <- NA

    # Remove rows where both scores are NA
    importance <- importance[!is.na(importance$score_perc) | !is.na(importance$score_no), ]

    return(importance)
}
