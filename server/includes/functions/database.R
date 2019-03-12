#' @title  db.checkUserAuthToken
#' @description Checks if user session X-TOKEN exist in database
#' @param auth_token
#' @return boolean
db.checkUserAuthToken  <- function(auth_token){

    sql <- "SELECT users_sessions.id AS id, users_sessions.uid AS uid, users.salt AS salt FROM `users_sessions` INNER JOIN users ON users_sessions.uid = users.id WHERE `session` = ?auth_token LIMIT 1;"
    query <- sqlInterpolate(databasePool, sql, auth_token = auth_token)
    results <- dbGetQuery(databasePool, query)

    return(results)
}

#' @title  db.getTotalCount
#' @description Return total count of data from mysql table
#' @param tables
#' @param where_clause
#' @return integer
db.getTotalCount <- function(tables, where_clause = NULL){
    data_count <- list()
    for (table in tables) {
        sql <- paste0("SELECT * FROM ",table,"")
        if(!is.null(where_clause)){
            sql <- paste0(sql, " WHERE ",where_clause,";")
        }
        results <- dbGetQuery(databasePool, sql)
        data_count[[table]] <- nrow(results)
    }
    return(data_count)
}


#' @title  db.apps.getCronJobQueue
#' @description Returns list of datasets that needs to be processed by a CRON script
#' @param data
#' @return list
db.apps.getCronJobQueue <- function(data){
    datasets = list()

    packages <- unlist(data$packages)
    packagesSQL <- paste0("SELECT id, internal_id, classification, regression  FROM models_packages WHERE models_packages.id IN (",paste(as.numeric(packages), sep="' '", collapse=", "),");")
    packagesQuery <- sqlInterpolate(databasePool, packagesSQL)
    packages <- dbGetQuery(databasePool, packagesQuery)

    ## Development overwrite
    ## testing_sql <- paste0("UPDATE dataset_queue SET status = 4 WHERE id = ", data$queueID)
    ## dbExecute(databasePool, testing_sql)

    sql <- paste0("## One Queue can have multiple resamples, resamples are datasets that needs to be processed on the server
                    ## Select queue needed for processing and all resamples that did not processed on all servers
                    SELECT 
                        dataset_queue.id AS queueID,
                        dataset_queue.uid AS userID,
                        dataset_queue.ufid,
                        dataset_queue.selectedOptions AS queueOptions,
                        dataset_queue.impute,
                        dataset_queue.extraction,
                        dataset_queue.packages,
                        dataset_queue.servers_total,
                        dataset_resamples.id AS resampleID,
                        dataset_resamples.selectedOptions AS resampleOptions,
                        dataset_resamples.samples_total AS samples_total,
                        users_files_main.file_path AS remotePathMain,
                        users_files_train.file_path AS remotePathTrain,
                        users_files_test.file_path AS remotePathTest

                    FROM dataset_queue
                    INNER JOIN dataset_resamples ON dataset_queue.id = dataset_resamples.dqid
                         ## Select only re-samples that are marked for processing
                         AND dataset_resamples.status IN (0,2)
                         AND dataset_resamples.servers_finished != dataset_queue.servers_total

                    LEFT JOIN users_files users_files_main ON dataset_resamples.ufid = users_files_main.id
                         AND users_files_main.uid = dataset_queue.uid

                    LEFT JOIN users_files users_files_train ON dataset_resamples.ufid_train = users_files_train.id
                         AND users_files_train.uid = dataset_queue.uid

                    LEFT JOIN users_files users_files_test ON dataset_resamples.ufid_test = users_files_test.id
                         AND users_files_test.uid = dataset_queue.uid

                    WHERE dataset_queue.id = ",data$queueID," AND dataset_queue.status IN(3, 4)

                    ORDER BY dataset_resamples.id ASC")

    query <- sqlInterpolate(databasePool, sql)
    results <- dbGetQuery(databasePool, query)
    if(nrow(results) > 0){
        for (i in 1:nrow(results)) {
            queueOptions <- list(jsonlite::fromJSON(results[i, ]$queueOptions))
            resampleOptions <- list(jsonlite::fromJSON(results[i, ]$resampleOptions))

            queueID <- results[i, ]$queueID
            resampleID <- results[i, ]$resampleID
            userID <- results[i, ]$userID

            samples_total <- results[i, ]$samples_total

            remotePathMain <-  results[i, ]$remotePathMain
            remotePathTrain <-  results[i, ]$remotePathTrain
            remotePathTest <-  results[i, ]$remotePathTest
            preProcess <- queueOptions[[1]]$preProcess
            partitionSplit <- queueOptions[[1]]$partitionSplit
            regressionFormula <- queueOptions[[1]]$formula$remapped
            classes <- queueOptions[[1]]$classes$remapped
            features <- resampleOptions[[1]]$features
            outcome <- resampleOptions[[1]]$outcome$remapped

            datasets[[i]] <- list(
                    queueID = queueID,
                    resampleID = resampleID,
                    userID = userID,
                    remotePathMain =  remotePathMain,
                    remotePathTrain =  remotePathTrain,
                    remotePathTest =  remotePathTest,
                    preProcess = preProcess,
                    partitionSplit = (partitionSplit / 100),
                    regressionFormula = regressionFormula,
                    samples_total = samples_total,
                    classes = classes,
                    features = features,
                    outcome = outcome,
                    packages = packages
                )       
        }
    }
    return(datasets)
}

db.apps.getModelsDetailsData <-function(modelsIDs){
    sql <- paste0("SELECT models.id                   AS modelID,
                           models_packages.internal_id AS modelInternalID,
                           users_files.file_path     AS remotePathMain
                    FROM   models
                           LEFT JOIN models_packages
                                  ON models_packages.id = models.mpid
                           LEFT JOIN users_files
                                  ON users_files.id = models.ufid
                    WHERE  models.id IN(",paste(as.numeric(modelsIDs), sep="' '", collapse=", "),")
                    ORDER BY models.id ASC;")
    query <- sqlInterpolate(databasePool, sql)
    results <- dbGetQuery(databasePool, query)

    return(results)
}

db.apps.getFeatureSetData <- function(resamplesID){
    datasets = list()

    sql <- paste0("SELECT 
                dataset_queue.id AS queueID,
                dataset_queue.uid AS userID,
                dataset_queue.ufid,
                dataset_queue.selectedOptions AS queueOptions,
                dataset_queue.impute,
                dataset_queue.extraction,
                dataset_queue.packages,
                dataset_queue.servers_total,
                dataset_resamples.id AS resampleID,
                dataset_resamples.selectedOptions AS resampleOptions,
                dataset_resamples.samples_total AS samples_total,
                users_files_main.file_path AS remotePathMain,
                users_files_train.file_path AS remotePathTrain,
                users_files_test.file_path AS remotePathTest

            FROM dataset_queue
            INNER JOIN dataset_resamples ON dataset_queue.id = dataset_resamples.dqid
                 ## Select only re-samples that are marked for processing
                 AND dataset_resamples.id IN (",paste(as.numeric(resamplesID), sep="' '", collapse=", "),")
                 AND dataset_resamples.servers_finished != dataset_queue.servers_total

            LEFT JOIN users_files users_files_main ON dataset_resamples.ufid = users_files_main.id
                 AND users_files_main.uid = dataset_queue.uid

            LEFT JOIN users_files users_files_train ON dataset_resamples.ufid_train = users_files_train.id
                 AND users_files_train.uid = dataset_queue.uid

            LEFT JOIN users_files users_files_test ON dataset_resamples.ufid_test = users_files_test.id
                 AND users_files_test.uid = dataset_queue.uid

            ORDER BY dataset_resamples.id ASC;")

    query <- sqlInterpolate(databasePool, sql)
    results <- dbGetQuery(databasePool, query)
    if(nrow(results) > 0){
        for (i in 1:nrow(results)) {
            queueOptions <- list(jsonlite::fromJSON(results[i, ]$queueOptions))
            packages <- list(jsonlite::fromJSON(results[i, ]$packages))
            
            resampleOptions <- list(jsonlite::fromJSON(results[i, ]$resampleOptions))



            queueID <- results[i, ]$queueID
            resampleID <- results[i, ]$resampleID
            userID <- results[i, ]$userID

            samples_total <- results[i, ]$samples_total
            remotePathMain <-  results[i, ]$remotePathMain
            remotePathTrain <-  results[i, ]$remotePathTrain
            remotePathTest <-  results[i, ]$remotePathTest

            preProcess <- queueOptions[[1]]$preProcess
            partitionSplit <- queueOptions[[1]]$partitionSplit

            regressionFormula <- queueOptions[[1]]$formula
            
            q_features <- queueOptions[[1]]$features
            r_features <- resampleOptions[[1]]$features
            features <- q_features[q_features$remapped %in% r_features, ]

            outcome <- resampleOptions[[1]]$outcome
            classes <- queueOptions[[1]]$classes
            
            datasets[[i]] <- list(
                    queueID = queueID,
                    resampleID = resampleID,
                    userID = userID,
                    remotePathMain =  remotePathMain,
                    remotePathTrain =  remotePathTrain,
                    remotePathTest =  remotePathTest,
                    preProcess = preProcess,
                    partitionSplit = (partitionSplit / 100),
                    regressionFormula = regressionFormula,
                    samples_total = samples_total,
                    classes = classes,
                    features = features,
                    outcome = outcome,
                    packages = packages
                )       
        }
    }
    return(datasets)
}

#' @title Check if specific model is processed
#' @description Check if model is processed for current resample ID
#' @param resampleID 
#' @param modelID
#' @return boolean
db.apps.checkIfModelProcessed <- function (resampleID, modelID){
    status <- FALSE
    query <- "SELECT id FROM models WHERE drid = ?resampleID AND mpid = ?modelID LIMIT 1;"
    
    query <- sqlInterpolate(databasePool, query, resampleID=resampleID, modelID=modelID)
    results <- dbGetQuery(databasePool, query)

    if(nrow(results) > 0){
        status <- TRUE
    }

    return (status)
}