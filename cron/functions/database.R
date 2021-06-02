#' @title getProcessingEntries
#' @description Returns next processing queue from database. Used if cron is used in single server mode.
#' Otherwise base64 encoded data from SIMON_DATA that is created by could.init script is used
#' @return data-frame
getProcessingEntries <- function(){
    queue = list()

    ## Get older processing entries first
    #
    # 1 - user confirms re-samples back in UI
    # 3 - Marked for processing
    # 4 - Processing
    # 8 - User resumes
    query <- "SELECT id, uid, packages, selectedOptions  FROM dataset_queue WHERE status IN(1,3,4,8) ORDER BY id ASC LIMIT 1"
    
    results <- dbGetQuery(databasePool, query)

    if(nrow(results) > 0){
        packages <- as.numeric(jsonlite::fromJSON(results[1, ]$packages)$packageID)
        queue <- list("queueID" = results[1, ]$id, "internalServerID" = 0, "packages" = packages, "initialization_time" = NULL, "selectedOptions" = jsonlite::fromJSON(results[1, ]$selectedOptions) )
    }

    return(queue)
}

#' @title getPerformanceVariable
#' @description 
#' @param variableValue 
#' @param performanceVariables 
#' @return data-frame
getPerformanceVariable <- function(variableValue, performanceVariables){
    ## details <- performanceVariables[performanceVariables$value %in% variableValue,]
    details <- performanceVariables %>% filter(value %in% variableValue)

    ## If performance variable is not already known, create a new one
    if(nrow(details) == 0){
        cat(paste0("===> WARNING: Creating new performance variables since we cannot find it: ",paste(variableValue, sep = ",", collapse = NULL)," \r\n"))

        for(vv in variableValue) { 
            pvID <- createPerformanceVariable(vv)
        }

        performanceVariables <- getAllPerformanceVariables()
    }

    return(performanceVariables)
}

#' @title createPerformanceVariable
#' @description 
#' @param variableValue 
#' @return data-frame
createPerformanceVariable <- function(variableValue){
    pvID <- NULL
    sql <- "INSERT IGNORE INTO models_performance_variables (id, value, created) VALUES (NULL, ?variableValue, NOW())
                ON DUPLICATE KEY UPDATE 
                value=?variableValue;"
    query <- sqlInterpolate(databasePool, sql, variableValue=variableValue)
    results <- dbExecute(databasePool, query)
    if(results == 1){
        pvID <- dbGetQuery(databasePool, "SELECT last_insert_id();")[1,1]
    }
    
    return(pvID)
}

#' @title getAllPerformanceVariables
#' @description Get all Performance Variables that are known to be used for model metrics
#' @return data-frame
getAllPerformanceVariables <- function(){
    query <- "SELECT id, value FROM models_performance_variables ORDER BY id ASC;"
    results <- dbGetQuery(databasePool, query)
    
    return(results)
}

#' @title getDatasetResamplesMappings
#' @description 
#' @param resampleID 
#' @param outcome_and_classes
#' @param data
#' @return 
getDatasetResamplesMappings <- function(queueID, resampleID, class_column){
    query <- "SELECT id, class_column, class_original, class_remapped FROM dataset_resamples_mappings WHERE dqid =?queueID AND drid =?resampleID AND class_column=?class_column"
    
    query <- sqlInterpolate(databasePool, query, queueID = queueID, resampleID=resampleID, class_column=class_column)
    results <- dbGetQuery(databasePool, query)
    
    return(results)
}

#' @title updateDatabaseFiled
#' @description 
#' @param table 
#' @param column
#' @param value
#' @param whereColumn
#' @param whereValue
#' @return 
updateDatabaseFiled <- function(table, column, value, whereColumn, whereValue){
    update_sql <- paste0("UPDATE ",table," SET ",column," = ?value WHERE ",whereColumn," = ?whereValue;")
    update_query <- sqlInterpolate(databasePool, update_sql, value=value, whereValue=whereValue)
    dbExecute(databasePool, update_query)
}

#' @title appendDatabaseFiled
#' @description 
#' @param table 
#' @param column
#' @param value
#' @param whereColumn
#' @param whereValue
#' @return 
appendDatabaseFiled <- function(table, column, value, whereColumn, whereValue){
    value <- paste0(value, "\r\n")
    update_sql <- paste0("UPDATE ",table," SET ",column," = if(",column," is null, ?value, concat(",column,", ?value)) WHERE ",whereColumn," = ?whereValue;")
    update_query <- sqlInterpolate(databasePool, update_sql, value=value, whereValue=whereValue)
    dbExecute(databasePool, update_query)
}

#' @title incrementDatabaseFiled
#' @description 
#' @param table 
#' @param column
#' @param value
#' @param whereColumn
#' @param whereValue
#' @return 
incrementDatabaseFiled <- function(table, column, value, whereColumn, whereValue){
    update_sql <- paste0("UPDATE ",table," SET ",column," = ",column," + ?value WHERE ",whereColumn," = ?whereValue;")
    update_query <- sqlInterpolate(databasePool, update_sql, value=value, whereValue=whereValue)
    dbExecute(databasePool, update_query)
}

#' @title datasetProportions
#' @description 
#' Classes that contains "strings" as values (eg. outcome) 
#' For-each "sting" value calculate following =>
#' outcome - (no) 1 - number
#' outcome - (%)  2 - percentage
#' 
#' Classes that contains "numbers" as values (eg. age) 
#' For-each "numeric" column calculate following =>
#' Age - (med) 3 - median
#' Age - (min) 4 - min
#' Age - (max) 5 - max
#' Age - (unq) 6 - unique values
#' Age - (tot) 7 - total values
#' 
#' @param resampleID Current resample ID
#' @param outcomes Character vector outcome columns
#' @param classes Character vector classes columns
#' @param data dataframe that contains data needed for training, testing or validation analysis
#' @return NULL
datasetProportions <- function(resampleID, outcomes, classes, data){
    outcome_and_classes <- c(outcomes, classes)

    ## Assign calculation types depending what kind of values are in columns
    ## Calculate 7 (total values) for both
    ## Since 6 and 7 is just length use if for both variable types
    calculate_types <- list(
            string = c(1,2,6,7),
            numbers = c(3,4,5,6,7)
        )

    props <- list()
    i <- 0
    
    for (dataSetsType in names(data)) {
        dataSetsTypeId = NULL

        if(dataSetsType == "training"){
            dataSetsTypeId = 1
        } else if(dataSetsType == "testing"){
            dataSetsTypeId = 2
        } else if(dataSetsType == "validation"){
            dataSetsTypeId = 3
        }else{
            dataSetsTypeId = 4
        }
        
        if(is.null(data[[dataSetsType]]) || nrow(data[[dataSetsType]]) < 2){
            next()
        }
        outcome_and_classes <- outcome_and_classes

        for(classColumn in outcome_and_classes){

            class_name = classColumn
            feature_set_type = dataSetsTypeId

            valuesOriginal <- data[[dataSetsType]][[classColumn]]
 
            data[[dataSetsType]][[classColumn]] = paste('data_', data[[dataSetsType]][[classColumn]], sep='')
            valuesUnique <- unique(data[[dataSetsType]][[classColumn]])


            table_percentage <- prop.table(table(data[[dataSetsType]][[classColumn]]))
            table_numbers <- table(data[[dataSetsType]][[classColumn]])

            calculateType = "string"
            isOutcome <- FALSE
            if(all.is.numeric(valuesOriginal)){
                calculateType = "numbers"
            }
            if(classColumn %in% outcomes){
                isOutcome <- TRUE
            }
            ## loop proportion tables and gather values
            for(classValue in valuesUnique){
                if(classValue == "data_"){
                    next()
                }
                for(measurement_type in calculate_types[[calculateType]]){
                    #cat(paste0("isOutcome ",isOutcome," calculateType ",calculateType," classColumn ", classColumn, " dataset ", dataSetsType, " value ", classValue, "\n"))
                    
                    result <- ""
                    if(measurement_type == 2){
                        result <- round(table_percentage[[classValue]], 2)
                    }else if(measurement_type == 1){
                        result <- round(table_numbers[[classValue]], 2)

                    }else if(measurement_type == 3){ # median
                        result <- median(valuesOriginal, na.rm = FALSE)
                    }else if(measurement_type == 4){ # min
                        result <- min(valuesOriginal)
                    }else if(measurement_type == 5){ # max
                        result <- max(valuesOriginal)
                    }else if(measurement_type == 6){ # unique
                        result <- length(valuesUnique)
                    }else if(measurement_type == 7){ # total values for the class
                        result <- length(valuesOriginal)
                    }

                    if(!is.null(result) || result != ""){
                        i <- i + 1
                        ID <- paste0("element_", i)
                        props[[ID]] <- list()
                       

                        if(calculateType == "string"){
                            props[[ID]]$value <- gsub("data_", "", classValue)
                        }else{
                            props[[ID]]$value = ""
                        }

                        props[[ID]]$class_name <- class_name
                        props[[ID]]$proportion_class_name <- class_name
                        props[[ID]]$feature_set_type <- feature_set_type
                        props[[ID]]$measurement_type <- measurement_type
                        props[[ID]]$result <- result
                        
                        # cat(paste0("1 - class: ", props[[ID]]$class_name, 
                        #     " dataset: ", props[[ID]]$feature_set_type, 
                        #     " measurement: ", props[[ID]]$measurement_type, 
                        #     " value: ", props[[ID]]$value, 
                        #     " result: ", props[[ID]]$result, "\n"))
                    }
                } ## measurement_type loop
                ## Dont calculate global number stats more than once for same data
                if(calculateType == "numbers"){
                    break
                }
            } ## classValue for loop

            if(isOutcome == FALSE && calculateType == "numbers"){
                ## Loop outcome columns and gather stats
                for(outcome in outcomes){
                    valuesUnique <- unique(data[[dataSetsType]][[outcome]])
                    ## Loop unique outcome column value
                    for(classValue in valuesUnique){
                        if(classValue == "data_"){
                            next()
                        }

                        valuesOriginal <- data[[dataSetsType]][data[[dataSetsType]][[outcome]] %in% classValue,][[classColumn]]
                        valuesOriginal <- as.numeric(gsub("data_", "", valuesOriginal))

                        for(measurement_type in calculate_types[[calculateType]]){
                            #cat(paste0("isOutcome ",isOutcome," calculateType ",calculateType," classColumn ", classColumn, " dataset ", dataSetsType, " value ", classValue, "\n"))
                            result <- ""
                            ## calculateType - numbers
                            if(measurement_type == 3){ # median
                                result <- median(valuesOriginal, na.rm = FALSE)
                            }else if(measurement_type == 4){ # min
                                result <- min(valuesOriginal)
                            }else if(measurement_type == 5){ # max
                                result <- max(valuesOriginal)
                            }else if(measurement_type == 7){ # total values
                                result <- length(valuesOriginal)
                            }
         
                            if(result != ""){
                                i <- i + 1
                                ID <- paste0("element_", i)
                                props[[ID]] <- list()
                                props[[ID]]$value = gsub("data_", "", classValue)
                                props[[ID]]$class_name <- class_name
                                props[[ID]]$proportion_class_name <- outcome
                                props[[ID]]$feature_set_type <- feature_set_type
                                props[[ID]]$measurement_type <- measurement_type
                                props[[ID]]$result <- result

                                # cat(paste0("2 - class: ", props[[ID]]$class_name, 
                                #     " dataset: ", props[[ID]]$feature_set_type, 
                                #     " measurement: ", props[[ID]]$measurement_type, 
                                #     " value: ", props[[ID]]$value, 
                                #     " result: ", props[[ID]]$result, "\n"))
                            }
                        } ## measurement_type loop
                    }
                }
            }

        } ## classColumn for loop
    } ## dataSetsType for loop

    props <- as.data.frame(data.table::rbindlist(props))
    query <- " INSERT IGNORE INTO `dataset_proportions`
               (
                      `id`,
                      `drid`,
                      `class_name`,
                      `proportion_class_name`,
                      `feature_set_type`,
                      `measurement_type`,
                      `value`,
                      `result`,
                      `created`
               )
               VALUES"
    query <- paste0(query, paste(sprintf("(NULL, '%s', '%s', '%s', '%s', '%s', '%s', '%s', NOW() )", resampleID, 
        props$class_name, 
        props$proportion_class_name, 
        props$feature_set_type, 
        props$measurement_type, 
        gsub("'","''", props$value),
        props$result), collapse = ","))
    dbExecute(databasePool, query)
}
#' @title db.apps.simon.saveFileInfo
#' @description Used to save newly generated Test/Train partitions files to MySQL
#' @param uid 
#' @param paths 
#' @return string
db.apps.simon.saveFileInfo <- function(uid, paths){
    ufid <- NULL

    extension <- ".csv"
    filename <- ""
    display_filename <- "default"
    mime_type <- "unknown"
    size <- 0
    file_hash <- ""

    sql <- "INSERT IGNORE INTO `users_files`
            (`id`, `uid`, `ufsid`, `item_type`, `file_path`, `filename`, `display_filename`, 
            `size`, `extension`, `mime_type`, `details`, `file_hash`, `created`, `updated`)
            VALUES (NULL,
                    ?uid,
                    1,
                    2,
                    ?file_path,
                    ?filename,
                    ?display_filename,
                    ?size,
                    ?extension,
                    ?mime_type,
                    NULL,
                    ?file_hash,
                    NOW(), NOW())
            ON DUPLICATE KEY UPDATE 
                id=LAST_INSERT_ID(id), uid=?uid, file_path=?file_path, filename=?filename, 
                display_filename=?display_filename, size=?size, extension=?extension, mime_type=?mime_type, file_hash=?file_hash"

    if("path_initial" %in% names(paths)){
        extension <- paste0(".", getExtension(paths$path_initial))
        ## Take the last extension in case multiple are detected
        if(length(extension) > 1){
            extension <- extension[length(extension)]
        }
        display_filename <- sub('\\..*$', '', basename(paths$path_initial))
        ##  Based on the data derived from /etc/mime.types
        mime_type <- mime::guess_type(paths$path_initial)
        ## Take the last mime in case multiple are detected
        if(length(mime_type) > 1){
            mime_type <- mime_type[length(mime_type)]
        }
    }
    
    if("renamed_path" %in% names(paths)){
        if(file.exists(paths$renamed_path)){
            size <- file.info(paths$renamed_path)$size
        }

        filename <- basename(paths$renamed_path)
        file_hash <- digest::digest(paths$renamed_path, algo="sha256", serialize=F, file=TRUE)
    }

    query <- sqlInterpolate(databasePool, sql, 
            uid=uid, 
            file_path=paths$file_path,
            filename=filename,
            display_filename=display_filename,
            size=size, 
            extension=extension,
            mime_type=mime_type,
            file_hash=file_hash
    )
    results <- dbExecute(databasePool, query)
    # 0 - ON DUPLICATE KEY
    if(results == 0 || results == 1){
        last_id <- dbGetQuery(databasePool, "SELECT last_insert_id();")
        ufid <- last_id[1,1]
    }else{
        print(paste0("====>>> ERROR: db.apps.simon.saveFileInfo ", results))
    }
    return(ufid)
}

#' @title db.apps.simon.saveFeatureSetsInfo
#' @description 
#' @param data 
#' @param samples
#' @param total_features
#' @param pqid
#' @param error
#' @return 
db.apps.simon.saveFeatureSetsInfo <- function(data, samples, total_features, pqid, error){
    fs_id <- NULL

    sql <- "INSERT IGNORE INTO `feature_sets` 
            (`id`, `pqid`, `data_source`, `samples_total`, `samples_training`, `samples_testing`, `features_count`, `error`, `created`, `updated`) 
            VALUES 
            (NULL, ?pqid, ?data_source, ?samples_total, ?samples_training, ?samples_testing, ?features_count, ?error, NOW(), NULL)

            ON DUPLICATE KEY UPDATE 
                samples_total=?samples_total, samples_training=?samples_training, samples_testing=?samples_testing, features_count=?features_count, error=?error, updated=NOW()"

    query <- sqlInterpolate(databasePool, sql, pqid=pqid, 
            data_source=as.numeric(1), 
            samples_total=samples$total, 
            samples_training=samples$training, 
            samples_testing=samples$testing, 
            features_count=total_features,
            error=toString(jsonlite::toJSON(error, pretty=TRUE)))
    
    results <- dbExecute(databasePool, query)

    if(results == 1){
        fs_id <- dbGetQuery(databasePool, "SELECT last_insert_id();")[1,1]
    }else{
        query <- sqlInterpolate(databasePool, "SELECT id FROM `feature_sets` WHERE `pqid` = ?pqid LIMIT 1;", pqid=pqid)
        results <- dbGetQuery(databasePool, query)
        if(nrow(results) > 0){
            fs_id <- results$id
        }
    }


    return(fs_id)
}

#' @title db.apps.simon.saveMethodAnalysisData
#' @description Save Model data into database with all performance measurements
#' @param resampleID ID of current processing re-sample
#' @param trainModel Complete model produces by caret::train
#' @param predConfusionMatrix
#' @param model_details Data-frame with current model details
#' @param predAUC List containing pROC measures
#' @param prAUC Precision/Recall AUC on Predict Test Set
#' @param predPostResample
#' @param status Boolean, true or false
#' @param errors Character vector with listed errors that occurred during training
#' @param model_time_start Sys.time() object with model starting time
#' @return list
db.apps.simon.saveMethodAnalysisData <- function(resampleID, trainModel, predConfusionMatrix, model_details, performanceVariables, predAUC, prAUC, predPostResample, errors, model_time_start){
    model_status <- 1
    training_time <- NULL

    ## Get total amount of time needed for model to process - time in DB should always be in milliseconds
    processing_time <- calculateTimeDifference(model_time_start, unit = "ms")
    if(is.null(processing_time)){
        processing_time <- 0
        cat(paste0("===> WARNING: Cannot calculate processing time. Time start: ",model_time_start," \r\n"))
    }

    if(length(errors) > 0){
        model_status <- 0
        errors <- paste(errors, collapse = "\n")
    }else{
        errors <- NULL
    }

    if (trainModel$status == TRUE) {
        ## Get only model training time
        training_time <- ceiling(as.numeric(trainModel$data$times$everything[3]) * 1000)
        cat(paste0("===> INFO: Model training time: ", training_time ," milliseconds \r\n"))
    }

    if(is.null(training_time)){
        training_time <- 0
    }

    sql <- "INSERT INTO `models`
                (
                    `id`,
                    `drid`,
                    `mpid`,
                    `status`,
                    `error`,
                    `training_time`,
                    `processing_time`,
                    `credits`,
                    `created`,
                    `updated`
                )
                    VALUES
                (
                    NULL,
                    ?drid,
                    ?mpid,
                    ?status,
                    ?error,
                    ?training_time,
                    ?processing_time,
                    NULL,
                    NOW(),
                    NOW()
                )   ON DUPLICATE KEY UPDATE
                drid=?drid, mpid=?mpid, status=?status, error=?error, training_time=?training_time, processing_time=?processing_time, updated=NOW();"



    query <- sqlInterpolate(databasePool, sql, 
        drid=resampleID, 
        mpid=model_details$id, 
        status=model_status, 
        error=toString(errors), 
        training_time=toString(training_time), 
        processing_time=processing_time)

    results <- dbExecute(databasePool, query)
    
    modelID <- NULL
    query <- sqlInterpolate(databasePool, "SELECT id FROM `models` WHERE `drid` = ?drid AND `mpid` = ?mpid AND `status` = ?status LIMIT 1;", drid=resampleID, mpid=model_details$id, status=model_status)
    results <- dbGetQuery(databasePool, query)
    if(nrow(results) > 0){
        modelID <- as.numeric(results$id)
    }

    ## Insert other model Variables:
    if(!is.null(modelID)){
        ## MySQL query placeholder
        prefQuery <- NULL

        ## Insert Model Training parameters
        if (trainModel$status == TRUE) {
            preferencies <- caret::getTrainPerf(trainModel$data)
            preferencies <- preferencies[, !(names(preferencies) %in% c("method"))]
            query <- NULL
            for(pref in names(preferencies)){
                for(value in preferencies[[pref]]){
                    ## value <- round(as.numeric(value), 4)
                    performanceVariables <- getPerformanceVariable(pref, performanceVariables)
                    pvDetails <- performanceVariables %>% filter(value == pref)

                    query <- c(query, sprintf("(NULL, '%s', '%s', '%s', NOW())", modelID, pvDetails$id, value))
                }
            }
            prefQuery <- paste(query, collapse = ",")
        }

        ## Insert Model Testing parameters
        if(!is.null(predConfusionMatrix)){
            confmatrix_data <- c(predConfusionMatrix$overall, predConfusionMatrix$byClass)
            confmatrix_data <- data.frame(prefName=names(confmatrix_data), prefValue=confmatrix_data, row.names=NULL)

      
            performanceVariables <- getPerformanceVariable(confmatrix_data$prefName, performanceVariables)  
            merged_values <- base::merge(confmatrix_data, performanceVariables, by.x = "prefName", by.y = "value", all.x = TRUE)

            query <- paste(sprintf("(NULL, '%s', '%s', '%s', NOW())", modelID, merged_values$id, merged_values$prefValue), collapse = ",")
            prefQuery <- paste(c(prefQuery, query), collapse = ",")

            ## Insert Positive control
            performanceVariables <- getPerformanceVariable("PositiveControl", performanceVariables)
            pvDetails <- performanceVariables %>% filter(value == "PositiveControl")

            prefQuery <- paste(c(prefQuery, paste0("(NULL, ",modelID,", ",pvDetails$id,", '",predConfusionMatrix$positive,"', NOW())")), collapse = ",")
        }

        ## Insert Testing pAUC
        if(!is.null(predAUC) & !is.null(predAUC$auc)){
            performanceVariables <- getPerformanceVariable("PredictAUC", performanceVariables)
            pvDetails <- performanceVariables %>% filter(value == "PredictAUC")

            prefQuery <- paste(c(prefQuery, paste0("(NULL, ",modelID,", ",pvDetails$id,", '",predAUC$auc,"', NOW())")), collapse = ",")
        }

        ## Insert Testing prAUC
        if(!is.null(prAUC) & !is.null(prAUC$auc.integral)){
            performanceVariables <- getPerformanceVariable("prAUC", performanceVariables)
            pvDetails <- performanceVariables %>% filter(value == "prAUC")

            prefQuery <- paste(c(prefQuery, paste0("(NULL, ",modelID,", ",pvDetails$id,", '",prAUC$auc.integral,"', NOW())")), collapse = ",")
        }

        ## Insert Testing Accuracy/Kappa or RMSE, Rsquared, MAE
        if(!is.null(predPostResample) & length(predPostResample) >= 2){
            postResampleData <- data.frame(prefName=names(predPostResample), prefValue=predPostResample, row.names=NULL)

            performanceVariables <- getPerformanceVariable(postResampleData$prefName, performanceVariables)
            merged_values <- base::merge(postResampleData, performanceVariables, by.x = "prefName", by.y = "value", all.x = TRUE)


            query <- paste(sprintf("(NULL, '%s', '%s', '%s', NOW())", modelID, merged_values$id, merged_values$prefValue), collapse = ",")
            prefQuery <- paste(c(prefQuery, query), collapse = ",")
        }
        ## When everything is ready insert data
        if(!is.null(prefQuery)){
            query <- paste0("INSERT IGNORE INTO models_performance (id, mid, mpvid, prefValue, created) VALUES ",prefQuery,";")
            dbExecute(databasePool, query)
        }
    }
    return(list(
        modelID = modelID,
        performanceVariables = performanceVariables))
}
#' @title Save variable importance to the database
#' @description  Save variable importance to the database and calculate unique variable importance hash
#' @param varImportance
#' @param modelID
#' @return 
db.apps.simon.saveVariableImportance <- function(varImportance, modelID){
    modelID <-as.numeric(modelID)
    ## Order dataframe for consistency, mostly because of md5 hash function
    varImportanceOrdered <- varImportance[order(varImportance$features, decreasing=F),]$features


    varImportance$features = lapply(varImportance$features, function(features) {
        dbQuoteString(databasePool, features)
    })

    # Begin the query
    query <- "INSERT IGNORE INTO `models_variables` 
    (`id`, `mid`, `feature_name`, `score_perc`, `score_no`, `rank`, `created`) VALUES"
    # Finish it with
    query <- paste0(query, paste(sprintf("(NULL, '%s', %s, '%s', '%s', '%s', NOW() )", modelID, varImportance$features, varImportance$score_perc, varImportance$score_no, varImportance$rank), collapse = ","))
    results <- dbExecute(databasePool, query)

    

    mv_hash <- digest::digest(paste(varImportanceOrdered, collapse = ','), algo="md5", serialize=F)
    updateDatabaseFiled("models", "mv_hash", mv_hash, "id", modelID)

    return(results)
}

#' @title Save RFE results
#' @description  Save new resample with selected columns from RFE
#' @param modelData
#' @param modelPredictors
#' @param dataTraining
#' @param resampleID
#' @return 
db.apps.simon.saveRecursiveFeatureElimination <- function(modelData, modelPredictors, dataTraining, resampleID){

    newResampleID <- FALSE

    query <- sqlInterpolate(databasePool, "SELECT * FROM `dataset_resamples` WHERE `id` = ?resampleID AND `data_source` = ?data_source AND `status` = ?status LIMIT 1;", resampleID=resampleID, data_source=0, status=3)
    originalResample <- dbGetQuery(databasePool, query)


    sql <- "INSERT INTO `dataset_resamples`
                (
                    `id`,
                    `dqid`,
                    `ufid`,
                    `ufid_train`,
                    `ufid_test`,
                    `data_source`,
                    `samples_total`,
                    `samples_training`,
                    `samples_testing`,
                    `features_total`,
                    `selectedOptions`,
                    `datapoints`,
                    `problemtype`,
                    `status`,
                    `servers_finished`,
                    `processing_time`,
                    `error`,
                    `created`,
                    `updated`
                )
                    VALUES
                (
                    NULL,
                    ?dqid,
                    ?ufid,
                    NULL,
                    NULL,
                    '1',
                    ?samples_total,
                    ?samples_training,
                    ?samples_testing,
                    ?features_total,
                    ?selected_options,
                    ?datapoints,
                    NULL,
                    '3',
                    '0',
                    NULL,
                    NULL,
                    NOW(),
                    NOW()
                );"


    selectedOptions <- list(jsonlite::fromJSON(originalResample$selectedOptions))
    selectedOptions[[1]]$features <- modelPredictors
    selectedOptions[[1]]$parentResampleID <- resampleID

    query <- pool::sqlInterpolate(databasePool, sql, 
            dqid=originalResample$dqid, 
            ufid=originalResample$ufid, 
            # ufid_train=originalResample$ufid_train, 
            # ufid_test=originalResample$ufid_test, 
            samples_total=as.numeric(originalResample$samples_total), 
            samples_training=as.numeric(originalResample$samples_training), 
            samples_testing=as.numeric(originalResample$samples_testing), 
            features_total=as.numeric(length(modelPredictors)), 
            selected_options=base::toString(jsonlite::toJSON(selectedOptions[[1]], pretty=TRUE)), 
            datapoints=as.numeric(length(modelPredictors) * nrow(dataTraining))
        )

    results <- dbExecute(databasePool, query)
    if(results == 1){
        newResampleID <- dbGetQuery(databasePool, "SELECT last_insert_id();")[1,1]
    }
    
    return(newResampleID)
}

#' @title copyResampleMappings
#' @description  Copy values from exsisting resample to a new one (duplicate)
#' @param queueID
#' @param resampleFromID
#' @param resampleToID
#' @return numeric
copyResampleMappings <- function(queueID, resampleFromID, resampleToID){

    sql <- "INSERT INTO dataset_resamples_mappings
                (dqid, drid, class_column, class_type, class_original, class_remapped, class_possition, created)
            SELECT 
                dqid, ?resampleToID, class_column, class_type, class_original, class_remapped, class_possition, created
            FROM 
                dataset_resamples_mappings
            WHERE 
                dqid = ?queueID AND drid = ?resampleFromID;"

    query <- sqlInterpolate(databasePool, sql,
        queueID=queueID,
        resampleToID=resampleToID, 
        resampleFromID=resampleFromID)

    results <- dbExecute(databasePool, query)

    return(results)
}
