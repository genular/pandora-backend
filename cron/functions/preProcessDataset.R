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

        updateDatabaseFiled("dataset_resamples", "status", 6, "id", dataset$resampleID)
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

        updateDatabaseFiled("dataset_resamples", "status", 6, "id", dataset$resampleID)
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
    outcome_unique_count <- length(outcome_unique)

    if(outcome_unique_count < 2 || outcome_unique_count > 702){
        cat(paste0("===> ERROR: You have: ", outcome_unique_count, " outcome class. You should have anything between 2-702 including 2 and 702.\r\n"))
        print(outcome_unique)
        updateDatabaseFiled("dataset_resamples", "status", 6, "id", dataset$resampleID)
        appendDatabaseFiled("dataset_resamples", "error", paste0("Incorrect number of outcome class levels in main dataset: ", outcome_unique_count), "id", dataset$resampleID)
        return(FALSE)
    }

    ## Remap outcome classes with A & B values
    mappings <- matrix(ncol=4, nrow=outcome_unique_count)

    ## Generate letters: LIMIT: 702 letters
    outcome_remapping <- c(LETTERS, sapply(LETTERS, function(x) paste0(x, LETTERS)))
    ## Convert "outcome" to characters and then do replacing
    datasetData[[dataset$outcome]] <- as.character(datasetData[[dataset$outcome]])

    m_count <- 1
    remap_count <- 1
    for(outcome_item in outcome_unique){
        mappings[m_count, ][1] <- dataset$outcome
        mappings[m_count, ][2] <- 2
        mappings[m_count, ][3] <- outcome_item
        mappings[m_count, ][4] <- outcome_remapping[remap_count]

        datasetData[[dataset$outcome]][datasetData[[dataset$outcome]] == outcome_item] <- outcome_remapping[remap_count]
        m_count <- m_count + 1
        remap_count <- remap_count + 1
    }

    ## Extract all non numeric column values and convert them to numeric
    non_numeric_column_ids <- unlist(lapply(datasetData[, !names(datasetData) %in% outcome_and_classes] , is.numeric))  
    non_numeric_column_names <- colnames(datasetData)[!non_numeric_column_ids]

    if(length(non_numeric_column_names) > 0){
        for (column_name in non_numeric_column_names){
            column_unique <- unique(datasetData[[column_name]])

            ## Extend the matrix
            mappings <- rbind(mappings, length(column_unique))

            column_remapping <- seq(1, length(column_unique), by=1)
            ## Convert "column" to characters and then do replacing
            datasetData[[column_name]] <- as.character(datasetData[[column_name]])

            remap_count <- 1
            ##   class_column class_type class_original class_remapped
            ## 1      column0          2       cyclists              A
            ## 2      column0          2   noncyclists               B
            ## 3      column0          2 wannabecyclist              C
            for(column_item in column_unique){
                ## class_column
                mappings[m_count, ][1] <- column_name
                ## class_type
                mappings[m_count, ][2] <- 2
                ## class_original
                mappings[m_count, ][3] <- column_item
                ## class_remapped
                mappings[m_count, ][4] <- column_remapping[remap_count]

                datasetData[[column_name]][datasetData[[column_name]] == column_item] <- column_remapping[remap_count]
                m_count <- m_count + 1
                remap_count <- remap_count + 1
            }
        }
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

    ## Convert all columns expect "outcome_and_classes" column to numeric values! 
    ## Same as above mappings but just in case we missed some!
    datasetData[, !names(datasetData) %in% outcome_and_classes] <- lapply(datasetData[, !names(datasetData) %in% outcome_and_classes] , as.numeric)

    # ==> 2 PREPROCCESING: Skewness and normalizing of the numeric predictors
    preProcessMapping <- NULL
    if(length(dataset$preProcess) > 0 ){
        transformations <- paste(dataset$preProcess, sep=",", collapse = ",")
        message <- paste0("===> INFO: Pre-processing transformation(s) (",transformations,") \r\n")
        cat(message)

        fs_status$info <- c(fs_status$info, message)

        preProcessedData <- preProcessData(datasetData, dataset$outcome, outcome_and_classes, dataset$preProcess)
        ## Final processed data-frame
        datasetData <- preProcessedData$processedMat

        if("pca" %in% dataset$preProcess){
            preProcessMapping <- preProcessedData$preprocessParams$rotation
            ## res.var <- factoextra::get_pca_var(res.pca)
            ## res.var$coord          # Coordinates
            ## res.var$contrib        # Contributions to the PCs
            ## res.var$cos2           # Quality of representation 
            ## corrplot::corrplot(res.var$cos2, is.corr = FALSE)
        }else if("ica" %in% dataset$preProcess){
            ## TODO not implemented
            ## preProcessMapping <- preProcessedData$processedMat
        }
    }

    ## Save newly generated components
    if(!is.null(preProcessMapping)){            
        saveDataPaths = list(path_initial = "", renamed_path = "", gzipped_path = "", file_path = "")
        ## JOB_DIR is temporarily directory on our local file-system
        saveDataPaths$path_initial <- paste0(JOB_DIR,"/data/",dataset$queueID,"_",dataset$resampleID,"_preProcessMapping.RData")
        save(preProcessMapping, file = saveDataPaths$path_initial)

        path_details = compressPath(saveDataPaths$path_initial)
        saveDataPaths$renamed_path = path_details$renamed_path
        saveDataPaths$gzipped_path = path_details$gzipped_path

        saveDataPaths$file_path = uploadFile(dataset$userID, saveDataPaths$gzipped_path, paste0("analysis/",serverData$queueID,"/",dataset$resampleID,"/data"))
        file_id <- db.apps.simon.saveFileInfo(dataset$userID, saveDataPaths)
    }

    ## Split datasetData into testing and training subsets based on Outcome column
    data <- createDataPartitions(datasetData, outcome = dataset$outcome, split = dataset$partitionSplit)

    samples <- list(total = nrow(datasetData), training = nrow(data$training), testing = nrow(data$testing))
    rm(datasetData)

    ## Coerce data to a standard data.frame
    data$training <- as.data.frame(data$training)
    data$testing <- as.data.frame(data$testing)

    ## Maintain order of outcome classes for different hard-coded performance calculations
    data$training <- data$training[order(data$training[[dataset$outcome]]), ]
    data$testing <- data$testing[order(data$testing[[dataset$outcome]]), ]

    ## Calculate dataset proportions
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

        updateDatabaseFiled("dataset_resamples", "status", 6, "id", dataset$resampleID)
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
                            status=as.numeric(3),
                            resampleID=as.numeric(dataset$resampleID))

    dbExecute(databasePool, query)

    return(TRUE)
}
