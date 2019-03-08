#' @title  
#' @description 
#' @param 
#' @param  
#' @return 
preProcessDataset <- function(dataset) {

    cat(paste0("===> INFO: Preprocessing: splitting into partitions.. path: ", dataset$remotePathMain,"\r\n"))

    filepath_extracted <- downloadDataset(dataset$remotePathMain)
    ## If data is missing cancel processing!
    if(filepath_extracted == FALSE){
        cat(paste0("===> ERROR: Cannot download remote dataset data\r\n"))
        updateDatabaseFiled("dataset_queue", "status", 6, "id", dataset$queueID)
        ## Remove PID file
        if(file.exists(SIMON_PID)){
            cat(paste0("===> INFO: Deleting SIMON_PID file \r\n"))
            invisible(file.remove(SIMON_PID))
        }
        quit()
    }

    glabalDataset <- data.table::fread(filepath_extracted, header = T, sep = ',', stringsAsFactors = FALSE, data.table = FALSE)

    #####################################################
    ## Combine Outcome and Classes
    outcome_and_classes <- c(dataset$outcome, dataset$classes)
    #####################################################

    if(length(dataset$outcome) != 1){
        cat("===> ERROR: Invalid number of outcome columns detected")
        quit()
    }

    ## Create local job processing dir /tmp/xyz
    JOB_DIR <- initilizeDatasetDirectory(dataset)


    fs_status <- list(error = c(), info = c())

    ## Remove all other than necessary columns, this should already be removed on intersect generation in PHP
    datasetData <- glabalDataset[, names(glabalDataset) %in% c(dataset$features, dataset$outcome, dataset$classes)]
    rm(glabalDataset)

    outcome_unique <- unique(datasetData[[dataset$outcome]])

    if(length(outcome_unique) > 2 || length(outcome_unique) < 2){
        cat(paste0("===> ERROR: Only two unique outcome classes are currently supported. You have: ", length(outcome_unique), "\r\n"))
        print(outcome_unique)
        updateDatabaseFiled("dataset_resamples", "status", 4, "id", dataset$resampleID)
        appendDatabaseFiled("dataset_resamples", "error", paste0("Incorrect number of outcome levels in main dataset: ", length(outcome_unique)), "id", dataset$resampleID)
        return(FALSE)
    }

    ## Remap outcome classes with A & B values
    mappings <- matrix(ncol=4, nrow=length(outcome_unique))

    ## Since "0" and "1", aren't valid variable names in R we need to use letters as class outcomes
    ## Remap outcome to numeric values
    ## outcome_remapping <- seq(1, length(outcome_unique), by=1)

    ## Generate letters: LIMIT: 702 letters
    outcome_remapping <- c(LETTERS, sapply(LETTERS, function(x) paste0(x, LETTERS)))

    ## Convert "outcome" to characters and then do replacing
    datasetData[[dataset$outcome]] <- as.character(datasetData[[dataset$outcome]])

    i <- 1
    for(outcome_item in outcome_unique){
        mappings[i, ][1] <- dataset$outcome
        mappings[i, ][2] <- 2
        mappings[i, ][3] <- outcome_item
        mappings[i, ][4] <- outcome_remapping[i]

        datasetData[[dataset$outcome]][datasetData[[dataset$outcome]] == outcome_item] <- outcome_remapping[i]
        i <- i + 1
    }

    ## Convert it to data-frame
    mappings <- as.data.frame(mappings)
    colnames(mappings) <- c("class_column", "class_type", "class_original", "class_remapped")

    query <- paste0("INSERT IGNORE INTO `dataset_resamples_mappings` 
                        (`id`, `dqid`, `drid`, `class_column`, `class_type`, `class_original`, `class_remapped`, `created`) 
                    VALUES", paste(sprintf("(NULL, '%s', '%s', '%s', '%s', '%s', '%s', NOW())", dataset$queueID, dataset$resampleID,
        mappings$class_column, mappings$class_type, mappings$class_original, mappings$class_remapped), collapse = ","))
   results <- dbExecute(databasePool, query)
   rm(mappings)

    ## Maintain outcome as factors
    datasetData[[dataset$outcome]] <- as.factor(datasetData[[dataset$outcome]])

    ## Convert all columns expect "outcome_and_classes" column to numeric
    datasetData[, !names(datasetData) %in% outcome_and_classes] <- lapply(datasetData[, !names(datasetData) %in% outcome_and_classes] , as.numeric)

    # ==> 2 PREPROCCESING: Skewness and normalizing of the numeric predictors
    if(length(dataset$preProcess) > 0 ){
        fs_status$info <- c(fs_status$info, paste0("Pre-processing transformation (centering, scaling, pca ... )"))
        datasetData <- preProcessData(datasetData, dataset$outcome, outcome_and_classes, dataset$preProcess)
    }

   
    ## Split datasetData into testing and training subsets based on Outcome column
    data <- createDataPartitions(datasetData, outcome = dataset$outcome, split = dataset$partitionSplit)

    samples <- list(total = nrow(datasetData), training = nrow(data$training), testing = nrow(data$testing))
    rm(datasetData)

    ## Coerce data to a standard data.frame
    data$training <- as.data.frame(data$training)
    data$testing <- as.data.frame(data$testing)

    datasetProportions(dataset$resampleID, dataset$outcome, dataset$classes, data)

    ## Make a backup of partitioned data
    splits = list(
        training = list(path_initial = "", path_renamed = "", gzipped_path = "", path_remote = "", ufid = ""),
        testing = list(path_initial = "", path_renamed = "", gzipped_path = "", path_remote = "", ufid = "")
    )

    splits$training$path_initial <- paste0(JOB_DIR,"/data/training.csv")
    data.table::fwrite(data$training, file = splits$training$path_initial, showProgress = FALSE)


    fileDetails = compressPath(splits$training$path_initial)
    splits$training$path_renamed = fileDetails$renamed_path
    splits$training$gzipped_path = fileDetails$gzipped_path

    splits$training$path_remote <- uploadFile(dataset$userID, splits$training$gzipped_path, paste0("uploads/datasets/",dataset$resampleID))

    splits$training$ufid <- db.apps.simon.saveFileInfo(dataset$userID, splits$training)
    file.remove(splits$training$path_renamed)
    file.remove(splits$training$gzipped_path)

    splits$testing$path_initial <- paste0(JOB_DIR,"/data/testing.csv")
    data.table::fwrite(data$testing, file = splits$testing$path_initial, showProgress = FALSE)
    fileDetails = compressPath(splits$testing$path_initial)
    splits$testing$path_renamed = fileDetails$renamed_path
    splits$testing$gzipped_path = fileDetails$gzipped_path

    splits$testing$path_remote <- uploadFile(dataset$userID, splits$testing$gzipped_path, paste0("uploads/datasets/",dataset$resampleID))
    splits$testing$ufid <- db.apps.simon.saveFileInfo(dataset$userID, splits$testing)
    file.remove(splits$testing$path_renamed)
    file.remove(splits$testing$gzipped_path)
    
    sql <- paste0("UPDATE dataset_resamples SET 
                    ufid_train=?ufid_train,
                    ufid_test=?ufid_test,
                    samples_training=?samples_training,
                    samples_testing=?samples_testing,
                    status=2
                    WHERE dataset_resamples.id=?resampleID;")

    query <- sqlInterpolate(databasePool, sql,
                            ufid_train=splits$training$ufid,
                            ufid_test=splits$testing$ufid,
                            samples_training=samples$training, 
                            samples_testing=samples$testing, 
                            resampleID=dataset$resampleID)

    dbExecute(databasePool, query)
}
