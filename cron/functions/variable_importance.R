#' @title  
#' @description 
#' @param model Model Fit from caret::train function
#' @param scale 
#' @return data frame
getVariableImportance <- function(model, scale = TRUE) {
    out <- tryCatch(
        {
            varImp(model, scale=scale)
        },
        error=function(msg) {
            cat(paste0("===> ERROR: (getVariableImportance) ",match.call()[[1]]," (error): ", msg, "\r\n"))
            return(NULL)
        },
        warning=function(msg) {
            cat(paste0("===> ERROR: (getVariableImportance) ",match.call()[[1]]," (warning): ", msg, "\r\n"))
            return(NULL)
        },
        finally={}
    )    
    return(out)
}

#' @title  
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
        ## Take Overall if available otherwise take first values row
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
