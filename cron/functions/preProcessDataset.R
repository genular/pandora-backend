#' @title preProcessDataset
#' @description Makes Train and Testing sets for the given dataset.
#' @param dataset
#' @return boolean
preProcessDataset <- function(dataset) {

    cat(paste0("===> INFO: preProcessDataset: started: ", dataset$remotePathMain,"\r\n"))

    filepath_extracted <- downloadDataset(dataset$remotePathMain)
    ## If data is missing cancel processing! 
    if(filepath_extracted == FALSE){
        message <- paste0("===> ERROR: Cannot download remote dataset data\r\n")
        cat(message)

        updateDatabaseFiled("dataset_resamples", "status", 5, "id", dataset$resampleID)
        appendDatabaseFiled("dataset_resamples", "error", message)
        return(FALSE)
    }

    glabalDataset <- data.table::fread(filepath_extracted, header = T, stringsAsFactors = FALSE, data.table = FALSE)

    #####################################################
    ## Combine Outcome and Classes
    outcome_and_classes <- c(dataset$outcome, dataset$classes)
    #####################################################

    if(length(dataset$outcome) != 1){

        message <- paste0("===> ERROR: Invalid number (",length(dataset$outcome),") of outcome columns detected. Currently only one is supported.")
        cat(message)

        updateDatabaseFiled("dataset_resamples", "status", 5, "id", dataset$resampleID)
        appendDatabaseFiled("dataset_resamples", "error", message)
        return(FALSE)
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
        updateDatabaseFiled("dataset_resamples", "status", 5, "id", dataset$resampleID)
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
        training =  list(path_initial = "", renamed_path = "", gzipped_path = "", file_path = "", ufid = ""),
        testing =  list(path_initial = "", renamed_path = "", gzipped_path = "", file_path = "", ufid = "")
    )

    #######################
    # Give it a unique filename to prevent filename clashes
    # since when processing happens all files from all resamples are downloaded in same /tmp directory on file-system
    splits$training$path_initial <- paste0(JOB_DIR,"/data/",dataset$queueID,"_",dataset$resampleID,"_training_partition.csv")
    data.table::fwrite(data$training, file = splits$training$path_initial, showProgress = FALSE)

    fileDetails = compressPath(splits$training$path_initial)
    splits$training$renamed_path = fileDetails$renamed_path
    splits$training$gzipped_path = fileDetails$gzipped_path

    splits$training$file_path <- uploadFile(dataset$userID, splits$training$gzipped_path, paste0("analysis/",dataset$queueID,"/",dataset$resampleID,"/partitions"))
    splits$training$ufid <- db.apps.simon.saveFileInfo(dataset$userID, splits$training)

    if(file.exists(splits$training$renamed_path)){ file.remove(splits$training$renamed_path) }
    if(file.exists(splits$training$gzipped_path)){ file.remove(splits$training$gzipped_path) }
    #######################
    splits$testing$path_initial <- paste0(JOB_DIR,"/data/",dataset$queueID,"_",dataset$resampleID,"_testing_partition.csv")
    data.table::fwrite(data$testing, file = splits$testing$path_initial, showProgress = FALSE)

    fileDetails = compressPath(splits$testing$path_initial)
    splits$testing$renamed_path = fileDetails$renamed_path
    splits$testing$gzipped_path = fileDetails$gzipped_path

    splits$testing$file_path <- uploadFile(dataset$userID, splits$testing$gzipped_path, paste0("analysis/",dataset$queueID,"/",dataset$resampleID,"/partitions"))
    splits$testing$ufid <- db.apps.simon.saveFileInfo(dataset$userID, splits$testing)

    if(file.exists(splits$testing$renamed_path)){ file.remove(splits$testing$renamed_path) }
    if(file.exists(splits$testing$gzipped_path)){ file.remove(splits$testing$gzipped_path) }
    #######################
    
    if(is.null(splits$training$ufid) || is.null(splits$testing$ufid)){
        message <- paste0("===> ERROR: Cannot save partitioned data into database, detected file ids: ",splits$training$ufid," - ", splits$testing$ufid)
        cat(message)

        updateDatabaseFiled("dataset_resamples", "status", 5, "id", dataset$resampleID)
        appendDatabaseFiled("dataset_resamples", "error", message)
        return(FALSE)
    }

    sql <- paste0("UPDATE dataset_resamples SET 
                            ufid_train=?ufid_train,
                            ufid_test=?ufid_test,
                            samples_training=?samples_training,
                            samples_testing=?samples_testing,
                            status=?status
                    WHERE dataset_resamples.id=?resampleID;")

    query <- sqlInterpolate(databasePool, sql,
                            ufid_train=as.numeric(splits$training$ufid),
                            ufid_test=as.numeric(splits$testing$ufid),
                            samples_training=as.numeric(samples$training),
                            samples_testing=as.numeric(samples$testing),
                            status=as.numeric(2),
                            resampleID=as.numeric(dataset$resampleID))

    dbExecute(databasePool, query)

    return(TRUE)
}
