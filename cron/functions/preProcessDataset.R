#' @title preProcessDataset
#' @description Makes Train and Testing sets for the given dataset.
#' @param dataset
#' dataset$remotePathMain
#' dataset$outcome
#' dataset$features
#' dataset$preProcess
#' dataset$userID
#' dataset$queueID
#' dataset$resampleID
#' dataset$resampleDataSource
#' @return boolean
preProcessDataset <- function(dataset) {
    success <- TRUE

    cat(paste0("===> INFO: preProcessDataset: started: ", dataset$remotePathMain,"\r\n"))

    globalDataset <- loadGlobalDataset(dataset$remotePathMain, dataset$resampleID)

    status <- checkSelectedOutcomeColumns(dataset$outcome, dataset$resampleID)
    if(status == FALSE){
        return(status)
    }

    ## Create local job processing directory /tmp/xyz
    JOB_DIR <- initilizeDatasetDirectory(dataset)

    cat(paste0("===> INFO: preProcessDataset: removing unnecessary columns: \r\n"))

    ## Remove all other than necessary columns, this should already be removed on intersect generation in PHP
    datasetData <- globalDataset[, names(globalDataset) %in% c(dataset$features, dataset$outcome, dataset$classes)]
    
    cat(paste0("===> INFO: preProcessDataset: defining factors: \r\n"))
    ## Maintain outcome as factors
    datasetData[[dataset$outcome]] <- as.factor(datasetData[[dataset$outcome]])
    ## Combine Outcome and Classes
    outcome_and_classes <- c(dataset$outcome, dataset$classes)

    cat(paste0("===> INFO: preProcessDataset: converting columns to numeric: \r\n"))
    ## Should we suppress warnings: suppressWarnings(as.numeric(c("1", "2", "X")))
    ## Convert all columns expect "outcome_and_classes" column to numeric values correcting NAs!
    datasetData[, !names(datasetData) %in% outcome_and_classes] <- lapply(datasetData[, !names(datasetData) %in% outcome_and_classes] , function(x) as.numeric(as.character(x)))

    status <- checkSelectedOutcomeValues(datasetData, dataset$outcome)
    if(status == FALSE){
        updateDatabaseFiled("dataset_resamples", "status", 6, "id", dataset$resampleID)
        appendDatabaseFiled("dataset_resamples", "error", paste0("Not enough number of unique outcome class levels/values"), "id", dataset$resampleID)
        return(status)
    }

    ## make mappings of outcome values
    resampleMappings <- generateResampleMappings(datasetData, dataset$outcome, outcome_and_classes, dataset$queueID, dataset$resampleID)
    ## Remap dataframe with mappings
    datasetData <- ramapColumnValuesByMappings(datasetData, resampleMappings$mappings, "class_original", "class_remapped")

    ## Preprocess resample data
    preProcessMapping <- preProcessResample(datasetData, dataset$preProcess, dataset$outcome, outcome_and_classes)
    
    datasetData <- preProcessMapping$datasetData

    if(!is.null(preProcessMapping$preProcessMapping)){ 
        ## 2. Save on file-system
        saveDataPaths <- saveAndUploadObject(preProcessMapping$preProcessMapping, dataset$userID, 
            paste0(JOB_DIR,"/data/",dataset$queueID,"_",dataset$resampleID,"_preProcessMapping.RData"), 
            paste0("analysis/",serverData$queueID,"/",dataset$resampleID,"/data"),
            "RData")

        ## 2. Save in database
        preProcessMappingFileID <- db.apps.pandora.saveFileInfo(dataset$userID, saveDataPaths)
    }

    ## Split datasetData into testing and training subsets based on Outcome column
    data <- createDataPartitions(datasetData, outcome = dataset$outcome, split = dataset$partitionSplit)
    ## Coerce data to a standard data.frame
    data$training <- as.data.frame(data$training)
    data$testing <- as.data.frame(data$testing)

    ## Maintain order of outcome classes for different hard-coded performance calculations
    data$training <- data$training[order(data$training[[dataset$outcome]]), ]
    data$testing <- data$testing[order(data$testing[[dataset$outcome]]), ]

    updateDatabaseFiled("dataset_resamples", "samples_training",nrow(data$training), "id", dataset$resampleID)
    updateDatabaseFiled("dataset_resamples", "samples_testing", nrow(data$testing), "id", dataset$resampleID)


    ## Calculate dataset proportions
    datasetProportions(dataset$resampleID, dataset$outcome, dataset$classes, data)

    saveDataPaths <- saveAndUploadObject(data$training, dataset$userID, 
        paste0(JOB_DIR,"/data/",dataset$queueID,"_",dataset$resampleID,"_training_partition.csv"), 
        paste0("analysis/",dataset$queueID,"/",dataset$resampleID,"/partitions"),
        "csv", FALSE)
    savedFileIDTrain <- db.apps.pandora.saveFileInfo(dataset$userID, saveDataPaths)

    updateDatabaseFiled("dataset_resamples", "ufid_train", savedFileIDTrain, "id", dataset$resampleID)

    saveDataPaths <- saveAndUploadObject(data$testing, dataset$userID, 
        paste0(JOB_DIR,"/data/",dataset$queueID,"_",dataset$resampleID,"_testing_partition.csv"), 
        paste0("analysis/",dataset$queueID,"/",dataset$resampleID,"/partitions"),
        "csv", FALSE)
    savedFileIDTest <- db.apps.pandora.saveFileInfo(dataset$userID, saveDataPaths)
    updateDatabaseFiled("dataset_resamples", "ufid_test", savedFileIDTest, "id", dataset$resampleID)

    if(is.null(savedFileIDTest) || is.null(savedFileIDTrain)){
        success <- FALSE
        message <- paste0("===> ERROR: Cannot save partitioned data into database, detected file ids: ",savedFileIDTrain," - ", savedFileIDTest)
        cat(message)

        updateDatabaseFiled("dataset_resamples", "status", 6, "id", dataset$resampleID)
        appendDatabaseFiled("dataset_resamples", "error", message)
        return(success)
    }

    ## Check number of unique outcomes in our partitions
    status <- checkSelectedOutcomeValues(data$training, dataset$outcome)
    if(status == FALSE){
        updateDatabaseFiled("dataset_resamples", "status", 6, "id", dataset$resampleID)
        appendDatabaseFiled("dataset_resamples", "error", paste0("Not enough number of unique outcome class levels/values in Training partition"), "id", dataset$resampleID)
        return(status)
    }

    status <- checkSelectedOutcomeValues(data$testing, dataset$outcome)
    if(status == FALSE){
        updateDatabaseFiled("dataset_resamples", "status", 6, "id", dataset$resampleID)
        appendDatabaseFiled("dataset_resamples", "error", paste0("Not enough number of unique outcome class levels/values in Testing partition"), "id", dataset$resampleID)
        return(status)
    }

    updateDatabaseFiled("dataset_resamples", "status", 3, "id", dataset$resampleID)

    ## If we successfully generated and preprocessed current resample check if we need to do RFE
    if(dataset$resampleDataSource == 0 & dataset$backwardSelection == 1){
        message <- paste0("===> INFO: Starting Recursive Feature Elimination\r\n")
        cat(message)

        ## Get only portion of data for RFE and leave other portion for model training
        rfeResults <- recursiveFeatureElimination(data$training, list(process_timeout = 3600), dataset$outcome)

        if(rfeResults$status == TRUE){
            message <- paste0("===> INFO: RFE selected ",length(rfeResults$modelPredictors)," columns\r\n")
            cat(message)

            if(length(rfeResults$modelPredictors) > 0){
                message <- paste0("===> INFO: Columns: ",paste(rfeResults$modelPredictors, sep=",", collapse = ",")," \r\n")
                cat(message)

                print("*******************************************")
                print(rfeResults$modelData)
                print("*******************************************")
            }


            ## 1. Save the new resample in databse with newly selected features
            rfeResampleID <- db.apps.pandora.saveRecursiveFeatureElimination(rfeResults$modelData, rfeResults$modelPredictors, data$training, dataset$resampleID)

            if(rfeResampleID == FALSE){
                message <- paste0("===> ERROR: Error creating new resample from RFE results \r\n")
                cat(message)
            }
            ## 2. Save the RFE model on file-system
            saveDataPaths <- saveAndUploadObject(rfeResults, dataset$userID, 
                paste0(JOB_DIR,"/data/",dataset$queueID,"_",dataset$resampleID,"_rfe_model.RData"), 
                paste0("analysis/",dataset$queueID,"/",dataset$resampleID,"/models"),
                "RData", FALSE)
            ## 3. Save the file in database
            rfeFileID <- db.apps.pandora.saveFileInfo(dataset$userID, saveDataPaths)

            ## 4. Generate new train and test files from original resample and update newly created one in database
            rfeData <- list(training = data$training, testing = NULL)
            rfeData$training <- rfeData$training[, names(rfeData$training) %in% c(rfeResults$modelPredictors, dataset$outcome, dataset$classes)]
            rfeData$testing <- data$testing[, names(data$testing) %in% c(rfeResults$modelPredictors, dataset$outcome, dataset$classes)]
            ## Calculate an save dataset proportions
            datasetProportions(rfeResampleID, dataset$outcome, dataset$classes, rfeData)
            ## Copy mappings from original resample to our RFE one
            status <- copyResampleMappings(dataset$queueID, dataset$resampleID, rfeResampleID)

            ## Save Train and Test files
            ## Update RFE resample with newly saved files IDS
            saveDataPaths <- saveAndUploadObject(rfeData$training, dataset$userID, 
                paste0(JOB_DIR,"/data/",dataset$queueID,"_",rfeResampleID,"_training_partition.csv"), 
                paste0("analysis/",dataset$queueID,"/",rfeResampleID,"/partitions"),
                "csv", FALSE)
            savedFileIDTrain <- db.apps.pandora.saveFileInfo(dataset$userID, saveDataPaths)

            updateDatabaseFiled("dataset_resamples", "ufid_train", savedFileIDTrain, "id", rfeResampleID)

            saveDataPaths <- saveAndUploadObject(rfeData$testing, dataset$userID, 
                paste0(JOB_DIR,"/data/",dataset$queueID,"_",rfeResampleID,"_testing_partition.csv"), 
                paste0("analysis/",dataset$queueID,"/",rfeResampleID,"/partitions"),
                "csv", FALSE)
            savedFileIDTest <- db.apps.pandora.saveFileInfo(dataset$userID, saveDataPaths)
            updateDatabaseFiled("dataset_resamples", "ufid_test", savedFileIDTest, "id", rfeResampleID)

            if(is.null(savedFileIDTest) || is.null(savedFileIDTrain)){
                success <- FALSE
                message <- paste0("===> ERROR: RFE - Cannot save partitioned data into database, detected file ids: ",savedFileIDTrain," - ", savedFileIDTest)
                cat(message)

                updateDatabaseFiled("dataset_resamples", "status", 6, "id", rfeResampleID)
                appendDatabaseFiled("dataset_resamples", "error", message)
                return(success)
            }

            ## Check number of unique outcomes in our partitions
            status <- checkSelectedOutcomeValues(rfeData$training, dataset$outcome)
            if(status == FALSE){
                updateDatabaseFiled("dataset_resamples", "status", 6, "id", rfeResampleID)
                appendDatabaseFiled("dataset_resamples", "error", paste0("Not enough number of unique outcome class levels/values in Training partition"), "id", rfeResampleID)
                return(status)
            }

            status <- checkSelectedOutcomeValues(rfeData$testing, dataset$outcome)
            if(status == FALSE){
                updateDatabaseFiled("dataset_resamples", "status", 6, "id", rfeResampleID)
                appendDatabaseFiled("dataset_resamples", "error", paste0("Not enough number of unique outcome class levels/values in Testing partition"), "id", rfeResampleID)
                return(status)
            }

            updateDatabaseFiled("dataset_resamples", "status", 3, "id", rfeResampleID)

        }else{
            message <- paste0("===> ERROR: Could not process RFE, not creating any resamples in database.\r\n")
            cat(message)
            str(rfeResults)
        }
        ## Mark resample as RFF processed
        updateDatabaseFiled("dataset_resamples", "data_source", 2, "id", dataset$resampleID)
        updateDatabaseFiled("dataset_resamples", "status", 5, "id", dataset$resampleID)
    }


    return(success)
}
